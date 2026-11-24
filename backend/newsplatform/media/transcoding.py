"""Video. MediaConvert in AWS, FFmpeg locally: the same ladder and the same files at the same names.

<prefix>hls/master.m3u8
<prefix>hls/master_<rendition>.m3u8      + segments master_<rendition>_*
<prefix>frames/frame.%07d.jpg            one every FRAME_SECONDS, turned into poster and sprite by `finish`
"""

import json
import math
import re
import subprocess
import tempfile
import time
import uuid
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Protocol

import pyvips
from django.conf import settings
from pydantic import field_validator

from newsplatform.common.errors import ServiceUnavailable
from newsplatform.integrations.aws import AwsConfig, client, field, whoami
from newsplatform.integrations.base import Provider, StepFailed, Test, guarded_call, register_provider
from newsplatform.integrations.services import get_active
from newsplatform.media.models import Asset
from newsplatform.media.storage import Storage

FRAME_SECONDS = 2
SEGMENT_SECONDS = 4
SPRITE_COLUMNS, SPRITE_WIDTH, SPRITE_MAX = 10, 160, 200
TYPES = {
    ".m3u8": "application/vnd.apple.mpegurl",
    ".m4s": "video/iso.segment",
    ".cmfv": "video/mp4",
    ".cmfa": "audio/mp4",
    ".mp4": "video/mp4",
}


@dataclass(frozen=True, slots=True)
class Rendition:
    name: str
    short_side: int
    bitrate: int  # bits per second


LADDER = (
    Rendition("240p", 240, 400_000),
    Rendition("360p", 360, 800_000),
    Rendition("480p", 480, 1_400_000),
    Rendition("720p", 720, 2_800_000),
    Rendition("1080p", 1080, 5_000_000),
)


class BadVideo(Exception):
    def __init__(self, code: str, detail: str = "") -> None:
        super().__init__(code)
        self.code, self.detail = code, detail


def ladder(width: int, height: int) -> list[tuple[Rendition, int, int]]:
    """Never larger than the source. The short side names a rendition, so vertical video fits too."""
    short = min(width, height)
    chosen = [r for r in LADDER if r.short_side <= short] or [LADDER[0]]
    out = []
    for r in chosen:
        target = min(r.short_side, short)
        scale = target / short
        # Encoders need even numbers.
        out.append((r, max(2, round(width * scale / 2) * 2), max(2, round(height * scale / 2) * 2)))
    return out


@dataclass(frozen=True, slots=True)
class Probe:
    width: int
    height: int
    duration_ms: int
    has_audio: bool


class Transcoder(Protocol):
    def start(self, storage: Storage, asset: Asset, prefix: str) -> str:
        """Returns a job id, or "" when the work is already done."""
        ...

    def status(self, job_id: str) -> tuple[str, str]:
        """("running" | "done" | "failed", detail)"""
        ...

    def probe(self, storage: Storage, asset: Asset, job_id: str) -> Probe: ...


# ---- FFmpeg ------------------------------------------------------------
def _run(args: Sequence[str], timeout: int) -> str:
    # No shell. Protocols and formats are limited: a crafted playlist inside an upload must not make FFmpeg
    # read local files or open connections.
    try:
        done = subprocess.run(args, capture_output=True, timeout=timeout, check=False)  # noqa: S603
    except subprocess.TimeoutExpired as exc:
        raise BadVideo("timeout") from exc
    if done.returncode != 0:
        raise BadVideo("unreadable", done.stderr.decode(errors="replace")[-300:])
    return done.stdout.decode(errors="replace")


_SAFE = ["-protocol_whitelist", "file", "-format_whitelist", "mov,mp4,m4a,3gp,3g2,mj2,matroska,webm"]


def probe_file(path: Path) -> Probe:
    raw = _run(
        ["ffprobe", "-v", "error", *_SAFE, "-show_streams", "-show_format", "-of", "json", str(path)], 60
    )
    data = json.loads(raw)
    stream = next((s for s in data.get("streams", []) if s.get("codec_type") == "video"), None)
    if stream is None:
        raise BadVideo("no_video")
    width, height = int(stream["width"]), int(stream["height"])
    rotation = next((int(d["rotation"]) for d in stream.get("side_data_list", []) if "rotation" in d), 0)
    if abs(rotation) % 180 == 90:
        width, height = height, width
    seconds = float(data.get("format", {}).get("duration") or stream.get("duration") or 0)
    if not math.isfinite(seconds) or seconds <= 0:
        raise BadVideo("no_duration")
    audio = any(s.get("codec_type") == "audio" for s in data["streams"])
    return Probe(width, height, round(seconds * 1000), audio)


