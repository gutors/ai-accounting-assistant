#!/usr/bin/env node
// afterFileEdit feedback hook (HKS-04).
//
// Safe-autocorrects Ruby the agent just wrote so RuboCop's house style
// (omakase) lands in the file instead of in a later lint surprise.
// Fail open: a missing bin/rubocop or a cop error must never block the
// edit that already succeeded. Unsafe cops stay off (`-a`, not `-A`).

const path = require("path");
const { spawnSync } = require("child_process");

function readStdin() {
  return new Promise((resolve) => {
    let data = "";
    process.stdin.on("data", (chunk) => (data += chunk));
    process.stdin.on("end", () => resolve(data));
    process.stdin.on("error", () => resolve(data));
  });
}

async function main() {
  const raw = await readStdin();

  let payload;
  try {
    payload = JSON.parse(raw || "{}");
  } catch {
    return;
  }

  const filePath = String(payload.file_path || "");
  if (!filePath || path.extname(filePath) !== ".rb") return;

  const cwd = Array.isArray(payload.workspace_roots) && payload.workspace_roots[0]
    ? payload.workspace_roots[0]
    : process.cwd();

  const rubocop = path.join(cwd, "bin", "rubocop");

  try {
    spawnSync(rubocop, ["-a", "--force-exclusion", filePath], {
      cwd,
      stdio: "ignore",
      timeout: 25000,
    });
  } catch {
    // Fail open.
  }
}

main();
