from decimal import Decimal
from datetime import timedelta

from rest_framework import viewsets, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db import transaction
from django.core.exceptions import ValidationError
from django.utils import timezone

from .models import (
    Invoice, Payment, Expense, Meal, Utility,
    PaymentAllocation, AuditLog, AuditAction,
    InvoiceStatus, InvoiceType, PaymentMethod,
)
from .serializers import (
    InvoiceSerializer,
    PaymentSerializer,
    PaymentAllocationSerializer,
    ExpenseSerializer,
    MealSerializer,
    UtilitySerializer,
)
from .billing_service import BillingService
from accounts.permissions import IsOwnerOrWarden
from accounts.property_permissions import filter_queryset_by_property


# ──────────────────────────────────────────────────────────────────────────────
# Existing ViewSets (backward compatible)
# ──────────────────────────────────────────────────────────────────────────────

class InvoiceViewSet(viewsets.ModelViewSet):
    serializer_class = InvoiceSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["pg", "tenant", "status", "type"]
    search_fields = ["tenant__name", "room__room_number", "invoice_number"]
    ordering_fields = ["due_date", "amount", "created_at"]

    def get_queryset(self):
        qs = Invoice.objects.select_related("pg", "tenant", "room", "bed").all()
        qs = filter_queryset_by_property(self.request.user, qs)
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")
        if pg_id:
            qs = qs.filter(pg_id=pg_id)
        return qs

    def perform_create(self, serializer):
        """Auto-generate invoice_number on creation."""
        with transaction.atomic():
            invoice = serializer.save()
            if not invoice.invoice_number:
                invoice.invoice_number = BillingService.generate_invoice_number()
                invoice.save(update_fields=["invoice_number"])


