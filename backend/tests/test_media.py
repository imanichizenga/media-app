import socket
import struct
import threading
from datetime import timedelta
from pathlib import Path

import boto3
import httpx
import pytest
import pyvips
from celery.exceptions import Retry
from django.core import checks
from django.utils import timezone
from moto.server import ThreadedMotoServer

from newsplatform.audit.models import AuditEntry
from newsplatform.common.errors import Conflict, DomainError, NotFound
from newsplatform.media import images, scanning, services, sniff, tasks, transcoding
from newsplatform.media import storage as storage_module
from newsplatform.media.models import Asset, AssetStatus
from newsplatform.media.storage import Storage
from tests import factories as f

pytestmark = pytest.mark.django_db
SAMPLE = Path(transcoding.__file__).parent / "samples/sample.mp4"
MB = 1024**2


@pytest.fixture(scope="module")
def s3_server():
    server = ThreadedMotoServer(port=0)
    server.start()
    _, port = server.get_host_and_port()
    yield f"http://127.0.0.1:{port}"
    server.stop()


@pytest.fixture
def store(s3_server, monkeypatch, settings):
    settings.STORAGE_ENDPOINT_URL = s3_server
    settings.LOCAL_SCANNER = "eicar"
    settings.LOCAL_TRANSCODER = True
    storage_module._local.cache_clear()
    client = storage_module._local()
    yield Storage(client, "news-media")
    for page in client.get_paginator("list_objects_v2").paginate(Bucket="news-media"):
        for o in page.get("Contents", []):
            client.delete_object(Bucket="news-media", Key=o["Key"])
    storage_module._local.cache_clear()


@pytest.fixture
def journalist(make_staff):
    return make_staff("journalist")


def upload(actor, data: bytes, kind="image", filename="a.jpg", part=None):
    asset = services.begin_upload(actor=actor, kind=kind, filename=filename, size=len(data))
    urls = services.sign_parts(
        actor=actor, asset_id=asset.pk, numbers=list(range(1, services.part_count(asset) + 1))
    )
    for n, url in urls.items():
        chunk = data[(n - 1) * asset.part_size : n * asset.part_size]
        httpx.put(url, content=chunk).raise_for_status()
    return asset


def photo(tmp_path, width=2400, height=1600, fmt="jpg", exif=True):
    ramp = pyvips.Image.xyz(width, height)
    image = (ramp[0] * 255 / width).bandjoin([ramp[1] * 255 / height, ramp[0] * 0 + 90]).cast("uchar")
    image = image.copy(interpretation="srgb")
    if exif:
        image = image.copy()
        for name, value in {
            "exif-ifd0-Make": "SecretCam",
            "exif-ifd0-Artist": "Jina la Mwandishi",
            "exif-ifd3-GPSLatitude": "6/1 48/1 0/1",
            "exif-ifd3-GPSLongitude": "39/1 17/1 0/1",
            "exif-ifd3-GPSLatitudeRef": "S",
        }.items():
            image.set_type(pyvips.GValue.gstr_type, name, value)
        image.set_type(pyvips.GValue.blob_type, "xmp-data", b"<x:xmpmeta>SecretXmp</x:xmpmeta>")
    path = tmp_path / f"photo.{fmt}"
    image.write_to_file(str(path))
    return path


# ---- images ------------------------------------------------------------
def test_the_test_photo_really_carries_gps(tmp_path):
    raw = photo(tmp_path).read_bytes()
    assert b"SecretCam" in raw
    assert b"SecretXmp" in raw
    assert any("GPS" in n for n in pyvips.Image.new_from_buffer(raw, "").get_fields())


def test_every_derivative_is_stripped_of_metadata(tmp_path):
    out = tmp_path / "out"
    out.mkdir()
    made = images.process(photo(tmp_path), out)
    assert len(made.files) == 5 * 3 + 3
    for path, _, _ in made.files:
        raw = path.read_bytes()
        for secret in (b"SecretCam", b"Jina la", b"SecretXmp", b"GPS", b"Exif\x00"):
            assert secret not in raw, (path.name, secret)
        fields = pyvips.Image.new_from_file(str(path)).get_fields()
        assert not [n for n in fields if n.startswith(("exif-", "xmp", "iptc", "icc"))], path.name


