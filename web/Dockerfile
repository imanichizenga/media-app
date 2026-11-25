# syntax=docker/dockerfile:1
# Build context: repository root.
FROM node:24-slim AS build
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 NEXT_TELEMETRY_DISABLED=1 CI=1
RUN npm install -g pnpm@12.16.1
WORKDIR /repo
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./
COPY web/package.json web/
COPY support/packages/design-tokens/package.json support/packages/design-tokens/
COPY support/generated/api-client/package.json support/generated/api-client/
COPY support/packages/content-schema/package.json support/packages/content-schema/
COPY support/packages/i18n/package.json support/packages/i18n/
COPY support/packages/ui/package.json support/packages/ui/
RUN pnpm install --frozen-lockfile --filter @news/web...
COPY support/packages support/packages
COPY support/generated support/generated
COPY web web
RUN pnpm --filter @news/design-tokens build && pnpm --filter @news/web build

FROM gcr.io/distroless/nodejs24-debian13:nonroot
WORKDIR /app
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 PORT=3000 HOSTNAME=0.0.0.0
COPY --from=build /repo/web/.next/standalone ./
COPY --from=build /repo/web/.next/static ./web/.next/static
COPY --from=build /repo/web/public ./web/public
COPY --from=build /repo/web/fonts ./web/fonts
EXPOSE 3000
CMD ["web/server.js"]
