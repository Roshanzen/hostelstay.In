import os

import pymysql
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Checks the configured MySQL database connection without exposing the password"

    def handle(self, *args, **options):
        db_engine = os.getenv("DB_ENGINE", "django.db.backends.mysql")
        db_name = os.getenv("DB_NAME")
        db_user = os.getenv("DB_USER", "root")
        db_password = os.getenv("DB_PASSWORD", "")
        db_host = os.getenv("DB_HOST", "127.0.0.1")
        db_port = os.getenv("DB_PORT", "3306")

        self.stdout.write(f"Database: {db_name}")
        self.stdout.write(f"Host: {db_host}")
        self.stdout.write(f"Port: {db_port}")
        self.stdout.write(f"User: {db_user}")

        if db_engine != "django.db.backends.mysql":
            self.stdout.write(self.style.WARNING("Expected MySQL backend but found: " + db_engine))
            return

        try:
            conn = pymysql.connect(
                host=db_host,
                port=int(db_port),
                user=db_user,
                password=db_password,
                charset="utf8mb4",
                connect_timeout=5,
            )
            with conn.cursor() as cursor:
                cursor.execute("SELECT 1")
            conn.close()
            self.stdout.write(self.style.SUCCESS("Connection: SUCCESS"))
        except pymysql.MySQLError as e:
            self.stdout.write(self.style.ERROR(f"Connection: FAILED ({e})"))
