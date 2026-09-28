from django.db import models
from properties.models import Property


class RoomStatus(models.TextChoices):
    AVAILABLE = "available", "Available"
    OCCUPIED = "occupied", "Occupied"
    MAINTENANCE = "maintenance", "Maintenance"


class Room(models.Model):
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        related_name="rooms",
        db_index=True,
    )
    room_number = models.CharField(max_length=50)
    floor = models.CharField(max_length=50, blank=True, default="1st Floor")
    room_type = models.CharField(max_length=50, blank=True, default="Standard")
    capacity = models.PositiveIntegerField(default=1)
    rent_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)
    status = models.CharField(
        max_length=20,
        choices=RoomStatus.choices,
        default=RoomStatus.AVAILABLE,
        db_index=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "rooms"
        verbose_name = "Room"
        verbose_name_plural = "Rooms"
        unique_together = ("pg", "room_number")
        ordering = ["room_number"]

    def __str__(self):
        return f"{self.room_number} - {self.pg.name}"

    @property
    def occupied_count(self):
        beds_count = self.beds.count()
        if beds_count > 0:
            return self.beds.filter(status="occupied").count()
        return self.tenants.filter(status="active").count()

    @property
    def is_full(self):
        return self.occupied_count >= self.capacity

