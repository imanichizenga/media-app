# 0002. Version baseline

Status: accepted, 2026-11-23

## Context
The brief asks for latest stable, pinned.

## Decision
Python 3.14, Django 5.2 LTS (supported to April 2028), PostgreSQL 17, Redis 7.1 (ElastiCache's current Redis OSS line), Node 24 LTS, Next 16.4, React 19.3, Terraform 1.17, AWS provider 6.73, Flutter 3.50. TypeScript is 5.9, not 7: `openapi-typescript` 7 requires the 5.x compiler API. Install scripts are denied by default; Dependabot waits 7 days before proposing a release.

## Alternatives
Django 6.1 (not LTS); TypeScript 7 with a second compiler for code generation.

## Consequences
Revisit TypeScript when the generator supports 7. Dart theming uses `material_ui`, because `package:flutter/material.dart` is deprecated since Flutter 3.47.
