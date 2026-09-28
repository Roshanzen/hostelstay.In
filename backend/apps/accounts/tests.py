from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

User = get_user_model()


class AuthTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email="warden@test.com",
            password="password123",
            name="Test Warden",
            role="warden",
        )

    def test_login_success(self):
        response = self.client.post(
            "/api/auth/login/",
            {"username": "warden@test.com", "password": "password123"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)
        self.assertEqual(response.data["user"]["email"], "warden@test.com")

    def test_login_invalid_credentials(self):
        response = self.client.post(
            "/api/auth/login/",
            {"username": "warden@test.com", "password": "wrongpassword"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_success(self):
        response = self.client.post(
            "/api/auth/register/",
            {
                "name": "New Owner",
                "email": "newowner@test.com",
                "password": "password123",
                "password_confirm": "password123",
                "role": "owner",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("access", response.data)
        self.assertEqual(response.data["user"]["email"], "newowner@test.com")
        self.assertEqual(response.data["user"]["role"], "tenant")

    def test_register_ignores_client_role(self):
        response = self.client.post(
            "/api/auth/register/",
            {
                "name": "Hacker",
                "email": "hacker@test.com",
                "password": "password123",
                "password_confirm": "password123",
                "role": "owner",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["user"]["role"], "tenant")

    def test_current_user_me(self):
        login_res = self.client.post(
            "/api/auth/login/",
            {"username": "warden@test.com", "password": "password123"},
            format="json",
        )
        token = login_res.data["access"]

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
        response = self.client.get("/api/auth/me/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["email"], "warden@test.com")

    def test_current_user_patch_rejects_role_change(self):
        login_res = self.client.post(
            "/api/auth/login/",
            {"username": "warden@test.com", "password": "password123"},
            format="json",
        )
        token = login_res.data["access"]

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
        response = self.client.patch(
            "/api/auth/me/",
            {"role": "owner", "account_status": "inactive"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.role, "warden")
        self.assertEqual(self.user.account_status, "active")

    def test_password_reset_requires_email_backend(self):
        response = self.client.post(
            "/api/auth/password-reset/",
            {"email": "warden@test.com"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

