# Audit chain broken

**Alarm:** `audit-chain-broken`. Treat it as a security incident, not a bug.

1. Do not deploy, migrate or restore. Snapshot the database: `aws rds create-db-snapshot`.
2. Run `python manage.py verify_audit_chain` and keep the output.
   - `content_modified`, `broken_link`: an entry was edited.
   - `gap`, `head_mismatch`, `anchored_entry_missing`: entries were removed.
   - `anchor_mismatch`: the chain was recomputed. Someone had owner access.
3. Compare with WORM storage, which a database attacker cannot change:
   `python manage.py shell -c "from newsplatform.integrations.providers.audit_anchor import verify_against_worm as v; print(v())"`
4. Rotate database credentials (see secrets-rotation), review CloudTrail and RDS logs, restore a copy to find the originals.
