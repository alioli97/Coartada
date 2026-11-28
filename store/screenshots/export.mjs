// Exports the store screenshots from the editor (store/screenshots-editor,
// App Store Screenshots skill) without clicking through it: opens the editor in
// headless Chrome once per device deck, presses "Export bundle" and unzips the
// bundle into store/screenshots/{ios,android}/…
//
// Needs Node 20+ and Google Chrome. With the editor running
// (cd store/screenshots-editor && npm run dev -- -p 3005):
//   node store/screenshots/export.mjs [http://localhost:3005] [device…]
import { createRequire } from "node:module";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const editor = join(here, "..", "screenshots-editor");
const require = createRequire(join(editor, "package.json"));
const { chromium } = require("playwright");
const JSZip = require("jszip");

const url = process.argv[2] ?? "http://localhost:3005";
const devices = process.argv.slice(3).length
  ? process.argv.slice(3)
  : ["iphone", "android", "feature-graphic"];
const projectFile = join(editor, "app-store-screenshots.json");

const browser = await chromium.launch({ channel: "chrome" });
try {
  for (const device of devices) {
    // The editor opens on the project's current device.
    const project = JSON.parse(readFileSync(projectFile, "utf8"));
    project.device = device;
    writeFileSync(projectFile, JSON.stringify(project, null, 2) + "\n");

    const page = await browser.newPage({ viewport: { width: 1600, height: 1000 } });
    await page.goto(url);
    const button = page.getByRole("button", { name: "Export bundle" });
    await button.waitFor({ timeout: 120_000 });
    await page.waitForTimeout(3000); // fonts and screenshots
    const [download] = await Promise.all([
      page.waitForEvent("download", { timeout: 300_000 }),
      button.click(),
    ]);
    const zip = await JSZip.loadAsync(readFileSync(await download.path()));
    let count = 0;
    for (const [name, entry] of Object.entries(zip.files)) {
      if (entry.dir || !name.endsWith(".png")) continue;
      const out = join(here, name);
      mkdirSync(dirname(out), { recursive: true });
      writeFileSync(out, await entry.async("nodebuffer"));
      count++;
    }
    console.log(`${device}: ${count} PNGs`);
    await page.close();
  }
} finally {
  await browser.close();
}
