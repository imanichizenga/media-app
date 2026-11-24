import ipaddress
from typing import Annotated, Any, Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from newsplatform.engagement.policy import KillSwitches, Policy
from newsplatform.site_config.theme.derive import SPEC

LogoId = Annotated[str, Field(pattern=r"^([0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12})?$")]
Hex = Annotated[str, Field(pattern=r"^#[0-9a-fA-F]{6}$")]


def _field(default: Any, en: str, sw: str, **kw: Any) -> Any:
    return Field(default=default, title=en, json_schema_extra={"x-title-sw": sw}, **kw)


class Section(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)


class Identity(Section):
    brand_name: str = _field("News", "Brand name", "Jina la chapa", min_length=1, max_length=60)
    tagline_sw: str = _field("", "Tagline (Swahili)", "Kaulimbiu (Kiswahili)", max_length=140)
    tagline_en: str = _field("", "Tagline (English)", "Kaulimbiu (Kiingereza)", max_length=140)
    # BrandLogo rows. Without a wordmark the name is typeset; without a dark one it is drawn in white.
    wordmark_light: LogoId = _field("", "Wordmark on light", "Nembo ya jina, mwanga")
    wordmark_dark: LogoId = _field("", "Wordmark on dark", "Nembo ya jina, giza")
    symbol: LogoId = _field("", "Symbol (square)", "Alama (mraba)")


class Appearance(Section):
    """Contrast is judged in `brand.validate`, which can also offer the nearest colour that passes."""

    schema_version: Literal[1] = 1
    theme: Literal["signature", "bold", "quiet"] = _field("signature", "Theme", "Mwonekano")
    color: Hex = _field(SPEC["color"], "Brand colour", "Rangi ya chapa")
    dark_color: Hex | Literal[""] = _field("", "Brand colour on dark", "Rangi ya chapa kwenye giza")

    @field_validator("color", "dark_color")
    @classmethod
    def _lower(cls, value: str) -> str:
        return value.lower()


class Brand(Section):
    """Published as one thing, so a name, a logo and a colour can never be half changed."""

    identity: Identity = Identity()
    appearance: Appearance = Appearance()


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
    "brand": Brand,
    "localization": Localization,
    "security": Security,
    "engagement": Engagement,
}