def test_variants_have_the_promised_widths_and_types(tmp_path):
    out = tmp_path / "out"
    out.mkdir()
    made = images.process(photo(tmp_path), out)
    assert (made.width, made.height) == (2400, 1600)
    for path, suffix, mime in made.files:
        image = pyvips.Image.new_from_file(str(path))
        if suffix.startswith("crop-"):
            assert (image.width, image.height) == images.CROPS[suffix[5:-4]]
        else:
            assert image.width == int(suffix.split(".")[0])
            assert abs(image.width / image.height - 1.5) < 0.02
        assert sniff.sniff(path.read_bytes()[:64]) == mime
    assert len(made.blurhash) >= 20
    assert made.color.startswith("#")


def test_small_images_are_never_enlarged(tmp_path):
    out = tmp_path / "out"
    out.mkdir()
    made = images.process(photo(tmp_path, 200, 100), out)
    assert set(made.variants["webp"]) == {"200"}
    for path, _, _ in made.files:
        assert pyvips.Image.new_from_file(str(path)).width <= 200


def test_rotation_is_applied_before_it_is_stripped(tmp_path):
    image = pyvips.Image.black(400, 200).copy(interpretation="srgb").bandjoin([0, 0]).copy()
    image.set_type(pyvips.GValue.gint_type, "orientation", 6)
    path, out = tmp_path / "r.jpg", tmp_path / "out"
    out.mkdir()
    image.write_to_file(str(path))
    made = images.process(path, out)
    assert (made.width, made.height) == (200, 400)


def test_crops_keep_the_focal_point(tmp_path):
    left = pyvips.Image.black(1000, 1000).bandjoin([0, 0]).linear(1, [255, 0, 0])
    right = pyvips.Image.black(1000, 1000).bandjoin([0, 0]).linear(1, [0, 0, 255])
    image = left.join(right, "horizontal").cast("uchar").copy(interpretation="srgb")
    path = tmp_path / "two.png"
    image.write_to_file(str(path))
    for x, channel in ((0, 0), (1000, 2)):
        out = tmp_path / str(x)
        out.mkdir()
        images.process(path, out, (x, 500))
        pixel = pyvips.Image.new_from_file(str(out / "crop-1x1.jpg")).getpoint(500, 500)
        assert pixel[channel] > 200


@pytest.mark.parametrize("fmt", ["png", "webp", "avif"])
def test_other_formats_and_transparency(tmp_path, fmt):
    out = tmp_path / "out"
    out.mkdir()
    assert images.process(photo(tmp_path, 800, 600, fmt, exif=False), out).mime == f"image/{fmt}"


def test_greyscale(tmp_path):
    path, out = tmp_path / "g.jpg", tmp_path / "out"
    out.mkdir()
    pyvips.Image.black(500, 400).copy(interpretation="b-w").write_to_file(str(path))
    assert images.process(path, out).color == "#000000"


def test_decompression_bombs_are_refused_from_the_header(tmp_path, monkeypatch):
    monkeypatch.setattr(images, "MAX_PIXELS", 1000)
    with pytest.raises(images.BadImage) as e:
        images.process(photo(tmp_path, 100, 100), tmp_path)
    assert e.value.code == "too_many_pixels"


@pytest.mark.parametrize(
    "raw",
    [
        b"",
        b"<svg xmlns='http://www.w3.org/2000/svg' onload='alert(1)'/>",
        b"<!doctype html><script>alert(1)</script>",
        b"GIF89a" + b"\0" * 50,
        b"MZ" + b"\0" * 100,
        b"%PDF-1.7",
        b"#EXTM3U\nfile:///etc/passwd",
        b"RIFF\0\0\0\0AVI " + b"\0" * 40,
    ],
)
def test_only_accepted_types_by_their_bytes(tmp_path, raw):
    path = tmp_path / "x.jpg"
    path.write_bytes(raw)
    assert sniff.sniff(raw[:64]) not in sniff.IMAGE_TYPES
    with pytest.raises(images.BadImage):
        images.process(path, tmp_path)


