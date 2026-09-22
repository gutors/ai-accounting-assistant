---
description: Add an isolated git worktree with its own PORT and Postgres databases. Use when the user says /worktree or needs a second checkout for a parallel agent.
---

# Worktree

One checkout per agent. Same object database, different files on disk. Never share `tmp/` or Spring sockets across worktrees (`AGENTS.md`).

If the invocation includes a slug, use it. Otherwise ask.

## Create one when

A second process needs its own dirty tree: another agent, another branch in parallel, research that must not touch the current branch. Do **not** create one to switch branches in a single sequential task — `git switch` is enough.

Verifier fault injection (`tlc-implement` `references/verify.md`) uses a throwaway worktree under `/tmp` and is **not** this command. A feature that already has `.specs/features/<name>/checks.md` uses the same isolation from `tlc-spec-lean` `references/verify.md`.

## Capacity (this machine)

M2 8GB. Plan for **2** concurrent `bin/rails server` processes; **3** is the hard ceiling. `git worktree list` first. Count running Pumas. If two servers are already up, do not start a third unless the user accepts the ceiling.

## Steps

1. Pick a short slug from the branch or issue (`auth`, `sefaz`).
2. Path:
   - Durable feature/agent work: sibling `../ai-accounting-assistant-<slug>`
   - Throwaway research: `/tmp/caa-<slug>` (this repo already parks research under `/private/tmp/wayfinder-research/`)
3. Base on `main` unless the user names another ref:

```
git worktree add -b <branch> <path> main
```

If the branch already exists, omit `-b` and pass the branch name as the last argument.

4. In the new tree: `bundle install`, then `bin/lefthook install`.
5. PORT: primary clone is `3000`; next free is `3001`, then `3002`. Puma reads `PORT` (`config/puma.rb`).
6. Databases. Do **not** export a single `DATABASE_URL` for the shell — `bin/rspec` would use it and could wipe development. Pass URLs per command:

| Env | URL | Command |
| --- | --- | --- |
| development | `postgres:///ai_accounting_assistant_<slug>_development` | `DATABASE_URL=… bin/rails db:setup` then `PORT=<n> DATABASE_URL=… bin/rails server` |
| test | `postgres:///ai_accounting_assistant_<slug>_test` | `RAILS_ENV=test DATABASE_URL=… bin/rails db:prepare` then `DATABASE_URL=… bin/rspec` |

7. Tell the user: path, branch, PORT, both database names. They should open **that folder** as the other agent's workspace. Do not `git push` or start the server unless they asked.

## Remove

```
git worktree remove <path>
dropdb ai_accounting_assistant_<slug>_development
dropdb ai_accounting_assistant_<slug>_test
```
