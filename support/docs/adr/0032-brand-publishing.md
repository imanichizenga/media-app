# 0032. Publishing and delivering the brand

Status: accepted, 2026-11-24

## Context
Name, logos, theme and colour must change together, be reviewable, reversible, and arrive without a flash.

## Decision
One settings section `brand` = identity + appearance, one version. `PUT /api/v1/brand`: step-up, `settings.manage`, four-eyes action `brand.publish`, audit event. `BrandVersion` keeps every published state with its stylesheet; restoring publishes it again as a new version. The theme is served at `/theme/<hash>.css`, immutable; old hashes answer for ever, so a cached page never loses its colours. Its selector is `html:root`, which outranks the bundled default in any order. The console links `/theme/current.css`, a redirect to the hash, because its server cannot know the hash without a call to the API; it blocks first paint either way. Public payload and manifest carry tokens and theme colours.

Old fields: migration 0002 (expand) copies names and colours into `brand`; the placeholder blue counts as "not chosen". The old row stays for the release that is still running; 0003 (contract) deletes it in the next release. Old logos were library files and are uploaded again, through the new checks: no environment has been deployed yet.

## Alternatives
Inline style from the server (needs a nonce per page, defeats the CDN); one stylesheet address with short cache (flash or staleness).

## Consequences
The preview runs real screens in a same-origin frame: `/preview` alone allows `frame-ancestors 'self'`. Emails take the name and colours and load no pictures. Share images (M2) and notifications (M6) read the same payload.
