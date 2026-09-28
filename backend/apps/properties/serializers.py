from rest_framework import serializers
from .models import Property


class PropertySerializer(serializers.ModelSerializer):
    owner_name = serializers.ReadOnlyField(source="owner.name")
    total_beds = serializers.ReadOnlyField()
    occupied_beds = serializers.ReadOnlyField()
    vacant_beds = serializers.ReadOnlyField()
    occupancy_rate = serializers.ReadOnlyField()
    rooms_count = serializers.SerializerMethodField()
    lead_warden = serializers.SerializerMethodField()

    class Meta:
        model = Property
        fields = [
            "id",
            "name",
            "address",
            "phone",
            "email",
            "description",
            "total_rooms",
            "rooms_count",
            "status",
            "owner",
            "owner_name",
            "total_beds",
            "occupied_beds",
            "vacant_beds",
            "occupancy_rate",
            "lead_warden",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "owner", "created_at", "updated_at"]

    def get_rooms_count(self, obj):
        count = obj.rooms.count()
        return count if count > 0 else obj.total_rooms

    def get_lead_warden(self, obj):
        from wardens.models import PropertyWardenAssignment
        assignment = PropertyWardenAssignment.objects.filter(property=obj).select_related("warden").first()
        if assignment and assignment.warden:
            return {
                "id": assignment.warden.id,
                "name": assignment.warden.name,
                "email": assignment.warden.email,
                "phone": assignment.warden.phone,
            }
        return None

    def create(self, validated_data):
        # Automatically associate owner from request user
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            validated_data["owner"] = request.user
        return super().create(validated_data)

