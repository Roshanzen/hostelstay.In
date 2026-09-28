from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ("name", "email", "phone", "role", "account_status", "is_staff", "date_joined")
    list_filter = ("role", "account_status", "is_staff", "is_active")
    search_fields = ("name", "email", "phone")
    ordering = ("-date_joined",)

    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal info", {"fields": ("name", "phone", "avatar", "username")}),
        ("Roles & Status", {"fields": ("role", "account_status")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Important dates", {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("email", "name", "phone", "role", "password", "password_confirm"),
        }),
    )

