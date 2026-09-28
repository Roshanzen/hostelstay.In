from rest_framework import viewsets, permissions
from .models import Complaint
from .serializers import ComplaintSerializer
from accounts.permissions import IsOwnerOrWarden
from accounts.property_permissions import filter_queryset_by_property


class ComplaintViewSet(viewsets.ModelViewSet):
    serializer_class = ComplaintSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ["pg", "priority", "status", "tenant"]
    search_fields = ["title", "description", "tenant__name"]
    ordering_fields = ["priority", "status", "created_at"]

    def get_queryset(self):
        qs = Complaint.objects.select_related("pg", "tenant", "assigned_to").all()
        user = self.request.user
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")

        if user.is_tenant:
            from tenants.models import Tenant
            tenant = Tenant.objects.filter(user=user).first()
            if tenant:
                qs = qs.filter(tenant=tenant)
            else:
                return Complaint.objects.none()
        else:
            qs = filter_queryset_by_property(user, qs)
            if pg_id:
                qs = qs.filter(pg_id=pg_id)

        return qs

    def perform_create(self, serializer):
        user = self.request.user
        if user.is_tenant:
            from tenants.models import Tenant
            tenant = Tenant.objects.filter(user=user).first()
            serializer.save(tenant=tenant)
        else:
            serializer.save()