def test_a_truncated_image_is_unreadable(tmp_path):
    path = photo(tmp_path)
    path.write_bytes(path.read_bytes()[:2000])
    with pytest.raises(images.BadImage) as e:
        images.process(path, tmp_path)
    assert e.value.code == "unreadable"


# ---- upload --------------------------------------------------------------
def test_photo_from_upload_to_ready(journalist, store, tmp_path, django_capture_on_commit_callbacks):
    with django_capture_on_commit_callbacks(execute=True):
        asset = upload(journalist, photo(tmp_path).read_bytes())
        services.complete_upload(actor=journalist, asset_id=asset.pk)
    asset.refresh_from_db()
    assert asset.status == AssetStatus.READY
    assert set(asset.outputs["variants"]) == {"avif", "webp", "jpeg"}
    served = store.keys("media/")
    assert set(asset.outputs["variants"]["avif"].values()) <= set(served)
    for key in served:
        assert b"SecretCam" not in store.read(key)
    assert asset.original_key.startswith("originals/")
    head = store.s3.head_object(Bucket=store.bucket, Key=asset.outputs["variants"]["webp"]["640"])
    assert head["ContentType"] == "image/webp"
    assert "immutable" in head["CacheControl"]


def test_an_interrupted_upload_continues_where_it_stopped(journalist, store, monkeypatch):
    monkeypatch.setattr(services, "MIN_PART", 5 * MB)
    data = b"\x07" * (12 * MB)
    asset = services.begin_upload(actor=journalist, kind="video", filename="v.mp4", size=len(data))
    urls = services.sign_parts(actor=journalist, asset_id=asset.pk, numbers=[1, 2, 3])
    httpx.put(urls[1], content=data[: 5 * MB]).raise_for_status()
    assert services.uploaded_parts(actor=journalist, asset_id=asset.pk) == [1]
    with pytest.raises(Conflict) as e:
        services.complete_upload(actor=journalist, asset_id=asset.pk)
    assert e.value.code == "parts_missing"
    httpx.put(urls[2], content=data[5 * MB : 10 * MB]).raise_for_status()
    httpx.put(urls[3], content=data[10 * MB :]).raise_for_status()
    monkeypatch.setattr(tasks.process, "delay", lambda _: None)
    assert services.complete_upload(actor=journalist, asset_id=asset.pk).status == AssetStatus.SCANNING
    assert store.read(asset.original_key) == data


def test_a_short_part_is_not_counted_as_uploaded(journalist, store, monkeypatch):
    monkeypatch.setattr(services, "MIN_PART", 5 * MB)
    asset = services.begin_upload(actor=journalist, kind="video", filename="v.mp4", size=8 * MB)
    url = store.s3.generate_presigned_url(
        "upload_part",
        Params={
            "Bucket": store.bucket,
            "Key": asset.original_key,
            "UploadId": asset.upload_id,
            "PartNumber": 1,
        },
    )
    httpx.put(url, content=b"x" * 100).raise_for_status()
    assert services.uploaded_parts(actor=journalist, asset_id=asset.pk) == []


def test_signed_urls_bind_the_length(journalist, store):
    asset = services.begin_upload(actor=journalist, kind="image", filename="a.jpg", size=1000)
    url = services.sign_parts(actor=journalist, asset_id=asset.pk, numbers=[1])[1]
    assert "content-length" in url.lower()


@pytest.mark.parametrize(
    ("kind", "size", "code"),
    [
        ("image", 0, "file_too_large"),
        ("image", 61 * MB, "file_too_large"),
        ("video", 9 * 1024**3, "file_too_large"),
        ("audio", 10, "validation_error"),
    ],
)
def test_limits(journalist, store, kind, size, code):
    with pytest.raises(DomainError) as e:
        services.begin_upload(actor=journalist, kind=kind, filename="x", size=size)
    assert e.value.code == code


