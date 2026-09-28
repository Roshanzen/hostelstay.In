from datetime import datetime, date
from django.utils import timezone
from django.db.models import Sum
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status

from properties.models import Property
from rooms.models import Room
from beds.models import Bed, BedStatus
from tenants.models import Tenant, TenantStatus
from payments.models import Invoice, Payment, Expense, Meal, Utility, InvoiceStatus
from maintenance.models import MaintenanceTicket, TicketStatus
from complaints.models import Complaint, ComplaintStatus
from notices.models import Notice
from payments.serializers import PaymentSerializer
from notices.serializers import NoticeSerializer
from accounts.property_permissions import authorized_property_ids


class DashboardStatsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        pg_id = request.query_params.get("pg") or request.query_params.get("property")
        month_str = request.query_params.get("month")

        if not month_str:
            now = timezone.localdate()
            month_str = f"{now.year}-{now.month:02d}"

        try:
            year, month = map(int, month_str.split("-"))
            start_date = date(year, month, 1)
            if month == 12:
                end_date = date(year + 1, 1, 1)
            else:
                end_date = date(year, month + 1, 1)
        except ValueError:
            start_date = None
            end_date = None

        allowed_prop_ids = list(authorized_property_ids(request.user))
        if not request.user.is_superuser:
            if pg_id:
                if int(pg_id) not in allowed_prop_ids:
                    return Response(
                        {"detail": "You are not authorized for this property."},
                        status=status.HTTP_403_FORBIDDEN,
                    )
            else:
                pg_id = allowed_prop_ids[0] if allowed_prop_ids else None
                if not pg_id:
                    return Response(
                        {"detail": "No authorized properties found."},
                        status=status.HTTP_403_FORBIDDEN,
                    )

        prop_filter = {}
        if pg_id:
            prop_filter["pg_id"] = pg_id

        # Beds & Occupancy
        total_beds = Bed.objects.filter(**prop_filter).count()
        if total_beds == 0 and pg_id:
            # Fallback to room capacities
            total_beds = sum(Room.objects.filter(pg_id=pg_id).values_list("capacity", flat=True))

        beds_qs = Bed.objects.filter(**prop_filter)
        if beds_qs.exists():
            occupied_beds = beds_qs.filter(status=BedStatus.OCCUPIED).count()
        else:
            assigned = Tenant.objects.filter(
                status=TenantStatus.ACTIVE,
                bed__isnull=False,
                **prop_filter
            ).count()
            occupied_beds = min(total_beds, assigned if assigned > 0 else Tenant.objects.filter(
                status=TenantStatus.ACTIVE,
                **prop_filter
            ).count())

        vacant_beds = max(0, total_beds - occupied_beds)
        occupancy_rate = min(100.0, round((occupied_beds / total_beds) * 100, 1)) if total_beds > 0 else 0.0
        total_active_tenants = Tenant.objects.filter(
            status=TenantStatus.ACTIVE,
            **prop_filter
        ).count()

        # Payments / Revenue in target month
        pay_qs = Payment.objects.filter(is_voided=False, **prop_filter)
        if start_date and end_date:
            pay_qs = pay_qs.filter(payment_date__gte=start_date, payment_date__lt=end_date)
        total_collected = float(pay_qs.aggregate(total=Sum("amount"))["total"] or 0.0)

        # Operational Expenses in target month
        exp_qs = Expense.objects.filter(**prop_filter)
        if start_date and end_date:
            exp_qs = exp_qs.filter(date__gte=start_date, date__lt=end_date)
        total_expenses = float(exp_qs.aggregate(total=Sum("amount"))["total"] or 0.0)

        # Maintenance costs
        maint_qs = MaintenanceTicket.objects.filter(**prop_filter)
        if start_date and end_date:
            maint_qs = maint_qs.filter(created_at__date__gte=start_date, created_at__date__lt=end_date)
        total_maint_cost = float(maint_qs.aggregate(total=Sum("cost_incurred"))["total"] or 0.0)

        # Utility costs
        util_qs = Utility.objects.filter(**prop_filter)
        if start_date and end_date:
            util_qs = util_qs.filter(billing_date__gte=start_date, billing_date__lt=end_date)
        total_util_cost = sum(u.total_amount for u in util_qs)

        # Extra meal charges
        meal_qs = Meal.objects.filter(is_extra=True, **prop_filter)
        if start_date and end_date:
            meal_qs = meal_qs.filter(date__gte=start_date, date__lt=end_date)
        total_meal_extras = float(meal_qs.aggregate(total=Sum("extra_charge"))["total"] or 0.0)

        total_costs = total_expenses + total_maint_cost + total_util_cost + total_meal_extras
        net_profit = round(total_collected - total_costs, 2)

        # Invoices: Overdue and Pending
        inv_qs = Invoice.objects.filter(is_voided=False, **prop_filter)
        unpaid_invoices = [inv for inv in inv_qs if inv.remaining_amount > 0 and inv.status not in (InvoiceStatus.CANCELLED, InvoiceStatus.VOID)]
        today = timezone.localdate()
        overdue_invoices = sum(1 for inv in unpaid_invoices if inv.due_date < today or inv.status == InvoiceStatus.OVERDUE)
        pending_amount = sum(inv.remaining_amount for inv in unpaid_invoices)

        # Operations
        open_tickets = MaintenanceTicket.objects.filter(
            status__in=[TicketStatus.OPEN, TicketStatus.IN_PROGRESS],
            **prop_filter
        ).count()

        open_complaints = Complaint.objects.filter(
            status__in=[ComplaintStatus.OPEN, ComplaintStatus.IN_PROGRESS],
            **prop_filter
        ).count()
        if open_complaints == 0 and open_tickets > 0:
            open_complaints = open_tickets

        # Recent activities
        recent_payments = Payment.objects.filter(is_voided=False, **prop_filter).select_related("tenant")[:5]
        recent_notices = Notice.objects.filter(
            is_published=True,
            **prop_filter
        ).select_related("created_by")[:5]

        return Response(
            {
                "success": True,
                "month": month_str,
                "total_collected": total_collected,
                "total_expenses": total_expenses,
                "total_maintenance_cost": total_maint_cost,
                "total_utility_cost": total_util_cost,
                "total_meal_extra_charges": total_meal_extras,
                "net_profit": net_profit,
                "total_beds": total_beds,
                "occupied_beds": occupied_beds,
                "vacant_beds": vacant_beds,
                "occupancy_rate": occupancy_rate,
                "overdue_invoices": overdue_invoices,
                "pending_amount": pending_amount,
                "total_tenants": total_active_tenants,
                "open_tickets": open_tickets,
                "open_complaints": open_complaints,
                "recent_payments": PaymentSerializer(recent_payments, many=True).data,
                "recent_notices": NoticeSerializer(recent_notices, many=True).data,
            },
            status=status.HTTP_200_OK,
        )