class FFmpeg:
    """Development and tests. Refused by a system check when deployed."""

    def start(self, storage: Storage, asset: Asset, prefix: str) -> str:
        with tempfile.TemporaryDirectory() as tmp:
            source, out = Path(tmp) / "source", Path(tmp) / "out"
            (out / "hls").mkdir(parents=True)
            (out / "frames").mkdir()
            storage.download(asset.original_key, source)
            found = probe_file(source)
            transcode(source, out, found)
            (out / "probe.json").write_text(
                json.dumps([found.width, found.height, found.duration_ms, found.has_audio])
            )
            for path in sorted(p for p in out.rglob("*") if p.is_file()):
                kind = TYPES.get(path.suffix) or (
                    "image/jpeg" if path.suffix == ".jpg" else "application/json"
                )
                storage.upload(path, prefix + str(path.relative_to(out)), kind)
        return ""

    def status(self, job_id: str) -> tuple[str, str]:
        return "done", ""

    def probe(self, storage: Storage, asset: Asset, job_id: str) -> Probe:
        width, height, duration, audio = json.loads(storage.read(f"{prefix_of(asset)}probe.json"))
        return Probe(width, height, duration, audio)


def transcode(source: Path, out: Path, found: Probe) -> None:
    steps = ladder(found.width, found.height)
    args = ["ffmpeg", "-v", "error", "-y", *_SAFE, "-i", str(source)]
    for _ in steps:
        args += ["-map", "0:v:0"] + (["-map", "0:a:0"] if found.has_audio else [])
    for i, (r, w, h) in enumerate(steps):
        args += [
            f"-filter:v:{i}", f"scale={w}:{h}", f"-c:v:{i}", "libx264", f"-b:v:{i}", str(r.bitrate),
            f"-maxrate:v:{i}", str(round(r.bitrate * 1.1)), f"-bufsize:v:{i}", str(r.bitrate * 2),
        ]  # fmt: skip
    args += ["-preset", "veryfast", "-profile:v", "main", "-pix_fmt", "yuv420p", "-sc_threshold", "0"]
    args += ["-force_key_frames", f"expr:gte(t,n_forced*{SEGMENT_SECONDS})", "-map_metadata", "-1"]
    if found.has_audio:
        args += ["-c:a", "aac", "-b:a", "128k", "-ac", "2", "-ar", "48000"]
    streams = " ".join(
        f"v:{i}{f',a:{i}' if found.has_audio else ''},name:{r.name}" for i, (r, _, _) in enumerate(steps)
    )
    args += [
        "-f", "hls", "-hls_time", str(SEGMENT_SECONDS), "-hls_playlist_type", "vod",
        "-hls_segment_type", "fmp4", "-hls_flags", "independent_segments",
        "-hls_fmp4_init_filename", "master_%v_init.mp4",
        "-hls_segment_filename", str(out / "hls/master_%v_%05d.m4s"),
        "-master_pl_name", "master.m3u8", "-var_stream_map", streams, str(out / "hls/master_%v.m3u8"),
    ]  # fmt: skip
    _run(args, 4 * 3600)
    every = max(FRAME_SECONDS, math.ceil(found.duration_ms / 1000 / SPRITE_MAX))
    frames = f"fps=1/{every}:start_time=0:round=up"
    _run(
        ["ffmpeg", "-v", "error", "-y", *_SAFE, "-i", str(source), "-vf", frames,
         "-frames:v", str(SPRITE_MAX), "-q:v", "3", str(out / "frames/frame.%07d.jpg")], 3600,
    )  # fmt: skip


# ---- MediaConvert --------------------------------------------------------
_ROLE = r"^arn:aws[a-z-]*:iam::\d{12}:role/.+$"


