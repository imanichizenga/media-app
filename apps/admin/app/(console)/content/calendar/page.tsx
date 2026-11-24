"use client";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, ChevronLeft, ChevronRight } from "lucide-react";
import Link from "next/link";
import { useFormatter, useTimeZone, useTranslations } from "next-intl";
import { useEffect, useState } from "react";
import { STATUS_TONE } from "@/components/editor/panels";
import { Badge, Bone, Button, Card, cx, ErrorState, PageHeader } from "@/components/ui";
import { call, client } from "@/lib/api";
import { contentKeys } from "@/lib/queries";
import { addDays, dayOf, fromZoned, mondayOf } from "@/lib/time";

export default function Calendar() {
  const t = useTranslations("content");
  const format = useFormatter();
  const zone = useTimeZone() ?? "UTC";
  const [week, setWeek] = useState(() => mondayOf(dayOf(new Date(), zone)));
  // "Today" may differ between the server that drew the page and the person reading it.
  const [today, setToday] = useState("");
  useEffect(() => setToday(dayOf(new Date(), zone)), [zone]);
  const days = Array.from({ length: 7 }, (_, i) => addDays(week, i));
  const from = fromZoned(`${week}T00:00`, zone) ?? "";
  const to = fromZoned(`${addDays(week, 7)}T00:00`, zone) ?? "";
  const { data, error, refetch } = useQuery({
    queryKey: [...contentKeys.posts, "calendar", from],
    queryFn: () =>
      call(() =>
        client.GET("/api/v1/posts", {
          params: { query: { from, to, status: ["scheduled", "published"], page_size: 100 } as never },
        }),
      ),
  });
  const on = (day: string) =>
    (data?.results ?? [])
      .map((p) => ({ ...p, at: new Date(p.scheduled_at ?? p.published_at ?? p.updated_at) }))
      .filter((p) => dayOf(p.at, zone) === day)
      .sort((a, b) => a.at.getTime() - b.at.getTime());
  const name = (day: string, options: object) =>
    format.dateTime(new Date(`${day}T00:00:00Z`), { ...options, timeZone: "UTC" });
  return (
    <>
      <PageHeader
        title={t("calendar")}
        lead={`${name(week, { day: "numeric", month: "long" })} – ${name(addDays(week, 6), { day: "numeric", month: "long", year: "numeric" })}`}
        actions={
          <>
            <Link
              href="/content"
              aria-label={t("back")}
              className="tap grid w-11 place-items-center rounded-sm hover:bg-surface-sunken"
            >
              <ArrowLeft aria-hidden size={20} />
            </Link>
            <Button
              variant="secondary"
              aria-label={t("previousWeek")}
              onClick={() => setWeek(addDays(week, -7))}
            >
              <ChevronLeft aria-hidden size={18} />
            </Button>
            <Button variant="secondary" onClick={() => setWeek(mondayOf(dayOf(new Date(), zone)))}>
              {t("thisWeek")}
            </Button>
            <Button variant="secondary" aria-label={t("nextWeek")} onClick={() => setWeek(addDays(week, 7))}>
              <ChevronRight aria-hidden size={18} />
            </Button>
          </>
        }
      />
      {error ? (
        <ErrorState error={error} retry={refetch} />
      ) : (
        <ol className="grid gap-3 lg:grid-cols-7">
          {days.map((day) => (
            <li key={day}>
              <Card className={cx("h-full min-h-40 p-3!", day === today && "border-accent!")}>
                <h2 className="pb-2 font-sans text-label">
                  {name(day, { weekday: "short", day: "numeric" })}
                </h2>
                <ul className="flex flex-col gap-2">
                  {data
                    ? on(day).map((post) => (
                        <li key={post.id}>
                          <Link
                            href={`/content/${post.id}`}
                            prefetch={false}
                            className="tap block rounded-sm bg-surface-sunken p-2 hover:text-accent"
                          >
                            <span className="flex flex-wrap items-center gap-1 text-caption text-text-secondary">
                              {format.dateTime(post.at, { timeStyle: "short" })}
                              <Badge tone={STATUS_TONE[post.status]}>{t(`status.${post.status}`)}</Badge>
                            </span>
                            <span className="line-clamp-3 text-label">{post.headline || t("untitled")}</span>
                          </Link>
                        </li>
                      ))
                    : [0, 1].map((i) => (
                        <li key={i} className="rounded-sm bg-surface-sunken p-2" data-skeleton="slot">
                          <span className="block text-caption">
                            <Bone className="w-16" />
                          </span>
                          <span className="block text-label">
                            <Bone className="w-full" />
                          </span>
                        </li>
                      ))}
                </ul>
              </Card>
            </li>
          ))}
        </ol>
      )}
    </>
  );
}
