# The mobile app

Everything a guest can do (M3). Sign-in, likes, comments: M4. Alerts: M6. Live player: M7. For You and search: M8.

## Run it

```sh
support/scripts/mobile-toolchain.sh && . /tmp/toolchain/env    # Flutter, JDK, Android SDK; about a minute
cd mobile && flutter pub get
flutter test                                                    # unit, widget, goldens
flutter test --update-goldens --tags golden                     # after a change made on purpose
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

The toolchain and every build live in `/tmp`, which a stopped Codespace empties. Source, goldens and lockfiles do not.

## Look at it

```sh
flutter test --run-skipped --tags look test/screens/gallery_test.dart
backend/.venv/bin/python support/scripts/mobile-gallery.py mobile/build/gallery out
```

## Brand

Name, logos, colours: admin. The app's icon, the name under it, bundle ids, splash and link hosts: `mobile/brand.yaml`, then `support/scripts/mobile-brand.sh` and a release. Today's ids and hosts are placeholders (human actions C2, D1).

## Release signing

Android: `mobile/android/key.properties` (ignored by git) with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. Without it a release is signed with the debug key, for testing only.
