# Confirm spreadsheet and discard never-sent month

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/confirm-spreadsheet-and-discard-never-sent-month.md` marks screens `month` and `home` binding through `.specs/features/visual-identity/design.md` (criteria 7 and 18).

Sources:

- `.tasks/confirm-spreadsheet-and-discard-never-sent-month.md` - criteria 1–18, the state diagram, the sweep, two doors, Unresolved empty. Nothing under Unresolved is settled while building
- https://github.com/gutors/ai-accounting-assistant/issues/116 - **binding for this slice**: disabled `Iniciar fechamento` plus notice `Inclua o extrato planilha de pelo menos uma conta bancária.` until at least one spreadsheet; mixed Falta/Presente still allowed; close-for-send unchanged; home `Excluir` last column; Turbo `Excluir este fechamento?`; only `Aberto` never closed-for-send (`month_folder_id` remains after Reabrir); DELETE destroys statements/movements, nullifies pool `month_id`, no writer; success `/` `Pronto.`; ineligible `422` `Só é possível excluir um fechamento aberto que nunca foi enviado.`; coordinator only
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent umbrella
- https://github.com/gutors/ai-accounting-assistant/issues/110 / `.tasks/confirm-accounts-before-movements.md` - continue-anyway with mixed Falta; this cut amends C1/C4 enabled submit and empty-account confirm
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screens `month` and `home`. Opened as a file in the repo. Today’s `month` ASCII still draws `[Iniciar fechamento]` enabled with no disabled/notice rule; today’s `home` Meses ledger is three columns with no `Excluir`. C7 and C18 amend those sections
- `app/models/month.rb` - `confirm_accounts` currently any open Month; `bank_statements` `dependent: :restrict_with_exception`; `reopen` keeps `month_folder_id`
- `app/views/months/show.html.erb`, `app/views/organizations/show.html.erb`, `MonthsController#account_confirmation`

## Out of scope

- Deleting a Month that is closed or was reopened after close-for-send — C9, C10, C14, C15
- Requiring every active account Presente before `Iniciar fechamento` — mixed still confirms (C3, C5); #110 continue-anyway
- Changing `Month#close_blocker` (`Importe o extrato de cada conta ativa`, `Há documento faltante`)
- Removing the Drive month folder — never-sent has none; writer is not called (C13)
- Prototype `/prototypes/confirm_accounts`
- Clearing `accounts_confirmed` without discarding the Month
- Settling Unresolved — none

## Landing

Touches `Month#confirm_accounts` so an open Month also needs at least one BankStatement with a spreadsheet, the unconfirmed month page (disabled submit + GET/POST notice), `DELETE /months/:year_month` for never-sent open Months (`closed` false and `month_folder_id` blank), home `Meses` last-column `Excluir`, and `design.md` sections `month` and `home`. Reuses `require_coordinator_organization`, `redirect_success` (`Pronto.`), `find_month` 404, home `422` re-render (`load_home` + `[data-notice="error"]`), `button_to` / `data-turbo-confirm`, and existing `close_blocker`.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Never-sent is `closed` false and `month_folder_id` blank | No new column. Reopen already keeps `month_folder_id`. Discard allowed only when both hold | `closed_at` that survives reopen — extra migration; #116 named the existing folder id. `!closed?` alone — a reopened month would be deletable after Drive had a `{YYYY-MM}` |
| Discard is `DELETE /months/:year_month` | HTML form; success `302` `/`; ineligible `422` with `Só é possível excluir um fechamento aberto que nunca foi enviado.`; missing `404`. No Drive call | `POST /months/:year_month/discard` — #116 named DELETE. Soft-delete / `discarded_at` — the unique `year_month` must free so `Abrir mês` works again (C12) |
| Confirm spreadsheet means a BankStatement with `spreadsheet` attached | `Month#spreadsheet_present?` is `bank_statements.joins(:spreadsheet_attachment).exists?`. GET and `confirm_accounts` share it | Infer from any BankStatement row (`Presente` without a file) — `plant_month` already creates that row; #116 named a spreadsheet |
| Discard keeps `bank_statements` `restrict_with_exception` | `Month#discard_never_sent` destroys statements then the Month, under `with_lock` | `dependent: :destroy` on `bank_statements` — any `Month#destroy` would wipe movements; restrict stays the safety net for other callers |

- Nothing else in this change is hard to reverse. Requiring a spreadsheet on the existing confirm POST is a condition on that write, not a new contract

