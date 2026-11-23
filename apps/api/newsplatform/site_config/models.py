from django.conf import settings
from django.db import models

from newsplatform.common.models import BaseModel


class SettingsSection(BaseModel):
    key = models.SlugField(max_length=32, unique=True)
    version = models.PositiveIntegerField(default=1)
    data = models.JSONField(default=dict)
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+"
    )

    def __str__(self) -> str:
        return f"{self.key} v{self.version}"
