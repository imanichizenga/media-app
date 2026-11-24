import type { ReactNode } from "react";

export const AuthShell = ({
  title,
  lead,
  children,
}: {
  title: string;
  lead?: string;
  children: ReactNode;
}) => (
  <main className="grid min-h-dvh place-items-center px-4 py-12">
    <div className="w-full max-w-sm">
      <h1 className="text-headline-l">{title}</h1>
      {lead && <p className="mt-2 text-text-secondary">{lead}</p>}
      <div className="mt-8">{children}</div>
    </div>
  </main>
);
