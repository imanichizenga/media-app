from newsplatform.accounts.models import User

_TEXT = {
    "new_device": (
        "New sign-in to your admin account / Umeingia kwa kifaa kipya",
        "Your account was used on a new device: {detail}\n\nIf this was not you, tell another administrator "
        "now.\n\nAkaunti yako imetumika kwenye kifaa kipya. Kama si wewe, mjulishe msimamizi mara moja.",
    ),
    "geo_anomaly": (
        "Sign-in from an unusual country / Kuingia kutoka nchi isiyo ya kawaida",
        "A sign-in came from an unusual place: {detail}\n\nJaribio la kuingia limetoka mahali pasipo pa "
        "kawaida.",
    ),
    "session_hijack_suspected": (
        "Session closed for your safety / Kipindi kimefungwa kwa usalama wako",
        "A session was used from a different device, so it was closed.\n\nKipindi kilitumika "
        "kwenye kifaa tofauti, hivyo kimefungwa.",
    ),
    "credentials_changed": (
        "Your sign-in details changed / Taarifa zako za kuingia zimebadilika",
        "What changed: {detail}\n\nKilichobadilika: {detail}",
    ),
}


def notify(user: User, kind: str, detail: str = "") -> None:
    """Every alert is also an AuthEvent shown in the console, so a missing email setup never hides it."""
    from newsplatform.staff_security.tasks import send_alert

    subject, text = _TEXT[kind]
    send_alert.delay(str(user.pk), subject, text.format(detail=detail))