## Screens (ui)

Opened `.specs/features/visual-identity/design.md` sections `month` and `home` as files. Today’s month ASCII still enables `Iniciar fechamento` with no spreadsheet notice. Today’s home Meses ledger is `Mês | AAAA-MM | Status` with no action column. Arrangement below is what C1–C3, C7–C11, C18 plus the amended sections require.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `month` unconfirmed, no spreadsheet | `[data-notice="error"]` `Inclua o extrato planilha de pelo menos uma conta bancária.`; confirm `h2` `Confirmar contas para fechamento`; submit `Iniciar fechamento` posting to `/months/:year_month/account_confirmation` is `disabled`; no `h2` `Recebimentos`, `Pagamentos`, `Documentos sem casamento`; empty accounts still `Nenhuma conta bancária ativa` plus that notice and disabled submit | notice uses the existing `[data-notice="error"]` slot after the summary and before `Contas bancárias`; confirm step stays after the bank section; submit stays in that step, disabled rather than omitted | spacing, colour, type weight on the notice and disabled submit |
| `month` unconfirmed, at least one Presente | `Iniciar fechamento` is not `disabled`; body does not include `Inclua o extrato planilha de pelo menos uma conta bancária.`; mixed Falta still listed | confirm sheet unchanged (Nome \| Situação then primary submit) | spacing, colour, type weight |
| `home` coordinator Meses | ledger columns `Mês`, `AAAA-MM`, `Status`, then a last action column; `li[data-row="month"]` with `Aberto` and never-sent (`month_folder_id` blank) includes `Excluir` posting `DELETE /months/:year_month` with `data-turbo-confirm` `Excluir este fechamento?`; `Fechado` and reopened `Aberto` (`month_folder_id` present) omit `Excluir`; empty list `Nenhum mês aberto` | `Excluir` is the last cell of the row, after Status; heading row has an empty last column (no fourth name); year_month desc list unchanged | spacing, colour, type weight on the action column |

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
- `Month#confirm_accounts` gains a spreadsheet-present branch; closest analogue: `confirm_accounts refuses when closed` in `spec/models/month_spec.rb` plus `spec/requests/months_spec.rb`
- Discard (`closed` / `month_folder_id` / destroy) is a Month state transition reached over HTTP — model examples per refuse/success member plus request specs for status and who may call
- `MonthsController#find_month` 404 is existing instrumentation; C16 asserts it at HTTP
- HTML copy, disabled submit, and `Excluir` column are view decisions; this repo has no view specs — request specs on `GET /months/:year_month` and `GET /`
- System specs are not required: every named observation is HTML, status, a column, or a file read

Cost: request examples for C1–C6, C8–C17; model examples for confirm-without-spreadsheet, confirm-with-spreadsheet, discard success, discard-when-closed, discard-when-folder-id; file-read examples for C7 and C18.

## Checks

Criteria 1–18 map to C1–C18. Unresolved is empty.

### S1 - Confirm needs a spreadsheet · 7 files · 159 KB · ~40k

**C1** - Given a signed-in coordinator of the focused organization, open Month `2026-05` with `accounts_confirmed` false, and one active BankAccount `Conta Principal` with no statement, when `GET /months/2026-05` runs, then the status is `200`, `[data-notice="error"]` is `Inclua o extrato planilha de pelo menos uma conta bancária.`, the confirm-step submit `Iniciar fechamento` posting to `/months/2026-05/account_confirmation` is present and `disabled`, `h2` `Confirmar contas para fechamento` is present, and the three movement `h2`s are absent.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed GET hides movements and shows confirm step"`

**C2** - Given that organization has no active BankAccount and Month `2026-05` is unconfirmed, when that GET runs, then the body includes `Nenhuma conta bancária ativa`, includes that same `[data-notice="error"]` text, and `Iniciar fechamento` is `disabled`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed GET with no active accounts still shows confirm step"`

**C3** - Given two active accounts `Conta Alfa` (Falta) and `Conta Principal` (Presente), month unconfirmed, when that GET runs, then `Iniciar fechamento` is not `disabled`, and the body does not include `Inclua o extrato planilha de pelo menos uma conta bancária.`
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed confirm step lists Alfa then Principal with Falta in margem"`

