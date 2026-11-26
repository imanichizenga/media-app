import { manage, sql } from "./helpers";

export default function setup() {
  sql("DROP DATABASE IF EXISTS news_e2e WITH (FORCE)", "postgres");
  sql("CREATE DATABASE news_e2e", "postgres");
  manage("migrate", "-v0");
  manage("shell", "-v0", "-c", "from newsplatform.common.redis import cache; cache().flushdb()");
  const [posts, images, videos] =
    process.env.SCREENS && process.env.SCREENS !== "m2-themes" ? [300, 28, 6] : [40, 10, 2];
  manage("seed_demo", `--posts=${posts}`, `--images=${images}`, `--videos=${videos}`);
}
