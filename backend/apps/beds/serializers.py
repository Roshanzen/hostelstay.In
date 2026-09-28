from rest_framework import serializers
from .models import Bed


class BedSerializer(serializers.ModelSerializer):
    room_number = serializers.ReadOnlyField(source="room.room_number")
    tenant_name = serializers.ReadOnlyField(source="tenant.name")

    class Meta:
        model = Bed
        fields = [
            "id",
            "pg",
            "room",
            "room_number",
            "label",
            "rent",
            "status",
            "tenant",
            "tenant_name",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

