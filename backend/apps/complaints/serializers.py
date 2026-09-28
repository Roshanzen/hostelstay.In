from rest_framework import serializers
from .models import Complaint


class ComplaintSerializer(serializers.ModelSerializer):
    tenant_name = serializers.ReadOnlyField(source="tenant.name")
    assigned_name = serializers.ReadOnlyField(source="assigned_to.name")

    class Meta:
        model = Complaint
        fields = [
            "id",
            "pg",
            "tenant",
            "tenant_name",
            "title",
            "description",
            "priority",
            "status",
            "assigned_to",
            "assigned_name",
            "resolution_notes",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

