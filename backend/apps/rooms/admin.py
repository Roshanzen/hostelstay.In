from django.contrib import admin
from .models import Room


@admin.register(Room)
class RoomAdmin(admin.ModelAdmin):
    list_display = ("room_number", "pg", "floor", "room_type", "capacity", "rent_amount", "status")
    list_filter = ("pg", "status", "floor", "room_type")
    search_fields = ("room_number", "pg__name")

