# Setup: bank accounts

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/setup-bank-accounts.md` marks screen `setup` binding through `.specs/features/visual-identity/design.md` (criterion 12).

Sources:

- `.tasks/setup-bank-accounts.md` - criteria 1–12, the state diagram, the sweep, zero doors, Unresolved 1–4 closed as open defaults in that file. Nothing under Unresolved is settled while building
- https://github.com/gutors/ai-accounting-assistant/issues/83 - **binding for this slice**: label `Coordenadas` → `Agência/Conta Corrente`; list columns Nome do Banco, Nome, Agencia/Conta Corrente, `extrato-{slug}`; one section form like Adicionar/Editar organização (same fields, not details per row); empty = Adicionar conta; Editar fills that form and submit saves that account; Desativar/Reativar on the row; no `/bank_accounts/new`; catalog and organization PIX out
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent: one tlc-plan slice; #83 is this bank-account chrome; later children consume the toast helper; profile `ui`
- https://github.com/gutors/ai-accounting-assistant/issues/76 - success `Pronto.`; field-only `422` has no toast (10, 11). Bank-account `302` was not in that listed set; 5, 6, 9 use the helper because #75 said remaining slices consume it (Unresolved 3)
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screen `setup`. Opened as a file in the repo. Section `setup` today still draws name / `extrato-{slug}` / coordinates, per-row `▸ Editar` details, and `Coordenadas`. C12 amends that section. Four-cell order, one section form, and `Agência/Conta Corrente` values are the task transcription
- `app/views/setup/show.html.erb` - today’s list plus per-row details plus empty POST form labelled `Coordenadas`
- `app/views/administration/new.html.erb` / `edit.html.erb` - same field set for add vs edit; those screens use extra routes, which #83 forbids here
- Open defaults in Unresolved 1–4 - Editar is `GET /setup?edit=bank_account&bank_account_id={id}`; no column header row; toast `Pronto.` on `302`; no `Cancelar`

## Out of scope

- Bank catalog membership, COMPE picker options, `Outro` — existing twelve names; #83 forbids a catalog recorte
- Organization PIX on the bank account — glossary and #83
- `/bank_accounts/new` or any route off `/setup` for the section form
- Changing `BankAccount.create_for` / `#apply_from` acceptance (slug collision, empty slug, unknown COMPE, deactivate keeps the row)
- Month screen bank-account cards (`GET /months/:year_month`) — still show coordinates as the stored string; label change is `/setup` only
- Contador, arquivo do pacote, certificado A1, tipos extras — #80–#82, #84
- Keeping typed values on document or A1 `422` — #85
- `Cancelar` on edit — Unresolved 4
- Glossary rename of **Bank account** coordinates; UI label only
- Confirm before Desativar — existing has none
- Settling Unresolved 1–4 beyond the Until answered column already in the task

## Landing

Touches `GET /setup` Contas bancárias HTML (`setup/show`, `SetupController`) and the existing `POST`/`PATCH /bank_accounts` re-render (`BankAccountsController`). Reuses `BankAccount.create_for` / `#apply_from`, COMPE catalog picker, `#76` `Pronto.` via `redirect_success`, `require_coordinator_organization`, and Contador’s `?edit=` query pattern. No schema change; no new named resource.

None — `POST /bank_accounts` and `PATCH /bank_accounts/:id` already exist. A query on `GET /setup` to fill the section form copies Contador `?edit=accountant` (Unresolved 1) and is not a new resource. Four-cell CSS on existing `li[data-row="bank-account"]` is reversible. No catalog or PIX schema.

- Nothing else in this change is hard to reverse (cell order, one section form, label, Editar query, success toast on existing 302s)

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at its own layer **and** one request spec at HTTP | one asserted case per enumerated member at its own layer; status and who may call at the boundary | follow |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` names the level and the sampling rule: a decision is proven at its own layer, one asserted case per enumerated member; HTTP also gets a request spec; system specs only when a request spec cannot settle the claim
- `BankAccount.create_for` / `#apply_from` acceptance is unchanged (out of scope). This cut is view chrome plus which HTML form `GET /setup` and a failed `POST`/`PATCH` re-render: add vs edit, four cells, labels, toast on 302, submitted fields on 422. Closest analogue: Contador `GET /setup?edit=accountant` in `spec/requests/setup_spec.rb` — request specs assert HTML. This repo has no view specs
- `BankAccountsController#create` / `#update` already choose `302` vs `422` from persist. The new branches are redirect_success on 302, re-render of the one section form as add or edit on 422, and `SetupController#show` filling that form from `edit=bank_account` when the id belongs to the focused organization. Those contracts are asserted at HTTP (C1–C11). Own-layer uniqueness stays in `bank_account_spec`
- System specs are not required: every named observation is HTML or status a request spec can read

