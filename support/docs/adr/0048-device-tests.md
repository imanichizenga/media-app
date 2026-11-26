# 0048. The app's device tests: evidence first, then a stable emulator

Status: accepted, 2026-11-26.

## Context

`main` went red after pull request 11: in `mobile-android` the emulator went `offline` in the middle of a test
("DriverError … Service connection disposed", "Failed to find ColorBuffer", "adb … could not connect to 5554"), twice
in one job. Earlier `m3-mobile` runs failed the same way. The job replaced a lost emulator once and called it a known
risk. That hid a fault without knowing what it was.

## What the evidence says

The job now keeps, on every run: the emulator's own output and exit status, every logcat buffer from boot
(`logcat -b all`), the runner's memory every 5 s with its largest processes, the kernel's log, tombstones and ANR
traces from the device, and, if the emulator dumps core, a backtrace of every thread (gdb). `android-verdict.sh`
classifies each run: (a) the app, (b) the emulator, (c) the runner's memory.

Soak runs, all on the same commit of the app ([diag-old](https://github.com/imanichizenga/media-app/actions/runs/45790651199), [diag-2](https://github.com/imanichizenga/media-app/actions/runs/45794574669), [diag-3](https://github.com/imanichizenga/media-app/actions/runs/45796575845)):

- **Not the app (a).** No fatal exception, native crash, ANR or low-memory kill of the app in any run. The only
  `am_kill` lines were the force-stops the perf script asks for.
- **Not memory (c).** No OOM kill in any kernel log; the least memory available on the runner during any run was
  over 7 GB of 16.
- **The emulator crashes (b).** The emulator process ends with SIGSEGV (status 139, "Segmentation fault (core
  dumped)"). The core is written by the thread **RenderThread** of `qemu-system-x86_64-headless`: the host side of the
  emulated GPU (gfxstream). The faulting address is outside every loaded library and the stack holds pixel-like
  values: SwiftShader's JIT-compiled rasteriser (its `memfd:SwiftShader.Memory` mappings are in the core) writing out
  of bounds. It follows gfxstream's own "Failed to find ColorBuffer / Failed to bind to texture: invalid color buffer",
  the message seen on `main`.
- **Only under Impeller.** Runs that reached the emulator, per configuration, and how many crashed so:

  | Configuration | Renderer | Emulator crashes |
  |---|---|---|
  | SwiftShader on the host, GLES (main's) | Impeller | 1 of 6 (diag-old), 3 of 6 (diag-2), 3 of 5 (diag-3) |
  | SwiftShader on the host, Vulkan | Impeller | 4 of 5 (diag-2) |
  | ATD image (`google_atd`), GLES | Impeller | 3 of 8 |
  | `-gpu guest` | Impeller | 6 of 8 (it still renders on the host) |
  | **SwiftShader on the host, GLES** | **Skia** | **0 of 7** |

So the fault is the emulator's software GPU (SwiftShader, through gfxstream, on the host) under Impeller's command
stream: a fault of the software GPU only, which no image or mode avoided. Real phones draw with a GPU, where Impeller
is the default and the measure that matters is G3's.

## Decision

- **On the emulator, the integration tests and the frames run with Skia** (`--no-enable-impeller`, the device
  workflow's `engine-flags`). This is scoped to the emulator job only; the app itself, every build, every phone and
  every simulator keep Impeller.
- **Impeller is still run in CI twice**: the Android cold starts launch the app as installed (Impeller), and the iOS
  simulator runs the whole integration suite with Impeller on Metal (the only renderer there).
- The emulator, written down in `support/scripts/android-emulator.sh`: API 34 `google_apis` x86_64, `-gpu
  swiftshader_indirect`, `-feature -Vulkan`, `-no-snapshot -no-boot-anim -no-audio`, no cameras, 3 cores, 3 GB of RAM,
  a 512 MB heap, 320×640 at 160 dpi (what the tests were written on). Animations stay on: the tests measure frames.
- The services beside it stay as they are (memory was never short), and the suite is not sharded (the crash was not
  a matter of length: it came in the first two tests).
- On the emulator the cold start is reported against the phone's budget (1.5 s) and guarded at 2.5 s: the same build
  measured 901 to 1810 ms from run to run there. Frame build time stays a budget; raster time is reported (software).
- When the emulator or Flutter changes (a new system image, emulator or Flutter release), run Soak with
  `engine-flags` empty to see whether Impeller is safe there again; if ten runs in a row pass, remove the flag.

## Alternatives

- Retrying a lost emulator: hides the fault (and the rule now forbids it).
- A larger runner: the runner had 7 GB free when the emulator crashed; memory was not the cause.
- Fewer services beside the emulator: same.
- Disabling Impeller everywhere: the fault is the emulator's, so only the emulator job is changed.
- Another image (ATD) or `-gpu guest`: both crashed as often (table above).
- Vulkan through SwiftShader: crashed as often.

## Consequences

- No step of the device jobs retries a test. Only a download that the network or a registry's rate limit (429)
  failed is run once more, and the job summary says so with the lines that proved it (`ci-retry-network.sh`).
- Every run's verdict and the runner's memory are in its job summary; on failure the evidence is an artifact.
- `Soak` (Actions → Soak → Run workflow) runs both device jobs N times side by side; the proof of stability is ten
  in a row of each with no failure.
- The emulator is configured in one place, `support/scripts/android-emulator.sh`, not by a third-party action.
- `required` fails if a job of CI is not in its list (`ci-required.py`), so a device job cannot fail unnoticed.
