from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from .models import Property, PropertyStatus
from .serializers import PropertySerializer
from accounts.permissions import IsOwnerOrWarden
from accounts.property_permissions import filter_queryset_by_property


class PropertyViewSet(viewsets.ModelViewSet):
    serializer_class = PropertySerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["status", "owner"]
    search_fields = ["name", "address", "phone", "email"]
    ordering_fields = ["name", "created_at", "total_rooms"]

    def get_queryset(self):
        qs = Property.objects.select_related("owner").all()
        return filter_queryset_by_property(self.request.user, qs, property_field="pk")

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        active_tenants = instance.tenants.filter(status="active").count()
        if active_tenants > 0:
            instance.status = PropertyStatus.INACTIVE
            instance.save()
            return Response(
                {"detail": f"Property '{instance.name}' has {active_tenants} active tenants and was deactivated to preserve lease and ledger records."},
                status=status.HTTP_200_OK
            )
        return super().destroy(request, *args, **kwargs)