class MediaConvertConfig(AwsConfig):
    job_role_arn: str = field(
        ..., "Job role", "Jukumu la kazi", pattern=r"^arn:aws[a-z-]*:iam::\d{12}:role/.+$"
    )
    queue_arn: str = field("", "Queue (optional)", "Foleni (hiari)")
    bucket: str = field(..., "Media bucket", "Ndoo ya media", pattern=r"^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$")

    @field_validator("queue_arn")
    @classmethod
    def _queue(cls, value: str) -> str:
        if value and not re.fullmatch(r"arn:aws[a-z-]*:mediaconvert:[a-z0-9-]+:\d{12}:queues/.+", value):
            raise ValueError("queue_arn is not a MediaConvert queue ARN")
        return value


class MediaConvert:
    def __init__(self, config: MediaConvertConfig) -> None:
        self.config = config
        self.api = client(config, "mediaconvert")

    def start(self, storage: Storage, asset: Asset, prefix: str) -> str:
        source = f"s3://{storage.bucket}/{asset.original_key}"
        with guarded_call("aws_mediaconvert", "probe"):
            info = self.api.probe(InputFiles=[{"FileUrl": source}])["ProbeResults"][0]
        found = _probe_result(info)
        job: dict[str, Any] = {
            "Role": self.config.job_role_arn,
            "Settings": job_settings(source, f"s3://{storage.bucket}/{prefix}", found),
            "UserMetadata": {"asset": str(asset.pk)},
            # A redelivered task must not start a second job.
            "ClientRequestToken": f"{asset.pk}-{asset.run}-{asset.attempts}",
        }
        if self.config.queue_arn:
            job["Queue"] = self.config.queue_arn
        with guarded_call("aws_mediaconvert", "create_job"):
            return str(self.api.create_job(**job)["Job"]["Id"])

    def status(self, job_id: str) -> tuple[str, str]:
        with guarded_call("aws_mediaconvert", "get_job"):
            job = self.api.get_job(Id=job_id)["Job"]
        state = {"COMPLETE": "done", "ERROR": "failed", "CANCELED": "failed"}.get(job["Status"], "running")
        return state, str(job.get("ErrorMessage", ""))[:300]

    def probe(self, storage: Storage, asset: Asset, job_id: str) -> Probe:
        with guarded_call("aws_mediaconvert", "probe"):
            url = f"s3://{storage.bucket}/{asset.original_key}"
            info = self.api.probe(InputFiles=[{"FileUrl": url}])["ProbeResults"][0]
        return _probe_result(info)


def _probe_result(info: dict[str, Any]) -> Probe:
    tracks = info["Container"]["Tracks"]
    track = next((t for t in tracks if t["TrackType"] == "video"), None)
    if track is None:
        raise BadVideo("no_video")
    props = track["VideoProperties"]
    seconds = float(info["Container"]["Duration"])
    audio = any(t["TrackType"] == "audio" for t in tracks)
    return Probe(int(props["Width"]), int(props["Height"]), round(seconds * 1000), audio)