Cost: request examples for C1–C11; file-read example for C12. No new model spec. Without the C7 add-form proofs, an other-org id could fill the form and every listed GET example would still pass. Without C10/C11, a 422 could re-render empty add fields.

## Checks

Criteria 1–12 map to C1–C12. Unresolved 1–4 stay the Until answered values in C3, C2, C5, and Out of scope.

### S1 - Columns and labels · 3 files · 34 KB · ~9k

**C1** - Given a signed-in coordinator of the focused organization with no bank accounts, when `GET /setup` runs, then the status is `200`, the Contas bancárias section (from heading `Contas bancárias` through heading `Tipos extras de exceção`) includes `Nenhuma conta bancária`, has no `li[data-row="bank-account"]`, does not include `Coordenadas`, and its section form (the one form in that section that contains `#name`, `#compe`, and `#coordinates`) has `label[for=name]` `Nome`, `label[for=compe]` `Banco`, `label[for=coordinates]` `Agência/Conta Corrente`, `action` `/bank_accounts`, and submit `Adicionar conta`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with no bank accounts includes empty line and add form labelled Agencia/Conta Corrente"`

**C2** - Given that organization has active Banco do Brasil account `Conta Principal` with coordinates `ag 1234` and inactive Santander account `Parada` with blank coordinates, when `GET /setup` runs, then each is `li[data-row="bank-account"][data-bank-account-id="{id}"]`, names still appear with `Alfa` before `Zeta` when those two names exist (existing order), `Conta Principal`’s row HTML contains `Banco do Brasil` then `Conta Principal` then `ag 1234` then `extrato-conta-principal` in that order, `Parada`’s row contains `Santander` then `Parada` then `extrato-parada` and includes `Inativa`, and neither row’s HTML includes `Coordenadas`. That GET has no header row whose cells are `Nome do Banco`, `Nome`, `Agência/Conta Corrente`, `extrato-{slug}` (Unresolved 2).
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup lists bank accounts as four cells without Coordenadas or column headers"`

### S2 - One section form: add or edit · 6 files · 42 KB · ~11k

**C3** - When `GET /setup` runs as in criterion 2, then that Contas bancárias section contains exactly one section form as defined in criterion 1, that form’s `action` is `/bank_accounts` with submit `Adicionar conta`, `#name` and `#coordinates` values are `""`, `#compe` is the existing twelve-name catalog picker (`select#compe`, no `Outro`), the section has no `<details>` whose `<summary>` text is `Editar`, and each listed row includes a control whose text is `Editar` whose URL is on `/setup` (Unresolved 1). Desativar / Reativar `button_to` forms on the rows are not that section form (they do not contain `#name`).
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup listed accounts have one add section form and row Editar on /setup"`

**C4** - Given the `Conta Principal` row from criterion 2, when `GET` of that row’s `Editar` control URL runs, then the status is `200`, the Contas bancárias section still lists both rows, the section form `action` is `/bank_accounts/{id}` of `Conta Principal` with `_method` `patch`, submit is `Salvar conta`, `#name` value is `Conta Principal`, `#compe` selected value is `001`, `#coordinates` value is `ag 1234`, labels match criterion 1, and there is no second form in that section that contains `#name`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET of row Editar fills the section form as PATCH Salvar conta"`

**C5** - Given that edit form, when `PATCH /bank_accounts/{id}` runs with `name` `Nova Conta`, `compe` `001`, and `coordinates` `ag 1234`, then the response is `302` to `/setup`, the row persists that name and slug `nova-conta`, and the following `GET /setup` matches the add section form in criterion 3 (`action` `/bank_accounts`, submit `Adicionar conta`, empty `#name`) and has `[data-toast-kind="success"]` text `Pronto.` (Unresolved 3).
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "PATCH section form 302s to add form and toasts Pronto"`

**C6** - Given the empty organization in criterion 1, when `POST /bank_accounts` runs with `name` `Conta Principal`, `compe` `001`, and `coordinates` `ag 1234`, then the response is `302` to `/setup`, one active Banco do Brasil account is persisted, and the following `GET /setup` includes that row as in criterion 2 and has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST /bank_accounts persists BB Conta Principal and toasts Pronto"`

