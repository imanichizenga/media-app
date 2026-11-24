import ipaddress
from typing import Annotated, Any, Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from newsplatform.engagement.policy import KillSwitches, Policy

AssetId = Annotated[str, Field(pattern=r"^([0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12})?$")]
Hex = Annotated[str, Field(pattern=r"^#[0-9a-fA-F]{6}$")]


def contrast(a: str, b: str) -> float:
    def lum(hex_: str) -> float:
        parts = [int(hex_[i : i + 2], 16) / 255 for i in (1, 3, 5)]
        r, g, bl = (c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in parts)
        return 0.2126 * r + 0.7152 * g + 0.0722 * bl

    hi, lo = sorted((lum(a), lum(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def _field(default: Any, en: str, sw: str, **kw: Any) -> Any:
    return Field(default=default, title=en, json_schema_extra={"x-title-sw": sw}, **kw)


class Section(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)


class Identity(Section):
    brand_name: str = _field("News", "Brand name", "Jina la chapa", min_length=1, max_length=60)
    tagline_sw: str = _field("", "Tagline (Swahili)", "Kaulimbiu (Kiswahili)", max_length=140)
    tagline_en: str = _field("", "Tagline (English)", "Kaulimbiu (Kiingereza)", max_length=140)
    accent_light: Hex = _field("#0b5cad", "Accent, light theme", "Rangi kuu, mwanga")
    accent_dark: Hex = _field("#7db8f5", "Accent, dark theme", "Rangi kuu, giza")
    # Media library files. Empty shows the brand name as text.
    logo_light: AssetId = _field("", "Logo, light theme", "Nembo, mwanga")
    logo_dark: AssetId = _field("", "Logo, dark theme", "Nembo, giza")
    favicon: AssetId = _field("", "App icon (square)", "Ikoni (mraba)")

    @model_validator(mode="after")
    def _accessible(self) -> Identity:
        if contrast(self.accent_light, "#ffffff") < 4.5:
            raise ValueError("accent_light needs a contrast of at least 4.5:1 on white (WCAG AA)")
        if contrast(self.accent_dark, "#1c1d20") < 4.5:
            raise ValueError("accent_dark needs a contrast of at least 4.5:1 on the dark surface (WCAG AA)")
        return self


class Localization(Section):
    default_locale: Literal["sw", "en"] = _field("sw", "Default language", "Lugha chaguo-msingi")
    timezone: str = _field("Africa/Dar_es_Salaam", "Time zone", "Ukanda wa saa")

    @field_validator("timezone")
    @classmethod
    def _tz(cls, value: str) -> str:
        try:
            ZoneInfo(value)
        except (ZoneInfoNotFoundError, ValueError) as exc:
            raise ValueError("Unknown time zone") from exc
        return value


class Security(Section):
    # MFA is deliberately absent: it is mandatory and cannot be configured off.
    idle_timeout_minutes: int = _field(
        15, "Idle timeout (minutes)", "Muda wa kutotumika (dakika)", ge=5, le=60
    )
    absolute_timeout_hours: int = _field(
        12, "Maximum session (hours)", "Muda wa juu wa kipindi (saa)", ge=1, le=24
    )
    step_up_minutes: int = _field(
        5, "Step-up validity (minutes)", "Uhalali wa uthibitisho (dakika)", ge=1, le=15
    )
    lockout_threshold: int = _field(8, "Failures before lockout", "Makosa kabla ya kufungwa", ge=3, le=20)
    lockout_minutes: int = _field(15, "Lockout (minutes)", "Muda wa kufungwa (dakika)", ge=5, le=240)
    four_eyes: Literal["auto", "on", "off"] = _field("auto", "Four-eyes approval", "Idhini ya watu wawili")
    ip_allowlist_enabled: bool = _field(False, "Restrict admin by IP", "Zuia kwa IP")
    ip_allowlist: list[str] = _field([], "Allowed networks (CIDR)", "Mitandao inayoruhusiwa", max_length=200)
    geo_anomaly_action: Literal["off", "alert", "block"] = _field(
        "alert", "Login from an unusual country", "Kuingia kutoka nchi isiyo ya kawaida"
    )

    @field_validator("ip_allowlist")
    @classmethod
    def _cidrs(cls, value: list[str]) -> list[str]:
        nets = [ipaddress.ip_network(v.strip(), strict=False) for v in value]
        if any(n.prefixlen == 0 for n in nets):
            raise ValueError("A /0 network would allow everyone")
        return sorted({str(n) for n in nets})

    @model_validator(mode="after")
    def _not_empty(self) -> Security:
        if self.ip_allowlist_enabled and not self.ip_allowlist:
            raise ValueError("Add at least one network before enabling the allowlist")
        return self


class Engagement(Section):
    """Global defaults and kill switches (engagement.policy)."""

    defaults: Policy = Policy()
    kill: KillSwitches = KillSwitches()


SECTIONS: dict[str, type[Section]] = {
    "identity": Identity,
    "localization": Localization,
    "security": Security,
    "engagement": Engagement,
}
