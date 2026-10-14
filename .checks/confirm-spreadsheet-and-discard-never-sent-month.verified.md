# Confirm spreadsheet and discard never-sent month Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 182e7b9..HEAD (HEAD `41ecbfb`)
**Round**: 2 - scoped (fix `41ecbfb` + round-1 non-PASS; proofs re-run in full at HEAD)
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Home re-opened this round (C8 arrangement renegotiated). Task, issue #116, and screen `month` carried from `3ed93c7` after re-read against the same artifacts; no new contradiction.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.tasks/confirm-spreadsheet-and-discard-never-sent-month.md` | yes - file (carried from `3ed93c7`) | none vs C1–C18. Task criterion 8 omits heading/cell order; checklist C8 (renegotiated after round 1) follows design `home` | - |
| https://github.com/gutors/ai-accounting-assistant/issues/116 | yes - `gh issue view 116` (carried from `3ed93c7`) | none: “última coluna Excluir” is the control, not a fourth heading name | - |
| `.specs/features/visual-identity/design.md` screen `month` | yes - file (carried from `3ed93c7`) | none vs C1–C3, C7 | notice **position** (after summary, before `Contas bancárias`) still unasserted — carried note, not a FAIL |
| `.specs/features/visual-identity/design.md` screen `home` | yes - file (verified at `41ecbfb`) | none vs C8–C11, C18. ASCII `Mês \| AAAA-MM \| Status \|` unnamed last column; `Excluir` last after Status | none that a selector must reach; C8 now covers heading empty last cell and last-cell `Excluir` |

Screens table visual-unproven cells name spacing, colour, type weight per screen — enumerated, not a blanket.

## Checks

Proofs re-run at `41ecbfb`. One invocation (`ruby bin/rspec`; `bin/rspec` exits 127): 25 examples, 0 failed. Each named `-e` string matched (25 filters → 25 examples). Proofs live in `182e7b9..HEAD` (C9 name pre-existed; omit-`Excluir` assertions added in range).

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | unconfirmed GET: `200`, notice, disabled `Iniciar fechamento`, confirm `h2`, no movement `h2`s | `ruby bin/rspec spec/requests/months_spec.rb -e "unconfirmed GET hides movements and shows confirm step"` passed | `spec/requests/months_spec.rb:1726` `have_http_status(:ok)`; `:1735` `submit["disabled"] == "disabled"`; `:1736` notice text; `:1729` confirm `h2`; `:1738–1740` movement `h2`s absent | PASS |
| C2 | no active accounts: empty copy, same notice, disabled submit | `… -e "unconfirmed GET with no active accounts still shows confirm step"` passed | `spec/requests/months_spec.rb:1786` `Nenhuma conta bancária ativa`; `:1791` disabled; `:1792` same notice | PASS |
| C3 | mixed Falta/Presente: submit not disabled, no spreadsheet notice | `… -e "unconfirmed confirm step lists Alfa then Principal with Falta in margem"` passed | `spec/requests/months_spec.rb:1775` `submit["disabled"]` `be_nil`; `:1776` body does not include the notice | PASS |
| C4 | POST without spreadsheet `422`, flag stays false | request + `spec/models/month_spec.rb -e "confirm_accounts refuses without a spreadsheet statement"` passed | `spec/requests/months_spec.rb:1873` `:unprocessable_content`; `:1874` notice; `:1875` `accounts_confirmed == false`; `spec/models/month_spec.rb:33` `errors[:base]` includes the notice; `:34` flag false | PASS |
| C5 | mixed POST `302` `/months/2026-05`, confirmed, `Pagamentos`, no confirm `h2` | request + `… -e "confirm_accounts on open month sets accounts_confirmed true"` passed | `spec/requests/months_spec.rb:1852–1854` found + redirect + `accounts_confirmed == true`; `:1856–1857` `Pagamentos` present, confirm `h2` absent; `spec/models/month_spec.rb:24` `accounts_confirmed == true` | PASS |
| C6 | closed POST `422` `Mês fechado`, flag unchanged | request + `… -e "confirm_accounts refuses when closed"` passed | `spec/requests/months_spec.rb:1926–1928` unprocessable, notice `Mês fechado`, `accounts_confirmed == false`; `spec/models/month_spec.rb:43–44` | PASS |
| C7 | `design.md` `month` states disabled/notice/Presente/mixed/close-for-send | `ruby bin/rspec spec/docs/visual_identity_month_bank_rows_spec.rb -e "visual-identity month disables confirm without a spreadsheet"` passed | `spec/docs/visual_identity_month_bank_rows_spec.rb:58–63` includes disabled, notice, `at least one Presente`, `mixed Falta allowed`, close-for-send sentence | PASS |
| C8 | never-sent `Aberto` row: `Excluir` DELETE + turbo confirm; Meses heading `Mês`, `AAAA-MM`, `Status`, empty last column; `Excluir` last cell after Status | `ruby bin/rspec spec/requests/organizations_spec.rb -e "never-sent open month row includes Excluir with turbo confirm"` passed | `spec/requests/organizations_spec.rb:331` includes `Aberto`; `:332–335` DELETE form, `data-turbo-confirm` `Excluir este fechamento?`, text `Excluir`; `:336–337` heading children `["Mês", "AAAA-MM", "Status", ""]`; `:338–340` four cells, Status `Aberto`, delete form in last child | PASS (verified at `41ecbfb`) |
| C9 | closed row `Fechado`, no `Excluir` | `… -e "closed month row says Fechado"` passed | `spec/requests/organizations_spec.rb:393–396` `Fechado`, not `Excluir`, delete form nil | PASS |
| C10 | reopened `Aberto` (`month_folder_id` present) omits `Excluir` | `… -e "reopened month row omits Excluir"` passed | `spec/requests/organizations_spec.rb:352–354` `Aberto`, form nil, not `Excluir` | PASS |
| C11 | confirmed never-sent still has `Excluir` | `… -e "confirmed never-sent month row includes Excluir"` passed | `spec/requests/organizations_spec.rb:366–369` delete form, turbo confirm, `Excluir` | PASS |
| C12 | DELETE empty never-sent `302` `/`, row gone, toast `Pronto.`, `Nenhum mês aberto`, reopen same `year_month` | request + model discard success passed | `spec/requests/months_spec.rb:1938–1951` found, redirect `/`, count `0`, toast kind success + `Pronto.`, empty copy, POST persists and `302` show; `spec/models/month_spec.rb:53` count `0` | PASS |
| C13 | DELETE with data: month/statements/movements/matches gone, document `month_id` nil, no writer, `302` | `… -e "DELETE never-sent month destroys statements matches and nullifies documents"` passed | `spec/requests/months_spec.rb:1965` `PackageArchiveWriter` not `receive(:current)`; `:1968–1975` found, redirect `/`, empty month/statement/payment/inflow/match, `document.month_id` nil | PASS |
| C14 | DELETE closed `422` notice, month remains closed | request + model passed | `spec/requests/months_spec.rb:1986–1989` unprocessable, notice, `be_closed`, count `1`; `spec/models/month_spec.rb:62–63` | PASS |
| C15 | DELETE reopened `422` same notice, month remains | request + model passed | `spec/requests/months_spec.rb:2000–2002` unprocessable, notice, `month_folder_id` still `drive-folder`; `spec/models/month_spec.rb:72–73` | PASS |
| C16 | invalid or missing DELETE `404`, no delete | `… -e "DELETE invalid or missing month returns 404"` passed | `spec/requests/months_spec.rb:2012–2013` `2026-13` not_found, count `1`; `:2017–2018` missing `2026-05` not_found, `2026-04` remains | PASS |
| C17 | submitter omits `Excluir`; DELETE `404`; month remains | orgs + months request passed | `spec/requests/organizations_spec.rb:380` body not `Excluir`; `spec/requests/months_spec.rb:2029–2030` not_found, count `1` | PASS |
| C18 | `design.md` `home` Meses columns + Excluir rules | `ruby bin/rspec spec/docs/home_open_month_list_spec.rb -e "visual-identity home Meses has Excluir on never-sent Aberto rows"` passed | `spec/docs/home_open_month_list_spec.rb:22–29` includes `Mês \| AAAA-MM \| Status`, `last action`, `Excluir`, never closed-for-send, turbo copy, Fechado/reopened omit | PASS (document; HTML arrangement is C8) |

## Coverage (recomputed)

Authority for screen members: `design.md` `month` / `home`. Decision members from `Month#confirm_accounts`, `Month#never_sent?`, `Month#discard_never_sent`, `find_month`, `require_coordinator_organization`. Home Meses arrangement row recomputed at `41ecbfb` (C8 HTML). Other set rows carried from `3ed93c7` after re-join against the same members.

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| unconfirmed GET confirm enablement (3) | no spreadsheet disabled C1 · no active accounts C2 · mixed enabled C3 | - |
| confirm POST outcomes (3) | no spreadsheet C4 · mixed C5 · closed C6 | - |
| home Excluir visibility (4) | never-sent open C8 · closed omit C9 · reopened omit C10 · confirmed never-sent C11 | - |
| home Meses arrangement (2) | empty last heading column C8 `:337` · `Excluir` last cell after Status C8 `:338–340` | - |
| DELETE outcomes (7) | empty 302 C12 · with data 302 C13 · closed 422 C14 · folder id 422 C15 · invalid 404 C16 · missing 404 C16 · submitter 404 C17 | - |
| designed screens this cut binds (2) | `month` C1–C7 · `home` C8–C12, C18 | - |
| visual-identity screens this cut does not bind (4) | — | `login`, `denied`, `setup`, `documents` — out of scope |
| `month` visual (3) | — | spacing, colour, type weight (enumerated) |
| `home` visual (3) | — | spacing, colour, type weight (enumerated) |

