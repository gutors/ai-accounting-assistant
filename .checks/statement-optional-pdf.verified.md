# Statement optional PDF Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 56c84dd..4ddb3e8
**Round**: 2 - full
**Verifier**: independent sub-agent (author != verifier)

Proofs ran at HEAD `4ddb3e8013fa081a2e3756fce807bfb623126662` via `ruby ./bin/rspec` (RSpec 3.13, `--format documentation`). Sandboxed `bin/rspec` cannot read `config/master.key`; examples ran outside the sandbox. A single `-e` with `|` is literal-escaped by RSpec and matched nothing (exit 0); the gate used one process and one `-e` per named example.

Round 1 FAIL at `de70258` was C14 row slots 0–1 and the actions cell unasserted (name/coordinates swap survived). HEAD `4ddb3e8` adds those assertions. This round re-proved C1–C16, not only C14.

## Binding sources

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.tasks/statement-optional-pdf.md` | yes - file | none vs C1–C16 / Landing / Unresolved 1–2 (`Envie a planilha`; closed GET / `open` on that account’s `422`) | — |
| https://github.com/gutors/ai-accounting-assistant/issues/108 | yes - `gh issue view 108` | none - spreadsheet required, PDF optional, omit-keeps, new-replaces, include in `<details>` `Incluir extrato`, Documentos `Pdf` / `Planilha`, Situação only Presente/Falta, `422` no longer `Envie o PDF e a planilha` | close-for-send “spreadsheet present” is Landing / existing `Month#missing_active_statement?` (row, not PDF blob); not a named check — matches task out-of-scope for close-blocker copy |
| `.specs/features/visual-identity/design.md` section `month` | yes - file, Contas bancárias ASCII + bullets through the `documents` heading | none - C16 matches the amended band: Situação `Presente`/`Falta` (no filenames), Documentos `Pdf {filename}` / `Planilha {filename}`, Incluir/Substituir `<details>`, closed month no form. Recebimentos, Pagamentos, pool, header, summary sentences unchanged as the task required | none on the bound Contas bancárias band. Header, summary, Recebimentos, Pagamentos, pool stay as opened (not this cut) |

