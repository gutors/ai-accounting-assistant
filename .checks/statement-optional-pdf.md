# Statement: optional PDF, compact upload, Documentos column

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/statement-optional-pdf.md` marks screen `month` binding through `.specs/features/visual-identity/design.md` (criterion 16).

Sources:

- `.tasks/statement-optional-pdf.md` - criteria 1–16, the state diagram, the sweep, two doors, Unresolved 1–2 stay open (`Envie a planilha`; Incluir closed on GET, `open` on that account’s `422`). Nothing under Unresolved is settled while building
- https://github.com/gutors/ai-accounting-assistant/issues/108 - **binding for this slice**: spreadsheet required, PDF optional on include and replace; Presente with spreadsheet only; omit PDF on replace keeps PDF; new PDF replaces; `422` copy is no longer `Envie o PDF e a planilha`; include in `<details>` like Substituir (summary `Incluir extrato`); Documentos `Pdf {filename}` / `Planilha {filename}`, one per line, no wrap; omit Pdf line when no PDF; Situação only Presente/Falta
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent umbrella; one tlc-plan per child
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screen `month`. Opened as a file in the repo. Section `month` today still puts filenames on Situação and draws Falta include inline. C16 amends Contas bancárias. Recebimentos, Pagamentos, pool, header, and the summary sentences stay as opened
- `app/models/bank_statement.rb` - today’s both-files gate `MISSING_FILES`, `persist_import` always attaches both
- `app/views/months/show.html.erb` / `_statement_form.html.erb` - today’s four-column bank ledger and inline include
- `app/models/month_package.rb` - already skips unattached PDF at close-for-send
- Open defaults in Unresolved 1–2 - `Envie a planilha`; Falta details closed until `422` opens them

## Out of scope

- PagSeguro Entradas/Saídas zero — #109
- Hide Recebimentos/Pagamentos until the coordinator confirms accounts — #110
- Matching screen, Resolver, N:1 — #111
- Overview: drop Ações, filter, collapse lists, Voltar para Início, richer pool — #112
- Requiring a `.pdf` extension or MIME on the optional PDF — existing: only non-blank
- A control that removes an attached PDF — #108 only omit-keeps and new-replaces
- Toast `Pronto.` on statement `302` — existing redirect has none
- Open Finance, OFX as a movement source, other COMPE parsers — existing `422`s stay except the missing-spreadsheet copy (C5)
- Changing `Month#close_blocker` copy `Importe o extrato de cada conta ativa` — it already keys off a BankStatement row, not the PDF blob
- Historical `.specs/features/bank-statement-upload/` C17/C25/C26 — those checks describe the old both-files gate and stay as history
- Settling Unresolved 1–2 beyond the task’s transcribed `Envie a planilha` and closed/`open` details

## Landing

Touches `BankStatement#submit` / `persist_import`, `POST /months/:year_month/bank_statements` `422` (failing `bank_account_id` for `open`), `GET /months/:year_month` bank ledger (Situação, Documentos, Incluir/Substituir details), `.ledger-month-bank` columns, and `design.md` section `month`. Reuses Active Storage optional `has_one_attached :pdf`, existing `:base` strings except the missing-spreadsheet copy, `_statement_form`, `require_coordinator_organization`, and `Month#missing_active_statement?` (still “no row”).

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Spreadsheet-only is a valid BankStatement | `submit` requires a `.csv`/`.xlsx` spreadsheet; `pdf` may be blank on first import; `Presente` iff a BankStatement row exists (spreadsheet attached). `Month#missing_active_statement?` stays “no row”, not “no PDF” | Keep requiring PDF — #108. Treat Presente as both files while allowing persist without PDF — Situação would lie |
| Omit PDF on replace keeps the blob | `persist_import` attaches `pdf` only when the param is present; a blank `pdf` does not `purge`. A new `pdf` replaces. Spreadsheet always attaches on a successful submit | Purge PDF when the file field is empty — the browser cannot say “keep” vs “clear”. A dedicated remove control is out of scope |

- Nothing else in this change is hard to reverse

## Screens (ui)

