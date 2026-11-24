"""Object storage. Originals are private for ever; only media/ is ever delivered."""

from functools import lru_cache
from pathlib import Path
from typing import Any

import boto3
from botocore.config import Config
from django.conf import settings

from newsplatform.common.errors import ServiceUnavailable
from newsplatform.integrations.aws import client
from newsplatform.integrations.base import guarded_call
from newsplatform.integrations.providers.s3 import S3Config
from newsplatform.integrations.services import get_active

PRESIGN_SECONDS = 3600
IMMUTABLE = "public, max-age=31536000, immutable"
_LOCAL = "local-dev-only"


@lru_cache
def _local() -> Any:
    return boto3.client(
        "s3",
        endpoint_url=settings.STORAGE_ENDPOINT_URL,
        region_name="us-east-1",
        aws_access_key_id=_LOCAL,
        aws_secret_access_key=_LOCAL,
        config=Config(signature_version="s3v4", s3={"addressing_style": "path"}),
    )


class Storage:
    def __init__(self, s3: Any, bucket: str) -> None:
        self.s3, self.bucket = s3, bucket

    def begin(self, key: str) -> str:
        with guarded_call("aws_s3", "create_multipart"):
            # Served types are set on derivatives. An original is never served, so it claims nothing.
            out = self.s3.create_multipart_upload(
                Bucket=self.bucket, Key=key, ContentType="application/octet-stream"
            )
        return str(out["UploadId"])

    def sign_part(self, key: str, upload_id: str, number: int, size: int) -> str:
        """The length is signed: a client cannot send more than it declared."""
        return str(
            self.s3.generate_presigned_url(
                "upload_part",
                Params={
                    "Bucket": self.bucket,
                    "Key": key,
                    "UploadId": upload_id,
                    "PartNumber": number,
                    "ContentLength": size,
                },
                ExpiresIn=PRESIGN_SECONDS,
            )
        )

    def parts(self, key: str, upload_id: str) -> list[dict[str, Any]]:
        found: list[dict[str, Any]] = []
        marker = 0
        while True:
            with guarded_call("aws_s3", "list_parts"):
                page = self.s3.list_parts(
                    Bucket=self.bucket, Key=key, UploadId=upload_id, PartNumberMarker=marker
                )
            found += page.get("Parts", [])
            if not page.get("IsTruncated"):
                return found
            marker = int(page["NextPartNumberMarker"])

    def complete(self, key: str, upload_id: str, parts: list[dict[str, Any]]) -> None:
        listed = [{"PartNumber": p["PartNumber"], "ETag": p["ETag"]} for p in parts]
        with guarded_call("aws_s3", "complete_multipart"):
            self.s3.complete_multipart_upload(
                Bucket=self.bucket, Key=key, UploadId=upload_id, MultipartUpload={"Parts": listed}
            )

    def abort(self, key: str, upload_id: str) -> None:
        with guarded_call("aws_s3", "abort_multipart"):
            self.s3.abort_multipart_upload(Bucket=self.bucket, Key=key, UploadId=upload_id)

    def size(self, key: str) -> int:
        with guarded_call("aws_s3", "head"):
            return int(self.s3.head_object(Bucket=self.bucket, Key=key)["ContentLength"])

    def download(self, key: str, path: Path) -> None:
        with guarded_call("aws_s3", "download"):
            self.s3.download_file(self.bucket, key, str(path))

    def upload(self, path: Path, key: str, content_type: str) -> None:
        with guarded_call("aws_s3", "upload"):
            self.s3.upload_file(
                str(path),
                self.bucket,
                key,
                ExtraArgs={"ContentType": content_type, "CacheControl": IMMUTABLE},
            )

    def put(self, key: str, data: bytes) -> None:
        with guarded_call("aws_s3", "put"):
            self.s3.put_object(Bucket=self.bucket, Key=key, Body=data, ContentType="application/octet-stream")

    def read(self, key: str) -> bytes:
        with guarded_call("aws_s3", "get"):
            body: bytes = self.s3.get_object(Bucket=self.bucket, Key=key)["Body"].read()
        return body

    def tags(self, key: str) -> dict[str, str]:
        with guarded_call("aws_s3", "get_tags"):
            out = self.s3.get_object_tagging(Bucket=self.bucket, Key=key)
        return {t["Key"]: t["Value"] for t in out["TagSet"]}

    def keys(self, prefix: str) -> list[str]:
        with guarded_call("aws_s3", "list"):
            pages = self.s3.get_paginator("list_objects_v2").paginate(Bucket=self.bucket, Prefix=prefix)
            return [o["Key"] for page in pages for o in page.get("Contents", [])]

    def delete(self, keys: list[str]) -> None:
        for i in range(0, len(keys), 1000):
            with guarded_call("aws_s3", "delete"):
                self.s3.delete_objects(
                    Bucket=self.bucket, Delete={"Objects": [{"Key": k} for k in keys[i : i + 1000]]}
                )


def storage() -> Storage:
    if settings.STORAGE_ENDPOINT_URL:
        return Storage(_local(), "news-media")
    config = get_active("aws_s3", S3Config)
    if config is None:
        raise ServiceUnavailable("Storage is not configured.", code="storage_not_configured")
    return Storage(client(config, "s3"), config.bucket)


def base_url() -> str:
    """Where delivered media lives. Empty means this origin, which only local development serves."""
    if settings.STORAGE_ENDPOINT_URL:
        return ""
    config = get_active("aws_s3", S3Config)
    return f"https://{config.cdn_domain}" if config else ""
