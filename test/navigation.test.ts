// Jekyll でビルドしたサイトを headless Chromium で開き、ナビのリンクをクリックしたときの動きを確認します。
// Chromium は Chrome DevTools Protocol で操作し、外部へのネットワークは遮断します。
import assert from "node:assert/strict";
import { execFileSync, spawn } from "node:child_process";
import { once } from "node:events";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { tmpdir } from "node:os";
import { extname, join } from "node:path";
import { createInterface } from "node:readline";
import { after, test } from "node:test";

const BASEURL = "/lorem-markdown-pages";
const PAGES = ["index.html", "document1.html", "document2.html"];
const CONTENT_TYPES: Record<string, string> = {
  ".css": "text/css",
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript",
  ".png": "image/png",
};

interface Message {
  id?: number;
  method?: string;
  sessionId?: string;
  result?: unknown;
  error?: { message: string };
}

class DevTools {
  readonly #socket: WebSocket;
  readonly #listeners = new Set<(message: Message) => void>();
  #lastId = 0;

  constructor(socket: WebSocket) {
    this.#socket = socket;
    socket.addEventListener("message", (event) => {
      const message = JSON.parse(String(event.data)) as Message;
      for (const listener of this.#listeners) {
        listener(message);
      }
    });
  }

  next(predicate: (message: Message) => boolean): Promise<Message> {
    return new Promise((resolve) => {
      const listener = (message: Message): void => {
        if (predicate(message)) {
          this.#listeners.delete(listener);
          resolve(message);
        }
      };
      this.#listeners.add(listener);
    });
  }

  async send<T>(method: string, params: object, sessionId?: string): Promise<T> {
    const id = ++this.#lastId;
    const reply = this.next((message) => message.id === id);
    this.#socket.send(JSON.stringify({ id, method, params, sessionId }));
    const { result, error } = await reply;
    if (error) {
      throw new Error(`${method}: ${error.message}`);
    }
    return result as T;
  }

  close(): void {
    this.#socket.close();
  }
}

const site = mkdtempSync(join(tmpdir(), "lorem-markdown-pages-site-"));
execFileSync("bundle", ["exec", "jekyll", "build", "--quiet", "--destination", site], { stdio: "inherit" });

const server = createServer((request, response) => {
  try {
    const path = decodeURIComponent(new URL(request.url ?? "/", "http://127.0.0.1").pathname);
    const body = readFileSync(join(site, path.slice(BASEURL.length)));
    response.writeHead(200, { "Content-Type": CONTENT_TYPES[extname(path)] ?? "application/octet-stream" });
    response.end(body);
  } catch {
    response.writeHead(404).end();
  }
});
server.listen(0, "127.0.0.1");
await once(server, "listening");
const origin = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;

const chromium = spawn(
  "chromium-headless-shell",
  ["--no-sandbox", "--remote-debugging-port=0", "--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE 127.0.0.1", "about:blank"],
  { stdio: ["ignore", "ignore", "pipe"] },
);
const endpoint = await new Promise<string>((resolve, reject) => {
  createInterface({ input: chromium.stderr }).on("line", (line) => {
    const match = /DevTools listening on (ws:\/\/\S+)/.exec(line);
    if (match?.[1]) {
      resolve(match[1]);
    }
  });
  chromium.once("exit", (code) => reject(new Error(`chromium-headless-shell exited with ${code}`)));
});
const socket = new WebSocket(endpoint);
await once(socket, "open");
const devtools = new DevTools(socket);

after(() => {
  devtools.close();
  // Chromium の子プロセスが stderr を開いたままにすることがあるため、パイプも閉じます。
  chromium.stderr.destroy();
  chromium.kill();
  server.closeAllConnections();
  server.close();
  rmSync(site, { recursive: true });
});

async function open(page: string): Promise<(expression: string) => Promise<unknown>> {
  const { targetId } = await devtools.send<{ targetId: string }>("Target.createTarget", { url: "about:blank" });
  const { sessionId } = await devtools.send<{ sessionId: string }>("Target.attachToTarget", { targetId, flatten: true });
  await devtools.send("Page.enable", {}, sessionId);
  const loaded = devtools.next((message) => message.method === "Page.loadEventFired" && message.sessionId === sessionId);
  await devtools.send("Page.navigate", { url: `${origin}${BASEURL}/${page}` }, sessionId);
  await loaded;

  return async (expression) => {
    const { result, exceptionDetails } = await devtools.send<{ result: { value: unknown }; exceptionDetails?: object }>(
      "Runtime.evaluate",
      { expression, awaitPromise: true, returnByValue: true },
      sessionId,
    );
    assert.equal(exceptionDetails, undefined, expression);
    return result.value;
  };
}

const ACTIVE_LINKS = `[...document.querySelectorAll("nav li.active a")].map((link) => link.getAttribute("href"))`;

for (const page of PAGES) {
  test(`${page}: clicking the last nav link scrolls to its heading and marks only that link active`, async () => {
    const evaluate = await open(page);
    const links = (await evaluate(`[...document.querySelectorAll("nav a")].map((link) => link.getAttribute("href"))`)) as string[];
    const last = links.at(-1);
    assert.ok(last, page);
    assert.deepEqual(await evaluate(ACTIVE_LINKS), [links[0]], page);

    await evaluate(`document.querySelectorAll("nav a")[${links.length - 1}].click()`);
    await evaluate(`new Promise((resolve) => $("html, body").promise().done(() => resolve()))`);

    assert.deepEqual(await evaluate(ACTIVE_LINKS), [last], page);
    assert.equal(await evaluate("location.hash"), "", `${page}: the default jump is prevented`);
    const { scrollY, expected } = (await evaluate(`(() => {
      const top = document.getElementById(${JSON.stringify(last.slice(1))}).getBoundingClientRect().top + scrollY;
      const max = document.documentElement.scrollHeight - innerHeight;
      return { scrollY, expected: Math.max(0, Math.min(top - 190, max)) };
    })()`)) as { scrollY: number; expected: number };
    assert.ok(Math.abs(scrollY - expected) <= 1, `${page}: scrollY ${scrollY}, expected ${expected}`);
  });
}
