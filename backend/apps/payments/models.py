from decimal import Decimal
from datetime import timedelta
from django.db import models
from django.conf import settings
from django.utils import timezone
from properties.models import Property
from tenants.models import Tenant
from rooms.models import Room


class InvoiceType(models.TextChoices):
    RENT = "rent", "Rent"
    UTILITY = "utility", "Utility"
    FINE = "fine", "Fine"
    MAINTENANCE = "maintenance", "Maintenance"
    DEPOSIT = "deposit", "Security Deposit"
    OTHER = "other", "Other"


class InvoiceStatus(models.TextChoices):
    DRAFT = "draft", "Draft"
    PENDING = "pending", "Pending"
    PAID = "paid", "Paid"
    OVERDUE = "overdue", "Overdue"
    CANCELLED = "cancelled", "Cancelled"
    PARTIAL = "partial", "Partial"
    VOID = "void", "Void"


class PaymentMethod(models.TextChoices):
    ESEWA = "esewa", "eSewa"
    KHALTI = "khalti", "Khalti"
    FONEPAY = "fonepay", "Fonepay"
    BANK_TRANSFER = "bankTransfer", "Bank Transfer"
    CASH = "cash", "Cash"
    OTHER = "other", "Other"


class ExpenseCategory(models.TextChoices):
    MAINTENANCE = "maintenance", "Maintenance"
    UTILITY = "utility", "Utility"
    GROCERY = "grocery", "Grocery"
    STAFF = "staff", "Staff"
    MARKETING = "marketing", "Marketing"
    TAX = "tax", "Tax"
    WATER = "water", "Water"
    ELECTRICITY = "electricity", "Electricity"
    OTHER = "other", "Other"


class Invoice(models.Model):
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        related_name="invoices",
        db_index=True,
    )
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name="invoices",
        db_index=True,
    )
    room = models.ForeignKey(
        Room,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="invoices",
    )
    bed = models.ForeignKey(
        "beds.Bed",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="invoices",
    )
    type = models.CharField(
        max_length=20,
        choices=InvoiceType.choices,
        default=InvoiceType.RENT,
    )
    # Billing period (for RENT invoices)
    period_start = models.DateField(null=True, blank=True, db_index=True)
    period_end = models.DateField(null=True, blank=True)
    # Unique human-readable invoice number
    invoice_number = models.CharField(max_length=30, unique=True, blank=True, default="")
    # Amounts
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    discount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0"))
    late_fee = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0"))
    paid_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0"))
    # Status
    status = models.CharField(
        max_length=20,
        choices=InvoiceStatus.choices,
        default=InvoiceStatus.PENDING,
        db_index=True,
    )
    grace_period_days = models.PositiveIntegerField(default=0)
    # Dates
    due_date = models.DateField(db_index=True)
    billing_date = models.DateField(null=True, blank=True)
    # Void tracking
    is_voided = models.BooleanField(default=False, db_index=True)
    voided_at = models.DateTimeField(null=True, blank=True)
    voided_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="voided_invoices",
    )
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "invoices"
        verbose_name = "Invoice"
        verbose_name_plural = "Invoices"
        ordering = ["-due_date", "-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["tenant", "type", "period_start", "period_end"],
                condition=models.Q(
                    type="rent",
                    period_start__isnull=False,
                    period_end__isnull=False,
                    is_voided=False,
                ),
                name="unique_rent_invoice_per_period",
            )
        ]

    def save(self, *args, **kwargs):
        if not self.invoice_number:
            from .billing_service import BillingService
            self.invoice_number = BillingService.generate_invoice_number()
        super().save(*args, **kwargs)

    def __str__(self):
        num = self.invoice_number or f"INV-{self.id}"
        return f"{num}: {self.tenant.name} - रु {self.amount}"


    @property
    def net_amount(self):
        """Base amount + late_fee - discount."""
        return max(Decimal("0"), self.amount + (self.late_fee or Decimal("0")) - (self.discount or Decimal("0")))

    @property
    def remaining_amount(self):
        return max(Decimal("0"), self.net_amount - (self.paid_amount or Decimal("0")))

    @property
    def is_overdue(self):
        today = timezone.localdate()
        return (
            not self.is_voided
            and self.status not in (InvoiceStatus.PAID, InvoiceStatus.CANCELLED, InvoiceStatus.VOID)
            and self.due_date < today
        )

    @property
    def effective_status(self):
        """Recompute status from balance + date + grace period."""
        if self.is_voided:
            return InvoiceStatus.VOID
        balance = self.remaining_amount
        if balance <= Decimal("0.01"):
            return InvoiceStatus.PAID
        if (self.paid_amount or Decimal("0")) > Decimal("0"):
            today = timezone.localdate()
            grace_deadline = self.due_date + timedelta(days=self.grace_period_days)
            if today > grace_deadline:
                return InvoiceStatus.OVERDUE
            return InvoiceStatus.PARTIAL
        today = timezone.localdate()
        grace_deadline = self.due_date + timedelta(days=self.grace_period_days)
        if today > grace_deadline:
            return InvoiceStatus.OVERDUE
        return InvoiceStatus.PENDING


