import { manage, sql } from "./helpers";

export default function setup() {
  sql("DROP DATABASE IF EXISTS news_e2e WITH (FORCE)", "postgres");
  sql("CREATE DATABASE news_e2e", "postgres");
  manage("migrate", "-v0");
  manage("shell", "-v0", "-c", "from newsplatform.common.redis import cache; cache().flushdb()");
}
