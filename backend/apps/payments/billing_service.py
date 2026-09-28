"""
HMS Billing Service
===================
Central service layer for all billing operations.
All financial writes use transaction.atomic() + select_for_update().
Django is the authoritative source of truth for all financial calculations.
"""
from decimal import Decimal
from datetime import date, timedelta
import calendar

try:
    from dateutil.relativedelta import relativedelta
except ImportError:
    relativedelta = None

from django.db import transaction
from django.utils import timezone


def _add_months(sourcedate: date, months: int) -> date:
    """Safely adds/subtracts months respecting varying days per month."""
    if relativedelta is not None:
        return sourcedate + relativedelta(months=months)
    month = sourcedate.month - 1 + months
    year = sourcedate.year + month // 12
    month = month % 12 + 1
    day = min(sourcedate.day, calendar.monthrange(year, month)[1])
    return date(year, month, day)


class BillingService:

    # ──────────────────────────────────────────────────────────────
    # Number generators
    # ──────────────────────────────────────────────────────────────

    @staticmethod
    def generate_invoice_number():
        """Generate unique sequential INV-YYYY-NNNNNN inside an atomic block."""
        from .models import Invoice
        year = timezone.localdate().year
        prefix = f"INV-{year}-"
        # Count all invoices (including voided) for this year to maintain sequence
        count = Invoice.objects.filter(invoice_number__startswith=prefix).count()
        candidate = f"{prefix}{count + 1:06d}"
        # Ensure uniqueness in case of concurrent inserts
        while Invoice.objects.filter(invoice_number=candidate).exists():
            count += 1
            candidate = f"{prefix}{count + 1:06d}"
        return candidate

    @staticmethod
    def generate_receipt_number():
        """Generate unique sequential RCP-YYYY-NNNNNN inside an atomic block."""
        from .models import Payment
        year = timezone.localdate().year
        prefix = f"RCP-{year}-"
        count = Payment.objects.filter(receipt_number__startswith=prefix).count()
        candidate = f"{prefix}{count + 1:06d}"
        while Payment.objects.filter(receipt_number=candidate).exists():
            count += 1
            candidate = f"{prefix}{count + 1:06d}"
        return candidate

    # ──────────────────────────────────────────────────────────────
    # Period date calculation
    # ──────────────────────────────────────────────────────────────

    @staticmethod
    def get_period_dates(contract_start: date, frequency: str, period_index: int):
        """
        Returns (period_start, period_end, due_date) for the given 0-based period_index.
        Uses month arithmetic so month-end boundaries (Jan 31, Feb 28, etc.) are correct.

        frequency: monthly | quarterly | half_yearly | yearly
        """
        freq_months = {
            "monthly": 1,
            "quarterly": 3,
            "half_yearly": 6,
            "yearly": 12,
        }.get(frequency, 1)

        period_start = _add_months(contract_start, period_index * freq_months)
        period_end = _add_months(period_start, freq_months) - timedelta(days=1)
        due_date = period_start  # due on first day of period
        return period_start, period_end, due_date


    # ──────────────────────────────────────────────────────────────
    # Idempotent invoice creation
    # ──────────────────────────────────────────────────────────────

    @staticmethod
    def get_or_create_rent_invoice(tenant, period_start: date, period_end: date, due_date: date, created_by=None):
        """
        Idempotent: find or create one rent invoice for the given period.
        Returns (invoice, created: bool).

        Guards:
        - Does NOT create if period_start > tenant.contract_end_date.
        - Does NOT create if a non-voided invoice already exists for this period.
        """
        from .models import Invoice, InvoiceType, InvoiceStatus, AuditLog, AuditAction

        # Contract-end guard
        if tenant.contract_end_date and period_start > tenant.contract_end_date:
            return None, False

        # Idempotency: look for existing non-voided invoice
        existing = Invoice.objects.filter(
            tenant=tenant,
            type=InvoiceType.RENT,
            period_start=period_start,
            period_end=period_end,
            is_voided=False,
        ).first()
        if existing:
            return existing, False

        # Calculate amounts
        rent = tenant.rent_amount or Decimal("0")
        if rent <= Decimal("0"):
            return None, False
        discount = tenant.discount or Decimal("0")
        grace_days = tenant.grace_period_days or 0

        # Compute late fee if applicable
        late_fee = Decimal("0")
        if tenant.late_fee_type == "fixed":
            late_fee = tenant.late_fee_value or Decimal("0")
        elif tenant.late_fee_type == "percentage":
            late_fee = (rent * (tenant.late_fee_value or Decimal("0")) / 100).quantize(Decimal("0.01"))

        invoice_number = BillingService.generate_invoice_number()

        invoice = Invoice.objects.create(
            pg=tenant.pg,
            tenant=tenant,
            room=tenant.room,
            bed=tenant.bed,
            type=InvoiceType.RENT,
            period_start=period_start,
            period_end=period_end,
            invoice_number=invoice_number,
            amount=rent,
            discount=discount,
            late_fee=late_fee,
            paid_amount=Decimal("0"),
            status=InvoiceStatus.PENDING,
            due_date=due_date,
            billing_date=period_start,
            grace_period_days=grace_days,
        )

        if created_by:
            try:
                AuditLog.objects.create(
                    action=AuditAction.INVOICE_CREATED,
                    model_name="Invoice",
                    object_id=str(invoice.id),
                    user=created_by,
                    pg=tenant.pg,
                    new_value={
                        "invoice_number": invoice_number,
                        "amount": str(rent),
                        "period": f"{period_start}–{period_end}",
                    },
                )
            except Exception:
                pass  # Audit log failure must not block invoice creation

        return invoice, True

    # ──────────────────────────────────────────────────────────────
    # Payment allocation engine
    # ──────────────────────────────────────────────────────────────

    @staticmethod
    @transaction.atomic
    def allocate_payment(payment, target_invoice=None, created_by=None):
        """
        Oldest-first allocation of payment.amount across unpaid invoices.

        Rules:
        1. If target_invoice is given, pay it first (then continue oldest-first).
        2. For each invoice: allocate min(remaining, invoice_balance).
        3. Update Invoice.paid_amount + status.
        4. Create PaymentAllocation rows (idempotent: skip if already allocated).

        Returns list of (invoice, allocated_amount) tuples.
        """
        from .models import Invoice, PaymentAllocation, InvoiceStatus, AuditLog, AuditAction

        remaining = Decimal(str(payment.amount))
        allocations = []

        # Fetch all unpaid invoices for this tenant, locked for update
        unpaid_qs = (
            Invoice.objects.select_for_update()
            .filter(
                tenant=payment.tenant,
                pg=payment.pg,
                is_voided=False,
            )
            .exclude(status=InvoiceStatus.PAID)
            .order_by("due_date", "created_at")
        )
        invoice_list = list(unpaid_qs)

        # If target_invoice specified, promote it to front
        if target_invoice:
            target_id = target_invoice.id
            front = [inv for inv in invoice_list if inv.id == target_id]
            rest = [inv for inv in invoice_list if inv.id != target_id]
            invoice_list = front + rest

        for invoice in invoice_list:
            if remaining <= Decimal("0.01"):
                break

            net_amount = invoice.net_amount
            current_paid = invoice.paid_amount or Decimal("0")
            balance = max(Decimal("0"), net_amount - current_paid)

            if balance <= Decimal("0.01"):
                continue

            # Idempotency: skip if already allocated
            if PaymentAllocation.objects.filter(payment=payment, invoice=invoice).exists():
                continue

            allocate_amount = min(remaining, balance)

            PaymentAllocation.objects.create(
                payment=payment,
                invoice=invoice,
                allocated_amount=allocate_amount,
            )

            old_status = invoice.status
            invoice.paid_amount = current_paid + allocate_amount
            new_balance = max(Decimal("0"), net_amount - invoice.paid_amount)

            if new_balance <= Decimal("0.01"):
                invoice.status = InvoiceStatus.PAID
            elif invoice.paid_amount > Decimal("0"):
                invoice.status = InvoiceStatus.PARTIAL

            invoice.save(update_fields=["paid_amount", "status", "updated_at"])
            remaining -= allocate_amount
            allocations.append((invoice, allocate_amount))

            if created_by and old_status != invoice.status:
                try:
                    AuditLog.objects.create(
                        action=AuditAction.STATUS_CHANGED,
                        model_name="Invoice",
                        object_id=str(invoice.id),
                        user=created_by,
                        pg=invoice.pg,
                        old_value={"status": old_status, "paid_amount": str(current_paid)},
                        new_value={"status": invoice.status, "paid_amount": str(invoice.paid_amount)},
                    )
                except Exception:
                    pass

        return allocations

    # ──────────────────────────────────────────────────────────────
    # Status refresh (batch PENDING→OVERDUE)
    # ──────────────────────────────────────────────────────────────

    @staticmethod
    def refresh_invoice_statuses(pg_id):
        """
        Batch recalculate and persist invoice statuses for a property.
        Marks PENDING invoices as OVERDUE where grace period has passed.
        Returns count of invoices updated.
        """
        from .models import Invoice, InvoiceStatus

        # Only process non-paid, non-void invoices
        invoices = Invoice.objects.filter(
            pg_id=pg_id,
            is_voided=False,
        ).exclude(status__in=[InvoiceStatus.PAID, InvoiceStatus.CANCELLED, InvoiceStatus.VOID])

        updated = 0
        for inv in invoices:
            computed = inv.effective_status
            if computed != inv.status:
                inv.status = computed
                inv.save(update_fields=["status", "updated_at"])
                updated += 1
        return updated

    # ──────────────────────────────────────────────────────────────
    # Billing summaries
    # ──────────────────────────────────────────────────────────────

    @staticmethod
    def get_tenant_billing_summary(tenant_id):
        """
        Returns full billing context for a tenant, authoritative from DB.
        """
        from .models import Invoice, InvoiceStatus, Payment
        from tenants.models import Tenant

        try:
            tenant = Tenant.objects.select_related("pg", "room", "bed").get(id=tenant_id)
        except Tenant.DoesNotExist:
            return None

        invoices = list(
            Invoice.objects.filter(tenant=tenant, is_voided=False)
            .order_by("due_date")
        )
        payments = list(
            Payment.objects.filter(tenant=tenant, is_voided=False)
            .order_by("-payment_date")[:10]
        )

        total_invoiced = sum(float(inv.net_amount) for inv in invoices)
        total_paid = sum(float(inv.paid_amount or 0) for inv in invoices)
        total_outstanding = max(0.0, total_invoiced - total_paid)

        overdue_invoices = [i for i in invoices if i.status == InvoiceStatus.OVERDUE]
        overdue_amount = sum(float(i.remaining_amount) for i in overdue_invoices)

        next_invoice = next(
            (i for i in invoices if i.status in (InvoiceStatus.PENDING, InvoiceStatus.PARTIAL)),
            None,
        )

        return {
            "tenant_id": tenant.id,
            "tenant_name": tenant.name,
            "billing_frequency": tenant.billing_frequency,
            "monthly_rent": float(tenant.rent_amount or 0),
            "discount": float(tenant.discount or 0),
            "grace_period_days": tenant.grace_period_days,
            "contract_start": str(tenant.contract_start_date) if tenant.contract_start_date else None,
            "contract_end": str(tenant.contract_end_date) if tenant.contract_end_date else None,
            "total_invoiced": total_invoiced,
            "total_paid": total_paid,
            "total_outstanding": total_outstanding,
            "overdue_amount": overdue_amount,
            "overdue_count": len(overdue_invoices),
            "next_invoice": (
                {
                    "id": next_invoice.id,
                    "invoice_number": next_invoice.invoice_number,
                    "amount": float(next_invoice.net_amount),
                    "paid_amount": float(next_invoice.paid_amount or 0),
                    "balance": float(next_invoice.remaining_amount),
                    "due_date": str(next_invoice.due_date),
                    "status": next_invoice.status,
                    "period_start": str(next_invoice.period_start) if next_invoice.period_start else None,
                    "period_end": str(next_invoice.period_end) if next_invoice.period_end else None,
                }
                if next_invoice
                else None
            ),
            "recent_payments": [
                {
                    "id": p.id,
                    "receipt_number": p.receipt_number,
                    "amount": float(p.amount),
                    "payment_date": str(p.payment_date),
                    "payment_method": p.payment_method,
                    "reference": p.reference,
                }
                for p in payments
            ],
        }

    @staticmethod
    def get_pg_billing_summary(pg_id):
        """
        Dashboard financial summary for a property.
        Reconciled: total_outstanding = total_invoiced - total_collected.
        """
        from .models import Invoice, InvoiceStatus
        from django.db.models import Sum, Count

        qs = Invoice.objects.filter(pg_id=pg_id, is_voided=False)

        agg = qs.aggregate(
            total_invoiced_raw=Sum("amount"),
            total_paid=Sum("paid_amount"),
            total_discount=Sum("discount"),
            total_late_fee=Sum("late_fee"),
            invoice_count=Count("id"),
        )

        # net = amount + late_fee - discount per invoice; sum as proxy
        total_invoiced = (
            float(agg["total_invoiced_raw"] or 0)
            + float(agg["total_late_fee"] or 0)
            - float(agg["total_discount"] or 0)
        )
        total_collected = float(agg["total_paid"] or 0)
        total_outstanding = max(0.0, total_invoiced - total_collected)

        overdue_qs = qs.filter(status=InvoiceStatus.OVERDUE)
        pending_qs = qs.filter(status=InvoiceStatus.PENDING)

        overdue_agg = overdue_qs.aggregate(a=Sum("amount"), p=Sum("paid_amount"))
        overdue_amount = max(
            0.0,
            float(overdue_agg["a"] or 0) - float(overdue_agg["p"] or 0),
        )

        pending_agg = pending_qs.aggregate(a=Sum("amount"))
        pending_amount = float(pending_agg["a"] or 0)

        return {
            "pg_id": str(pg_id),
            "total_invoiced": total_invoiced,
            "total_collected": total_collected,
            "total_outstanding": total_outstanding,
            "overdue_amount": overdue_amount,
            "pending_amount": pending_amount,
            "invoice_count": agg["invoice_count"] or 0,
            "overdue_count": overdue_qs.count(),
            "pending_count": pending_qs.count(),
            "paid_count": qs.filter(status=InvoiceStatus.PAID).count(),
            "partial_count": qs.filter(status=InvoiceStatus.PARTIAL).count(),
        }
