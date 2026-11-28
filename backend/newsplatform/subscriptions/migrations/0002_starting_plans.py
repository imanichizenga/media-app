"""Plans to start from (ADR-0052): three a month, and the same three a year for ten months' price. The newsroom
changes or hides them in Subscriptions; nothing here is fixed."""

from django.db import migrations

_FEATURES = {
    "basic": (
        ["Habari zote za wanachama", "Kwenye simu na kompyuta", "Bila matangazo"],
        ["Every subscriber story", "On your phone and computer", "No ads"],
    ),
    "standard": (
        [
            "Habari zote za wanachama",
            "Uchambuzi na ripoti maalum",
            "Bila matangazo",
            "Habari kwanza kabla ya wengine",
        ],
        [
            "Every subscriber story",
            "Analysis and special reports",
            "No ads",
            "Big stories before anyone else",
        ],
    ),
    "family": (
        [
            "Kila kitu cha Kamili",
            "Vifaa vingi kwa wakati mmoja",
            "Kumbukumbu ya habari zote",
            "Msaada wa haraka",
        ],
        [
            "Everything in Standard",
            "Many devices at once",
            "The whole archive",
            "Priority help",
        ],
    ),
}
_TIERS = [
    # code, Swahili name, English name, price a month, tone, highlighted
    ("basic", "Msingi", "Basic", 3_000, "ocean", False),
    ("standard", "Kamili", "Standard", 5_000, "brand", True),
    ("family", "Familia", "Premium", 9_000, "violet", False),
]


def plans(apps, schema_editor):
    Plan = apps.get_model("subscriptions", "Plan")
    if Plan.objects.exists():
        return
    for position, (code, sw, en, price, tone, top) in enumerate(_TIERS):
        features_sw, features_en = _FEATURES[code]
        for interval in ("month", "year"):
            yearly = interval == "year"
            Plan.objects.create(
                code=f"{code}-{interval}",
                interval=interval,
                price=price * 10 if yearly else price,
                name_sw=sw,
                name_en=en,
                tagline_sw="Miezi 12 kwa bei ya 10" if yearly else "Lipa kila mwezi, acha wakati wowote",
                tagline_en="Twelve months for the price of ten" if yearly else "Pay monthly, stop any time",
                features_sw=features_sw,
                features_en=features_en,
                badge_sw=("Maarufu zaidi" if top else "") if not yearly else "Okoa 17%",
                badge_en=("Most popular" if top else "") if not yearly else "Save 17%",
                tone=tone,
                highlighted=top,
                position=position,
            )


class Migration(migrations.Migration):
    dependencies = [("subscriptions", "0001_initial")]
    operations = [migrations.RunPython(plans, migrations.RunPython.noop)]