def test_part_size_grows_so_large_files_fit(journalist, store):
    asset = services.begin_upload(actor=journalist, kind="video", filename="x", size=8 * 1024**3)
    assert services.part_count(asset) <= services.MAX_PARTS < 10_000


def test_uploads_belong_to_the_uploader(journalist, make_staff, store):
    asset = services.begin_upload(actor=journalist, kind="image", filename="a", size=10)
    other = make_staff("editor_in_chief")
    for action in (
        lambda: services.sign_parts(actor=other, asset_id=asset.pk, numbers=[1]),
        lambda: services.uploaded_parts(actor=other, asset_id=asset.pk),
        lambda: services.complete_upload(actor=other, asset_id=asset.pk),
        lambda: services.cancel_upload(actor=other, asset_id=asset.pk),
    ):
        with pytest.raises(NotFound):
            action()


@pytest.mark.parametrize("numbers", [[], [0], [2], list(range(1, 60))])
def test_part_numbers_are_checked(journalist, store, numbers):
    asset = services.begin_upload(actor=journalist, kind="image", filename="a", size=10)
    with pytest.raises(DomainError):
        services.sign_parts(actor=journalist, asset_id=asset.pk, numbers=numbers)


@pytest.mark.parametrize("name", ["../../etc/passwd", "C:\\x\\passwd", "passwd"])
def test_file_names_are_labels_only(journalist, store, name):
    asset = services.begin_upload(actor=journalist, kind="image", filename=name, size=10)
    assert asset.filename == "passwd"
    assert "passwd" not in asset.original_key


# ---- scanning ------------------------------------------------------------
def test_malware_is_rejected_audited_and_removed(journalist, store, django_capture_on_commit_callbacks):
    with django_capture_on_commit_callbacks(execute=True):
        asset = upload(journalist, b"\xff\xd8\xff" + b"0" * 2_000_000 + scanning.EICAR)
        services.complete_upload(actor=journalist, asset_id=asset.pk)
    asset.refresh_from_db()
    assert (asset.status, asset.error_code) == (AssetStatus.REJECTED, "malware")
    assert store.keys("originals/") == []
    assert store.keys("media/") == []
    assert AuditEntry.objects.filter(action="media.rejected").count() == 1


def test_nothing_is_processed_without_a_scanner(journalist, store, settings, tmp_path):
    settings.LOCAL_SCANNER = ""
    with pytest.raises(DomainError) as e:
        scanning.scanner()
    assert e.value.code == "scanner_not_configured"


@pytest.mark.parametrize(
    ("status", "clean"),
    [("NO_THREATS_FOUND", True), ("THREATS_FOUND", False), ("UNSUPPORTED", False), ("FAILED", False)],
)
def test_guardduty_verdicts(status, clean):
    class Fake:
        def tags(self, key):
            return {"GuardDutyMalwareScanStatus": status}

    assert scanning.GuardDuty().is_clean(Fake(), "k", Path()) is clean


def test_guardduty_waits_for_a_verdict():
    class Fake:
        def tags(self, key):
            return {}

    with pytest.raises(scanning.NotReady):
        scanning.GuardDuty().is_clean(Fake(), "k", Path())


class RemoteScanner:
    remote = True

    def __init__(self, verdict: bool | None):
        self.verdict = verdict

    def is_clean(self, storage, key, path):
        assert path is None
        if self.verdict is None:
            raise scanning.NotReady
        return self.verdict


def _uploaded(journalist, kind="image", data=b"\xff\xd8\xff" + b"0" * 1000):
    asset = upload(journalist, data, kind=kind)
    services.complete_upload(actor=journalist, asset_id=asset.pk)
    asset.refresh_from_db()
    return asset


