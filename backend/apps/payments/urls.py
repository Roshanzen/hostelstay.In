from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    InvoiceViewSet,
    PaymentViewSet,
    ExpenseViewSet,
    MealViewSet,
    UtilityViewSet,
    # New billing views
    BillingSummaryView,
    TenantBillingSummaryView,
    RecordPaymentView,
    VoidInvoiceView,
    OverdueInvoicesView,
    UpcomingInvoicesView,
    GeneratePeriodInvoicesView,
    RefreshInvoiceStatusesView,
    PaymentAllocationsView,
)

combined_router = DefaultRouter()
combined_router.register(r"invoices", InvoiceViewSet, basename="comb-invoice")
combined_router.register(r"payments", PaymentViewSet, basename="comb-payment")
combined_router.register(r"expenses", ExpenseViewSet, basename="comb-expense")
combined_router.register(r"meals", MealViewSet, basename="comb-meal")
combined_router.register(r"utilities", UtilityViewSet, basename="comb-utility")

urlpatterns = [
    # ── Existing REST endpoints (backward compatible) ──
    path("", include(combined_router.urls)),

    # ── New billing endpoints ──
    path("billing/summary/", BillingSummaryView.as_view(), name="billing-summary"),
    path("billing/tenant-summary/<int:tenant_id>/", TenantBillingSummaryView.as_view(), name="billing-tenant-summary"),
    path("billing/record-payment/", RecordPaymentView.as_view(), name="billing-record-payment"),
    path("billing/void-invoice/<int:pk>/", VoidInvoiceView.as_view(), name="billing-void-invoice"),
    path("billing/overdue/", OverdueInvoicesView.as_view(), name="billing-overdue"),
    path("billing/upcoming/", UpcomingInvoicesView.as_view(), name="billing-upcoming"),
    path("billing/generate-period-invoices/", GeneratePeriodInvoicesView.as_view(), name="billing-generate-periods"),
    path("billing/refresh-statuses/", RefreshInvoiceStatusesView.as_view(), name="billing-refresh-statuses"),
    path("billing/payment-allocations/", PaymentAllocationsView.as_view(), name="billing-payment-allocations"),
]
