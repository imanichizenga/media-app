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
