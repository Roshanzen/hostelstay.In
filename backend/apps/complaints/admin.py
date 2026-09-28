from django.contrib import admin
from .models import Complaint


@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = ("title", "pg", "tenant", "priority", "status", "assigned_to", "created_at")
    list_filter = ("pg", "priority", "status", "created_at")
    search_fields = ("title", "description", "tenant__name")

