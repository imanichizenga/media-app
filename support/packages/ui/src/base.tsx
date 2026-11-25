/** Plain pieces, usable on the server: nothing here reaches the browser as script. */

export const cx = (...parts: (string | false | null | undefined)[]) => parts.filter(Boolean).join(" ");

/** Skeleton text: sits inside the real element, so it inherits its exact line height. */
export const Bone = ({ className = "w-24" }: { className?: string }) => (
  <span aria-hidden className={cx("bone", className)}>
    {" "}
  </span>
);
