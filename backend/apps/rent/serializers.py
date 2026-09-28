from rest_framework import serializers
from .models import RentCycle


class RentCycleSerializer(serializers.ModelSerializer):
    class Meta:
        model = RentCycle
        fields = [
            "id",
            "pg",
            "billing_month",
            "generated_at",
            "total_tenants_billed",
            "total_amount_billed",
        ]
        read_only_fields = ["id", "generated_at", "total_tenants_billed", "total_amount_billed"]


class GenerateRentInvoicesSerializer(serializers.Serializer):
    pg = serializers.IntegerField(required=True)
    billing_month = serializers.CharField(required=True, max_length=7)  # YYYY-MM
    due_days = serializers.IntegerField(default=10, min_value=1, max_value=31)

