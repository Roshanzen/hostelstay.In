from decimal import Decimal
from datetime import date, timedelta
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone

from properties.models import Property
from rooms.models import Room
from beds.models import Bed
from tenants.models import Tenant, TenantStatus, BillingFrequency
from payments.models import (
    Invoice, Payment, PaymentAllocation, AuditLog,
    InvoiceStatus, InvoiceType, PaymentMethod,
)
from payments.billing_service import BillingService

User = get_user_model()


class BillingServiceTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            phone="9800000000",
            email="owner@test.com",
            password="testpassword",
            role="owner",
        )
        self.pg = Property.objects.create(
            name="Test PG",
            address="Kathmandu",
            owner=self.user,
        )
        self.room = Room.objects.create(
            pg=self.pg,
            room_number="101",
            floor="1",
            capacity=2,
            rent_amount=Decimal("10000.00"),
        )
        self.bed = Bed.objects.create(
            pg=self.pg,
            room=self.room,
            label="Bed 1",
            rent=Decimal("10000.00"),
        )

        self.tenant = Tenant.objects.create(
            pg=self.pg,
            room=self.room,
            bed=self.bed,
            name="Aayush Sharma",
            phone="9812345678",
            rent_amount=Decimal("10000.00"),
            security_deposit=Decimal("5000.00"),
            move_in_date=date(2026, 1, 1),
            contract_start_date=date(2026, 1, 1),
            contract_end_date=date(2026, 6, 30),
            billing_frequency=BillingFrequency.MONTHLY,
            grace_period_days=5,
            status=TenantStatus.ACTIVE,
        )

    def test_invoice_and_receipt_number_generation(self):
        inv_num1 = BillingService.generate_invoice_number()
        inv_num2 = BillingService.generate_invoice_number()
        self.assertTrue(inv_num1.startswith("INV-"))
        self.assertTrue(inv_num2.startswith("INV-"))

        rcp_num1 = BillingService.generate_receipt_number()
        rcp_num2 = BillingService.generate_receipt_number()
        self.assertTrue(rcp_num1.startswith("RCP-"))
        self.assertTrue(rcp_num2.startswith("RCP-"))

    def test_period_dates_monthly(self):
        start, end, due = BillingService.get_period_dates(date(2026, 1, 1), "monthly", 0)
        self.assertEqual(start, date(2026, 1, 1))
        self.assertEqual(end, date(2026, 1, 31))
        self.assertEqual(due, date(2026, 1, 1))

        start1, end1, due1 = BillingService.get_period_dates(date(2026, 1, 1), "monthly", 1)
        self.assertEqual(start1, date(2026, 2, 1))
        self.assertEqual(end1, date(2026, 2, 28))

    def test_get_or_create_rent_invoice_idempotence(self):
        start, end, due = BillingService.get_period_dates(self.tenant.contract_start_date, "monthly", 0)
        inv1, created1 = BillingService.get_or_create_rent_invoice(self.tenant, start, end, due)
        self.assertTrue(created1)
        self.assertIsNotNone(inv1)
        self.assertEqual(inv1.amount, Decimal("10000.00"))
        self.assertEqual(inv1.status, InvoiceStatus.PENDING)

        # Re-calling should return existing invoice
        inv2, created2 = BillingService.get_or_create_rent_invoice(self.tenant, start, end, due)
        self.assertFalse(created2)
        self.assertEqual(inv1.id, inv2.id)

    def test_contract_end_guard(self):
        # Tenant contract ends 2026-06-30
        beyond_start = date(2026, 7, 1)
        beyond_end = date(2026, 7, 31)
        inv, created = BillingService.get_or_create_rent_invoice(self.tenant, beyond_start, beyond_end, beyond_start)
        self.assertFalse(created)
        self.assertIsNone(inv)

    def test_payment_allocation_partial_and_multi_invoice(self):
        # Create invoice 1 (Jan): 10,000
        inv1, _ = BillingService.get_or_create_rent_invoice(
            self.tenant, date(2026, 1, 1), date(2026, 1, 31), date(2026, 1, 1)
        )
        # Create invoice 2 (Feb): 10,000
        inv2, _ = BillingService.get_or_create_rent_invoice(
            self.tenant, date(2026, 2, 1), date(2026, 2, 28), date(2026, 2, 1)
        )

        # Pay partial: 6,000
        pay1 = Payment.objects.create(
            pg=self.pg,
            tenant=self.tenant,
            amount=Decimal("6000.00"),
            payment_date=date(2026, 1, 5),
            payment_method=PaymentMethod.CASH,
            receipt_number=BillingService.generate_receipt_number(),
        )
        allocs1 = BillingService.allocate_payment(pay1)
        self.assertEqual(len(allocs1), 1)
        inv1.refresh_from_db()
        self.assertEqual(inv1.paid_amount, Decimal("6000.00"))
        self.assertEqual(inv1.status, InvoiceStatus.PARTIAL)
        self.assertEqual(inv1.remaining_amount, Decimal("4000.00"))

        # Pay remaining on inv1 + full inv2: 4,000 + 10,000 = 14,000
        pay2 = Payment.objects.create(
            pg=self.pg,
            tenant=self.tenant,
            amount=Decimal("14000.00"),
            payment_date=date(2026, 2, 2),
            payment_method=PaymentMethod.ESEWA,
            receipt_number=BillingService.generate_receipt_number(),
        )
        allocs2 = BillingService.allocate_payment(pay2)
        self.assertEqual(len(allocs2), 2)
        inv1.refresh_from_db()
        inv2.refresh_from_db()
        self.assertEqual(inv1.status, InvoiceStatus.PAID)
        self.assertEqual(inv1.paid_amount, Decimal("10000.00"))
        self.assertEqual(inv2.status, InvoiceStatus.PAID)
        self.assertEqual(inv2.paid_amount, Decimal("10000.00"))

    def test_overdue_refresh(self):
        past_due = timezone.localdate() - timedelta(days=20)
        inv = Invoice.objects.create(
            pg=self.pg,
            tenant=self.tenant,
            room=self.room,
            type=InvoiceType.RENT,
            invoice_number=BillingService.generate_invoice_number(),
            amount=Decimal("10000.00"),
            paid_amount=Decimal("0"),
            status=InvoiceStatus.PENDING,
            due_date=past_due,
            grace_period_days=5,
        )
        updated = BillingService.refresh_invoice_statuses(self.pg.id)
        self.assertEqual(updated, 1)
        inv.refresh_from_db()
        self.assertEqual(inv.status, InvoiceStatus.OVERDUE)
