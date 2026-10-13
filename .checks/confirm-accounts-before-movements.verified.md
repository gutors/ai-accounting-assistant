# Confirm accounts before movements Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 4c92517..0b4b3a5
**Round**: 2 - full
**Verifier**: independent sub-agent (author != verifier)

Round 1 FAIL at `722f9e6` (two-column `Nome` | `Situação` unasserted; `confirm_accounts` open persist not at model layer) is closed at `0b4b3a5`. Full playbook re-run on every check, not only those two gaps.

## Binding sources

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.specs/features/visual-identity/design.md` section `month` | yes - file in repo (`### \`month\` — GET /months/:year_month`, lines 278–371) | none vs C1–C22 copy (heading `Confirmar contas para fechamento`, submit `Iniciar fechamento`, insert-statements summary, two-column `Nome` \| `Situação`, omit three movement `h2`s while unconfirmed open, closed overlay lists movements) | none selector-reachable for this cut |
| https://github.com/gutors/ai-accounting-assistant/issues/110 | yes - `gh issue view 110` (WebFetch 404 on private URL) | none on the slice (upload persists; hide lists until confirm; Month not session; replace does not hide; match gate; close-for-send unchanged). Issue CTA was continue-anyway; checks and amended `design.md` use `Iniciar fechamento` as the later transcribed decision named in the checklist Sources | matching screen itself (#111) is out of this cut; POST gate is C13–C15 |

Screens enumerated (selector-reachable, function/state): unconfirmed summary sentence; `h2` Contas bancárias then confirm step; two-column confirm head `Nome` \| `Situação` then rows then submit `Iniciar fechamento` to `/months/:year_month/account_confirmation`; Presente/Falta in ledger name order with Falta in `margem`; empty `Nenhuma conta bancária ativa` plus confirm + submit; movement `h2`s and `data-row` inflow/payment/pool-document **absent** (not empty lists); confirmed/closed missing-document summary in `margem`, `Falta o extrato…`, three movement sections, no confirm `h2`; closed `[data-stamp="closed"]` `Mês fechado`. Those have checks (C3 now asserts the two-column head). Visual unproven is enumerated (spacing, colour, type weight) — not a blanket.

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | unconfirmed GET 200; bank then confirm `h2`; submit `Iniciar fechamento` to `/months/2026-05/account_confirmation`; insert-statements summary; no movement `h2`s or rows; no missing-document sentence | example passed at 0b4b3a5 | `spec/requests/months_spec.rb:1726` `have_http_status(:ok)`; `:1730` bank index `<` confirm; `:1731–1734` form action + submit value; `:1736` insert sentence; `:1737–1743` absences | PASS |
| C2 | statement POST 302; persists 15500; flag false; GET still hides movements; Situação `Presente` | passed | `spec/requests/bank_statements_spec.rb:482` `:found`; `:487` `amount_cents: 15500`; `:488` `accounts_confirmed` false; `:492–499` heading/row absences + `Presente` | PASS |
| C3 | Alfa then Principal; Falta/Presente; Falta `text-margem`; submit enabled; two-column `Nome` \| `Situação` | passed | `spec/requests/months_spec.rb:1761` head `["Nome", "Situação"]`; `:1763–1764` rows `Alfa/Falta` then `Principal/Presente`; `:1771` `.text-margem` `== "Falta"`; `:1773–1774` submit not disabled | PASS |
| C4 | no active accounts: empty copy + confirm + submit; no movement `h2`s | passed | `spec/requests/months_spec.rb:1784–1790` | PASS |
| C5 | tarifa unconfirmed: insert summary, not `1 pagamento com documento faltante`; no payment row | passed | `spec/requests/months_spec.rb:1802–1804` | PASS |
| C6 | confirm POST 302; flag true; GET Pronto. toast; movement `h2`s; no confirm `h2`; summary `1 pagamento com documento faltante` in `text-margem`; payment `R$ 155,00`; model open persist | both examples passed | `spec/requests/months_spec.rb:1818–1819` found + redirect; `:1820` true; `:1824–1825` toast success `Pronto.`; `:1827–1832` headings + `.text-margem`; `:1833–1834` payment amount; `spec/models/month_spec.rb:21–22` errors empty + `accounts_confirmed` true | PASS |
| C7 | mixed confirm: flag true; Principal movements; `Falta o extrato de 1 conta ativa`; Alfa Situação `Falta` | passed | `spec/requests/months_spec.rb:1847` true; `:1850` payment rows; `:1851` Falta sentence; `:1853` situation `Falta`. Weak: `:1849` `include("Conta Principal")` is also the bank ledger | PASS |
| C8 | second POST 302; flag true; one Month; movement `h2`s; Pronto. | passed | `spec/requests/months_spec.rb:1865–1874` | PASS |
| C9 | closed GET 200; stamp `Mês fechado`; no confirm `h2`; payment row | passed | `spec/requests/months_spec.rb:1886–1890` | PASS |
| C10 | closed confirm POST 422 `[data-notice="error"]` `Mês fechado`; flag false; model `confirm_accounts` same | both examples passed | `spec/requests/months_spec.rb:1903–1905` `:unprocessable_content` + `error_notice_text` (helper `spec/support/page_helpers.rb:7–12` is `data-notice="error"`) `== "Mês fechado"`; `spec/models/month_spec.rb:32–33` `:base` includes `Mês fechado` | PASS |
| C11 | replace after confirm: one statement; flag true; no confirm `h2`; has Pagamentos | passed | `spec/requests/bank_statements_spec.rb:513–518` | PASS |
| C12 | `Month.open` 2026-06 `accounts_confirmed` false | passed | `spec/models/month_spec.rb:12` | PASS |
| C13 | unconfirmed match POST 404; no Match | passed | `spec/requests/matches_spec.rb:625–627` | PASS |
| C14 | unconfirmed document_exception 404; still missing-document | passed | `spec/requests/document_exceptions_spec.rb:403–404` | PASS |
| C15 | unconfirmed return 404; `month_id` unchanged | passed | `spec/requests/month_returns_spec.rb:119–120` | PASS |
| C16 | confirmed missing-document payment includes `Resolver` | passed | `spec/requests/months_spec.rb:1920` | PASS |
| C17 | confirmed match POST 302; one Match | passed | `spec/requests/matches_spec.rb:639–640` | PASS |
| C18 | unconfirmed close Falta: 422 `Importe o extrato de cada conta ativa`; not closed | passed | `spec/requests/months_spec.rb:1931–1933` | PASS |
| C19 | unconfirmed close missing-document: 422 `Há documento faltante`; not closed | passed | `spec/requests/months_spec.rb:1944–1946` | PASS |
| C20 | `design.md` month section + visual-identity checks state the confirm-before-movements band | passed | `spec/docs/visual_identity_month_bank_rows_spec.rb:28–51` file includes listed phrases including `two-column ledger (\`Nome\`, \`Situação\`)` at `:36` | PASS |
| C21 | GLOSSARY **Accounts confirmation** | passed | `spec/docs/glossary_spec.rb:8–18` | PASS |
| C22 | backfill closed or with statement true; neither false | passed | `spec/models/month_spec.rb:48–50` three members; SQL is `AddAccountsConfirmedToMonths::BACKFILL_SQL` at `:46` | PASS |