**C7** - Given focus on organization A while organization B has bank account id `{id}` named `Alheia`, when `GET /setup?edit=bank_account&bank_account_id={id}` runs, then the status is `200`, the body does not include `Alheia`, and the section form matches criterion 1 (add). The same GET with `bank_account_id` that is not an id of the focused organization matches that add form.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup edit bank_account of another organization stays the add form"`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup edit bank_account with unknown id stays the add form"`

### S3 - Row Desativar / Reativar and 422 keeps add or edit · 4 files · 36 KB · ~9k

**C8** - When `GET /setup` runs as in criterion 2, then the `Conta Principal` row includes `Desativar`, the `Parada` row includes `Reativar` and `Inativa`, the Contas bancárias section does not include `Excluir`, and `DELETE /bank_accounts/:id` still responds `404` and keeps the row (existing).
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup listed accounts show Desativar or Reativar and no Excluir"`
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "DELETE /bank_accounts/:id returns 404 and keeps the row"`

**C9** - When `PATCH /bank_accounts/{id}` of `Conta Principal` runs with `active` `false` only, then the response is `302` to `/setup`, the row stays, the following `GET /setup` includes `Conta Principal` and `Inativa` on that row, the section form is the add form in criterion 3, and that GET has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "PATCH active false 302s to add form with Inativa and toasts Pronto"`

