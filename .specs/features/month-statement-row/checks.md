# Month statement row checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/month-statement-row/plan.md`

17 checks in 2 slices · 0 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. The gesture checks run in
Cuprite system specs, because staging two files behind one picker is JavaScript.

## Checks

### S1 - the extrato action is one icon in its row

**C1** - On an open month each active account row has exactly one statement control, in its action
cell, at the 1.75rem `.ledger-action-icon` hit area: a `+` named `Incluir extrato` when the account
has no statement, the pencil named `Substituir extrato` when it has one; no row has a `<details>`
summary with either name (AC 1)
Proof: `bin/rspec spec/requests/month_statement_row_spec.rb -e "open month account rows carry one statement icon and no disclosure summary"`

**C2** - An account without a statement shows `A planilha é obrigatória` in its Documentos cell and
no `Pdf` or `Planilha` line there (AC 2)
Proof: `bin/rspec spec/requests/month_statement_row_spec.rb -e "account without statement shows only the planilha hint in Documentos"`

**C3** - The open month page with the five row states matches
`.specs/features/month-statement-row/captures/statement-row.png` (AC 3)
Proof: browser - reach the state, save `captures/statement-row.running.png`

**C4** - Picking a spreadsheet alone stages `Planilha {filename}` in Documentos and shows `Enviar
extrato` and `Descartar` in the action cell, with no `+` (AC 4)
Proof: `bin/rspec spec/system/month_statement_row_spec.rb -e "picking a spreadsheet alone stages Planilha and offers the send"`

**C5** - Picking a PDF alone stages `Pdf {filename}` above `A planilha é obrigatória` and shows `+`
and `Descartar`, with no `Enviar extrato` (AC 5)
Proof: `bin/rspec spec/system/month_statement_row_spec.rb -e "picking a PDF alone withholds the send and keeps the hint"`

**C6** - Picking a PDF and a spreadsheet stages `Pdf {filename}` above `Planilha {filename}` and
shows `Enviar extrato` and `Descartar` (AC 6)
Proof: `bin/rspec spec/system/month_statement_row_spec.rb -e "picking both files stages Pdf above Planilha with the send"`

**C7** - Picking two PDFs and two spreadsheets in one selection stages the first of each kind and
ignores the second of each (AC 7)
Proof: `bin/rspec spec/system/month_statement_row_spec.rb -e "two files of each kind stage the first of each"`

**C8** - A chosen file whose extension is not `.pdf`, `.csv` or `.xlsx` is discarded and the row
prints `Só PDF, .csv ou .xlsx` in margem; the next accepted file stages and the sentence goes (AC 8)
Proof: `bin/rspec spec/system/month_statement_row_spec.rb -e "nota txt and extrato ofx are refused and a staged xlsx clears the sentence"`

**C9** - Clicking `Enviar extrato` posts `bank_account_id`, `pdf` and `spreadsheet`, responds `302`
to `/months/2026-05`, and the page then lists the statement's own `Pdf` and `Planilha` lines with
the success toast (AC 9)
Proof: `bin/rspec spec/system/month_statement_row_spec.rb -e "sending the staged files persists the statement and toasts"`

**C10** - Clicking `Descartar` returns that row to the C1 state with nothing posted (AC 10)
Proof: `bin/rspec spec/system/month_statement_row_spec.rb -e "descartar clears the staged files without posting"`

**C11** - WHILE the month is closed no account row shows a statement control and the page has no
`Enviar extrato` (AC 11)
Proof: `bin/rspec spec/requests/month_statement_row_spec.rb -e "closed month rows have no statement control"`

**C17** - A `POST /months/2026-05/bank_statements` refused for a missing spreadsheet responds `422`
with the notice `Envie a planilha`, the failing row keeps its `Incluir extrato` control, and the page
carries no staged `Pdf` or `Planilha` line for it (AC 9)
Proof: `bin/rspec spec/requests/month_statement_row_spec.rb -e "refused POST re-renders with Envie a planilha and no staged files"`

**C18** - After `Reabrir`, the month page shows the `Incluir extrato` control again and no
`Enviar extrato` (existing behaviour, new control)
Proof: `bin/rspec spec/requests/reopen_spec.rb -e "reopen shows the statement control and hides the send"`

### S2 - Pagamentos reads as two lines at 14px

