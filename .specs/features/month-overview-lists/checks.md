# Month overview lists checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/month-overview-lists/plan.md`

32 checks in 5 slices · 1 one-way door · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.

## Checks

### S1 - Iniciar fechamento toasts when it cannot run

**C1** - WHILE an open month has `accounts_confirmed` false and no spreadsheet statement, `GET /months/2026-05` responds `200`, `Iniciar fechamento` is present and is not `disabled`, and `[data-notice="error"]` is `Inclua o extrato planilha de pelo menos uma conta bancária.` (AC 1)
Proof: `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "unconfirmed GET without spreadsheet enables Iniciar fechamento and shows spreadsheet notice"`

**C2** - `POST /months/2026-05/account_confirmation` without a spreadsheet responds `422`, keeps `accounts_confirmed` false, and `[data-toast-kind=error]` is `Inclua o extrato planilha de pelo menos uma conta bancária.` (AC 2)
Proof: `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "POST account_confirmation without spreadsheet returns 422 error toast"`

**C3** - `POST /months/2026-05/account_confirmation` for a closed month responds `422` and `[data-toast-kind=error]` is `Mês fechado` (AC 3)
Proof: `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "POST account_confirmation on closed month returns 422 toast Mes fechado"`

**C4** - `POST /months/2026-05/account_confirmation` on an open month that has a spreadsheet sets `accounts_confirmed` true, responds `302` to `/months/2026-05`, and the success toast is `Contas de maio de 2026 confirmadas.` (AC 4)
Proof: `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "POST account_confirmation reveals movements and Pronto toast"`

**C5** - Unauthenticated `POST /months/2026-05/account_confirmation` responds `302` to `/login` (AC 5)
Proof: `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "unauthenticated POST account_confirmation responds 302 to /login"`

**C6** - Submitter `POST /months/2026-05/account_confirmation` responds `404` (AC 6)
Proof: `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "submitter POST account_confirmation responds 404"`

### S2 - Catalog debits are not payments · door 1

**C7** - `BankStatement` import on COMPE `001` with a debit whose history is `Transferência — BB Rende Fácil` does not insert a Payment for that line and still inserts other debits and credits from that file (AC 7)
Proof: `bin/rspec spec/models/investment_transfer_catalog_spec.rb -e "COMPE 001 debit Transferencia BB Rende Facil is a catalog match"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "persist_import on COMPE 001 skips catalog debit and inserts other movements"`

**C8** - WHILE a Payment row already exists on COMPE `001` with history `Transferência — BB Rende Fácil`, `GET /months/2026-05` after accounts are confirmed does not list that row in Pagamentos, `GET /months/2026-05/matches` does not list it, and the missing-document sentence does not count it (AC 8)
Proof: `bin/rspec spec/models/payment_spec.rb -e "for_month omits leftover COMPE 001 Rende Facil payment"`
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "GET month and matches omit leftover catalog debit from lists and missing-document sentence"`

**C9** - WHILE that leftover Payment is the only unmatched debit, `POST /months/2026-05/close` with every active account Presente does not refuse with `Há documento faltante` (AC 9)
Proof: `bin/rspec spec/models/month_spec.rb -e "close does not refuse leftover catalog debit as missing document"`
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "POST close with leftover catalog debit does not return Ha documento faltante"`

**C10** - `SummarySpreadsheet` for that month does not include that history in the custos / Pagamentos section (AC 10)
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "custos section omits leftover COMPE 001 Rende Facil payment"`

**C11** - A debit history on COMPE `001` of `RENDE FACIL` or `rende facil` is a catalog match the same as `Rende Fácil` (AC 11)
Proof: `bin/rspec spec/models/investment_transfer_catalog_spec.rb -e "COMPE 001 debit RENDE FACIL and rende facil match like Rende Facil"`

**C12** - A debit history `Transferência — BB Rende Fácil` on COMPE `033` is a Payment (AC 12)
Proof: `bin/rspec spec/models/investment_transfer_catalog_spec.rb -e "COMPE 033 debit Transferencia BB Rende Facil is not a catalog match"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "persist_import on COMPE 033 inserts Rende Facil debit as Payment"`

**C13** - A credit history on COMPE `001` that contains `Rende Fácil` is inserted and listed as an Inflow (AC 13)
Proof: `bin/rspec spec/models/investment_transfer_catalog_spec.rb -e "COMPE 001 credit containing Rende Facil is not a catalog match"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "persist_import on COMPE 001 inserts Rende Facil credit as Inflow"`

**C14** - Import that finishes with one catalog debit, one ordinary debit, and one credit toasts `1 recebimento` and `1 pagamento` (AC 14)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "import toast counts 1 recebimento and 1 pagamento omitting catalog debit"`

