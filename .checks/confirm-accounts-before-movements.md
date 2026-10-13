# Confirm accounts before movements

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/confirm-accounts-before-movements.md` marks screen `month` binding through `.specs/features/visual-identity/design.md` (criterion 20).

Sources:

- `.tasks/confirm-accounts-before-movements.md` - criteria 1–22, the state diagram, the sweep, three doors, Unresolved 1–2 stay at the transcribed answers (heading `Confirmar contas para fechamento`, submit `Iniciar fechamento`, unconfirmed summary is the insert-statements sentence; backfill C22). Nothing under Unresolved is settled beyond that transcription. Conversation copy on the prototype is already in those criteria
- https://github.com/gutors/ai-accounting-assistant/issues/110 - **binding for this slice**: intermediate `GET /months/:year_month`; upload persists immediately; hide Recebimentos, Pagamentos, and the matching pool until confirm; while unconfirmed show accounts plus a step listing present vs missing; agreement on `Month` not session; replace after agreement does not hide lists; same gate when a matching screen exists; close-for-send still refuses active account without statement and payment without document. Button label in the issue was continue-anyway; the task now names `Iniciar fechamento`
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent umbrella; one tlc-plan per child
- https://github.com/gutors/ai-accounting-assistant/issues/76 / `.tasks/action-result-toast.md` - success toast `Pronto.` on later month actions
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screen `month`. Opened as a file in the repo. Today’s ASCII still draws Recebimentos/Pagamentos/pool on every GET. C20 amends that section. Prototype at `GET /prototypes/confirm-accounts` is a development mock of the same copy and arrangement; it is not a binding source
- `app/views/months/show.html.erb`, `MonthsController#show`, `ApplicationController#load_month_page` - today’s always-on lists
- `app/models/month.rb` - `close_blocker` already `MISSING_STATEMENT` / `MISSING_DOCUMENT`; no confirmation bit
- `GLOSSARY.md` - **Accounts confirmation** is missing until C21
- Open defaults in Unresolved 1–2 as transcribed in the task

## Out of scope

- Optional PDF, compact include, Documentos column — #108 (shipped)
- PagSeguro parser — #109
- Matching screen (`GET /months/:year_month/matches`), Resolver / N:1 redesign — #111 (that screen reads this same Month flag; this cut gates today’s on-page POSTs)
- Month overview: drop Ações, filter, collapse lists, Voltar para Início — #112
- A control that clears `accounts_confirmed` — source only persists the agreement
- Requiring every account Presente before `Iniciar fechamento` — the control stays enabled with Falta
- Toast on statement `POST` — existing redirect has none
- Changing `Month#close_blocker` copy or adding a confirmation blocker — close stays the two existing refusals (C18, C19)
- Open Finance, OFX, inactive accounts on the month list — existing
- Removing the development prototype at `/prototypes/confirm-accounts` — leave it; production does not use it
- Settling Unresolved 1–2 beyond the task’s transcribed heading, button, summary sentence, and backfill rule

## Landing

Touches `months.accounts_confirmed`, `Month.open`, a backfill migration, `POST /months/:year_month/account_confirmation`, `GET /months/:year_month` (hide movement sections until confirm or closed), match / document-exception / return 404 while unconfirmed, `design.md` section `month`, and `GLOSSARY.md`. Reuses `redirect_success` (`Pronto.`), existing `close_blocker` copy, `require_coordinator_organization`, bank ledger `Falta`/`Presente`, and verb POSTs (`close`, `reopen`, `restore`).

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Agreement is a boolean on `Month` | `months.accounts_confirmed` `boolean` `null: false` `default: false`. `Month.open` leaves the default. Import/replace does not write the column | Session flag — #110. Infer from “every account Presente” — continue-anyway and replace-must-not-hide cannot be expressed. Timestamp — source did not ask when |
| Confirm is `POST /months/:year_month/account_confirmation` | no params; success `302` to show + toast `Pronto.`; closed `422` `Mês fechado`. No DELETE | `PATCH` the Month with a body field — this app’s month actions are verb POSTs |
| Unconfirmed match/exception/return | HTTP `404`, no persist, no new Portuguese `:base` | `422` with a new sentence — #110 says there is no movement to match, which is the existing not-found shape |

- Nothing else in this change is hard to reverse. C22 backfill (`true` if `closed` or a BankStatement exists) is forced by Unresolved 2 / criterion 22

## Screens (ui)