**C12** - Every Pagamentos row is at most 2 lines and at most 48px tall at 1280px, whatever its
status: history `14px`/`18px`, status and document `14px`/`18px`, account meta `13px`/`18px` (AC 12)
Proof: `bin/rspec spec/system/month_statement_row_spec.rb -e "every Pagamentos row measures at most 48px across five statuses"`

**C13** - A history, a document list or a status word wider than its column truncates with ellipsis
and carries the full text in `title` (AC 13)
Proof: `bin/rspec spec/requests/month_statement_row_spec.rb -e "long history document and status cells truncate and carry title"`

**C14** - A matched payment whose `Match` carries `desconto não documentado` omits that sentence from
Pagamentos and still prints it on `GET /months/2026-05/matches` (AC 14)
Proof: `bin/rspec spec/requests/month_statement_row_spec.rb -e "Pagamentos omits the match observation that matches still shows"`

**C15** - At 390px each Pagamentos row shows date and amount on the first line and the truncated
history with its status on the second, the Documento cell is not displayed, and the document measures
390px with no horizontal scroll, as `.specs/features/month-statement-row/captures/statement-row-390.png`
shows (AC 15)
Proof: browser - reach the state at 390px, save `captures/statement-row-390.running.png`
Proof: `bin/rspec spec/system/month_statement_row_spec.rb -e "390px pagamentos stacks two lines without horizontal scroll"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| statement row states (5) | empty `+` C1 · PDF only `+` `×` C5 · spreadsheet alone `✓` `×` C4 · both `✓` `×` C6 · refused sentence C8 · present pencil C1 | - |
| picker input space (7) | `.pdf` C5 · `.csv` C4 · `.xlsx` C4 · `.txt` C8 · `.ofx` C8 · second of a kind C7 · both kinds at once C6 | - |
| `POST /months/:year_month/bank_statements` statuses this change can reach (2) | `302` `/months/2026-05` C9 · `422` C17 | - |
| Pagamentos statuses measured (5) | `Documento faltante` C12 · `Casado` C12 · `Tarifa bancária` C12 · `Honorário do contador` C12 · extra kind C12 | - |
| capture states (2) | `captures/statement-row.png` C3 · `captures/statement-row-390.png` C15 | - |
| row control names (2) | `Incluir extrato` C1, C11 · `Substituir extrato` C1 | - |

## Swept

- validation: C8
- failure modes: C17
- idempotency: existing - a second send replaces that account's statement and its movements (`bank_statements_spec` "second POST ..." examples)
- authorization: existing - `require_coordinator_organization` plus the `404` branches for submitter, unknown month, foreign and inactive account, untouched by this feature and kept green by `bank_statements_spec`
- concurrency: existing - `BankStatement.import` retries `RecordNotUnique` against the existing row
- data lifecycle: n/a - the staged files live in the DOM and never persist; a send still replaces the statement
- dependency failure: n/a - no external call is added
- state transitions: C4, C5, C6, C10
- observability: n/a - no logging requirement in this slice

## Handoff

- **Settled mid-build:** the plan's AC 4 had the send gated on the PDF as well as the spreadsheet; the user's decision and `BankStatement#submit` both make the spreadsheet the only requirement, so a spreadsheet alone offers `Enviar extrato` and a PDF alone does not. Plan ACs 4-15 were renumbered to match.
- **Dispatched:** Verifier at `de99997`; screens round 1 at `de99997`
- **Boundary:** -
- **Abandoned:** the first request-spec version asserted three controls per row; the row carries three controls with two `hidden`, so the proof reads the visible ones.
- **Walked:** signed in at `/login` as a throwaway coordinator on a scratch organization, opened `/months/2026-05`, and staged files through the row picker by dispatching a `change` with a `DataTransfer`: `poupança` with a PDF alone → `Pdf extrato…` above `A planilha é obrigatória`, `+` and `×`, no send; `conta corrente` with a PDF and an `.xlsx` → both names, `Enviar extrato` and `×`; `aplicação` with a `.txt` → `Só PDF, .csv ou .xlsx` in margem above the hint, `+` and `×`. The Presente row carried the pencil when the statement had a PDF and a spreadsheet. Pagamentos rows measured 43px. At 390px the page measured 390px with no horizontal scroll (C15). The scratch organization and account were deleted after the walk.
