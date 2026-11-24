"""Which engagement a post allows. Global → category, root first → post → kill switches."""

from collections.abc import Iterable
from enum import StrEnum
from typing import Any

from pydantic import BaseModel, ConfigDict


class CommentMode(StrEnum):
    OPEN = "open"
    VERIFIED = "verified"
    PREMODERATED = "premoderated"
    CLOSED = "closed"


COMMENT_MODES = [(m.value, m.name) for m in CommentMode]


class Policy(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)
    likes: bool = True
    comments: CommentMode = CommentMode.OPEN
    bookmarks: bool = True
    shares: bool = True
    reposts: bool = False
    live_chat: bool = True


class Override(BaseModel):
    """Only what differs; None inherits."""

    model_config = ConfigDict(extra="forbid", frozen=True)
    likes: bool | None = None
    comments: CommentMode | None = None
    bookmarks: bool | None = None
    shares: bool | None = None
    reposts: bool | None = None
    live_chat: bool | None = None

    def stored(self) -> dict[str, Any]:
        return self.model_dump(mode="json", exclude_none=True)


class KillSwitches(BaseModel):
    """Site-wide, for a crisis. They win over everything."""

    model_config = ConfigDict(extra="forbid", frozen=True)
    likes: bool = False
    comments: bool = False
    bookmarks: bool = False
    shares: bool = False
    reposts: bool = False
    live_chat: bool = False


def resolve(base: Policy, kill: KillSwitches, overrides: Iterable[dict[str, Any]]) -> Policy:
    data = base.model_dump()
    for raw in overrides:
        data.update(Override.model_validate(raw).stored())
    for name, off in kill.model_dump().items():
        if off:
            data[name] = CommentMode.CLOSED if name == "comments" else False
    return Policy.model_validate(data)
