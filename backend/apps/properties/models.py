from django.db import models
from django.conf import settings


class PropertyStatus(models.TextChoices):
    ACTIVE = "active", "Active"
    INACTIVE = "inactive", "Inactive"
    ARCHIVED = "archived", "Archived"


class Property(models.Model):
    name = models.CharField(max_length=255)
    address = models.TextField(blank=True, default="")
    phone = models.CharField(max_length=50, blank=True, default="")
    email = models.EmailField(blank=True, default="")
    description = models.TextField(blank=True, default="")
    total_rooms = models.PositiveIntegerField(default=0)
    status = models.CharField(
        max_length=20,
        choices=PropertyStatus.choices,
        default=PropertyStatus.ACTIVE,
        db_index=True,
    )
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="owned_properties",
        db_index=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "properties"
        verbose_name = "Property"
        verbose_name_plural = "Properties"
        ordering = ["-created_at"]

    def __str__(self):
        return self.name

    @property
    def total_beds(self):
        # Calculate from rooms or beds
        from beds.models import Bed
        count = Bed.objects.filter(pg=self).count()
        if count > 0:
            return count
        from rooms.models import Room
        return sum(Room.objects.filter(pg=self).values_list("capacity", flat=True))

    @property
    def occupied_beds(self):
        from beds.models import Bed, BedStatus
        beds_qs = Bed.objects.filter(pg=self)
        if beds_qs.exists():
            return beds_qs.filter(status=BedStatus.OCCUPIED).count()
        from tenants.models import Tenant
        assigned = Tenant.objects.filter(pg=self, status="active", bed__isnull=False).count()
        if assigned > 0:
            return min(self.total_beds, assigned)
        return min(self.total_beds, Tenant.objects.filter(pg=self, status="active").count())

    @property
    def vacant_beds(self):
        return max(0, self.total_beds - self.occupied_beds)

    @property
    def occupancy_rate(self):
        total = self.total_beds
        if total > 0:
            return min(100.0, round((self.occupied_beds / total) * 100, 1))
        return 0.0


