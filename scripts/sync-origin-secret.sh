#!/usr/bin/env bash
# Copies ORIGIN_VERIFY_SECRET from Secrets Manager into the CloudFront origin header, so it never enters
# Terraform state. Run after the first apply and after rotating secrets. Usage: sync-origin-secret.sh <env> <dist-id>...
set -euo pipefail
env="${1:?environment}"
shift
secret=$(aws secretsmanager get-secret-value --secret-id "news-$env/ORIGIN_VERIFY_SECRET" --query SecretString --output text)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
umask 077
for id in "$@"; do
  aws cloudfront get-distribution-config --id "$id" > "$tmp/raw.json"
  etag=$(jq -r .ETag "$tmp/raw.json")
  SECRET="$secret" jq '.DistributionConfig | .Origins.Items |= map(.CustomHeaders = {Quantity: 1, Items: [{HeaderName: "X-Origin-Verify", HeaderValue: env.SECRET}]})' "$tmp/raw.json" > "$tmp/new.json"
  aws cloudfront update-distribution --id "$id" --if-match "$etag" --distribution-config "file://$tmp/new.json" --query Distribution.Status --output text
done
