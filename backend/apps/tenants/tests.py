from decimal import Decimal
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model

from properties.models import Property
from rooms.models import Room, RoomStatus
from beds.models import Bed, BedStatus
from tenants.models import Tenant, TenantStatus
from payments.models import Invoice, Payment, InvoiceStatus

User = get_user_model()


class TenantAdmissionTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="owner@example.com",
            phone="9800000001",
            role="owner",
            password="testpassword123",
        )
        self.client.force_authenticate(user=self.user)

        self.property = Property.objects.create(
            name="Test Sunshine Hostel",
            owner=self.user,
            total_rooms=5,
        )
        self.room = Room.objects.create(
            pg=self.property,
            room_number="A",
            capacity=2,
            rent_amount=Decimal("12000.00"),
        )
        self.bed_a = Bed.objects.create(
            pg=self.property,
            room=self.room,
            label="A",
            status=BedStatus.OCCUPIED,
        )
        self.bed_b = Bed.objects.create(
            pg=self.property,
            room=self.room,
            label="B",
            status=BedStatus.AVAILABLE,
        )

    def test_successful_tenant_admission(self):
        payload = {
            "pg": self.property.id,
            "room": self.room.id,
            "bed": self.bed_b.id,
            "name": "Roshan",
            "phone": "+977 9800112233",
            "id_number": "12345",
            "id_type": "citizenship",
            "rent_amount": 12000,
            "security_deposit": 12000,
            "move_in_date": "2026-09-25",
            "status": "active",
        }
        res = self.client.post("/api/tenants/tenants/", payload)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(res.data.get("success"))

        # Verify bed is now occupied
        self.bed_b.refresh_from_db()
        self.assertEqual(self.bed_b.status, BedStatus.OCCUPIED)
        self.assertIsNotNone(self.bed_b.tenant)
        self.assertEqual(self.bed_b.tenant.name, "Roshan")

        # Verify room status
        self.room.refresh_from_db()
        self.assertEqual(self.room.status, RoomStatus.OCCUPIED)

        # Verify invoices created (deposit + rent)
        invs = Invoice.objects.filter(tenant=self.bed_b.tenant)
        self.assertEqual(sum(i.amount for i in invs), Decimal("24000.00"))
        self.assertEqual(sum(i.paid_amount for i in invs), Decimal("12000.00"))

        # Verify payment created
        pay = Payment.objects.filter(tenant=self.bed_b.tenant).first()
        self.assertIsNotNone(pay)
        self.assertEqual(pay.amount, Decimal("12000.00"))

    def test_admission_resolves_string_room_and_bed(self):
        payload = {
            "pg": self.property.id,
            "room": "A",
            "bed": "B",
            "name": "Roshan String IDs",
            "phone": "+977 9800112244",
            "id_number": "54321",
            "id_type": "citizenship",
            "rent_amount": 12000,
            "security_deposit": 12000,
            "move_in_date": "2026-09-25",
            "status": "active",
        }
        res = self.client.post("/api/tenants/tenants/", payload)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data.get("bed"), self.bed_b.id)

    def test_reject_already_occupied_bed(self):
        # bed_a is already occupied in setUp
        payload = {
            "pg": self.property.id,
            "room": self.room.id,
            "bed": self.bed_a.id,
            "name": "Second Tenant",
            "phone": "+977 9800112255",
            "move_in_date": "2026-09-25",
        }
        res = self.client.post("/api/tenants/tenants/", payload)
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("bed", res.data.get("errors", {}))

    def test_tenant_checkout_releases_bed(self):
        payload = {
            "pg": self.property.id,
            "room": self.room.id,
            "bed": self.bed_b.id,
            "name": "Roshan To Checkout",
            "phone": "+977 9800112266",
            "move_in_date": "2026-09-25",
            "status": "active",
        }
        res = self.client.post("/api/tenants/tenants/", payload)
        tenant_id = res.data["id"]

        # Checkout
        checkout_res = self.client.post(f"/api/tenants/tenants/{tenant_id}/checkout/")
        self.assertEqual(checkout_res.status_code, status.HTTP_200_OK)

        self.bed_b.refresh_from_db()
        self.assertEqual(self.bed_b.status, BedStatus.AVAILABLE)
        self.assertIsNone(self.bed_b.tenant)
