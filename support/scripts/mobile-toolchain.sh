#!/usr/bin/env bash
# Flutter, JDK 21 and the Android SDK, in one folder. Safe to run again: it installs only what is missing.
#   support/scripts/mobile-toolchain.sh [folder]     default $TOOLCHAIN or /tmp/toolchain
#   . <folder>/env                                   puts it on the path
# The Flutter version comes from mobile/.fvmrc, the same file CI reads. Accepts the Android SDK licences.
set -euo pipefail
here="$(cd "$(dirname "$0")/../.." && pwd)"
dir="${1:-${TOOLCHAIN:-/tmp/toolchain}}"
flutter="$(sed -n 's/.*"flutter": *"\([^"]*\)".*/\1/p' "$here/mobile/.fvmrc")"
jdk="21.0.13.1+2"
tools="16111833"
tools_sha1="e025545c62a8e64c7559119566a569fb1dec5f60"
packages=("platform-tools" "platforms;android-36" "build-tools;36.0.0" "ndk;28.2.13676358")
mkdir -p "$dir"
if [ "$(cat "$dir/flutter/version" 2>/dev/null || true)" != "$flutter" ] && [ ! -x "$dir/flutter/bin/flutter" ]; then
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$flutter-stable.tar.xz" | tar xJ -C "$dir"
fi
if [ ! -x "$dir/jdk/bin/java" ]; then
  mkdir -p "$dir/jdk"
  curl -fsSL "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-${jdk/+/%2B}/OpenJDK21U-jdk_x64_linux_hotspot_${jdk/+/_}.tar.gz" | tar xz -C "$dir/jdk" --strip-components=1
fi
if [ ! -x "$dir/android/cmdline-tools/latest/bin/sdkmanager" ]; then
  zip="$(mktemp)"
  curl -fsSL -o "$zip" "https://dl.google.com/android/repository/commandlinetools-linux-${tools}_latest.zip"
  echo "$tools_sha1  $zip" | sha1sum -c --quiet
  mkdir -p "$dir/android/cmdline-tools"
  unzip -q "$zip" -d "$dir/android/cmdline-tools" && mv "$dir/android/cmdline-tools/cmdline-tools" "$dir/android/cmdline-tools/latest"
  rm "$zip"
fi
cat > "$dir/env" <<ENV
export JAVA_HOME="$dir/jdk" ANDROID_HOME="$dir/android" PUB_CACHE="$dir/pub-cache" GRADLE_USER_HOME="$dir/gradle"
export PATH="$dir/flutter/bin:$dir/jdk/bin:$dir/android/platform-tools:$dir/android/cmdline-tools/latest/bin:\$PATH"
ENV
# shellcheck disable=SC1091
. "$dir/env"
yes | sdkmanager --licenses > /dev/null 2>&1 || true
sdkmanager --install "${packages[@]}" > /dev/null
flutter config --no-analytics --android-sdk "$ANDROID_HOME" --jdk-dir "$JAVA_HOME" > /dev/null
# Builds are large and can be made again: they go beside the toolchain, not into the workspace.
if [ ! -e "$here/mobile/build" ]; then
  mkdir -p "$dir/mobile-build" && ln -s "$dir/mobile-build" "$here/mobile/build"
fi
flutter --version | head -1