Opened `.specs/features/visual-identity/design.md` section `month` as a file. Today's ASCII still always shows Recebimentos / Pagamentos / pool. C20 amends it. Arrangement below is what C1–C7, C9, C20 plus the amended section require. Compact confirm sheet (max-width 28rem, Nome | Situação) is the prototype the coordinator reviewed; tokens stay the month system.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `month` unconfirmed open | summary `Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.` (not `pagamento com documento faltante`); `h2` `Contas bancárias` then `h2` `Confirmar contas para fechamento`; confirm rows name + `Presente` or `Falta` (`text-margem` on Falta) in ledger name order; submit `Iniciar fechamento` posting to `/months/:year_month/account_confirmation`; no `h2` `Recebimentos`, `Pagamentos`, `Documentos sem casamento`; no `li[data-row="inflow"]`, `payment`, `pool-document`; empty active accounts: `Nenhuma conta bancária ativa` plus the confirm `h2` and submit | confirm step after the bank section, not grouped Presente/Falta lists; confirm sheet is a two-column ledger (`Nome`, `Situação`) then the primary submit; movement sections omitted entirely, not empty; bank ledger unchanged | spacing, colour, type weight on the confirm step |
| `month` confirmed or closed | missing-document summary (`1 pagamento com documento faltante` in `text-margem` when N=1); `Falta o extrato de N conta(s)` when any active account lacks a statement; `h2` Recebimentos, Pagamentos, Documentos sem casamento and their rows as today’s band; no `h2` `Confirmar contas para fechamento`; closed: `[data-stamp="closed"]` `Mês fechado` and payment rows even if the flag is false | confirm step absent; movement sections after Contas bancárias in today’s order | spacing, colour, type weight (existing month) |

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

These rows are the bar I build under — approving the checklist is enough for that. Writing them into `.cursor/rules/rails.mdc` needs an explicit yes, and it lands as its own commit before the build. Without one I build under them and leave the file alone.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at its own layer **and** one request spec at HTTP | one asserted case per enumerated member at its own layer; status and who may call at the boundary | follow |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` names the level and the sampling rule
- `Month#accounts_confirmed` and confirm-when-closed are decisions; closest analogue: `Month#close_for_send` / `reopen` in `spec/models/month_spec.rb` plus `spec/requests/months_spec.rb`
- Unconfirmed match/exception/return 404 is a controller guard reached over HTTP — request spec; if the guard is a named method on Month (e.g. `movements_visible?`), also a model example per state
- HTML copy and section order are view decisions; this repo has no view specs — request specs on `GET` / `POST` `months/show`
- System specs are not required: every named observation is HTML, status, a column, or a file read

Cost: request examples for C1–C11, C13–C19; model examples for C10, C12, C22 and confirm-when-closed; file-read examples for C20–C21.

## Checks

Criteria 1–22 map to C1–C22. Unresolved 1–2 stay at the transcribed heading, button, summary, and backfill.

### S1 - Unconfirmed GET hides movements · 4 files · 100 KB · ~25k

**C1** - Given a signed-in coordinator of the focused organization, open Month `2026-05` with `accounts_confirmed` false, and one active BankAccount `Conta Principal` with no statement, when `GET /months/2026-05` runs, then the status is `200`, the body includes `h2` `Contas bancárias`, includes `h2` `Confirmar contas para fechamento` after that bank section, includes a submit whose text is `Iniciar fechamento` posting to `/months/2026-05/account_confirmation`, includes `Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.`, and includes neither `h2` `Recebimentos` nor `h2` `Pagamentos` nor `h2` `Documentos sem casamento`. There is no `li[data-row="inflow"]`, `li[data-row="payment"]`, or `li[data-row="pool-document"]`. The summary does not include `pagamento com documento faltante`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed GET hides movements and shows confirm step"`

**C2** - Given that same unconfirmed month, when `POST /months/2026-05/bank_statements` runs with that account’s id and the BB May 2026 fixture spreadsheet and no `pdf`, then the status is `302` to `/months/2026-05`, one BankStatement persists for that pair, that statement has a Payment of `15500` cents (the fixture tarifa), `accounts_confirmed` stays false, and the following GET still matches criterion 1’s heading absences and has no payment/inflow/pool rows. That account’s Situação text is exactly `Presente`.
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST statement on unconfirmed month keeps flag false and hides payments"`

**C3** - Given two active accounts `Conta Alfa` (Falta) and `Conta Principal` (Presente), month unconfirmed, when `GET /months/2026-05` runs, then the `Confirmar contas para fechamento` section includes both names in the same order as the bank ledger (`Conta Alfa` then `Conta Principal`), includes `Falta` and `Presente` on those rows, the Falta label in that section is `text-margem`, and `Iniciar fechamento` is enabled.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed confirm step lists Alfa then Principal with Falta in margem"`

**C4** - Given the organization has no active BankAccount and Month `2026-05` is unconfirmed, when that GET runs, then the body includes `Nenhuma conta bancária ativa`, includes `h2` `Confirmar contas para fechamento` and `Iniciar fechamento`, and still omits the three movement `h2`s.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed GET with no active accounts still shows confirm step"`

