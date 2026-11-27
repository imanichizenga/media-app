"""Sign in with Apple (REST API, https://developer.apple.com/documentation/signinwithapplerestapi, read
2026-11-27).

Client secret: an ES256 JWT signed with the private key (header kid; claims iss team, aud https://appleid.apple.com,
sub client id, at most six months). Website: authorization code flow with response_mode form_post (required
when
asking for name and email); the code is exchanged here and the ID token verified against Apple's keys. Apps
send the
identity token their SDK received, whose audience is the bundle ID.
"""

import re
import time
from typing import Any

import httpx
from joserfc import jwt
from joserfc.jwk import ECKey
from pydantic import SecretStr, field_validator

from newsplatform.integrations.aws import field
from newsplatform.integrations.base import (
    Provider,
    ProviderConfig,
    StepFailed,
    Test,
    guarded_call,
    register_provider,
)

ISSUER = "https://appleid.apple.com"
AUTHORIZE = "https://appleid.apple.com/auth/authorize"
TOKEN = "https://appleid.apple.com/auth/token"  # noqa: S105 (an address, not a password)
KEYS = "https://appleid.apple.com/auth/keys"
REVOKE = "https://appleid.apple.com/auth/revoke"
_TEN = r"^[A-Z0-9]{10}$"


class AppleConfig(ProviderConfig):
    team_id: str = field(..., "Team ID", "Kitambulisho cha timu", pattern=_TEN)
    key_id: str = field(..., "Key ID", "Kitambulisho cha ufunguo", pattern=_TEN)
    services_id: str = field(
        ...,
        "Services ID (website)",
        "Services ID (tovuti)",
        help_en="Return URL to register: <website>/api/auth/apple/callback",
        help_sw="URL ya kurudi ya kusajili: <tovuti>/api/auth/apple/callback",
        pattern=r"^[A-Za-z0-9.-]{3,155}$",
    )
    bundle_id: str = field(
        "", "App bundle ID (iOS)", "Bundle ID ya programu (iOS)", pattern=r"^$|^[A-Za-z0-9.-]{3,155}$"
    )
    private_key: SecretStr = field(
        ...,
        "Private key (.p8)",
        "Ufunguo binafsi (.p8)",
        help_en="The whole file, from -----BEGIN PRIVATE KEY----- to the end.",
        help_sw="Faili lote, kuanzia -----BEGIN PRIVATE KEY----- hadi mwisho.",
    )

    @field_validator("private_key")
    @classmethod
    def _pem(cls, value: SecretStr) -> SecretStr:
        return SecretStr(pem(value.get_secret_value()))

    def audiences(self) -> list[str]:
        return [c for c in (self.services_id, self.bundle_id) if c]


def pem(raw: str) -> str:
    """A pasted key, whatever became of its line breaks in a one-line field, as a proper PEM."""
    body = re.sub(r"-----(BEGIN|END) PRIVATE KEY-----", "", raw)
    body = re.sub(r"\\n|\s", "", body)
    if not re.fullmatch(r"[A-Za-z0-9+/=]{40,}", body):
        raise ValueError("This is not a .p8 private key.")
    lines = [body[i : i + 64] for i in range(0, len(body), 64)]
    return "-----BEGIN PRIVATE KEY-----\n" + "\n".join(lines) + "\n-----END PRIVATE KEY-----\n"


def client_secret(config: AppleConfig, client_id: str) -> str:
    now = int(time.time())
    key = ECKey.import_key(config.private_key.get_secret_value())
    claims = {"iss": config.team_id, "iat": now, "exp": now + 3600, "aud": ISSUER, "sub": client_id}
    return jwt.encode({"alg": "ES256", "kid": config.key_id}, claims, key)


def _post(config: AppleConfig, url: str, client_id: str, data: dict[str, str]) -> httpx.Response:
    body = {"client_id": client_id, "client_secret": client_secret(config, client_id), **data}
    with guarded_call("apple_signin", url.rsplit("/", 1)[-1]):
        return httpx.post(url, data=body, timeout=10)


def exchange(config: AppleConfig, *, code: str, redirect_uri: str) -> dict[str, Any]:
    response = _post(
        config,
        TOKEN,
        config.services_id,
        {"code": code, "grant_type": "authorization_code", "redirect_uri": redirect_uri},
    )
    data: dict[str, Any] = response.json()
    if response.status_code != 200:
        raise StepFailed(str(data.get("error", response.status_code)))
    return data


def revoke(config: AppleConfig, *, token: str, client_id: str) -> None:
    """On account deletion (App Store guideline 5.1.1(v)). 200 also when the token was already invalid."""
    _post(config, REVOKE, client_id, {"token": token, "token_type_hint": "refresh_token"})


@register_provider
class AppleProvider(Provider[AppleConfig]):
    key, name, category = "apple_signin", "Sign in with Apple", "identity"
    description_en = "Readers sign in with their Apple ID: required in the iOS app, offered on the website."
    description_sw = "Wasomaji huingia kwa Apple ID: lazima kwenye programu ya iOS, hiari kwenye tovuti."
    config_model = AppleConfig

    def test(self, config: AppleConfig, t: Test, params: dict[str, Any]) -> None:
        t.step(
            "secret",
            "Sign a client secret with the key",
            "Saini siri ya mteja kwa ufunguo",
            lambda: f"{len(client_secret(config, config.services_id))} characters",
        )

        def accepted() -> str:
            # A made-up code: Apple says invalid_grant only once the client and its secret are accepted.
            response = _post(
                config,
                TOKEN,
                config.services_id,
                {"code": "test-not-a-real-code", "grant_type": "authorization_code"},
            )
            error = str(response.json().get("error", "")) if response.content else ""
            if error == "invalid_grant":
                return "Team ID, key ID, Services ID and key accepted."
            if error == "invalid_client":
                raise StepFailed(
                    error, "Apple refused the client: check the Team ID, key ID, Services ID and the .p8 key."
                )
            if error == "unauthorized_client":
                raise StepFailed(
                    error,
                    "This Services ID may not use Sign in with Apple: "
                    "enable it in Apple's developer account.",
                )
            raise StepFailed(error or f"HTTP {response.status_code}")

        t.step("client", "Apple accepts the client", "Apple inakubali mteja", accepted, needs="secret")
        t.step(
            "keys",
            "Read Apple's signing keys",
            "Soma funguo za Apple",
            lambda: f"{len(_keys())} keys",
        )


def _keys() -> list[Any]:
    from newsplatform.accounts.oidc import fetch_json

    return list(fetch_json("apple_signin", KEYS).get("keys", []))
