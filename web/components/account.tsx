import { cx } from "@news/ui/base";
import {
  Download,
  Eye,
  Heart,
  LogOut,
  MessageCircle,
  SendHorizontal,
  Smartphone,
  Trash2,
  Users,
  X,
} from "@news/ui/icons";
import type { T } from "@/lib/i18n";
import { BUTTON } from "./button";

/**
 * Readers' accounts and what they do (ADR-0050). Everything here is drawn by the server, the same for everyone, so
 * the CDN keeps one copy; islands/account.ts fills in who is signed in and the counts, and opens the sheets.
 * Without script: sign-in, likes and comments need it; reading never does.
 */
export type Methods = {
  phone: boolean;
  google: boolean;
  apple: boolean;
  local_sms: boolean;
  resend_seconds: number;
  terms_version: string;
};

const FIELD =
  "h-12 w-full rounded-md border border-border-strong bg-surface px-4 text-body-l outline-none placeholder:text-text-tertiary focus:border-text-primary";
const SECOND =
  "tap flex w-full items-center justify-center gap-3 rounded-md border border-border-strong bg-surface px-4 text-label font-medium hover:bg-surface-sunken";

function Google() {
  return (
    <svg aria-hidden viewBox="0 0 24 24" width="20" height="20">
      <path
        fill="#EA4335"
        d="M12 10.2v3.9h5.5c-.2 1.3-1.6 3.9-5.5 3.9-3.3 0-6-2.7-6-6.1s2.7-6.1 6-6.1c1.9 0 3.1.8 3.8 1.5l2.6-2.5C16.8 3.3 14.6 2.4 12 2.4 6.7 2.4 2.4 6.7 2.4 12s4.3 9.6 9.6 9.6c5.5 0 9.2-3.9 9.2-9.4 0-.6-.1-1.1-.2-1.6H12Z"
      />
      <path
        fill="#4285F4"
        d="M21.2 10.6H12v3.5h5.5c-.3 1.2-1 2.2-2.1 2.9l3.3 2.6c1.9-1.8 3-4.4 3-7.4 0-.6-.1-1.1-.2-1.6Z"
      />
      <path
        fill="#FBBC05"
        d="M6.4 14.1A6 6 0 0 1 6 12c0-.7.1-1.4.4-2.1L3 7.3A9.6 9.6 0 0 0 2.4 12c0 1.6.4 3.1 1 4.4l3-2.3Z"
      />
      <path
        fill="#34A853"
        d="M12 21.6c2.6 0 4.8-.9 6.4-2.4l-3.1-2.5c-.9.6-2 1-3.3 1-2.5 0-4.6-1.7-5.4-4l-3.2 2.4c1.6 3.2 4.9 5.5 8.6 5.5Z"
      />
    </svg>
  );
}
function Apple() {
  return (
    <svg aria-hidden viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
      <path d="M16.4 12.6c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9-.8 0-2-.9-3.4-.9-1.7 0-3.3 1-4.2 2.6-1.8 3.1-.5 7.7 1.3 10.2.9 1.2 1.9 2.6 3.2 2.6 1.3-.1 1.8-.8 3.4-.8s2 .8 3.4.8c1.4 0 2.3-1.3 3.1-2.5 1-1.4 1.4-2.8 1.4-2.9-.1 0-2.8-1.1-2.8-4.1ZM13.8 4.9c.7-.9 1.2-2 1.1-3.2-1 0-2.3.7-3 1.6-.7.8-1.3 2-1.1 3.1 1.1.1 2.3-.6 3-1.5Z" />
    </svg>
  );
}

/**
 * One sheet for every way in (SPEC: phone, Google and Apple in ONE sheet, never a full-page wall): a bottom sheet on a
 * phone, a dialog at a desk. Its title says what the reader was doing ("Sign in to like this story"), and after it
 * that very thing is done.
 */
