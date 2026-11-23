#!/usr/bin/env bash
# Regenerates packages/api-client-dart from the public OpenAPI schema.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf packages/api-client-dart
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/work" openapitools/openapi-generator-cli:v7.27.0 generate \
  -i /work/docs/api/openapi-public.json -g dart-dio -o /work/packages/api-client-dart \
  --additional-properties=pubName=news_api_client,pubVersion=0.1.0,serializationLibrary=json_serializable,hideGenerationTimestamp=true \
  --global-property=apiTests=false,modelTests=false > /dev/null
rm -rf packages/api-client-dart/.openapi-generator packages/api-client-dart/.gitignore packages/api-client-dart/.travis.yml packages/api-client-dart/git_push.sh
cd packages/api-client-dart
dart pub get > /dev/null
dart run build_runner build > /dev/null
dart format lib > /dev/null
