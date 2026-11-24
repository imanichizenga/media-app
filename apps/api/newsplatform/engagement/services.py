from collections.abc import Iterable
from typing import Any

from newsplatform.common.errors import DomainError
from newsplatform.engagement.policy import Override, Policy, resolve
from newsplatform.site_config.schemas import Engagement
from newsplatform.site_config.services import get_section


def settings() -> Engagement:
    section = get_section("engagement")[0]
    assert isinstance(section, Engagement)  # noqa: S101 (type narrowing)
    return section


def validated(raw: dict[str, Any]) -> dict[str, Any]:
    try:
        return Override.model_validate(raw).stored()
    except ValueError as exc:
        raise DomainError("The engagement settings are invalid.", code="validation_error") from exc


def resolved(overrides: Iterable[dict[str, Any]], current: Engagement | None = None) -> Policy:
    section = current or settings()
    return resolve(section.defaults, section.kill, overrides)