@pytest.mark.parametrize("verdict", [None, False])
def test_an_original_is_never_opened_before_a_clean_remote_verdict(journalist, store, monkeypatch, verdict):
    asset = _uploaded(journalist)
    monkeypatch.setattr(tasks, "scanner", lambda: RemoteScanner(verdict))
    for name in ("download", "head", "read"):
        monkeypatch.setattr(type(store), name, lambda *a, **k: pytest.fail("read before the verdict"))
    if verdict is None:
        with pytest.raises(scanning.NotReady):
            tasks._process(asset)
    else:
        tasks._process(asset)
        asset.refresh_from_db()
        assert (asset.status, asset.error_code) == (AssetStatus.REJECTED, "malware")
        assert store.keys("originals/") == []


def test_video_does_not_pass_through_the_worker_when_the_scan_is_remote(journalist, store, monkeypatch):
    asset = _uploaded(journalist, "video", b"\0\0\0\x18ftypmp42" + b"0" * 1000)
    started = []

    class Transcoder:
        def start(self, storage, asset, prefix):
            started.append(prefix)
            return "job-1"

        def status(self, job_id):
            return "running", ""

    monkeypatch.setattr(tasks, "scanner", lambda: RemoteScanner(True))
    monkeypatch.setattr(transcoding, "transcoder", Transcoder)
    monkeypatch.setattr(type(store), "download", lambda *a, **k: pytest.fail("downloaded"))
    with pytest.raises(scanning.NotReady):
        tasks._process(asset)
    asset.refresh_from_db()
    assert (asset.status, asset.mime, asset.job_id) == (AssetStatus.PROCESSING, "video/mp4", "job-1")
    assert started == [transcoding.prefix_of(asset)]


def clamd(reply: bytes):
    """A tiny clamd: reads INSTREAM frames and answers."""
    server = socket.create_server(("127.0.0.1", 0))
    got = bytearray()

    def serve():
        conn, _ = server.accept()
        with conn, conn.makefile("rb") as stream:
            assert stream.read(10) == b"zINSTREAM\0"
            while size := struct.unpack(">I", stream.read(4))[0]:
                got.extend(stream.read(size))
            conn.sendall(reply)

    threading.Thread(target=serve, daemon=True).start()
    return scanning.ClamAv("127.0.0.1", server.getsockname()[1]), got


def test_clamav_protocol(tmp_path):
    path = tmp_path / "f"
    path.write_bytes(b"x" * 200_000)
    scan, got = clamd(b"stream: OK\0")
    assert scan.is_clean(None, "k", path)
    assert bytes(got) == path.read_bytes()
    scan, _ = clamd(b"stream: Eicar-Test-Signature FOUND\0")
    assert not scan.is_clean(None, "k", path)
    scan, _ = clamd(b"INSTREAM size limit exceeded. ERROR\0")
    with pytest.raises(RuntimeError):
        scan.is_clean(None, "k", path)


# ---- video -----------------------------------------------------------------
@pytest.mark.parametrize(
    ("size", "names"),
    [
        ((1920, 1080), ["240p", "360p", "480p", "720p", "1080p"]),
        ((1080, 1920), ["240p", "360p", "480p", "720p", "1080p"]),
        ((3840, 2160), ["240p", "360p", "480p", "720p", "1080p"]),
        ((854, 480), ["240p", "360p", "480p"]),
        ((320, 180), ["240p"]),
    ],
)
def test_ladder(size, names):
    steps = transcoding.ladder(*size)
    assert [r.name for r, _, _ in steps] == names
    for _, w, h in steps:
        assert w % 2 == h % 2 == 0
        assert w <= size[0] + 1
        assert abs(w / h - size[0] / size[1]) < 0.03


