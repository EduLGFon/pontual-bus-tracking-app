// T12 hub tests: AC06 socket behaviors (caps, heartbeat, backpressure,
// bye) at the unit level with fake sockets. Live upgrade path is verified
// on staging per S2 close-out.
import { assert, assertEquals } from "@std/assert";
import { Hub, type HubSocket, OPEN } from "../src/ws/hub.ts";

function fakeSocket(
  over: Partial<HubSocket> = {},
): HubSocket & { sent: string[]; closed: number | null } {
  return {
    sent: [],
    closed: null,
    readyState: OPEN,
    bufferedAmount: 0,
    send(data: string) {
      (this as unknown as { sent: string[] }).sent.push(data);
    },
    close(code?: number) {
      (this as unknown as { closed: number | null }).closed = code ?? 1000;
    },
    ...over,
  };
}

Deno.test("AC06: caps refuse over global and per-IP limits", () => {
  const hub = new Hub({
    maxConnections: 2,
    maxPerIp: 1,
    maxMsgPerMin: 10,
    maxMsgBytes: 128,
  });
  assert(hub.connect(fakeSocket(), "1.1.1.1"));
  assertEquals(hub.connect(fakeSocket(), "1.1.1.1"), null);
  assert(hub.connect(fakeSocket(), "2.2.2.2"));
  assertEquals(hub.connect(fakeSocket(), "3.3.3.3"), null);
});

Deno.test("AC06: sub and unsub manage subscription", () => {
  const hub = new Hub();
  const sock = fakeSocket();
  const conn = hub.connect(sock, "1.1.1.1")!;
  const reply = hub.onMessage(
    conn,
    JSON.stringify({ op: "sub", line: 7 }),
    0,
    () => "SNAP",
  );
  assertEquals(reply, "SNAP");
  assertEquals(conn.lineId, 7);
  assertEquals(
    hub.onMessage(conn, JSON.stringify({ op: "unsub" }), 1000, () => "SNAP"),
    null,
  );
  assertEquals(conn.lineId, null);
});

Deno.test("AC06: oversized, unknown op, and bad JSON close the socket", () => {
  const hub = new Hub();
  for (
    const raw of ["x".repeat(129), JSON.stringify({ op: "nuke" }), "{nope"]
  ) {
    const sock = fakeSocket();
    const conn = hub.connect(sock, "9.9.9.9")!;
    assertEquals(hub.onMessage(conn, raw, 0, () => null), null);
    assert(sock.closed !== null);
    assertEquals(hub.size, 0);
  }
});

Deno.test("AC06: more than 10 messages per minute closes the socket", () => {
  const hub = new Hub();
  const sock = fakeSocket();
  const conn = hub.connect(sock, "5.5.5.5")!;
  for (let i = 0; i < 10; i++) {
    hub.onMessage(conn, JSON.stringify({ op: "unsub" }), i * 1000, () => null);
  }
  assertEquals(
    hub.onMessage(conn, JSON.stringify({ op: "unsub" }), 11000, () => null),
    null,
  );
  assert(sock.closed !== null);
});

Deno.test("broadcast reaches subscribers and skips pressured sockets", () => {
  const hub = new Hub();
  const a = fakeSocket();
  const b = fakeSocket();
  const pressured = fakeSocket({ bufferedAmount: 300 * 1024 });
  const ca = hub.connect(a, "1.1.1.1")!;
  const cb = hub.connect(b, "2.2.2.2")!;
  const cp = hub.connect(pressured, "3.3.3.3")!;
  hub.onMessage(ca, JSON.stringify({ op: "sub", line: 7 }), 0, () => null);
  hub.onMessage(cb, JSON.stringify({ op: "sub", line: 9 }), 0, () => null);
  hub.onMessage(cp, JSON.stringify({ op: "sub", line: 7 }), 0, () => null);
  hub.broadcast(7, "PING7");
  assertEquals(a.sent, ["PING7"]);
  assertEquals(b.sent, []);
  assertEquals(pressured.sent, []);
});

Deno.test("heartbeat and bye reach open sockets", () => {
  const hub = new Hub();
  const sock = fakeSocket();
  hub.connect(sock, "1.1.1.1");
  hub.heartbeat(123);
  assertEquals(sock.sent, [JSON.stringify({ hb: 123 })]);
  hub.closeAll();
  assert(sock.sent[1].includes("restart"));
  assertEquals(sock.closed, 1012);
  assertEquals(hub.size, 0);
});