### S3 - Each list sorts on its own

**C15** - `GET /months/2026-05` with no sort params orders Pagamentos, Recebimentos, and Documentos sem casamento by date ascending then `id` ascending, and each list’s Data header has `aria-sort="ascending"` (AC 15)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "GET month defaults each list to date ascending with aria-sort"`

**C16** - Using Pagamentos Valor produces `payments_sort=amount` and `payments_dir=desc`, Pagamentos order by amount descending then `id` descending, and Recebimentos stay date ascending (AC 16)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "Pagamentos Valor sorts amount desc without reordering Recebimentos"`

**C17** - When Pagamentos is already `payments_sort=amount` and `payments_dir=desc`, using Pagamentos Valor again sets `payments_dir=asc` (AC 17)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "Pagamentos Valor toggles amount dir from desc to asc"`

**C18** - Using Recebimentos Data while `payments_sort=amount` sorts inflows by date (toggle dir) and keeps Pagamentos amount-sorted (AC 18)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "Recebimentos Data sort keeps Pagamentos amount sort"`

**C19** - Using Documentos sem casamento Favorecido produces `pool_sort=payee` and orders the pool by `payee` then `id` in the active dir (AC 19)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "pool Favorecido sorts by payee"`

**C20** - Using Documentos sem casamento Valor orders the pool by `amount_cents` then `id` in the active dir (AC 20)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "pool Valor sorts by amount_cents"`

**C21** - WHILE `bank_account_id` is set, a sort header URL keeps `bank_account_id` (AC 21)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "sort header URLs keep bank_account_id"`

**C22** - IF `payments_sort` is not `date` or `amount`, or `pool_sort` is not `date` or `payee` or `amount`, or a `*_dir` is not `asc` or `desc`, THAT list uses date ascending then `id` ascending (AC 22)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "invalid sort and dir params fall back to date ascending"`

**C23** - Unauthenticated `GET /months/2026-05` responds `302` to `/login` (AC 23)
Proof: `bin/rspec spec/requests/months_spec.rb -e "unauthenticated GET /months/2026-05 responds 302 to /login"`

**C30** - Submitter `GET /months/2026-05` responds `404` (Surface)
Proof: `bin/rspec spec/requests/months_spec.rb -e "submitter GET /months/2026-05 responds 404 and omits PIX Isolado"`

**C31** - Coordinator `GET /months/2026-05` when that month does not exist responds `404` (Surface)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-04 when never opened responds 404"`

### S4 - Pagamentos Status has no suggestion line

**C24** - WHILE a missing payment has a document suggestion, `GET /months/2026-05` that payment’s `[data-cell=status]` includes `Documento faltante` and does not include `Sugestão` (AC 24)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "Pagamentos status includes Documento faltante without document Sugestao"`

**C25** - WHILE a missing payment has an exception suggestion, `GET /months/2026-05` that payment’s `[data-cell=status]` includes `Documento faltante` and does not include `Sugestão de exceção` (AC 25)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "Pagamentos status includes Documento faltante without Sugestao de excecao"`

**C26** - WHILE a missing payment has an exception suggestion, `GET /months/2026-05/matches` that payment row still includes `Sugestão de exceção` (AC 26)
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches still includes Sugestao de excecao"`

### S5 - Pool has no selector and no last column

