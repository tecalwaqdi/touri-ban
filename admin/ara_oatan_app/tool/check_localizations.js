const fs = require("fs");
const path = require("path");

const languageDir = path.join(__dirname, "..", "assets", "langs");
const files = fs
  .readdirSync(languageDir)
  .filter((file) => file.endsWith(".json"))
  .sort();
const translations = Object.fromEntries(
  files.map((file) => [
    path.basename(file, ".json"),
    JSON.parse(fs.readFileSync(path.join(languageDir, file), "utf8")),
  ]),
);

const base = translations.en;
if (!base) throw new Error("assets/langs/en.json is required");
const baseKeys = Object.keys(base).sort();
const placeholderPattern = /\{[A-Za-z0-9_]+\}|\{\}/g;
let failures = 0;

function placeholders(value) {
  return typeof value === "string"
    ? (value.match(placeholderPattern) || []).sort()
    : [];
}

for (const [locale, values] of Object.entries(translations)) {
  const keys = Object.keys(values).sort();
  const missing = baseKeys.filter((key) => !Object.hasOwn(values, key));
  const extra = keys.filter((key) => !Object.hasOwn(base, key));
  const empty = keys.filter(
    (key) => typeof values[key] === "string" && !values[key].trim(),
  );
  const replacement = keys.filter(
    (key) =>
      typeof values[key] === "string" && /[�□]|\?{4,}/u.test(values[key]),
  );
  const placeholderMismatch = baseKeys.filter(
    (key) =>
      JSON.stringify(placeholders(base[key])) !==
      JSON.stringify(placeholders(values[key])),
  );

  const problems =
    missing.length +
    extra.length +
    empty.length +
    replacement.length +
    placeholderMismatch.length;
  failures += problems;
  console.log(
    `${locale}: keys=${keys.length}, missing=${missing.length}, extra=${extra.length}, ` +
      `empty=${empty.length}, replacement=${replacement.length}, ` +
      `placeholderMismatch=${placeholderMismatch.length}`,
  );
  if (missing.length) console.log(`  missing: ${missing.join(", ")}`);
  if (extra.length) console.log(`  extra: ${extra.join(", ")}`);
  if (empty.length) console.log(`  empty: ${empty.join(", ")}`);
  if (replacement.length) {
    console.log(`  replacement: ${replacement.join(", ")}`);
  }
  if (placeholderMismatch.length) {
    console.log(
      `  placeholder mismatch: ${placeholderMismatch.join(", ")}`,
    );
  }
}

if (failures > 0) {
  console.error(`Localization check failed with ${failures} issue(s).`);
  process.exitCode = 1;
} else {
  console.log(`Localization check passed for ${files.length} discovered locale(s).`);
}
