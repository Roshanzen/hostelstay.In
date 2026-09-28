from datetime import date
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from properties.models import Property
from wardens.models import PropertyWardenAssignment
from rooms.models import Room, RoomStatus
from beds.models import Bed, BedStatus
from tenants.models import Tenant, TenantStatus
from payments.models import Invoice, Payment, Expense, InvoiceStatus
from maintenance.models import MaintenanceTicket

User = get_user_model()


class EndToEndHMSTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Owner
        self.owner = User.objects.create_user(
            email="owner@test.com", password="password123", name="Owner Test", role="owner"
        )
        # Warden
        self.warden = User.objects.create_user(
            email="warden@test.com", password="password123", name="Warden Test", role="warden"
        )

        # Authenticate as Warden
        login_res = self.client.post(
            "/api/auth/login/",
            {"username": "warden@test.com", "password": "password123"},
            format="json",
        )
        self.token = login_res.data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.token}")

        # Property
        self.prop = Property.objects.create(
            name="Kathmandu Residency",
            address="Thamel, Kathmandu",
            owner=self.owner,
            total_rooms=5,
        )

        # Assign Warden to Property
        PropertyWardenAssignment.objects.create(
            warden=self.warden,
            property=self.prop,
            can_manage_tenants=True,
            can_manage_rooms=True,
            can_view_payments=True,
        )

    def test_warden_assigned_properties_endpoint(self):
        response = self.client.get("/api/wardens/wardens/assigned/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "Kathmandu Residency")

    def test_room_and_bed_lifecycle(self):
        # 1. Create Room
        room_res = self.client.post(
            "/api/rooms/rooms/",
            {
                "pg": self.prop.id,
                "room_number": "101",
                "floor": "1st Floor",
                "room_type": "Double Shared",
                "capacity": 2,
                "rent_amount": 8000.0,
                "status": "available",
            },
            format="json",
        )
        self.assertEqual(room_res.status_code, status.HTTP_201_CREATED)
        room_id = room_res.data["id"]

        # 2. Create Bed
        bed_res = self.client.post(
            "/api/beds/beds/",
            {
                "pg": self.prop.id,
                "room": room_id,
                "label": "Bed 1",
                "rent": 8000.0,
                "status": "available",
            },
            format="json",
        )
        self.assertEqual(bed_res.status_code, status.HTTP_201_CREATED)
        bed_id = bed_res.data["id"]

        # 3. Create Tenant in that bed
        tenant_res = self.client.post(
            "/api/tenants/tenants/",
            {
                "pg": self.prop.id,
                "room": room_id,
                "bed": bed_id,
                "name": "Nitesh Adhikari",
                "phone": "9841999888",
                "email": "nitesh@gmail.com",
                "rent_amount": 8000.0,
                "security_deposit": 10000.0,
                "move_in_date": "2026-01-01",
                "status": "active",
            },
            format="json",
        )
        self.assertEqual(tenant_res.status_code, status.HTTP_201_CREATED)
        tenant_id = tenant_res.data["id"]

        # Verify bed is now occupied
        bed = Bed.objects.get(id=bed_id)
        self.assertEqual(bed.status, BedStatus.OCCUPIED)
        self.assertEqual(bed.tenant_id, tenant_id)

        # 4. Check out tenant -> bed becomes available again
        checkout_res = self.client.post(f"/api/tenants/tenants/{tenant_id}/checkout/")
        self.assertEqual(checkout_res.status_code, status.HTTP_200_OK)

        bed.refresh_from_db()
        self.assertEqual(bed.status, BedStatus.AVAILABLE)
        self.assertIsNone(bed.tenant)

    def test_invoice_and_payment_settlement(self):
        tenant = Tenant.objects.create(
            pg=self.prop,
            name="Sita Gurung",
            phone="9800001122",
            move_in_date=date(2026, 1, 1),
            rent_amount=9000.0,
        )

        # Create Invoice
        inv_res = self.client.post(
            "/api/invoices/invoices/",
            {
                "pg": self.prop.id,
                "tenant": tenant.id,
                "type": "rent",
                "amount": 9000.0,
                "paid_amount": 0.0,
                "status": "pending",
                "due_date": "2026-02-01",
            },
            format="json",
        )
        self.assertEqual(inv_res.status_code, status.HTTP_201_CREATED)
        inv_id = inv_res.data["id"]

        # Make payment against this invoice
        pay_res = self.client.post(
            "/api/payments/payments/",
            {
                "pg": self.prop.id,
                "tenant": tenant.id,
                "invoice": inv_id,
                "amount": 9000.0,
                "payment_date": "2026-01-25",
                "payment_method": "esewa",
                "reference": "ES-998811",
            },
            format="json",
        )
        self.assertEqual(pay_res.status_code, status.HTTP_201_CREATED)

        # Verify invoice is automatically marked as PAID
        inv = Invoice.objects.get(id=inv_id)
        self.assertEqual(inv.status, InvoiceStatus.PAID)
        self.assertEqual(float(inv.paid_amount), 9000.0)

    def test_dashboard_stats_calculation(self):
        stats_res = self.client.get(f"/api/dashboard/stats/?pg={self.prop.id}")
        self.assertEqual(stats_res.status_code, status.HTTP_200_OK)
        self.assertIn("total_collected", stats_res.data)
        self.assertIn("total_expenses", stats_res.data)
        self.assertIn("net_profit", stats_res.data)
        self.assertIn("occupancy_rate", stats_res.data)


class AuthorizationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.owner = User.objects.create_user(
            email="owner_auth@test.com", password="password123", name="Owner A", role="owner"
        )
        self.other_owner = User.objects.create_user(
            email="owner_b@test.com", password="password123", name="Owner B", role="owner"
        )
        self.warden = User.objects.create_user(
            email="warden_auth@test.com", password="password123", name="Warden A", role="warden"
        )
        self.prop = Property.objects.create(
            name="Auth Property", address="Somewhere", owner=self.owner, total_rooms=1
        )
        PropertyWardenAssignment.objects.create(
            warden=self.warden, property=self.prop, can_manage_tenants=True, can_manage_rooms=True
        )

    def test_unassigned_warden_cannot_see_other_property_rooms(self):
        login_res = self.client.post(
            "/api/auth/login/",
            {"username": "warden_auth@test.com", "password": "password123"},
            format="json",
        )
        token = login_res.data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

        response = self.client.get("/api/rooms/rooms/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)

    def test_owner_cannot_see_other_owner_properties(self):
        login_res = self.client.post(
            "/api/auth/login/",
            {"username": "owner_auth@test.com", "password": "password123"},
            format="json",
        )
        token = login_res.data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

        response = self.client.get("/api/properties/properties/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "Auth Property")

