import { Bone } from "@news/ui/base";
import { ArticleBody } from "@news/ui/content";
import type { Metadata } from "next";
import type { ReactNode } from "react";
import { ArticleView } from "@/components/article";
import { ExploreView } from "@/components/explore";
import { Frame, Wide } from "@/components/frame";
import { HomeView } from "@/components/home";
import { Feed, none, PageHead, Subsections } from "@/components/parts";
import { ShortsBones, ShortsFrame } from "@/components/shorts";
import { VideoView } from "@/components/video";
import { home, navigation, orNull, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { viewOf } from "@/lib/view";

export const metadata: Metadata = { robots: { index: false, follow: false }, title: "" };
const Part = ({ kind, paths, children }: { kind: string; paths?: string; children: ReactNode }) => (
  <template data-skeleton={kind} data-paths={paths}>
    {children}
  </template>
);

/** Every page without its data, asked for once, shown while the next page comes (web/islands/navigate.ts). */
export default async function Page({ params }: { params: Promise<{ locale: Locale }> }) {
  const { locale } = await params;
  const [site, nav, front] = await Promise.all([readSite(), navigation(locale), orNull(home(locale))]);
  // Sections with sections of their own open on a row of chips: their skeleton has it too.
  const parents = nav.filter((n) => n.children.length > 0).map((n) => n.path);
  const view = viewOf(locale, site);
  const t = words(locale);
  const feed = (lead: boolean) => <Feed list={none(9)} env={view} t={t} lead={lead} empty={null} />;
  return (
    <>
      <Part kind="home">
        <HomeView locale={locale} known={front ?? undefined} />
      </Part>
      <Part kind="front">
        <Frame locale={locale} path={at(locale, "/latest")} place="home" view={view}>
          <Wide>
            <PageHead hidden />
            {feed(true)}
          </Wide>
        </Frame>
      </Part>
      <Part kind="section" paths={parents.join(" ")}>
        <Frame locale={locale} path={at(locale, "/latest")} place="home" view={view}>
          <Wide>
            <PageHead hidden>
              <Subsections />
            </PageHead>
            {feed(true)}
          </Wide>
        </Frame>
      </Part>
      <Part kind="story">
        <Frame locale={locale} path="" place="home" view={view} title={<Bone className="w-32" />}>
          <Wide>
            <PageHead>
              <p className="max-w-prose text-text-secondary lg:text-body-l">
                <Bone className="w-3/4" />
              </p>
            </PageHead>
            {feed(true)}
          </Wide>
        </Frame>
      </Part>
      <Part kind="list">
        <Frame locale={locale} path="" place="home" view={view} title={<Bone className="w-32" />}>
          <Wide>
            <PageHead />
            {feed(true)}
          </Wide>
        </Frame>
      </Part>
      <Part kind="author">
        <Frame locale={locale} path="" place="home" view={view} title={<Bone className="w-32" />}>
          <Wide>
            <div className="flex flex-col gap-4 border-border border-b pt-6 pb-6 sm:flex-row sm:items-start lg:pt-10">
              <span aria-hidden data-face className="bone block! size-24 shrink-0 rounded-full!" />
              <div className="flex min-w-0 flex-1 flex-col gap-2">
                <p className="font-serif text-headline-l lg:text-display">
                  <Bone className="w-64" />
                </p>
                <p className="text-label">
                  <Bone className="w-40" />
                </p>
                <p className="max-w-prose text-body-l">
                  <Bone className="w-full" />
                  <Bone className="w-2/3" />
                </p>
              </div>
            </div>
            {feed(false)}
          </Wide>
        </Frame>
      </Part>
      <Part kind="article">
        <ArticleView env={view} zone={site.localization.timezone} related={[]} path="" />
      </Part>
      <Part kind="video">
        <VideoView locale={locale} list={none(12)} />
      </Part>
      <Part kind="explore">
        <ExploreView locale={locale} view={view} nav={none(8)} faces={[]} />
      </Part>
      <Part kind="shorts">
        <ShortsFrame locale={locale}>
          <ShortsBones />
        </ShortsFrame>
      </Part>
      <Part kind="still">
        <Frame locale={locale} path="" view={view} title={<Bone className="w-32" />}>
          <Wide>
            <div className="mx-auto max-w-[44rem]">
              <PageHead />
              <div className="pt-10">
                <ArticleBody.Skeleton />
              </div>
            </div>
          </Wide>
        </Frame>
      </Part>
    </>
  );
}
