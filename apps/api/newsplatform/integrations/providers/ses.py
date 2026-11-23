from typing import Any

from pydantic import EmailStr

from newsplatform.integrations.aws import AwsConfig, client, field
from newsplatform.integrations.base import Provider, StepFailed, Test, guarded_call, register_provider


class SesConfig(AwsConfig):
    from_email: EmailStr = field(..., "Sender address", "Anwani ya mtumaji")
    from_name: str = field("", "Sender name", "Jina la mtumaji", max_length=60, pattern=r'^[^\r\n"<>]*$')
    configuration_set: str = field(
        "", "Configuration set (optional)", "Seti ya usanidi (hiari)", pattern=r"^[A-Za-z0-9_-]*$"
    )


def send(config: SesConfig, *, to: str, subject: str, text: str) -> str:
    sender = f'"{config.from_name}" <{config.from_email}>' if config.from_name else config.from_email
    extra = {"ConfigurationSetName": config.configuration_set} if config.configuration_set else {}
    out = client(config, "sesv2").send_email(
        FromEmailAddress=sender,
        Destination={"ToAddresses": [to]},
        Content={
            "Simple": {
                "Subject": {"Data": subject, "Charset": "UTF-8"},
                "Body": {"Text": {"Data": text, "Charset": "UTF-8"}},
            }
        },
        **extra,
    )
    return str(out["MessageId"])


def deliver(*, to: str, subject: str, text: str) -> bool:
    """False when email is not configured. Callers must then tell the user, not pretend it was sent."""
    from newsplatform.integrations.services import get_active

    config = get_active("aws_ses", SesConfig)
    if config is None:
        return False
    with guarded_call("aws_ses", "send_email"):
        send(config, to=to, subject=subject, text=text)
    return True


@register_provider
class SesProvider(Provider[SesConfig]):
    key, name, category = "aws_ses", "Amazon SES", "email"
    description_en = "Email for staff invitations and security alerts."
    description_sw = "Barua pepe za mialiko ya wafanyakazi na tahadhari za usalama."
    config_model = SesConfig
    test_params = ["to"]

    def test(self, config: SesConfig, t: Test, params: dict[str, Any]) -> None:
        box: dict[str, Any] = {}

        def account() -> str:
            box["ses"] = client(config, "sesv2")
            info = box["ses"].get_account()
            if not info.get("SendingEnabled"):
                raise StepFailed("Sending is disabled for this account.", "Resolve it in the SES console.")
            return (
                "Production access"
                if info.get("ProductionAccessEnabled")
                else ("Sandbox: mail reaches verified recipients only")
            )

        def identity() -> str:
            domain = config.from_email.split("@")[1]
            for name in (config.from_email, domain):
                try:
                    info = box["ses"].get_email_identity(EmailIdentity=name)
                except box["ses"].exceptions.NotFoundException:
                    continue
                if info.get("VerifiedForSendingStatus"):
                    return f"{'Domain' if name == domain else 'Address'} identity verified"
            raise StepFailed(
                "The sender is not a verified identity.", "Verify the domain in SES and add DKIM records."
            )

        def mail() -> str:
            send(
                config,
                to=params["to"],
                subject="Test email / Barua ya jaribio",
                text="Email works.\nBarua pepe inafanya kazi.",
            )
            return "Accepted by SES"

        t.step("account", "Account status", "Hali ya akaunti", account)
        t.step("identity", "Sender identity", "Utambulisho wa mtumaji", identity, needs="account")
        t.step("send", "Send test email", "Tuma barua ya jaribio", mail, needs="identity")
