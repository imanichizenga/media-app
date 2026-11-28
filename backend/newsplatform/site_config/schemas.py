import ipaddress
from typing import Annotated, Any, Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from newsplatform.engagement.policy import KillSwitches, Policy
from newsplatform.site_config.theme.derive import SPEC

LogoId = Annotated[str, Field(pattern=r"^([0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12})?$")]
Version = Annotated[str, Field(pattern=r"^(\d{1,3}\.\d{1,3}\.\d{1,3})?$")]
Url = Annotated[str, Field(pattern=r"^(https://[^\s\"'<>]+)?$", max_length=300)]
Pin = Annotated[str, Field(pattern=r"^[A-Za-z0-9+/]{43}=$")]
Package = Annotated[str, Field(pattern=r"^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$", max_length=100)]
Fingerprint = Annotated[str, Field(pattern=r"^([0-9A-F]{2}:){31}[0-9A-F]{2}$")]
AppId = Annotated[str, Field(pattern=r"^[A-Z0-9]{10}\.[A-Za-z0-9.-]+$", max_length=155)]
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


class App(Section):
    """What installed apps must know before anything else. Every phone reads it: nothing here is secret."""

    min_android: Version = _field("", "Oldest Android version allowed", "Toleo la zamani zaidi, Android")
    min_ios: Version = _field("", "Oldest iOS version allowed", "Toleo la zamani zaidi, iOS")
    recommended_android: Version = _field(
        "", "Recommended Android version", "Toleo linalopendekezwa, Android"
    )
    recommended_ios: Version = _field("", "Recommended iOS version", "Toleo linalopendekezwa, iOS")
    store_android: Url = _field("", "Google Play address", "Anwani ya Google Play")
    store_ios: Url = _field("", "App Store address", "Anwani ya App Store")
    maintenance: bool = _field(False, "Maintenance", "Matengenezo")
    maintenance_sw: str = _field(
        "", "Maintenance message (Swahili)", "Ujumbe wa matengenezo (Kiswahili)", max_length=300
    )
    maintenance_en: str = _field(
        "", "Maintenance message (English)", "Ujumbe wa matengenezo (Kiingereza)", max_length=300
    )
    # Kill switches: a feature that misbehaves in installed apps can be turned off without a release.
    shorts: bool = _field(True, "Shorts", "Video fupi")
    youtube: bool = _field(True, "YouTube player", "Kicheza YouTube")
    offline_saving: bool = _field(True, "Saving for offline reading", "Kuhifadhi kwa kusoma bila mtandao")
    link_about: Url = _field("", "About us page", "Ukurasa wa kuhusu sisi")
    link_editorial: Url = _field("", "Editorial policy page", "Ukurasa wa sera ya uhariri")
    link_corrections: Url = _field("", "Corrections page", "Ukurasa wa marekebisho")
    link_contact: Url = _field("", "Contact page", "Ukurasa wa mawasiliano")
    link_privacy: Url = _field("", "Privacy page", "Ukurasa wa faragha")
    link_terms: Url = _field("", "Terms page", "Ukurasa wa masharti")
    pinning: bool = _field(False, "Certificate pinning", "Kufunga cheti")
    pins: list[Pin] = _field(
        [], "Certificate pins (SHA-256, base64)", "Pini za cheti (SHA-256, base64)", max_length=6
    )
    android_packages: list[Package] = _field(
        [], "Android packages that open links", "Programu za Android zinazofungua viungo", max_length=4
    )
    android_certificates: list[Fingerprint] = _field(
        [], "Android signing certificates (SHA-256)", "Vyeti vya kusaini vya Android (SHA-256)", max_length=6
    )
    ios_app_ids: list[AppId] = _field(
        [], "iOS app IDs that open links", "Programu za iOS zinazofungua viungo", max_length=4
    )

    @model_validator(mode="after")
    def _two_pins(self) -> App:
        # One pin alone locks every phone out on the day the certificate changes.
        if self.pinning and len(set(self.pins)) < 2:
            raise ValueError("Pinning needs at least two different pins: the current one and a backup")
        return self

    @model_validator(mode="after")
    def _message(self) -> App:
        if self.maintenance and not (self.maintenance_sw and self.maintenance_en):
            raise ValueError("Write the maintenance message in both languages")
        return self


