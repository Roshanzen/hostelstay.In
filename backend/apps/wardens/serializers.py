from rest_framework import serializers
from .models import PropertyWardenAssignment
from accounts.models import User, UserRole
from accounts.serializers import UserSerializer
from properties.models import Property
from properties.serializers import PropertySerializer


class PropertyWardenAssignmentSerializer(serializers.ModelSerializer):
    warden_details = UserSerializer(source="warden", read_only=True)
    property_details = PropertySerializer(source="property", read_only=True)
    email = serializers.ReadOnlyField(source="warden.email")
    name = serializers.ReadOnlyField(source="warden.name")
    phone = serializers.ReadOnlyField(source="warden.phone")
    property_name = serializers.ReadOnlyField(source="property.name")

    class Meta:
        model = PropertyWardenAssignment
        fields = [
            "id",
            "warden",
            "warden_details",
            "property",
            "property_details",
            "property_name",
            "email",
            "name",
            "phone",
            "can_manage_tenants",
            "can_manage_rooms",
            "can_view_payments",
            "can_manage_expenses",
            "can_view_maintenance",
            "can_view_reports",
            "assigned_at",
        ]
        read_only_fields = ["id", "assigned_at"]

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        # Flutter expects data['warden'] to be either the user object or ID
        ret["warden"] = UserSerializer(instance.warden).data
        return ret


class InviteWardenSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    name = serializers.CharField(required=True)
    password = serializers.CharField(required=True, min_length=6)
    property = serializers.PrimaryKeyRelatedField(queryset=Property.objects.all())
    phone = serializers.CharField(required=False, allow_blank=True, default="")
    warden = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), required=False, allow_null=True
    )
    can_manage_tenants = serializers.BooleanField(default=True)
    can_manage_rooms = serializers.BooleanField(default=True)
    can_view_payments = serializers.BooleanField(default=True)
    can_manage_expenses = serializers.BooleanField(default=True)
    can_view_maintenance = serializers.BooleanField(default=True)
    can_view_reports = serializers.BooleanField(default=True)


class AssignWardenSerializer(serializers.Serializer):
    warden = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    property = serializers.PrimaryKeyRelatedField(queryset=Property.objects.all())
    can_manage_tenants = serializers.BooleanField(default=True)
    can_manage_rooms = serializers.BooleanField(default=True)
    can_view_payments = serializers.BooleanField(default=True)
    can_manage_expenses = serializers.BooleanField(default=True)
    can_view_maintenance = serializers.BooleanField(default=True)
    can_view_reports = serializers.BooleanField(default=True)

