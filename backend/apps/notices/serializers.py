from rest_framework import serializers
from .models import Notice


class NoticeSerializer(serializers.ModelSerializer):
    author_name = serializers.ReadOnlyField(source="created_by.name")
    property_name = serializers.ReadOnlyField(source="pg.name")

    class Meta:
        model = Notice
        fields = [
            "id",
            "pg",
            "property_name",
            "title",
            "content",
            "target_role",
            "is_published",
            "created_by",
            "author_name",
            "expires_at",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_by", "created_at", "updated_at"]

    def create(self, validated_data):
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)

