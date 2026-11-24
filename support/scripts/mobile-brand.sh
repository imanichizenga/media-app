#!/usr/bin/env bash
# brand.yaml → launcher icons, splash and the iOS settings. Android reads brand.yaml itself.
set -euo pipefail
here="$(cd "$(dirname "$0")/../.." && pwd)"
"$here/backend/.venv/bin/python" "$here/support/scripts/mobile-brand.py" "$here/mobile"
cd "$here/mobile"
dart run flutter_launcher_icons > /dev/null
dart run flutter_native_splash:create > /dev/null