class Payment(models.Model):
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        related_name="payments",
        db_index=True,
    )
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name="payments",
        db_index=True,
    )
    invoice = models.ForeignKey(
        Invoice,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="payments",
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    payment_date = models.DateField(db_index=True)
    payment_method = models.CharField(
        max_length=30,
        choices=PaymentMethod.choices,
        default=PaymentMethod.CASH,
    )
    reference = models.TextField(blank=True, default="")
    receipt_number = models.CharField(max_length=30, unique=True, blank=True, default="")
    notes = models.TextField(blank=True, default="")
    collected_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="collected_payments",
    )
    is_voided = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "payments"
        verbose_name = "Payment"
        verbose_name_plural = "Payments"
        ordering = ["-payment_date", "-created_at"]

    def save(self, *args, **kwargs):
        if not self.receipt_number:
            from .billing_service import BillingService
            self.receipt_number = BillingService.generate_receipt_number()
        super().save(*args, **kwargs)

    def __str__(self):
        num = self.receipt_number or f"PAY-{self.id}"
        return f"{num}: रु {self.amount} via {self.payment_method}"



class PaymentAllocation(models.Model):
    """Links one Payment to one Invoice with the allocated amount."""
    payment = models.ForeignKey(
        Payment,
        on_delete=models.CASCADE,
        related_name="allocations",
    )
    invoice = models.ForeignKey(
        Invoice,
        on_delete=models.CASCADE,
        related_name="allocations",
    )
    allocated_amount = models.DecimalField(max_digits=12, decimal_places=2)
    allocated_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "payment_allocations"
        verbose_name = "Payment Allocation"
        verbose_name_plural = "Payment Allocations"
        unique_together = ("payment", "invoice")
        ordering = ["allocated_at"]

    def __str__(self):
        return f"PAY-{self.payment_id} → INV-{self.invoice_id}: रु {self.allocated_amount}"


class AuditAction(models.TextChoices):
    INVOICE_CREATED = "invoice_created", "Invoice Created"
    INVOICE_UPDATED = "invoice_updated", "Invoice Updated"
    INVOICE_VOIDED = "invoice_voided", "Invoice Voided"
    PAYMENT_RECORDED = "payment_recorded", "Payment Recorded"
    PAYMENT_ALLOCATED = "payment_allocated", "Payment Allocated"
    PAYMENT_VOIDED = "payment_voided", "Payment Voided"
    STATUS_CHANGED = "status_changed", "Status Changed"


class AuditLog(models.Model):
    action = models.CharField(max_length=50, choices=AuditAction.choices, db_index=True)
    model_name = models.CharField(max_length=50)
    object_id = models.CharField(max_length=50)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="audit_logs",
    )
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="audit_logs",
    )
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)
    old_value = models.JSONField(null=True, blank=True)
    new_value = models.JSONField(null=True, blank=True)
    notes = models.TextField(blank=True, default="")

    class Meta:
        db_table = "billing_audit_logs"
        verbose_name = "Audit Log"
        verbose_name_plural = "Audit Logs"
        ordering = ["-timestamp"]

    def __str__(self):
        return f"{self.action} on {self.model_name} #{self.object_id} at {self.timestamp}"


class Expense(models.Model):
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        related_name="expenses",
        db_index=True,
    )
    category = models.CharField(
        max_length=30,
        choices=ExpenseCategory.choices,
        default=ExpenseCategory.OTHER,
        db_index=True,
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    date = models.DateField(db_index=True)
    description = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "expenses"
        verbose_name = "Expense"
        verbose_name_plural = "Expenses"
        ordering = ["-date", "-created_at"]

    def __str__(self):
        return f"{self.category.capitalize()}: रु {self.amount} on {self.date}"


class MealType(models.TextChoices):
    BREAKFAST = "breakfast", "Breakfast"
    LUNCH = "lunch", "Lunch"
    DINNER = "dinner", "Dinner"
    SNACK = "snack", "Snack"


class Meal(models.Model):
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        related_name="meals",
        db_index=True,
    )
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name="meals",
        db_index=True,
    )
    date = models.DateField(db_index=True)
    meal_type = models.CharField(
        max_length=20,
        choices=MealType.choices,
        default=MealType.LUNCH,
    )
    attended = models.BooleanField(default=True)
    is_extra = models.BooleanField(default=False)
    extra_charge = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        default=0.0,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "meals"
        verbose_name = "Meal"
        verbose_name_plural = "Meals"
        ordering = ["-date", "-created_at"]

    def __str__(self):
        return f"{self.meal_type.capitalize()} for {self.tenant.name} on {self.date}"


class UtilityType(models.TextChoices):
    ELECTRICITY = "electricity", "Electricity"
    WATER = "water", "Water"
    INTERNET = "internet", "Internet"
    GAS = "gas", "Gas"
    WASTE = "waste", "Waste"
    OTHER = "other", "Other"


class Utility(models.Model):
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        related_name="utilities",
        db_index=True,
    )
    utility_type = models.CharField(
        max_length=30,
        choices=UtilityType.choices,
        default=UtilityType.ELECTRICITY,
    )
    units = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)
    rate = models.DecimalField(max_digits=10, decimal_places=2, default=1.0)
    billing_date = models.DateField(db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "utilities"
        verbose_name = "Utility"
        verbose_name_plural = "Utilities"
        ordering = ["-billing_date", "-created_at"]

    def __str__(self):
        return f"{self.utility_type.capitalize()} on {self.billing_date} - {self.pg.name}"

    @property
    def total_amount(self):
        return float(self.units * self.rate)
