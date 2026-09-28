from django.contrib import admin
from .models import RentCycle


@admin.register(RentCycle)
class RentCycleAdmin(admin.ModelAdmin):
    list_display = ("pg", "billing_month", "total_tenants_billed", "total_amount_billed", "generated_at")
    list_filter = ("pg", "billing_month")