Opened `.specs/features/visual-identity/design.md` section `month` as a file. Today's ASCII still has filenames on Situação and inline include; C16 amends Contas bancárias. Arrangement below is what C10–C16 plus that amended section require.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `month` bank rows | `.ledger-head.ledger-month-bank`: `Nome`, `Agência/conta`, `Situação`, `Documentos`, empty actions heading; `li[data-row="bank-account"]` Situação text exactly `Presente` or `Falta` (`text-margem` on Falta); Documentos `Pdf {filename}` then `Planilha {filename}` (omit Pdf when no PDF; omit both on Falta); `Incluir extrato` / `Substituir extrato` summaries; inner `PDF` / `Incluir PDF`, `Planilha` / `Incluir planilha`, `Enviar extrato`; `[data-notice="error"]` `Envie a planilha` on C4/C13; no `Falta o extrato` when every active account is Presente | five cells in that order on head and each row; Documentos after Situação; Pdf line above Planilha; include/replace in `<details>` not `open` on success GET; failing account’s `Incluir extrato` `open` on `422`; closed month: Situação + Documentos, no form; Documentos cell of a Presente row includes `whitespace-nowrap` | spacing, colour, type weight on month bank ledger |

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

- `.cursor/rules/rails.mdc` names the level and the sampling rule: a decision is proven at its own layer, one asserted case per enumerated member; HTTP also gets a request spec; system specs only when a request spec cannot settle the claim
- `BankStatement#submit` decides missing-spreadsheet / bad extension, optional PDF persist, omit-pdf keep, attach-new-pdf. Closest analogue: existing `spec/models/bank_statement_spec.rb` plus `spec/requests/bank_statements_spec.rb`
- Bank ledger HTML (column order, details `open`, Documentos lines, Situação text) is a view decision; this repo has no view specs — request specs on `GET` / `422` `months/show`
- System specs are not required: every named observation is HTML, status, attachment, or a file read a request/docs spec can settle

Cost: request examples for C1–C15; model examples for spreadsheet-only persist, missing spreadsheet, `.ofx`, oversize PDF, omit-pdf keep, attach PDF onto spreadsheet-only; file-read example for C16.

## Checks

Criteria 1–16 map to C1–C16. Unresolved 1–2 stay `Envie a planilha` and closed GET / `open` on that account’s `422`.

### S1 - Spreadsheet-only Presente · 5 files · 45 KB · ~11k

**C1** - Given a signed-in coordinator of the focused organization, open Month `2026-05`, and an active COMPE `001` BankAccount `Conta Principal`, when `POST /months/2026-05/bank_statements` runs with `bank_account_id` of that account and the BB May 2026 fixture spreadsheet, without `pdf`, then the status is `302` to `/months/2026-05`, one BankStatement persists for that pair, that statement’s `spreadsheet` is attached with the fixture filename, and `pdf` is not attached.
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST spreadsheet only persists statement without pdf"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "import without pdf persists spreadsheet only"`

**C2** - When the following `GET /months/2026-05` runs, then that `li[data-row="bank-account"]` includes `Presente`, includes a Documentos cell whose text contains `Planilha` then the spreadsheet filename, does not include `Pdf`, and the Situação cell’s text is exactly `Presente` (no filename in that cell). The page does not include `Falta o extrato`.
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "GET after spreadsheet-only shows Presente Planilha and no Pdf"`

**C3** - Given the same setup, when `POST /months/2026-05/bank_statements` runs with that `bank_account_id`, `pdf` the May 2026 statement PDF (`extrato-maio-2026.pdf`), and the BB spreadsheet (`extrato-maio-2026.xlsx`), then the status is `302` to `/months/2026-05`, both blobs are attached, and the following GET’s Documentos cell contains `Pdf extrato-maio-2026.pdf` on one line and `Planilha extrato-maio-2026.xlsx` on the next, in that order, and Situação text is exactly `Presente`.
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST pdf and spreadsheet shows Pdf then Planilha in Documentos"`

