"""Beem SMS (https://docs.beem.africa, read 2026-11-27): send, balance, sender names.

Basic auth with the API key and secret. Numbers go without the leading "+". Code 100 is success; the
alphanumeric
sender ID is at most 11 characters and must be active on the account (the shared "INFO" is disabled).
"""

import base64
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

SEND = "https://apisms.beem.africa/v1/send"
BALANCE = "https://apisms.beem.africa/public/v1/vendors/balance"
SENDERS = "https://apisms.beem.africa/public/v1/sender-names"
_TIMEOUT = httpx.Timeout(10.0, connect=5.0)


class BeemConfig(ProviderConfig):
    api_key: str = field(..., "API key", "Ufunguo wa API", min_length=8, max_length=200)
    secret_key: SecretStr = field(..., "Secret key", "Ufunguo wa siri")
    sender_id: str = field(
        ...,
        "Sender ID",
        "Jina la mtumaji",
        help_en="As approved by Beem, at most 11 letters or digits. The shared INFO is disabled.",
        help_sw="Kama lilivyoidhinishwa na Beem, herufi au tarakimu 11 zisizozidi. INFO haitumiki tena.",
        pattern=r"^[A-Za-z0-9 ._-]{1,11}$",
    )


def _auth(config: BeemConfig) -> dict[str, str]:
    raw = f"{config.api_key}:{config.secret_key.get_secret_value()}".encode()
    return {"Authorization": "Basic " + base64.b64encode(raw).decode(), "Content-Type": "application/json"}


def _explain(response: httpx.Response) -> StepFailed:
    """Beem's own word as the detail; what to do about it as the hint (in Swahili too, integrations.hints)."""
    try:
        body = response.json()
    except ValueError:
        body = {}
    code = body.get("code") if isinstance(body, dict) else None
    detail = f"HTTP {response.status_code}" + (f", code {code}: {body.get('message', '')}" if code else "")
    if code == 101:
        return StepFailed(detail, "The number is not valid.")
    if code == 102:
        return StepFailed(detail, "The Beem account has no credit left. Top it up.")
    if code == 103:
        return StepFailed(detail, "Beem had an internal error. Try again shortly.")
    if code in (111, 121):
        return StepFailed(detail, "The sender ID is not registered or not active on this Beem account.")
    if code == 120 or response.status_code == 401:
        return StepFailed(detail, "The API key or secret is wrong.")
    return StepFailed(detail)


def balance(config: BeemConfig) -> float:
    with guarded_call("beem_sms", "balance"):
        response = httpx.get(BALANCE, headers=_auth(config), timeout=_TIMEOUT)
    if response.status_code != 200:
        raise _explain(response)
    return float(response.json()["data"]["credit_balance"])


def senders(config: BeemConfig) -> list[dict[str, Any]]:
    with guarded_call("beem_sms", "sender_names"):
        response = httpx.get(SENDERS, headers=_auth(config), params={"q": config.sender_id}, timeout=_TIMEOUT)
    if response.status_code != 200:
        raise _explain(response)
    return list(response.json().get("data") or [])


def send(config: BeemConfig, *, to: str, text: str) -> str:
    """`to` in E.164 ("+255…"). Returns Beem's request id; raises StepFailed when Beem refuses."""
    body = {
        "source_addr": config.sender_id,
        "schedule_time": "",
        "encoding": 0,
        "message": text,
        "recipients": [{"recipient_id": 1, "dest_addr": to.removeprefix("+")}],
    }
    with guarded_call("beem_sms", "send"):
        response = httpx.post(SEND, headers=_auth(config), json=body, timeout=_TIMEOUT)
        if response.status_code >= 500:
            raise StepFailed(f"HTTP {response.status_code}", "Beem had an internal error. Try again shortly.")
    data = response.json() if response.headers.get("content-type", "").startswith("application/json") else {}
    if response.status_code != 200 or not data.get("successful") or data.get("code") != 100:
        raise _explain(response)
    if int(data.get("valid", 1)) < 1:
        raise StepFailed("Beem did not accept the number.", "The number is not valid.")
    return str(data.get("request_id", ""))


@register_provider
class BeemProvider(Provider[BeemConfig]):
    key, name, category = "beem_sms", "Beem SMS", "messaging"
    description_en = (
        "Sends sign-in codes by SMS. Fraud limits and allowed countries are in Settings → Sign-in."
    )
    description_sw = (
        "Hutuma misimbo ya kuingia kwa SMS. Mipaka na nchi zinazoruhusiwa ziko Mipangilio → Kuingia."
    )
    config_model = BeemConfig
    test_params = ["phone"]

    def test(self, config: BeemConfig, t: Test, params: dict[str, Any]) -> None:
        t.step(
            "balance", "Sign in and read the balance", "Ingia na usome salio", lambda: _balance_text(config)
        )

        def sender() -> str:
            found = [
                s for s in senders(config) if str(s.get("senderid", "")).lower() == config.sender_id.lower()
            ]
            if not found:
                raise StepFailed(
                    f"{config.sender_id} is not on this account.",
                    "The sender ID is not registered or not active on this Beem account.",
                )
            status = str(found[0].get("status", ""))
            if status.lower() != "active":
                raise StepFailed(
                    f"{config.sender_id} is {status or 'not active'}.",
                    "The sender ID is not registered or not active on this Beem account.",
                )
            return f"{config.sender_id}: {status}"

        t.step("sender", "The sender ID is active", "Jina la mtumaji linatumika", sender, needs="balance")

        def message() -> str:
            from newsplatform.accounts.phones import normalise

            to = normalise(str(params.get("phone", "")))
            if to is None:
                raise StepFailed("Write the number with its country code, e.g. +255712345678.")
            return f"Request {send(config, to=to, text=f'{config.sender_id}: test SMS / SMS ya majaribio.')}"

        t.step("send", "Send a test SMS", "Tuma SMS ya majaribio", message, needs="sender")


def _balance_text(config: BeemConfig) -> str:
    credit = balance(config)
    if credit <= 0:
        raise StepFailed(f"Credit {credit:g}.", "The Beem account has no credit left. Top it up.")
    return f"Credit {credit:g}"
