from django.db import models
from decimal import Decimal
from django.conf import settings
from properties.models import Property
from rooms.models import Room
from beds.models import Bed


class BillingFrequency(models.TextChoices):
    MONTHLY = "monthly", "Monthly"
    QUARTERLY = "quarterly", "Quarterly"
    HALF_YEARLY = "half_yearly", "Half-Yearly"
    YEARLY = "yearly", "Yearly"


class LateFeeType(models.TextChoices):
    NONE = "none", "None"
    FIXED = "fixed", "Fixed Amount"
    PERCENTAGE = "percentage", "Percentage"


class IdType(models.TextChoices):
    CITIZENSHIP = "citizenship", "Citizenship"
    PASSPORT = "passport", "Passport"
    DRIVING_LICENSE = "drivingLicense", "Driving License"
    NATIONAL_ID = "nationalId", "National ID"
    STUDENT_ID = "studentId", "Student ID"
    OTHER = "other", "Other"


class TenantStatus(models.TextChoices):
    ACTIVE = "active", "Active"
    INACTIVE = "inactive", "Inactive"
    NOTICE = "notice", "Notice"
    GRADUATED = "graduated", "Graduated"


class Tenant(models.Model):
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        related_name="tenants",
        db_index=True,
    )
    room = models.ForeignKey(
        Room,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="tenants",
        db_index=True,
    )
    bed = models.ForeignKey(
        Bed,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="current_tenants",
        db_index=True,
    )
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="tenant_profile",
    )
    name = models.CharField(max_length=255)
    phone = models.CharField(max_length=50)
    email = models.EmailField(blank=True, default="")
    emergency_contact = models.CharField(max_length=255, blank=True, default="")
    id_number = models.CharField(max_length=100, blank=True, default="")
    id_type = models.CharField(
        max_length=50,
        choices=IdType.choices,
        default=IdType.CITIZENSHIP,
    )
    id_image_path = models.TextField(blank=True, default="")
    rent_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)
    security_deposit = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)
    deposit_deductions = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)
    move_in_date = models.DateField()
    contract_start_date = models.DateField(null=True, blank=True)
    contract_end_date = models.DateField(null=True, blank=True)
    status = models.CharField(
        max_length=20,
        choices=TenantStatus.choices,
        default=TenantStatus.ACTIVE,
        db_index=True,
    )
    # Billing configuration
    billing_frequency = models.CharField(
        max_length=20,
        choices=BillingFrequency.choices,
        default=BillingFrequency.MONTHLY,
    )
    grace_period_days = models.PositiveIntegerField(default=5)
    late_fee_type = models.CharField(
        max_length=20,
        choices=LateFeeType.choices,
        default=LateFeeType.NONE,
    )
    late_fee_value = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal("0"))
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal("0"))
    guardian_name = models.CharField(max_length=255, blank=True, default="")
    guardian_phone = models.CharField(max_length=50, blank=True, default="")
    address = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


    class Meta:
        db_table = "tenants"
        verbose_name = "Tenant"
        verbose_name_plural = "Tenants"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.name} ({self.phone}) - {self.pg.name}"

    @property
    def room_number(self):
        return self.room.room_number if self.room else ""

    @property
    def bed_label(self):
        return self.bed.label if self.bed else ""

    @property
    def outstanding_balance(self):
        # Calculate unpaid/overdue amount from invoices
        from payments.models import Invoice, InvoiceStatus
        invoices = Invoice.objects.filter(tenant=self).exclude(status=InvoiceStatus.PAID)
        return sum(inv.remaining_amount for inv in invoices)

