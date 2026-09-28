from django.db import models
from django.conf import settings
from properties.models import Property


class PropertyWardenAssignment(models.Model):
    warden = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="warden_assignments",
    )
    property = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        related_name="warden_assignments",
    )
    can_manage_tenants = models.BooleanField(default=True)
    can_manage_rooms = models.BooleanField(default=True)
    can_view_payments = models.BooleanField(default=True)
    can_manage_expenses = models.BooleanField(default=True)
    can_view_maintenance = models.BooleanField(default=True)
    can_view_reports = models.BooleanField(default=True)
    assigned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "property_warden_assignments"
        verbose_name = "Property Warden Assignment"
        verbose_name_plural = "Property Warden Assignments"
        unique_together = ("warden", "property")

    def __str__(self):
        return f"{self.warden.name} -> {self.property.name}"

