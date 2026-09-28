from rest_framework import serializers
from django.db import transaction
from datetime import timedelta
from django.utils import timezone
from .models import Tenant, TenantStatus
from beds.models import Bed, BedStatus
from rooms.models import Room, RoomStatus
from payments.models import Invoice, InvoiceType, InvoiceStatus, Payment, PaymentMethod


class TenantSerializer(serializers.ModelSerializer):
    room_number = serializers.ReadOnlyField()
    bed_label = serializers.ReadOnlyField()
    outstanding_balance = serializers.ReadOnlyField()

    class Meta:
        model = Tenant
        fields = [
            "id",
            "pg",
            "room",
            "room_number",
            "bed",
            "bed_label",
            "name",
            "phone",
            "email",
            "emergency_contact",
            "id_number",
            "id_type",
            "id_image_path",
            "rent_amount",
            "security_deposit",
            "deposit_deductions",
            "move_in_date",
            "contract_start_date",
            "contract_end_date",
            "status",
            # Billing configuration
            "billing_frequency",
            "grace_period_days",
            "late_fee_type",
            "late_fee_value",
            "discount",
            "guardian_name",
            "guardian_phone",
            "address",
            "outstanding_balance",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


    def to_internal_value(self, data):
        data_copy = data.copy() if hasattr(data, "copy") else dict(data)

        # 1. Resolve PG if passed as string or not provided
        pg_val = data_copy.get("pg")
        if pg_val:
            try:
                pg_id = int(pg_val)
                data_copy["pg"] = pg_id
            except (ValueError, TypeError):
                pass
        else:
            request = self.context.get("request")
            if request:
                query_pg = request.query_params.get("pg") or request.query_params.get("property")
                if query_pg:
                    try:
                        data_copy["pg"] = int(query_pg)
                    except (ValueError, TypeError):
                        pass

        resolved_pg = data_copy.get("pg")

        # 2. Resolve room (either PK or room_number string within the PG)
        room_val = data_copy.get("room")
        if room_val is not None:
            room_pk = None
            try:
                room_pk = int(room_val)
                if not Room.objects.filter(id=room_pk).exists():
                    room_pk = None
            except (ValueError, TypeError):
                room_pk = None

            if room_pk is None:
                cleaned_num = str(room_val).replace("Room", "").strip()
                room_qs = Room.objects.all()
                if resolved_pg:
                    room_qs = room_qs.filter(pg_id=resolved_pg)
                room_obj = room_qs.filter(room_number__iexact=cleaned_num).first()
                if room_obj:
                    data_copy["room"] = room_obj.pk
                    if not resolved_pg:
                        data_copy["pg"] = room_obj.pg_id
                        resolved_pg = room_obj.pg_id
            else:
                data_copy["room"] = room_pk

        # 3. Resolve bed (either PK or bed label string within the room)
        bed_val = data_copy.get("bed")
        if bed_val is not None and str(bed_val).strip() != "":
            bed_pk = None
            try:
                bed_pk = int(bed_val)
                if not Bed.objects.filter(id=bed_pk).exists():
                    bed_pk = None
            except (ValueError, TypeError):
                bed_pk = None

            if bed_pk is None:
                cleaned_label = str(bed_val).replace("Bed", "").strip()
                bed_qs = Bed.objects.all()
                resolved_room_id = data_copy.get("room")
                if resolved_room_id:
                    bed_qs = bed_qs.filter(room_id=resolved_room_id)
                elif resolved_pg:
                    bed_qs = bed_qs.filter(pg_id=resolved_pg)

                bed_obj = bed_qs.filter(label__iexact=cleaned_label).first()
                if not bed_obj and cleaned_label:
                    bed_obj = bed_qs.filter(label__iexact=f"Bed {cleaned_label}").first()

                if bed_obj:
                    data_copy["bed"] = bed_obj.pk
                    if not data_copy.get("room"):
                        data_copy["room"] = bed_obj.room_id
                    if not resolved_pg:
                        data_copy["pg"] = bed_obj.pg_id
            else:
                data_copy["bed"] = bed_pk

        # 4. Normalize ID type
        id_type = data_copy.get("id_type")
        if id_type:
            id_str = str(id_type).lower()
            if "passport" in id_str:
                data_copy["id_type"] = "passport"
            elif "license" in id_str:
                data_copy["id_type"] = "drivingLicense"
            elif "national" in id_str:
                data_copy["id_type"] = "nationalId"
            elif "student" in id_str:
                data_copy["id_type"] = "studentId"
            elif "citizenship" in id_str:
                data_copy["id_type"] = "citizenship"
            else:
                data_copy["id_type"] = "other"

        return super().to_internal_value(data_copy)

    def validate(self, attrs):
        bed = attrs.get("bed")
        room = attrs.get("room")
        pg = attrs.get("pg")

        if bed:
            if not room:
                room = bed.room
                attrs["room"] = room
            elif bed.room_id != room.id:
                raise serializers.ValidationError(
                    {"bed": [f"Bed '{bed.label}' does not belong to Room '{room.room_number}'."]}
                )

            if not pg:
                pg = bed.pg
                attrs["pg"] = pg
            elif bed.pg_id != pg.id:
                raise serializers.ValidationError(
                    {"bed": ["Selected bed does not belong to the selected property."]}
                )

            # Check if bed is already occupied (allow unchanged bed during update)
            is_same_tenant = self.instance and self.instance.bed_id == bed.id
            if not is_same_tenant and bed.status == BedStatus.OCCUPIED:
                raise serializers.ValidationError(
                    {"bed": [f"Bed '{bed.label}' in Room '{room.room_number}' is already occupied. Please select an available bed."]}
                )

        if room and pg and room.pg_id != pg.id:
            raise serializers.ValidationError(
                {"room": ["Selected room does not belong to the selected property."]}
            )

        return attrs

    def create(self, validated_data):
        with transaction.atomic():
            bed = validated_data.get("bed")
            room = validated_data.get("room")
            if bed and not room:
                validated_data["room"] = bed.room
                room = bed.room

            # 1. Concurrency lock on bed row
            locked_bed = None
            if bed:
                locked_bed = Bed.objects.select_for_update().get(id=bed.id)
                if locked_bed.status == BedStatus.OCCUPIED and locked_bed.tenant is not None:
                    raise serializers.ValidationError(
                        {"bed": [f"Bed '{locked_bed.label}' was just occupied by another admission. Please select another bed."]}
                    )

            # 2. Create tenant
            tenant = super().create(validated_data)

            # 3. Update Bed status and tenant assignment atomically
            if locked_bed:
                locked_bed.status = BedStatus.OCCUPIED
                locked_bed.tenant = tenant
                locked_bed.save(update_fields=["status", "tenant", "updated_at"])
            elif tenant.bed:
                Bed.objects.filter(id=tenant.bed.id).update(
                    status=BedStatus.OCCUPIED,
                    tenant=tenant,
                )

            # 4. Update Room status if full
            if tenant.room:
                r = Room.objects.select_for_update().get(id=tenant.room.id)
                occ_beds = r.beds.filter(status=BedStatus.OCCUPIED).count()
                if r.is_full or (r.beds.count() >= r.capacity and occ_beds >= r.capacity):
                    r.status = RoomStatus.OCCUPIED
                else:
                    r.status = RoomStatus.AVAILABLE
                r.save(update_fields=["status", "updated_at"])

            # 5. Financials: create move-in invoices using BillingService
            from payments.billing_service import BillingService
            from payments.models import Invoice, InvoiceType, InvoiceStatus

            rent = tenant.rent_amount or 0
            deposit = tenant.security_deposit or 0
            move_in_date = tenant.move_in_date or timezone.localdate()

            # 5a. Security deposit invoice (if any)
            if deposit > 0:
                deposit_inv_number = BillingService.generate_invoice_number()
                dep_inv = Invoice.objects.create(
                    pg=tenant.pg,
                    tenant=tenant,
                    room=tenant.room,
                    bed=tenant.bed,
                    type=InvoiceType.DEPOSIT,
                    invoice_number=deposit_inv_number,
                    amount=deposit,
                    paid_amount=deposit,  # mark deposit as received
                    status=InvoiceStatus.PAID,
                    due_date=move_in_date,
                    billing_date=move_in_date,
                    notes="Security deposit collected on move-in.",
                )
                from payments.models import Payment, PaymentAllocation, PaymentMethod
                rcp_num = BillingService.generate_receipt_number()
                dep_pay = Payment.objects.create(
                    pg=tenant.pg,
                    tenant=tenant,
                    invoice=dep_inv,
                    amount=deposit,
                    payment_date=move_in_date,
                    payment_method=PaymentMethod.CASH,
                    receipt_number=rcp_num,
                    notes="Security deposit collected on move-in.",
                )
                PaymentAllocation.objects.create(
                    payment=dep_pay,
                    invoice=dep_inv,
                    allocated_amount=deposit,
                )

            # 5b. First rent invoice via BillingService (idempotent)
            if rent > 0:
                start = tenant.contract_start_date or move_in_date
                freq = tenant.billing_frequency or "monthly"
                p_start, p_end, due = BillingService.get_period_dates(start, freq, 0)
                BillingService.get_or_create_rent_invoice(
                    tenant, p_start, p_end, due,
                    created_by=getattr(self, "_request_user", None),
                )

            return tenant


    def update(self, instance, validated_data):
        with transaction.atomic():
            old_bed = instance.bed
            new_bed = validated_data.get("bed", old_bed)
            new_status = validated_data.get("status", instance.status)

            # Lock new bed if changing bed
            if new_bed and new_bed != old_bed:
                locked_new_bed = Bed.objects.select_for_update().get(id=new_bed.id)
                if locked_new_bed.status == BedStatus.OCCUPIED and locked_new_bed.tenant != instance:
                    raise serializers.ValidationError(
                        {"bed": [f"Bed '{locked_new_bed.label}' is already occupied."]}
                    )

            tenant = super().update(instance, validated_data)

            # If bed changed, release old bed
            if old_bed and old_bed != new_bed:
                Bed.objects.filter(id=old_bed.id).update(
                    status=BedStatus.AVAILABLE,
                    tenant=None,
                )

            # If new bed assigned and active
            if new_bed and new_status == TenantStatus.ACTIVE:
                Bed.objects.filter(id=new_bed.id).update(
                    status=BedStatus.OCCUPIED,
                    tenant=tenant,
                )
            elif new_bed and new_status != TenantStatus.ACTIVE:
                # If moved out or inactive, release bed
                Bed.objects.filter(id=new_bed.id).update(
                    status=BedStatus.AVAILABLE,
                    tenant=None,
                )

            # Update room status
            if tenant.room:
                r = Room.objects.select_for_update().get(id=tenant.room.id)
                occ_beds = r.beds.filter(status=BedStatus.OCCUPIED).count()
                if r.is_full or (r.beds.count() >= r.capacity and occ_beds >= r.capacity):
                    r.status = RoomStatus.OCCUPIED
                else:
                    r.status = RoomStatus.AVAILABLE
                r.save(update_fields=["status", "updated_at"])

            return tenant

