from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db import transaction

from .models import PropertyWardenAssignment
from .serializers import (
    PropertyWardenAssignmentSerializer,
    InviteWardenSerializer,
    AssignWardenSerializer,
)
from accounts.models import User, UserRole, AccountStatus
from accounts.serializers import UserSerializer
from accounts.permissions import IsOwner, IsWarden, IsOwnerOrWarden
from accounts.property_permissions import authorized_property_ids
from properties.models import Property
from properties.serializers import PropertySerializer


class WardenViewSet(viewsets.ModelViewSet):
    serializer_class = PropertyWardenAssignmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = PropertyWardenAssignment.objects.select_related("warden", "property").all()
        allowed_prop_ids = list(authorized_property_ids(self.request.user))
        if not allowed_prop_ids and not self.request.user.is_superuser:
            return PropertyWardenAssignment.objects.none()
        return qs.filter(property_id__in=allowed_prop_ids)

    @action(detail=False, methods=["get"], url_path="assigned")
    def assigned(self, request):
        """Returns properties assigned to current authenticated warden (or owned if owner)."""
        if request.user.is_superuser:
            properties = Property.objects.filter(status="active")
        elif request.user.is_owner:
            properties = Property.objects.filter(owner=request.user, status="active")
        else:
            assignments = PropertyWardenAssignment.objects.filter(
                warden=request.user,
                property__status="active",
            ).select_related("property")
            properties = [a.property for a in assignments]
        serializer = PropertySerializer(properties, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=False, methods=["get"], url_path="available")
    def available(self, request):
        """Returns wardens not yet assigned to the specified property."""
        pg_id = request.query_params.get("pg") or request.query_params.get("property")
        if not pg_id:
            return Response(
                {"detail": "Property ID is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        allowed_prop_ids = list(authorized_property_ids(request.user))
        if pg_id not in allowed_prop_ids and not request.user.is_superuser:
            return Response(
                {"detail": "You are not authorized for this property."},
                status=status.HTTP_403_FORBIDDEN,
            )

        assigned_user_ids = PropertyWardenAssignment.objects.filter(
            property_id=pg_id
        ).values_list("warden_id", flat=True)

        users = User.objects.filter(role=UserRole.WARDEN).exclude(id__in=assigned_user_ids)
        serializer = UserSerializer(users, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @action(detail=False, methods=["post"], url_path="invite")
    def invite(self, request):
        """Creates or invites a warden and assigns them to the property."""
        serializer = InviteWardenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        prop = data["property"]

        allowed_prop_ids = list(authorized_property_ids(request.user))
        if prop.id not in allowed_prop_ids and not request.user.is_superuser:
            return Response(
                {"detail": "You are not authorized for this property."},
                status=status.HTTP_403_FORBIDDEN,
            )

        with transaction.atomic():
            warden = data.get("warden")
            if not warden:
                email = data["email"].strip()
                warden = User.objects.filter(email__iexact=email).first()
                if not warden:
                    warden = User.objects.create_user(
                        email=email,
                        password=data["password"],
                        name=data["name"].strip(),
                        phone=data.get("phone", "").strip(),
                        role=UserRole.WARDEN,
                        account_status=AccountStatus.ACTIVE,
                    )

            assignment, _ = PropertyWardenAssignment.objects.update_or_create(
                warden=warden,
                property=prop,
                defaults={
                    "can_manage_tenants": data.get("can_manage_tenants", True),
                    "can_manage_rooms": data.get("can_manage_rooms", True),
                    "can_view_payments": data.get("can_view_payments", True),
                    "can_manage_expenses": data.get("can_manage_expenses", True),
                    "can_view_maintenance": data.get("can_view_maintenance", True),
                    "can_view_reports": data.get("can_view_reports", True),
                },
            )

        res_serializer = PropertyWardenAssignmentSerializer(assignment)
        return Response(res_serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=["post"], url_path="assign")
    def assign(self, request):
        serializer = AssignWardenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        prop = data["property"]

        allowed_prop_ids = list(authorized_property_ids(request.user))
        if prop.id not in allowed_prop_ids and not request.user.is_superuser:
            return Response(
                {"detail": "You are not authorized for this property."},
                status=status.HTTP_403_FORBIDDEN,
            )

        assignment, created = PropertyWardenAssignment.objects.update_or_create(
            warden=data["warden"],
            property=prop,
            defaults={
                "can_manage_tenants": data.get("can_manage_tenants", True),
                "can_manage_rooms": data.get("can_manage_rooms", True),
                "can_view_payments": data.get("can_view_payments", True),
                "can_manage_expenses": data.get("can_manage_expenses", True),
                "can_view_maintenance": data.get("can_view_maintenance", True),
                "can_view_reports": data.get("can_view_reports", True),
            },
        )
        res_serializer = PropertyWardenAssignmentSerializer(assignment)
        return Response(res_serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)

    @action(detail=False, methods=["delete"], url_path="remove")
    def remove(self, request):
        warden_id = request.query_params.get("warden")
        property_id = request.query_params.get("property") or request.query_params.get("pg")

        if not warden_id or not property_id:
            return Response(
                {"detail": "Both warden and property parameters are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        allowed_prop_ids = list(authorized_property_ids(request.user))
        try:
            prop_id_int = int(property_id)
        except ValueError:
            prop_id_int = None

        if prop_id_int not in allowed_prop_ids and not request.user.is_superuser:
            return Response(
                {"detail": "You are not authorized for this property."},
                status=status.HTTP_403_FORBIDDEN,
            )

        PropertyWardenAssignment.objects.filter(
            warden_id=warden_id, property_id=property_id
        ).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=["delete"], url_path="delete-warden")
    def delete_warden(self, request):
        if not request.user.is_owner and not request.user.is_superuser:
            return Response(
                {"detail": "Only owners can delete warden accounts."},
                status=status.HTTP_403_FORBIDDEN,
            )
        warden_id = request.query_params.get("warden")
        if not warden_id:
            return Response(
                {"detail": "warden parameter is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        User.objects.filter(id=warden_id, role=UserRole.WARDEN).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    def partial_update(self, request, *args, **kwargs):
        instance = self.get_object()
        allowed_prop_ids = list(authorized_property_ids(request.user))
        if instance.property_id not in allowed_prop_ids and not request.user.is_superuser:
            return Response(
                {"detail": "You are not authorized for this assignment."},
                status=status.HTTP_403_FORBIDDEN,
            )

        account_status = request.data.get("account_status")
        if account_status:
            instance.warden.account_status = account_status
            instance.warden.save(update_fields=["account_status"])

        return super().partial_update(request, *args, **kwargs)


class MyAssignedPropertiesView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        assignments = PropertyWardenAssignment.objects.filter(
            warden=request.user
        ).select_related("property")
        serializer = PropertyWardenAssignmentSerializer(assignments, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class MyPermissionsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        pg_id = request.query_params.get("pg") or request.query_params.get("property")
        if not pg_id:
            return Response(
                {"detail": "pg query parameter is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        allowed_prop_ids = list(authorized_property_ids(request.user))
        try:
            pg_id_int = int(pg_id)
        except ValueError:
            pg_id_int = None

        if pg_id_int not in allowed_prop_ids and not request.user.is_superuser:
            return Response(
                {
                    "warden": str(request.user.id),
                    "pg": str(pg_id),
                    "can_manage_tenants": False,
                    "can_manage_rooms": False,
                    "can_view_payments": False,
                    "can_manage_expenses": False,
                    "can_view_maintenance": False,
                    "can_view_reports": False,
                },
                status=status.HTTP_200_OK,
            )

        # Owners have full permissions
        if request.user.is_owner or request.user.is_superuser:
            return Response(
                {
                    "warden": str(request.user.id),
                    "pg": str(pg_id),
                    "can_manage_tenants": True,
                    "can_manage_rooms": True,
                    "can_view_payments": True,
                    "can_manage_expenses": True,
                    "can_view_maintenance": True,
                    "can_view_reports": True,
                },
                status=status.HTTP_200_OK,
            )

        assignment = PropertyWardenAssignment.objects.filter(
            warden=request.user, property_id=pg_id
        ).first()

        if not assignment:
            return Response(
                {
                    "warden": str(request.user.id),
                    "pg": str(pg_id),
                    "can_manage_tenants": False,
                    "can_manage_rooms": False,
                    "can_view_payments": False,
                    "can_manage_expenses": False,
                    "can_view_maintenance": False,
                    "can_view_reports": False,
                },
                status=status.HTTP_200_OK,
            )

        return Response(
            {
                "warden": str(request.user.id),
                "pg": str(pg_id),
                "can_manage_tenants": assignment.can_manage_tenants,
                "can_manage_rooms": assignment.can_manage_rooms,
                "can_view_payments": assignment.can_view_payments,
                "can_manage_expenses": assignment.can_manage_expenses,
                "can_view_maintenance": assignment.can_view_maintenance,
                "can_view_reports": assignment.can_view_reports,
            },
            status=status.HTTP_200_OK,
        )

