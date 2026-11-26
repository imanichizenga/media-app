# Web and app: the same product

The website at phone width and the app follow the same rules ([ADR-0044](../adr/0044-space-and-native.md), amended by
M3.2). What differs is listed with its reason; only a platform's own conventions may differ. The galleries put the
screens side by side on the same content: [m2](screens/m2.zip) (app beside phone web) and [m3-2](screens/m3-2.zip).

## The same

| | How it is held the same |
|---|---|
| Colour, type, space, radius, motion | Tokens from one package; one derivation in Python, TypeScript and Dart, shared vectors |
| Themes | Three, chosen in the admin, light and dark; Shorts are always dark |
| Icons | Lucide drawings on both |
| Card anatomy | Picture, then *category · time*, then headline; the whole card is one link |
| The line of meta (R2) | One line, nothing cut: the reading time goes first, then the category's short name, then the time. Web: the parts wrap whole onto a hidden line, and the island wears the short name. App: measured, then chosen. Tests: `space_test.dart`, `site.spec.ts` |
| Videos in lists (R1) | The length in a corner, never a play button; the play mark belongs to the player |
| Live rail (R3) | Rings, at most 96 high, two lines under each: the editor's rail title or the headline cut between words by the server (`rail_title`, one source for both) |
| Signals | Breaking: one line, full width, icon and label. Live: the pill and the ring |
| Space (S1) | At 360×640 the lead's whole headline and meta stand above the bottom bar, in both languages. Tests: `space_test.dart`, `site.spec.ts` |
| A row of sections that goes on | The side with more fades so the next section peeks in; a chevron there (44 wide, named for screen readers) goes most of a row on; nothing on a side with nothing more. Tests: `residuals_test.dart`, `site.spec.ts` |
| Home's frame (S2) | The wordmark on Home only; one row of tabs, underlined; the other places use a plain title |
| Article (S3) | The picture at most 16:9 and 40% of the screen; headline, standfirst and byline in the first screen; neutral actions in a bar that covers nothing and steps aside while reading down |
| Red | The wordmark and its rule, the active place, primary buttons, links, the saved mark, breaking and live; at most 7.5% of any screen (`residuals_test.dart`) |
| Words | `support/packages/i18n`, one source for both |
| Counts and times | 1.3K; "dakika 5 zilizopita" under a day, then a date |
| Empty, error, offline | The same drawings, one sentence, one action |
| Skeletons | The component without data, in its place (web: within 8 px and CLS < 0.05; app: goldens) |
| Addresses | The same paths; a link opens the app when it is installed (app and universal link files served by the website) |
| Wide screens (S5) | The width is used: the lead with the latest beside it, sections three or four across; no lone phone column |

## Different on purpose

| | Web | App | Why |
|---|---|---|---|
| Bottom bar, active place | The icon and label in the brand | Android: the icon in the brand on a soft pill, the label in ink (Material 3, R5). iOS: the icon and label in the brand (the tab bar's own convention) | Each platform's own convention (N1) |
| Title bars, page transitions, refresh, menus, sheets, switches | The browser's: links, the back button, no pull to refresh | iOS: large titles, edge swipe, bouncing, action sheets. Android: predictive back, stretch, bottom sheets | Native first (ADR-0044) |
| Story menu on a long press | None (a long press belongs to the browser) | iOS: a context menu with the story's preview (N5); Android: a bottom sheet | Native first |
| Home tabs | Each tab is its own address | Pages one swipes between, each keeping its place | The web's unit is the address; the app's is the gesture |
| Wide screens, the frame | A header with centred sections; a footer | A navigation rail | Desk conventions on each |
| Live rail at desk width | Larger rings (72) and labels | Phones and tablets: 54 | A desk has the room |
| "Open in app" | A dismissible banner on phones, never an interstitial; iOS: Safari's own banner | n/a | Only the web can offer it |
| Onboarding | None | Once: welcome, language, topics | The app is installed on purpose; the web is arrived at |
| Text size and scheme | Chosen on the page, kept on the device | Settings, kept on the device; follows the system | |
| Saved | A list on this device (headline and address); reading needs the network, and offline the page says so and offers the list | Saved with text and pictures, readable offline | No service worker on the web yet; the app has its own storage |
