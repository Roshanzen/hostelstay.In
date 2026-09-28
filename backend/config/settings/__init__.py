import os

_settings_module = os.getenv("DJANGO_SETTINGS_MODULE", "config.settings")
if _settings_module == "config.settings.production":
    from .production import *  # noqa: F401,F403
else:
    from .base import *  # noqa: F401,F403

