from django.contrib import admin
from .models import PropertyWardenAssignment


@admin.register(PropertyWardenAssignment)
class PropertyWardenAssignmentAdmin(admin.ModelAdmin):
    list_display = (
        "warden",
        "property",
        "can_manage_tenants",
        "can_manage_rooms",
        "can_view_payments",
        "can_manage_expenses",
        "can_view_maintenance",
        "can_view_reports",
        "assigned_at",
    )
    list_filter = ("property", "can_manage_tenants", "can_manage_rooms", "can_view_payments")
    search_fields = ("warden__name", "warden__email", "property__name")

