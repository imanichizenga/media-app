"""Object storage contract, run against whatever S3_CONTRACT_ENDPOINT points at (see ADR-0022).

docker compose --profile storage up -d --wait
cd apps/api && S3_CONTRACT_ENDPOINT=http://127.0.0.1:8333 uv run python -m tests.live_storage
"""

import contextlib
import os
import sys
import uuid
from typing import Any

import boto3
import httpx
from botocore.config import Config
from botocore.exceptions import ClientError

PART = 5 * 1024 * 1024


def run(s3: Any, bucket: str, anonymous_url: str) -> list[tuple[str, bool]]:
    key, results = f"contract/{uuid.uuid4()}", []
    upload = s3.create_multipart_upload(Bucket=bucket, Key=key, ContentType="video/mp4")["UploadId"]
    body = os.urandom(PART * 2 + 12345)

    def put(number: int) -> str:
        url = s3.generate_presigned_url(
            "upload_part",
            Params={"Bucket": bucket, "Key": key, "UploadId": upload, "PartNumber": number},
            ExpiresIn=60,
        )
        res = httpx.put(url, content=body[(number - 1) * PART : number * PART], timeout=60)
        res.raise_for_status()
        return res.headers["etag"]

    put(1)
    put(2)  # the connection drops here; a new client asks what arrived
    parts = s3.list_parts(Bucket=bucket, Key=key, UploadId=upload)["Parts"]
    results.append(
        ("an interrupted upload lists its finished parts", [p["PartNumber"] for p in parts] == [1, 2])
    )
    done = [{"PartNumber": p["PartNumber"], "ETag": p["ETag"]} for p in parts]
    done.append({"PartNumber": 3, "ETag": put(3)})
    s3.complete_multipart_upload(Bucket=bucket, Key=key, UploadId=upload, MultipartUpload={"Parts": done})
    got = s3.get_object(Bucket=bucket, Key=key)
    results.append(("resumed upload is byte identical", got["Body"].read() == body))
    results.append(("content type is kept", got["ContentType"] == "video/mp4"))
    ranged = s3.get_object(Bucket=bucket, Key=key, Range="bytes=100-199")
    results.append(("range requests work", ranged["Body"].read() == body[100:200]))
    results.append(
        ("anonymous read is refused", httpx.get(f"{anonymous_url}/{key}").status_code in (401, 403))
    )
    url = s3.generate_presigned_url("get_object", Params={"Bucket": bucket, "Key": key}, ExpiresIn=60)
    results.append(("a tampered signature is refused", httpx.get(url[:-4] + "0000").status_code == 403))
    s3.delete_object(Bucket=bucket, Key=key)
    try:
        s3.head_object(Bucket=bucket, Key=key)
        gone = False
    except ClientError as exc:
        gone = exc.response["Error"]["Code"] in ("404", "NoSuchKey")
    results.append(("deleted means gone", gone))
    return results


def main() -> int:
    endpoint, bucket = os.environ["S3_CONTRACT_ENDPOINT"], "contract"
    s3 = boto3.client(
        "s3",
        endpoint_url=endpoint,
        region_name="us-east-1",
        aws_access_key_id="local-dev-only",
        aws_secret_access_key="local-dev-only",
        config=Config(signature_version="s3v4", s3={"addressing_style": "path"}),
    )
    with contextlib.suppress(s3.exceptions.BucketAlreadyOwnedByYou, s3.exceptions.BucketAlreadyExists):
        s3.create_bucket(Bucket=bucket)
    results = run(s3, bucket, f"{endpoint}/{bucket}")
    for name, ok in results:
        sys.stdout.write(f"{'PASS' if ok else 'FAIL'} {name}\n")
    return 0 if all(ok for _, ok in results) else 1


if __name__ == "__main__":
    sys.exit(main())