def test_video_from_upload_to_adaptive_stream(
    journalist, store, tmp_path, django_capture_on_commit_callbacks
):
    with django_capture_on_commit_callbacks(execute=True):
        asset = upload(journalist, SAMPLE.read_bytes(), "video", "v.mp4")
        services.complete_upload(actor=journalist, asset_id=asset.pk)
    asset.refresh_from_db()
    assert (asset.status, asset.error_code) == (AssetStatus.READY, "")
    assert (asset.width, asset.height) == (640, 360)
    assert 2900 <= asset.duration_ms <= 3100
    prefix = transcoding.prefix_of(asset)
    master = store.read(asset.outputs["hls"]).decode()
    assert master.count("#EXT-X-STREAM-INF") == 2
    for name in ("240p", "360p"):
        assert f"master_{name}.m3u8" in master
        playlist = store.read(f"{prefix}hls/master_{name}.m3u8").decode()
        assert "#EXT-X-ENDLIST" in playlist
        assert "#EXT-X-MAP" in playlist
        for line in playlist.splitlines():
            if line and not line.startswith("#"):
                assert store.size(f"{prefix}hls/{line}") > 0
    assert store.read(asset.outputs["sprite_vtt"]).decode().startswith("WEBVTT")
    assert sniff.sniff(store.read(asset.outputs["poster"])[:64]) == "image/jpeg"
    assert store.keys(f"{prefix}frames/") == []


@pytest.mark.parametrize(
    "raw", [b"#EXTM3U\n#EXTINF:1\nfile:///etc/passwd\n", b"\0" * 5000, b"concat:/etc/passwd"]
)
def test_files_that_are_not_video_are_rejected(journalist, store, raw, django_capture_on_commit_callbacks):
    with django_capture_on_commit_callbacks(execute=True):
        asset = upload(journalist, raw, "video", "v.mp4")
        services.complete_upload(actor=journalist, asset_id=asset.pk)
    asset.refresh_from_db()
    assert (asset.status, asset.error_code) == (AssetStatus.REJECTED, "unsupported_type")


def test_a_playlist_dressed_as_mp4_reads_nothing(tmp_path):
    path = tmp_path / "x"
    path.write_bytes(b"#EXTM3U\n#EXT-X-TARGETDURATION:1\n#EXTINF:1,\nfile:///etc/passwd\n#EXT-X-ENDLIST\n")
    with pytest.raises(transcoding.BadVideo):
        transcoding.probe_file(path)


def test_mediaconvert_job_matches_the_layout():
    found = transcoding.Probe(1920, 1080, 600_000, True)
    job = transcoding.job_settings("s3://b/originals/x", "s3://b/media/v/x/", found)
    hls, frames = job["OutputGroups"]
    assert hls["OutputGroupSettings"]["CmafGroupSettings"]["Destination"] == "s3://b/media/v/x/hls/master"
    names = [o["NameModifier"] for o in hls["Outputs"]]
    assert names == [f"_{r.name}" for r in transcoding.LADDER] + ["_audio"]
    capture = frames["Outputs"][0]["VideoDescription"]["CodecSettings"]["FrameCaptureSettings"]
    assert 600 / capture["FramerateDenominator"] <= transcoding.SPRITE_MAX
    silent = transcoding.job_settings("s", "d", transcoding.Probe(640, 360, 1000, False))
    assert all("AudioDescriptions" not in o for o in silent["OutputGroups"][0]["Outputs"])


def test_mediaconvert_settings_are_valid_for_the_api():
    """botocore validates the shape against the service model without calling AWS."""
    from botocore.validate import ParamValidator

    client = boto3.client(
        "mediaconvert", region_name="eu-west-1", aws_access_key_id="a", aws_secret_access_key="b"
    )
    shape = client.meta.service_model.operation_model("CreateJob").input_shape
    found = transcoding.Probe(1080, 1920, 45_000, True)
    report = ParamValidator().validate(
        {
            "Role": "arn:aws:iam::123456789012:role/x",
            "Settings": transcoding.job_settings("s3://b/a", "s3://b/c/", found),
        },
        shape,
    )
    assert not report.has_errors(), report.generate_report()


class FakeConvert:
    def __init__(self, *states):
        self.states = list(states)
        self.started = 0

    def start(self, storage, asset, prefix):
        self.started += 1
        return "job-1"

    def status(self, job_id):
        return self.states.pop(0)

    def probe(self, *_):
        return transcoding.Probe(640, 360, 3000, True)


