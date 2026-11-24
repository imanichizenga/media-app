# 0042. Mobile security

Status: accepted, 2026-11-24

## Context
Nothing in the binary is secret; the network is hostile.

## Decision
SPKI pins (two at least) arrive with the app config, which is itself fetched **without** pins: it is the answer that can switch a wrong pin off. Android: no cleartext outside the dev flavor, no backup, R8, obfuscated Dart with split symbols. iOS: ATS defaults. The device id is in the keychain. One web view exists, for `youtube-nocookie.com/embed/` after a tap; its navigation is locked to that. Changing pins, link owners or the oldest allowed version needs four eyes.

## Alternatives
Pinning the config too (a mistake would lock every phone out).

## Consequences
dart:io shows the leaf certificate only: pins are of the leaf's key and its backup.
