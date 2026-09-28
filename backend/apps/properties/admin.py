from django.contrib import admin
from .models import Property


@admin.register(Property)
class PropertyAdmin(admin.ModelAdmin):
    list_display = ("name", "owner", "total_rooms", "phone", "email", "status", "created_at")
    list_filter = ("status", "created_at")
    search_fields = ("name", "address", "phone", "email", "owner__name", "owner__email")

