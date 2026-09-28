from django.contrib import admin
from .models import Bed


@admin.register(Bed)
class BedAdmin(admin.ModelAdmin):
    list_display = ("label", "room", "pg", "rent", "status", "tenant")
    list_filter = ("pg", "status")
    search_fields = ("label", "room__room_number", "tenant__name")

