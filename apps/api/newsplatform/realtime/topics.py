"""What staff may subscribe to. Each app registers its topics in `ready()`; nothing else can be subscribed."""

import uuid
from dataclasses import dataclass

from newsplatform.accounts.models import User
from newsplatform.rbac.selectors import grants_for

_registry: dict[str, str] = {}


@dataclass(frozen=True, slots=True)
class Topic:
    kind: str
    id: uuid.UUID

    def __str__(self) -> str:
        return f"{self.kind}:{self.id}"

    @property
    def group(self) -> str:
        return f"{self.kind}.{self.id.hex}"


def register(kind: str, permission: str) -> None:
    _registry[kind] = permission


def parse(raw: object) -> Topic | None:
    kind, _, ident = raw.partition(":") if isinstance(raw, str) else ("", "", "")
    if kind not in _registry:
        return None
    try:
        return Topic(kind, uuid.UUID(ident))
    except ValueError:
        return None


def allowed(user: User, topic: Topic) -> bool:
    return _registry[topic.kind] in grants_for(user).any
