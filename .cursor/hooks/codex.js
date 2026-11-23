// Translate Codex hook events into the existing project hook inputs.
const fs = require("node:fs");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { checkRead } = require("./guard-read");

const root = path.resolve(__dirname, "../..");

function run(script, input, timeout = 9_000) {
  return spawnSync(process.execPath, [path.join(__dirname, script)], {
    cwd: root,
    input: JSON.stringify(input),
    encoding: "utf8",
    timeout,
  });
}

function decision(script, input) {
  const result = run(script, input);
  if (result.status === 0) return JSON.parse(result.stdout);
  if (script === "guard-shell.js") return { permission: "allow" };
  return {
    permission: "deny",
    user_message: "Could not run the project PR check. Verify the requirement before proceeding.",
  };
}

function deny(reason) {
  return {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: reason,
    },
  };
}

function checkShell(command, cwd) {
  const shellInput = { command, cwd };
  const shell = decision("guard-shell.js", shellInput);
  if (shell.permission === "deny") return deny(shell.user_message);

  // Codex shell calls have no beforeReadFile event. Inspect literal path
  // arguments here, using the same filename policy as Cursor.
  const words = command.match(/"[^"\n]*"|'[^'\n]*'|[^\s"'<>|;&()]+/g) || [];
  for (const word of words) {
    const filePath = word.replace(/^--[\w-]+=/, "").replace(/^["']|["']$/g, "");
    if (/^[A-Za-z_][\w]*=/.test(filePath)) continue;
    if (/\s/.test(filePath) && !fs.existsSync(path.resolve(cwd, filePath))) continue;
    const read = checkRead(filePath);
    if (read.permission === "deny") return deny("Shell command targets a protected file. Use a safe fixture or template.");
  }

  for (const [pattern, script] of [
    [/\bgh\s+pr\s+create\b/i, "guard-pr-issue.js"],
    [/\bgh\s+pr\s+merge\b/i, "guard-pr-judge.js"],
  ]) {
    if (!pattern.test(command)) continue;
    const pr = decision(script, shellInput);
    if (pr.permission !== "allow") {
      return deny(`${pr.user_message} An explicit human waiver must be applied from the human's terminal.`);
    }
  }

  if (shell.permission === "ask") {
    // The matching Codex execution rules prompt for shell operations with
    // known prefixes. Context also preserves the instruction on other forms.
    return {
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: "The project shell guard flagged a push, deploy, publish, or history rewrite. Confirm the user authorized the operation and follow the Codex approval policy.",
      },
    };
  }
  return {};
}

function checkFileTool(input) {
  const files = [input.path, input.file_path, ...(Array.isArray(input.paths) ? input.paths : [])];
  for (const filePath of files) {
    if (typeof filePath !== "string") continue;
    const read = checkRead(filePath);
    if (read.permission === "deny") return deny(read.user_message);
  }
  return {};
}

function formatPatch(command, cwd) {
  const edits = command.matchAll(/^\*\*\* (?:Add File|Update File|Move to): (.+)$/gm);
  const files = new Set();
  for (const edit of edits) {
    const filePath = path.resolve(cwd, edit[1].trimEnd());
    if (path.extname(filePath) === ".rb" && fs.existsSync(filePath)) {
      files.add(fs.realpathSync(filePath));
    }
  }

  const rubyFiles = Array.from(files).filter((filePath) => {
    const relative = path.relative(root, filePath);
    return !relative.startsWith(".." + path.sep) && !path.isAbsolute(relative) &&
      path.extname(relative) === ".rb";
  });
  if (rubyFiles.length) {
    run("format-ruby.js", { file_paths: rubyFiles, workspace_roots: [root] }, 26_000);
  }
}

function main(payload) {
  const input = payload.tool_input || {};
  const cwd = input.workdir || payload.cwd || root;
  if (payload.hook_event_name === "PostToolUse") {
    formatPatch(input.command || "", cwd);
    return {};
  }
  if (["Bash", "exec_command", "Shell"].includes(payload.tool_name)) {
    return checkShell(input.command || "", cwd);
  }
  return checkFileTool(input);
}

try {
  process.stdout.write(JSON.stringify(main(JSON.parse(fs.readFileSync(0, "utf8")))));
} catch (error) {
  process.stderr.write(`Project hook failed: ${error.message}\n`);
  process.exitCode = 1;
}
