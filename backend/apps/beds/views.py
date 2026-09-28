from rest_framework import viewsets, permissions
from .models import Bed
from .serializers import BedSerializer
from accounts.permissions import IsOwnerOrWarden
from accounts.property_permissions import filter_queryset_by_property


class BedViewSet(viewsets.ModelViewSet):
    serializer_class = BedSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["pg", "room", "status"]
    search_fields = ["label", "room__room_number", "tenant__name"]
    ordering_fields = ["label", "rent", "created_at"]

    def get_queryset(self):
        qs = Bed.objects.select_related("pg", "room", "tenant").all()
        qs = filter_queryset_by_property(self.request.user, qs)
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")
        room_id = self.request.query_params.get("room")
        status_filter = self.request.query_params.get("status")

        if pg_id:
            qs = qs.filter(pg_id=pg_id)
        if room_id:
            qs = qs.filter(room_id=room_id)
        if status_filter:
            qs = qs.filter(status=status_filter)
        return qs