def test_an_asynchronous_job_is_followed_and_started_once(journalist, store, monkeypatch):
    fake = FakeConvert(("running", ""), ("running", ""), ("failed", "bad codec"))
    monkeypatch.setattr(transcoding, "transcoder", lambda: fake)
    monkeypatch.setattr(tasks.process, "delay", lambda _: None)
    asset = upload(journalist, SAMPLE.read_bytes(), "video", "v.mp4")
    services.complete_upload(actor=journalist, asset_id=asset.pk)
    for _ in range(2):
        with pytest.raises(Retry):
            tasks.process.apply(args=[str(asset.pk)], throw=True)
    tasks.process.apply(args=[str(asset.pk)])
    asset.refresh_from_db()
    assert fake.started == 1
    assert (asset.status, asset.error_code, asset.error_detail) == ("failed", "transcode_failed", "bad codec")


def test_a_job_that_never_ends_is_given_up(journalist, store, monkeypatch):
    monkeypatch.setattr(transcoding, "transcoder", lambda: FakeConvert(("running", "")))
    asset = f.asset("video", status="processing", job_id="job-1")
    Asset.objects.filter(pk=asset.pk).update(updated_at=timezone.now() - timedelta(hours=13))
    tasks.process.apply(args=[str(asset.pk)])
    asset.refresh_from_db()
    assert asset.error_code == "timeout"


def test_failures_are_retried_then_kept_for_a_person(journalist, store, monkeypatch, tmp_path):
    monkeypatch.setattr(tasks.process, "delay", lambda _: None)
    asset = upload(journalist, photo(tmp_path).read_bytes())
    services.complete_upload(actor=journalist, asset_id=asset.pk)

    def broken(*_):
        raise ConnectionError

    monkeypatch.setattr(images, "process", broken)
    for _ in range(services.MAX_ATTEMPTS - 1):
        with pytest.raises(Retry):
            tasks.process.apply(args=[str(asset.pk)], throw=True)
    tasks.process.apply(args=[str(asset.pk)])
    asset.refresh_from_db()
    assert (asset.status, asset.error_code) == ("failed", "processing_failed")
    asset = services.retry(actor=journalist, asset_id=asset.pk)
    assert (asset.status, asset.attempts) == ("scanning", 0)


def test_a_retry_starts_a_new_job(journalist, store, monkeypatch, tmp_path):
    asset = f.asset("video", status="failed", uploaded_by=journalist)
    tokens = []

    class Api:
        def probe(self, **_):
            track = {"TrackType": "video", "VideoProperties": {"Width": 640, "Height": 360}}
            return {"ProbeResults": [{"Container": {"Duration": 3.0, "Tracks": [track]}}]}

        def create_job(self, **job):
            tokens.append(job["ClientRequestToken"])
            return {"Job": {"Id": "j"}}

    monkeypatch.setattr(tasks.process, "delay", lambda _: None)
    worker = transcoding.MediaConvert.__new__(transcoding.MediaConvert)
    worker.config, worker.api = type("C", (), {"job_role_arn": "r", "queue_arn": ""})(), Api()
    worker.start(store, asset, "p/")
    worker.start(store, asset, "p/")  # the same task delivered twice
    asset = services.retry(actor=journalist, asset_id=asset.pk)
    worker.start(store, asset, "p/")
    assert tokens[0] == tokens[1] != tokens[2]


def test_processing_twice_changes_nothing(journalist, store, tmp_path, django_capture_on_commit_callbacks):
    with django_capture_on_commit_callbacks(execute=True):
        asset = upload(journalist, photo(tmp_path).read_bytes())
        services.complete_upload(actor=journalist, asset_id=asset.pk)
    before = sorted(store.keys(""))
    tasks.process.apply(args=[str(asset.pk)])
    assert sorted(store.keys("")) == before


def test_sprite_cues_cover_the_whole_video():
    vtt = transcoding.sprite_vtt(12, 160, 90, 2, 23_500)
    assert "00:00:22.000 --> 00:00:23.500" in vtt
    assert "xywh=160,90,160,90" in vtt