Screens table visual exemption is enumerated (`spacing, colour, type weight on month bank ledger`), not a blanket. Inner form `PDF` / `Incluir PDF` / `Planilha` / `Incluir planilha` / `Enviar extrato` is C10–C11. Falta `text-margem` is C7. Five head cells, five row cells in Nome / Agência/conta / Situação / Documentos / actions order, and Documentos-after-Situação are C14.

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | spreadsheet-only POST `302` to `/months/2026-05`; one statement; spreadsheet attached; pdf not | `-e "POST spreadsheet only persists statement without pdf"` + `-e "import without pdf persists spreadsheet only"` — both ran, passed | `spec/requests/bank_statements_spec.rb:95-103` `have_http_status(:found)` `redirect_to("/months/2026-05")` `count eq(1)` `spreadsheet.filename eq("extrato-maio-2026.xlsx")` `pdf.not_to be_attached`; `spec/models/bank_statement_spec.rb:96-99` persisted, spreadsheet filename, `pdf.not_to be_attached` | PASS |
| C2 | GET row Presente; Documentos Planilha + filename, no Pdf; Situação exactly `Presente`; page omits `Falta o extrato` | `-e "GET after spreadsheet-only shows Presente Planilha and no Pdf"` passed | `spec/requests/bank_statements_spec.rb:116-121` `documents.text` include `Planilha` and `extrato-maio-2026.xlsx`, `not_to include("Pdf")`; situation `eq("Presente")`; `response.body.not_to include("Falta o extrato")` | PASS |
| C3 | POST both files `302`; blobs attached; Documentos lines Pdf then Planilha; Situação `Presente` | `-e "POST pdf and spreadsheet shows Pdf then Planilha in Documentos"` passed | `spec/requests/bank_statements_spec.rb:131-141` `:found` redirect; both attached; `lines.eq(["Pdf extrato-maio-2026.pdf", "Planilha extrato-maio-2026.xlsx"])`; situation `eq("Presente")` | PASS |
| C4 | pdf-only and no-files: no persist, `422`, notice `Envie a planilha` | three examples passed | `spec/requests/bank_statements_spec.rb:151-153` and `161-163` `:unprocessable_content`, `error_notice_text eq("Envie a planilha")` (`p[role=alert][data-notice=error]`, `spec/support/page_helpers.rb:8-12`), count 0; `spec/models/bank_statement_spec.rb:88-90` `errors[:base] include("Envie a planilha")` count 0 | PASS |
| C5 | valid pdf + `.ofx`: no persist, `422`, `Envie a planilha` | both examples passed | `spec/requests/bank_statements_spec.rb:329-331` `:unprocessable_content` `error_notice_text eq("Envie a planilha")` count 0; `spec/models/bank_statement_spec.rb:182-184` `errors[:base] include("Envie a planilha")` | PASS |
| C6 | oversize pdf 10485761 + valid spreadsheet: no persist, `422`, `Cada arquivo pode ter no máximo 10 MB` | both examples passed (`oversized_pdf` is `"x" * 10_485_761` in `spec/support/statement_helpers.rb:66-67`) | `spec/requests/bank_statements_spec.rb:317-319` `:unprocessable_content` `error_notice_text eq("Cada arquivo pode ter no máximo 10 MB")` count 0; `spec/models/bank_statement_spec.rb:175-176` not persisted, count 0 (no OVERSIZE string at model) | PASS |
| C7 | Falta in `text-margem`; Documentos no Pdf/Planilha; Situação exactly `Falta` | `-e "Falta row Situacao is Falta and Documentos has no Pdf or Planilha"` passed | `spec/requests/months_spec.rb:1639-1643` `.text-margem eq("Falta")`; documents `not_to include("Pdf")` / `"Planilha"`; situation `eq("Falta")` | PASS |
| C8 | replace omit pdf: one statement; pdf still `extrato-maio-2026.pdf`; spreadsheet new name; GET Pdf + Planilha new | both examples passed | `spec/requests/bank_statements_spec.rb:344-353` count 1, pdf filename, `spreadsheet eq("replace.csv")`, GET includes Pdf line and `replace.csv`; `spec/models/bank_statement_spec.rb:191-194` same filenames | PASS |
| C9 | pdf onto spreadsheet-only attaches `extrato-maio-2026.pdf`; GET Documentos has Pdf + Planilha | both examples passed | `spec/requests/bank_statements_spec.rb:366-372` pdf filename; GET includes `Pdf extrato-maio-2026.pdf` and spreadsheet filename; `spec/models/bank_statement_spec.rb:201-203` both filenames | PASS |
| C10 | Falta open month: `<details>` summary `Incluir extrato`, not `open`; inner PDF/Planilha fields and `Enviar extrato`; no `Substituir extrato` | `-e "absent statement folds the upload form under Incluir extrato"` passed | `spec/requests/months_spec.rb:1620-1627` summary `eq("Incluir extrato")` `open eq(false)`; details include `PDF` `Incluir PDF` `Planilha` `Incluir planilha`; submit `Enviar extrato`; summaries `not_to include("Substituir extrato")` | PASS |
| C11 | Presente open month: `Substituir extrato`, not `open`; same inner form; no `Incluir extrato` | `-e "present statement folds the upload form under Substituir extrato"` passed | `spec/requests/months_spec.rb:1599-1606` summary `eq("Substituir extrato")` `open eq(false)`; same inner strings/submit; summaries `not_to include("Incluir extrato")` | PASS |
| C12 | closed Presente: Situação `Presente`, Documentos lines from C3, neither Incluir nor Substituir | `-e "closed Presente row keeps Documentos and omits statement forms"` passed | `spec/requests/months_spec.rb:1657-1661` situation `eq("Presente")`; `lines.eq(["Pdf extrato-maio-2026.pdf", "Planilha extrato-maio-2026.xlsx"])`; `not_to include` Incluir/Substituir | PASS |
| C13 | `422` from C4: failing account `Incluir extrato` is `open`; notice still `Envie a planilha` | `-e "POST without files opens Incluir extrato on the failing account"` passed | `spec/requests/bank_statements_spec.rb:172-179` `:unprocessable_content`; `error_notice_text eq("Envie a planilha")`; failing details `open eq(true)`; other account `open eq(false)` | PASS |
| C14 | head children Nome, Agência/conta, Situação, Documentos, empty actions; each bank row same cell order; Presente Documentos has `whitespace-nowrap` | `-e "month bank ledger head and rows are Nome Agencia Situacao Documentos actions"` passed | `spec/requests/months_spec.rb:1671-1682` head `eq(["Nome", "Agência/conta", "Situação", "Documentos", ""])`; `cells.size eq(5)`; `cells[0] eq(statement.bank_account.name)`; `cells[1] eq(statement.bank_account.coordinates.to_s)`; `cells[2] data-cell situation`; `cells[3] data-cell documents` and class include `whitespace-nowrap`; `cells[4] summary eq("Substituir extrato")` | PASS |
| C15 | two accounts: only Presente lists Pdf/Planilha filenames; Falta matches C7 | `-e "two accounts only Presente row lists Pdf and Planilha filenames"` passed | `spec/requests/months_spec.rb:1691-1702` Presente docs include Pdf/`extrato.pdf`/Planilha/`extrato.xlsx`; Falta `text-margem Falta`, documents omit Pdf/Planilha, situation `Falta` | PASS |
| C16 | design.md month Contas bancárias uses Situação + Documentos (not old Situação filenames / inline include); visual-identity bank-row checks follow | `-e "visual-identity month Contas bancarias uses Situacao and Documentos"` passed | `spec/docs/visual_identity_month_bank_rows_spec.rb:9-20` month section includes `Documentos`, `Pdf {filename}`, `Planilha {filename}`, `Incluir extrato`, Situação Presente or Falta, `no filenames`; not old inline / filenames-in-meta; checks.md includes `Envie a planilha` and Incluir-fold, not inline-details ancestor / old PDF copy. Does not assert `Substituir extrato`, `Closed month: no form`, or no-wrap in the design file — those UI facts sit on C11, C12, C14 | PASS |

