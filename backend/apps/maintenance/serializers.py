from rest_framework import serializers
from .models import MaintenanceTicket


class MaintenanceTicketSerializer(serializers.ModelSerializer):
    room_number = serializers.ReadOnlyField(source="room.room_number")
    tenant_name = serializers.ReadOnlyField(source="tenant.name")

    class Meta:
        model = MaintenanceTicket
        fields = [
            "id",
            "pg",
            "title",
            "category",
            "priority",
            "status",
            "description",
            "room",
            "room_number",
            "tenant",
            "tenant_name",
            "cost_incurred",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

