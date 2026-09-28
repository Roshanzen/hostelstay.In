from django.contrib import admin
from .models import MaintenanceTicket


@admin.register(MaintenanceTicket)
class MaintenanceTicketAdmin(admin.ModelAdmin):
    list_display = ("title", "pg", "category", "priority", "status", "room", "tenant", "cost_incurred", "created_at")
    list_filter = ("pg", "category", "priority", "status", "created_at")
    search_fields = ("title", "description", "tenant__name", "room__room_number")

