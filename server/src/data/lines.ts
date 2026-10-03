// Line resolver. Production data comes from the built static bundle in
// DATA_DIR (T14 builds it); until then the file loader yields an empty
// registry and unknown lines return 404. Tests inject a fake resolver.
// Line ids are stable and never reused; removal means is_active false.
export interface LineRecord {
  id: number;
  isActive: boolean;
  route: { lat: number; lng: number }[] | null;
}

export type LineResolver = (id: number) => LineRecord | null;

/** Registry resolver for tests and early wiring. */
export function registryResolver(lines: LineRecord[]): LineResolver {
  const byId = new Map(lines.map((l) => [l.id, l]));
  return (id: number) => byId.get(id) ?? null;
}

/**
 * Load the built bundle from DATA_DIR (manifest plus lines file).
 * Returns an empty list when the bundle is absent; the T14 builder creates
 * it and T17 adds route geometry. Throws on corrupt bundles.
 */
export async function loadLinesFromDir(dataDir: string): Promise<LineRecord[]> {
  let manifestText: string;
  try {
    manifestText = await Deno.readTextFile(`${dataDir}/manifest.json`);
  } catch {
    return [];
  }
  const manifest = JSON.parse(manifestText) as { lines?: unknown };
  if (typeof manifest.lines !== "string" || manifest.lines.includes("..")) {
    throw new Error("bad bundle manifest");
  }
  const linesText = await Deno.readTextFile(`${dataDir}/${manifest.lines}`);
  const lines = JSON.parse(linesText) as {
    id?: unknown;
    is_active?: unknown;
    pilot?: unknown;
  }[];
  if (!Array.isArray(lines)) throw new Error("bad bundle lines");
  return lines.map((l) => ({
    id: Number(l.id),
    isActive: l.is_active === true,
    route: null,
  }));
}
