from django.db import models
from properties.models import Property
from rooms.models import Room
from tenants.models import Tenant


class TicketCategory(models.TextChoices):
    PLUMBING = "plumbing", "Plumbing"
    ELECTRICAL = "electrical", "Electrical"
    FURNITURE = "furniture", "Furniture"
    APPLIANCE = "appliance", "Appliance"
    CLEANING = "cleaning", "Cleaning"
    PEST = "pest", "Pest"
    OTHER = "other", "Other"


class TicketPriority(models.TextChoices):
    LOW = "low", "Low"
    MEDIUM = "medium", "Medium"
    HIGH = "high", "High"
    URGENT = "urgent", "Urgent"


class TicketStatus(models.TextChoices):
    OPEN = "open", "Open"
    IN_PROGRESS = "inProgress", "In Progress"
    RESOLVED = "resolved", "Resolved"
    CANCELLED = "cancelled", "Cancelled"


class MaintenanceTicket(models.Model):
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        related_name="maintenance_tickets",
        db_index=True,
    )
    title = models.CharField(max_length=255)
    category = models.CharField(
        max_length=30,
        choices=TicketCategory.choices,
        default=TicketCategory.OTHER,
        db_index=True,
    )
    priority = models.CharField(
        max_length=20,
        choices=TicketPriority.choices,
        default=TicketPriority.MEDIUM,
        db_index=True,
    )
    status = models.CharField(
        max_length=20,
        choices=TicketStatus.choices,
        default=TicketStatus.OPEN,
        db_index=True,
    )
    description = models.TextField(blank=True, default="")
    room = models.ForeignKey(
        Room,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="maintenance_tickets",
    )
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="maintenance_tickets",
    )
    cost_incurred = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        default=0.0,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "maintenance_tickets"
        verbose_name = "Maintenance Ticket"
        verbose_name_plural = "Maintenance Tickets"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} ({self.status}) - {self.pg.name}"

