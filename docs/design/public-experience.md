# The public experience

Design spec for the website (M2) and the app (M3). Prototypes: `design/prototypes`. Gallery: [screens/m2-design](screens/m2-design/index.html). **Waits for approval (G2)** before either is built.

## Idea

A reading room with one loud bell. Everything is quiet, warm neutral and serif, so the single red thing on the page (breaking, live) is never missed. The same five places, the same cards and the same action row on the phone's browser, the desk and the app.

## Rules

1. **Red means breaking or live.** Nothing else is red: errors are rust, likes are the accent.
2. **One anatomy for every card:** picture, then *category · time*, then headline. Categories are named in the accent, not coded by colour.
3. **Serif speaks, sans works.** Newsreader for headlines and body headings, Inter for everything one reads past or presses.
4. **Absent, never empty.** No live coverage, no rail. Comments off, no comment icon. No gap is left behind.
5. **The whole card is one link**, one stop for a keyboard, one target for a thumb. Minimum 44 px.
6. **A skeleton is the component without data.** `LeadCard` with no card draws its bones in its own elements, so the shapes cannot drift apart.
7. **The frame knows before the page does.** Header, sections, breaking banner and tabs come with the frame; nothing pushes the page down later.
8. **Times are honest:** "dakika 5 zilizopita" under a day, then a date. The exact time is always in the markup.
9. Motion 150 to 250 ms, off under reduced motion. The live dot is the only thing that moves on its own.

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

WCAG 2.2 AA in both themes: axe finds nothing on the 96 prototype screens in the gallery (text over photographs is judged by eye, with a gradient behind it), and no page scrolls sideways at 390 px. Contrast is tested on every token pair. Text follows the reader's own size. Each place has one `h1`; landmarks are named; the first stop is a link to the content.

## Performance, by design

Two font files, both subsetted. One picture is loaded eagerly: the lead. Frames fix every picture's shape and carry its colour until it arrives. Cards are plain markup with no script; the only scripts are the theme, the language, the share sheet and, when asked, a player.

## Questions for the approver

1. Brand name, logo and accent (G6). "Mfano News" and the blue are placeholders: both change in one place.
2. The five tabs: **Nyumbani, Video, Gundua, Hifadhi, Wewe**. Right words?
3. Comments before or after related stories in the app's article? Here they are a sheet, so neither.
4. Shorts are always dark, even in the light theme. Agreed?

## Regenerate

```sh
cd apps/api && API_SURFACE=public … uvicorn config.asgi:application --port 8010   # on a database filled by seed_demo
node design/prototypes/capture.mjs          # content and pictures
pnpm --filter @news/prototypes build        # dist/<locale>/<theme>/<page>.html
node design/prototypes/shoot.mjs            # the gallery, with axe and a sideways-scroll check
node tests/e2e/contact-sheet.mjs m2-design
```
