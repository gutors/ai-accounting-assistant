#!/usr/bin/env node
// beforeShellExecution gate hook (HKS-03).
//
// Turns AGENTS.md's "Do not" list from prose the model might forget into a
// mechanical check that runs on every shell command in this workspace.
// Design goal: fail SAFE, not fail LOUD — a bug in this heuristic must never
// brick every ordinary shell command, so we default to "allow" on any
// parsing error and only act when a pattern below explicitly matches.
//
// Decision table (first match wins, most severe checked first):
//   1. destructive filesystem / database ops -> deny (no override from here;
//      edit this file if a real case turns out to be a false positive)
//   2. push / deploy / publish               -> ask  (human confirms in-flow)
//   3. history rewrite                       -> ask
//   otherwise                                 -> allow
//
// This is a regex/token heuristic, not a shell parser. It is intentionally
// simple per the create-hook guidance: start working, tighten later.

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

function tokenize(command) {
  return command.split(/\s+/).filter(Boolean);
}

// Flags that combine recursive + force, in either -rf or split form.
function isRecursiveForce(flagTokens) {
  const joined = flagTokens.join(" ");
  return (
    flagTokens.some((f) => /^-[a-z]*r[a-z]*f[a-z]*$/i.test(f)) ||
    flagTokens.some((f) => /^-[a-z]*f[a-z]*r[a-z]*$/i.test(f)) ||
    (/(^|\s)-r(\s|$)/.test(joined) && /(^|\s)-f(\s|$)/.test(joined)) ||
    (flagTokens.includes("--recursive") &&
      (flagTokens.includes("--force") || flagTokens.includes("-f"))) ||
    (flagTokens.includes("-r") && flagTokens.includes("--force"))
  );
}

function findDangerousRm(command, cwd) {
  const tokens = tokenize(command);
  for (let i = 0; i < tokens.length; i++) {
    const tok = tokens[i];
    if (tok !== "rm" && !tok.endsWith("/rm")) continue;

    const flagTokens = [];
    let target = null;
    for (const t of tokens.slice(i + 1)) {
      if (t.startsWith("-")) {
        flagTokens.push(t);
      } else {
        target = t;
        break;
      }
    }
    if (!target || !isRecursiveForce(flagTokens)) continue;

    const isRootOrHome = /^(\/|~)\/?$/.test(target) || /^\$HOME\/?$/.test(target);
    const isAbsoluteOutsideWorkspace =
      target.startsWith("/") && cwd && !target.startsWith(cwd);

    if (isRootOrHome || isAbsoluteOutsideWorkspace) {
      return target;
    }
  }
  return null;
}

function isNonLocalDestructiveDb(command) {
  const hasDropOrTruncate = /\b(DROP|TRUNCATE)\s+(DATABASE|TABLE)\b/i.test(command);
  const mentionsLocal = /localhost|127\.0\.0\.1/i.test(command);
  if (hasDropOrTruncate && !mentionsLocal) return true;

  const isRailsDestructiveDbTask = /\brails\s+db:(drop|reset|purge)\b/i.test(command);
  const targetsProduction = /RAILS_ENV\s*=\s*production/i.test(command) ||
    /--environment[= ]production/i.test(command);
  if (isRailsDestructiveDbTask && targetsProduction) return true;

  return false;
}

const PUSH_DEPLOY_PATTERN =
  /\bgit\s+push\b|\b(fly|flyctl)\s+deploy\b|\bgcloud\s+run\s+deploy\b|\bdocker\s+push\b|\bheroku\b[^&|;]*\bdeploy\b|\bkamal\s+deploy\b|\bcap(istrano)?\s+\S*deploy\b|\bnpm\s+publish\b|\bgem\s+push\b/i;

const HISTORY_REWRITE_PATTERN =
  /\bgit\s+rebase\b|\bgit\s+reset\s+--hard\b|\bgit\s+filter-branch\b|\bgit\s+filter-repo\b/i;

async function main() {
  const raw = await readStdin();

  let payload;
  try {
    payload = JSON.parse(raw || "{}");
  } catch {
    // Can't parse the hook input at all: allow rather than crash. This is a
    // hook-plumbing failure, not a signal that the command is dangerous.
    respond({ permission: "allow" });
    return;
  }

  const command = String(payload.command || "");
  const cwd = String(payload.cwd || "");

  try {
    // --- 1. Destructive filesystem / database ops: deny -------------------

    const dangerousRmTarget = findDangerousRm(command, cwd);
    if (dangerousRmTarget) {
      respond({
        permission: "deny",
        user_message: `Blocked: "rm -rf" targeting "${dangerousRmTarget}", outside the workspace.`,
        agent_message: `A gate hook denied "${command}": recursive force-delete outside the workspace is on the AGENTS.md "do not" list. If this target is genuinely safe, ask the human to run it manually outside the agent session.`,
      });
      return;
    }

    if (isNonLocalDestructiveDb(command)) {
      respond({
        permission: "deny",
        user_message: "Blocked: destructive database command against a non-local database.",
        agent_message: `A gate hook denied "${command}": DROP/TRUNCATE without "localhost" in the command, or a Rails destructive db task against RAILS_ENV=production, matches AGENTS.md's "do not change production systems" rule.`,
      });
      return;
    }

    // --- 2. Push / deploy / publish: ask -----------------------------------

    if (PUSH_DEPLOY_PATTERN.test(command)) {
      respond({
        permission: "ask",
        user_message: `This command pushes or deploys: "${command}". AGENTS.md says not to do this unless the user explicitly asked — confirm before continuing.`,
        agent_message: "A gate hook flagged this as a push/deploy/publish command. Only proceed if the user explicitly asked for this in the current conversation; otherwise stop and ask. git push to GitHub: required_permissions [\"all\"] on the first Shell call.",
      });
      return;
    }

    // --- 3. History rewrite: ask --------------------------------------------

    if (HISTORY_REWRITE_PATTERN.test(command)) {
      respond({
        permission: "ask",
        user_message: `This command rewrites git history: "${command}". Confirm before continuing.`,
        agent_message: "A gate hook flagged this as a history-rewriting git command (rebase/reset --hard/filter-branch/filter-repo). Confirm the target branch is not shared before proceeding.",
      });
      return;
    }

    respond({ permission: "allow" });
  } catch {
    // Any unexpected error in the heuristic itself: allow. This script gates
    // known-dangerous patterns; it must not become the thing that blocks
    // ordinary work when it hits an edge case it wasn't written for.
    respond({ permission: "allow" });
  }
}

main();