# ---- library ----------------------------------------------------------------
def test_editing_and_usage(journalist, make_staff, monkeypatch):
    from newsplatform.content import tasks as content_tasks

    monkeypatch.setattr(content_tasks.announce, "delay", lambda *_: None)
    editor = make_staff("editor_in_chief")
    cat, pic = f.category(), f.asset(uploaded_by=journalist)
    image = {"type": "image", "id": "block-2", "asset": str(pic.pk), "alt": "a"}
    texts = {"sw": {"headline": "H", "body": f.body("a", image)}}
    post = f.post(editor, cat, texts=texts)
    assert services.usage(pic) == [post.pk]
    with pytest.raises(Conflict) as e:
        services.delete(actor=editor, asset_id=pic.pk)
    assert e.value.code == "asset_in_use"
    services.update(actor=journalist, asset_id=pic.pk, data={"credit": "Mpya"})
    with pytest.raises(DomainError):
        services.update(actor=make_staff("journalist"), asset_id=pic.pk, data={"credit": "x"})


def test_prune_removes_what_nobody_needs(journalist, store, monkeypatch):
    abandoned = services.begin_upload(actor=journalist, kind="image", filename="a", size=10)
    fresh = services.begin_upload(actor=journalist, kind="image", filename="b", size=10)
    gone = f.asset(deleted_at=timezone.now() - timedelta(days=31), original_key="originals/zz")
    kept = f.asset(deleted_at=timezone.now() - timedelta(days=29))
    store.s3.put_object(Bucket=store.bucket, Key="media/i/zz/640.webp", Body=b"x")
    Asset.objects.filter(pk=abandoned.pk).update(created_at=timezone.now() - timedelta(days=2))
    assert services.prune() == 2
    assert set(Asset.objects.values_list("pk", flat=True)) == {fresh.pk, kept.pk}
    assert store.keys("media/i/zz/") == []
    assert gone.pk


@pytest.mark.parametrize(
    "name", ["STORAGE_ENDPOINT_URL", "LOCAL_TRANSCODER", "LOCAL_SCANNER", "LOCAL_WEB_ORIGIN"]
)
def test_stand_ins_are_refused_when_deployed(settings, name):
    settings.IS_DEPLOYED = True
    setattr(settings, name, "eicar")
    assert any(name in e.msg for e in checks.run_checks())


def test_logos_keep_their_transparency(tmp_path):
    source = tmp_path / "logo.png"
    pyvips.Image.black(400, 200, bands=4).copy(interpretation="srgb").write_to_file(str(source))
    out = tmp_path / "out"
    out.mkdir()
    images.process(source, out)
    for name in ("320.webp", "320.avif"):
        assert pyvips.Image.new_from_file(str(out / name)).hasalpha()
    jpeg = pyvips.Image.new_from_file(str(out / "320.jpg"))
    assert not jpeg.hasalpha()
    assert min(jpeg.getpoint(0, 0)) > 250  # on white


def test_moving_the_focal_point_never_takes_a_picture_away(
    journalist, store, tmp_path, monkeypatch, django_capture_on_commit_callbacks
):
    with django_capture_on_commit_callbacks(execute=True):
        asset = upload(journalist, photo(tmp_path).read_bytes())
        services.complete_upload(actor=journalist, asset_id=asset.pk)
    asset.refresh_from_db()
    old = asset.outputs["crops"]["1x1"]
    queued = []
    monkeypatch.setattr(tasks.recrop, "delay", queued.append)
    with django_capture_on_commit_callbacks(execute=True):
        services.update(actor=journalist, asset_id=asset.pk, data={"focal_x": 100})
    asset.refresh_from_db()
    assert (asset.status, asset.outputs["crops"]["1x1"]) == (AssetStatus.READY, old)
    assert queued == [str(asset.pk)]
    tasks.recrop.apply(args=queued)
    asset.refresh_from_db()
    assert "/100-500/" in asset.outputs["crops"]["1x1"]
    assert store.keys(asset.outputs["crops"]["1x1"])
    # A slow task for an older point must not undo a newer one.
    services.recropped(asset.pk, (500, 500), {"crops": {}, "variants": {}})
    asset.refresh_from_db()
    assert "/100-500/" in asset.outputs["crops"]["1x1"]
