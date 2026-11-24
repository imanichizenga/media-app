"use client";
import { keepPreviousData, useInfiniteQuery, useQuery, useQueryClient } from "@tanstack/react-query";
import { useFormatter } from "next-intl";
import { useEffect, useSyncExternalStore } from "react";
import { call, client } from "./api";
import { realtime } from "./realtime";

export const keys = {
  session: ["session"] as const,
  integrations: ["integrations"] as const,
  integration: (key: string) => ["integrations", key] as const,
  approvals: (status: string) => ["approvals", status] as const,
  staff: ["staff"] as const,
  roles: ["roles"] as const,
  security: ["me", "security"] as const,
  settings: (key: string) => ["settings", key] as const,
};

export const useSession = () =>
  useQuery({
    queryKey: keys.session,
    queryFn: () => call(() => client.GET("/api/v1/auth/session")),
    staleTime: 60_000,
  });
export function useCan() {
  const { data } = useSession();
  return (code: string) => data?.permissions.includes(code) ?? false;
}
export const useIntegrations = (enabled = true) =>
  useQuery({
    queryKey: keys.integrations,
    queryFn: () => call(() => client.GET("/api/v1/integrations")),
    enabled,
    refetchInterval: 60_000,
  });
const useConnected = () =>
  useSyncExternalStore(
    (notify) => {
      const off = realtime.onStatus(notify);
      return () => void off();
    },
    () => realtime.connected,
    () => false,
  );

/** Refetches `queryKey` whenever the server signals `topic`. A null topic watches nothing. */
export function useSignal(topic: string | null, queryKey: readonly string[]) {
  const queries = useQueryClient();
  const id = queryKey.join("/");
  useEffect(() => {
    if (!topic) return;
    return realtime.subscribe(topic, () => queries.invalidateQueries({ queryKey: id.split("/") }));
  }, [topic, id, queries]);
}

export function useIntegration(key: string) {
  const connected = useConnected();
  const query = useQuery({
    queryKey: keys.integration(key),
    queryFn: () => call(() => client.GET("/api/v1/integrations/{key}", { params: { path: { key } } })),
    // Signals drive a running test. Polling covers a missing socket, and a lost signal.
    refetchInterval: (q) => (running(q.state.data?.latest_test) ? (connected ? 5_000 : 700) : false),
  });
  const run = query.data?.latest_test;
  useSignal(run && running(run) ? `integration_test:${run.id}` : null, keys.integration(key));
  return query;
}
const running = (run?: { status: string } | null) => ["queued", "running"].includes(run?.status ?? "");
export const useStaff = () =>
  useQuery({ queryKey: keys.staff, queryFn: () => call(() => client.GET("/api/v1/staff")) });
export const useRoles = () =>
  useQuery({ queryKey: keys.roles, queryFn: () => call(() => client.GET("/api/v1/roles")) });
export const useMySecurity = () =>
  useQuery({ queryKey: keys.security, queryFn: () => call(() => client.GET("/api/v1/me/security")) });
export const useSettings = (key: string) =>
  useQuery({
    queryKey: keys.settings(key),
    queryFn: () => call(() => client.GET("/api/v1/settings/{key}", { params: { path: { key } } })),
    staleTime: Number.POSITIVE_INFINITY,
  });

type Page<T> = { next_cursor: string | null; results: T[] };
export function usePaged<T>(
  key: readonly unknown[],
  load: (cursor?: string) => Promise<Page<T>>,
  enabled = true,
) {
  const query = useInfiniteQuery({
    queryKey: key,
    queryFn: ({ pageParam }) => load(pageParam),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (last: Page<T>) => last.next_cursor ?? undefined,
    placeholderData: keepPreviousData,
    enabled,
  });
  return { ...query, rows: query.data?.pages.flatMap((p) => p.results) };
}

export function useTime() {
  const format = useFormatter();
  return (value: string | null | undefined) =>
    value ? format.dateTime(new Date(value), { dateStyle: "medium", timeStyle: "short" }) : "—";
}

// ---- content ----
export const contentKeys = {
  posts: ["posts"] as const,
  post: (id: string) => ["posts", id] as const,
  media: ["media"] as const,
  asset: (id: string) => ["media", id] as const,
  categories: ["categories"] as const,
  tags: (q: string) => ["tags", q] as const,
  stories: (q: string) => ["stories", q] as const,
  regions: ["regions"] as const,
  redirects: (q: string) => ["redirects", q] as const,
  author: (id: string) => ["authors", id] as const,
};
export const useCategories = () =>
  useQuery({
    queryKey: contentKeys.categories,
    queryFn: () => call(() => client.GET("/api/v1/categories")),
    staleTime: 60_000,
  });
export const useRegions = () =>
  useQuery({
    queryKey: contentKeys.regions,
    queryFn: () => call(() => client.GET("/api/v1/regions")),
    staleTime: 300_000,
  });
export const useAuthors = () =>
  useQuery({
    queryKey: ["authors"],
    queryFn: () => call(() => client.GET("/api/v1/authors")),
    staleTime: 60_000,
  });

const BUSY = new Set(["uploading", "scanning", "processing"]);
export const isBusy = (status?: string) => BUSY.has(status ?? "");
/** One file, kept fresh by signals while it is being processed. */
export function useAsset(id: string | null) {
  const connected = useConnected();
  const query = useQuery({
    queryKey: contentKeys.asset(id ?? ""),
    queryFn: () =>
      call(() => client.GET("/api/v1/media/{asset_id}", { params: { path: { asset_id: id ?? "" } } })),
    enabled: Boolean(id),
    refetchInterval: (q) => (isBusy(q.state.data?.asset.status) ? (connected ? 10_000 : 2_000) : false),
  });
  useSignal(id && isBusy(query.data?.asset.status) ? `asset:${id}` : null, contentKeys.asset(id ?? ""));
  return query;
}
/** Refetches the library when a listed file changes state. */
export function useAssetSignal(id: string, status: string) {
  useSignal(isBusy(status) && status !== "uploading" ? `asset:${id}` : null, contentKeys.media);
}
