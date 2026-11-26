# The public experience

Design spec for the website (M2) and the app (M3). Prototypes: `support/design/prototypes`. Galleries: [screens/m2-themes](screens/m2-themes.zip) (current), [screens/m2-design](screens/m2-design.zip) (as approved on 2026-11-24 with changes D1 to D7). Themes approved on 2026-11-24.

## Idea

A reading room with a red name over the door. White, ink and one red, used with discipline, so the page stays calm and the brand is unmistakable. The same five places, the same cards and the same action row on the phone's browser, the desk and the app.

## Rules

1. **Red is the brand, with discipline.** Only the wordmark, the masthead accent, the active place, primary buttons, article links, the liked heart, and breaking and live. Categories, metadata, headlines and body are ink. Errors are rust. **Red budget:** no screen reads as a red screen.
   **Signals are shapes, not colours:** breaking is a full-width banner with an icon and an uppercase label; live is a filled pill with a pulsing dot, and a ring in the live rail. Reserved. Dark themes have their own softer red ([ADR-0029](../adr/0029-red-is-the-brand.md)).
2. **One anatomy for every card:** picture, then *category · time*, then headline. Categories are named in ink, not coded by colour. Video pictures always show their length; live ones the pill instead.
3. **Serif speaks, sans works.** Newsreader for headlines and body headings, Inter for everything one reads past or presses.
4. **Absent, never empty.** No live coverage, no rail. Comments off, no comment icon. No gap is left behind.
5. **The whole card is one link**, one stop for a keyboard, one target for a thumb. Minimum 44 px.
6. **A skeleton is the component without data.** `LeadCard` with no card draws its bones in its own elements, so the shapes cannot drift apart.
7. **The frame knows before the page does.** Header, sections, breaking banner and tabs come with the frame; nothing pushes the page down later.
8. **Times are honest:** "dakika 5 zilizopita" under a day, then a date. The exact time is always in the markup.
9. Motion 150 to 250 ms, off under reduced motion. The live dot is the only thing that moves on its own.

10. **Counts are compact** (1.3K, 3.4M); the exact number is in the label for those who listen.

## Themes

Chosen in Admin → Appearance, with one brand colour; light and dark each ([ADR-0030](../adr/0030-brand-themes.md), [derivation](../../packages/design-tokens/spec/derivation.md)).

| | Red Signature (default) | Bold Ink | Quiet Paper |
|---|---|---|---|
| Canvas | White, ink text | White reading surfaces | Warm paper, ink text |
| Masthead | White, red name, thin red rule | Black, white name | Paper, red name |
| Bottom bar | White, red active place | Black, red active place | Paper, ink active place |
| Breaking | Ink black, red label and icon | Red, white text | Paper, red label |
| Links, liked | Red | Red | Ink |
| Dark | Near black, softened red | The same black chrome | Warm charcoal |

## Window classes

Compact below 600: the phone. Medium 600 to 839: two-column feed, article capped at 680. Expanded from 840: a navigation rail replaces the bottom bar, the feed has more columns, related stories stand beside the article ([ADR-0035](../adr/0035-window-classes.md)).

## Places

| Place | Phone | Desk |
|---|---|---|
| Frame | Wordmark, search, language, theme; scrolling sections; five tabs below | Date, centred wordmark; centred sections; footer |
| Home | Breaking, live rail, lead, rows, latest, video strip, sections | Lead, two cards and the river of latest in three columns; then video band; sections alternate between one large with three rows and four across |
| Article | One column. The tab bar gives way to the action bar | 44 rem column, actions at its left edge, related at its right |
| Shorts | Full screen, always dark, actions at the right thumb | The same, centred in a 9:16 frame |
| Video | Lead, then a list | Lead with three beside it, then four across |
| Live | Player, then updates or chat | Player and updates; chat beside them, following the scroll |
| Category | Name, description, subsections, lead, rows | Lead with two cards, then two columns of rows |
| Search | Trending, categories, journalists; results with three filters | The same, in a reading column |
| Onboarding | The app only, once: welcome, language, topics, alerts. **Skip** is always there | None |
| Sign in | Sheet over the article. Says what will happen, keeps the story in view, returns to the exact place and finishes the action | The same, centred |
| Comments | Sheet, 86% tall, composer always in reach | Drawer at the right, the article still visible |
| Empty, error, offline | A drawing, one sentence, one action | The same |

## What arrives when

The prototypes show the finished product. M2 builds **only** what works for a guest, and leaves no gap and no dead button for the rest:

| Seen in the prototypes | Built in |
|---|---|
| Home, Article, Category, Video, Live blog, author, static pages, all states | M2 (web), M3 (app) |
| Shorts feed, saved and offline | M2 simple, M3 full |
| Like, comment, save to account, follow, sign in, comments sheet | M4 |
| Alerts and their onboarding step | M6 |
| Live player, viewers, chat | M7 |
| For you, search results, trending searches, journalists to follow | M8 |

Search in M2 is a page with categories and no field, until there is something to search with.

## Accessibility

WCAG 2.2 AA in both themes: axe finds nothing on the 320 prototype screens in the themes gallery (text over photographs is judged by eye, with a gradient behind it), and no page scrolls sideways at 390 px. Contrast is tested on every token pair. Text follows the reader's own size. Each place has one `h1`; landmarks are named; the first stop is a link to the content.

## Performance, by design

Two font files, both subsetted. One picture is loaded eagerly: the lead. Frames fix every picture's shape and carry its colour until it arrives. Cards are plain markup with no script; the only scripts are the theme, the language, the share sheet and, when asked, a player.

## Decided

2026-11-24, verbatim in [PROGRESS.md](../PROGRESS.md): the five tabs; comments as a sheet on the app and a drawer on a desk; Shorts always dark; changes D1 to D7, all applied.

## Regenerate

```sh
cd backend && API_SURFACE=public … uvicorn config.asgi:application --port 8010   # on a database filled by seed_demo
node support/design/prototypes/capture.mjs          # content and pictures
pnpm --filter @news/prototypes build        # dist/<locale>/<theme>/<scheme>/<page>.html
node support/design/prototypes/shoot.mjs            # the gallery, with axe and a sideways-scroll check
node support/tests/e2e/contact-sheet.mjs m2-themes
```
