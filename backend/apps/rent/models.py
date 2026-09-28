from django.db import models
from properties.models import Property


class RentCycle(models.Model):
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        related_name="rent_cycles",
        db_index=True,
    )
    billing_month = models.CharField(max_length=7, db_index=True)  # Format: YYYY-MM
    generated_at = models.DateTimeField(auto_now_add=True)
    total_tenants_billed = models.PositiveIntegerField(default=0)
    total_amount_billed = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)

    class Meta:
        db_table = "rent_cycles"
        verbose_name = "Rent Cycle"
        verbose_name_plural = "Rent Cycles"
        unique_together = ("pg", "billing_month")
        ordering = ["-billing_month"]

    def __str__(self):
        return f"{self.pg.name} - {self.billing_month}"

