from django.contrib import admin
from .models import Booking


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ("name", "phone", "pg", "room", "bed", "expected_checkin", "advance_amount", "status")
    list_filter = ("pg", "status", "expected_checkin")
    search_fields = ("name", "phone", "email")

