#!/usr/bin/env node
// beforeShellExecution gate, scoped by hooks.json's matcher to `gh pr create`.
//
// docs/agents/issue-tracker.md treats GitHub Issues as the spec/tracking
// surface for this repo. This hook makes "every PR traces to an issue"
// mechanical: it looks for a `#<number>` reference in the PR title/body
// (inline, in --body-file, or in the commits --fill would pull from) before
// letting `gh pr create` run. It asks rather than denies — a PR with no
// issue is sometimes legitimate (e.g. this very harness-engineering work),
// and the human should be the one who waives it, not the script.

const fs = require("fs");
const path = require("path");
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

function extractFlagValue(command, flagNames) {
  for (const flag of flagNames) {
    const re = new RegExp(
      `--${flag}(?:=|\\s+)("(?:[^"\\\\]|\\\\.)*"|'(?:[^'\\\\]|\\\\.)*'|\\S+)`
    );
    const m = re.exec(command);
    if (m) return m[1].replace(/^["']|["']$/g, "");
  }
  return null;
}

const ISSUE_REF_PATTERN = /#\d+/;

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

  try {
    if (!/\bgh\s+pr\s+create\b/i.test(command)) {
      respond({ permission: "allow" });
      return;
    }

    let haystack = command;

    const bodyFile = extractFlagValue(command, ["body-file", "F"]);
    if (bodyFile && bodyFile !== "-") {
      try {
        const resolved = path.isAbsolute(bodyFile)
          ? bodyFile
          : path.join(cwd, bodyFile);
        haystack += "\n" + fs.readFileSync(resolved, "utf8");
      } catch {
        // Body file unreadable from here: judge on the command text alone.
      }
    }

    if (/--fill(-first)?\b/i.test(command) && !ISSUE_REF_PATTERN.test(haystack)) {
      // --fill/--fill-first derive title+body from commit messages.
      try {
        const log = execFileSync("git", ["log", "--format=%B", "-20"], {
          cwd,
          encoding: "utf8",
          timeout: 5000,
        });
        haystack += "\n" + log;
      } catch {
        // Not a git repo, or git unavailable here: judge on what we have.
      }
    }

    if (ISSUE_REF_PATTERN.test(haystack)) {
      respond({ permission: "allow" });
      return;
    }

    respond({
      permission: "ask",
      user_message:
        'This PR doesn\'t reference a GitHub issue (no "#<number>" found in the title/body). Link one (e.g. "Closes #12") before opening it, or confirm there\'s a deliberate reason not to.',
      agent_message:
        "A gate hook found no issue reference in this `gh pr create` command's title/body/linked commits. docs/agents/issue-tracker.md expects PRs to trace to an issue. Add one, or ask the human to confirm this PR intentionally has none.",
    });
  } catch {
    respond({ permission: "allow" });
  }
}

main();
