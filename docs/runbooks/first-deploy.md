# First deployment of an environment

Needs an AWS account per environment, a Route 53 zone, and the GitHub repository.

1. **Bootstrap** (administrator, once): in `infra/terraform/bootstrap` run `terraform apply -var environment=staging -var github_repository=<owner/name>`.
2. Create `envs/staging/backend.hcl`: `bucket = "<state_bucket>"`, `key = "platform.tfstate"`, `region = "af-south-1"`. af-south-1 must be enabled on the account (it is opt-in).
3. `terraform -chdir=infra/terraform/envs/staging init -backend-config=backend.hcl` then `plan`, review, `apply -var zone_id=... -var domain=...`.
   Services will not become healthy yet: no images exist.
4. `scripts/sync-origin-secret.sh staging <api dist> <admin dist>` (output `distributions`).
5. In GitHub create environment `staging` and variables `AWS_DEPLOY_READY=true`, `AWS_DEPLOY_ROLE`, `AWS_ACCOUNT_ID`, `AWS_REGION`, `APP_SUBNETS` (comma separated), `APP_SECURITY_GROUP`, `API_HOST`, `ADMIN_HOST`. Protect `prod` with required reviewers.
6. Run the Deploy workflow.
7. **First administrators:** run the `migrate` task definition with command override `python manage.py bootstrap_super_admin <email>` **twice, for two people**, and read each link from its log. Links are single use and expire in 72 hours. With one Super Admin, four-eyes changes cannot be approved.
8. In the console, configure and test S3, MediaConvert, audit anchor, WAF and SES with the Terraform output `console` (also the job role for MediaConvert and the API distribution for **Website and CDN**). Leave the access keys empty: the worker's task role is used.
   Until SES passes, security alerts appear only in the console.

9. Upload one picture and one video in Media library. The picture must become Ready within a minute; a file stuck in Scanning means [media-stuck](media-stuck.md).

Set `RDS_CA_SHA256` when building the PgBouncer image to pin the CA bundle.
