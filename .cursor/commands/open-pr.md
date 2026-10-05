---
description: Open a GitHub PR to main that references an issue. Use when the user says /open-pr or asks to create the pull request.
---

# Open PR

Do this ritual. Read `origin/main...HEAD`; do not invent a summary from the branch name alone.

If the invocation includes an issue number, use it. Otherwise ask. The `gh pr create` hook *asks* when `#N` is missing — that is not a waiver (`AGENTS.md`, `docs/agents/issue-tracker.md`).

1. If the working tree is dirty, stop and ask whether to commit first. Do not commit unless the user says so.
2. Resolve the GitHub issue. Prefer the number the user named. Else `gh issue list --state open` and ask. If none exists, create one (`gh issue create`) or stop for an explicit human waiver.
3. `git fetch origin main`. Read `git log --oneline origin/main..HEAD` and `git diff origin/main...HEAD`. Confirm the branch tracks a remote and is up to date enough to push.
4. Push if needed: `git push -u origin HEAD`. Do not force-push `main`.
5. Write the PR body with the `pr` skill. Title explains **why**. Append `Closes #N` or `Fixes #N` after that body (the hook looks for `#<number>` in title, body, or `--fill` commits). Create with `gh pr create --title` and a heredoc `--body`.
6. Return the PR URL. Do not merge. Do not run the-judge — it reviews a PR that already exists; the merge hook checks that it ran.