**C5** - Given criterion 2’s unconfirmed month whose only missing-document Payment is that tarifa, when that GET runs, then the summary includes `Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.`, does not include `1 pagamento com documento faltante`, and there is still no `li[data-row="payment"]`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed GET with tarifa uses insert-statements summary not missing-document count"`

### S2 - Confirmation persists on Month · 5 files · 90 KB · ~22k

**C6** - Given criterion 2’s unconfirmed Presente month, when `POST /months/2026-05/account_confirmation` runs with no body fields, then the status is `302` to `/months/2026-05`, that Month’s `accounts_confirmed` is true, and the following GET is `200` with `[data-toast-kind="success"]` text `Pronto.`, with `h2` `Recebimentos`, `Pagamentos`, and `Documentos sem casamento`, with no `h2` `Confirmar contas para fechamento`, with summary `1 pagamento com documento faltante` in `text-margem`, and with a `li[data-row="payment"]` whose amount is `R$ 155,00`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST account_confirmation reveals movements and Pronto toast"`
Proof: `bin/rspec spec/models/month_spec.rb -e "confirm_accounts on open month sets accounts_confirmed true"`

**C7** - Given criterion 3’s mixed Presente/Falta unconfirmed month, when that POST runs, then `accounts_confirmed` is true, the following GET lists movements from `Conta Principal`, still includes `Falta o extrato de 1 conta ativa`, and `Conta Alfa` Situação text is exactly `Falta`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST account_confirmation with mixed Falta keeps Alfa Falta and lists Principal movements"`

**C8** - Given `accounts_confirmed` is already true, when that POST runs again, then the status is `302`, `accounts_confirmed` stays true, `organization.months.where(year_month: "2026-05").count` stays `1`, and the following GET still has the movement `h2`s and `Pronto.`
Proof: `bin/rspec spec/requests/months_spec.rb -e "second POST account_confirmation is idempotent"`

**C9** - Given Month `2026-05` is closed, `accounts_confirmed` is false, and a Payment exists for it, when `GET /months/2026-05` runs, then the status is `200`, `[data-stamp="closed"]` is `Mês fechado`, there is no `h2` `Confirmar contas para fechamento`, and a `li[data-row="payment"]` is present.
Proof: `bin/rspec spec/requests/months_spec.rb -e "closed GET shows movements even when accounts_confirmed is false"`

**C10** - Given that closed month, when `POST /months/2026-05/account_confirmation` runs, then the status is `422`, `[data-notice="error"]` is `Mês fechado`, and `accounts_confirmed` stays false.
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST account_confirmation on closed month returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/month_spec.rb -e "confirm_accounts refuses when closed"`

### S3 - Replace after agreement keeps lists · 3 files · 25 KB · ~6k

**C11** - Given a confirmed open month whose statement has both PDF and spreadsheet, when `POST /months/2026-05/bank_statements` runs with a different valid spreadsheet and without `pdf`, then one BankStatement remains, `accounts_confirmed` stays true, and the following GET has no `h2` `Confirmar contas para fechamento` and still has `h2` `Pagamentos`.
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST replace after confirmation keeps accounts_confirmed and Pagamentos"`

**C12** - When `Month.open` persists `2026-06` for that organization, then that row’s `accounts_confirmed` is false.
Proof: `bin/rspec spec/models/month_spec.rb -e "Month.open leaves accounts_confirmed false"`

### S4 - Match gate; close-for-send unchanged · 6 files · 50 KB · ~12k

**C13** - Given an unconfirmed month that already has a Payment, when `POST /months/2026-05/matches` runs with that `payment_ids[]` and a valid unmatched `supporting_document_ids[]`, then the status is `404` and no Match is persisted.
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match on unconfirmed month returns 404"`

**C14** - Given that Payment, when `POST /months/2026-05/payments/{id}/document_exception` runs with `kind` `bank_fee`, then the status is `404` and the Payment is still missing-document.
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST document_exception on unconfirmed month returns 404"`

**C15** - Given an unconfirmed month and a SupportingDocument whose `month_id` is that Month and `match_id` is nil, when `POST /months/2026-05/supporting_documents/{id}/return` runs, then the status is `404` and `month_id` is unchanged.
Proof: `bin/rspec spec/requests/month_returns_spec.rb -e "POST return on unconfirmed month returns 404"`

**C16** - Given criterion 6’s following GET and that tarifa still missing-document, then that `li[data-row="payment"]` includes `Resolver`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "confirmed GET missing-document payment includes Resolver"`

**C17** - Given that confirmed month, an unmatched SupportingDocument, and that tarifa, when `POST /months/2026-05/matches` runs with those ids, then the status is `302` and one Match persists (existing 1:1 rules).
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match on confirmed month persists 302"`

