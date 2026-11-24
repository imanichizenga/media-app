"use client";
import { useQueryClient } from "@tanstack/react-query";
import { CircleAlert, CircleCheck, Pause, Play, X } from "lucide-react";
import { useTranslations } from "next-intl";
import { createContext, type ReactNode, useCallback, useContext, useEffect, useRef, useState } from "react";
import { cx, useErrorText } from "@/components/ui";
import { call, client } from "@/lib/api";
import { contentKeys } from "@/lib/queries";
import { findUnfinished, kindOf, type Resume, type Transfer, upload, uploadApi } from "@/lib/upload";

type Job = Transfer & { file: File; kind: "image" | "video"; resume?: Resume; onDone?: (id: string) => void };
type Uploads = { add: (files: Iterable<File>, onDone?: (id: string) => void) => void };
const Context = createContext<Uploads>({ add: () => {} });
export const useUploads = () => useContext(Context);

/** Uploads belong to the console, not to a page: moving around does not stop them. */
export function UploadsProvider({ children }: { children: ReactNode }) {
  const queries = useQueryClient();
  const [jobs, setJobs] = useState<Job[]>([]);
  const stops = useRef(new Map<string, AbortController>());
  const patch = useCallback(
    (key: string, values: Partial<Job>) =>
      setJobs((all) => all.map((j) => (j.key === key ? { ...j, ...values } : j))),
    [],
  );

  const run = useCallback(
    async (job: Job) => {
      const stop = new AbortController();
      stops.current.set(job.key, stop);
      patch(job.key, { state: "sending", error: undefined });
      let id = job.asset;
      try {
        const resume = job.resume ?? (await findUnfinished(job.file));
        await upload(
          job.file,
          job.kind,
          uploadApi,
          (sent, asset) => {
            id = asset;
            patch(job.key, { sent, asset });
          },
          stop.signal,
          resume,
        );
        patch(job.key, { state: "done", sent: job.size });
        queries.invalidateQueries({ queryKey: contentKeys.media });
        if (id) job.onDone?.(id);
      } catch (error) {
        patch(job.key, stop.signal.aborted ? { state: "paused" } : { state: "failed", error });
      } finally {
        stops.current.delete(job.key);
      }
    },
    [patch, queries],
  );

  const add = useCallback<Uploads["add"]>(
    (files, onDone) => {
      for (const file of files) {
        const kind = kindOf(file);
        const job: Job = {
          key: crypto.randomUUID(),
          name: file.name,
          size: file.size,
          sent: 0,
          state: kind ? "waiting" : "failed",
          file,
          kind: kind ?? "image",
          onDone,
          ...(kind ? {} : { error: { code: "unsupported_type" } }),
        };
        setJobs((all) => [...all, job]);
        if (kind) void run(job);
      }
    },
    [run],
  );

  const active = jobs.some((j) => j.state === "sending");
  useEffect(() => {
    if (!active) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    addEventListener("beforeunload", warn);
    return () => removeEventListener("beforeunload", warn);
  }, [active]);

  const discard = (job: Job) => {
    stops.current.get(job.key)?.abort();
    setJobs((all) => all.filter((j) => j.key !== job.key));
    const { asset } = job;
    if (asset && job.state !== "done")
      void call(() =>
        client.DELETE("/api/v1/media/uploads/{asset_id}", { params: { path: { asset_id: asset } } }),
      ).catch(() => {});
  };
  return (
    <Context value={{ add }}>
      {children}
      <Tray
        jobs={jobs}
        pause={(job) => stops.current.get(job.key)?.abort()}
        resume={(job) => void run({ ...job, resume: undefined })}
        discard={discard}
      />
    </Context>
  );
}

function Tray({
  jobs,
  pause,
  resume,
  discard,
}: {
  jobs: Job[];
  pause: (job: Job) => void;
  resume: (job: Job) => void;
  discard: (job: Job) => void;
}) {
  const t = useTranslations("media");
  const text = useErrorText();
  if (jobs.length === 0) return null;
  return (
    <section
      aria-label={t("uploads")}
      className="fixed right-4 bottom-4 left-4 z-30 max-h-80 overflow-y-auto rounded-md border border-border bg-surface-raised p-2 shadow-lg sm:left-auto sm:w-96"
    >
      <ul className="flex flex-col">
        {jobs.map((job) => {
          const percent = job.size ? Math.floor((job.sent / job.size) * 100) : 0;
          const failed = job.state === "failed";
          return (
            <li key={job.key} className="flex items-center gap-3 p-2">
              <div className="min-w-0 flex-1">
                <p className="truncate text-label">{job.name}</p>
                <progress
                  value={percent}
                  max={100}
                  aria-label={t("progressOf", { name: job.name })}
                  className={cx("h-1 w-full", failed ? "accent-danger" : "accent-brand")}
                />
                <p className={cx("text-caption", failed ? "text-danger" : "text-text-secondary")}>
                  {failed
                    ? (job.error as { code?: string })?.code === "unsupported_type"
                      ? t("error.unsupported_type")
                      : text(job.error)
                    : t(`transfer.${job.state}`, { percent })}
                </p>
              </div>
              {job.state === "done" ? (
                <CircleCheck aria-hidden size={20} className="text-success" />
              ) : failed ? (
                <CircleAlert aria-hidden size={20} className="text-danger" />
              ) : null}
              {job.state === "sending" && (
                <TrayButton label={t("pause", { name: job.name })} onClick={() => pause(job)}>
                  <Pause aria-hidden size={18} />
                </TrayButton>
              )}
              {(job.state === "paused" || (failed && job.kind && job.asset)) && (
                <TrayButton label={t("resume", { name: job.name })} onClick={() => resume(job)}>
                  <Play aria-hidden size={18} />
                </TrayButton>
              )}
              <TrayButton
                label={t(job.state === "done" ? "dismiss" : "cancelUpload", { name: job.name })}
                onClick={() => discard(job)}
              >
                <X aria-hidden size={18} />
              </TrayButton>
            </li>
          );
        })}
      </ul>
    </section>
  );
}
const TrayButton = ({
  label,
  onClick,
  children,
}: {
  label: string;
  onClick: () => void;
  children: ReactNode;
}) => (
  <button
    type="button"
    aria-label={label}
    onClick={onClick}
    className="tap grid w-11 shrink-0 place-items-center rounded-sm hover:bg-surface-sunken"
  >
    {children}
  </button>
);
