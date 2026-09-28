from django.core.management.base import BaseCommand
from django.conf import settings
import os


class Command(BaseCommand):
    help = "Run production-like deployment checks"

    def handle(self, *args, **options):
        errors = []

        if settings.DEBUG:
            errors.append("DEBUG must be False in production.")

        if not settings.SECRET_KEY or settings.SECRET_KEY.startswith("django-insecure"):
            errors.append("SECRET_KEY is insecure or missing.")

        if not settings.ALLOWED_HOSTS:
            errors.append("ALLOWED_HOSTS is empty.")

        if settings.CORS_ALLOW_ALL_ORIGINS:
            errors.append("CORS_ALLOW_ALL_ORIGINS must be False in production.")

        if not settings.CORS_ALLOWED_ORIGINS:
            errors.append("CORS_ALLOWED_ORIGINS is empty.")

        db = settings.DATABASES["default"]
        if db["ENGINE"] == "django.db.backends.sqlite3":
            errors.append("SQLite must not be used in production.")

        if errors:
            self.stderr.write("Production deployment check failed:")
            for err in errors:
                self.stderr.write(f" - {err}")
            raise SystemExit(1)

        self.stdout.write("Production deployment checks passed.")
