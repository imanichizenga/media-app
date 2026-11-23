"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { setNonce } from "get-nonce";
import { type ReactNode, useEffect, useState } from "react";
import { ApiError } from "@/lib/api";
import { drain } from "@/lib/early-errors";

type Props = { nonce: string; monitoring: boolean; children: ReactNode };
export function Providers({ nonce, monitoring, children }: Props) {
  useEffect(() => {
    // Loaded after the page works, so reporting costs nothing at start.
    if (!monitoring) drain();
    else import("@/lib/monitoring").then(({ start }) => start(drain())).catch(() => {});
  }, [monitoring]);
  const [queries] = useState(() => {
    if (nonce) setNonce(nonce); // the scroll lock in dialogs injects one style element
    return new QueryClient({
      defaultOptions: {
        queries: {
          staleTime: 15_000,
          retry: (count, error) =>
            count < 2 && (!(error instanceof ApiError) || error.status >= 500 || error.status === 0),
        },
      },
    });
  });
  return <QueryClientProvider client={queries}>{children}</QueryClientProvider>;
}
