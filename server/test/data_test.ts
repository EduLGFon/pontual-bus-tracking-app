// Bundle loader tests: missing dir yields empty, built bundle loads.
import { assertEquals } from "@std/assert";
import { loadLinesFromDir, registryResolver } from "../src/data/lines.ts";

Deno.test("missing bundle yields empty registry", async () => {
  const dir = await Deno.makeTempDir();
  try {
    assertEquals(await loadLinesFromDir(dir), []);
    assertEquals(registryResolver([])(7), null);
  } finally {
    await Deno.remove(dir, { recursive: true });
  }
});

Deno.test("built bundle loads lines", async () => {
  const dir = await Deno.makeTempDir();
  try {
    const lines = JSON.stringify([{ id: 7, is_active: true }]);
    await Deno.writeTextFile(`${dir}/lines.abc123def456.json`, lines);
    await Deno.writeTextFile(
      `${dir}/manifest.json`,
      JSON.stringify({ lines: "lines.abc123def456.json" }),
    );
    const loaded = await loadLinesFromDir(dir);
    assertEquals(loaded, [{ id: 7, isActive: true, route: null }]);
  } finally {
    await Deno.remove(dir, { recursive: true });
  }
});