class Seo(Section):
    """What search engines ask for. Public: all of it is served to anyone who asks."""

    google_verification: str = _field(
        "", "Google Search Console code", "Msimbo wa Google Search Console", pattern=r"^[A-Za-z0-9_-]{0,100}$"
    )
    bing_verification: str = _field(
        "", "Bing Webmaster code", "Msimbo wa Bing Webmaster", pattern=r"^[A-Za-z0-9]{0,64}$"
    )
    indexnow: bool = _field(False, "Tell search engines at once (IndexNow)", "Julisha injini za utafutaji")
    indexnow_key: str = _field("", "IndexNow key", "Ufunguo wa IndexNow", pattern=r"^([a-f0-9]{32})?$")
    same_as: list[Url] = _field(
        [], "The publisher's profiles elsewhere", "Kurasa za mchapishaji kwingine", max_length=12
    )
    app_banner: bool = _field(False, "Offer the app on phones", "Pendekeza programu kwenye simu")

    @model_validator(mode="after")
    def _key(self) -> Seo:
        if self.indexnow and not self.indexnow_key:
            raise ValueError("IndexNow needs a key of 32 hexadecimal characters")
        return self


class Engagement(Section):
    """Global defaults and kill switches (engagement.policy)."""

    defaults: Policy = Policy()
    kill: KillSwitches = KillSwitches()
    # Views, likes and comments on the cards of lists, before a story is opened. A count a story does not
    # allow (likes off, comments closed) is never shown, whatever this says.
    card_counts: bool = _field(True, "Show counts on story cards", "Onyesha idadi kwenye kadi za habari")
    # Web Push to every browser that asked, when a story is first published (ADR-0051).
    push_new_stories: bool = _field(
        True, "Notify readers of each new story", "Wajulishe wasomaji kila habari mpya"
    )


CallingCode = Annotated[str, Field(pattern=r"^[1-9][0-9]{0,3}$")]


class SignIn(Section):
    """How readers sign in (ADR-0050). The vendors' keys are in Integrations; these are the rules around
    them."""

    phone: bool = _field(True, "Phone and SMS code", "Simu na msimbo wa SMS")
    google: bool = _field(True, "Google", "Google")
    apple: bool = _field(True, "Apple", "Apple")
    countries: list[CallingCode] = _field(
        ["255"], "Countries SMS codes may go to (calling codes)", "Nchi zinazoweza kupokea SMS", max_length=60
    )
    code_minutes: int = _field(5, "A code lasts (minutes)", "Msimbo unadumu (dakika)", ge=2, le=15)
    attempts: int = _field(5, "Tries for one code", "Majaribio kwa msimbo mmoja", ge=3, le=10)
    resend_seconds: int = _field(
        60, "Wait before another code (seconds)", "Subiri kabla ya msimbo mwingine", ge=30, le=600
    )
    per_phone_daily: int = _field(
        8, "Codes to one number a day", "Misimbo kwa namba moja kwa siku", ge=3, le=50
    )
    per_ip_hourly: int = _field(
        20, "Codes from one network an hour", "Misimbo kutoka mtandao mmoja kwa saa", ge=5, le=500
    )
    per_prefix_hourly: int = _field(
        200, "Codes to one number range an hour", "Misimbo kwa kundi la namba kwa saa", ge=10, le=5000
    )
    sms_hourly_budget: int = _field(
        3000, "All SMS codes an hour (budget)", "SMS zote kwa saa (bajeti)", ge=10, le=500000
    )
    android_app_hash: str = _field(
        "",
        "Android app hash (SMS autofill)",
        "Hash ya programu ya Android",
        pattern=r"^([A-Za-z0-9+/]{11})?$",
    )
    terms_version: str = _field(
        "2026-11", "Terms version readers accept", "Toleo la masharti", pattern=r"^[0-9A-Za-z._-]{1,20}$"
    )


SECTIONS: dict[str, type[Section]] = {
    "brand": Brand,
    "localization": Localization,
    "app": App,
    "seo": Seo,
    "security": Security,
    "engagement": Engagement,
    "sign_in": SignIn,
}
