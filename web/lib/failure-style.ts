/** The failure page's own look, fixed: the policy allows exactly this text by its hash (lib/csp.ts). */
export const STYLE = `
:root{color-scheme:light dark}
body{margin:0;min-height:100dvh;display:grid;place-items:center;padding:16px;text-align:center;font:17px/1.6 system-ui,sans-serif;background:var(--color-bg,Canvas);color:var(--color-text-primary,CanvasText)}
svg{width:128px;height:128px}h1{font:600 26px/1.25 Georgia,serif;margin:16px 0 8px}p{margin:0 auto 24px;max-width:24rem}
a{display:inline-flex;align-items:center;min-height:44px;padding:0 20px;margin:4px;border-radius:8px;color:inherit}
a.go{background:var(--color-brand,#b5121b);color:var(--color-on-brand,#fff);text-decoration:none}
`;
