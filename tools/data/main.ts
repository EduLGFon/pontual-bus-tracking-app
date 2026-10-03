// Static data validator and builder. The repo is the source of truth:
// humans edit data/lines/*.json, this tool validates and builds the
// deployed bundle. See PLAN.md section 7.
// Run: deno task data-validate | data-build (from tools/).

const ROOT = new URL("../../", import.meta.url);
const LINES_DIR = new URL("data/lines/", ROOT);
const SCHEMA_URL = new URL("data/schema/line.schema.json", ROOT);
const BUILD_DIR = new URL("build/", ROOT);
const SIZE_BUDGET = 100 * 1024;

export interface LineFile {
  path: string;
  data: Record<string, unknown>;
  bytes: number;
}

export async function readLineFiles(): Promise<LineFile[]> {
  const schema = JSON.parse(await Deno.readTextFile(SCHEMA_URL));
  const out: LineFile[] = [];
  for await (const entry of Deno.readDir(LINES_DIR)) {
    if (!entry.isFile || !entry.name.endsWith(".json")) continue;
    const url = new URL(entry.name, LINES_DIR);
    const text = await Deno.readTextFile(url);
    const bytes = new TextEncoder().encode(text).length;
    let data: unknown;
    try {
      data = JSON.parse(text);
    } catch {
      throw new Error(`${entry.name}: invalid JSON`);
    }
    checkStructure(entry.name, schema, data);
    out.push({
      path: entry.name,
      data: data as Record<string, unknown>,
      bytes,
    });
  }
  return out;
}

/** Structural check driven by the JSON Schema file (subset interpreter). */
export function checkStructure(
  name: string,
  schema: Schema,
  data: unknown,
): void {
  const fail = (why: string): never => {
    throw new Error(`${name}: ${why}`);
  };
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    fail("root must be an object");
  }
  const obj = data as Record<string, unknown>;
  for (const key of schema.required ?? []) {
    if (!(key in obj)) fail(`missing required key ${key}`);
  }
  if (schema.additionalProperties === false) {
    for (const key of Object.keys(obj)) {
      if (!(key in (schema.properties ?? {}))) fail(`unknown key ${key}`);
    }
  }
  for (const [key, prop] of Object.entries(schema.properties ?? {})) {
    if (!(key in obj)) continue;
    checkValue(`${key}`, prop, obj[key], fail);
  }
}

interface Schema {
  required?: string[];
  additionalProperties?: boolean;
  properties?: Record<string, Prop>;
}

interface Prop {
  type?: string | string[];
  const?: unknown;
  enum?: unknown[];
  pattern?: string;
  minimum?: number;
  maximum?: number;
  minLength?: number;
  maxLength?: number;
  minItems?: number;
  items?: Prop | { type: string };
}

function checkValue(
  path: string,
  prop: Prop,
  value: unknown,
  fail: (why: string) => never,
): void {
  if (prop.const !== undefined && value !== prop.const) {
    fail(`${path} must be ${JSON.stringify(prop.const)}`);
  }
  if (prop.enum && !prop.enum.includes(value)) {
    fail(`${path} has a bad enum value`);
  }
  const types = Array.isArray(prop.type)
    ? prop.type
    : prop.type
    ? [prop.type]
    : [];
  if (types.length > 0) {
    const ok = types.some((t) =>
      jsType(value) === t || (t === "integer" && isInt(value))
    );
    if (!ok) fail(`${path} has a bad type`);
  }
  if (typeof value === "string") {
    if (prop.minLength !== undefined && value.length < prop.minLength) {
      fail(`${path} is too short`);
    }
    if (prop.maxLength !== undefined && value.length > prop.maxLength) {
      fail(`${path} is too long`);
    }
    if (prop.pattern && !new RegExp(prop.pattern).test(value)) {
      fail(`${path} does not match ${prop.pattern}`);
    }
  }
  if (typeof value === "number") {
    if (prop.minimum !== undefined && value < prop.minimum) {
      fail(`${path} is too small`);
    }
    if (prop.maximum !== undefined && value > prop.maximum) {
      fail(`${path} is too large`);
    }
  }
  if (
    Array.isArray(value) && prop.minItems !== undefined &&
    value.length < prop.minItems
  ) {
    fail(`${path} needs more items`);
  }
}

