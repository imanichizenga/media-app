#!/usr/bin/env bash
# Release order: migrate (expand only) → roll services → smoke test. ECS rolls each service back on failed health
# checks; if anything fails after that, every service returns to the revision it ran before.
set -euo pipefail
: "${ENVIRONMENT:?}" "${REGISTRY:?}" "${TAG:?}" "${SUBNETS:?}" "${SECURITY_GROUP:?}" "${API_HOST:?}" "${ADMIN_HOST:?}"
prefix="news-$ENVIRONMENT"
services=(worker-critical worker-default beat api-public api-admin ws-admin admin-web)
network="awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}"

# New revision of a family with every image of ours moved to $TAG; prints its ARN.
register() {
  aws ecs describe-task-definition --task-definition "$prefix-$1" --query taskDefinition --output json |
    jq --arg tag "$TAG" --arg registry "$REGISTRY" '
      .containerDefinitions |= map(if (.image | startswith($registry)) then .image |= sub(":[^:/]+$"; ":" + $tag) else . end)
      | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy, .deregisteredAt)
      | with_entries(select(.value != null))' > "/tmp/$1.json"
  aws ecs register-task-definition --cli-input-json "file:///tmp/$1.json" --query taskDefinition.taskDefinitionArn --output text
}

echo "::group::Release task"
task=$(aws ecs run-task --cluster "$prefix" --launch-type FARGATE --task-definition "$(register migrate)" \
  --network-configuration "$network" --query 'tasks[0].taskArn' --output text)
aws ecs wait tasks-stopped --cluster "$prefix" --tasks "$task"
code=$(aws ecs describe-tasks --cluster "$prefix" --tasks "$task" --query 'tasks[0].containers[0].exitCode' --output text)
[ "$code" = "0" ] || { echo "Release task failed ($code). Nothing was rolled out."; exit 1; }
echo "::endgroup::"

declare -A previous
for s in "${services[@]}"; do
  previous[$s]=$(aws ecs describe-services --cluster "$prefix" --services "$s" --query 'services[0].taskDefinition' --output text)
done
rollback() {
  echo "::error::Deployment failed, returning every service to its previous revision"
  for s in "${services[@]}"; do
    aws ecs update-service --cluster "$prefix" --service "$s" --task-definition "${previous[$s]}" > /dev/null
  done
  aws ecs wait services-stable --cluster "$prefix" --services "${services[@]}"
}
trap rollback ERR

declare -A target
for s in "${services[@]}"; do
  target[$s]=$(register "$s")
  aws ecs update-service --cluster "$prefix" --service "$s" --task-definition "${target[$s]}" > /dev/null
done
aws ecs wait services-stable --cluster "$prefix" --services "${services[@]}"
for s in "${services[@]}"; do
  # "Stable" is also true after ECS rolled a service back, so check what is actually running.
  now=$(aws ecs describe-services --cluster "$prefix" --services "$s" --query 'services[0].taskDefinition' --output text)
  [ "$now" = "${target[$s]}" ] || { echo "$s was rolled back by its circuit breaker"; false; }
done

curl -fsS --retry 5 --retry-all-errors "https://$API_HOST/health/ready" > /dev/null
curl -fsS --retry 5 --retry-all-errors "https://$API_HOST/api/v1/site-config" > /dev/null
curl -fsS --retry 5 --retry-all-errors "https://$ADMIN_HOST/healthz" > /dev/null
code=$(curl -s -o /dev/null -w '%{http_code}' "https://$ADMIN_HOST/api/v1/auth/session")
[ "$code" = "401" ] || { echo "Admin API answered $code, expected 401"; false; }
code=$(curl -s -o /dev/null -w '%{http_code}' "https://$API_HOST/api/v1/auth/session")
[ "$code" = "404" ] || { echo "The public host exposes admin routes ($code)"; false; }
# No session and no Origin: the socket service must answer, and must refuse.
code=$(curl -s -o /dev/null -w '%{http_code}' --http1.1 -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Sec-WebSocket-Version: 13' \
  -H 'Sec-WebSocket-Key: AAAAAAAAAAAAAAAAAAAAAA==' "https://$ADMIN_HOST/ws/v1/staff")
[ "$code" = "403" ] || { echo "The staff socket answered $code, expected 403"; false; }
echo "Deployed $TAG to $ENVIRONMENT"
