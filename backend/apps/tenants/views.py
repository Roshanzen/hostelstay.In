from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction

from .models import Tenant, TenantStatus
from .serializers import TenantSerializer
from beds.models import Bed, BedStatus
from rooms.models import Room, RoomStatus
from accounts.permissions import IsOwnerOrWarden
from accounts.property_permissions import filter_queryset_by_property


class TenantViewSet(viewsets.ModelViewSet):
    serializer_class = TenantSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["pg", "room", "status", "id_type"]
    search_fields = ["name", "phone", "email", "emergency_contact", "id_number", "room__room_number"]
    ordering_fields = ["name", "move_in_date", "rent_amount", "created_at"]

    def get_queryset(self):
        qs = Tenant.objects.select_related("pg", "room", "bed").all()
        qs = filter_queryset_by_property(self.request.user, qs)
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")
        if pg_id:
            qs = qs.filter(pg_id=pg_id)
        return qs

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        tenant = serializer.save()
        headers = self.get_success_headers(serializer.data)

        # Build comprehensive structured response
        resp_data = dict(serializer.data)
        resp_data["success"] = True
        resp_data["message"] = (
            f"Tenant {tenant.name} admitted to Room {tenant.room_number or ''} "
            f"{tenant.bed_label or ''} successfully."
        )
        resp_data["tenant"] = serializer.data
        resp_data["room"] = tenant.room_id
        resp_data["room_number"] = tenant.room_number
        resp_data["bed"] = tenant.bed_id
        resp_data["bed_label"] = tenant.bed_label
        resp_data["property"] = {
            "id": tenant.pg_id,
            "name": tenant.pg.name if tenant.pg else "",
        }

        # Billing details
        inv = tenant.invoices.first()
        if inv:
            resp_data["billing"] = {
                "invoice_id": inv.id,
                "amount": float(inv.amount),
                "paid_amount": float(inv.paid_amount),
                "status": inv.status,
                "due_date": str(inv.due_date),
            }

        return Response(resp_data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_destroy(self, instance):
        with transaction.atomic():
            room = instance.room
            # Release bed when tenant record is removed
            if instance.bed:
                Bed.objects.filter(id=instance.bed.id).update(
                    status=BedStatus.AVAILABLE,
                    tenant=None,
                )
            instance.delete()
            if room:
                Room.objects.filter(id=room.id).update(status=RoomStatus.AVAILABLE)

    @action(detail=True, methods=["post"], url_path="checkout")
    def checkout(self, request, pk=None):
        tenant = self.get_object()
        with transaction.atomic():
            tenant.status = TenantStatus.INACTIVE
            tenant.save(update_fields=["status", "updated_at"])
            if tenant.bed:
                Bed.objects.filter(id=tenant.bed.id).update(
                    status=BedStatus.AVAILABLE,
                    tenant=None,
                )
            if tenant.room:
                Room.objects.filter(id=tenant.room.id).update(
                    status=RoomStatus.AVAILABLE,
                )
        return Response(
            {"success": True, "detail": f"Tenant {tenant.name} has been checked out."},
            status=status.HTTP_200_OK,
        )

