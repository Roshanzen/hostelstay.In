from properties.models import Property


def dashboard_context(request):
    """
    Supplies active property and owner properties globally across templates
    for the top header, sidebar switcher, and quick modal selects.
    """
    if not request.user.is_authenticated:
        return {}

    user = request.user
    if user.is_superuser:
        props = Property.objects.all().order_by("-created_at")
    elif user.is_owner or user.is_staff:
        props = Property.objects.filter(owner=user).order_by("-created_at")
    else:
        props = Property.objects.none()

    active_prop_id = request.GET.get("property_id")
    active_prop = None

    if active_prop_id:
        active_prop = props.filter(id=active_prop_id).first()

    if not active_prop and props.exists():
        active_prop = props.first()

    return {
        "global_properties": props,
        "global_active_property": active_prop,
    }
