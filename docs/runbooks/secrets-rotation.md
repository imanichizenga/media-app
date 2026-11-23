# Rotating secrets

1. Raise `secrets_version` in the environment and apply. This regenerates the database, Redis, Django and origin secrets together, so plan a maintenance window.
2. Run the Deploy workflow: the release task sets the new `news_app` password and tasks restart with new values.
3. Run `scripts/sync-origin-secret.sh` for both distributions.

Rotating the Django key invalidates CSRF tokens (pages refresh them) and **recovery codes**: ask staff to generate new ones. KMS keys rotate yearly on their own; old ciphertext stays readable.
