from rest_framework import serializers
from .models import Room, RoomStatus


class RoomSerializer(serializers.ModelSerializer):
    occupied_count = serializers.ReadOnlyField()
    is_full = serializers.ReadOnlyField()

    class Meta:
        model = Room
        fields = [
            "id",
            "pg",
            "room_number",
            "floor",
            "room_type",
            "capacity",
            "rent_amount",
            "status",
            "occupied_count",
            "is_full",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def to_internal_value(self, data):
        # Flutter sends status as 'vacant' or 'available'
        data_copy = data.copy() if hasattr(data, "copy") else dict(data)
        if data_copy.get("status") == "vacant":
            data_copy["status"] = "available"
        return super().to_internal_value(data_copy)

    def create(self, validated_data):
        room = super().create(validated_data)
        from beds.models import Bed
        for i in range(room.capacity):
            label = chr(65 + i)
            Bed.objects.get_or_create(
                room=room,
                label=label,
                defaults={"pg": room.pg, "rent": room.rent_amount},
            )
        return room

    def update(self, instance, validated_data):
        room = super().update(instance, validated_data)
        from beds.models import Bed
        for i in range(room.capacity):
            label = chr(65 + i)
            Bed.objects.get_or_create(
                room=room,
                label=label,
                defaults={"pg": room.pg, "rent": room.rent_amount},
            )
        return room

