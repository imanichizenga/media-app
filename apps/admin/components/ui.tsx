"use client";
import { CircleAlert, CircleCheck, CloudOff, Inbox, type LucideIcon, TriangleAlert, X } from "lucide-react";
import { useTranslations } from "next-intl";
import { Dialog as RadixDialog } from "radix-ui";
import { Children, type ComponentProps, createContext, type ReactNode, useContext, useId } from "react";
import { ApiError } from "@/lib/api";

export const cx = (...parts: (string | false | null | undefined)[]) => parts.filter(Boolean).join(" ");

/** Skeleton text: sits inside the real element, so it inherits its exact line height. */
export const Bone = ({ className = "w-24" }: { className?: string }) => (
  <span aria-hidden className={cx("bone", className)}>
    {" "}
  </span>
);

/** Holds a header button's place until permissions are known. */
export const ActionBone = ({ className = "w-28" }: { className?: string }) => (
  <span aria-hidden className={cx("tap bone", className)} />
);

/** Breaks after the @ when it must, never in the middle of a word it could keep whole. */
export function Email({ value }: { value: string }) {
  const at = value.indexOf("@") + 1;
  return (
    <>
      {value.slice(0, at)}
      <wbr />
      {value.slice(at)}
    </>
  );
}

const VARIANTS = {
  primary: "bg-accent text-on-accent hover:opacity-90",
  secondary: "bg-surface text-text-primary border border-border-strong hover:bg-surface-sunken",
  ghost: "text-text-secondary hover:bg-surface-sunken hover:text-text-primary",
  danger: "bg-danger text-on-danger hover:opacity-90",
};
export function Button({
  variant = "primary",
  pending = false,
  className,
  children,
  ...props
}: ComponentProps<"button"> & { variant?: keyof typeof VARIANTS; pending?: boolean }) {
  return (
    <button
      type="button"
      {...props}
      disabled={props.disabled || pending}
      aria-busy={pending || undefined}
      className={cx(
        "tap inline-flex items-center justify-center gap-2 rounded-sm px-4 text-label transition-colors disabled:cursor-not-allowed disabled:opacity-60",
        VARIANTS[variant],
        className,
      )}
    >
      {pending && <span aria-hidden className="size-2 rounded-full bg-current motion-safe:animate-pulse" />}
      {children}
    </button>
  );
}

const CONTROL =
  "tap w-full rounded-sm border border-border-strong bg-surface px-3 text-body-m text-text-primary placeholder:text-text-tertiary disabled:opacity-60 aria-invalid:border-danger";

export function Field({
  label,
  help,
  error,
  children,
}: {
  label: string;
  help?: string;
  error?: string;
  children: (props: {
    id: string;
    "aria-describedby"?: string;
    "aria-invalid"?: true;
    className: string;
  }) => ReactNode;
}) {
  const id = useId();
  const describedBy = error ? `${id}-error` : help ? `${id}-help` : undefined;
  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={id} className="text-label">
        {label}
      </label>
      {children({
        id,
        className: CONTROL,
        ...(describedBy ? { "aria-describedby": describedBy } : {}),
        ...(error ? { "aria-invalid": true as const } : {}),
      })}
      {error ? (
        <p id={`${id}-error`} className="text-caption text-danger">
          {error}
        </p>
      ) : help ? (
        <p id={`${id}-help`} className="text-caption text-text-secondary">
          {help}
        </p>
      ) : null}
    </div>
  );
}

export const TextField = ({
  label,
  help,
  error,
  ...props
}: Omit<ComponentProps<"input">, "id"> & { label: string; help?: string; error?: string }) => (
  <Field label={label} help={help} error={error}>
    {(control) => <input {...props} {...control} />}
  </Field>
);

