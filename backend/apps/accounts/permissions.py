from rest_framework import permissions


class IsOwner(permissions.BasePermission):
    """Allows access only to authenticated property owners or admins."""
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.is_owner or request.user.is_superuser)
        )


class IsWarden(permissions.BasePermission):
    """Allows access to wardens, owners or admins."""
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.is_warden or request.user.is_owner or request.user.is_superuser)
        )


class IsTenant(permissions.BasePermission):
    """Allows access only to authenticated tenants."""
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            request.user.is_tenant
        )


class IsOwnerOrWarden(permissions.BasePermission):
    """Allows access to either owners or assigned wardens."""
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.is_owner or request.user.is_warden or request.user.is_superuser)
        )