def job_settings(source: str, destination: str, found: Probe) -> dict[str, Any]:
    outputs: list[dict[str, Any]] = []
    for r, w, h in ladder(found.width, found.height):
        outputs.append(
            {
                "NameModifier": f"_{r.name}",
                "ContainerSettings": {"Container": "CMFC"},
                "VideoDescription": {
                    "Width": w,
                    "Height": h,
                    "CodecSettings": {
                        "Codec": "H_264",
                        "H264Settings": {
                            "RateControlMode": "QVBR",
                            "MaxBitrate": r.bitrate,
                            "GopSize": 2,
                            "GopSizeUnits": "SECONDS",
                            "SceneChangeDetect": "TRANSITION_DETECTION",
                            "QualityTuningLevel": "SINGLE_PASS_HQ",
                        },
                    },
                },
            }
        )
    if found.has_audio:
        outputs.append(
            {
                "NameModifier": "_audio",
                "ContainerSettings": {"Container": "CMFC"},
                "AudioDescriptions": [
                    {
                        "CodecSettings": {
                            "Codec": "AAC",
                            "AacSettings": {
                                "Bitrate": 128000,
                                "CodingMode": "CODING_MODE_2_0",
                                "SampleRate": 48000,
                            },
                        }
                    }
                ],
            }
        )
    every = max(FRAME_SECONDS, math.ceil(found.duration_ms / 1000 / SPRITE_MAX))
    return {
        "Inputs": [
            {
                "FileInput": source,
                "AudioSelectors": {"Audio Selector 1": {"DefaultSelection": "DEFAULT"}},
                "VideoSelector": {"Rotate": "AUTO"},
                "TimecodeSource": "ZEROBASED",
            }
        ],
        "OutputGroups": [
            {
                "Name": "HLS",
                "OutputGroupSettings": {
                    "Type": "CMAF_GROUP_SETTINGS",
                    "CmafGroupSettings": {
                        "Destination": f"{destination}hls/master",
                        "SegmentLength": SEGMENT_SECONDS,
                        "FragmentLength": 2,
                        "SegmentControl": "SEGMENTED_FILES",
                        "WriteHlsManifest": "ENABLED",
                        "WriteDashManifest": "DISABLED",
                    },
                },
                "Outputs": outputs,
            },
            {
                "Name": "Frames",
                "OutputGroupSettings": {
                    "Type": "FILE_GROUP_SETTINGS",
                    "FileGroupSettings": {"Destination": f"{destination}frames/frame"},
                },
                "Outputs": [
                    {
                        "ContainerSettings": {"Container": "RAW"},
                        "VideoDescription": {
                            "CodecSettings": {
                                "Codec": "FRAME_CAPTURE",
                                "FrameCaptureSettings": {
                                    "FramerateNumerator": 1,
                                    "FramerateDenominator": every,
                                    "MaxCaptures": SPRITE_MAX,
                                    "Quality": 80,
                                },
                            }
                        },
                    }
                ],
            },
        ],
    }


@register_provider
class MediaConvertProvider(Provider[MediaConvertConfig]):
    key, name, category = "aws_mediaconvert", "AWS MediaConvert", "media"
    description_en = "Turns uploaded video into adaptive streams."
    description_sw = "Hubadilisha video zilizopakiwa kuwa mitiririko inayojirekebisha."
    config_model = MediaConvertConfig

    def test(self, config: MediaConvertConfig, t: Test, params: dict[str, Any]) -> None:
        def queue() -> str:
            name = config.queue_arn.rsplit("/", 1)[-1] if config.queue_arn else "Default"
            got = client(config, "mediaconvert").get_queue(Name=name)["Queue"]
            if got["Status"] != "ACTIVE":
                raise StepFailed(
                    f"The queue is {got['Status']}.", "Resume the queue in the MediaConvert console."
                )
            return str(got["Name"])

        def role() -> str:
            iam = client(config, "iam", "us-east-1")
            policy = iam.get_role(RoleName=config.job_role_arn.rsplit("/", 1)[-1])["Role"][
                "AssumeRolePolicyDocument"
            ]
            if "mediaconvert.amazonaws.com" not in json.dumps(policy):
                raise StepFailed(
                    "The role does not trust MediaConvert.", "Allow mediaconvert.amazonaws.com to assume it."
                )
            return "Trusts MediaConvert"

        def sample() -> str:
            from newsplatform.media.storage import Storage as S

            storage, token = S(client(config, "s3"), config.bucket), uuid.uuid4().hex
            source, prefix = f"probe/{token}", f"media/_probe/{token}/"
            api = client(config, "mediaconvert")
            storage.upload(SAMPLE, source, "video/mp4")
            try:
                job = api.create_job(
                    Role=config.job_role_arn,
                    Settings=job_settings(
                        f"s3://{config.bucket}/{source}", f"s3://{config.bucket}/{prefix}", probe_sample()
                    ),
                    **({"Queue": config.queue_arn} if config.queue_arn else {}),
                )["Job"]
                deadline = time.monotonic() + 200
                while time.monotonic() < deadline:
                    job = api.get_job(Id=job["Id"])["Job"]
                    if job["Status"] == "COMPLETE":
                        break
                    if job["Status"] in ("ERROR", "CANCELED"):
                        raise StepFailed(str(job.get("ErrorMessage", job["Status"]))[:300])
                    time.sleep(5)
                else:
                    raise StepFailed(
                        "The job did not finish in 200 seconds.", "Check the queue for waiting jobs."
                    )
                made = storage.keys(f"{prefix}hls/")
                if f"{prefix}hls/master.m3u8" not in made:
                    raise StepFailed("The job finished without a master playlist.")
                return f"{len(made)} files"
            finally:
                storage.delete([source, *storage.keys(prefix)])

        t.step("credentials", "Credentials", "Vitambulisho", lambda: whoami(config))
        t.step("queue", "Queue is active", "Foleni inafanya kazi", queue, needs="credentials")
        t.step("role", "Job role", "Jukumu la kazi", role, needs="credentials")
        t.step(
            "sample", "Transcode a 3-second sample", "Badilisha sampuli ya sekunde 3", sample, needs="role"
        )


