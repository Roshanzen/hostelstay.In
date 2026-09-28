import logging
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status

logger = logging.getLogger(__name__)


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is not None:
        errors = {}
        message = "An error occurred."

        if isinstance(response.data, dict):
            if "detail" in response.data:
                message = str(response.data["detail"])
                errors = {"detail": [message]}
            else:
                errors = response.data
                # Pick first error as message
                first_key = next(iter(response.data), None)
                if first_key:
                    first_val = response.data[first_key]
                    if isinstance(first_val, list) and len(first_val) > 0:
                        message = f"{first_key}: {first_val[0]}"
                    else:
                        message = f"{first_key}: {first_val}"
        elif isinstance(response.data, list):
            message = response.data[0] if len(response.data) > 0 else "Validation error"
            errors = {"non_field_errors": response.data}

        custom_data = {
            "success": False,
            "message": message,
            "detail": message,
            "errors": errors,
        }
        response.data = custom_data
        return response

    # Unhandled 500 exceptions
    logger.exception(f"Unhandled server exception: {exc}")
    return Response(
        {
            "success": False,
            "message": "Internal server error. Please try again later.",
            "detail": "Internal server error. Please try again later.",
            "errors": {"server": ["An unexpected error occurred on the server."]},
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )

