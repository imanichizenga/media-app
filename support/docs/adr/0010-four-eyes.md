# 0010. Four-eyes approvals

Status: accepted, 2026-11-23

## Context
Sensitive changes need a second person.

## Decision
Generic approval requests with identifiers only in the payload. Both people are re-checked at execution, inside one transaction. A CHECK constraint forbids self-approval. `auto` means on in production. Changing the policy is judged by the policy in force. Break-glass is a management command, audited.

## Alternatives
Per-feature flags.

## Consequences
Approved invitations and MFA resets are delivered by email only, so neither approver sees the link. SES must therefore be configured early in production.
