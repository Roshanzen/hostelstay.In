from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from properties.models import Property
from wardens.models import PropertyWardenAssignment
from rooms.models import Room
from beds.models import Bed
from tenants.models import Tenant, TenantStatus
from payments.models import Payment, Expense, Invoice, InvoiceStatus

User = get_user_model()


class WebDashboardAndOwnerTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.owner = User.objects.create_user(
            email="owner@test.com",
            password="password123",
            name="Roshan",
            role="owner",
            is_staff=True,
        )
        self.warden = User.objects.create_user(
            email="warden@test.com",
            password="password123",
            name="Test Warden",
            role="warden",
            is_staff=True,
        )
        self.tenant_user = User.objects.create_user(
            email="tenant@test.com",
            password="password123",
            name="Test Resident",
            role="tenant",
            is_staff=False,
        )
        self.property = Property.objects.create(
            name="Max boys hostel",
            address="kathmandu",
            phone="9807778303",
            owner=self.owner,
            total_rooms=30,
        )

    def test_smart_root_html_redirects_to_login(self):
        response = self.client.get("/", HTTP_ACCEPT="text/html,application/xhtml+xml")
        self.assertEqual(response.status_code, 302)
        self.assertIn("/login/", response.url)

    def test_smart_root_json_returns_endpoints(self):
        response = self.client.get("/", HTTP_ACCEPT="application/json")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("endpoints", data)
        self.assertEqual(data["message"], "HostelGhar HMS API")

    def test_login_page_renders(self):
        response = self.client.get("/login/")
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "PG Manager")
        self.assertContains(response, "Owner Sign In")
        self.assertContains(response, "Register as Owner")

    def test_register_page_renders(self):
        response = self.client.get("/register/")
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "PG Manager")
        self.assertContains(response, "Create First Owner Account")

    def test_owner_registration_success(self):
        response = self.client.post("/register/", {
            "name": "Roshan Yadav",
            "email": "roshan.new@pgmanager.com",
            "phone": "9807778303",
            "password": "password123",
            "password_confirm": "password123",
            "property_name": "sunshine boys hostel",
            "property_address": "mahadevstahn koteshwor",
            "property_rooms": "23",
        }, follow=True)

        self.assertEqual(response.status_code, 200)
        user = User.objects.filter(email="roshan.new@pgmanager.com").first()
        self.assertIsNotNone(user)
        self.assertEqual(user.name, "Roshan Yadav")
        self.assertEqual(user.role, "owner")
        self.assertTrue(user.is_staff)

        # Check property was created dynamically
        prop = Property.objects.filter(owner=user, name="sunshine boys hostel").first()
        self.assertIsNotNone(prop)
        self.assertEqual(prop.total_rooms, 23)

        # Check dashboard loaded with welcome message and property
        self.assertContains(response, "Welcome back, Roshan Yadav!")
        self.assertContains(response, "sunshine boys hostel")

    def test_owner_login_success(self):
        response = self.client.post("/login/", {
            "identifier": "owner@test.com",
            "password": "password123",
        }, follow=True)
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.context["user"].is_authenticated)
        self.assertEqual(response.context["user"].email, "owner@test.com")
        self.assertContains(response, "Welcome back, Roshan!")

    def test_tenant_cannot_access_owner_portal(self):
        response = self.client.post("/login/", {
            "identifier": "tenant@test.com",
            "password": "password123",
        })
        self.assertEqual(response.status_code, 200)
        self.assertFalse(self.client.session.get("_auth_user_id"))

    def test_dashboard_dynamic_data(self):
        # Create rooms, beds, tenant, payment, expense for owner's property
        room = Room.objects.create(pg=self.property, room_number="101", capacity=2, rent_amount=8000)
        bed1 = Bed.objects.create(pg=self.property, room=room, label="Bed 1A", rent=8000, status="occupied")
        bed2 = Bed.objects.create(pg=self.property, room=room, label="Bed 1B", rent=8000, status="available")
        tenant = Tenant.objects.create(
            pg=self.property,
            room=room,
            bed=bed1,
            name="Aayush Nepal",
            phone="9811111111",
            move_in_date="2026-09-01",
            status="active"
        )
        Payment.objects.create(
            pg=self.property,
            tenant=tenant,
            amount=8000,
            payment_date="2026-09-01",
            payment_method="esewa",
        )
        Expense.objects.create(
            pg=self.property,
            category="groceries",
            amount=2500,
            date="2026-09-02",
            description="Monthly pantry items",
        )
        PropertyWardenAssignment.objects.create(
            property=self.property,
            warden=self.warden,
        )

        self.client.login(email="owner@test.com", password="password123")
        response = self.client.get("/dashboard/")
        self.assertEqual(response.status_code, 200)

        # Check stat values
        stats = response.context["stats"]
        self.assertEqual(stats["total_properties"], 1)
        self.assertEqual(stats["total_wardens"], 1)
        self.assertEqual(stats["total_tenants"], 1)
        self.assertEqual(stats["total_rooms"], 1)
        self.assertEqual(stats["total_beds"], 2)
        self.assertEqual(stats["occupied_beds"], 1)
        self.assertEqual(stats["available_beds"], 1)
        self.assertEqual(stats["total_payments"], 1)
        self.assertEqual(stats["total_payments_amount"], 8000.0)
        self.assertEqual(stats["total_expenses"], 1)
        self.assertEqual(stats["total_expenses_amount"], 2500.0)

        # Check properties table rendering
        self.assertContains(response, "Max boys hostel")
        self.assertContains(response, "kathmandu")
        self.assertContains(response, "9807778303")

    def test_property_create_view_post(self):
        self.client.login(email="owner@test.com", password="password123")
        response = self.client.post("/dashboard/properties/create/", {
            "name": "sunshine boys hostel",
            "address": "mahadevstahn koteshwor",
            "phone": "9807778303",
            "total_rooms": "23",
            "description": "Clean hostel with WiFi",
        }, follow=True)
        self.assertEqual(response.status_code, 200)

        created_prop = Property.objects.filter(name="sunshine boys hostel").first()
        self.assertIsNotNone(created_prop)
        self.assertEqual(created_prop.total_rooms, 23)
        self.assertEqual(created_prop.address, "mahadevstahn koteshwor")

    def test_invite_new_warden(self):
        self.client.login(email="owner@test.com", password="password123")
        response = self.client.post("/dashboard/wardens/invite/", {
            "property_id": self.property.id,
            "name": "Warden Ramesh",
            "email": "ramesh@hostel.com",
            "phone": "9809999999",
            "password": "password123",
        }, follow=True)
        self.assertEqual(response.status_code, 200)

        new_warden = User.objects.filter(email="ramesh@hostel.com").first()
        self.assertIsNotNone(new_warden)
        self.assertEqual(new_warden.role, "warden")

        assignment = PropertyWardenAssignment.objects.filter(
            property=self.property,
            warden=new_warden,
        ).first()
        self.assertIsNotNone(assignment)

    def test_all_sidebar_pages(self):
        self.client.login(email="owner@test.com", password="password123")
        pages = [
            "/dashboard/",
            "/dashboard/properties/",
            f"/dashboard/properties/{self.property.id}/",
            "/dashboard/wardens/",
            "/dashboard/tenants/",
            "/dashboard/rooms/",
            "/dashboard/beds/",
            "/dashboard/payments/",
            "/dashboard/expenses/",
            "/dashboard/invoices/",
            "/dashboard/utilities/",
            "/dashboard/maintenance/",
            "/dashboard/meals/",
            "/dashboard/security-deposits/",
            "/dashboard/reports/",
            "/dashboard/activity/",
        ]
        for url in pages:
            res = self.client.get(url)
            self.assertEqual(res.status_code, 200, f"Page {url} failed with {res.status_code}")
