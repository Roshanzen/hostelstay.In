from rest_framework import viewsets, permissions
from .models import Room
from .serializers import RoomSerializer
from accounts.permissions import IsOwnerOrWarden
from accounts.property_permissions import filter_queryset_by_property


class RoomViewSet(viewsets.ModelViewSet):
    serializer_class = RoomSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["pg", "status", "floor", "room_type"]
    search_fields = ["room_number", "floor", "room_type"]
    ordering_fields = ["room_number", "rent_amount", "created_at"]

    def get_queryset(self):
        qs = Room.objects.select_related("pg").all()
        qs = filter_queryset_by_property(self.request.user, qs)
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")
        if pg_id:
            qs = qs.filter(pg_id=pg_id)
        return qs

