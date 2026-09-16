# Bank statement upload checks

Profile: standard
Plan: `.specs/features/bank-statement-upload/plan.md`

50 checks in 4 slices · 5 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.

## Checks

### S1 - Open month and account cards · door 2

**C1** - Unauthenticated `GET /months/2026-05` responds `302` to `/login` (MONTH-01, AC 1)
Proof: `bin/rspec spec/requests/months_spec.rb -e "unauthenticated GET /months/2026-05 responds 302 to /login"`

**C2** - `GET /months/2026-05` with a session and no focused organization responds `302` to `/login` (MONTH-01, AC 2)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 without focus responds 302 to /login"`

**C3** - Authenticated `GET /` includes the heading `Meses` and a form that posts `year_month` to `/months` (MONTH-01, AC 3)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "organization home includes Meses form posting year_month to /months"`

**C4** - `GET /` includes `Nenhum mês aberto` when the focused organization has no Month (MONTH-01, AC 4)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "GET / with no Month includes Nenhum mes aberto"`

**C5** - `POST /months` with `year_month=2026-05` persists one Month for the focused organization and that calendar month and responds `302` to `/months/2026-05` (MONTH-01, AC 5, door 2)
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months 2026-05 persists Month and redirects"`
Proof: `bin/rspec spec/models/month_spec.rb -e "opens 2026-05 for the organization"`

**C6** - `POST /months` with `year_month=2026-05` when that Month already exists persists no second Month and responds `302` to `/months/2026-05` (MONTH-01, AC 6, door 2)
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months 2026-05 a second time does not duplicate"`
Proof: `bin/rspec spec/models/month_spec.rb -e "finds existing 2026-05 rather than creating a second"`

**C7** - Authenticated `GET /months/2026-05` responds `200`, uses locale `pt-BR`, and includes `2026-05` (MONTH-01, AC 7)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 responds 200 with pt-BR and 2026-05"`

**C8** - `GET /months/2026-05` includes `Nenhuma conta bancária ativa` when the focused organization has zero active BankAccounts (MONTH-01, AC 8)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 with zero active accounts includes Nenhuma conta bancaria ativa"`

**C9** - `GET /months/2026-05` includes the active BankAccount unique name and `Falta` when that account has no statement for that Month (MONTH-01, AC 9)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 includes active account name and Falta"`

**C10** - `GET /months/2026-05` includes the BankAccount coordinates text on that account’s card (MONTH-01, AC 10)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 includes coordinates on the account card"`

**C11** - `GET /` after Month `2026-05` exists includes a link whose text is `2026-05` and whose href is `/months/2026-05` (MONTH-01, AC 11)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "GET / links 2026-05 to /months/2026-05"`

**C12** - `POST /months` with `year_month=2026-13` persists no Month and responds `422` (MONTH-01, AC 12)
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months 2026-13 returns 422"`
Proof: `bin/rspec spec/models/month_spec.rb -e "rejects year_month 2026-13"`

**C13** - `GET /months/2026-13` responds `404` (MONTH-01, AC 13)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-13 responds 404"`

**C14** - `GET /months/2026-04` when that organization has no Month for `2026-04` responds `404` (MONTH-01, AC 14)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-04 when never opened responds 404"`

**C15** - Unauthenticated `POST /months` persists no Month and responds `302` to `/login` (MONTH-01, AC 15)
Proof: `bin/rspec spec/requests/months_spec.rb -e "unauthenticated POST /months responds 302 to /login"`

**C16** - `GET /months/2026-05` while focused on organization A does not include BankAccount unique names that belong only to organization B (MONTH-01, AC 16)
Proof: `bin/rspec spec/requests/months_spec.rb -e "month page does not include another organization bank account names"`

**C47** - Two concurrent `POST /months` with `year_month=2026-05` for the same organization persist exactly one Month (door 2)
Proof: `bin/rspec spec/models/month_spec.rb -e "concurrent opens persist exactly one Month"`

**C49** - Unauthenticated `GET /` responds `302` to `/login` (Surface `GET /`)
Proof: `bin/rspec spec/requests/sessions_spec.rb -e "unauthenticated GET / responds 302 to /login"`

### S2 - Banco do Brasil upload · door 1 · door 3 · door 4 · door 5

**C17** - `POST /months/2026-05/bank_statements` with a PDF and the BB May 2026 fixture `.xlsx` for an active COMPE `001` BankAccount persists one BankStatement for that pair, responds `302` to `/months/2026-05`, and that card includes `Presente` plus both original filenames (STMT-01, AC 17, door 3, door 5)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST BB xlsx persists statement Presente and filenames"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "import BB xlsx persists one BankStatement for the month and account"`

