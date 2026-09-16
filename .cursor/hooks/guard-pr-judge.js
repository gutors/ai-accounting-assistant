#!/usr/bin/env node
// beforeShellExecution gate, scoped by hooks.json's matcher to `gh pr merge`.
//
// the-judge (~/.cursor/skills/the-judge) reviews an already-open PR and
// posts a consolidated GitHub review — it cannot run before the PR exists,
// so unlike the issue-reference check at create time this one belongs at
// merge time, the last point where blocking is still useful. It checks, via
// `gh pr view --json reviews`, whether a review matching the-judge's
// summary template (a "## TL;DR" + "## Findings" body) already exists on
// the PR. This is a heuristic signature match, not a review of the review's
// content or verdict — it only proves the-judge ran, not that it approved.

const { execFileSync } = require("child_process");

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

function extractMergeTarget(command) {
  const m = /\bgh\s+pr\s+merge\s+(\S+)/i.exec(command);
  if (!m) return null;
  const candidate = m[1];
  if (candidate.startsWith("-")) return null; // it's a flag, not a PR ref
  return candidate;
}

async function main() {
  const raw = await readStdin();

  let payload;
  try {
    payload = JSON.parse(raw || "{}");
  } catch {
    respond({ permission: "allow" });
    return;
  }

  const command = String(payload.command || "");
  const cwd = String(payload.cwd || process.cwd());

  if (!/\bgh\s+pr\s+merge\b/i.test(command)) {
    respond({ permission: "allow" });
    return;
  }

  try {
    const target = extractMergeTarget(command);
    const args = ["pr", "view"];
    if (target) args.push(target);
    args.push("--json", "reviews");

    const out = execFileSync("gh", args, {
      cwd,
      encoding: "utf8",
      timeout: 8000,
    });
    const data = JSON.parse(out);
    const reviews = Array.isArray(data.reviews) ? data.reviews : [];

    const hasJudgeReview = reviews.some(
      (r) =>
        typeof r.body === "string" &&
        /##\s*TL;DR/i.test(r.body) &&
        /##\s*Findings/i.test(r.body)
    );

    if (hasJudgeReview) {
      respond({ permission: "allow" });
      return;
    }

    respond({
      permission: "ask",
      user_message:
        "No the-judge review found on this PR (looked for a \"## TL;DR\" / \"## Findings\" review body). Run the-judge before merging, or confirm this merge doesn't need it.",
      agent_message:
        "A gate hook checked `gh pr view --json reviews` and found no review matching the-judge's summary template. Run the-judge on this PR first, unless the human explicitly waives it for this merge.",
    });
  } catch {
    // gh unavailable/unauthenticated, no PR found, network hiccup, or an
    // unparseable target: don't block a merge on this heuristic failing to
    // run at all. The gate only acts when it successfully found reviews to
    // check.
    respond({ permission: "allow" });
  }
}

main();