**C18** - Given an unconfirmed open month with at least one active account Falta, when `POST /months/2026-05/close` runs, then the status is `422`, `[data-notice="error"]` is `Importe o extrato de cada conta ativa`, and `closed` stays false.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed close with Falta still Importe o extrato"`

**C19** - Given an unconfirmed open month where every active account is Presente and a Payment is missing-document, when `POST /months/2026-05/close` runs, then the status is `422`, `[data-notice="error"]` is `Há documento faltante`, and `closed` stays false.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed close with missing document still Ha documento faltante"`

### S5 - Binding month wireframe, glossary, backfill · 4 files · 40 KB · ~10k

**C20** - `.specs/features/visual-identity/design.md` section `month` states: while `accounts_confirmed` is false and the month is open, the summary is `Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.` (not the missing-document count); after Contas bancárias a step `Confirmar contas para fechamento` lists each active account’s name with `Presente` or `Falta` (`Falta` in `margem`) in ledger name order and submit `Iniciar fechamento`; `Recebimentos`, `Pagamentos`, and `Documentos sem casamento` are omitted. After confirmation (or while closed), the missing-document summary and those three sections match today’s band; the confirm step is absent. `visual-identity` month checks follow this.
Proof: `bin/rspec spec/docs/visual_identity_month_bank_rows_spec.rb -e "visual-identity month confirms accounts before movements"`

**C21** - `GLOSSARY.md` defines **Accounts confirmation**: the coordinator’s persisted agreement on a Month that the statement set is ready to work as movements; until then those three lists stay off the month page and there is no movement to match; upload still writes the BankStatement; replacing a statement does not clear it; not session. Avoid: Presente (per-account file), close-for-send.
Proof: `bin/rspec spec/docs/glossary_spec.rb -e "GLOSSARY defines Accounts confirmation"`

**C22** - After the migration runs, an existing Month that is `closed` or that already has a BankStatement has `accounts_confirmed` true; an existing Month with neither stays false. New `Month.open` stays false (C12).
Proof: `bin/rspec spec/models/month_spec.rb -e "accounts_confirmed backfill closed or with statement true else false"`

## Swept

- validation: C10 — confirm refused when `closed` with existing `Mês fechado`; confirm POST has no input fields
- failure modes: C10, C13–C15, C18, C19 — closed confirm; unconfirmed match/exception/return; close blockers unchanged
- idempotency and retry: C8 — a second confirm POST does not insert a Month and leaves `accounts_confirmed` true
- authorization: existing — coordinator + focus; submitter `404`; foreign month `404`
- concurrency and ordering: n/a — overlapping confirms both want true; the write is monotonic. Import does not clear the flag (C11). Unique Month `(organization_id, year_month)` is existing
- data lifecycle: C12, C22 — new `Month.open` is false; backfill Unresolved 2
- external-dependency failure: n/a — no Drive/SEFAZ/mail on this path
- state transitions: C2, C6, C7, C9, C11, C12 — unconfirmed / confirmed / closed overlay
- observability: C6, C8 — success toast `Pronto.`; the source names no log or metric

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| unconfirmed GET bands (4) | no statement C1 · after import still hidden C2/C5 · mixed Falta/Presente C3 · no active accounts C4 | - |
| confirm POST outcomes (4) | open Presente 302 C6 · mixed 302 C7 · already true idempotent C8 · closed 422 C10 | - |
| closed overlay (1) | GET lists even if flag false C9 | - |
| replace / new month (2) | replace keeps flag C11 · `Month.open` false C12 | - |
| unconfirmed movement POSTs (3) | match C13 · exception C14 · return C15 | - |
| confirmed match path (2) | Resolver visible C16 · match 302 C17 | - |
| close-for-send copy unchanged (2) | missing statement C18 · missing document C19 | - |
| designed screens this cut binds (1) | `month` C1–C7, C9, C16, C20 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `setup`, `documents` — out of scope |
| `month` visual (3 properties) | — | spacing, colour, type weight on the confirm step |
| backfill members (3) | closed true C22 · has BankStatement true C22 · neither false C22 | - |

- Claims naming a status code, route or response shape: C1, C2, C6, C8, C9, C10, C11, C13, C14, C15, C17, C18, C19 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~25k (`show.html.erb` + `months_spec.rb` 74 KB counted once) + S2 ~22k (same show + months_spec not paid twice; `month.rb` + new confirm controller) + S3 ~6k (`bank_statements_spec`) + S4 ~12k (matches / exceptions / returns specs) + S5 ~10k (`design.md` + `GLOSSARY.md` + docs specs) = ~75k unique-file floor. All five slices stay under 150k and share the month page. No split. One batch.

- Where the boundary fell:
- What the user settled mid-build: heading `Confirmar contas para fechamento`; submit `Iniciar fechamento`; unconfirmed summary is the insert-statements sentence, not the missing-document count (already in the checks). Prototype is not production.
- What was abandoned:
