"""Snippe payments (https://docs.snippe.sh/docs/2026-01-25, read 2026-11-28): mobile money and card checkout.

Mobile money: `POST /v1/payments` with `payment_type: "mobile"` sends a USSD push to the reader's phone
(Airtel Money, M-Pesa, Mixx by Yas, Halotel). Amounts are whole shillings, TZS only, at least 500. Each create
carries an `Idempotency-Key` of at most 30 characters. `GET /v1/payments/{reference}` says where it is:
pending, completed, failed, voided or expired.

Cards: a Payment Session (`POST /api/v1/sessions`) gives a hosted `checkout_url` the reader is sent to, and
back to `redirect_url`. Sessions take their own bearer token (the docs do not use the `snp_` key there), and
the methods it offers are this platform's to ask for (`allowed_methods`), so both are settings here, not code.

Webhooks: `X-Webhook-Signature` is hex HMAC-SHA256, keyed with the account's `whsec_` signing key, of
"{X-Webhook-Timestamp}.{raw body}"; older than five minutes is refused.
"""

import hashlib
import hmac
import time
from typing import Any

import httpx
from pydantic import SecretStr

from newsplatform.integrations.aws import field
from newsplatform.integrations.base import (
    Provider,
    ProviderConfig,
    StepFailed,
    Test,
    guarded_call,
    register_provider,
)

API = "https://api.snippe.sh"
_TIMEOUT = httpx.Timeout(15.0, connect=5.0)
TOLERANCE = 300
MINIMUM = 500


class SnippeConfig(ProviderConfig):
    api_key: SecretStr = field(
        ...,
        "API key",
        "Ufunguo wa API",
        help_en="From Snippe: Settings → API Keys, with the collection scopes. It starts with snp_.",
        help_sw="Kutoka Snippe: Settings → API Keys, wenye ruhusa za collection. Unaanza na snp_.",
    )
    webhook_secret: SecretStr = field(
        ...,
        "Webhook signing key",
        "Ufunguo wa kusaini webhook",
        help_en="Settings → Webhook Secret. It starts with whsec_.",
        help_sw="Settings → Webhook Secret. Unaanza na whsec_.",
    )
    webhook_url: str = field(
        ...,
        "Webhook address",
        "Anwani ya webhook",
        help_en="This platform's public API, ending /api/v1/subscriptions/webhook. Snippe reports payments.",
        help_sw="API ya umma ya mfumo huu, ikiishia /api/v1/subscriptions/webhook.",
        pattern=r"^https://[^\s\"'<>]+/api/v1/subscriptions/webhook$",
        max_length=300,
    )
    card_token: SecretStr | None = field(
        None,
        "Checkout token (cards)",
        "Tokeni ya malipo ya kadi",
        help_en="For the hosted checkout where readers pay by card. Leave empty to offer mobile money only.",
        help_sw="Kwa ukurasa wa malipo wa kadi. Acha wazi kutoa pesa kwa simu pekee.",
    )
    card_methods: str = field(
        "card",
        "Checkout methods",
        "Njia za malipo kwenye ukurasa",
        help_en="As Snippe names them, separated by commas (e.g. card,mobile_money).",
        help_sw="Kama Snippe inavyoziita, zikitenganishwa kwa koma (mf. card,mobile_money).",
        pattern=r"^[a-z_]+(,[a-z_]+)*$",
        max_length=80,
    )
    base_url: str = field(
        API, "API address", "Anwani ya API", pattern=r"^https://[^\s\"'<>]+$", max_length=200
    )

    @property
    def cards(self) -> bool:
        return self.card_token is not None and bool(self.card_token.get_secret_value())


def _headers(token: str, key: str = "") -> dict[str, str]:
    h = {"Authorization": f"Bearer {token}", "Content-Type": "application/json", "Accept": "application/json"}
    if key:
        h["Idempotency-Key"] = key[:30]
    return h


def _explain(response: httpx.Response) -> StepFailed:
    try:
        body = response.json()
    except ValueError:
        body = {}
    code = str(body.get("error_code", "")) if isinstance(body, dict) else ""
    message = str(body.get("message", "")) if isinstance(body, dict) else ""
    detail = f"HTTP {response.status_code}" + (f", {code}: {message}" if code or message else "")
    if response.status_code == 401:
        return StepFailed(detail, "The Snippe API key is wrong or revoked.")
    if response.status_code == 403:
        return StepFailed(detail, "Give the Snippe API key the collection scopes.")
    if response.status_code == 429:
        return StepFailed(detail, "Snippe is limiting requests. Try again in a minute.")
    if response.status_code >= 500:
        return StepFailed(detail, "Snippe had an internal error. Try again shortly.")
    return StepFailed(detail)


def _data(response: httpx.Response) -> dict[str, Any]:
    body = response.json()
    data = body.get("data") if isinstance(body, dict) else None
    return data if isinstance(data, dict) else {}


def balance(config: SnippeConfig) -> dict[str, Any]:
    with guarded_call("snippe", "balance"):
        r = httpx.get(
            f"{config.base_url}/v1/payments/balance",
            headers=_headers(config.api_key.get_secret_value()),
            timeout=_TIMEOUT,
        )
    if r.status_code != 200:
        raise _explain(r)
    return _data(r)


def push(
    config: SnippeConfig,
    *,
    key: str,
    amount: int,
    phone: str,
    customer: dict[str, str],
    metadata: dict[str, str],
) -> dict[str, Any]:
    """A USSD push to `phone` (E.164). Returns Snippe's payment: `reference`, `status`, `expires_at`."""
    body = {
        "payment_type": "mobile",
        "details": {"amount": amount, "currency": "TZS"},
        "phone_number": phone.removeprefix("+"),
        "customer": customer,
        "webhook_url": config.webhook_url,
        "metadata": metadata,
    }
    with guarded_call("snippe", "payment"):
        r = httpx.post(
            f"{config.base_url}/v1/payments",
            headers=_headers(config.api_key.get_secret_value(), key),
            json=body,
            timeout=_TIMEOUT,
        )
        if r.status_code >= 500:
            raise _explain(r)
    if r.status_code not in (200, 201):
        raise _explain(r)
    return _data(r)


def checkout(
    config: SnippeConfig,
    *,
    amount: int,
    description: str,
    customer: dict[str, str],
    redirect_url: str,
    metadata: dict[str, str],
) -> dict[str, Any]:
    """A hosted checkout for cards. Returns the session: `reference`, `checkout_url`."""
    if not config.card_token:
        raise StepFailed("No checkout token.", "Add the checkout token to take cards.")
    body = {
        "amount": amount,
        "currency": "TZS",
        "allowed_methods": config.card_methods.split(","),
        "customer": customer,
        "redirect_url": redirect_url,
        "webhook_url": config.webhook_url,
        "description": description[:200],
        "metadata": metadata,
        "expires_in": 3600,
    }
    with guarded_call("snippe", "session"):
        r = httpx.post(
            f"{config.base_url}/api/v1/sessions",
            headers=_headers(config.card_token.get_secret_value()),
            json=body,
            timeout=_TIMEOUT,
        )
        if r.status_code >= 500:
            raise _explain(r)
    if r.status_code not in (200, 201):
        raise _explain(r)
    return _data(r)


def status(config: SnippeConfig, reference: str) -> dict[str, Any]:
    with guarded_call("snippe", "status"):
        r = httpx.get(
            f"{config.base_url}/v1/payments/{reference}",
            headers=_headers(config.api_key.get_secret_value()),
            timeout=_TIMEOUT,
        )
    if r.status_code != 200:
        raise _explain(r)
    return _data(r)


def verify(
    config: SnippeConfig, *, raw: bytes, timestamp: str, signature: str, now: float | None = None
) -> bool:
    """The webhook is Snippe's, and recent."""
    if not timestamp.isdigit() or not signature:
        return False
    if abs((now or time.time()) - int(timestamp)) > TOLERANCE:
        return False
    key = config.webhook_secret.get_secret_value().encode()
    expected = hmac.new(key, timestamp.encode() + b"." + raw, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature.strip().lower())


@register_provider
class SnippeProvider(Provider[SnippeConfig]):
    key, name, category = "snippe", "Snippe payments", "payments"
    description_en = (
        "Takes subscription payments: mobile money push, and cards on Snippe's checkout. "
        "Plans are in Subscriptions."
    )
    description_sw = (
        "Hupokea malipo ya usajili: pesa kwa simu, na kadi kwenye ukurasa wa Snippe. Vifurushi viko Usajili."
    )
    config_model = SnippeConfig

    def test(self, config: SnippeConfig, t: Test, params: dict[str, Any]) -> None:
        def read() -> str:
            b = balance(config)
            value = b.get("balance", b.get("available", b))
            return f"Balance {value}"

        t.step("balance", "Sign in and read the balance", "Ingia na usome salio", read)

        def signing() -> str:
            secret = config.webhook_secret.get_secret_value()
            if not secret.startswith("whsec_"):
                raise StepFailed(
                    "The signing key does not start with whsec_.", "Paste the webhook signing key again."
                )
            return "whsec_…"

        t.step("webhook", "The webhook signing key", "Ufunguo wa kusaini webhook", signing)
