from rest_framework import viewsets, permissions
from .models import Booking
from .serializers import BookingSerializer
from accounts.permissions import IsOwnerOrWarden
from accounts.property_permissions import filter_queryset_by_property


class BookingViewSet(viewsets.ModelViewSet):
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrWarden]
    filterset_fields = ["pg", "room", "status"]
    search_fields = ["name", "phone", "email", "notes"]
    ordering_fields = ["expected_checkin", "booking_date", "advance_amount"]

    def get_queryset(self):
        qs = Booking.objects.select_related("pg", "room", "bed").all()
        qs = filter_queryset_by_property(self.request.user, qs)
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")
        if pg_id:
            qs = qs.filter(pg_id=pg_id)
        return qs