**C4** - Given no statement on that account, when `POST /months/2026-05/bank_statements` runs with that `bank_account_id` and `pdf` only (no spreadsheet), then no BankStatement persists, the status is `422`, and `[data-notice="error"]` is `Envie a planilha`. The same POST with no files matches that `422` and copy.
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST pdf only returns 422 Envie a planilha"`
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST without files returns 422 Envie a planilha"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "rejects import without spreadsheet"`

**C5** - When `POST /months/2026-05/bank_statements` runs with a valid `pdf` and a movement file whose extension is `.ofx`, then no BankStatement persists, the status is `422`, and `[data-notice="error"]` is `Envie a planilha`.
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST ofx spreadsheet returns 422 Envie a planilha"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "rejects movement file extension ofx"`

**C6** - When `POST /months/2026-05/bank_statements` runs with `pdf` of `10485761` bytes and a valid spreadsheet, then no BankStatement persists, the status is `422`, and `[data-notice="error"]` is `Cada arquivo pode ter no máximo 10 MB`.
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST file of 10485761 bytes returns 422 max 10 MB"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "rejects a file larger than 10485760 bytes"`

**C7** - Given that account has no statement this month, when `GET /months/2026-05` runs, then that row includes `Falta` in `text-margem`, its Documentos cell includes neither `Pdf` nor `Planilha`, and Situação text is exactly `Falta`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "Falta row Situacao is Falta and Documentos has no Pdf or Planilha"`

### S2 - Replace keeps an omitted PDF · 2 files · 14 KB · ~3k

**C8** - Given a statement that has both `extrato-maio-2026.pdf` and `extrato-maio-2026.xlsx`, when `POST /months/2026-05/bank_statements` runs with a different valid spreadsheet and without `pdf`, then one BankStatement remains, `pdf` is still `extrato-maio-2026.pdf`, `spreadsheet` is the new filename, and the following GET shows `Pdf extrato-maio-2026.pdf` and `Planilha` plus that new filename.
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST replace without pdf keeps existing pdf"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "replace without pdf keeps the attached pdf"`

**C9** - Given a spreadsheet-only statement as in criterion 1, when `POST /months/2026-05/bank_statements` runs with `pdf` `extrato-maio-2026.pdf` and a valid spreadsheet, then `pdf` is attached as that filename and the following GET’s Documentos cell includes `Pdf extrato-maio-2026.pdf` and `Planilha` plus the spreadsheet filename.
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST pdf onto spreadsheet-only attaches pdf"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "import pdf onto spreadsheet-only attaches pdf"`

### S3 - Incluir extrato details · 3 files · 86 KB · ~21k

**C10** - When `GET /months/2026-05` runs as in criterion 7 (Falta, month open), then that row’s upload is inside a `<details>` whose `<summary>` text is `Incluir extrato`, that details is not `open`, and the details contain the existing file fields (`PDF` / `Incluir PDF`, `Planilha` / `Incluir planilha`) and submit `Enviar extrato`. The row has no `<summary>` `Substituir extrato`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "absent statement folds the upload form under Incluir extrato"`

**C11** - When `GET /months/2026-05` runs as in criterion 3 (Presente, month open), then that row’s upload is inside a `<details>` whose `<summary>` text is `Substituir extrato`, not `open`, with the same inner form as criterion 10. The row has no `<summary>` `Incluir extrato`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "present statement folds the upload form under Substituir extrato"`

**C12** - While the month is closed, `GET /months/2026-05` for a Presente row still shows Situação `Presente` and the Documentos lines from criterion 3, and that row includes neither `Incluir extrato` nor `Substituir extrato`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "closed Presente row keeps Documentos and omits statement forms"`

**C13** - When the `422` from criterion 4 renders, then the `Incluir extrato` details of that `bank_account_id` is `open`, and `[data-notice="error"]` is still `Envie a planilha`.
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST without files opens Incluir extrato on the failing account"`

### S4 - Documentos column and binding month wireframe · 4 files · 69 KB · ~17k

