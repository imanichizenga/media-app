import type { NextConfig } from "next";

const security = [
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
  { key: "X-Frame-Options", value: "DENY" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
  },
];
const api = process.env.API_PROXY_TARGET;

const config: NextConfig = {
  output: "standalone",
  poweredByHeader: false,
  cacheHandler: require.resolve("./cache-handler.mjs"),
  cacheMaxMemorySize: 0,
  outputFileTracingIncludes: { "/og/*/*": ["./fonts/*.woff"] },
  reactStrictMode: true,
  // Files under the media CDN are already every size: nothing is resized here.
  // Titles and descriptions are in the head of every document, for every reader.
  htmlLimitedBots: /.*/,
  images: { unoptimized: true },
  transpilePackages: ["@news/api-client", "@news/content-schema", "@news/i18n", "@news/ui"],
  headers: async () => [
    { source: "/(.*)", headers: security },
    // The content is in the name.
    { source: "/js/(.*)", headers: [{ key: "Cache-Control", value: "public, max-age=31536000, immutable" }] },
  ],
  // Local and E2E only. In AWS the load balancer and the CDN route these on the same origin.
  rewrites: async () => ({
    beforeFiles: [],
    afterFiles: api
      ? [
          { source: "/theme/:path+", destination: `${api}/theme/:path+` },
          { source: "/media/:path+", destination: `${api}/media/:path+` },
        ]
      : [],
    fallback: [],
  }),
};

export default config;
