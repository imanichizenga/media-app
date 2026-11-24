# From one colour to a theme

One input: a brand colour `#rrggbb`, and optionally a second one for dark surfaces. Output: every token of every theme, light and dark, as `#rrggbb`. Three ports: `src/theme.ts`, `apps/api/newsplatform/site_config/theme/derive.py`, `dart/lib/theme_derivation.dart`. `vectors.json` is the referee: CI runs it in all three, and one differing digit fails.

`src/themes.json` holds the data: three themes, each with neutrals and brand rules per scheme, and the list of pairs that must pass.

## Colour

Numbers are IEEE doubles. No trigonometry: hue is kept as a unit vector `(x, y)`, so platforms cannot disagree about an angle.

- **sRGB → linear:** `v/12.92` up to 0.04045, else `((v+0.055)/1.055)^2.4`. Back: `12.92v` up to 0.0031308, else `1.055v^(1/2.4)-0.055`.
- **Linear → OKLCH:** Ottosson's matrices, cube root as `^(1/3)`. `c = sqrt(a²+b²)`, `x = a/c`, `y = b/c`. Below `c = 0.0005` the colour is grey: `c = x = y = 0`.
- **paint(l, c, x, y):** OKLCH → linear sRGB. Inside the gamut means every channel in [-0.0001, 1.0001]. Outside, bisect chroma between 0 and `c`, 20 times, and take the lower bound. Then clamp to [0, 1], encode, and round each channel with `floor(255v + 0.5)`.
- **Contrast:** WCAG 2 relative luminance, on the rounded colours.

## Rules

Applied in the order written in `themes.json`; a rule may name an earlier token. `o` is the base colour in OKLCH: the brand colour, or in the dark scheme the dark colour when there is one.

| Rule                   | Result                                                                                                                                                                                                    |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `"#rrggbb"`            | That colour                                                                                                                                                                                               |
| `"@token"`             | That token                                                                                                                                                                                                |
| `["exact"]`            | The base colour                                                                                                                                                                                           |
| `["fill", grounds…]`   | For fills on dark surfaces: from `l = 0.3` in steps of 0.0025, chroma `0.92·o.c`, the first colour at 3:1 on every ground. Dark grounds are chosen so that white on it still reaches 4.5:1                |
| `["soften", grounds…]` | For text and icons on dark surfaces: from `l = 0.64` in steps of 0.005, chroma `min(0.9·o.c, 0.17)`, the first colour at 4.5:1 on every ground. With a dark colour chosen by hand: that colour, unchanged |
| `["strong", token]`    | The token's OKLCH with `l - 0.055`                                                                                                                                                                        |
| `["tint", l, c]`       | `paint(l, min(o.c, c))` in the base hue                                                                                                                                                                   |

A walk computes `l = start + step·i` (never by adding) and stops at `l ≥ 1`.

## Validity

A colour is valid when every pair passes in **all** themes and both schemes, so switching theme can never fail. `nearest` walks the lightness of the same hue and chroma in steps of 0.005, darker before lighter, and returns the first valid colour. For a dark colour only the dark schemes are judged.
