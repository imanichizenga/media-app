/** Reads a one-time token from the URL fragment, then removes it from the address bar and history. */
export function takeFragment(): string {
  const token = location.hash.slice(1);
  if (token) history.replaceState(null, "", location.pathname);
  return token;
}
