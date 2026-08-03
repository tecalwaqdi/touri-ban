const fs = require("fs");
const path = require("path");
const iconv = require("../firebase/functions/node_modules/iconv-lite");

const languageDir = path.join(__dirname, "..", "assets", "langs");
const shouldWrite = process.argv.includes("--write");

const expectedScript = {
  ar: /\p{Script=Arabic}/u,
  ur: /\p{Script=Arabic}/u,
  ru: /\p{Script=Cyrillic}/u,
  ky: /\p{Script=Cyrillic}/u,
  ka: /\p{Script=Georgian}/u,
  "zh-Hans": /\p{Script=Han}/u,
  en: /\p{Script=Latin}/u,
  az: /\p{Script=Latin}/u,
  tr: /\p{Script=Latin}/u,
  fr: /\p{Script=Latin}/u,
  id: /\p{Script=Latin}/u,
};

function scriptCount(value, locale) {
  const matcher = expectedScript[locale];
  if (!matcher) return 0;
  let count = 0;
  for (const char of value) {
    if (matcher.test(char)) count++;
  }
  return count;
}

function mojibakeScore(value) {
  const sequences = [
    /ط[§£¹±¨®©]/gu,
    /ظ[„…†‡ˆ‰]/gu,
    /ذ[،؛µ¶·¸¹º»¼½¾¿]/gu,
    /ر[€پ‚ƒ„…†‡]/gu,
    /[ÃÂÐÑ][\p{L}\p{P}]/gu,
    /â(?:€|„|™|†|‡|ˆ|‰|œ|ž|¢)/gu,
    /(?:à¤|à´|à²|à°|ê¦|لگ|وœ)/gu,
  ];
  return sequences.reduce(
    (score, pattern) => score + (value.match(pattern) || []).length,
    0,
  );
}

function decodeWindows1256Utf8(value) {
  try {
    return iconv.decode(iconv.encode(value, "windows-1256"), "utf8");
  } catch (_) {
    return value;
  }
}

function repairString(value, locale) {
  let current = value;
  for (let pass = 0; pass < 2; pass++) {
    const candidate = decodeWindows1256Utf8(current);
    if (
      candidate === current ||
      candidate.includes("�") ||
      candidate.includes("????")
    ) {
      break;
    }
    const currentScript = scriptCount(current, locale);
    const candidateScript = scriptCount(candidate, locale);
    const currentMojibake = mojibakeScore(current);
    const candidateMojibake = mojibakeScore(candidate);
    const scriptImproved = candidateScript > currentScript;
    const corruptionImproved = candidateMojibake < currentMojibake;
    if (!scriptImproved && !corruptionImproved) break;
    current = candidate;
  }
  return current;
}

function repairValue(value, locale, stats) {
  if (typeof value === "string") {
    const repaired = repairString(value, locale);
    if (repaired !== value) stats.changed++;
    return repaired;
  }
  if (Array.isArray(value)) {
    return value.map((item) => repairValue(item, locale, stats));
  }
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [
        key,
        repairValue(item, locale, stats),
      ]),
    );
  }
  return value;
}

let total = 0;
for (const file of fs.readdirSync(languageDir).filter((f) => f.endsWith(".json"))) {
  const locale = path.basename(file, ".json");
  const fullPath = path.join(languageDir, file);
  const original = JSON.parse(fs.readFileSync(fullPath, "utf8"));
  const stats = { changed: 0 };
  const repaired = repairValue(original, locale, stats);
  total += stats.changed;
  console.log(`${file}: ${stats.changed} repaired value(s)`);
  if (shouldWrite && stats.changed > 0) {
    fs.writeFileSync(fullPath, `${JSON.stringify(repaired, null, 2)}\n`, "utf8");
  }
}

console.log(`${shouldWrite ? "Repaired" : "Would repair"}: ${total} value(s)`);

