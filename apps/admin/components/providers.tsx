"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { setNonce } from "get-nonce";
import { type ReactNode, useState } from "react";
import { ApiError } from "@/lib/api";

export function Providers({ nonce, children }: { nonce: string; children: ReactNode }) {
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