**C4** - Given criterion 1’s unconfirmed month, when `POST /months/2026-05/account_confirmation` runs, then the status is `422`, `[data-notice="error"]` is `Inclua o extrato planilha de pelo menos uma conta bancária.`, and that Month’s `accounts_confirmed` stays false.
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST account_confirmation without spreadsheet returns 422"`
Proof: `bin/rspec spec/models/month_spec.rb -e "confirm_accounts refuses without a spreadsheet statement"`

**C5** - Given criterion 3’s mixed unconfirmed month, when that POST runs, then the status is `302` to `/months/2026-05`, `accounts_confirmed` is true, and the following GET has `h2` `Pagamentos` and no `h2` `Confirmar contas para fechamento`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST account_confirmation with mixed Falta keeps Alfa Falta and lists Principal movements"`
Proof: `bin/rspec spec/models/month_spec.rb -e "confirm_accounts on open month sets accounts_confirmed true"`

**C6** - Given Month `2026-05` is closed, when that POST runs, then the status is `422`, `[data-notice="error"]` is `Mês fechado`, and `accounts_confirmed` is unchanged.
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST account_confirmation on closed month returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/month_spec.rb -e "confirm_accounts refuses when closed"`

**C7** - `.specs/features/visual-identity/design.md` section `month` states: while the confirm step is shown and no account has a spreadsheet statement, `Iniciar fechamento` is disabled and the notice is `Inclua o extrato planilha de pelo menos uma conta bancária.`; with at least one Presente it stays enabled (mixed Falta allowed). Close-for-send still requires every active account’s statement.
Proof: `bin/rspec spec/docs/visual_identity_month_bank_rows_spec.rb -e "visual-identity month disables confirm without a spreadsheet"`

### S2 - Discard never-sent from home · 8 files · 80 KB · ~20k

**C8** - Given a signed-in coordinator, Month `2026-05` open, `closed` false, `month_folder_id` nil, when `GET /` runs, then that `li[data-row="month"]` includes `Aberto`, includes a control whose text is `Excluir` posting `DELETE /months/2026-05`, and that form’s `data-turbo-confirm` is `Excluir este fechamento?`. The Meses heading row is `Mês`, `AAAA-MM`, `Status`, then an empty last column; `Excluir` is the last cell of the month row, after Status.
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "never-sent open month row includes Excluir with turbo confirm"`

**C9** - Given Month `2026-05` is closed (`closed` true), when `GET /` runs, then that month row includes `Fechado` and does not include `Excluir`.
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "closed month row says Fechado"`

**C10** - Given Month `2026-05` is open (`closed` false) and `month_folder_id` is `drive-folder`, when `GET /` runs, then that month row includes `Aberto` and does not include `Excluir`.
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "reopened month row omits Excluir"`

**C11** - Given Month `2026-05` is open, `accounts_confirmed` true, `month_folder_id` nil, when `GET /` runs, then that month row includes `Excluir` as in criterion 8.
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "confirmed never-sent month row includes Excluir"`

**C12** - Given a never-sent open Month `2026-05` (`month_folder_id` nil) with no BankStatement, when `DELETE /months/2026-05` runs, then the status is `302` to `/`, `organization.months.where(year_month: "2026-05").count` is `0`, the following `GET /` has `[data-toast-kind="success"]` text `Pronto.` and includes `Nenhum mês aberto`, and a following `POST /months` with `year_month` `2026-05` persists one Month and is `302` to `/months/2026-05`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "DELETE never-sent empty month redirects home and frees year_month"`
Proof: `bin/rspec spec/models/month_spec.rb -e "discard_never_sent destroys an open month with blank month_folder_id"`

