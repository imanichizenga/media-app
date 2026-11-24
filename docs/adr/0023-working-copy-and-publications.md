# 0023. Working copy and publications

Status: accepted, 2026-11-24

## Context
Editors change a live article over hours; readers must see only finished versions. A list page that assembles cards from posts, texts, bylines, categories and files needs many joins, for almost all of the traffic.

## Decision
`Post` and `PostText` are the working copy. Publishing writes one `Publication` per language: the complete card and the complete article as JSON, exactly as the public API returns them, with a content hash. `Listing` rows (feed, key, time) are the index for every feed. `content/publishing.py` is the only writer of both. Edits to a live article stay invisible until **Publish changes**. When surroundings change (a category name, a picture's credit, an author), `refresh` rebuilds from the last *published* revision, so unpublished words never leak; "updated" moves only if the result differs.

## Alternatives
Assembling on read with a cache in front (every cold miss is expensive, and one stale part is hard to find); a status flag per revision (readers and editors share tables and locks).

## Consequences
Any change to the card or article shape needs a rebuild of publications (`rebuild_posts`, in batches). Reads are two queries whatever the page. Preview uses the same builder without writing.