## Coverage (recomputed)

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| first-import file combinations (5) | spreadsheet-only C1 · pdf+spreadsheet C3 · pdf-only C4 · no files C4 · `.ofx` C5 | - |
| oversize PDF with valid spreadsheet (1) | C6 | - |
| Situação / Documentos states (3 named; table lists 4 arrows) | Falta C7 · Presente spreadsheet-only C2 · Presente both files C3 · two-account mix C15 | - |
| replace PDF (2) | omit keeps C8 · new attaches C9 | - |
| statement form folds (4) | Incluir closed C10 · Substituir closed C11 · closed month no form C12 · `422` open Incluir C13 | - |
| bank ledger columns (5) | Nome · Agência/conta · Situação · Documentos · empty actions — C14 head literals and row cells 0–4 | - |
| designed screens this cut binds (1) | `month` C2, C7, C10–C16 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `setup`, `documents` — out of scope |
| `month` visual (3 properties) | — | spacing, colour, type weight on month bank ledger |

- Claims naming status/route/shape: C1, C3, C4, C5, C6, C8, C9, C13 — each has a request-spec proof at HTTP. No level gap.
- Landing “spreadsheet-only is a valid BankStatement” / “omit pdf does not purge” joined to C1 / C8.

## Test policy rows

Judged against the checklist’s `## Test policy` (which follows `.cursor/rules/rails.mdc`), not a weaker house taste.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `app/models/bank_statement.rb` `#submit` / `persist_import` | own layer **and** request spec; one case per member | met for spreadsheet-only, missing spreadsheet, `.ofx`, oversize persist-reject, omit-pdf keep, attach-pdf — C1/C4–C6/C8/C9. Oversize **copy** is only at HTTP (C6 request), matching the check’s HTML claim |
| Decides, not reached across a boundary | `app/views/months/show.html.erb` bank ledger (Situação, Documentos, details `open`, column order) | own layer; repo has no view specs → request GET/`422` | met for C2, C7, C10–C15 including C14 row Nome / Agência/conta / actions |
| Entry point that decides nothing | `BankStatementsController#create` (redirect vs `422` render; `@import_bank_account_id`) | request spec | met — C1/C3–C6/C8/C9/C13 |
| Instrumentation / pass-through | `_statement_form`, Active Storage attach | consumer | met — consumers are C10–C11 / C1 persist |

## Swept existing

| Row | Cited constraint | Present? |
|---|---|---|
| authorization | `require_coordinator_organization` on `BankStatementsController` | yes - `app/controllers/bank_statements_controller.rb:2` |
| concurrency | unique `(month_id, bank_account_id)` + `RecordNotUnique` retry | yes - `db/schema.rb:86`; `app/models/bank_statement.rb:20-23` |
| data / close | `Month#missing_active_statement?` is missing **row**, not missing PDF | yes - `app/models/month.rb:101-104` pluck statement `bank_account_id` |
| close-for-send files | `MonthPackage#statement_files` skips unattached PDF | yes - `app/models/month_package.rb:39-41` `if statement.pdf.attached?` |
| not in scope | OFX as movement source, remove-PDF control, toast on `302` | policy — no code to be wrong about |

## Faults injected

Scratch worktree `/tmp/tlc-verify-sopdf-r2` at `4ddb3e8`. Real-tree porcelain before and after: `?? .checks/statement-optional-pdf.verified.md`. Worktree removed after the five mutants.

| Mutation | Location | Killed |
|---|---|---|
| `submit` rejects blank `pdf` (restore both-files gate) | `BankStatement#submit` | yes — C1 expected `302`, got `422` (`bank_statements_spec.rb:95`) |
| Documentos lines Planilha above Pdf | `months/show.html.erb` documents cell | yes — C3 `lines` expected Pdf then Planilha (`bank_statements_spec.rb:140`) |
| omit `@import_bank_account_id` on `422` | `BankStatementsController#create` | yes — C13 `open` expected true (`bank_statements_spec.rb:178`) |
| `MISSING_SPREADSHEET` → `Envie o PDF e a planilha` | `BankStatement` constant | yes — C4 notice (`bank_statements_spec.rb:162`) |
| swap row name and coordinates cells | `months/show.html.erb` first two `<p>` | yes — C14 `cells[0]` expected `"Conta Principal"`, got `""` (`months_spec.rb:1677`) |

## Gate

`ruby ./bin/rspec` four files, 23 named examples (every checklist `-e` string) — 23 passed, 0 failed at `4ddb3e8`.

Five mutants killed, including the round-1 survivor on C14 row order.
