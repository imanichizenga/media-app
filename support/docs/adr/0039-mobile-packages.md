# 0039. Mobile packages

Status: accepted, 2026-11-24

## Context
As few as possible, none unmaintained, exact versions.

## Decision
Used: material_ui and cupertino_ui (they moved out of the SDK in Flutter 3.47), flutter_riverpod with its generator, go_router with its builder, dio (the generated client is built on it), drift with drift_flutter, flutter_secure_storage, flutter_cache_manager with path_provider (bounded picture stores, one permanent for saved articles), video_player, webview_flutter (YouTube only), share_plus, url_launcher, package_info_plus, connectivity_plus, sentry_flutter, crypto (pins). Development: build_runner, drift_dev, mocktail, flutter_lints, flutter_launcher_icons, flutter_native_splash.

Not used: cached_network_image (pulls octo_image and the deprecated Material; a 40-line `ImageProvider` over the same cache manager does it and reads saved pictures first), a blurhash package (last released in 2023 and 2025; 60 lines, tested), visibility_detector (2023; route and ticker state say the same), an icon font (icons are path data generated from the same Lucide the web uses, with a filled form), alchemist (plain `matchesGoldenFile` with the bundled fonts draws real text), shimmer, photo_view.

## Alternatives
The full list in the task.

## Consequences
Some code of our own, all of it small and tested.
