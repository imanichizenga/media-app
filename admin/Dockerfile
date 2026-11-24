# syntax=docker/dockerfile:1
# Build context: repository root.
FROM node:24-slim AS build
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 NEXT_TELEMETRY_DISABLED=1 CI=1
RUN npm install -g pnpm@12.16.1
WORKDIR /repo
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./
COPY admin/package.json admin/
COPY support/packages/design-tokens/package.json support/packages/design-tokens/
COPY support/generated/api-client/package.json support/generated/api-client/
COPY support/packages/content-schema/package.json support/packages/content-schema/
COPY support/packages/ui/package.json support/packages/ui/
COPY support/packages/screens/package.json support/packages/screens/
RUN pnpm install --frozen-lockfile --filter @news/admin...
COPY support/packages support/packages
COPY support/generated support/generated
COPY admin admin
RUN pnpm --filter @news/design-tokens build && pnpm --filter @news/admin build

FROM gcr.io/distroless/nodejs24-debian13:nonroot
WORKDIR /app
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 PORT=3001 HOSTNAME=0.0.0.0
COPY --from=build /repo/admin/.next/standalone ./
COPY --from=build /repo/admin/.next/static ./admin/.next/static
COPY --from=build /repo/admin/public ./admin/public
EXPOSE 3001
CMD ["admin/server.js"]
