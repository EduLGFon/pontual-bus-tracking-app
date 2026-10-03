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

/** File loader stub. Reads DATA_DIR when T14 lands; empty until then. */
export function loadLinesFromDir(
  _dataDir: string,
): Promise<LineRecord[]> {
  return Promise.resolve([]);
}
