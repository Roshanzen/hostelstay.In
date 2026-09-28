import os
import pymysql
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Creates the configured MySQL database if it does not already exist"

    def handle(self, *args, **options):
        db_name = os.getenv("DB_NAME", "hms")
        db_user = os.getenv("DB_USER", "root")
        db_password = os.getenv("DB_PASSWORD", "")
        db_host = os.getenv("DB_HOST", "127.0.0.1")
        db_port = int(os.getenv("DB_PORT", "3306"))

        self.stdout.write(f"Connecting to MySQL server at {db_host}:{db_port} as user '{db_user}'...")

        try:
            conn = pymysql.connect(
                host=db_host,
                port=db_port,
                user=db_user,
                password=db_password,
                charset="utf8mb4",
                cursorclass=pymysql.cursors.DictCursor,
            )
            with conn.cursor() as cursor:
                cursor.execute(
                    f"CREATE DATABASE IF NOT EXISTS `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
                )
                self.stdout.write(self.style.SUCCESS(f"Database `{db_name}` is ready!"))
            conn.close()
        except pymysql.MySQLError as e:
            self.stdout.write(
                self.style.WARNING(
                    f"Could not automatically create MySQL database: {e}\n"
                    f"Please ensure MySQL is running and set your DB credentials in backend/.env:\n"
                    f"DB_NAME={db_name}\nDB_USER={db_user}\nDB_PASSWORD=your_password\n"
                    f"Then run:\n"
                    f"python manage.py setup_mysql\n"
                    f"python manage.py migrate\n"
                    f"python manage.py seed_data"
                )
            )

