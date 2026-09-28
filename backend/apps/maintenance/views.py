from rest_framework import viewsets, permissions
from .models import MaintenanceTicket
from .serializers import MaintenanceTicketSerializer
from accounts.permissions import IsOwnerOrWarden
from accounts.property_permissions import filter_queryset_by_property


class MaintenanceTicketViewSet(viewsets.ModelViewSet):
    serializer_class = MaintenanceTicketSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["pg", "category", "priority", "status", "room"]
    search_fields = ["title", "description", "tenant__name", "room__room_number"]
    ordering_fields = ["priority", "status", "created_at", "cost_incurred"]

    def get_queryset(self):
        qs = MaintenanceTicket.objects.select_related("pg", "room", "tenant").all()
        qs = filter_queryset_by_property(self.request.user, qs)
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")
        if pg_id:
            qs = qs.filter(pg_id=pg_id)
        return qs

