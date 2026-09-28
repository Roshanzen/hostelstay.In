from rest_framework import serializers
from .models import Booking


class BookingSerializer(serializers.ModelSerializer):
    room_number = serializers.ReadOnlyField(source="room.room_number")
    bed_label = serializers.ReadOnlyField(source="bed.label")
    property_name = serializers.ReadOnlyField(source="pg.name")

    class Meta:
        model = Booking
        fields = [
            "id",
            "pg",
            "property_name",
            "room",
            "room_number",
            "bed",
            "bed_label",
            "name",
            "phone",
            "email",
            "booking_date",
            "expected_checkin",
            "advance_amount",
            "status",
            "notes",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "booking_date", "created_at", "updated_at"]

