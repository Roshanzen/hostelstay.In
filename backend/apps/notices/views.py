from rest_framework import viewsets, permissions
from .models import Notice
from .serializers import NoticeSerializer
from accounts.permissions import IsOwnerOrWarden
from accounts.property_permissions import filter_queryset_by_property


class NoticeViewSet(viewsets.ModelViewSet):
    serializer_class = NoticeSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ["pg", "target_role", "is_published"]
    search_fields = ["title", "content"]
    ordering_fields = ["created_at", "expires_at"]

    def get_queryset(self):
        qs = Notice.objects.select_related("pg", "created_by").all()
        user = self.request.user
        pg_id = self.request.query_params.get("pg") or self.request.query_params.get("property")

        if user.is_tenant:
            qs = qs.filter(is_published=True, target_role__in=["all", "tenant"])
        else:
            qs = filter_queryset_by_property(user, qs)
            if pg_id:
                qs = qs.filter(pg_id=pg_id)

        return qs

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [permissions.IsAuthenticated(), IsOwnerOrWarden()]
        return [permissions.IsAuthenticated()]

