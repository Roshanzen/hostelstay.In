from django.db import models
from properties.models import Property
from rooms.models import Room


class BedStatus(models.TextChoices):
    AVAILABLE = "available", "Available"
    OCCUPIED = "occupied", "Occupied"
    MAINTENANCE = "maintenance", "Maintenance"


class Bed(models.Model):
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        related_name="beds",
        db_index=True,
    )
    room = models.ForeignKey(
        Room,
        on_delete=models.CASCADE,
        related_name="beds",
        db_index=True,
    )
    label = models.CharField(max_length=50)
    rent = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)
    status = models.CharField(
        max_length=20,
        choices=BedStatus.choices,
        default=BedStatus.AVAILABLE,
        db_index=True,
    )
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="assigned_bed_records",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "beds"
        verbose_name = "Bed"
        verbose_name_plural = "Beds"
        unique_together = ("room", "label")
        ordering = ["room__room_number", "label"]

    def __str__(self):
        return f"{self.room.room_number} - {self.label}"

