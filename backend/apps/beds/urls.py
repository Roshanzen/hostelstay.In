from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import BedViewSet

router = DefaultRouter()
router.register(r"beds", BedViewSet, basename="bed")
router.register(r"", BedViewSet, basename="bed-direct")

urlpatterns = [
    path("", include(router.urls)),
]
