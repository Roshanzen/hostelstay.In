from django.db import models
from django.conf import settings
from properties.models import Property


class NoticeRoleTarget(models.TextChoices):
    ALL = "all", "All"
    WARDEN = "warden", "Wardens"
    TENANT = "tenant", "Tenants"


class Notice(models.Model):
    pg = models.ForeignKey(
        Property,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="notices",
        db_index=True,
    )
    title = models.CharField(max_length=255)
    content = models.TextField()
    target_role = models.CharField(
        max_length=20,
        choices=NoticeRoleTarget.choices,
        default=NoticeRoleTarget.ALL,
    )
    is_published = models.BooleanField(default=True, db_index=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="authored_notices",
    )
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "notices"
        verbose_name = "Notice"
        verbose_name_plural = "Notices"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} - {self.pg.name if self.pg else 'All Properties'}"

