# 0004. One user table, isolated staff realm

Status: accepted, 2026-11-23

## Context
A journalist can also be a reader.

## Decision
`accounts.User` holds identity. Staff sign-in is a separate realm: own sessions, cookie, host and MFA. Django's auth backends and admin are not installed.

## Alternatives
Two user tables; `django.contrib.auth` permissions.

## Consequences
Account merging is never needed. Public tokens (M4) can never authenticate to admin.
