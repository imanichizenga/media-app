# 0044. Space and native conventions

Status: accepted, 2026-11-25. Supersedes in part 0043 and 0032's frame on the app.

## Context
G2 on the app: approved with changes. Space is for news: chrome must never crowd out content. Native first: each platform feels like itself, while brand, type and card anatomy stay identical.

## Decision

**Space.** On 360×640 the lead's whole headline and meta line stand above the bottom bar; on 390×844 the next story has begun (S1, a test in both languages). Home: a bar with the wordmark, one row of tabs, a one-line breaking banner, a rail of at most 96. The wordmark is on Home only; the other places use the platform's title bar (S2). An article's picture is at most 16:9 and 40% of the screen, and its actions are a bar the page makes room for, so they cover nothing (S3). Meta is one line: the category gives way, the time never does (S4). Wide windows use their width (S5).

**Native.** `lib/ui/adaptive` is the only place that asks which platform it is: page transitions, pull to refresh, title bars, the bottom bar, choices, confirmations, the story menu, settings rows, switches. A test enforces it. iOS: edge swipe, bouncing, large titles, translucent bars, action sheets. Android: predictive back, stretch, M3 navigation bar, bottom sheets. Fonts and colours are the brand's on both (N1, N2, V4).

**Home tabs** are pages one swipes between; each keeps its place (N3). They share one header that gives way, rather than a nested scroll view: pull to refresh then works natively on both platforms, and each page is an ordinary list.

**Lists stay under their tab.** A category, tag or journalist opened from a place is pushed inside that place, the bottom bar still there; a story covers it. Tapping the active tab goes to the top, then to the root (N2).

**A refreshed Home waits for its reader.** At the top it is applied, and a banner that is new grows in. Further down nothing moves: a pill says there is news and goes up when tapped (V2). What a skeleton cannot know, breaking news and live coverage, arrives in the same frame as the stories, never after.

**Red:** the wordmark, its rule, the active place, primary buttons, links, the saved mark, breaking and live. Sharing is not red (V3). A play mark only on the lead video and in the player (V1).

## Alternatives
NestedScrollView (positions and the iOS refresh control fight it); per-screen platform checks; a floating pill that hides (it still covers when it shows).

## Consequences
Every golden of the app changes. The gallery shows before and after.

## Amended 2026-11-26 (M3.2, after G2 on the M3.1 gallery)

- **R1. No play button on any card.** A card in a list says it is a video by its length in a corner; the play mark in the middle of a picture belongs to the player alone (this supersedes "a play mark only on the lead video": the Video tab's first card is a card too). Test: `residuals_test.dart`, "no card in any list shows a play button".
- **R2. What the one line of meta keeps.** The category, whole, never cut inside a word; then the time; then the reading time. It gives way in that order backwards: the reading time goes first, then the category takes the short name an editor gave it (`short_name` on the category's text in each language, at most 14 characters, edited in Admin → Taxonomy; empty means the name), then the time goes. Only a short name too long for the line on its own is drawn smaller, never cut. Test: `space_test.dart`, "meta is one line … and no category is cut", at 320, 360 and 390 wide and text ×1, ×1.5 and ×2.
- **R3. Live rail labels.** Two lines at caption size under each ring: the editor's rail title (`rail_title` on a live post's text in each language, at most 24 characters), or the headline cut between words by the server (`publishing.rail_title`). A word is never split: a word too wide for the ring makes the label a little smaller, down to 8.5. The rail stays within 96. Tests: `test_public_api.py` (the cut), `residuals_test.dart` (the longest Swahili titles at text ×1, ×1.3 and ×2).
- **R4. No picture beside itself.** `seed_demo` gives each post a picture that its neighbour does not have in any list it will be in (home's rows and carousels, the rail, its section, its type, in each language; its tags, story and writer when the pictures allow) and needs at least 10 pictures. Explore's tiles take their newest picture that no earlier tile shows. Tests: `test_seed_demo.py`, `residuals_test.dart`.
- **R5. Android's bar of places follows Material 3's roles.** The active place: its icon in the brand, on a pill of the brand's soft container (on Bold Ink's black bar in a light theme, the brand over the black), its label in ink. iOS is unchanged. Tests: contrast in every theme and scheme, and the bar itself (`residuals_test.dart`).
- **The red budget is measured**: at most 7.5% of any screen in the brand's red, on Home, a section, Explore and an article, in every theme, both schemes, both platforms. The largest approved use is Bold Ink's breaking banner on Home, about 5.6%.