const TONES = {
  neutral: "bg-surface-sunken text-text-secondary",
  success: "bg-success-soft text-success",
  warning: "bg-warning-soft text-warning",
  danger: "bg-danger-soft text-danger",
  accent: "bg-accent-soft text-accent",
};
export type Tone = keyof typeof TONES;
export const Badge = ({ tone = "neutral", children }: { tone?: Tone; children: ReactNode }) => (
  <span
    className={cx(
      "inline-flex items-center gap-1 rounded-sm px-2 text-caption font-medium whitespace-nowrap",
      TONES[tone],
    )}
  >
    {children}
  </span>
);

export const Card = ({ className, ...props }: ComponentProps<"section">) => (
  <section {...props} className={cx("rounded-md border border-border bg-surface p-5", className)} />
);

export const PageHeader = ({
  title,
  lead,
  actions,
}: {
  title: ReactNode;
  lead?: ReactNode;
  actions?: ReactNode;
}) => (
  <header className="mb-6 flex flex-wrap items-end justify-between gap-4">
    <div>
      <h1 className="text-headline-m">{title}</h1>
      {lead && <p className="max-w-prose text-text-secondary">{lead}</p>}
    </div>
    {actions && <div className="flex flex-wrap gap-2">{actions}</div>}
  </header>
);

function Message({
  icon: Icon,
  title,
  body,
  action,
}: {
  icon: LucideIcon;
  title: string;
  body?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center gap-3 px-6 py-12 text-center">
      <span className="grid size-16 place-items-center rounded-full bg-accent-soft text-accent">
        <Icon aria-hidden size={28} />
      </span>
      <p className="text-title">{title}</p>
      {body && <p className="max-w-sm text-text-secondary">{body}</p>}
      {action}
    </div>
  );
}
export const Empty = ({ title, body, action }: { title: string; body?: string; action?: ReactNode }) => (
  <Message icon={Inbox} title={title} body={body} action={action} />
);

export function useErrorText() {
  const t = useTranslations("errors");
  return (error: unknown) => {
    if (!(error instanceof ApiError)) return t("unavailable");
    if (error.code === "rate_limited")
      return t("rate_limited", { seconds: Number(error.extra.retry_after ?? 60) });
    return t.has(error.code as never)
      ? t(error.code as never)
      : error.status >= 500
        ? t("unavailable")
        : error.detail || t("unavailable");
  };
}

export function ErrorState({ error, retry }: { error: unknown; retry?: () => void }) {
  const t = useTranslations("common");
  const text = useErrorText();
  const offline = error instanceof ApiError && error.code === "offline";
  return (
    <Message
      icon={offline ? CloudOff : CircleAlert}
      title={text(error)}
      action={
        retry && (
          <Button variant="secondary" onClick={retry}>
            {t("retry")}
          </Button>
        )
      }
    />
  );
}

export function Notice({ tone, children }: { tone: "success" | "warning" | "danger"; children: ReactNode }) {
  const Icon = { success: CircleCheck, warning: TriangleAlert, danger: CircleAlert }[tone];
  return (
    <div
      role={tone === "danger" ? "alert" : "status"}
      className={cx("flex gap-3 rounded-sm p-3", TONES[tone])}
    >
      <Icon aria-hidden size={20} className="mt-0.5 shrink-0" />
      <div className="min-w-0 break-words">{children}</div>
    </div>
  );
}
export function FormError({ error }: { error: unknown }) {
  const text = useErrorText();
  return error ? <Notice tone="danger">{text(error)}</Notice> : null;
}