export function AuthSheet({ t, methods, brand }: { t: T; methods: Methods; brand: string }) {
  const none = !methods.phone && !methods.google && !methods.apple;
  return (
    <dialog
      id="auth-sheet"
      data-auth-sheet
      aria-labelledby="auth-title"
      data-local={methods.local_sms ? "" : undefined}
      data-resend={methods.resend_seconds}
      data-terms={methods.terms_version}
      data-say-phone={t("errorPhone")}
      data-say-country={t("errorCountry")}
      data-say-wait={t("errorWait")}
      data-say-wrong={t("errorCodeWrong", { n: "#" })}
      data-say-expired={t("errorCodeExpired")}
      data-say-sms={t("errorSmsDown")}
      data-say-error={t("errorTryAgain")}
      data-say-resend-in={t("codeResendIn", { n: "#" })}
      data-say-local={t("codeLocal", { v: "#" })}
      data-say-lead={t("codeLead", { v: "#" })}
      data-say-welcome={t("signedInToast", { name: "#" })}
      data-say-signed-out={t("signedOutToast")}
      className="sheet m-0 mt-auto w-full max-w-none rounded-t-2xl bg-surface p-0 text-text-primary shadow-2xl backdrop:bg-black/50 sm:m-auto sm:max-w-md sm:rounded-2xl"
    >
      <div className="relative flex flex-col gap-5 px-5 pt-3 pb-[max(1.25rem,env(safe-area-inset-bottom))] sm:p-7">
        <span aria-hidden className="mx-auto h-1 w-10 rounded-full bg-border-strong sm:hidden" />
        <button
          type="button"
          data-sheet-close
          aria-label={t("close")}
          className="tap absolute top-2 right-2 grid w-11 place-items-center rounded-full text-text-secondary hover:bg-surface-sunken"
        >
          <X size={20} />
        </button>

        {/* 1. How to come in */}
        <div data-step="start" className="flex flex-col gap-5">
          <div className="flex flex-col gap-1 pr-10">
            <h2
              id="auth-title"
              className="font-serif text-headline-m"
              data-auth-title
              data-default={t("signInTitle")}
            >
              {t("signInTitle")}
            </h2>
            <p className="text-text-secondary">{t("signInLead")}</p>
          </div>
          {none && <p className="rounded-md bg-surface-sunken p-4 text-label">{t("errorSmsDown")}</p>}
          {methods.phone && (
            <form data-form="phone" className="flex flex-col gap-3" noValidate>
              <label htmlFor="auth-phone" className="text-label font-medium">
                {t("phoneLabel")}
              </label>
              <div className="flex gap-2">
                <span className="grid h-12 shrink-0 place-items-center rounded-md border border-border bg-surface-sunken px-3 text-label tabular-nums">
                  🇹🇿 +255
                </span>
                <input
                  id="auth-phone"
                  name="phone"
                  type="tel"
                  inputMode="tel"
                  autoComplete="tel-national"
                  placeholder="712 345 678"
                  required
                  maxLength={20}
                  className={FIELD}
                  aria-describedby="auth-phone-hint auth-error"
                />
              </div>
              <p id="auth-phone-hint" className="text-caption text-text-secondary">
                {t("phoneHint")}
              </p>
              <button type="submit" className={cx(BUTTON, "w-full")}>
                <Smartphone size={18} className="mr-2" />
                {t("sendCode")}
              </button>
            </form>
          )}
          {(methods.google || methods.apple) && (
            <div className="flex flex-col gap-3">
              {methods.phone && (
                <p className="flex items-center gap-3 text-caption text-text-secondary before:h-px before:flex-1 before:bg-border after:h-px after:flex-1 after:bg-border">
                  {t("orWith")}
                </p>
              )}
              {methods.google && (
                <a href="/api/auth/google/start" data-oauth className={SECOND}>
                  <Google />
                  {t("withGoogle")}
                </a>
              )}
              {methods.apple && (
                <a href="/api/auth/apple/start" data-oauth className={SECOND}>
                  <Apple />
                  {t("withApple")}
                </a>
              )}
            </div>
          )}
        </div>

        {/* 2. The code */}
        <form data-step="code" data-form="code" hidden className="flex flex-col gap-4" noValidate>
          <div className="flex flex-col gap-1 pr-10">
            <h2 className="font-serif text-headline-m">{t("codeTitle")}</h2>
            <p className="text-text-secondary" data-code-lead />
          </div>
          <label htmlFor="auth-code" className="sr-only">
            {t("codeLabel")}
          </label>
          <input
            id="auth-code"
            name="code"
            inputMode="numeric"
            autoComplete="one-time-code"
            pattern="[0-9]*"
            maxLength={6}
            placeholder="••••••"
            className={cx(FIELD, "text-center font-semibold text-headline-m tracking-[0.5em]")}
            aria-describedby="auth-error"
          />
          <p
            data-local-code
            hidden
            className="rounded-md bg-warning-soft px-3 py-2 text-caption text-warning"
          />
          <button type="submit" className={cx(BUTTON, "w-full")}>
            {t("verify")}
          </button>
          <div className="flex items-center justify-between text-label">
            <button type="button" data-change-phone className="tap text-text-secondary underline">
              {t("codeChangePhone")}
            </button>
            <button
              type="button"
              data-resend
              disabled
              className="tap text-text-secondary underline disabled:no-underline disabled:opacity-60"
            >
              {t("codeResend")}
            </button>
          </div>
        </form>

        {/* 3. A name, once */}
        <form data-step="name" data-form="name" hidden className="flex flex-col gap-4" noValidate>
          <h2 className="pr-10 font-serif text-headline-m">{t("welcomeName")}</h2>
          <div className="flex flex-col gap-2">
            <label htmlFor="auth-name" className="text-label font-medium">
              {t("nameLabel")}
            </label>
            <input id="auth-name" name="display_name" autoComplete="name" maxLength={80} className={FIELD} />
            <p className="text-caption text-text-secondary">{t("nameHint")}</p>
          </div>
          <label className="flex items-start gap-3 text-label">
            <input type="checkbox" name="accept_terms" className="mt-1 size-5 accent-brand" />
            <span>
              {t("acceptTerms")} (
              <a href="/terms" className="underline">
                {brand}
              </a>
              )
            </span>
          </label>
          <button type="submit" className={cx(BUTTON, "w-full")}>
            {t("continueOn")}
          </button>
        </form>

        <p id="auth-error" role="alert" data-auth-error className="text-label text-error empty:hidden" />
      </div>
    </dialog>
  );
}

