"""Sign in with Google (OpenID Connect, https://developers.google.com/identity/openid-connect, read
2026-11-27).

The website uses the authorization code flow (its client ID and secret, a redirect URI registered in the Cloud
console); the apps send the ID token their SDK received. Either way the ID token is verified here: Google's
keys,
`iss` accounts.google.com, `aud` one of the client IDs below, `exp`. Endpoints come from the discovery
document.
"""

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

DISCOVERY = "https://accounts.google.com/.well-known/openid-configuration"
ISSUERS = ["https://accounts.google.com", "accounts.google.com"]
_ID = r"^$|^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$"


class GoogleConfig(ProviderConfig):
    web_client_id: str = field(
        ...,
        "Web client ID",
        "Kitambulisho cha mteja wa wavuti",
        help_en="Authorised redirect URI: <website>/api/auth/google/callback",
        help_sw="URI ya kurudi iliyoidhinishwa: <tovuti>/api/auth/google/callback",
        pattern=_ID[4:],
    )
    web_client_secret: SecretStr = field(..., "Web client secret", "Siri ya mteja wa wavuti")
    android_client_id: str = field("", "Android client ID", "Kitambulisho cha mteja wa Android", pattern=_ID)
    ios_client_id: str = field("", "iOS client ID", "Kitambulisho cha mteja wa iOS", pattern=_ID)

    def audiences(self) -> list[str]:
        return [c for c in (self.web_client_id, self.android_client_id, self.ios_client_id) if c]


def discovery() -> dict[str, Any]:
    from newsplatform.accounts.oidc import fetch_json

    return fetch_json("google_signin", DISCOVERY)


def exchange(config: GoogleConfig, *, code: str, redirect_uri: str, verifier: str) -> dict[str, Any]:
    """The website's code for tokens. Raises StepFailed with Google's own error word."""
    body = {
        "code": code,
        "client_id": config.web_client_id,
        "client_secret": config.web_client_secret.get_secret_value(),
        "redirect_uri": redirect_uri,
        "grant_type": "authorization_code",
    }
    if verifier:
        body["code_verifier"] = verifier
    with guarded_call("google_signin", "token"):
        response = httpx.post(str(discovery()["token_endpoint"]), data=body, timeout=10)
    data: dict[str, Any] = response.json()
    if response.status_code != 200:
        error = str(data.get("error", response.status_code))
        raise StepFailed(error)  # Google's own word, compared by callers (invalid_grant, invalid_client)
    return data


@register_provider
class GoogleProvider(Provider[GoogleConfig]):
    key, name, category = "google_signin", "Sign in with Google", "identity"
    description_en = "Readers sign in with their Google account, on the website and in the apps."
    description_sw = "Wasomaji huingia kwa akaunti zao za Google, kwenye tovuti na kwenye programu."
    config_model = GoogleConfig

    def test(self, config: GoogleConfig, t: Test, params: dict[str, Any]) -> None:
        found: dict[str, Any] = {}

        def read() -> str:
            found.update(discovery())
            return str(found.get("issuer"))

        t.step("discovery", "Read Google's discovery document", "Soma hati ya ugunduzi ya Google", read)
        t.step(
            "keys",
            "Read Google's signing keys",
            "Soma funguo za Google",
            lambda: f"{len(_keys(found))} keys",
            needs="discovery",
        )

        def client() -> str:
            # A made-up code: Google says the code is bad (invalid_grant) only once the client itself is
            # accepted.
            try:
                exchange(
                    config, code="test-not-a-real-code", redirect_uri="https://example.invalid/", verifier=""
                )
            except StepFailed as exc:
                if exc.detail == "invalid_grant":
                    return "Client ID and secret accepted."
                if exc.detail in {"invalid_client", "unauthorized_client"}:
                    raise StepFailed(
                        exc.detail, "Check the web client ID and secret in Google Cloud → Credentials."
                    ) from exc
                raise
            raise StepFailed("Google accepted a made-up code.")

        t.step(
            "client",
            "Google accepts the web client",
            "Google inakubali mteja wa wavuti",
            client,
            needs="discovery",
        )


def _keys(found: dict[str, Any]) -> list[Any]:
    from newsplatform.accounts.oidc import fetch_json

    return list(fetch_json("google_signin", str(found["jwks_uri"])).get("keys", []))
