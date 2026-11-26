# Draws the launcher icon and the splash, and writes the iOS half of brand.yaml. Called by mobile-brand.sh.
import re
import sys
from pathlib import Path

import pyvips

mobile = Path(sys.argv[1])
brand = {
    m[1]: m[2].strip().strip('"') for m in re.finditer(r"^(\w+): *(.+)$", (mobile / "brand.yaml").read_text(), re.M)
}
red = [int(brand["color"][i : i + 2], 16) for i in (1, 3, 5)]
fonts = mobile / "assets/fonts/Newsreader.ttf"


def letter(size: int) -> pyvips.Image:
    text = pyvips.Image.text(brand["letter"], font="Newsreader Bold", fontfile=str(fonts), width=size, height=size, rgba=True)
    return text.resize(size / max(text.width, text.height))


def on(canvas: int, mark: int, ground: list[int]) -> pyvips.Image:
    glyph = letter(mark)
    alpha = glyph[3]
    white = alpha.new_from_image([255, 255, 255]).bandjoin(alpha).copy(interpretation="srgb")
    base = pyvips.Image.black(canvas, canvas, bands=4).copy(interpretation="srgb") + ground
    return base.composite2(white, "over", x=(canvas - glyph.width) // 2, y=(canvas - glyph.height) // 2).cast("uchar")


out = mobile / "brand"
out.mkdir(exist_ok=True)
on(1024, 560, [*red, 255]).flatten().pngsave(str(out / "icon.png"), keep="none")
# Adaptive icons and the splash are masked to a circle: the mark keeps to the middle third.
on(1024, 380, [0, 0, 0, 0]).pngsave(str(out / "foreground.png"), keep="none")
on(1152, 360, [0, 0, 0, 0]).pngsave(str(out / "splash.png"), keep="none")
(mobile / "flutter_launcher_icons.yaml").write_text(
    f"""# Written by support/scripts/mobile-brand.sh from brand.yaml. Do not edit.
flutter_launcher_icons:
  android: ic_launcher
  ios: true
  remove_alpha_ios: true
  image_path: brand/icon.png
  adaptive_icon_background: "{brand['color']}"
  adaptive_icon_foreground: brand/foreground.png
  adaptive_icon_monochrome: brand/foreground.png
"""
)
(mobile / "flutter_native_splash.yaml").write_text(
    f"""# Written by support/scripts/mobile-brand.sh from brand.yaml. Do not edit.
flutter_native_splash:
  color: "{brand['color']}"
  image: brand/splash.png
  android_12:
    color: "{brand['color']}"
    image: brand/splash.png
  web: false
"""
)
(mobile / "ios/Flutter/Brand.xcconfig").write_text(
    f"""// Written by support/scripts/mobile-brand.sh from brand.yaml. Do not edit.
BRAND_NAME = {brand['name']}
BRAND_ID = {brand['ios_id']}
HOST_DEV = {brand['host_dev']}
HOST_STAGING = {brand['host_staging']}
HOST_PROD = {brand['host_prod']}
"""
)