Landing `never_sent` = `closed` false and `month_folder_id` blank. `spreadsheet_present?` via `spreadsheet_attachment` is C4/C5. `restrict_with_exception` remains on `has_many :bank_statements` (`app/models/month.rb:16`); discard destroys statements first (`:116`).

Level: claims naming status/route/shape (C1, C4–C6, C8, C12–C17) have request-spec assertions at HTTP. Model tables sit beside C4–C6, C12, C14, C15. `find_month` 404 is instrumentation; C16 is at HTTP only — matches Test policy.

## Test policy rows

Row classifying `organizations_spec.rb` re-judged at `41ecbfb` (C8 HTML arrangement added). Others carried from `3ed93c7`.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `app/models/month.rb` `confirm_accounts` / `discard_never_sent` / `never_sent?` / `spreadsheet_present?` | own layer + HTTP; one case per member | yes: confirm closed / no spreadsheet / success; discard success / closed / folder id; HTTP C4–C6, C12–C15, C17 who-may-call |
| Decides, not reached across a boundary | none added | own layer | n/a |
| Entry point that decides nothing | `MonthsController#destroy` / `#account_confirmation` (forward + status map) | request: accept, reject, error | yes: 302/422/404 paths C4–C6, C12–C17 |
| Instrumentation / pass-through | `find_month`, `redirect_success` | consumer | yes: C16 HTTP 404; C12 toast `Pronto.` |

`.cursor/rules/rails.mdc` already answers both allocation questions; the checklist follows it. HTML copy and Meses arrangement use request specs (no view specs in this repo). System specs not required.

## Swept existing

Carried from `3ed93c7` (cited lines unchanged at HEAD).

| Row | Cited constraint | Present |
|---|---|---|
| concurrency | `with_lock` on confirm/discard | yes `app/models/month.rb:93`, `:110` |
| unique `year_month` | `validates :year_month, uniqueness: { scope: :organization_id }` | yes `:21` |
| missing month | `find_month` `head :not_found` | yes `app/controllers/months_controller.rb:108–117` |
| coordinator only | `before_action :require_coordinator_organization` | yes `:2` |
| close-for-send unchanged | `close_blocker` `MISSING_STATEMENT` | yes `app/models/month.rb:135` |
| success toast | `redirect_success` → `Pronto.` | yes `application_controller.rb:213–214` |
| notice `role="alert"` | shared notice | yes `app/views/shared/_notice.html.erb:1`; C1 locator `error_notice` requires it |

Not-in-scope rows: policy, not code.

## Faults injected

Round 2 (surfaces the C8 fix created), scratch `git worktree add /tmp/tlc-verify-confirm-discard-r2 HEAD`. Real-tree porcelain after remove matches baseline (untracked `.checks/…verified.md`, `.tasks/…`, `prototypes_*` only).

| Mutation | Location | Killed |
|---|---|---|
| last Meses heading cell `""` → `"Excluir"` | `app/views/organizations/show.html.erb` | yes — C8 `:337` expected `["Mês", "AAAA-MM", "Status", ""]` |
| `Excluir` moved into Status cell (empty last span) | same | yes — C8 `:339` Status text no longer `Aberto` |

Round 1 faults (carried from `3ed93c7`, not re-injected): disabled submit → false (C1); skip `spreadsheet_present?` refuse (C4 model); always render `Excluir` (C9); skip `never_sent?` refuse (C14 model); `destroy` without `discard_never_sent` (C12). No surviving mutant on those five surfaces.

## Gate

`ruby bin/rspec` (25 named examples across `months_spec.rb`, `month_spec.rb`, `organizations_spec.rb`, two docs specs) — 25 passed, 0 failed. (`bin/rspec` exit 127.)

## Findings (ranked)

None that fail the gate. Round-1 FAIL (home Meses arrangement with no HTML check) is closed by C8 `:336–340`. Carried note: month notice document order (after summary, before `Contas bancárias`) remains unasserted; C1 only requires `p[role="alert"][data-notice="error"]` somewhere.
