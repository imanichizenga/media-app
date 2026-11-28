from typing import Any

from django.conf import settings
from django.core.checks import Error, register


@register()
def deployed_environment_is_hardened(app_configs: Any, **_: Any) -> list[Error]:
    if not settings.IS_DEPLOYED:
        return []
    rules = {
        "E001": (settings.STAFF_COOKIE_SECURE, "Staff cookies must be Secure with the __Host- prefix"),
        "E002": (bool(settings.KMS_KEY_ARN), "KMS_KEY_ARN is required"),
        "E003": (not settings.LOCAL_ENCRYPTION_KEY, "LOCAL_ENCRYPTION_KEY must not be set"),
        "E004": (not settings.AWS_ENDPOINT_URL, "AWS_ENDPOINT_URL must not be set"),
        "E008": (not settings.STORAGE_ENDPOINT_URL, "STORAGE_ENDPOINT_URL must not be set"),
        "E009": (not settings.LOCAL_TRANSCODER, "LOCAL_TRANSCODER must not be set"),
        "E016": (not settings.LOCAL_SMS, "LOCAL_SMS must not be set"),
        "E017": (not settings.LOCAL_PAYMENTS, "LOCAL_PAYMENTS must not be set"),
        "E010": (not settings.LOCAL_SCANNER, "LOCAL_SCANNER must not be set"),
        "E011": (not settings.LOCAL_WEB_ORIGIN, "LOCAL_WEB_ORIGIN must not be set"),
        "E005": (settings.ADMIN_ORIGIN.startswith("https://"), "ADMIN_ORIGIN must be https"),
        "E006": (not settings.DEBUG, "DEBUG must be off"),
        "E007": (len(settings.SECRET_KEY) >= 50, "DJANGO_SECRET_KEY is too short"),
    }
    return [Error(msg, id=f"staff_security.{code}") for code, (ok, msg) in rules.items() if not ok]
