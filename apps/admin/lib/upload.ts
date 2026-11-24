import type { Schemas } from "@news/api-client/admin";
import { ApiError, call, client } from "./api";

export type Asset = Schemas["Asset"];
export type Transfer = {
  key: string;
  name: string;
  size: number;
  sent: number;
  state: "waiting" | "sending" | "paused" | "done" | "failed";
  error?: unknown;
  asset?: string;
};
export type Api = {
  begin(file: File, kind: "image" | "video"): Promise<{ id: string; partSize: number; partCount: number }>;
  existing(id: string): Promise<number[]>;
  sign(id: string, numbers: number[]): Promise<Record<string, string>>;
  put(url: string, body: Blob, onProgress: (bytes: number) => void, signal: AbortSignal): Promise<void>;
  complete(id: string): Promise<unknown>;
  sleep(ms: number): Promise<void>;
};

const PARALLEL = 3;
const SIGN = 10;
const RETRIES = 6;

/** An upload begun earlier, perhaps in a tab that is gone. Only what is missing is sent. */
export type Resume = { id: string; partSize: number; partCount: number };

/** Sends a file in parts straight to storage. A failed part waits and tries again; finished parts stay sent. */
export async function upload(
  file: File,
  kind: "image" | "video",
  api: Api,
  onProgress: (sent: number, id: string) => void,
  signal: AbortSignal,
  resume?: Resume,
): Promise<string> {
  const { id, partSize, partCount } = resume ?? (await api.begin(file, kind));
  const length = (n: number) => Math.min(partSize, file.size - (n - 1) * partSize);
  const have = new Set(resume ? await api.existing(id) : []);
  const flying = new Map<number, number>();
  let done = [...have].reduce((sum, n) => sum + length(n), 0);
  const report = () => onProgress(done + [...flying.values()].reduce((a, b) => a + b, 0), id);
  report();
  const queue = Array.from({ length: partCount }, (_, i) => i + 1).filter((n) => !have.has(n));
  const urls = new Map<number, string>();
  // One request at a time: the next worker usually finds its address already there.
  let signing: Promise<unknown> = Promise.resolve();
  const urlFor = async (n: number): Promise<string> => {
    const turn = signing.then(async () => {
      if (urls.has(n)) return;
      const batch = [n, ...queue.filter((m) => !urls.has(m) && m !== n).slice(0, SIGN - 1)];
      const signed = await api.sign(id, batch);
      for (const [k, url] of Object.entries(signed)) urls.set(Number(k), url);
    });
    signing = turn.catch(() => {});
    await turn;
    return urls.get(n) as string;
  };
  const send = async (n: number) => {
    for (let attempt = 0; ; attempt++) {
      signal.throwIfAborted();
      try {
        const url = await urlFor(n);
        await api.put(
          url,
          file.slice((n - 1) * partSize, (n - 1) * partSize + length(n)),
          (bytes) => {
            flying.set(n, bytes);
            report();
          },
          signal,
        );
        flying.delete(n);
        done += length(n);
        report();
        return;
      } catch (error) {
        flying.delete(n);
        signal.throwIfAborted();
        urls.delete(n); // it may have expired
        if (attempt >= RETRIES || (error instanceof ApiError && error.status >= 400 && error.status < 500))
          throw error;
        report();
        await api.sleep(Math.min(30_000, 1_000 * 2 ** attempt));
      }
    }
  };
  const worker = async () => {
    for (let n = queue.shift(); n !== undefined; n = queue.shift()) await send(n);
  };
  await Promise.all(Array.from({ length: PARALLEL }, worker));
  await api.complete(id);
  return id;
}

const put: Api["put"] = (url, body, onProgress, signal) =>
  new Promise((resolve, reject) => {
    // fetch() cannot report upload progress.
    const request = new XMLHttpRequest();
    request.open("PUT", url);
    request.upload.onprogress = (e) => onProgress(e.loaded);
    request.onload = () =>
      request.status < 300 ? resolve() : reject(new Error(`storage answered ${request.status}`));
    request.onerror = () => reject(new Error("network"));
    request.ontimeout = request.onerror;
    const abort = () => request.abort();
    request.onabort = () => reject(new DOMException("Aborted", "AbortError"));
    signal.addEventListener("abort", abort, { once: true });
    request.onloadend = () => signal.removeEventListener("abort", abort);
    request.send(body);
  });

const path = (asset_id: string) => ({ params: { path: { asset_id } } });
export const uploadApi: Api = {
  begin: async (file, kind) => {
    const r = await call(() =>
      client.POST("/api/v1/media/uploads", { body: { kind, filename: file.name, size: file.size } }),
    );
    return { id: r.asset.id, partSize: r.part_size, partCount: r.part_count };
  },
  existing: async (id) =>
    (await call(() => client.GET("/api/v1/media/uploads/{asset_id}/parts", path(id)))).parts,
  sign: async (id, numbers) =>
    (
      await call(() =>
        client.POST("/api/v1/media/uploads/{asset_id}/parts", { ...path(id), body: { numbers } }),
      )
    ).urls,
  put,
  complete: (id) => call(() => client.POST("/api/v1/media/uploads/{asset_id}", path(id))),
  sleep: (ms) => new Promise((resolve) => setTimeout(resolve, ms)),
};

const MIN_PART = 8 * 1024 ** 2;
const MAX_PARTS = 9000;
/** The server's rule, for a file whose upload was begun before this page was opened. */
export const partSizeFor = (size: number) => Math.max(MIN_PART, Math.ceil(size / MAX_PARTS));

export async function findUnfinished(file: File): Promise<Resume | undefined> {
  const page = await call(() =>
    client.GET("/api/v1/media", { params: { query: { mine: true, status: "uploading", q: file.name } } }),
  );
  const match = page.results.find((a) => a.filename === file.name && a.bytes === file.size);
  if (!match) return undefined;
  const partSize = partSizeFor(file.size);
  return { id: match.id, partSize, partCount: Math.ceil(file.size / partSize) };
}

export const kindOf = (file: File): "image" | "video" | null =>
  file.type.startsWith("image/") ? "image" : file.type.startsWith("video/") ? "video" : null;
