from newsplatform.accounts.models import User
from newsplatform.common import context
from newsplatform.staff_security.models import AuthEvent


def auth_event(kind: str, *, ok: bool, user: User | None = None, subject: str = "", detail: str = "") -> None:
    ctx = context.current()
    AuthEvent.objects.create(
        kind=kind,
        ok=ok,
        user=user,
        subject=subject,
        ip=ctx.ip or "",
        country=ctx.country,
        user_agent=ctx.user_agent,
        detail=detail[:200],
        request_id=ctx.request_id,
    )
