"""M1 acceptance: a 1 GB upload survives a network cut and plays as adaptive HLS. Needs ffmpeg and the storage profile.

docker compose --profile storage up -d --wait
cd apps/api && API_SURFACE=admin STORAGE_ENDPOINT_URL=http://127.0.0.1:8333 LOCAL_TRANSCODER=1 LOCAL_SCANNER=eicar \
  uv run python -m tests.live_upload
"""

import contextlib
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.test")
django.setup()

import httpx  # noqa: E402
from django.test.utils import setup_databases, teardown_databases  # noqa: E402

GB = 1024**3


def say(ok: bool, text: str) -> None:
    sys.stdout.write(f"{'PASS' if ok else 'FAIL'} {text}\n")
    sys.stdout.flush()
    if not ok:
        raise SystemExit(1)


def make_video(path: Path, size: int) -> None:
    """Noise does not compress, so a fixed bit rate reaches the size without hours of video."""
    subprocess.run(  # noqa: S603
        ["ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i", "testsrc2=size=1280x720:rate=25:duration=24",  # noqa: S607
         "-f", "lavfi", "-i", "sine=frequency=440:duration=24", "-vf", "noise=alls=100:allf=t",
         "-c:v", "libx264", "-preset", "ultrafast", "-b:v", "380M", "-minrate", "380M", "-maxrate", "380M",
         "-bufsize", "380M", "-x264-params", "nal-hrd=cbr", "-pix_fmt", "yuv420p", "-c:a", "aac", str(path)],
        check=True,
    )  # fmt: skip
    say(path.stat().st_size >= size, f"source video is {path.stat().st_size / GB:.2f} GB")


def main() -> None:
    from newsplatform.accounts.models import User
    from newsplatform.common.redis import cache
    from newsplatform.media import services, tasks, transcoding
    from newsplatform.media import storage as storage_module
    from newsplatform.media.models import AssetStatus
    from newsplatform.rbac.models import Role
    from newsplatform.rbac.services import assign_role, sync_system_roles

    old = setup_databases(verbosity=0, interactive=False)
    cache().flushdb()
    tasks.process.delay = lambda _: None
    s3 = storage_module._local()
    with contextlib.suppress(s3.exceptions.ClientError):
        s3.create_bucket(Bucket="news-media")
    store = storage_module.storage()
    try:
        sync_system_roles()
        user = User.objects.create_user(email="a@example.test", password="x" * 20, display_name="A")
        assign_role(actor=None, user=user, role=Role.objects.get(key="journalist"))
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "source.mp4"
            make_video(source, GB)
            size = source.stat().st_size
            asset = services.begin_upload(actor=user, kind="video", filename="v.mp4", size=size)
            total = services.part_count(asset)
            start, sent = time.monotonic(), 0
            with source.open("rb") as f, httpx.Client(timeout=120) as http:

                def send(number: int) -> None:
                    nonlocal sent
                    url = services.sign_parts(actor=user, asset_id=asset.pk, numbers=[number])[number]
                    f.seek((number - 1) * asset.part_size)
                    http.put(url, content=f.read(asset.part_size)).raise_for_status()
                    sent += 1

                cut = total // 2
                for n in range(1, cut + 1):
                    send(n)
                # The network goes away in the middle of a part.
                url = services.sign_parts(actor=user, asset_id=asset.pk, numbers=[cut + 1])[cut + 1]

                def broken():
                    f.seek(cut * asset.part_size)
                    yield f.read(asset.part_size // 3)
                    raise ConnectionResetError

                with contextlib.suppress(Exception):
                    http.put(url, content=broken(), headers={"content-length": str(asset.part_size)})
            with source.open("rb") as f, httpx.Client(timeout=120) as http:  # a new client, knowing nothing
                have = services.uploaded_parts(actor=user, asset_id=asset.pk)
                say(have == list(range(1, cut + 1)), f"after the cut, {len(have)} of {total} parts are kept")
                for n in sorted(set(range(1, total + 1)) - set(have)):
                    send(n)
            say(sent == total, f"each part was sent once ({sent})")
            services.complete_upload(actor=user, asset_id=asset.pk)
            say(store.size(asset.original_key) == size, f"uploaded in {time.monotonic() - start:.0f}s")
        start = time.monotonic()
        tasks.process.apply(args=[str(asset.pk)])
        asset.refresh_from_db()
        say(asset.status == AssetStatus.READY, f"ready in {time.monotonic() - start:.0f}s {asset.error_code}")
        master = store.read(asset.outputs["hls"]).decode()
        names = [r.name for r, _, _ in transcoding.ladder(1280, 720)]
        say(all(f"master_{n}.m3u8" in master for n in names), f"adaptive: {', '.join(names)}")
        # A player's view: the whole stream decodes from the playlist, in every rendition.
        with tempfile.TemporaryDirectory() as tmp:
            prefix = transcoding.prefix_of(asset)
            for key in store.keys(f"{prefix}hls/"):
                store.download(key, Path(tmp) / key.rsplit("/", 1)[-1])
            for name in names:
                out = subprocess.run(  # noqa: S603
                    ["ffprobe", "-v", "error", "-count_packets", "-select_streams", "v:0", "-show_entries",  # noqa: S607
                     "stream=nb_read_packets", "-of", "csv=p=0", f"{tmp}/master_{name}.m3u8"],
                    capture_output=True, text=True, check=True,
                )  # fmt: skip
                frames = int(out.stdout.split()[0].strip(","))
                say(590 <= frames <= 610, f"{name} plays to the end ({frames} frames)")
        store.delete([asset.original_key, *store.keys(prefix)])
    finally:
        teardown_databases(old, verbosity=0)


if __name__ == "__main__":
    main()
