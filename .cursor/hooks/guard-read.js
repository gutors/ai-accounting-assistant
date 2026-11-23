#!/usr/bin/env node
// beforeReadFile gate hook (HKS-03, secret-bearing-reads half).
//
// Keeps AGENTS.md's "do not put secrets ... in chat" rule out of the
// model's context entirely, rather than trusting the model not to paste a
// secret it already read. beforeReadFile only supports "allow"/"deny"
// (no "ask") per Cursor's hooks spec, so a match here always denies.
//
// Recognizes: .env files (not templates), A1 certificates (.pfx/.p12),
// the Rails master key, wrap-key material, and refresh-token files.

const path = require("path");

function readStdin() {
  return new Promise((resolve) => {
    let data = "";
    process.stdin.on("data", (chunk) => (data += chunk));
    process.stdin.on("end", () => resolve(data));
    process.stdin.on("error", () => resolve(data));
  });
}

function respond(decision) {
  process.stdout.write(JSON.stringify(decision));
}

function checkRead(filePath) {
  const base = path.basename(filePath).toLowerCase();

  const isEnvTemplate = /\.env\.(example|sample|template)$/i.test(base);
  const isEnvFile = !isEnvTemplate && (base === ".env" || /^\.env\..+/.test(base));
  const isCert = /\.(pfx|p12)$/i.test(base);
  const isMasterKey = base === "master.key" || /(^|[._-])master\.key$/i.test(base);
  const isWrapKey = /wrap.*key/i.test(base) || /key.*wrap/i.test(base);
  const isRefreshToken = /refresh.*token/i.test(base);

  const reasons = [];
  if (isEnvFile) reasons.push(".env file (real secrets, not a template)");
  if (isCert) reasons.push("A1 certificate (.pfx/.p12)");
  if (isMasterKey) reasons.push("Rails master key");
  if (isWrapKey) reasons.push("wrap key material");
  if (isRefreshToken) reasons.push("refresh token file");

  if (reasons.length > 0) {
    return {
      permission: "deny",
      user_message: `Blocked read of "${filePath}": looks like ${reasons.join(", ")}. AGENTS.md says these never enter the repo or chat context.`,
    };
  }
  return { permission: "allow" };
}

async function main() {
  const raw = await readStdin();
  try {
    const payload = JSON.parse(raw || "{}");
    respond(checkRead(String(payload.file_path || "")));
  } catch {
    respond({ permission: "allow" });
  }
}

if (require.main === module) main();
module.exports = { checkRead };
