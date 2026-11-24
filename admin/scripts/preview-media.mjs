// The Appearance preview shows seed stories; their pictures live with the screens.
import { cpSync, rmSync } from "node:fs";

const root = new URL("..", import.meta.url).pathname;
rmSync(`${root}public/preview-media`, { recursive: true, force: true });
cpSync(`${root}../support/packages/screens/media`, `${root}public/preview-media/media`, { recursive: true });