SAMPLE = Path(__file__).parent / "samples/sample.mp4"


def probe_sample() -> Probe:
    return Probe(640, 360, 3000, True)


def transcoder() -> Transcoder:
    if settings.LOCAL_TRANSCODER:
        return FFmpeg()
    config = get_active("aws_mediaconvert", MediaConvertConfig)
    if config is None:
        raise ServiceUnavailable("Video processing is not configured.", code="transcoder_not_configured")
    return MediaConvert(config)


# ---- shared ----------------------------------------------------------------
def prefix_of(asset: Asset) -> str:
    return f"media/v/{asset.original_key.rsplit('/', 1)[-1]}/"


def finish(storage: Storage, asset: Asset) -> dict[str, str]:
    """Poster and scrubbing sprite from the captured frames. The same code after either transcoder."""
    prefix = prefix_of(asset)
    if f"{prefix}hls/master.m3u8" not in storage.keys(f"{prefix}hls/master.m3u8"):
        raise BadVideo("no_manifest")
    frames = sorted(storage.keys(f"{prefix}frames/"))
    if not frames:
        raise BadVideo("no_frames")
    with tempfile.TemporaryDirectory() as tmp:
        local = []
        for i, key in enumerate(frames[:SPRITE_MAX]):
            path = Path(tmp) / f"{i:04d}.jpg"
            storage.download(key, path)
            local.append(path)
        # The first frame is often black.
        poster = Path(tmp) / "poster.jpg"
        pyvips.Image.new_from_file(str(local[min(1, len(local) - 1)])).write_to_file(
            str(poster), keep="none", Q=82
        )
        tiles = [pyvips.Image.thumbnail(str(p), SPRITE_WIDTH) for p in local]
        sprite = Path(tmp) / "sprite.jpg"
        pyvips.Image.arrayjoin(tiles, across=SPRITE_COLUMNS).write_to_file(str(sprite), keep="none", Q=70)
        vtt = Path(tmp) / "sprite.vtt"
        every = max(FRAME_SECONDS, math.ceil((asset.duration_ms or 0) / 1000 / SPRITE_MAX))
        vtt.write_text(sprite_vtt(len(tiles), tiles[0].width, tiles[0].height, every, asset.duration_ms or 0))
        storage.upload(poster, f"{prefix}poster.jpg", "image/jpeg")
        storage.upload(sprite, f"{prefix}sprite.jpg", "image/jpeg")
        storage.upload(vtt, f"{prefix}sprite.vtt", "text/vtt")
    storage.delete(frames)
    return {
        "hls": f"{prefix}hls/master.m3u8",
        "poster": f"{prefix}poster.jpg",
        "sprite": f"{prefix}sprite.jpg",
        "sprite_vtt": f"{prefix}sprite.vtt",
    }


def _stamp(seconds: float) -> str:
    ms = round(seconds * 1000)
    return f"{ms // 3_600_000:02d}:{ms // 60_000 % 60:02d}:{ms // 1000 % 60:02d}.{ms % 1000:03d}"


def sprite_vtt(count: int, width: int, height: int, every: int, duration_ms: int) -> str:
    out = ["WEBVTT", ""]
    for i in range(count):
        end = duration_ms / 1000 if i == count - 1 else (i + 1) * every
        x, y = i % SPRITE_COLUMNS * width, i // SPRITE_COLUMNS * height
        out += [
            f"{_stamp(i * every)} --> {_stamp(max(end, i * every + 0.001))}",
            f"sprite.jpg#xywh={x},{y},{width},{height}",
            "",
        ]
    return "\n".join(out)
