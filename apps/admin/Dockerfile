# syntax=docker/dockerfile:1
# Build context: repository root.
FROM node:26-slim AS build
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 NEXT_TELEMETRY_DISABLED=1 CI=1
RUN npm install -g pnpm@12.16.1
WORKDIR /repo
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./
COPY apps/admin/package.json apps/admin/
COPY packages/design-tokens/package.json packages/design-tokens/
COPY packages/api-client/package.json packages/api-client/
RUN pnpm install --frozen-lockfile --filter @news/admin...
COPY packages packages
COPY apps/admin apps/admin
RUN pnpm --filter @news/design-tokens build && pnpm --filter @news/admin build

FROM gcr.io/distroless/nodejs24-debian13:nonroot
WORKDIR /app
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 PORT=3001 HOSTNAME=0.0.0.0
COPY --from=build /repo/apps/admin/.next/standalone ./
COPY --from=build /repo/apps/admin/.next/static ./apps/admin/.next/static
EXPOSE 3001
CMD ["apps/admin/server.js"]
