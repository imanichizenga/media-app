# Mobile performance

| Budget | Target | Measured |
|---|---|---|
| Download, armeabi-v7a | < 30 MB | 20.4 MB (release, 2026-11-24) |
| Download, arm64-v8a | < 30 MB | 23.1 MB |
| Download, x86_64 | < 30 MB | 24.4 MB |
| iOS app | reported | 28.4 MB unsigned, uncompressed (2026-11-24) |
| Cold start to cached news | < 1.5 s, profile, mid-range Android | **Not measured on a phone (G3).** On CI, debug builds, from an already running process to cached news on screen: 400 ms (Android emulator), 354 ms (iOS simulator). That is not a cold start of the process; it says only that nothing got worse |
| Feed and Shorts | 60 fps | **Not measured on a phone (G3)** |
| Shorts | never more than three players | Met: 50 swipes in `app_test.dart` |
| Picture memory | bounded | 96 MB, 300 pictures; every picture decoded at the size it is shown |

CI fails above 30 MB. Work before the first frame: open the database, read the settings, build the theme. Everything else (device id, eviction, unfinished downloads) waits for the frame.
