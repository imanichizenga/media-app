import re

from django.db import transaction

from newsplatform.accounts.models import User
from newsplatform.audit.services import record
from newsplatform.common.errors import Conflict, DomainError
from newsplatform.rbac import selectors as rbac
from newsplatform.seo.models import Redirect


@transaction.atomic
def moved(old: str, new: str, *, automatic: bool = True) -> None:
    if old == new:
        return
    # The new address is live content again: nothing may redirect away from it.
    Redirect.objects.filter(from_path=new).delete()
    Redirect.objects.filter(to_path=old).update(to_path=new)
    Redirect.objects.update_or_create(from_path=old, defaults={"to_path": new, "is_automatic": automatic})


def moved_prefix(old: str, new: str) -> None:
    """A category moved. One rule per post would be thousands of rows, so one prefix rule covers them."""
    moved(f"{old}/*", f"{new}/*")
    moved(old, new)


def resolve(path: str) -> str | None:
    """Where `path` lives now, or None. Exact rules win over the longest matching prefix rule."""
    if len(path) > 400 or not path.startswith("/"):
        raise DomainError("Invalid path", code="validation_error")
    seen = {path}
    current = path
    for _ in range(5):
        found = _step(current)
        if found is None or found in seen:
            break
        seen.add(found)
        current = found
    return current if current != path else None


def _step(path: str) -> str | None:
    parts = path.rstrip("/").split("/")
    prefixes = ["/".join(parts[:i]) + "/*" for i in range(len(parts) - 1, 1, -1)]
    rules = dict(Redirect.objects.filter(from_path__in=[path, *prefixes]).values_list("from_path", "to_path"))
    if path in rules:
        return rules[path]
    for rule in prefixes:
        if rule in rules:
            return rules[rule][:-2] + path[len(rule) - 2 :]
    return None


_LOCAL = re.compile(r"/[A-Za-z0-9/_.~%-]*")


@transaction.atomic
def add_manual(*, actor: User, from_path: str, to_path: str) -> Redirect:
    rbac.require(actor, "taxonomy.manage")
    for path in (from_path, to_path):
        # Local only, so a redirect can never send a reader to another site.
        if not _LOCAL.fullmatch(path) or path.startswith("//") or "/../" in path:
            raise DomainError("Use an address on this site, such as /habari/jina.", code="invalid_path")
    from_path = from_path.rstrip("/") or "/"
    from newsplatform.content.models import Publication

    if from_path == "/" or Publication.objects.filter(path=from_path).exists():
        raise Conflict("A page is published at this address.", code="path_in_use")
    # The target may itself have moved. Point at where it is now, and leave its own rule alone.
    to_path = resolve(to_path) or to_path
    if from_path == to_path:
        raise DomainError("This would redirect in a circle.", code="redirect_loop")
    moved(from_path, to_path, automatic=False)
    row = Redirect.objects.get(from_path=from_path)
    record(
        actor=actor,
        action="redirect.created",
        target=row,
        label=from_path,
        after={"to": to_path},
    )
    return row


@transaction.atomic
def remove(*, actor: User, row: Redirect) -> None:
    rbac.require(actor, "taxonomy.manage")
    record(
        actor=actor, action="redirect.deleted", target=row, label=row.from_path, before={"to": row.to_path}
    )
    row.delete()
