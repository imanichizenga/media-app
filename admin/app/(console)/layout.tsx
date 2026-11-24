import type { ReactNode } from "react";
import { UploadsProvider } from "@/components/media/uploads";
import { Shell } from "@/components/shell";

export default function ConsoleLayout({ children }: { children: ReactNode }) {
  return (
    <UploadsProvider>
      <Shell>{children}</Shell>
    </UploadsProvider>
  );
}
