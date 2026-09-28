from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    WardenViewSet,
    MyAssignedPropertiesView,
    MyPermissionsView,
)

router = DefaultRouter()
router.register(r"wardens", WardenViewSet, basename="warden")
router.register(r"", WardenViewSet, basename="warden-direct")

urlpatterns = [
    path("my-assigned-properties/", MyAssignedPropertiesView.as_view(), name="my-assigned-properties"),
    path("my-permissions/", MyPermissionsView.as_view(), name="my-permissions"),
    path("", include(router.urls)),
]
