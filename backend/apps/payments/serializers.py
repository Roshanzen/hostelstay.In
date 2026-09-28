from rest_framework import serializers
from .models import Invoice, Payment, PaymentAllocation, AuditLog, Expense, Meal, Utility


class PaymentAllocationSerializer(serializers.ModelSerializer):
    invoice_number = serializers.ReadOnlyField(source="invoice.invoice_number")
    invoice_status = serializers.ReadOnlyField(source="invoice.status")

    class Meta:
        model = PaymentAllocation
        fields = [
            "id",
            "payment",
            "invoice",
            "invoice_number",
            "invoice_status",
            "allocated_amount",
            "allocated_at",
        ]
        read_only_fields = ["id", "allocated_at"]


class InvoiceSerializer(serializers.ModelSerializer):
    tenant_name = serializers.ReadOnlyField(source="tenant.name")
    room_number = serializers.ReadOnlyField(source="room.room_number")
    remaining_amount = serializers.ReadOnlyField()
    is_overdue = serializers.ReadOnlyField()
    net_amount = serializers.ReadOnlyField()
    effective_status = serializers.ReadOnlyField()

    class Meta:
        model = Invoice
        fields = [
            "id",
            "pg",
            "tenant",
            "tenant_name",
            "room",
            "room_number",
            "bed",
            "type",
            "invoice_number",
            "period_start",
            "period_end",
            "amount",
            "discount",
            "late_fee",
            "net_amount",
            "paid_amount",
            "status",
            "effective_status",
            "due_date",
            "billing_date",
            "grace_period_days",
            "remaining_amount",
            "is_overdue",
            "is_voided",
            "notes",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "invoice_number", "created_at", "updated_at"]


class PaymentSerializer(serializers.ModelSerializer):
    tenant_name = serializers.ReadOnlyField(source="tenant.name")
    invoice_details = InvoiceSerializer(source="invoice", read_only=True)
    allocations = PaymentAllocationSerializer(many=True, read_only=True)

    class Meta:
        model = Payment
        fields = [
            "id",
            "pg",
            "tenant",
            "tenant_name",
            "invoice",
            "invoice_details",
            "amount",
            "payment_date",
            "payment_method",
            "reference",
            "receipt_number",
            "notes",
            "is_voided",
            "allocations",
            "created_at",
        ]
        read_only_fields = ["id", "receipt_number", "created_at"]


class ExpenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Expense
        fields = [
            "id",
            "pg",
            "category",
            "amount",
            "date",
            "description",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class MealSerializer(serializers.ModelSerializer):
    tenant_name = serializers.ReadOnlyField(source="tenant.name")

    class Meta:
        model = Meal
        fields = [
            "id",
            "pg",
            "tenant",
            "tenant_name",
            "date",
            "meal_type",
            "attended",
            "is_extra",
            "extra_charge",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class UtilitySerializer(serializers.ModelSerializer):
    total_amount = serializers.ReadOnlyField()

    class Meta:
        model = Utility
        fields = [
            "id",
            "pg",
            "utility_type",
            "units",
            "rate",
            "billing_date",
            "total_amount",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

    def to_internal_value(self, data):
        ret = super().to_internal_value(data)
        if "total_amount" in data and ("units" not in data or ret.get("units") == 0):
            ret["units"] = data["total_amount"]
            ret["rate"] = 1.0
        return ret