**C18** - Importing that BB fixture for `2026-05` persists exactly 18 Inflows and exactly 13 Payments on that BankStatement (STMT-01, AC 18, door 4)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST BB xlsx persists 18 Inflows and 13 Payments"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "BB May 2026 fixture yields 18 Inflows and 13 Payments"`

**C19** - Importing that BB fixture persists a Payment of `15500` cents dated `2026-05-11` whose history includes `Tarifa Pacote de Serviços` (STMT-01, AC 19, door 4)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST BB xlsx persists tarifa Payment 15500 cents"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "BB fixture tarifa is Payment 15500 cents on 2026-05-11"`

**C20** - Importing that BB fixture persists an Inflow of `6300` cents dated `2026-05-04` whose history is `Pix - Recebido — 04/05 17:51 DIEGO OLIVEIRA VIEIRA` (STMT-01, AC 20, door 4)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST BB xlsx persists Pix Recebido Inflow 6300 cents"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "BB fixture Pix Recebido is Inflow 6300 cents with detalhamento"`

**C21** - Importing that BB fixture persists no Inflow and no Payment whose history is `Saldo Anterior` or `S A L D O` (STMT-01, AC 21)
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "BB fixture skips Saldo Anterior and S A L D O"`

**C22** - `GET /months/2026-05` after that import includes headings `Recebimentos` and `Pagamentos`, the date `11/05/2026`, the amount `R$ 155,00`, and that BankAccount’s unique name on that payment row (STMT-01, AC 22)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "GET /months/2026-05 lists tarifa under Pagamentos as R$ 155,00"`

**C23** - Inflow and Payment amounts persist as integer cents (`15500` for `R$ 155,00`) (STMT-01, AC 23)
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "tarifa amount_cents is Integer 15500"`

**C24** - A successful import attaches a PDF blob and a spreadsheet blob through Active Storage and not through Drive (STMT-01, AC 24, door 1)
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "import attaches pdf and spreadsheet via Active Storage"`

**C25** - `POST /months/2026-05/bank_statements` with only a PDF and no spreadsheet persists no BankStatement and responds `422` with `Envie o PDF e a planilha` (STMT-01, AC 25)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST pdf only returns 422 Envie o PDF e a planilha"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "rejects import without spreadsheet"`

**C26** - `POST /months/2026-05/bank_statements` with only a spreadsheet and no PDF persists no BankStatement and responds `422` with `Envie o PDF e a planilha` (STMT-01, AC 26)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST spreadsheet only returns 422 Envie o PDF e a planilha"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "rejects import without pdf"`

**C27** - `POST /months/2026-05/bank_statements` with a `.xlsx` whose header row is not the 11 BB names for a COMPE `001` account persists no BankStatement and responds `422` with `Não foi possível ler a planilha` (STMT-01, AC 27)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST BB scrambled headers returns 422 Nao foi possivel ler a planilha"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "rejects BB xlsx whose headers are not the eleven names"`

**C28** - `POST /months/2026-05/bank_statements` with a PDF and a `.csv` whose header row is those 11 BB names and whose data rows match the BB fixture persists exactly 18 Inflows and exactly 13 Payments (STMT-01, AC 28, door 5)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST BB csv persists 18 Inflows and 13 Payments"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "import BB csv yields 18 Inflows and 13 Payments"`

**C29** - Unauthenticated `POST /months/2026-05/bank_statements` persists no BankStatement and responds `302` to `/login` (STMT-01, AC 29)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "unauthenticated POST bank_statements responds 302 to /login"`

**C48** - The Rails app loads Active Storage; the test service is Disk with root `tmp/storage`; `config/storage.yml` defines no Drive service; Kamal is still absent (door 1)
Proof: `bin/rspec spec/config/application_spec.rb -e "loads Active Storage Disk test service, skips Drive and Kamal"`

### S3 - PagSeguro, replace, unsupported bank · door 3 · door 4

**C30** - `POST /months/2026-05/bank_statements` with a PDF and the PagSeguro May 2026 fixture `.xlsx` for an active COMPE `290` BankAccount persists exactly 64 Inflows and exactly 7 Payments (STMT-02, AC 30, door 4)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST PagSeguro xlsx persists 64 Inflows and 7 Payments"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro May 2026 fixture yields 64 Inflows and 7 Payments"`

**C31** - Importing that PagSeguro fixture persists no Inflow and no Payment whose history starts with `Saldo do dia` (STMT-02, AC 31)
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro fixture skips Saldo do dia"`