**C13** - Given a never-sent open Month `2026-05` that has a BankStatement, a Match, and a SupportingDocument whose `month_id` is that Month, when `DELETE /months/2026-05` runs, then the Month is gone, no BankStatement, Payment, Inflow, or Match remains for it, that document’s `month_id` is nil, `PackageArchiveWriter` is not invoked, and the status is `302` to `/`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "DELETE never-sent month destroys statements matches and nullifies documents"`

**C14** - Given Month `2026-05` is closed, when `DELETE /months/2026-05` runs, then the status is `422`, `[data-notice="error"]` is `Só é possível excluir um fechamento aberto que nunca foi enviado.`, and the Month still exists and stays closed.
Proof: `bin/rspec spec/requests/months_spec.rb -e "DELETE closed month returns 422"`
Proof: `bin/rspec spec/models/month_spec.rb -e "discard_never_sent refuses when closed"`

**C15** - Given Month `2026-05` is open with `month_folder_id` `drive-folder`, when that DELETE runs, then the status is `422` with that same notice, and the Month still exists.
Proof: `bin/rspec spec/requests/months_spec.rb -e "DELETE reopened month returns 422"`
Proof: `bin/rspec spec/models/month_spec.rb -e "discard_never_sent refuses when month_folder_id is present"`

**C16** - When `DELETE /months/2026-13` or `DELETE /months/2026-05` on a focused organization with no such Month runs, then the status is `404` and no Month is deleted.
Proof: `bin/rspec spec/requests/months_spec.rb -e "DELETE invalid or missing month returns 404"`

**C17** - Given a signed-in submitter of the focused organization and a never-sent Month `2026-05`, when `GET /` runs, then the body does not include `Excluir`; when `DELETE /months/2026-05` runs, then the status is `404` and the Month still exists.
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home omits Excluir"`
Proof: `bin/rspec spec/requests/months_spec.rb -e "submitter DELETE month returns 404"`

**C18** - `.specs/features/visual-identity/design.md` section `home` (coordinator) states: the `Meses` ledger columns are `Mês | AAAA-MM | Status` then a last action column; `Excluir` is on `Aberto` rows that have never been closed-for-send, with Turbo confirm `Excluir este fechamento?`; `Fechado` and reopened `Aberto` rows omit it.
Proof: `bin/rspec spec/docs/home_open_month_list_spec.rb -e "visual-identity home Meses has Excluir on never-sent Aberto rows"`

## Swept

- validation: C1, C4 — confirm refused with no spreadsheet; C14, C15 — discard refused unless `!closed && month_folder_id` blank
- failure modes: C4, C6, C14, C15, C16 — confirm/discard `:base` notices; missing month `404`
- idempotency and retry: C16 — a second DELETE after success is `404`; C5 — mixed confirm still succeeds once; existing second confirm POST with a spreadsheet is unchanged
- authorization: C17 and existing — coordinator + focus; submitter `404`
- concurrency and ordering: existing — `Month` mutations take `with_lock`; unique `(organization_id, year_month)` so a DELETE then `Month.open` of the same key is C12, not a second overlapping row. Overlapping DELETEs of a gone row are `404` via `find_month`
- data lifecycle: C12, C13 — Month row deleted; statements/payments/inflows/matches destroyed; supporting `month_id` nullified; Active Storage blobs on those statements go with them; Drive untouched
- external-dependency failure: C13 — writer is not invoked, so Drive errors cannot occur on this path
- state transitions: C4, C5, C12–C15 and the task States diagram
- observability: C12 — success toast `Pronto.`; C1, C4, C14 — error notice; the source names no log or metric

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| unconfirmed GET confirm enablement (3) | no statement disabled C1 · no active accounts disabled C2 · mixed enabled C3 | - |
| confirm POST outcomes (3) | no spreadsheet 422 C4 · mixed 302 C5 · closed 422 C6 | - |
| home Excluir visibility (4) | never-sent open C8 · closed omit C9 · reopened omit C10 · confirmed never-sent C11 | - |
| home Meses arrangement (2) | empty last heading column C8 · `Excluir` last cell after Status C8 | - |
| DELETE outcomes (7) | empty never-sent 302 C12 · with data 302 C13 · closed 422 C14 · folder id 422 C15 · invalid year_month 404 C16 · missing 404 C16 · submitter 404 C17 | - |
| designed screens this cut binds (2) | `month` C1–C7 · `home` C8–C12, C18 | - |
| visual-identity screens this cut does not bind (4) | — | `login`, `denied`, `setup`, `documents` — out of scope |
| `month` visual (3 properties) | — | spacing, colour, type weight on the notice and disabled submit |
| `home` visual (3 properties) | — | spacing, colour, type weight on the Meses action column |

- Claims naming a status code, route or response shape: C1, C4, C5, C6, C8, C12, C13, C14, C15, C16, C17 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~40k (`months_spec.rb` 87 KB counted once; `month.rb` / `show.html.erb` / `design.md`) + S2 ~20k (same `month.rb` / `months_controller` / `design.md` not paid twice; home ERB + `organizations_spec`) = ~55k unique-file floor. Both slices stay under 150k and share Month + HTTP. No split. One batch.

- Where the boundary fell:
- What the user settled mid-build:
- What was abandoned:
