# 0045. The publisher's own pages

Status: accepted, 2026-11-25.

## Context
About, editorial policy, corrections, contact, privacy and terms are asked for by law (PDPA), by Google (E-E-A-T) and by the app stores. The texts are the publisher's (G5), and arrive after the code.

## Decision
A `pages` app: six keys with fixed addresses, the same in both languages. A revision is never changed; publishing points at one, so going back is publishing an older one, and what readers were promised, and when, can be proven. Both languages or none. Permission `pages.manage` (editor in chief and above); publishing asks for a fresh passkey, and is audited. The body is the article's content schema: one renderer, one editor.

A page that is not published does not exist: no address, no link in the footer, no line in the sitemap. Absent, never empty.

## Alternatives
Markdown files in the repository (a lawyer's correction would need a release); posts of a special type (they would appear in feeds and sitemaps as news); a page builder (six texts do not need one).

## Consequences
The site is complete without the texts and whole with them. New addresses need a key, because the website reserves them.
