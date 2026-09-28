from rest_framework import status, permissions, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from django.db import transaction

from .models import User, UserRole, AccountStatus, PasswordResetToken, AccountDeletionRequest
from .serializers import (
    UserSerializer,
    RegisterSerializer,
    LoginSerializer,
    PasswordResetRequestSerializer,
    ChangePasswordSerializer,
    PasswordResetConfirmSerializer,
)
from .permissions import IsOwner


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        refresh = RefreshToken.for_user(user)
        refresh["role"] = user.role
        refresh["email"] = user.email
        refresh["name"] = user.name

        return Response(
            {
                "success": True,
                "message": "Account created successfully.",
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": UserSerializer(user).data,
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        return Response(
            {
                "success": True,
                "message": "Logged in successfully.",
                "access": data["access"],
                "refresh": data["refresh"],
                "user": data["user"],
            },
            status=status.HTTP_200_OK,
        )


class CurrentUserView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def patch(self, request):
        mutable_data = request.data.copy()
        mutable_data.pop("role", None)
        mutable_data.pop("account_status", None)
        mutable_data.pop("is_staff", None)
        mutable_data.pop("is_superuser", None)
        mutable_data.pop("username", None)
        serializer = UserSerializer(request.user, data=mutable_data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)


class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return Response(
                {"detail": "Refresh token is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response(
                {"success": True, "detail": "Successfully logged out."},
                status=status.HTTP_200_OK,
            )
        except TokenError:
            return Response(
                {"detail": "Invalid or expired refresh token."},
                status=status.HTTP_400_BAD_REQUEST,
            )


class PasswordResetRequestView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"].strip()
        user = User.objects.filter(email__iexact=email).first()

        if user:
            token = PasswordResetToken.objects.create(
                user=user,
                token=PasswordResetToken.generate_token(),
                expires_at=timezone.now() + timezone.timedelta(hours=1),
            )

            reset_url = f"{getattr(settings, 'FRONTEND_URL', 'http://localhost:3000')}/reset-password?token={token.token}"
            subject = "Password Reset Request"
            message = (
                f"Hello {user.name},\n\n"
                f"Click the link below to reset your password:\n{reset_url}\n\n"
                "This link will expire in 1 hour.\n"
                "If you did not request this, please ignore this email."
            )

            try:
                send_mail(
                    subject=subject,
                    message=message,
                    from_email=getattr(settings, "DEFAULT_FROM_EMAIL", "no-reply@example.com"),
                    recipient_list=[user.email],
                    fail_silently=False,
                )
            except Exception as exc:
                if not getattr(settings, "EMAIL_BACKEND", None):
                    raise RuntimeError(
                        "Password reset email is not configured. Set EMAIL_BACKEND and related settings."
                    ) from exc
                raise

        return Response(
            {
                "success": True,
                "detail": "If an account exists with this email, password reset instructions have been sent.",
            },
            status=status.HTTP_200_OK,
        )


class PasswordResetConfirmView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        reset_token = PasswordResetToken.objects.filter(token=data["token"]).first()
        if not reset_token or not reset_token.is_valid():
            return Response(
                {"detail": "Invalid or expired reset token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = reset_token.user
        user.set_password(data["new_password"])
        user.save(update_fields=["password"])

        reset_token.is_used = True
        reset_token.save(update_fields=["is_used"])

        return Response(
            {"success": True, "detail": "Password has been reset successfully."},
            status=status.HTTP_200_OK,
        )


class ChangePasswordView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        request.user.set_password(serializer.validated_data["new_password"])
        request.user.save()
        return Response(
            {"success": True, "detail": "Password has been updated successfully."},
            status=status.HTTP_200_OK,
        )


class AccountDeleteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        password = request.data.get("password")
        if not password or not request.user.check_password(password):
            return Response(
                {"detail": "Current password is incorrect."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        with transaction.atomic():
            AccountDeletionRequest.objects.create(user=request.user)
            request.user.is_active = False
            request.user.account_status = AccountStatus.SUSPENDED
            request.user.email = f"deleted_{request.user.id}@deleted.invalid"
            request.user.username = None
            request.user.phone = ""
            request.user.name = "Deleted User"
            request.user.save(
                update_fields=["is_active", "account_status", "email", "username", "phone", "name"]
            )

        return Response(
            {"success": True, "detail": "Account deletion has been initiated."},
            status=status.HTTP_200_OK,
        )


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsOwner]
    filterset_fields = ["role", "account_status"]
    search_fields = ["name", "email", "phone"]
