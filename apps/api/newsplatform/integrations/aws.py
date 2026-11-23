import re
from typing import Any

import boto3
from botocore.config import Config
from django.conf import settings
from pydantic import Field, SecretStr, model_validator

from newsplatform.integrations.base import ProviderConfig

_ROLE = re.compile(r"^arn:aws[a-z-]*:iam::\d{12}:role/.+$")


def field(default: Any, en: str, sw: str, *, help_en: str = "", help_sw: str = "", **kw: Any) -> Any:
    return Field(
        default,
        title=en,
        description=help_en,
        json_schema_extra={"x-title-sw": sw, "x-help-sw": help_sw},
        **kw,
    )


class AwsConfig(ProviderConfig):
    region: str = field(..., "AWS region", "Eneo la AWS", pattern=r"^[a-z]{2}(-[a-z]+)+-\d$")
    role_arn: str = field(
        "",
        "Role to assume (optional)",
        "Jukumu la kuchukua (hiari)",
        help_en="Leave empty to use the task role (recommended).",
        help_sw="Acha wazi kutumia jukumu la seva (inapendekezwa).",
    )
    access_key_id: str = field("", "Access key ID (optional)", "Kitambulisho cha ufunguo (hiari)")
    secret_access_key: SecretStr | None = field(None, "Secret access key", "Ufunguo wa siri")

    @model_validator(mode="after")
    def _credentials(self) -> AwsConfig:
        if bool(self.access_key_id) != bool(self.secret_access_key):
            raise ValueError("Provide both the access key ID and the secret, or neither")
        if self.role_arn and not _ROLE.match(self.role_arn):
            raise ValueError("role_arn is not an IAM role ARN")
        return self


def client(config: AwsConfig, service: Any, region: str | None = None) -> Any:
    region = region or config.region
    keys: dict[str, Any] = {}
    if config.access_key_id and config.secret_access_key:
        keys = {
            "aws_access_key_id": config.access_key_id,
            "aws_secret_access_key": config.secret_access_key.get_secret_value(),
        }
    opts = Config(
        connect_timeout=3,
        read_timeout=10,
        retries={"max_attempts": 2, "mode": "standard"},
        signature_version="s3v4" if service == "s3" else None,
    )
    endpoint = settings.AWS_ENDPOINT_URL or None
    if config.role_arn:
        sts = boto3.client("sts", region_name=region, endpoint_url=endpoint, config=opts, **keys)
        creds = sts.assume_role(RoleArn=config.role_arn, RoleSessionName="newsplatform")["Credentials"]
        keys = {
            "aws_access_key_id": creds["AccessKeyId"],
            "aws_secret_access_key": creds["SecretAccessKey"],
            "aws_session_token": creds["SessionToken"],
        }
    return boto3.client(service, region_name=region, endpoint_url=endpoint, config=opts, **keys)


def whoami(config: AwsConfig) -> str:
    return f"Account {client(config, 'sts').get_caller_identity()['Account']}"