class PaymentViewSet(viewsets.ModelViewSet):
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["pg", "tenant", "payment_method"]
    search_fields = ["tenant__name", "reference", "receipt_number"]
    ordering_fields = ["payment_date", "amount", "created_at"]

    def get_queryset(self):
        qs = Payment.objects.select_related("pg", "tenant", "invoice").prefetch_related("allocations").all()
        qs = filter_queryset_by_property(self.request.user, qs)
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")
        if pg_id:
            qs = qs.filter(pg_id=pg_id)
        return qs

    def create(self, request, *args, **kwargs):
        """
        Legacy payment creation — still supported for backward compatibility.
        Delegates to BillingService.allocate_payment() for oldest-first allocation.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        amount = serializer.validated_data.get("amount", Decimal("0"))
        if amount <= 0:
            raise ValidationError({"amount": "Payment amount must be greater than zero."})

        target_invoice = serializer.validated_data.get("invoice")

        with transaction.atomic():
            receipt_number = BillingService.generate_receipt_number()
            payment = serializer.save(
                receipt_number=receipt_number,
                collected_by=request.user,
            )

            allocations = BillingService.allocate_payment(
                payment,
                target_invoice=target_invoice,
                created_by=request.user,
            )

            try:
                AuditLog.objects.create(
                    action=AuditAction.PAYMENT_RECORDED,
                    model_name="Payment",
                    object_id=str(payment.id),
                    user=request.user,
                    pg=payment.pg,
                    new_value={
                        "receipt_number": receipt_number,
                        "amount": str(amount),
                        "payment_method": payment.payment_method,
                        "allocations_count": len(allocations),
                    },
                )
            except Exception:
                pass

        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)


class ExpenseViewSet(viewsets.ModelViewSet):
    serializer_class = ExpenseSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["pg", "category"]
    search_fields = ["description", "category"]
    ordering_fields = ["date", "amount", "created_at"]

    def get_queryset(self):
        qs = Expense.objects.select_related("pg").all()
        qs = filter_queryset_by_property(self.request.user, qs)
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")
        if pg_id:
            qs = qs.filter(pg_id=pg_id)
        return qs


class MealViewSet(viewsets.ModelViewSet):
    serializer_class = MealSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["pg", "tenant", "meal_type", "date", "is_extra"]
    search_fields = ["tenant__name"]
    ordering_fields = ["date", "created_at"]

    def get_queryset(self):
        qs = Meal.objects.select_related("pg", "tenant").all()
        qs = filter_queryset_by_property(self.request.user, qs)
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")
        if pg_id:
            qs = qs.filter(pg_id=pg_id)
        return qs


class UtilityViewSet(viewsets.ModelViewSet):
    serializer_class = UtilitySerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["pg", "utility_type", "billing_date"]
    ordering_fields = ["billing_date", "created_at"]

    def get_queryset(self):
        qs = Utility.objects.select_related("pg").all()
        qs = filter_queryset_by_property(self.request.user, qs)
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")
        if pg_id:
            qs = qs.filter(pg_id=pg_id)
        return qs


# ──────────────────────────────────────────────────────────────────────────────
# New Billing API Views
# ──────────────────────────────────────────────────────────────────────────────

class BillingSummaryView(APIView):
    """GET /api/billing/summary/?pg=<id> — dashboard financial reconciliation."""
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]

    def get(self, request):
        pg_id = request.query_params.get("pg") or request.query_params.get("property")
        if not pg_id:
            return Response({"detail": "pg parameter required."}, status=status.HTTP_400_BAD_REQUEST)
        # Refresh overdue statuses so numbers are accurate
        BillingService.refresh_invoice_statuses(pg_id)
        summary = BillingService.get_pg_billing_summary(pg_id)
        return Response(summary)


class TenantBillingSummaryView(APIView):
    """GET /api/billing/tenant-summary/<tenant_id>/ — per-tenant financial context."""
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]

    def get(self, request, tenant_id):
        summary = BillingService.get_tenant_billing_summary(tenant_id)
        if not summary:
            return Response({"detail": "Tenant not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(summary)


class RecordPaymentView(APIView):
    """
    POST /api/billing/record-payment/
    Atomic: create Payment + oldest-first PaymentAllocation + AuditLog.
    Returns receipt_number + allocation breakdown.
    """
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]

    def post(self, request):
        data = request.data
        tenant_id = data.get("tenant")
        pg_id = data.get("pg")

        try:
            amount = Decimal(str(data.get("amount", 0)))
        except Exception:
            return Response({"detail": "Invalid amount."}, status=status.HTTP_400_BAD_REQUEST)

        if amount <= 0:
            return Response({"detail": "Amount must be greater than zero."}, status=status.HTTP_400_BAD_REQUEST)

        from tenants.models import Tenant
        from properties.models import Property
        from datetime import date as date_type

        try:
            tenant = Tenant.objects.get(id=tenant_id, pg_id=pg_id)
        except Tenant.DoesNotExist:
            return Response({"detail": "Tenant not found for the given property."}, status=status.HTTP_404_NOT_FOUND)

        try:
            prop = Property.objects.get(id=pg_id)
        except Property.DoesNotExist:
            return Response({"detail": "Property not found."}, status=status.HTTP_404_NOT_FOUND)

        payment_method = data.get("payment_method", PaymentMethod.CASH)
        reference = data.get("reference", "")
        notes = data.get("notes", "")
        target_invoice_id = data.get("invoice")

        payment_date_raw = data.get("payment_date")
        try:
            payment_date = date_type.fromisoformat(str(payment_date_raw)) if payment_date_raw else timezone.localdate()
        except ValueError:
            payment_date = timezone.localdate()

        target_invoice = None
        if target_invoice_id:
            target_invoice = Invoice.objects.filter(id=target_invoice_id, tenant=tenant).first()

        with transaction.atomic():
            receipt_number = BillingService.generate_receipt_number()

            payment = Payment.objects.create(
                pg=prop,
                tenant=tenant,
                invoice=target_invoice,
                amount=amount,
                payment_date=payment_date,
                payment_method=payment_method,
                reference=reference,
                receipt_number=receipt_number,
                notes=notes,
                collected_by=request.user,
            )

            allocations = BillingService.allocate_payment(
                payment,
                target_invoice=target_invoice,
                created_by=request.user,
            )

            try:
                AuditLog.objects.create(
                    action=AuditAction.PAYMENT_RECORDED,
                    model_name="Payment",
                    object_id=str(payment.id),
                    user=request.user,
                    pg=prop,
                    new_value={
                        "receipt_number": receipt_number,
                        "amount": str(amount),
                        "payment_method": payment_method,
                        "allocations": [
                            {"invoice_id": inv.id, "invoice_number": inv.invoice_number, "amount": str(a_amt)}
                            for inv, a_amt in allocations
                        ],
                    },
                )
            except Exception:
                pass  # Audit failure must not roll back the payment

        alloc_data = [
            {
                "invoice_id": inv.id,
                "invoice_number": inv.invoice_number,
                "allocated_amount": float(a_amt),
                "invoice_status": inv.status,
                "invoice_balance": float(inv.remaining_amount),
            }
            for inv, a_amt in allocations
        ]

        return Response(
            {
                "success": True,
                "payment_id": payment.id,
                "receipt_number": receipt_number,
                "amount": float(amount),
                "payment_method": payment_method,
                "payment_date": str(payment.payment_date),
                "tenant_id": tenant.id,
                "tenant_name": tenant.name,
                "allocations": alloc_data,
                "allocations_count": len(alloc_data),
            },
            status=status.HTTP_201_CREATED,
        )


class VoidInvoiceView(APIView):
    """POST /api/billing/void-invoice/<pk>/ — void an invoice with audit trail."""
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]

    def post(self, request, pk):
        try:
            invoice = Invoice.objects.select_for_update().get(id=pk)
        except Invoice.DoesNotExist:
            return Response({"detail": "Invoice not found."}, status=status.HTTP_404_NOT_FOUND)

        if invoice.is_voided:
            return Response({"detail": "Invoice is already voided."}, status=status.HTTP_400_BAD_REQUEST)

        reason = request.data.get("reason", "")

        with transaction.atomic():
            old_status = invoice.status
            invoice.is_voided = True
            invoice.status = InvoiceStatus.CANCELLED
            invoice.voided_at = timezone.now()
            invoice.voided_by = request.user
            invoice.notes = f"VOIDED: {reason}" if reason else "VOIDED"
            invoice.save(update_fields=["is_voided", "status", "voided_at", "voided_by", "notes", "updated_at"])

            try:
                AuditLog.objects.create(
                    action=AuditAction.INVOICE_VOIDED,
                    model_name="Invoice",
                    object_id=str(invoice.id),
                    user=request.user,
                    pg=invoice.pg,
                    old_value={"status": old_status},
                    new_value={"status": "void", "reason": reason},
                    notes=reason,
                )
            except Exception:
                pass

        return Response(
            {
                "success": True,
                "invoice_id": invoice.id,
                "invoice_number": invoice.invoice_number,
            }
        )


class OverdueInvoicesView(APIView):
    """GET /api/billing/overdue/?pg=<id> — overdue invoices with days_overdue."""
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]

    def get(self, request):
        pg_id = request.query_params.get("pg") or request.query_params.get("property")
        if not pg_id:
            return Response({"detail": "pg parameter required."}, status=status.HTTP_400_BAD_REQUEST)

        BillingService.refresh_invoice_statuses(pg_id)
        today = timezone.localdate()

        overdue = (
            Invoice.objects.select_related("tenant", "room")
            .filter(pg_id=pg_id, status=InvoiceStatus.OVERDUE, is_voided=False)
            .order_by("due_date")
        )

        result = []
        for inv in overdue:
            balance = float(inv.remaining_amount)
            days_overdue = max(0, (today - inv.due_date).days)
            result.append(
                {
                    "id": inv.id,
                    "invoice_number": inv.invoice_number,
                    "tenant_id": inv.tenant_id,
                    "tenant_name": inv.tenant.name if inv.tenant else "",
                    "room_number": inv.room.room_number if inv.room else "",
                    "amount": float(inv.amount),
                    "discount": float(inv.discount or 0),
                    "late_fee": float(inv.late_fee or 0),
                    "net_amount": float(inv.net_amount),
                    "paid_amount": float(inv.paid_amount or 0),
                    "balance": balance,
                    "due_date": str(inv.due_date),
                    "days_overdue": days_overdue,
                    "period_start": str(inv.period_start) if inv.period_start else None,
                    "period_end": str(inv.period_end) if inv.period_end else None,
                    "status": inv.status,
                }
            )

        return Response({"results": result, "count": len(result)})


class UpcomingInvoicesView(APIView):
    """GET /api/billing/upcoming/?pg=<id> — pending invoices due in next 30 days."""
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]

    def get(self, request):
        pg_id = request.query_params.get("pg") or request.query_params.get("property")
        if not pg_id:
            return Response({"detail": "pg parameter required."}, status=status.HTTP_400_BAD_REQUEST)

        today = timezone.localdate()
        next_30 = today + timedelta(days=30)

        upcoming = (
            Invoice.objects.select_related("tenant", "room")
            .filter(
                pg_id=pg_id,
                is_voided=False,
                status__in=[InvoiceStatus.PENDING, InvoiceStatus.PARTIAL],
                due_date__gte=today,
                due_date__lte=next_30,
            )
            .order_by("due_date")
        )

        result = []
        for inv in upcoming:
            result.append(
                {
                    "id": inv.id,
                    "invoice_number": inv.invoice_number,
                    "tenant_id": inv.tenant_id,
                    "tenant_name": inv.tenant.name if inv.tenant else "",
                    "room_number": inv.room.room_number if inv.room else "",
                    "amount": float(inv.amount),
                    "net_amount": float(inv.net_amount),
                    "paid_amount": float(inv.paid_amount or 0),
                    "balance": float(inv.remaining_amount),
                    "due_date": str(inv.due_date),
                    "days_until_due": (inv.due_date - today).days,
                    "period_start": str(inv.period_start) if inv.period_start else None,
                    "period_end": str(inv.period_end) if inv.period_end else None,
                    "status": inv.status,
                }
            )

        return Response({"results": result, "count": len(result)})


class GeneratePeriodInvoicesView(APIView):
    """
    POST /api/billing/generate-period-invoices/
    Contract-aware, idempotent invoice generation.
    Body: { pg, tenant (optional), periods_ahead (default=1) }
    """
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]

    def post(self, request):
        from dateutil.relativedelta import relativedelta
        from tenants.models import Tenant, TenantStatus

        pg_id = request.data.get("pg")
        tenant_id = request.data.get("tenant")
        try:
            periods_ahead = max(1, int(request.data.get("periods_ahead", 1)))
        except (TypeError, ValueError):
            periods_ahead = 1

        if not pg_id:
            return Response({"detail": "pg required."}, status=status.HTTP_400_BAD_REQUEST)

        if tenant_id:
            tenants = Tenant.objects.filter(id=tenant_id, pg_id=pg_id, status=TenantStatus.ACTIVE)
        else:
            tenants = Tenant.objects.filter(pg_id=pg_id, status=TenantStatus.ACTIVE)

        today = timezone.localdate()
        invoices_created = 0
        total_amount = Decimal("0")

        freq_months_map = {
            "monthly": 1,
            "quarterly": 3,
            "half_yearly": 6,
            "yearly": 12,
        }

        with transaction.atomic():
            for tenant in tenants:
                if not tenant.rent_amount or tenant.rent_amount <= 0:
                    continue

                start = tenant.contract_start_date or tenant.move_in_date
                if not start:
                    continue

                freq = tenant.billing_frequency or "monthly"
                freq_months = freq_months_map.get(freq, 1)
                cutoff = today + relativedelta(months=periods_ahead * freq_months)

                for i in range(200):  # hard cap to prevent infinite loops
                    p_start, p_end, due = BillingService.get_period_dates(start, freq, i)

                    # Stop at contract end
                    if tenant.contract_end_date and p_start > tenant.contract_end_date:
                        break

                    # Stop at cutoff
                    if p_start > cutoff:
                        break

                    invoice, created = BillingService.get_or_create_rent_invoice(
                        tenant, p_start, p_end, due, created_by=request.user
                    )
                    if created and invoice:
                        invoices_created += 1
                        total_amount += invoice.amount

        return Response(
            {
                "success": True,
                "invoices_created": invoices_created,
                "total_amount": float(total_amount),
            },
            status=status.HTTP_201_CREATED,
        )


class RefreshInvoiceStatusesView(APIView):
    """POST /api/billing/refresh-statuses/?pg=<id> — batch mark OVERDUE."""
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]

    def post(self, request):
        pg_id = request.query_params.get("pg") or request.data.get("pg")
        if not pg_id:
            return Response({"detail": "pg required."}, status=status.HTTP_400_BAD_REQUEST)
        count = BillingService.refresh_invoice_statuses(pg_id)
        return Response({"success": True, "updated": count})


class PaymentAllocationsView(APIView):
    """GET /api/billing/payment-allocations/?payment=<id> — allocation detail."""
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]

    def get(self, request):
        payment_id = request.query_params.get("payment")
        if not payment_id:
            return Response({"detail": "payment parameter required."}, status=status.HTTP_400_BAD_REQUEST)
        allocs = PaymentAllocation.objects.select_related("invoice").filter(payment_id=payment_id)
        serializer = PaymentAllocationSerializer(allocs, many=True)
        return Response({"results": serializer.data, "count": allocs.count()})
