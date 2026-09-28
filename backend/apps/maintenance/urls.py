from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MaintenanceTicketViewSet

router = DefaultRouter()
router.register(r"maintenance", MaintenanceTicketViewSet, basename="maintenance")
router.register(r"", MaintenanceTicketViewSet, basename="maintenance-direct")

urlpatterns = [
    path("", include(router.urls)),
]
