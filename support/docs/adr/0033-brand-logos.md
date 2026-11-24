# 0033. Logos: cleaned, rasterised, kept in the database

Status: accepted, 2026-11-24

## Context
An SVG is a program. Logos are needed before media storage is configured.

## Decision
Uploads are base64 JSON up to 1 MB. SVG is parsed with defusedxml and rebuilt from an allowlist of elements and attributes; references only to `#ids`, pictures only as PNG, JPEG or WebP data. What cannot be dropped without changing the drawing (style sheets, live text, filters) is refused with a reason. Both kinds are drawn to PNG at 1x, 2x, 3x and a large size, trimmed, and a white version is made for dark grounds. Files live in Postgres, are served under their own digest, immutable, with a sandboxing policy. Web uses `<img>`, never inline SVG; the app uses PNG.

## Alternatives
Media bucket (needs a wider IAM role and a configured bucket); DOMPurify (a browser engine on the server).

## Consequences
The exception to "the API never proxies bytes" is bounded: a few files, cached at the edge.