**C14** - Given at least one active BankAccount, when `GET /months/2026-05` runs, then `.ledger-head.ledger-month-bank` children in order are `Nome`, `Agência/conta`, `Situação`, `Documentos`, then an empty actions heading. Each `li[data-row="bank-account"]` uses that same cell order. The Documentos cell of a Presente row includes `whitespace-nowrap`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "month bank ledger head and rows are Nome Agencia Situacao Documentos actions"`

**C15** - Given two active accounts, one Presente with both files and one Falta, when that GET runs, then only the Presente row includes `Pdf` / `Planilha` filenames, and the Falta row matches criterion 7.
Proof: `bin/rspec spec/requests/months_spec.rb -e "two accounts only Presente row lists Pdf and Planilha filenames"`

**C16** - `.specs/features/visual-identity/design.md` section `month` — Contas bancárias is no longer name | coordinates | `Presente` plus two filenames in meta (or `Falta`) | inline include or `Substituir extrato`. It is name | coordinates | Situação `Presente` or `Falta` (no filenames) | Documentos (`Pdf {filename}` when a PDF is attached, omitted otherwise; `Planilha {filename}` when a spreadsheet is attached; one per line, no wrap) | `Incluir extrato` details when Falta and open, `Substituir extrato` when Presente and open. Closed month: no form. `visual-identity` month bank-row checks follow this, not the old Situação filenames.
Proof: `bin/rspec spec/docs/visual_identity_month_bank_rows_spec.rb -e "visual-identity month Contas bancarias uses Situacao and Documentos"`

## Swept

- validation: C4, C5, C6 — spreadsheet required and `.csv`/`.xlsx`; PDF optional; 10 MB when a PDF is sent; other existing `:base` strings (`Não foi possível ler a planilha`, unsupported bank, dates outside the month, `Mês fechado`) stay
- failure modes: C4, C13 — missing spreadsheet `422` re-renders show with notice and open details
- idempotency and retry: C8 — same `POST` is replace; omit `pdf` does not attach a second PDF and does not purge. `BankStatement.import` `RecordNotUnique` retry is existing
- authorization: existing — `require_coordinator_organization`; foreign or inactive account `404`; closed month `:base` `Mês fechado`
- concurrency and ordering: existing — `import` find-or-initialize plus unique (month, bank_account); two overlapping POSTs serialize on that row; omit-pdf keep is per persist of the winner
- data lifecycle: C1, C8, C9 — PDF blob may be absent; existing rows already have both attachments; nothing to backfill or strip
- external-dependency failure: n/a — Disk Active Storage local; Drive is close-for-send, unchanged
- state transitions: C1–C3, C7–C9 — Falta / Presente; spreadsheet-only vs both files
- observability: n/a — the source names no log, metric, or trace; the person sees Situação, Documentos, and the notice

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| first-import file combinations (5) | spreadsheet-only C1 · pdf+spreadsheet C3 · pdf-only C4 · no files C4 · `.ofx` C5 | - |
| oversize PDF with valid spreadsheet (1) | C6 | - |
| Situação / Documentos states (3) | Falta C7 · Presente spreadsheet-only C2 · Presente both files C3 · two-account mix C15 | - |
| replace PDF (2) | omit keeps C8 · new attaches C9 | - |
| statement form folds (4) | Incluir closed C10 · Substituir closed C11 · closed month no form C12 · `422` open Incluir C13 | - |
| bank ledger columns (5) | Nome · Agência/conta · Situação · Documentos · empty actions — C14 | - |
| designed screens this cut binds (1) | `month` C2, C7, C10–C16 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `setup`, `documents` — out of scope |
| `month` visual (3 properties) | — | spacing, colour, type weight on month bank ledger |

- Claims naming a status code, route or response shape: C1, C3, C4, C5, C6, C8, C9, C13 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~11k (model + controller + both statement specs + `show.html.erb`) + S2 ~3k (same persist path) + S3 ~21k (`show.html.erb` + `months_spec.rb` 69 KB counted once) + S4 ~17k (`design.md` + CSS + docs spec; `show` / `months_spec` not paid twice) = ~52k unique-file floor. All four slices stay under 150k and share the month bank ledger. No split. One batch.