function jsType(value: unknown): string {
  if (value === null) return "null";
  if (Array.isArray(value)) return "array";
  return typeof value;
}

function isInt(value: unknown): boolean {
  return typeof value === "number" && Number.isInteger(value);
}

/** Semantic checks: uniqueness, sorted times, size budget. */
export function checkSemantics(files: LineFile[]): void {
  const ids = new Set<unknown>();
  const codes = new Set<unknown>();
  const shorts = new Set<unknown>();
  let total = 0;
  for (const f of files) {
    total += f.bytes;
    const d = f.data;
    for (
      const [key, set] of [["id", ids], ["code", codes], [
        "short",
        shorts,
      ]] as const
    ) {
      if (set.has(d[key])) {
        throw new Error(`${f.path}: duplicate ${key} ${String(d[key])}`);
      }
      set.add(d[key]);
    }
    for (const s of (d["schedules"] as Record<string, unknown>[])) {
      const keys = Object.keys(s).sort();
      if (JSON.stringify(keys) !== '["day_type","origin","times"]') {
        throw new Error(`${f.path}: bad schedule keys ${keys.join(",")}`);
      }
      if (
        !["weekday", "saturday", "sunday_holiday"].includes(
          s["day_type"] as string,
        )
      ) {
        throw new Error(`${f.path}: bad day_type ${String(s["day_type"])}`);
      }
      const times = s["times"] as string[];
      for (const t of times) {
        if (!/^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(t)) {
          throw new Error(`${f.path}: bad time ${t}`);
        }
      }
      const sorted = [...times].sort();
      if (times.some((t, i) => t !== sorted[i])) {
        throw new Error(`${f.path}: unsorted times for ${String(s["origin"])}`);
      }
      if (new Set(times).size !== times.length) {
        throw new Error(
          `${f.path}: duplicate times for ${String(s["origin"])}`,
        );
      }
    }
  }
  if (total > SIZE_BUDGET) {
    throw new Error(`lines exceed size budget: ${total} > ${SIZE_BUDGET}`);
  }
}

async function sha12(text: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text),
  );
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0"))
    .join("").slice(0, 12);
}

/** Build the deployed bundle into build/. Returns the manifest. */
export async function buildBundle(
  files: LineFile[],
): Promise<Record<string, unknown>> {
  const lines = files.map((f) => f.data).sort((a, b) =>
    Number(a["id"]) - Number(b["id"])
  );
  const linesText = JSON.stringify(lines);
  const linesHash = await sha12(linesText);
  const linesName = `lines.${linesHash}.json`;

  await Deno.mkdir(BUILD_DIR, { recursive: true });
  await Deno.writeTextFile(new URL(linesName, BUILD_DIR), linesText);

  const manifest = {
    data_version: linesHash,
    lines: linesName,
    routes: {},
    generated_at: new Date().toISOString(),
  };
  await Deno.writeTextFile(
    new URL("manifest.json", BUILD_DIR),
    JSON.stringify(manifest, null, 2),
  );

  const config = {
    min_app_version: "0.1.0",
    maintenance: false,
    message_pt: "",
    consent_version: 1,
    tile_url: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
  };
  await Deno.writeTextFile(
    new URL("config.json", BUILD_DIR),
    JSON.stringify(config, null, 2),
  );
  return manifest;
}

if (import.meta.main) {
  const cmd = Deno.args[0];
  const files = await readLineFiles();
  checkSemantics(files);
  if (cmd === "validate") {
    console.log(`valid: ${files.length} line files`);
  } else if (cmd === "build") {
    const manifest = await buildBundle(files);
    console.log(`built: ${JSON.stringify(manifest)}`);
  } else {
    console.error("usage: main.ts validate|build");
    Deno.exit(2);
  }
}
