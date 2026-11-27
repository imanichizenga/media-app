#!/usr/bin/env bash
# Regenerates support/generated/api-client-dart from the public OpenAPI schema.
set -euo pipefail
cd "$(dirname "$0")/../.."
rm -rf support/generated/api-client-dart
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/work" openapitools/openapi-generator-cli:v7.27.0 generate \
  -i /work/support/docs/api/openapi-public.json -g dart-dio -o /work/support/generated/api-client-dart \
  --additional-properties=pubName=news_api_client,pubVersion=0.1.0,serializationLibrary=json_serializable,hideGenerationTimestamp=true \
  --global-property=apiTests=false,modelTests=false > /dev/null
rm -rf support/generated/api-client-dart/.openapi-generator support/generated/api-client-dart/.gitignore support/generated/api-client-dart/.travis.yml support/generated/api-client-dart/git_push.sh
cd support/generated/api-client-dart
# json_serializable writes Dart 3.8's null-aware map entries for optional fields; the app is on 3.14 anyway.
sed -i "s/sdk: '>=3.5.0 <4.0.0'/sdk: '>=3.8.0 <4.0.0'/" pubspec.yaml
dart pub get > /dev/null
dart run build_runner build > /dev/null
dart format lib > /dev/null
