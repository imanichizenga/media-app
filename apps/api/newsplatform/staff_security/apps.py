from django.apps import AppConfig


class StaffSecurityConfig(AppConfig):
    name = "newsplatform.staff_security"

    def ready(self) -> None:
        from newsplatform.common import schema  # noqa: F401
        from newsplatform.staff_security import checks, staff  # noqa: F401