/** Who read a story: signed-in readers, newest first, and how many guests. Filled by the island. */
export function ReadersSheet({ t }: { t: T }) {
  return (
    <dialog
      id="readers-sheet"
      data-readers-sheet
      aria-labelledby="readers-title"
      data-say-guests={t("readersGuests", { n: "#" })}
      data-say-none={t("readersNone")}
      className="sheet m-0 mt-auto w-full max-w-none rounded-t-2xl bg-surface p-0 text-text-primary shadow-2xl backdrop:bg-black/50 sm:m-auto sm:max-w-md sm:rounded-2xl"
    >
      <div className="flex max-h-[80dvh] flex-col">
        <div className="flex items-center gap-3 border-border border-b px-5 py-3">
          <Users size={20} className="text-text-secondary" />
          <h2 id="readers-title" className="flex-1 font-serif text-headline-s">
            {t("readersTitle")}
          </h2>
          <button
            type="button"
            data-sheet-close
            aria-label={t("close")}
            className="tap grid w-11 place-items-center rounded-full text-text-secondary hover:bg-surface-sunken"
          >
            <X size={20} />
          </button>
        </div>
        <p data-readers-sum className="px-5 pt-3 text-caption text-text-secondary" />
        <ul data-readers-list className="flex-1 divide-y divide-border overflow-y-auto px-5 pb-5" />
        <template data-reader-row>
          <li className="flex items-center gap-3 py-3">
            <span
              data-initial
              className="grid size-9 shrink-0 place-items-center rounded-full bg-brand-soft font-semibold text-brand-text"
            />
            <span className="min-w-0 flex-1">
              <span data-name className="block truncate text-label font-medium" />
              <span data-handle className="block truncate text-caption text-text-secondary" />
            </span>
          </li>
        </template>
      </div>
    </dialog>
  );
}

/** Under the byline: how many times opened, and by how many people. The people open the list. */
export function StoryStats({ post, t }: { post: string; t: T }) {
  return (
    <p className="flex items-center gap-4 text-caption text-text-secondary" data-stats={post}>
      <span className="inline-flex items-center gap-1.5" data-say={t("viewsCount", { n: "#" })}>
        <Eye size={16} />
        <span data-n="views" className="tabular-nums">
          –
        </span>
        <span className="sr-only" data-said />
      </span>
      <button
        type="button"
        data-do-readers={post}
        data-say={t("readersCount", { n: "#" })}
        className="tap -my-3 inline-flex items-center gap-1.5 rounded-full px-2 hover:bg-surface-sunken hover:text-text-primary"
      >
        <Users size={16} />
        <span data-n="readers" className="tabular-nums">
          –
        </span>
        <span className="sr-only" data-said />
      </button>
    </p>
  );
}

