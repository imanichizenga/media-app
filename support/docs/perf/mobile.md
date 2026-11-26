# Mobile performance

| Budget | Target | Measured |
|---|---|---|
| Download, armeabi-v7a | < 30 MB | 20.4 MB (release, 2026-11-24) |
| Download, arm64-v8a | < 30 MB | 23.1 MB |
| Download, x86_64 | < 30 MB | 24.4 MB |
| iOS app | reported | 28.4 MB unsigned, uncompressed (2026-11-24) |
| Cold start to cached news | < 1.5 s, profile, mid-range Android | **Not measured on a phone (G3).** **Emulator, not a phone** (profile build, process killed, airplane mode, `Fully drawn` reported by the app), 2026-11-26, 7 runs of the same build: median 1242 ms, range 901 to 1810 ms. CI fails above 2.5 s there; the 1.5 s budget is judged on a phone |
| Feed and Shorts | 60 fps | **Not measured on a phone (G3).** **Emulator, not a phone**, Skia (ADR-0048): frame build p90 1.8 ms (feed), 0.4 ms (Shorts), well under 16.7 ms; raster p90 about 19 ms, drawn by a software GPU, so reported only |
| Shorts | never more than three players | Met: 50 swipes in `app_test.dart` |
| Picture memory | bounded | 96 MB, 300 pictures; every picture decoded at the size it is shown |

CI fails above 30 MB. Work before the first frame: open the database, read the settings, build the theme. Everything else (device id, eviction, unfinished downloads) waits for the frame.