**C32** - Importing that PagSeguro fixture persists a Payment of `151240` cents dated `2026-05-11` whose history is `Pix enviado — VITOR CASTRO FERREIRA` (STMT-02, AC 32, door 4)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST PagSeguro xlsx persists Pix enviado Payment 151240 cents"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro Pix enviado is Payment 151240 cents on 2026-05-11"`

**C33** - Importing that PagSeguro fixture persists an Inflow of `2` cents dated `2026-05-01` whose history is `Rendimento da conta — Rendimento líquido sobre dinheiro em conta` (STMT-02, AC 33, door 4)
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro rendimento is Inflow 2 cents on 2026-05-01"`

**C34** - A second `POST /months/2026-05/bank_statements` for a BankAccount that already has a BankStatement persists exactly one BankStatement for that pair, persists only the new files’ Inflows and Payments, and leaves none of the previous Inflow or Payment rows (STMT-02, AC 34, door 3)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST replace drops previous tarifa Payment"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "replace keeps one BankStatement and only new movements"`

**C35** - `POST /months/2026-05/bank_statements` for an active BankAccount whose COMPE is `341` persists no BankStatement and responds `422` with `Este banco ainda não tem leitura de planilha` (STMT-02, AC 35)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST Itau COMPE 341 returns 422 Este banco ainda nao tem leitura"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "rejects COMPE 341"`

**C36** - Two concurrent statement imports for the same BankAccount and Month persist exactly one BankStatement for that pair (STMT-02, AC 36, door 3)
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "concurrent imports persist exactly one BankStatement"`

### S4 - Isolation, inactive, bounds

**C37** - `POST /months/2026-05/bank_statements` for a BankAccount not on the focused organization leaves that organization unchanged and responds `404` (STMT-03, AC 37)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST bank_statements of another organization returns 404"`

**C38** - `POST /months/2026-05/bank_statements` for an inactive BankAccount with no statement on that Month persists no BankStatement and responds `404` (STMT-03, AC 38)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST bank_statements for inactive account returns 404"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "rejects import for inactive BankAccount with no statement"`

**C39** - After deactivating a BankAccount that already has a BankStatement on Month `2026-05`, `GET /months/2026-05` still includes that statement’s Payment histories and does not include `Falta` for that account (STMT-03, AC 39)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "GET /months/2026-05 after deactivate still lists Payment and omits Falta"`

**C40** - `POST /months/2026-05/bank_statements` with a PDF or spreadsheet larger than `10485760` bytes persists no BankStatement and responds `422` with `Cada arquivo pode ter no máximo 10 MB` (STMT-03, AC 40)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST file of 10485761 bytes returns 422 max 10 MB"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "rejects a file larger than 10485760 bytes"`

**C41** - `POST /months/2026-05/bank_statements` with a movement file whose extension is `.ofx` persists no BankStatement and responds `422` with `Envie o PDF e a planilha` (STMT-03, AC 41)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST ofx spreadsheet returns 422 Envie o PDF e a planilha"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "rejects movement file extension ofx"`

**C42** - `POST /months/2026-05/bank_statements` of a COMPE `001` spreadsheet that, after skip rules, contains a movement dated `2026-04-01` persists no BankStatement and responds `422` with `A planilha tem movimentação fora de 2026-05` (STMT-03, AC 42)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST BB row dated 2026-04-01 returns 422 fora de 2026-05"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "rejects BB movement whose date is not in 2026-05"`

**C43** - Importing a spreadsheet that yields zero Inflows and zero Payments after skip rules persists the BankStatement and `GET /months/2026-05` includes `Presente` for that account (STMT-03, AC 43)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST zero-row spreadsheet persists Presente"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "zero movements after skips still persist BankStatement"`

**C44** - `GET /months/2026-05` while focused on organization A does not include Inflow or Payment history text that exists only on organization B’s statements (STMT-03, AC 44)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "month page does not include another organization Payment history"`

**C45** - `GET /months/2026-05` lists Payment dates in ascending order (STMT-03, AC 45)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "GET /months/2026-05 lists Payment dates ascending"`

**C46** - `DELETE /months/2026-05` leaves the Month in place and responds `404` (STMT-03, AC 46, door 2)
Proof: `bin/rspec spec/requests/months_spec.rb -e "DELETE /months/2026-05 returns 404 and keeps the Month"`