**C27** - `GET /months/2026-05` with unmatched documents: Documentos sem casamento head cells are `Data`, `Favorecido`, `Tipo`, `Valor`, `Foto` only; the page does not include `name="supporting_document_ids[]"` and does not include `Devolver` (AC 27)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "pool heads are Data Favorecido Tipo Valor Foto without checkbox or Devolver"`

**C28** - WHILE an unmatched document has `month_id` equal to this month, `GET /months/2026-05` lists the payee and does not include `Devolver` (AC 28)
Proof: `bin/rspec spec/requests/month_overview_lists_spec.rb -e "pool lists unmatched month document payee without Devolver"`

**C29** - WHILE the pool is empty, `GET /months/2026-05` fold includes `Nenhum documento sem casamento` (AC 29)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 with no unmatched documents includes Nenhum documento sem casamento"`

**C32** - Visual-identity month ASCII no longer draws disabled Iniciar, Sugestão under Pagamentos Status, the pool checkbox, or a Devolver column (Changes underneath)
Proof: `bin/rspec spec/docs/visual_identity_month_overview_spec.rb -e "visual-identity month omits disabled Iniciar Sugestao under Status pool checkbox and Devolver"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| `POST /months/:year_month/account_confirmation` statuses (5) | `302` success C4 · `422` no spreadsheet C2 · `422` closed C3 · `302` `/login` C5 · `404` submitter C6 | - |
| `GET /months/:year_month` statuses (3) | `200` C1 · `302` `/login` C23 · `404` submitter C30 · `404` unknown month C31 | - |
| catalog matcher examples (8) | skip insert C7 · leftover lists C8 · close gate C9 · resumo C10 · case C11 · COMPE `033` C12 · credit inflow C13 · toast count C14 | - |
| Landing catalog row (3) | COMPE `001` C7 · debit not credit C13 · substring `rende facil` C11 | - |
| sort params (8) | default date C15 · Pagamentos amount desc C16 · toggle asc C17 · independent inflows C18 · pool payee C19 · pool amount C20 · `bank_account_id` C21 · invalid fallback C22 | - |
| Pagamentos Status lines (3) | document suggestion omitted C24 · exception suggestion omitted C25 · Casar still shows exception suggestion C26 | - |
| pool controls (4) | heads only C27 · no checkbox C27 · no Devolver C27, C28 · empty copy C29 | - |

- Claims naming a status code, route or response shape: C1–C6, C9, C23, C30, C31 - each has a proof that crosses the boundary
- No other check claims more than the single case its proof exercises
- Catalog membership is table-driven in `investment_transfer_catalog_spec.rb` (C7, C11, C12, C13)

## Swept

- validation: C22 - unknown `*_sort` / `*_dir` fall back to date ascending
- failure modes: C2, C3 - refused confirm is `422` with error toast and no `accounts_confirmed` write
- idempotency: existing - second `POST account_confirmation` after success stays confirmed (`months_account_confirmation_spec.rb` "second POST account_confirmation is idempotent")
- authorization: C5, C6, C23, C30 - unsigned `302` `/login`; submitter `404`
- concurrency: n/a - `confirm_accounts` is a boolean already true on retry; catalog match is a pure function of COMPE plus history
- data lifecycle: C7, C8 - new imports skip insert; leftover Payment rows are hidden by the live reader rule with no migration
- dependency failure: n/a - no external call in this slice
- state transitions: C2, C4 - refused confirm stays Unconfirmed; success moves to Confirmed
- observability: n/a - no logging requirement in this slice

## Handoff

- **Settled mid-build:** none
- **Dispatched:** Verifier at `f2a6f02` range `5311bc1..HEAD` returned
- **Boundary:** C1-C32 closed at `f2a6f02`
- **Abandoned:** none
- **Walked:** Signed in on `/login` via Ambiente local (`gutors@gmail.com`). Opened `/months/2026-09` (unconfirmed, no spreadsheet). `Iniciar fechamento` was enabled; a click posted and showed the error toast `Inclua o extrato planilha de pelo menos uma conta bancária.` plus the GET notice. This local month has no confirmed lists, so Pagamentos sort, catalog omit, and pool columns were not walked in the browser (covered by request specs).
