const fs = require("fs");
const path = require("path");

const libDir = path.join(__dirname, "..", "lib");
const allowedLiterals = new Set(["G", "Touri Taxi", "•"]);
const textLiteralPattern =
  /\b(?:const\s+)?Text\(\s*('(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")(?!\s*\.tr\s*\()/g;

function dartFiles(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) return dartFiles(entryPath);
    return entry.name.endsWith(".dart") ? [entryPath] : [];
  });
}

function literalValue(raw) {
  return raw
    .slice(1, -1)
    .replace(/\\(['"\\nrt])/g, (_, character) => {
      if (character === "n") return "\n";
      if (character === "r") return "\r";
      if (character === "t") return "\t";
      return character;
    });
}

const violations = [];
for (const file of dartFiles(libDir)) {
  if (file.endsWith(`${path.sep}internationalization.dart`)) continue;
  const source = fs.readFileSync(file, "utf8");
  for (const match of source.matchAll(textLiteralPattern)) {
    const value = literalValue(match[1]);
    const isDynamic = value.includes("$");
    const isFormattingOnly = /^[-+0-9 .:/]+$/.test(value);
    if (
      value.length < 2 ||
      isDynamic ||
      isFormattingOnly ||
      allowedLiterals.has(value)
    ) {
      continue;
    }
    const line = source.slice(0, match.index).split(/\r?\n/).length;
    violations.push(`${path.relative(libDir, file)}:${line}: ${value}`);
  }
}

if (violations.length) {
  console.error("Hardcoded user-facing Text literals found:");
  console.error(violations.join("\n"));
  process.exitCode = 1;
} else {
  console.log("Hardcoded UI string check passed.");
}
