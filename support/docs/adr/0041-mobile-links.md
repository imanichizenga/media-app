# 0041. Links

Status: accepted, 2026-11-24

## Context
One link opens the same story in web and app (ADR-0024).

## Decision
Routes are the website's addresses; `parsePlace` is the only code that knows them. Tabs use the paths the site reserves: `/`, `/video`, `/search`, `/saved`, `/profile`. Unknown addresses ask `/content/resolve`. The association files are served by the API from the admin's app settings until the website forwards them.

## Alternatives
A custom scheme; a mapping table.

## Consequences
A path the app does not draw opens in the browser.
