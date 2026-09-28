from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RentCycleViewSet, GenerateRentInvoicesView

router = DefaultRouter()
router.register(r"cycles", RentCycleViewSet, basename="rent-cycle")
router.register(r"", RentCycleViewSet, basename="rent-cycle-direct")

urlpatterns = [
    path("generate-invoices/", GenerateRentInvoicesView.as_view(), name="generate-invoices"),
    path("", include(router.urls)),
]