/** The heart: optimistic, with its count; a guest is asked to sign in first, and the like is done after. */
export function LikeButton({ post, t, className }: { post: string; t: T; className: string }) {
  return (
    <button
      type="button"
      data-like={post}
      aria-pressed="false"
      aria-label={t("likeStory")}
      data-say={t("likesCount", { n: "#" })}
      data-intent={t("signInToLike")}
      className={cx(className, "like gap-1 aria-pressed:text-liked")}
    >
      <Heart size={21} className="like-heart" />
      <span data-n="likes" className="min-w-3 text-caption tabular-nums empty:hidden" />
    </button>
  );
}

export function CommentsButton({ t, className }: { t: T; className: string }) {
  return (
    <a href="#comments" className={cx(className, "gap-1")} aria-label={t("comments")}>
      <MessageCircle size={21} />
      <span data-n="comments" className="min-w-3 text-caption tabular-nums empty:hidden" />
    </a>
  );
}

/**
 * Comments, Instagram's way: newest first, replies one level under, a like for each, the writer marked. The first page
 * comes when the reader nears it, so a story's own page is never slower for its comments.
 */
export function Comments({ post, t, mode }: { post: string; t: T; mode: string }) {
  const closed = mode === "closed";
  return (
    <section
      id="comments"
      aria-labelledby="comments-title"
      data-comments={post}
      data-say-replies={t("commentReplies", { n: "#" })}
      data-say-reply-to={t("commentReplyTo", { name: "#" })}
      data-say-slow={t("commentSlow")}
      data-say-failed={t("commentFailed")}
      data-intent={t("signInToComment")}
      className="flex scroll-mt-36 flex-col gap-4 border-border border-t pt-6"
    >
      <h2 id="comments-title" className="flex items-baseline gap-2 font-serif text-headline-m">
        {t("comments")}
        <span data-n="comments" className="font-sans text-label text-text-secondary tabular-nums" />
      </h2>
      {closed ? (
        <p className="rounded-md bg-surface-sunken px-4 py-3 text-label text-text-secondary">
          {t("commentsClosed")}
        </p>
      ) : (
        <form data-comment-form className="flex items-end gap-2" noValidate>
          <span
            aria-hidden
            data-me-initial
            className="grid size-10 shrink-0 place-items-center rounded-full bg-surface-sunken font-semibold text-text-secondary"
          >
            ?
          </span>
          <div className="min-w-0 flex-1 rounded-2xl border border-border-strong bg-surface focus-within:border-text-primary">
            <p
              data-replying
              hidden
              className="flex items-center justify-between px-4 pt-2 text-caption text-text-secondary"
            >
              <span data-replying-to />
              <button type="button" data-cancel-reply aria-label={t("close")} className="tap -my-3 px-2">
                <X size={14} />
              </button>
            </p>
            <label htmlFor="comment-body" className="sr-only">
              {t("commentPlaceholder")}
            </label>
            <textarea
              id="comment-body"
              name="body"
              rows={1}
              maxLength={2000}
              placeholder={t("commentPlaceholder")}
              className="block max-h-40 min-h-11 w-full resize-none bg-transparent px-4 py-2.5 outline-none placeholder:text-text-tertiary"
            />
          </div>
          <button
            type="submit"
            aria-label={t("commentSend")}
            className="tap grid w-11 shrink-0 place-items-center rounded-full bg-brand text-on-brand hover:bg-brand-strong disabled:opacity-50"
          >
            <SendHorizontal size={18} />
          </button>
        </form>
      )}
      <p data-comments-none hidden className="py-6 text-center text-text-secondary">
        {t("commentsNone")}
      </p>
      <ol data-comment-list className="flex flex-col gap-5" />
      <button type="button" data-comments-more hidden className={cx(BUTTON, "self-center")}>
        {t("commentsMore")}
      </button>
      <template data-comment-row>
        <li className="comment flex gap-3">
          <span
            data-initial
            className="grid size-9 shrink-0 place-items-center rounded-full bg-brand-soft font-semibold text-brand-text"
          />
          <div className="min-w-0 flex-1">
            <p className="flex flex-wrap items-center gap-x-2 text-caption">
              <span data-name className="font-semibold text-label" />
              <span
                data-writer
                hidden
                className="rounded-sm bg-brand px-1.5 text-[11px] font-semibold text-on-brand uppercase"
              >
                {t("commentWriter")}
              </span>
              <time data-when className="text-text-secondary" />
              <span data-held hidden className="text-warning">
                · {t("commentHeld")}
              </span>
            </p>
            <p data-body className="whitespace-pre-line break-words" />
            <div className="flex items-center gap-4 text-caption text-text-secondary">
              <button
                type="button"
                data-comment-like
                aria-pressed="false"
                aria-label={t("likeStory")}
                className="tap -ml-2 inline-flex items-center gap-1 px-2 aria-pressed:text-liked"
              >
                <Heart size={15} />
                <span data-likes className="tabular-nums empty:hidden" />
              </button>
              <button type="button" data-comment-reply className="tap font-medium hover:text-text-primary">
                {t("commentReply")}
              </button>
              <button type="button" data-comment-delete hidden className="tap hover:text-error">
                {t("commentDelete")}
              </button>
            </div>
            <button
              type="button"
              data-comment-replies
              hidden
              className="tap text-caption font-medium text-text-secondary before:mr-2 before:inline-block before:h-px before:w-6 before:bg-border-strong before:align-middle hover:text-text-primary"
            />
            <ol data-replies className="mt-3 flex flex-col gap-4 empty:hidden" />
          </div>
        </li>
      </template>
    </section>
  );
}