## Coverage (recomputed)

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| unconfirmed GET bands (4) | no statement C1 · after import C2/C5 · mixed C3 · no active C4 | - |
| confirm POST outcomes (4) | open Presente 302 C6 · mixed C7 · idempotent C8 · closed 422 C10 | - |
| closed overlay (1) | GET lists if flag false C9 | - |
| replace / new month (2) | C11 · C12 | - |
| unconfirmed movement POSTs (3) | C13 · C14 · C15 | - |
| confirmed match path (2) | C16 · C17 | - |
| close-for-send copy (2) | C18 · C19 | - |
| designed screens this cut binds (1) | `month` C1–C7, C9, C16, C20; two-column head C3 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `setup`, `documents` |
| `month` visual (3 properties) | — | spacing, colour, type weight on the confirm step (enumerated) |
| backfill members (3) | closed C22 · BankStatement C22 · neither C22 | - |
| `confirm_accounts` branches (2) | closed refuse C10 model+HTTP · open persist model+HTTP C6 | - |

Landing enumerations match the table (boolean on Month; POST confirm 302/`Pronto.`/closed 422; unconfirmed match/exception/return 404). No extra set hiding in Landing without a row.

Swept **existing** authorization: `MonthsController` `before_action :require_coordinator_organization` (`app/controllers/months_controller.rb:2`); `head :not_found unless coordinator_on_focus?` (`application_controller.rb:62`); `find_month` / `find_focused_month` scopes `focused_organization.months`. Constraint is in the code.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `Month#confirm_accounts` (`app/models/month.rb:89`) | own layer **and** HTTP; one case per member | closed: C10 both. open persist: HTTP C6 + model `confirm_accounts on open month sets accounts_confirmed true` |
| Decides, reached across a boundary | `find_month_with_visible_movements` (`application_controller.rb:112`) | HTTP (not a Month method) | C13–C15 unconfirmed 404; C17 confirmed 302. Guard is controller, matching the checklist “if named on Month” caveat |
| Decides, not reached across a boundary | `Month.open` default (`month.rb:32–34` leaves schema default) | own layer | C12 |
| Entry / view HTML | `months#show`, `account_confirmation`, `show.html.erb` | request spec | C1–C11, C16, C18, C19; C3 asserts two-column head |
| Instrumentation | bank_statement POST does not write the flag | consumer | C2, C11 |

All rows met.

## Faults injected

Scratch: `/tmp/tlc-verify-confirm-accounts-r2` at 0b4b3a5. Real-tree porcelain before/after matched (`M config/routes.rb`, untracked prototype/task/verified files). Scratch discarded.

| Mutation | Location | Killed |
|---|---|---|
| `movements_visible = true` | `app/views/months/show.html.erb` | yes — C1 expected confirm `h2`, got Recebimentos/Pagamentos/pool |
| confirm head `Nome`/`Situação` → `Banco`/`Status` | `app/views/months/show.html.erb` | yes — C3 expected `["Nome", "Situação"]` |
| skip `update!(accounts_confirmed: true)` | `app/models/month.rb` | yes — C6 model expected flag true |
| drop `if closed?` in `confirm_accounts` | `app/models/month.rb` | yes — C10 model expected `Mês fechado` on `:base` |
| skip unconfirmed `head :not_found` | `app/controllers/application_controller.rb` `find_month_with_visible_movements` | yes — C13 Match.count 0→1 |

No surviving mutant in the five surfaces. Cap 5; remaining proofs share those surfaces or are file-read (C20–C21). New surfaces from round-1 gaps (two-column head; open persist at model) were included.

## Gate

`bin/rspec` eight files, 24 `-e` names (C1–C22; C6 and C10 each have two proofs) — **24 passed, 0 failed** at `0b4b3a5`. Each named example appeared in the JSON run log as `passed`.
