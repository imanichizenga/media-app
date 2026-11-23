# Backup and restore drill

Automated backups: 14 days, point-in-time (RPO about 5 minutes). Drill every quarter:

1. `aws rds restore-db-instance-to-point-in-time --source-db-instance-identifier news-<env> --target-db-instance-identifier news-<env>-drill --use-latest-restorable-time`
2. Point a local `DATABASE_URL` at it through a bastion session and run `python manage.py verify_audit_chain`.
3. Run `verify_against_worm()` (audit-chain-broken, step 3). Record the duration: the target RTO is 1 hour. Delete the drill instance.

Not yet performed: it needs the staging account.
