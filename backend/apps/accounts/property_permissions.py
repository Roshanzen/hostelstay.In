from typing import Iterable

from django.db.models import QuerySet

from accounts.models import User
from properties.models import Property
from wardens.models import PropertyWardenAssignment


def authorized_property_ids(user: User) -> Iterable[int]:
    if user.is_superuser:
        return Property.objects.all().values_list("pk", flat=True)

    owned = list(Property.objects.filter(owner=user).values_list("pk", flat=True))
    assigned = list(
        PropertyWardenAssignment.objects.filter(warden=user).values_list(
            "property_id", flat=True
        )
    )
    return list(set(owned + assigned))



def filter_queryset_by_property(user: User, queryset: QuerySet, property_field: str = "pg_id") -> QuerySet:
    allowed = authorized_property_ids(user)
    if not allowed and not user.is_superuser:
        return queryset.none()
    return queryset.filter(**{f"{property_field}__in": allowed})


def assert_property_membership(user: User, property_id: int) -> bool:
    allowed = authorized_property_ids(user)
    return property_id in allowed
