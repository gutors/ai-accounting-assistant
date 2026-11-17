# Monthly close for NGO coordinators

**Language:** English · [Português](README.pt-BR.md)

<img src="public/icon.svg" alt="" width="48" height="48">

<a href="https://paladini.github.io/harness-score/"><img alt="Harness Score" src="https://raw.githubusercontent.com/gutors/ai-accounting-assistant/badges/harness-badge.svg" height="20"></a>

A system to close the month for one or more **organizations** (NGO or similar): import statements, keep supporting documents, match each payment to a document or an exception, flag missing documents, generate the summary spreadsheet, and assemble the **monthly package** for the accountant.

The coordinator delivers the package. The system does not replace the accountant.

> [!IMPORTANT]
> The product prepares the package and writes a copy to the **package archive** (Drive). **Close-for-send** is not delivery to the accountant.

## Who uses it

| Role | Does | Does not |
| --- | --- | --- |
| **Coordinator** | Closes the month, validates matches, marks exceptions | — |
| **Submitter** | Inserts supporting documents | See the statement or bank payments |
| **Accountant** | Receives the package | Use the system |

The ritual and the summary spreadsheet format are the same across organizations. Bank accounts, accountant, package destination, package archive, and extras (exception kinds, SEFAZ certificate, submitters) vary by organization.

Who registers a new organization is a Google account on the allowlist (`ADMINISTRATOR_EMAIL`). That person opens **Administração**, confirms the coordinator’s name and email, and the system sends the welcome mail. They do not close the month in the coordinator’s place.

## Ritual

1. The coordinator imports the statement of each **bank account** (PDF + CSV/XLSX in this version).
2. Coordinator and submitters insert **supporting documents** (photo and/or authorized XML). A photo of a nota may be read on the server to find the chave de acesso.
3. The system suggests matches; the coordinator confirms — or marks a **document exception**.
4. A payment with neither match nor exception is a **missing document** and blocks close-for-send.
5. **Close-for-send** freezes the month in the product and writes the package to the **month folder** `{YYYY-MM}` in the organization’s Drive archive.
6. The coordinator delivers the same package to the accountant.

Canonical vocabulary: [`GLOSSARY.md`](GLOSSARY.md).

## Run locally

Ruby `3.4.10` (`.ruby-version`) and PostgreSQL accepting connections. The development database is `ai_accounting_assistant_development`.

### First time

In the repository folder:

```sh
bundle install
bin/lefthook install
bin/rails db:setup
```

`db:setup` creates the database, loads the schema, and runs the seed. If the database already exists, use `bin/rails db:migrate`. The development seed is idempotent: it does not write a second `ONG Exemplo` when the sample account is already there.

Create a `.env` at the repo root (Git ignores this file) and fill in the OAuth client and mail. No quotes and no spaces around `=`:

```sh
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
ADMINISTRATOR_EMAIL=
MAIL_FROM=
MAILER_HOST=localhost:3000
SMTP_ADDRESS=
SMTP_PORT=587
SMTP_USER_NAME=
SMTP_PASSWORD=
```

In the Google OAuth client, type **Web application**, the authorized redirect URI is `http://localhost:3000/auth/google_oauth2/callback`. Scheme, host, and port must match the browser bar.

### Each time

```sh
bin/dev
```

Open `http://localhost:3000`. Stop with `Ctrl-C` in that terminal.

`bin/dev` starts Puma and Tailwind, and Foreman loads `.env`. `bin/rails server` alone does not load `.env` and does not watch CSS.

If port 3000 is taken:

```sh
PORT=3001 bin/dev
```

The URL and the redirect URI then use port `3001`.

### Sign in

Sign in with Google as `gutors@gmail.com` to land on `ONG Exemplo` as coordinator. In development, `/login` also lists **Ambiente local**: one button per already-persisted account (`POST /dev/session`) so the agent (or you) can sign in without Google. That door does not exist in production. Another name or another email:

```sh
ORGANIZATION_NAME="ONG Norte" COORDINATOR_EMAIL="coord@exemplo.org" bin/rails coordinator:bootstrap
```

The Google account used to sign in must be the coordinator’s, with a verified email. While the OAuth app is in testing mode, that account must be on the test-users list.

### Variables

Required for local login: `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`.

| Variable | When |
| --- | --- |
| `ADMINISTRATOR_EMAIL` | Google email that opens `/administration` |
| `MAIL_FROM` | Sender of the welcome mail |
| `MAILER_HOST` | Host of the links in that mail |
| `SMTP_ADDRESS` | SMTP server; without it, sending is not configured |
| `SMTP_PORT` | SMTP port; `587` when empty |
| `SMTP_USER_NAME` | SMTP user |
| `SMTP_PASSWORD` | SMTP password |
| `GOOGLE_DRIVE_REFRESH_TOKEN` | Drive writer account at close-for-send. Not the operator login |
| `SEFAZ_WRAP_KEY` | Wraps the A1 certificate. Without it, installing the certificate and identified consulta are left out; the rest of the close still runs |
| `ORGANIZATION_NAME`, `COORDINATOR_EMAIL` | Only for `coordinator:bootstrap` |

A nota photo uses the `tesseract` binary on `PATH`, with languages `por` and `eng`. Without it, the read comes back empty and the chave stays typed.

A PDF photo uses the `pdftoppm` binary (Poppler) on `PATH`. Without it, the PDF read comes back empty and the fields stay typed.

> [!WARNING]
> Do not put an A1 certificate, passwords, Drive tokens, the `.env`, or real financial data in the repository.

## State

> [!NOTE]
> `bin/rails db:seed` in development persists the organization `ONG Exemplo` and the coordinator account `gutors@gmail.com`.

Product decisions live in the [monthly close map](https://github.com/gutors/ai-accounting-assistant/issues/1). A new feature starts from **tlc-spec-lean** (`plan.md` and `checks.md` under `.specs/features/<name>/`). The map is not the specification to implement.

## Platform (v1)

Locked. Detail and rejected alternatives: [ADR-0001](docs/adr/0001-rails-8-hotwire.md).

| Piece | Choice |
| --- | --- |
| App | Rails 8, one process (Puma), server-rendered HTML with Hotwire (Turbo + Stimulus) |
| UI | Tailwind, locale `pt-BR` |
| Data | PostgreSQL, Active Record; money in integer cents (`bigint`) |
| Auth | Google OIDC (`openid email`); app session. The account that writes to Drive is not the operator login |
| Working files | Opaque object store (container disk is ephemeral) |
| Package archive | Drive, only at close-for-send / restore the month folder |
| Deploy | Container that sleeps when idle; timeout in minutes (enough for close-for-send). Host brand is not locked |
| Tests | RSpec (`bin/rspec`) |

## Out of this version

- Open Finance consent (the JSON path is sketched; upload only in this version)
- Accountant as an operator; NF-e issuance; organization CNPJ as a setup field
- The system becoming an Open Finance receptor (BCB)

## Documentation

| Doc | What for |
| --- | --- |
| [`GLOSSARY.md`](GLOSSARY.md) | Domain glossary |
| [Issue #1](https://github.com/gutors/ai-accounting-assistant/issues/1) | Product map |
| [`docs/adr/`](docs/adr/) | Platform decisions |
| [`AGENTS.md`](AGENTS.md) | How agents work in this repo |
| [`README.pt-BR.md`](README.pt-BR.md) | This README in Portuguese |

The code in this repository is for viewing only. All rights reserved — see [`LICENSE`](LICENSE).
