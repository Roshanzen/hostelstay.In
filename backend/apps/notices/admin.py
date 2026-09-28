from django.contrib import admin
from .models import Notice


@admin.register(Notice)
class NoticeAdmin(admin.ModelAdmin):
    list_display = ("title", "pg", "target_role", "is_published", "created_by", "created_at", "expires_at")
    list_filter = ("pg", "target_role", "is_published", "created_at")
    search_fields = ("title", "content")