export function Dialog({
  open,
  onClose,
  title,
  description,
  children,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  description?: string;
  children: ReactNode;
}) {
  const t = useTranslations("common");
  return (
    <RadixDialog.Root open={open} onOpenChange={(next) => !next && onClose()}>
      <RadixDialog.Portal>
        <RadixDialog.Overlay className="fixed inset-0 z-40 bg-black/50" />
        <RadixDialog.Content
          {...(description ? {} : { "aria-describedby": undefined })}
          className="fixed inset-x-0 bottom-0 z-50 max-h-[90dvh] overflow-y-auto rounded-t-lg border border-border bg-surface-raised p-6 sm:inset-auto sm:top-1/2 sm:left-1/2 sm:w-full sm:max-w-lg sm:-translate-x-1/2 sm:-translate-y-1/2 sm:rounded-lg"
        >
          <div className="mb-4 flex items-start justify-between gap-4">
            <div>
              <RadixDialog.Title className="text-headline-s">{title}</RadixDialog.Title>
              {description && (
                <RadixDialog.Description className="text-text-secondary">
                  {description}
                </RadixDialog.Description>
              )}
            </div>
            <RadixDialog.Close
              aria-label={t("close")}
              className="tap -m-2 grid w-11 place-items-center rounded-sm hover:bg-surface-sunken"
            >
              <X aria-hidden size={20} />
            </RadixDialog.Close>
          </div>
          {children}
        </RadixDialog.Content>
      </RadixDialog.Portal>
    </RadixDialog.Root>
  );
}

const Head = createContext<string[]>([]);
const CellLabel = createContext("");
/** Tables on wide screens; on phones each row is a card of label and value, so nothing is cut off. */
export function Table({ head, label, children }: { head: string[]; label: string; children: ReactNode }) {
  return (
    <section
      aria-label={label}
      // biome-ignore lint/a11y/noNoninteractiveTabindex: a scrollable region must be reachable by keyboard
      tabIndex={0}
      className="relative overflow-x-auto rounded-md border border-border bg-surface"
    >
      {/* Roles are explicit because display:block removes the table's own. */}
      {/* biome-ignore lint/a11y/noRedundantRoles: see above */}
      <table role="table" className="w-full text-left text-label max-md:block">
        <thead className="border-b border-border text-text-secondary max-md:sr-only">
          <tr>
            {head.map((h, i) => (
              <th key={h || i} scope="col" className="px-4 py-3 font-medium whitespace-nowrap">
                {h || <span className="sr-only">·</span>}
              </th>
            ))}
          </tr>
        </thead>
        {/* biome-ignore lint/a11y/noRedundantRoles: see above */}
        <tbody role="rowgroup" className="divide-y divide-border max-md:block">
          <Head value={head}>{children}</Head>
        </tbody>
      </table>
    </section>
  );
}
export function Td({ className, children, ...props }: ComponentProps<"td">) {
  const label = useContext(CellLabel);
  return (
    <td
      // biome-ignore lint/a11y/noRedundantRoles: display changes on phones
      role="cell"
      {...props}
      className={cx(
        "px-4 py-3 align-top max-md:flex max-md:items-baseline max-md:gap-4 max-md:px-4 max-md:py-1",
        className,
      )}
    >
      {label && (
        <span aria-hidden className="w-28 shrink-0 text-caption text-text-secondary md:hidden">
          {label}
        </span>
      )}
      <div className="min-w-0 break-words max-md:flex-1">{children}</div>
    </td>
  );
}
export function Row({ children, ...props }: ComponentProps<"tr">) {
  const head = useContext(Head);
  return (
    <tr
      // biome-ignore lint/a11y/noRedundantRoles: display changes on phones
      role="row"
      {...props}
      className="max-md:block max-md:py-2"
    >
      {Children.toArray(children).map((cell, i) => (
        // biome-ignore lint/suspicious/noArrayIndexKey: columns never move
        <CellLabel key={i} value={head[i] ?? ""}>
          {cell}
        </CellLabel>
      ))}
    </tr>
  );
}
/** `action`: the last column holds a button, which sets the row height. */
export const BoneRows = ({
  widths,
  rows = 8,
  action = false,
}: {
  widths: string[];
  rows?: number;
  action?: boolean;
}) =>
  Array.from({ length: rows }, (_, r) => (
    // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
    <Row key={r} data-skeleton="row">
      {widths.map((w, c) => (
        // biome-ignore lint/suspicious/noArrayIndexKey: static placeholders
        <Td key={c}>
          {action && c === widths.length - 1 ? (
            <span aria-hidden className={cx("tap bone", w)} />
          ) : (
            <Bone className={w} />
          )}
        </Td>
      ))}
    </Row>
  ));
