import type { NextConfig } from "next";
import createNextIntlPlugin from "next-intl/plugin";

const security = [
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "no-referrer" },
  { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
  { key: "Cross-Origin-Resource-Policy", value: "same-origin" },
  {
    key: "Permissions-Policy",
    value:
      "camera=(), microphone=(), geolocation=(), payment=(), usb=(), publickey-credentials-get=(self), publickey-credentials-create=(self)",
  },
  { key: "X-Robots-Tag", value: "noindex, nofollow" },
];
const api = process.env.API_PROXY_TARGET;
const realtime = process.env.REALTIME_PROXY_TARGET;

const config: NextConfig = {
  output: "standalone",
  poweredByHeader: false,
  reactStrictMode: true,
  transpilePackages: ["@news/api-client", "@news/content-schema", "@news/ui"],
  headers: async () => [{ source: "/(.*)", headers: security }],
  // Local and E2E only. In AWS the load balancer routes /api and /ws on the same origin.
  rewrites: async () => [
    ...(api ? [{ source: "/api/v1/:path*", destination: `${api}/api/v1/:path*` }] : []),
    ...(realtime ? [{ source: "/ws/v1/:path*", destination: `${realtime}/ws/v1/:path*` }] : []),
  ],
};

export default createNextIntlPlugin("./lib/i18n.ts")(config);
