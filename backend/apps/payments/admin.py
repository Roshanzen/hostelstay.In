from django.contrib import admin
from .models import Invoice, Payment, Expense, PaymentAllocation, AuditLog


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = (
        "invoice_number", "tenant", "pg", "type",
        "amount", "discount", "late_fee", "paid_amount",
        "status", "due_date", "period_start", "period_end", "is_voided",
    )
    list_filter = ("pg", "status", "type", "due_date", "is_voided")
    search_fields = ("tenant__name", "tenant__phone", "invoice_number")
    readonly_fields = ("invoice_number", "voided_at", "voided_by", "created_at", "updated_at")


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = (
        "receipt_number", "tenant", "pg", "amount",
        "payment_method", "payment_date", "invoice", "is_voided",
    )
    list_filter = ("pg", "payment_method", "payment_date", "is_voided")
    search_fields = ("tenant__name", "reference", "receipt_number")
    readonly_fields = ("receipt_number", "collected_by", "created_at")


@admin.register(PaymentAllocation)
class PaymentAllocationAdmin(admin.ModelAdmin):
    list_display = ("id", "payment", "invoice", "allocated_amount", "allocated_at")
    list_filter = ("payment__pg",)
    search_fields = ("payment__receipt_number", "invoice__invoice_number")


@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    list_display = ("id", "category", "pg", "amount", "date", "description")
    list_filter = ("pg", "category", "date")
    search_fields = ("description", "category")


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ("id", "action", "model_name", "object_id", "user", "pg", "timestamp")
    list_filter = ("action", "model_name", "pg", "timestamp")
    search_fields = ("object_id", "notes")
    readonly_fields = ("timestamp",)
