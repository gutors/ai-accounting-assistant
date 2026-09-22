# Monthly close (ONG)

Web app for a financial **Coordinator** to close a month for one or more **Organization**s (statements, supporting documents, matches, summary spreadsheet, monthly package). The coordinator delivers the package; the **Accountant** is not an operator. Read `README.md` and `CONTEXT.md` — do not revive the old SMB / owner-dashboard / multi-company books framing.

## How to work

1. A new feature uses **tlc-plan**, then **tlc-implement**. Open that skill. GitHub issue #1 is the product map; it is not a build source.
2. tlc-plan writes `.tasks/<name>.md`. A human confirms that task before implementation. tlc-implement extracts `.checks/<feature>.md` from it and builds from that checklist.
3. A builder reports and stops. The orchestrator — never the builder — dispatches a fresh Verifier (`.cursor/agents/tlc-verifier.md`) over `<feature base>..HEAD` with every check. Author is not verifier.
4. Project memory: `.specs/STATE.md` is the **handoff** snapshot only. Decisions that constrain later features live in `docs/adr/` (start from ADR-0001). Do not start a second log in STATE.md. Features that already have `.specs/features/<name>/` stay there. New tasks and checklists go to `.tasks/` and `.checks/`.
5. Do not paste tlc-plan or tlc-implement `references/` into this file.
6. A feature that already has `.specs/features/<name>/checks.md` continues with **tlc-spec-lean**. A new feature does not get a folder there.

## tlc-implement

profile: standard
handoff: on

Raise to `ui` when the task names a binding screen or design source. Say so in one line; do not silently exceed this floor.

## Stack

Platform v1 (locked — do not reopen inside a feature plan. A live architecture alternative is an ADR first, then a Landing row):

- **App:** Rails 8, one process (Puma: UI + server). Server-rendered HTML with **Hotwire** (Turbo + Stimulus). Deploy as a **scale-to-zero container** (sleeps when idle; request timeout in minutes — enough for **close-for-send**). Not Lambda/Vercel-style functions as the primary runtime; not a 24h VM as the cost model. Local: `bin/rails server`. Host brand (Cloud Run, Fly, …) is not locked.
- **Operator auth:** Google OIDC on the server (`openid email`); app session; `email_verified` plus invite-email match. No Drive scopes on operator login. **Account** ≠ Drive writer. Pick the OmniAuth/OIDC gem in Landing of the first auth feature — do not invent Devise “because Rails”.
- **Drive:** dedicated writer Google account (OAuth refresh token on the server). The coordinator shares the existing **package archive** folder with that account; the app writes `{YYYY-MM}` (**month folder**) at **close-for-send**.
- **Data:** PostgreSQL via Active Record. Money: integer cents (`bigint`, Ruby `Integer`), never `Float` or `BigDecimal` for domain amounts. Compute may scale to zero (same idle-cost idea); brand is not locked.
- **Jobs:** Active Job; Solid Queue is the Rails 8 default (no Redis). **Close-for-send** may stay an in-request long job (timeout in minutes) or run as a job — pick in Landing of that feature.
- **SEFAZ certificate:** A1 `.pfx` + passphrase encrypted in Postgres; wrapping key in the process environment. Identified consulta (mTLS) on the server, including when a **Submitter** triggers it unattended.
- **Working files:** opaque object store from v1 (container disk is ephemeral). Drive only at close-for-send / month-folder restore. Metadata in Postgres. No second database. Local dev may use a disk adapter of the same blob interface. Brand (S3, GCS, …) is not locked. Active Storage only if Landing of the first file feature chooses it as that interface.
- **UI:** Tailwind + Hotwire. No React, no shadcn/ui. Default locale `pt-BR`. User-facing copy: pt-BR.
- **Tests:** RSpec (`spec/`). Decision tables and guards are proven at their own layer, one asserted case per enumerated member; HTTP boundaries also get a request spec. See `.cursor/rules/rails.mdc`.
- Conventions: `.cursor/rules/rails.mdc` (loads when Ruby/ERB/Gemfile is in play).

