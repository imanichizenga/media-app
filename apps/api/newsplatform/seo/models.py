from django.db import models
from django.db.models import F, Q

from newsplatform.common.models import BaseModel


class Redirect(BaseModel):
    """Permanent redirects. Chains are flattened on write, so a visitor is redirected once."""

    from_path = models.CharField(max_length=400, unique=True)
    to_path = models.CharField(max_length=400, db_index=True)
    is_automatic = models.BooleanField(default=True)

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=Q(from_path__startswith="/") & Q(to_path__startswith="/"), name="redirect_is_local"
            ),
            models.CheckConstraint(condition=~Q(from_path=F("to_path")), name="redirect_not_to_itself"),
        ]

    def __str__(self) -> str:
        return f"{self.from_path} → {self.to_path}"