/** On You: a guest is invited in; a reader sees their account. Which one is decided by the island. */
export function AccountCard({ t, brand }: { t: T; brand: string }) {
  return (
    <section aria-label={t("accountTitle")} data-account>
      <div
        data-guest
        className="flex flex-col items-start gap-3 rounded-lg border border-border bg-surface p-5"
      >
        <h2 className="font-serif text-headline-m">{t("joinTitle")}</h2>
        <p className="text-text-secondary">{t("joinPoints")}</p>
        <button type="button" data-auth-open data-intent={t("signInTitle")} className={BUTTON}>
          {t("signIn")}
        </button>
        <p className="sr-only">{brand}</p>
      </div>
      <div data-reader hidden className="flex flex-col gap-4 rounded-lg border border-border bg-surface p-5">
        <div className="flex items-center gap-4">
          <span
            data-me-initial
            className="grid size-16 shrink-0 place-items-center rounded-full bg-brand font-serif text-headline-l text-on-brand"
          />
          <div className="min-w-0 flex-1">
            <p data-me-name className="truncate font-serif text-headline-s" />
            <p data-me-handle className="truncate text-label text-text-secondary" />
            <p data-me-contact className="truncate text-caption text-text-secondary" />
          </div>
        </div>
        <form data-form="profile" className="flex flex-col gap-2" noValidate>
          <label htmlFor="me-name" className="text-label font-medium">
            {t("editName")}
          </label>
          <div className="flex gap-2">
            <input id="me-name" name="display_name" maxLength={80} className={FIELD} />
            <button type="submit" className={cx(BUTTON, "shrink-0")}>
              {t("saveChanges")}
            </button>
          </div>
        </form>
        <label className="flex items-center gap-3 text-label">
          <input type="checkbox" data-hide-readers className="size-5 accent-brand" />
          {t("readersPrivate")}
        </label>
        <div className="flex flex-wrap gap-2 border-border border-t pt-4">
          <button type="button" data-sign-out className={SECOND.replace("w-full", "w-auto")}>
            <LogOut size={18} />
            {t("signOut")}
          </button>
          <a href="/api/me/export" download className={SECOND.replace("w-full", "w-auto")}>
            <Download size={18} />
            {t("downloadData")}
          </a>
          <button
            type="button"
            data-delete-account
            data-confirm={t("deleteConfirm")}
            className={cx(SECOND.replace("w-full", "w-auto"), "text-error")}
          >
            <Trash2 size={18} />
            {t("deleteAccount")}
          </button>
        </div>
      </div>
    </section>
  );
}