Parallel local agents: one git worktree per agent; distinct `PORT` and `DATABASE_URL` per checkout. On this M2 8GB machine, plan for 2 concurrent `bin/rails server` processes (3 is the hard ceiling). Do not share Spring/tmp between worktrees. Use `/worktree`.

## Layout

| Path | Role |
| --------------------------------- | ---------------------------------------- |
| `app/` | Rails (controllers, models, views, jobs) — create on first feature |
| `config/` | Rails config (create on first feature) |
| `db/` | Migrations and schema (create on first feature) |
| `spec/` | RSpec (create on first feature) |
| `.specs/` | Handoff (`STATE.md`) and features already specified with tlc-spec-lean |
| `.tasks/` | tlc-plan tasks for new features |
| `.checks/` | tlc-implement checklists and verification reports |
| `.cursor/rules/` | Stack conventions (glob-scoped) |
| `.cursor/skills/tlc-spec-lean/` | Skill for a feature that already has `.specs/features/<name>/checks.md` |
| `.cursor/commands/` | Human-triggered slash commands (`/open-pr`, `/worktree`) |
| `.cursor/agents/` | Project subagents (`tlc-verifier`) |

If a folder is missing, create it as part of the planned feature — do not scaffold empty trees “just in case.”

## Language

- **UI, user-facing copy, product docs:** Portuguese (Brazil).
- **Code, comments, commit messages, and technical artifacts** (`.specs`, `.tasks`, `.checks`): English.
- Domain words: `CONTEXT.md`.

## Commit messages

- Explain **why** the change exists; the diff already shows what changed.
- Do not list every file or document in the message.

## Commands

When `Gemfile` exists, use `bin/rails`, `bin/rspec`, and other `bin/` wrappers. Prefer existing scripts over inventing new ones. `npm test` is the same `bin/rspec` entry (harness-score looks for a `package.json` test script; this is not a Node app). After clone or a new worktree, run `bin/lefthook install` so pre-commit runs RuboCop and erb_lint on staged files. A check’s proof names a **specific example** (selector), never a whole suite; if no command exists yet, ask.

## Pull requests

- Every PR to `main` references a GitHub issue (`Closes #N` / `Fixes #N`) — see `docs/agents/issue-tracker.md`. No issue, no PR, unless a human explicitly waives it. Use `/open-pr`.
- Run the `the-judge` skill against the open PR before merging to `main` — it reviews a PR that already exists (posts a GitHub review via `gh`), so it runs after creation, not before.
- `.cursor/hooks.json` gates `gh pr create` (issue reference) and `gh pr merge` (the-judge checkpoint) mechanically. These bullets are why those gates exist, not a substitute for them — a hook failing open (e.g. `gh` unreachable) doesn’t waive the rule.

## Do not

- Put secrets, A1 files, wrap keys, Drive refresh tokens, or real financial data in the repo or in chat.
- `git push`, deploy, or change production systems unless the user explicitly asks.
- Load extra skills unless the user asks or the task clearly requires them.
- Use floating-point types for money (`Float`, `BigDecimal` for domain amounts).
- Attach Drive OAuth to operator login, or treat the writer Google account as **Account**.
- Choose hosting vendor, object-store brand, GCP project, or KMS unless the user reopens platform. The **pattern** is locked: scale-to-zero container + object store + Postgres that may sleep.
- Put close-for-send or A1/SEFAZ mTLS in short-lived functions (Lambda, Vercel Hobby timeouts) as the home of that work.
- Treat the container filesystem as durable storage for photos, XML, or statements.
- Implement Open Finance consent, a BCB receptor, NF-e issuance, accountant login, or organization CNPJ as a setup field.
- Start product code before a human has confirmed the `.tasks/<name>.md` task and tlc-implement has extracted `.checks/<feature>.md`.
- Plan a new feature with tlc-spec-lean. That skill stays for a feature that already has `.specs/features/<name>/checks.md`.
- Dispatch the Verifier from a builder, or treat a self-check as verification.

## Agent skills

### Issue tracker

Issues live in this repo's GitHub Issues (`gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Default role labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
