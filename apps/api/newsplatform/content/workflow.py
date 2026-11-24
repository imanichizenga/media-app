"""The editorial state machine, as data: the admin and the tests read the same table the service enforces."""

from dataclasses import dataclass
from enum import StrEnum

from newsplatform.content.models import Status as S


class Need(StrEnum):
    OWN = "own"  # an author of the post with content.edit_own, or content.edit_others in its category
    REVIEW = "content.review"
    PUBLISH = "content.publish"
    PUBLISH_OR_DIRECT = "publish_or_direct"  # content.publish, or an author with content.publish_direct
    DELETE = "content.delete"


@dataclass(frozen=True, slots=True)
class Transition:
    key: str
    sources: frozenset[str]
    target: S
    need: Need
    note_required: bool = False


def _t(key: str, sources: set[S], target: S, need: Need, note: bool = False) -> Transition:
    return Transition(key, frozenset(sources), target, need, note)


TRANSITIONS: dict[str, Transition] = {
    t.key: t
    for t in [
        _t("submit", {S.DRAFT}, S.SUBMITTED, Need.OWN),
        _t("withdraw", {S.SUBMITTED}, S.DRAFT, Need.OWN),
        _t("start_review", {S.SUBMITTED}, S.IN_REVIEW, Need.REVIEW),
        _t("request_changes", {S.SUBMITTED, S.IN_REVIEW, S.APPROVED}, S.DRAFT, Need.REVIEW, True),
        _t("approve", {S.SUBMITTED, S.IN_REVIEW}, S.APPROVED, Need.REVIEW),
        _t("schedule", {S.DRAFT, S.APPROVED, S.UNPUBLISHED}, S.SCHEDULED, Need.PUBLISH_OR_DIRECT),
        _t("unschedule", {S.SCHEDULED}, S.APPROVED, Need.PUBLISH_OR_DIRECT),
        _t(
            "publish",
            {S.DRAFT, S.APPROVED, S.SCHEDULED, S.UNPUBLISHED},
            S.PUBLISHED,
            Need.PUBLISH_OR_DIRECT,
        ),
        # Edits to a live article become visible only through this.
        _t("republish", {S.PUBLISHED}, S.PUBLISHED, Need.PUBLISH_OR_DIRECT),
        _t("unpublish", {S.PUBLISHED}, S.UNPUBLISHED, Need.PUBLISH, True),
        _t("archive", {S.DRAFT, S.UNPUBLISHED}, S.ARCHIVED, Need.DELETE),
        _t("restore", {S.ARCHIVED}, S.DRAFT, Need.DELETE),
    ]
}
KEYS = [(k, k) for k in sorted(TRANSITIONS)]
# Anyone else editing here would change what a reviewer has already read.
EDITABLE_BY_AUTHOR = frozenset({S.DRAFT, S.UNPUBLISHED, S.PUBLISHED})
