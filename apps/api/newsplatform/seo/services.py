from django.db import transaction

from newsplatform.common.errors import DomainError
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
