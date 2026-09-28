from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from dashboard.web_views import (
    smart_home_view,
    api_root_response,
    login_view,
    register_view,
    logout_view,
    dashboard_view,
    properties_view,
    property_create_view,
    property_edit_view,
    property_delete_view,
    property_detail_view,
    wardens_management_view,
    assign_warden_view,
    invite_warden_view,
    unassign_warden_view,
    update_warden_permissions_view,
    tenants_view,
    rooms_view,
    beds_view,
    payments_view,
    expenses_view,
    invoices_view,
    utilities_view,
    maintenance_view,
    meals_view,
    security_deposits_view,
    reports_view,
    activity_view,
)


def api_root(request):
    return api_root_response()


urlpatterns = [
    # Intelligent Root: Redirects browser to web dashboard/login, serves JSON to API clients
    path("", smart_home_view, name="root"),
    path("api/", api_root, name="api-root"),

    # Owner Web Authentication
    path("login/", login_view, name="web-login"),
    path("register/", register_view, name="web-register"),
    path("logout/", logout_view, name="web-logout"),

    # Owner Web Dashboard
    path("dashboard/", dashboard_view, name="web-dashboard"),

    # Properties
    path("dashboard/properties/", properties_view, name="web-properties"),
    path("dashboard/properties/create/", property_create_view, name="web-property-create"),
    path("dashboard/properties/<int:property_id>/", property_detail_view, name="web-property-detail"),
    path("dashboard/properties/<int:property_id>/edit/", property_edit_view, name="web-property-edit"),
    path("dashboard/properties/<int:property_id>/delete/", property_delete_view, name="web-property-delete"),

    # Wardens
    path("dashboard/wardens/", wardens_management_view, name="web-wardens"),
    path("dashboard/wardens/assign/", assign_warden_view, name="web-warden-assign"),
    path("dashboard/wardens/invite/", invite_warden_view, name="web-warden-invite"),
    path("dashboard/wardens/unassign/<int:assignment_id>/", unassign_warden_view, name="web-warden-unassign"),
    path("dashboard/wardens/update-permissions/<int:assignment_id>/", update_warden_permissions_view, name="web-warden-update-permissions"),

    # Operational & Domain Pages
    path("dashboard/tenants/", tenants_view, name="web-tenants"),
    path("dashboard/rooms/", rooms_view, name="web-rooms"),
    path("dashboard/beds/", beds_view, name="web-beds"),
    path("dashboard/payments/", payments_view, name="web-payments"),
    path("dashboard/expenses/", expenses_view, name="web-expenses"),
    path("dashboard/invoices/", invoices_view, name="web-invoices"),
    path("dashboard/utilities/", utilities_view, name="web-utilities"),
    path("dashboard/maintenance/", maintenance_view, name="web-maintenance"),
    path("dashboard/meals/", meals_view, name="web-meals"),
    path("dashboard/security-deposits/", security_deposits_view, name="web-security-deposits"),
    path("dashboard/reports/", reports_view, name="web-reports"),
    path("dashboard/activity/", activity_view, name="web-activity"),

    # Django Administration
    path("admin/", admin.site.urls),

    # Authentication & User Management
    path("api/", include("accounts.urls")),

    # Property & Hostel Management
    path("api/properties/", include("properties.urls")),

    # Warden Management
    path("api/wardens/", include("wardens.urls")),

    # Room & Bed Management
    path("api/rooms/", include("rooms.urls")),
    path("api/beds/", include("beds.urls")),

    # Tenant Management
    path("api/tenants/", include("tenants.urls")),

    # Invoices, Payments, Expenses, Meals, Utilities, Billing
    path("api/invoices/", include("payments.urls")),
    path("api/payments/", include("payments.urls")),
    path("api/expenses/", include("payments.urls")),
    path("api/meals/", include("payments.urls")),
    path("api/utilities/", include("payments.urls")),
    path("api/", include("payments.urls")),

    # Maintenance & Complaints
    path("api/maintenance/", include("maintenance.urls")),
    path("api/complaints/", include("complaints.urls")),

    # Notices & Announcements
    path("api/notices/", include("notices.urls")),

    # Rent Automation & Cycles
    path("api/rent/", include("rent.urls")),
    path("api/cycles/", include("rent.urls")),

    # Bookings & Reservations
    path("api/bookings/", include("bookings.urls")),

    # Notifications
    path("api/notifications/", include("notifications.urls")),

    # Dashboard & Real-time Analytics API
    path("api/dashboard/", include("dashboard.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
