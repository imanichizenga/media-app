"""Local development only: serves media/ from SeaweedFS, in CloudFront's place. The route exists only with
STORAGE_ENDPOINT_URL, which a system check refuses in deployed environments."""

import mimetypes

from botocore.exceptions import ClientError
from django.http import HttpRequest, HttpResponse
from django.views.decorators.http import require_safe

from newsplatform.media.storage import IMMUTABLE, storage
from newsplatform.media.transcoding import TYPES


@require_safe
def serve(request: HttpRequest, path: str) -> HttpResponse:
    if ".." in path:
        return HttpResponse(status=404)
    store = storage()
    wanted = {"Range": request.headers["Range"]} if "Range" in request.headers else {}
    try:
        got = store.s3.get_object(Bucket=store.bucket, Key=f"media/{path}", **wanted)
    except ClientError:
        return HttpResponse(status=404)
    suffix = "." + path.rsplit(".", 1)[-1]
    kind = TYPES.get(suffix) or mimetypes.guess_type(path)[0] or "application/octet-stream"
    response = HttpResponse(got["Body"].read(), content_type=kind, status=206 if wanted else 200)
    response["Cache-Control"] = IMMUTABLE
    response["Accept-Ranges"] = "bytes"
    response["Access-Control-Allow-Origin"] = "*"
    response["Cross-Origin-Resource-Policy"] = "cross-origin"
    if "ContentRange" in got:
        response["Content-Range"] = got["ContentRange"]
    return response