**C10** - Given an existing account whose slug is `cafe`, when `POST /bank_accounts` runs with `name` `Cafe`, `compe` `033`, and `coordinates` `ag 9`, then no additional row is persisted, the status is `422`, the section form is still the add form (`action` `/bank_accounts`, submit `Adicionar conta`) with `#name` `Cafe`, `#compe` `033`, and `#coordinates` `ag 9`, and the body has no `[data-toast]` (field uniqueness, same as #76 field-only `422`).
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST colliding slug returns 422 add form with submitted fields and no toast"`

**C11** - Given `Outra` on the focused organization and a sibling whose slug is `cafe`, when `PATCH /bank_accounts/{id}` of `Outra` runs with `name` `Cafe`, `compe` `033`, and `coordinates` `x`, then `Outra`’s name stays `Outra`, the status is `422`, the section form `action` is `/bank_accounts/{id}` of `Outra` with submit `Salvar conta`, `#name` is `Cafe`, `#compe` is `033`, `#coordinates` is `x`, and the body has no `[data-toast]`.
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "PATCH colliding slug returns 422 edit form with submitted fields and no toast"`

### S4 - Binding setup wireframe · 4 files · 63 KB · ~16k

**C12** - `.specs/features/visual-identity/design.md` section `setup` — Contas bancárias is no longer name / `extrato-{slug}` / coordinates with per-row `<details><summary>Editar</summary>` plus a separate empty POST form labelled `Coordenadas`. It is four cells per `li[data-row="bank-account"]` in order bank presentation name, name, agência/conta corrente, `extrato-{slug}`; `Desativar` / `Reativar` on the row; one section form Nome / Banco / `Agência/Conta Corrente`; empty POST `Adicionar conta`; Editar fills that form as PATCH `Salvar conta`. `visual-identity` C42 follows this, not the old fold.
Proof: `bin/rspec spec/docs/setup_bank_accounts_spec.rb -e "visual-identity setup bank accounts are four cells and one section form"`

## Screens (ui)

Design opened: `.specs/features/visual-identity/design.md` (file in the repo). Until C12 lands, Contas bancárias ASCII, cell order, one section form, and `Agência/Conta Corrente` values are the task transcription; Contador, `Arquivo do pacote`, A1 fold, extras, and two-column forms from 768px come from the opened `setup` section.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `setup` banks, empty | `Nenhuma conta bancária`; no `li[data-row="bank-account"]`; no `Coordenadas`; `label[for=name]` `Nome`; `label[for=compe]` `Banco`; `label[for=coordinates]` `Agência/Conta Corrente`; submit `Adicionar conta` C1 | one section form `action` `/bank_accounts` after the empty line, containing `#name`, `#compe`, `#coordinates` C1 | spacing, colour, type weight |
| `setup` banks, listed add | four cells in order bank name, account name, coordinates text, `extrato-{slug}`; `Inativa` on inactive; no `Coordenadas`; no header cells `Nome do Banco` / `Nome` / `Agência/Conta Corrente` / `extrato-{slug}`; `Desativar` / `Reativar`; no `Excluir`; row `Editar` URL on `/setup`; submit `Adicionar conta`; empty `#name` C2, C3, C8 | `li[data-row="bank-account"]` cells then row actions; exactly one section form; no `<details><summary>Editar</summary>`; Desativar/Reativar forms do not contain `#name` C2, C3 | spacing, colour, type weight |
| `setup` banks, listed edit | both rows still listed; submit `Salvar conta`; `#name` `Conta Principal`; `#compe` `001`; `#coordinates` `ag 1234`; labels as C1 C4 | section form `action` `/bank_accounts/{id}` with `_method` `patch`; no second form that contains `#name` C4 | spacing, colour, type weight |
| `setup` banks, after 302 | add form; `[data-toast-kind="success"]` `Pronto.` C5, C6, C9 | `action` `/bank_accounts`; empty `#name`; deactivate stays add C5, C9 | spacing, colour, type weight |
| `setup` banks, 422 | add: submitted `Cafe` / `033` / `ag 9` C10; edit: submitted `Cafe` / `033` / `x` and persisted name `Outra` C11; no `[data-toast]` C10, C11 | add form `action` `/bank_accounts` C10; edit form `action` `/bank_accounts/{id}` `Salvar conta` C11 | spacing, colour, type weight |
| `setup` banks, other-org or unknown edit query | no `Alheia`; add form C7 | `GET /setup?edit=bank_account&bank_account_id=` does not fill from another organization C7 | spacing, colour, type weight |

## Swept

- validation: existing `BankAccount` name/slug/COMPE; C10, C11 reuse colliding slug `422`; this cut does not add a rule; label `Agência/Conta Corrente` still posts `coordinates`
- failure modes: C10, C11 — `422` re-renders the section form in add or edit with submitted values
- idempotency and retry: C3 — a second `GET /setup` stays add; C5 — a second identical name PATCH still `302` and add
- authorization: existing — `BankAccountsController` / `SetupController` `require_coordinator_organization`; C7 — other-org id does not fill the form; this cut does not add a resource route
- concurrency and ordering: n/a — unique `(organization_id, name)` / `(organization_id, slug)` already serialize concurrent creates (existing); this cut does not add a write
- data lifecycle: C2 — existing rows render the four cells on next `GET /setup`; no backfill; stored `coordinates` unchanged
- external-dependency failure: n/a — bank-account save does not call Drive, SMTP, or SEFAZ
- state transitions: C1, C3, C4, C5, C6, C9, C10, C11
- observability: n/a — the source names no log, metric, or trace; C5, C6, C9 reuse the existing success toast helper (`Pronto.`)

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| list occupancy (2) | empty C1 · listed C2 | - |
| cell members (4) | bank presentation name · account name · coordinates text · `extrato-{slug}` C2 | - |
| section form mode (8) | GET add empty C1 · GET add listed C3 · GET edit C4 · GET other-org C7 · GET unknown id C7 · POST 422 add C10 · PATCH 422 edit C11 · GET after 302 add C5, C6, C9 | - |
| POST /bank_accounts outcomes this cut observes (2) | persist `302` + `Pronto.` C6 · colliding slug `422` no toast C10 | existing empty slug / unknown COMPE stay in `bank_accounts_spec` |
| PATCH /bank_accounts/:id outcomes this cut observes (3) | section-form save `302` C5 · `active` false `302` C9 · colliding slug `422` C11 | existing other-org `404` and DELETE `404` stay; C8 reuses DELETE |
| designed screens this cut binds (1) | `setup` C1–C12 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `month`, `documents` — out of scope |
| `setup` banks visual (3 properties × 6 states) | — | spacing, colour, type weight on empty, listed add, listed edit, after 302, 422, and other-org query |

- Claims naming a status code, route or response shape: C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~9k + S2 ~11k + S3 ~9k + S4 ~16k = ~45k token floor. All four slices share `setup/show.html.erb`; unique bytes sit under ~90k plus the opened design (~21 KB). All four stay under 150k and share the Contas bancárias section. No split. One batch.
