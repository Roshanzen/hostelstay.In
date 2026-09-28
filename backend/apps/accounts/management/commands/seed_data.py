from datetime import date, timedelta
from django.core.management.base import BaseCommand
from django.db import transaction

from accounts.models import User, UserRole, AccountStatus
from properties.models import Property, PropertyStatus
from wardens.models import PropertyWardenAssignment
from rooms.models import Room, RoomStatus
from beds.models import Bed, BedStatus
from tenants.models import Tenant, TenantStatus, IdType
from payments.models import (
    Invoice,
    InvoiceType,
    InvoiceStatus,
    Payment,
    PaymentMethod,
    Expense,
    ExpenseCategory,
    Meal,
    MealType,
    Utility,
    UtilityType,
)
from maintenance.models import MaintenanceTicket, TicketCategory, TicketPriority, TicketStatus
from notices.models import Notice, NoticeRoleTarget
from complaints.models import Complaint, ComplaintPriority, ComplaintStatus


class Command(BaseCommand):
    help = "Seeds database with initial production-like demo data for HMS/Warden application"

    def handle(self, *args, **options):
        self.stdout.write("Seeding database...")

        with transaction.atomic():
            # 1. Superuser / Owner
            owner, _ = User.objects.update_or_create(
                email="owner@hostelghar.com",
                defaults={
                    "name": "Bikash Shrestha",
                    "phone": "+977 9851000001",
                    "role": UserRole.OWNER,
                    "account_status": AccountStatus.ACTIVE,
                    "is_staff": True,
                    "is_superuser": True,
                },
            )
            owner.set_password("password123")
            owner.save()

            # 2. Warden User
            warden, _ = User.objects.update_or_create(
                email="warden@hostelghar.com",
                defaults={
                    "name": "Ram Bahadur Thapa",
                    "phone": "+977 9841234567",
                    "role": UserRole.WARDEN,
                    "account_status": AccountStatus.ACTIVE,
                    "is_staff": True,
                },
            )
            warden.set_password("password123")
            warden.save()

            # 3. Properties
            p1, _ = Property.objects.update_or_create(
                name="HostelGhar Thamel",
                defaults={
                    "address": "Thamel Marg, Ward 26, Kathmandu, Nepal",
                    "phone": "+977 1-4241000",
                    "email": "thamel@hostelghar.com",
                    "description": "Premium student & young professional hostel in Thamel.",
                    "total_rooms": 12,
                    "status": PropertyStatus.ACTIVE,
                    "owner": owner,
                },
            )

            p2, _ = Property.objects.update_or_create(
                name="HostelGhar Pulchowk",
                defaults={
                    "address": "Pulchowk Road, Lalitpur, Nepal",
                    "phone": "+977 1-5522000",
                    "email": "pulchowk@hostelghar.com",
                    "description": "Quiet engineering & college study residency.",
                    "total_rooms": 8,
                    "status": PropertyStatus.ACTIVE,
                    "owner": owner,
                },
            )

            # 4. Warden Assignment
            PropertyWardenAssignment.objects.update_or_create(
                warden=warden,
                property=p1,
                defaults={
                    "can_manage_tenants": True,
                    "can_manage_rooms": True,
                    "can_view_payments": True,
                    "can_manage_expenses": True,
                    "can_view_maintenance": True,
                    "can_view_reports": True,
                },
            )

            # 5. Rooms for Property 1
            r101, _ = Room.objects.update_or_create(
                pg=p1,
                room_number="101",
                defaults={
                    "floor": "1st Floor",
                    "room_type": "Double Shared",
                    "capacity": 2,
                    "rent_amount": 8500.0,
                    "status": RoomStatus.OCCUPIED,
                },
            )

            r102, _ = Room.objects.update_or_create(
                pg=p1,
                room_number="102",
                defaults={
                    "floor": "1st Floor",
                    "room_type": "Single Deluxe",
                    "capacity": 1,
                    "rent_amount": 12000.0,
                    "status": RoomStatus.OCCUPIED,
                },
            )

            r201, _ = Room.objects.update_or_create(
                pg=p1,
                room_number="201",
                defaults={
                    "floor": "2nd Floor",
                    "room_type": "Triple Shared",
                    "capacity": 3,
                    "rent_amount": 7500.0,
                    "status": RoomStatus.AVAILABLE,
                },
            )

            # 6. Beds
            b101_1, _ = Bed.objects.update_or_create(
                room=r101,
                label="Bed A",
                defaults={"pg": p1, "rent": 8500.0, "status": BedStatus.OCCUPIED},
            )
            b101_2, _ = Bed.objects.update_or_create(
                room=r101,
                label="Bed B",
                defaults={"pg": p1, "rent": 8500.0, "status": BedStatus.AVAILABLE},
            )

            b102_1, _ = Bed.objects.update_or_create(
                room=r102,
                label="Bed 1",
                defaults={"pg": p1, "rent": 12000.0, "status": BedStatus.OCCUPIED},
            )

            b201_1, _ = Bed.objects.update_or_create(
                room=r201,
                label="Bed 1",
                defaults={"pg": p1, "rent": 7500.0, "status": BedStatus.OCCUPIED},
            )
            b201_2, _ = Bed.objects.update_or_create(
                room=r201,
                label="Bed 2",
                defaults={"pg": p1, "rent": 7500.0, "status": BedStatus.AVAILABLE},
            )
            b201_3, _ = Bed.objects.update_or_create(
                room=r201,
                label="Bed 3",
                defaults={"pg": p1, "rent": 7500.0, "status": BedStatus.AVAILABLE},
            )

            # 7. Tenants
            t1, _ = Tenant.objects.update_or_create(
                phone="9841234567",
                defaults={
                    "pg": p1,
                    "room": r101,
                    "bed": b101_1,
                    "name": "Aarav Sharma",
                    "email": "aarav@gmail.com",
                    "emergency_contact": "9841112233",
                    "id_number": "27-01-76-01234",
                    "id_type": IdType.CITIZENSHIP,
                    "rent_amount": 8500.0,
                    "security_deposit": 10000.0,
                    "move_in_date": date(2024, 1, 15),
                    "status": TenantStatus.ACTIVE,
                    "guardian_name": "Hari Sharma",
                    "guardian_phone": "9841112233",
                    "address": "Pokhara, Kaski",
                },
            )
            b101_1.tenant = t1
            b101_1.save()

            t2, _ = Tenant.objects.update_or_create(
                phone="9801234567",
                defaults={
                    "pg": p1,
                    "room": r102,
                    "bed": b102_1,
                    "name": "Pooja Thapa",
                    "email": "pooja@gmail.com",
                    "emergency_contact": "9801112233",
                    "id_number": "06-01-74-05678",
                    "id_type": IdType.CITIZENSHIP,
                    "rent_amount": 12000.0,
                    "security_deposit": 15000.0,
                    "move_in_date": date(2024, 2, 1),
                    "status": TenantStatus.ACTIVE,
                    "guardian_name": "Krishna Thapa",
                    "guardian_phone": "9801112233",
                    "address": "Biratnagar, Morang",
                },
            )
            b102_1.tenant = t2
            b102_1.save()

            t3, _ = Tenant.objects.update_or_create(
                phone="9812345678",
                defaults={
                    "pg": p1,
                    "room": r201,
                    "bed": b201_1,
                    "name": "Rohan KC",
                    "email": "rohan@gmail.com",
                    "emergency_contact": "9812223344",
                    "id_number": "PP-982341",
                    "id_type": IdType.PASSPORT,
                    "rent_amount": 7500.0,
                    "security_deposit": 10000.0,
                    "move_in_date": date(2024, 3, 10),
                    "status": TenantStatus.ACTIVE,
                    "guardian_name": "Mina KC",
                    "guardian_phone": "9812223344",
                    "address": "Chitwan, Nepal",
                },
            )
            b201_1.tenant = t3
            b201_1.save()

            # 8. Invoices
            today = date.today()
            # Overdue invoice for Aarav
            inv1, _ = Invoice.objects.update_or_create(
                tenant=t1,
                billing_date=date(today.year, today.month, 1),
                defaults={
                    "pg": p1,
                    "room": r101,
                    "type": InvoiceType.RENT,
                    "amount": 9000.0,
                    "paid_amount": 0.0,
                    "status": InvoiceStatus.OVERDUE,
                    "due_date": today - timedelta(days=8),
                },
            )

            # Paid invoice for Pooja
            inv2, _ = Invoice.objects.update_or_create(
                tenant=t2,
                billing_date=date(today.year, today.month, 1),
                defaults={
                    "pg": p1,
                    "room": r102,
                    "type": InvoiceType.RENT,
                    "amount": 12000.0,
                    "paid_amount": 12000.0,
                    "status": InvoiceStatus.PAID,
                    "due_date": today + timedelta(days=10),
                },
            )

            # Payment for Pooja
            Payment.objects.update_or_create(
                invoice=inv2,
                defaults={
                    "pg": p1,
                    "tenant": t2,
                    "amount": 12000.0,
                    "payment_date": today - timedelta(days=2),
                    "payment_method": PaymentMethod.ESEWA,
                    "reference": "ES-98410291",
                },
            )

            # 9. Expenses
            Expense.objects.update_or_create(
                pg=p1,
                date=today - timedelta(days=5),
                category=ExpenseCategory.ELECTRICITY,
                defaults={
                    "amount": 4500.0,
                    "description": "NEA Electricity bill for block A",
                },
            )
            Expense.objects.update_or_create(
                pg=p1,
                date=today - timedelta(days=3),
                category=ExpenseCategory.GROCERY,
                defaults={
                    "amount": 8200.0,
                    "description": "Weekly mess food and vegetables",
                },
            )

            # 10. Maintenance Ticket
            MaintenanceTicket.objects.update_or_create(
                pg=p1,
                title="Geyser leakage in Room 101 bathroom",
                defaults={
                    "category": TicketCategory.PLUMBING,
                    "priority": TicketPriority.HIGH,
                    "status": TicketStatus.OPEN,
                    "description": "Water pipe joint leaking under geyser valve.",
                    "room": r101,
                    "tenant": t1,
                    "cost_incurred": 0.0,
                },
            )

            # 11. Notice
            Notice.objects.update_or_create(
                pg=p1,
                title="Monthly Gate Timing & Visitors Policy",
                defaults={
                    "content": "Hostel main gates close promptly at 9:30 PM. Overnight guests require warden clearance.",
                    "target_role": NoticeRoleTarget.ALL,
                    "is_published": True,
                    "created_by": warden,
                },
            )

        self.stdout.write(self.style.SUCCESS("Database successfully seeded with demo data!"))