**C50** - `BankStatement` attaches files as `pdf` and `spreadsheet` (door 1)
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "has_one_attached pdf and spreadsheet"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| `GET /` statuses (2) | 200 C3 · 302 C49 | - |
| `POST /months` statuses (2) | 302 C5 · 422 C12 | - |
| `GET /months/:year_month` statuses (3) | 200 C7 · 302 C1 · 404 C13 | - |
| `GET /months/:year_month` 404 reasons (2) | invalid `2026-13` C13 · never opened `2026-04` C14 | - |
| `POST /months/:year_month/bank_statements` statuses (3) | 302 C17 · 422 C25 · 404 C37 | - |
| `DELETE /months/:year_month` statuses (1) | 404 C46 | - |
| statement 422 reasons (7) | pdf only C25 · spreadsheet only C26 · bad headers C27 · COMPE `341` C35 · oversized C40 · `.ofx` C41 · date outside month C42 | - |
| statement 404 reasons (2) | other organization C37 · inactive without statement C38 | - |
| supported COMPE (2) | `001` C18 · `290` C30 | - |
| spreadsheet extensions accepted (2) | `.xlsx` C18 · `.csv` C28 | - |
| BB skip histories (2) | `Saldo Anterior` C21 · `S A L D O` C21 | - |
| PagSeguro skip (1) | `Saldo do dia` C31 | - |
| credit vs debit (4) | BB `C` Inflow C20 · BB `D` Payment C19 · PagSeguro `Entradas` Inflow C33 · PagSeguro `Saidas` Payment C32 | - |
| Active Storage attachments (2) | `pdf` C50 · `spreadsheet` C50 | - |
| Month uniqueness (2) | second POST C6 · concurrent C47 | - |
| BankStatement uniqueness (2) | replace C34 · concurrent C36 | - |
| Relations entities (6) | Organization C5 · Month C5 · BankAccount C9 · BankStatement C17 · Inflow C18 · Payment C18 | - |
| Landing doors (5) | Active Storage C48 · Month identity C5 · one statement C34 · Inflow vs Payment C18 · rubyXL/CSV C17 | - |
| startup config: Active Storage (1 assembly) | Rails test app C48 | - |

- Claims naming a status code, route or response shape: C1, C2, C3, C5, C7, C12, C13, C14, C15, C17, C25, C26, C27, C29, C35, C37, C38, C40, C41, C42, C46, C49 - each has a proof that crosses the HTTP boundary
- No other check claims more than the single case its proof exercises, except C21 (2 BB skip histories) and C50 (2 attachment names), each table-driven over the whole set

## Test policy

`.cursor/rules/rails.mdc` already answers which level proves which code and how much of the input space counts. This build runs under those rows; they are not proposed as a new guideline commit.

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Decides, reached across a boundary | one at the boundary **and** one at its own layer | the contract at the boundary; one asserted case per row of the decision table at its own layer |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member |
| Entry point that decides nothing | one at the boundary | accepted input, each rejected input, each error path |
| Instrumentation, pass-throughs | none of its own | covered by its consumer's proof |

Evidence (classified from the approved plan):

- Month open/find/reject: 3 outcomes (`2026-05` create, `2026-05` find, `2026-13` reject) plus concurrent unique -> decides, reached across `POST /months`
- Statement import: COMPE `001`/`290`/`341`, skip-row tables, credit vs debit, date-in-month, both files required, extension, 10 MiB bound, replace, inactive -> decides, reached across `POST /months/:year_month/bank_statements`
- Active Storage service and attachment names: startup plus model declarations -> decides, not a coordinator write of config; proven at own layer C48, C50; blob presence after import C24
- closest analogue in the repo: `spec/models/bank_account_spec.rb` + `spec/requests/bank_accounts_spec.rb` — persist, uniqueness including concurrent, 422 at the HTTP boundary

Cost: dual proofs on Month write (C5, C6, C12), statement import accepts (C17–C20, C28, C30, C32, C34, C43) and rejects (C25–C27, C35, C38, C40–C42). Without those own-layer proofs the COMPE and skip tables would be proven only by a path that happens to traverse them.

## Swept

- validation: C12, C27, C40, C41, C42
- failure modes: C25, C26, C35
- idempotency: C6, C34
- authorization: C1, C2, C15, C29, C37
- concurrency: C36, C47
- data lifecycle: C34, C39, C46 - replace drops previous movements; deactivate keeps them; Month is never deleted
- dependency failure: n/a - no Drive or bank HTTP in this cut; blobs are local Disk
- state transitions: C9, C17, C34 - `Falta` to `Presente`; replace stays one statement; no closed Month in this cut
- observability: n/a - no logging or metrics criterion in the plan

## Handoff

- S1–S4 share `Month`, `BankStatement`, and `/months/:year_month`. Estimated ~22 product/spec files (month + statement models, Active Storage install, two readers, fixtures, request specs) ≪ 150k tokens. One builder, no split.
- S1-S4 = one builder
- **Boundary:** C1-C50 closed at `b483091`
- **Settled mid-build:** none
- **Abandoned:** string-appending an April row onto the BB CSV made `CSV.parse` fail, so the date-outside-month path looked like an unreadable file; the extra row is written with the csv library instead.
