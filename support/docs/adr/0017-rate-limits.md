# 0017. Rate limits and lockout

Status: accepted, 2026-11-23

## Context
Brute force and denial of service.

## Decision
GCRA in Redis with hashed subjects. Staff authentication fails closed without Redis; everything else fails open. Lockout is per account and IP, plus a 12x account-wide ceiling, so an attacker cannot lock a victim out. MFA is limited per session and per user.

## Alternatives
Account lockout; CAPTCHA.

## Consequences
A Redis outage blocks new staff sign-ins, not existing sessions.
