from django.contrib import admin
from .models import Tenant


@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    list_display = ("name", "phone", "pg", "room", "bed", "rent_amount", "security_deposit", "status", "move_in_date")
    list_filter = ("pg", "status", "id_type", "move_in_date")
    search_fields = ("name", "phone", "email", "id_number", "guardian_name")

