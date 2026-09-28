from datetime import datetime, date
from rest_framework import viewsets, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db import transaction

from .models import RentCycle
from .serializers import RentCycleSerializer, GenerateRentInvoicesSerializer
from properties.models import Property
from tenants.models import Tenant, TenantStatus
from payments.models import Invoice, InvoiceType, InvoiceStatus
from accounts.permissions import IsOwnerOrWarden


class RentCycleViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = RentCycle.objects.select_related("pg").all()
    serializer_class = RentCycleSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["pg", "billing_month"]

    def get_queryset(self):
        qs = super().get_queryset()
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")
        if pg_id:
            qs = qs.filter(pg_id=pg_id)
        return qs


class GenerateRentInvoicesView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]

    def post(self, request):
        serializer = GenerateRentInvoicesSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        pg_id = data["pg"]
        billing_month = data["billing_month"]
        due_days = data["due_days"]

        prop = Property.objects.filter(id=pg_id).first()
        if not prop:
            return Response({"detail": "Property not found."}, status=status.HTTP_404_NOT_FOUND)

        try:
            year, month = map(int, billing_month.split("-"))
            billing_date = date(year, month, 1)
            due_date = date(year, month, min(due_days, 28))
        except ValueError:
            return Response(
                {"detail": "billing_month must be in YYYY-MM format."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        active_tenants = Tenant.objects.filter(pg=prop, status=TenantStatus.ACTIVE)
        invoices_created = 0
        total_billed = 0.0

        with transaction.atomic():
            for tenant in active_tenants:
                # Check if invoice already exists for this tenant and month
                exists = Invoice.objects.filter(
                    pg=prop,
                    tenant=tenant,
                    type=InvoiceType.RENT,
                    billing_date=billing_date,
                ).exists()

                if not exists and tenant.rent_amount > 0:
                    from payments.billing_service import BillingService

                    period_start, period_end, _ = BillingService.get_period_dates(billing_date, "monthly", 0)
                    inv_num = BillingService.generate_invoice_number()


                    Invoice.objects.create(
                        pg=prop,
                        tenant=tenant,
                        room=tenant.room,
                        bed=tenant.bed,
                        type=InvoiceType.RENT,
                        invoice_number=inv_num,
                        period_start=billing_date,
                        period_end=period_end,
                        amount=tenant.rent_amount,
                        paid_amount=0.0,
                        discount=tenant.discount or 0.0,
                        grace_period_days=tenant.grace_period_days or 0,
                        status=InvoiceStatus.PENDING,
                        due_date=due_date,
                        billing_date=billing_date,
                    )
                    invoices_created += 1
                    total_billed += float(tenant.rent_amount)


            cycle, _ = RentCycle.objects.update_or_create(
                pg=prop,
                billing_month=billing_month,
                defaults={
                    "total_tenants_billed": invoices_created,
                    "total_amount_billed": total_billed,
                },
            )

        return Response(
            {
                "success": True,
                "message": f"Generated {invoices_created} rent invoices for {billing_month}.",
                "invoices_created": invoices_created,
                "total_amount_billed": total_billed,
                "billing_month": billing_month,
            },
            status=status.HTTP_201_CREATED,
        )

