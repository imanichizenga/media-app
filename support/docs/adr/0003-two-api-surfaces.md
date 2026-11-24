# 0003. Separate public and admin API surfaces

Status: accepted, 2026-11-23

## Context
Admin must be isolated from the public API.

## Decision
One codebase, two deployments chosen by `API_SURFACE`. The public process does not load admin URLs at all. Two OpenAPI documents. Admin API is served on the admin origin under `/api/v1`.

## Alternatives
One deployment with permission checks; two codebases.

## Consequences
A routing mistake cannot expose admin endpoints (tested). Same image, different blast radius and IAM role.
