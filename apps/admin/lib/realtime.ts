import { call, client } from "./api";

type Listener = () => void;
type Deps = {
  open: () => WebSocket;
  ticket: () => Promise<string>;
  random: () => number;
};
/** The server says the session is over or lacks rights. Retrying cannot help; REST reports it to the person. */
const FINAL = new Set([4401, 4403]);
const IDLE_MS = 5_000;

/**
 * One socket for the whole console, open only while something is watched. Messages say *what* changed, never the
 * data: listeners refetch through REST. Losing the socket only makes pages slower, because they also poll.
 */
export class Realtime {
  private socket: WebSocket | null = null;
  private ready = false;
  private attempts = 0;
  private timer: ReturnType<typeof setTimeout> | undefined;
  private readonly topics = new Map<string, Set<Listener>>();
  private readonly watchers = new Set<Listener>();

  constructor(private readonly deps: Deps) {}

  get connected() {
    return this.ready;
  }
  onStatus(listener: Listener) {
    this.watchers.add(listener);
    return () => this.watchers.delete(listener);
  }

  subscribe(topic: string, listener: Listener): () => void {
    const listeners = this.topics.get(topic) ?? new Set();
    listeners.add(listener);
    if (!this.topics.has(topic)) {
      this.topics.set(topic, listeners);
      if (this.ready) this.send({ type: "subscribe", topic });
    }
    clearTimeout(this.idle);
    this.connect();
    return () => {
      listeners.delete(listener);
      if (listeners.size > 0 || !this.topics.delete(topic)) return;
      if (this.ready) this.send({ type: "unsubscribe", topic });
      // Moving between pages should not reconnect each time.
      if (this.topics.size === 0) this.idle = setTimeout(() => this.disconnect(), IDLE_MS);
    };
  }
  private idle: ReturnType<typeof setTimeout> | undefined;

  private connect() {
    if (this.socket || this.timer) return;
    let socket: WebSocket;
    try {
      socket = this.deps.open();
    } catch {
      return this.retry();
    }
    this.socket = socket;
    socket.onopen = async () => {
      try {
        const ticket = await this.deps.ticket();
        if (this.socket === socket) this.send({ type: "auth", ticket });
      } catch {
        socket.close();
      }
    };
    socket.onmessage = (event) => this.receive(String(event.data));
    socket.onclose = (event) => {
      if (this.socket !== socket) return;
      this.socket = null;
      this.setReady(false);
      if (!FINAL.has(event.code) && this.topics.size > 0) this.retry();
    };
  }

  private disconnect() {
    clearTimeout(this.timer);
    this.timer = undefined;
    const socket = this.socket;
    this.socket = null;
    socket?.close();
    this.setReady(false);
  }

  private retry() {
    const ceiling = Math.min(30_000, 1_000 * 2 ** this.attempts++);
    // Full jitter: a restart must not bring every console back in the same second.
    this.timer = setTimeout(
      () => {
        this.timer = undefined;
        if (this.topics.size > 0) this.connect();
      },
      ceiling / 2 + (this.deps.random() * ceiling) / 2,
    );
  }

  private receive(raw: string) {
    let message: { type?: string; topic?: string };
    try {
      message = JSON.parse(raw);
    } catch {
      return;
    }
    if (message.type === "ready") {
      this.attempts = 0;
      this.setReady(true);
      for (const topic of this.topics.keys()) this.send({ type: "subscribe", topic });
    } else if (message.topic && (message.type === "changed" || message.type === "subscribed")) {
      for (const listener of this.topics.get(message.topic) ?? []) listener();
    }
  }

  private send(message: object) {
    this.socket?.send(JSON.stringify(message));
  }
  private setReady(ready: boolean) {
    if (this.ready === ready) return;
    this.ready = ready;
    for (const watcher of this.watchers) watcher();
  }
}

export const realtime = new Realtime({
  open: () =>
    new WebSocket(`${location.protocol === "https:" ? "wss" : "ws"}://${location.host}/ws/v1/staff`),
  ticket: async () => (await call(() => client.POST("/api/v1/realtime/ticket"))).ticket,
  random: Math.random,
});
