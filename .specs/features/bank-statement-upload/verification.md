# Bank statement upload verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: 68771ba..HEAD
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

User walk skipped: HTML request-spec feature; no human UI walk required.

Proofs re-run in full at HEAD `0dd963ff18a62c7ab632d3ff6ca79c5af076806e`: one `bin/rspec` invocation over the seven proof files plus one `--example-matches` alternation of every named selector — 70 examples, 0 failures. Every named example existed (`rg -n` / `it "..."` hit, 70/70) and appeared as passed in that run. C49’s example lives in `spec/requests/sessions_spec.rb`, which is **not** in `68771ba..HEAD`; it is the existing Surface `GET /` 302, re-run at HEAD.

Real-tree porcelain at start (not Verifier mutations): `M .specs/LESSONS.md`, `M .specs/STATE.md`, `M .specs/lessons.json`, `?? .specs/features/bank-statement-upload/verification.md`. Worktree discard left that baseline unchanged.

Fix after round 1: `0dd963f` only. C21 claim unchanged; proof now requires persist and non-empty histories.

## Binding sources

Carried from `f0a61d4`. Step 1 is `ui` only; the C21 fix did not touch the interface. Plan: "No design source for the screens. Verification stays on project profile `standard` (no binding screen, so not `ui`)." Did not drop to light.

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| n/a — no binding screen | n/a | none | - |

## Checks

Proofs verified at `0dd963f`. Evidence for every `spec/models/bank_statement_spec.rb` citation verified at `0dd963f` (the fix inserted two assertions in the C21 example and shifted later lines). Other files’ citations carried from `f0a61d4`.

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | unauthenticated GET /months/2026-05 is 302 to /login | batch exit 0 at `0dd963f`; `-e "unauthenticated GET /months/2026-05 responds 302 to /login"` passed | `spec/requests/months_spec.rb:7` - `expect(response).to have_http_status(:found)` ; `spec/requests/months_spec.rb:8` - `expect(response).to redirect_to("/login")` | PASS |
| C2 | GET /months/2026-05 without focus is 302 to /login | batch exit 0 at `0dd963f`; `-e "GET /months/2026-05 without focus responds 302 to /login"` passed | `spec/requests/months_spec.rb:20` - `expect(response).to have_http_status(:found)` ; `spec/requests/months_spec.rb:21` - `expect(response).to redirect_to("/login")` | PASS |
| C3 | authenticated GET / includes Meses form posting year_month to /months | batch exit 0 at `0dd963f`; `-e "organization home includes Meses form posting year_month to /months"` passed | `spec/requests/organizations_spec.rb:82` - `have_http_status(:ok)` ; `spec/requests/organizations_spec.rb:83` - `include("Meses")` ; `spec/requests/organizations_spec.rb:84` - `include('action="/months"')` ; `spec/requests/organizations_spec.rb:85` - `include('name="year_month"')` | PASS |
| C4 | GET / with no Month includes Nenhum mês aberto | batch exit 0 at `0dd963f`; `-e "GET / with no Month includes Nenhum mes aberto"` passed | `spec/requests/organizations_spec.rb:94` - `expect(response.body).to include("Nenhum mês aberto")` | PASS |
| C5 | POST /months 2026-05 persists one Month and 302 to /months/2026-05 | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/months_spec.rb:30-32` - `:found`, `redirect_to("/months/2026-05")`, `count).to eq(1)` ; `spec/models/month_spec.rb:11-14` - `be_persisted`, `eq("2026-05")`, `eq(organization)`, `count).to eq(1)` | PASS |
| C6 | second POST /months 2026-05 persists no second Month, 302 | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/months_spec.rb:42-44` - `:found`, `redirect_to("/months/2026-05")`, `count).to eq(1)` ; `spec/models/month_spec.rb:21-22` - `expect(second).to eq(first)`, `count).to eq(1)` | PASS |
| C7 | GET /months/2026-05 is 200, pt-BR, includes 2026-05 | batch exit 0 at `0dd963f`; `-e "GET /months/2026-05 responds 200 with pt-BR and 2026-05"` passed | `spec/requests/months_spec.rb:54` - `have_http_status(:ok)` ; `spec/requests/months_spec.rb:55` - `include('lang="pt-BR"')` ; `spec/requests/months_spec.rb:56` - `include("2026-05")` | PASS |
| C8 | zero active accounts includes Nenhuma conta bancária ativa | batch exit 0 at `0dd963f`; `-e "GET /months/2026-05 with zero active accounts includes Nenhuma conta bancaria ativa"` passed | `spec/requests/months_spec.rb:66` - `expect(response.body).to include("Nenhuma conta bancária ativa")` | PASS |
| C9 | active account name and Falta | batch exit 0 at `0dd963f`; `-e "GET /months/2026-05 includes active account name and Falta"` passed | `spec/requests/months_spec.rb:77` - `include("Conta Principal")` ; `spec/requests/months_spec.rb:78` - `include("Falta")` | PASS |
| C10 | coordinates on the account card | batch exit 0 at `0dd963f`; `-e "GET /months/2026-05 includes coordinates on the account card"` passed | `spec/requests/months_spec.rb:89` - `expect(response.body).to include("ag 1234")` | PASS |
| C11 | GET / links 2026-05 to /months/2026-05 | batch exit 0 at `0dd963f`; `-e "GET / links 2026-05 to /months/2026-05"` passed | `spec/requests/organizations_spec.rb:104` - `include("2026-05")` ; `spec/requests/organizations_spec.rb:105` - `include('href="/months/2026-05"')` | PASS |
| C12 | POST year_month=2026-13 persists no Month, 422 | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/months_spec.rb:96-98` - `not_to change(Month, :count)` ; `spec/requests/months_spec.rb:100` - `have_http_status(:unprocessable_content)` ; `spec/models/month_spec.rb:28-29` - `not_to be_persisted`, `months.count).to eq(0)` | PASS |
| C13 | GET /months/2026-13 is 404 | batch exit 0 at `0dd963f`; `-e "GET /months/2026-13 responds 404"` passed | `spec/requests/months_spec.rb:109` - `expect(response).to have_http_status(:not_found)` | PASS |
| C14 | GET /months/2026-04 never opened is 404 | batch exit 0 at `0dd963f`; `-e "GET /months/2026-04 when never opened responds 404"` passed | `spec/requests/months_spec.rb:118` - `expect(response).to have_http_status(:not_found)` | PASS |
| C15 | unauthenticated POST /months persists no Month, 302 to /login | batch exit 0 at `0dd963f`; `-e "unauthenticated POST /months responds 302 to /login"` passed | `spec/requests/months_spec.rb:122-124` - `not_to change(Month, :count)` ; `spec/requests/months_spec.rb:126-127` - `:found`, `redirect_to("/login")` | PASS |
| C16 | month page omits other-org bank account names | batch exit 0 at `0dd963f`; `-e "month page does not include another organization bank account names"` passed | `spec/requests/months_spec.rb:141` - `include("Conta Alfa")` ; `spec/requests/months_spec.rb:142` - `not_to include("Conta Beta")` | PASS |
| C47 | concurrent POST-equivalent opens persist exactly one Month | batch exit 0 at `0dd963f`; `-e "concurrent opens persist exactly one Month"` passed | `spec/models/month_spec.rb:45` - `expect(Month.where(organization: org, year_month: "2026-05").count).to eq(1)` | PASS |
| C49 | unauthenticated GET / is 302 to /login | batch exit 0 at `0dd963f`; `-e "unauthenticated GET / responds 302 to /login"` passed | `spec/requests/sessions_spec.rb:7` - `have_http_status(:found)` ; `spec/requests/sessions_spec.rb:8` - `redirect_to("/login")` (example not in `68771ba..HEAD`; existing Surface status, ran at HEAD) | PASS |
| C17 | POST BB xlsx persists one statement, 302, Presente and filenames | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:19-26` - `:found`, `redirect_to("/months/2026-05")`, `count).to eq(1)`, `include("Presente")`, `include("extrato-maio-2026.pdf")`, `include("extrato-maio-2026.xlsx")` ; `spec/models/bank_statement_spec.rb:28-31` - `be_persisted`, `eq(month)`, `eq(bb_account)`, `count).to eq(1)` | PASS |
| C18 | BB fixture yields 18 Inflows and 13 Payments | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:37-38` - `inflows.count).to eq(18)`, `payments.count).to eq(13)` ; `spec/models/bank_statement_spec.rb:37-38` - same 18 / 13 | PASS |
| C19 | BB tarifa Payment 15500 cents on 2026-05-11 | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:49-50` - `eq(Date.new(2026, 5, 11))`, `include("Tarifa Pacote de Serviços")` ; `spec/models/bank_statement_spec.rb:45-46` - same | PASS |
| C20 | BB Pix Recebido Inflow 6300 cents with detalhamento | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:61` - `eq("Pix - Recebido — 04/05 17:51 DIEGO OLIVEIRA VIEIRA")` ; `spec/models/bank_statement_spec.rb:53` - same `eq` | PASS |
| C21 | BB fixture skips Saldo Anterior and S A L D O | batch exit 0 at `0dd963f`; `-e "BB fixture skips Saldo Anterior and S A L D O"` passed | `spec/models/bank_statement_spec.rb:58` - `expect(statement).to be_persisted` ; `spec/models/bank_statement_spec.rb:61` - `expect(histories).not_to be_empty` ; `spec/models/bank_statement_spec.rb:62` - `not_to include("Saldo Anterior")` ; `spec/models/bank_statement_spec.rb:63` - `not_to include("S A L D O")` | PASS |
| C22 | month page lists tarifa under Pagamentos as R$ 155,00 | batch exit 0 at `0dd963f`; `-e "GET /months/2026-05 lists tarifa under Pagamentos as R$ 155,00"` passed | `spec/requests/bank_statements_spec.rb:72-76` - `include("Recebimentos")`, `include("Pagamentos")`, `include("11/05/2026")`, `include("R$ 155,00")`, `include("Conta Principal")` (name is page-wide, not row-scoped) | PASS |
| C23 | tarifa amount_cents is Integer 15500 | batch exit 0 at `0dd963f`; `-e "tarifa amount_cents is Integer 15500"` passed | `spec/models/bank_statement_spec.rb:71` - `expect(payment.amount_cents).to be_a(Integer)` ; `spec/models/bank_statement_spec.rb:72` - `eq(15500)` | PASS |
| C24 | import attaches pdf and spreadsheet via Active Storage, not Drive | batch exit 0 at `0dd963f`; `-e "import attaches pdf and spreadsheet via Active Storage"` passed | `spec/models/bank_statement_spec.rb:78-79` - `pdf).to be_attached`, `spreadsheet).to be_attached` ; `spec/models/bank_statement_spec.rb:80-81` - `service_name).to eq("test")` twice ; `spec/models/bank_statement_spec.rb:82` - `not_to match(/Drive/)` | PASS |
| C25 | POST pdf only is 422 Envie o PDF e a planilha, no statement | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:86-88` - `:unprocessable_content`, `include("Envie o PDF e a planilha")`, `count).to eq(0)` ; `spec/models/bank_statement_spec.rb:88-89` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C26 | POST spreadsheet only is 422 Envie o PDF e a planilha, no statement | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:97-100` - `:unprocessable_content`, `include("Envie o PDF e a planilha")`, `count).to eq(0)` ; `spec/models/bank_statement_spec.rb:95-96` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C27 | scrambled BB headers is 422 Não foi possível ler a planilha | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:110-112` - `:unprocessable_content`, `include("Não foi possível ler a planilha")`, `count).to eq(0)` ; `spec/models/bank_statement_spec.rb:102-103` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C28 | POST BB csv persists 18 Inflows and 13 Payments | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:123-124` - `eq(18)`, `eq(13)` ; `spec/models/bank_statement_spec.rb:109-110` - same | PASS |
| C29 | unauthenticated POST bank_statements persists none, 302 to /login | batch exit 0 at `0dd963f`; `-e "unauthenticated POST bank_statements responds 302 to /login"` passed | `spec/requests/bank_statements_spec.rb:128-132` - `not_to change(BankStatement, :count)` ; `spec/requests/bank_statements_spec.rb:134-135` - `:found`, `redirect_to("/login")` | PASS |
| C48 | loads Active Storage Disk test service; no Drive service; Kamal absent | batch exit 0 at `0dd963f`; `-e "loads Active Storage Disk test service, skips Drive and Kamal"` passed | `spec/config/application_spec.rb:9-16` - `defined?(ActiveStorage::Engine)).not_to be_nil`, `service).to eq(:test)`, `be_a(ActiveStorage::Service::DiskService)`, `include("tmp/storage")`, `not_to match(/Drive/)`, `deploy.yml").not_to exist`, `not_to match(/^\s*gem ["']kamal["']/)` — evidence about the **test** boot only (`config/environments/test.rb:31`); Landing also names development `:local` / `storage/` | PASS |
| C30 | PagSeguro xlsx persists 64 Inflows and 7 Payments | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:146-147` - `eq(64)`, `eq(7)` ; `spec/models/bank_statement_spec.rb:116-117` - same | PASS |
| C31 | PagSeguro skips histories starting with Saldo do dia | batch exit 0 at `0dd963f`; `-e "PagSeguro fixture skips Saldo do dia"` passed | `spec/models/bank_statement_spec.rb:124` - `histories.none? { history.start_with?("Saldo do dia") }` is `true` | PASS |
| C32 | PagSeguro Pix enviado Payment 151240 cents on 2026-05-11 | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:158-159` - `eq(Date.new(2026, 5, 11))`, `eq("Pix enviado — VITOR CASTRO FERREIRA")` ; `spec/models/bank_statement_spec.rb:131-132` - same | PASS |
| C33 | PagSeguro rendimento Inflow 2 cents on 2026-05-01 | batch exit 0 at `0dd963f`; `-e "PagSeguro rendimento is Inflow 2 cents on 2026-05-01"` passed | `spec/models/bank_statement_spec.rb:139` - `eq("Rendimento da conta — Rendimento líquido sobre dinheiro em conta")` | PASS |
| C34 | replace keeps one BankStatement and drops previous tarifa | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:172-174` - `bank_statements.count).to eq(1)`, `Payment.where(...Tarifa...).to be_empty`, `payments.count).to eq(1)` ; `spec/models/bank_statement_spec.rb:146-150` - pair count 1, payments 1, inflows 0, tarifa empty | PASS |
| C35 | COMPE 341 is 422 Este banco ainda não tem leitura de planilha | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:184-186` - `:unprocessable_content`, `include("Este banco ainda não tem leitura de planilha")`, `count).to eq(0)` ; `spec/models/bank_statement_spec.rb:157-158` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C36 | concurrent imports persist exactly one BankStatement | batch exit 0 at `0dd963f`; `-e "concurrent imports persist exactly one BankStatement"` passed | `spec/models/bank_statement_spec.rb:213` - `expect(BankStatement.where(month: opened, bank_account: account).count).to eq(1)` | PASS |
| C37 | POST other-org bank account is 404, that org unchanged | batch exit 0 at `0dd963f`; `-e "POST bank_statements of another organization returns 404"` passed | `spec/requests/bank_statements_spec.rb:201` - `have_http_status(:not_found)` ; `spec/requests/bank_statements_spec.rb:202` - `org_b.months.count).to eq(0)` ; `spec/requests/bank_statements_spec.rb:203` - `BankStatement.count).to eq(0)` | PASS |
| C38 | POST inactive account with no statement is 404, persists none | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:214-215` - `:not_found`, `count).to eq(0)` ; `spec/models/bank_statement_spec.rb:165-166` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C39 | after deactivate, GET still lists Payment and omits Falta | batch exit 0 at `0dd963f`; `-e "GET /months/2026-05 after deactivate still lists Payment and omits Falta"` passed | `spec/requests/bank_statements_spec.rb:227` - `include("Tarifa Pacote de Serviços")` ; `spec/requests/bank_statements_spec.rb:228` - `not_to include("Falta")` | PASS |
| C40 | file of 10485761 bytes is 422 max 10 MB, persists none | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:238-240` - `:unprocessable_content`, `include("Cada arquivo pode ter no máximo 10 MB")`, `count).to eq(0)` ; `spec/models/bank_statement_spec.rb:172-173` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C41 | .ofx spreadsheet is 422 Envie o PDF e a planilha | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:250-252` - `:unprocessable_content`, `include("Envie o PDF e a planilha")`, `count).to eq(0)` ; `spec/models/bank_statement_spec.rb:179-180` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C42 | BB row dated 2026-04-01 is 422 fora de 2026-05 | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:262-264` - `:unprocessable_content`, `include("A planilha tem movimentação fora de 2026-05")`, `count).to eq(0)` ; `spec/models/bank_statement_spec.rb:186-187` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C43 | zero-row spreadsheet persists Presente | batch exit 0 at `0dd963f`; both `-e` passed | `spec/requests/bank_statements_spec.rb:275-276` - `bank_statements.count).to eq(1)`, `include("Presente")` ; `spec/models/bank_statement_spec.rb:193-195` - `be_persisted`, `inflows.count).to eq(0)`, `payments.count).to eq(0)` | PASS |
| C44 | month page omits other-org Payment/Inflow history | batch exit 0 at `0dd963f`; `-e "month page does not include another organization Payment history"` passed | `spec/requests/bank_statements_spec.rb:294` - `not_to include("Tarifa Pacote de Serviços")` ; `spec/requests/bank_statements_spec.rb:295` - `not_to include("DIEGO OLIVEIRA VIEIRA")` | PASS |
| C45 | Payment dates listed ascending | batch exit 0 at `0dd963f`; `-e "GET /months/2026-05 lists Payment dates ascending"` passed | `spec/requests/bank_statements_spec.rb:307` - `expect(dates.size).to be >= 2` ; `spec/requests/bank_statements_spec.rb:308` - `expect(dates).to eq(dates.sort)` | PASS |
| C46 | DELETE /months/2026-05 is 404 and keeps the Month | batch exit 0 at `0dd963f`; `-e "DELETE /months/2026-05 returns 404 and keeps the Month"` passed | `spec/requests/months_spec.rb:152` - `have_http_status(:not_found)` ; `spec/requests/months_spec.rb:153` - `months.where(year_month: "2026-05").count).to eq(1)` | PASS |
| C50 | BankStatement has_one_attached pdf and spreadsheet | batch exit 0 at `0dd963f`; `-e "has_one_attached pdf and spreadsheet"` passed | `spec/models/bank_statement_spec.rb:21` - `reflect_on_attachment(:pdf)).to be_present` ; `spec/models/bank_statement_spec.rb:22` - `reflect_on_attachment(:spreadsheet)).to be_present` | PASS |

## Coverage

BB skip histories recomputed at `0dd963f` from plan AC 21 and `BancoDoBrasilSpreadsheet::SKIP` (`app/models/banco_do_brasil_spreadsheet.rb:6`). Other rows carried from `f0a61d4` (fix did not change those authorities). `config/environments/development.rb:31` `:local` is named by door 1; C48 boots only the test assembly (`config/environments/test.rb:31`) and cannot fail a wrong development service — recorded as the startup-config limit, not a missing Surface member.

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| GET / statuses (2) | plan Surface | 200 C3 · 302 C49 | - |
| POST /months statuses (2) | plan Surface | 302 C5 · 422 C12 | - |
| GET /months/:year_month statuses (3) | plan Surface | 200 C7 · 302 C1 · 404 C13 | - |
| GET /months/:year_month 404 reasons (2) | plan AC 13-14 | invalid `2026-13` C13 · never opened `2026-04` C14 | - |
| POST /months/:year_month/bank_statements statuses (3) | plan Surface | 302 C17 · 422 C25 · 404 C37 | - |
| DELETE /months/:year_month statuses (1) | plan Surface | 404 C46 | - |
| statement 422 reasons (7) | plan AC 25-27, 35, 40-42 | pdf only C25 · spreadsheet only C26 · bad headers C27 · COMPE `341` C35 · oversized C40 · `.ofx` C41 · date outside month C42 | - |
| statement 404 reasons (2) | plan AC 37-38 | other organization C37 · inactive without statement C38 | - |
| supported COMPE (2) | plan Landing / AC 18, 30 | `001` C18 · `290` C30 | - |
| spreadsheet extensions accepted (2) | plan Landing door 5 | `.xlsx` C18 · `.csv` C28 | - |
| BB skip histories (2) | plan AC 21; `app/models/banco_do_brasil_spreadsheet.rb:6` `SKIP = [ "Saldo Anterior", "S A L D O" ]`; C21 at HEAD asserts persist, non-empty histories, and both strings absent | `Saldo Anterior` C21 · `S A L D O` C21 | - |
| PagSeguro skip (1) | plan AC 31 | `Saldo do dia` C31 | - |
| credit vs debit (4) | plan Landing door 4 | BB `C` Inflow C20 · BB `D` Payment C19 · PagSeguro `Entradas` Inflow C33 · PagSeguro `Saidas` Payment C32 | - |
| Active Storage attachments (2) | plan Landing door 1 | `pdf` C50 · `spreadsheet` C50 | - |
| Month uniqueness (2) | plan Relations / door 2 | second POST C6 · concurrent C47 | - |
| BankStatement uniqueness (2) | plan Relations / door 3 | replace C34 · concurrent C36 | - |
| Relations entities (6) | plan Relations | Organization C5 · Month C5 · BankAccount C9 · BankStatement C17 · Inflow C18 · Payment C18 | - |
| Landing doors (5) | plan Landing | Active Storage C48 · Month identity C5 · one statement C34 · Inflow vs Payment C18 · rubyXL C17 / CSV C28 | - |
| startup config: Active Storage (1 assembly) | Landing door 1; `config/application.rb:8` `require "active_storage/engine"` ; `config/environments/test.rb:31` `:test` ; `config/storage.yml:1-3` Disk `tmp/storage` | Rails test app C48 | - |

No Surface route lacked a status row. Claims that name a status/route have an HTTP-boundary proof except C47/C36 (concurrency, own layer) and model-only skip/amount/attachment checks as listed.

## Test policy rows

Re-judged at `0dd963f` the row that classifies statement import / `bank_statement_spec.rb`. Other rows carried from `f0a61d4`.

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decides, reached across a boundary | `app/models/month.rb` ; `app/models/bank_statement.rb` ; `app/models/banco_do_brasil_spreadsheet.rb` ; `app/models/pagseguro_spreadsheet.rb` ; `app/models/brl_cents.rb` ; `app/models/spreadsheet_grid.rb` ; `app/models/statement_spreadsheet.rb` ; `app/controllers/months_controller.rb` ; `app/controllers/bank_statements_controller.rb` | boundary + own layer: Month C5, C6, C12 (concurrent unique C47 own-layer only, same shape as close-setup) ; statement accepts C17-C20, C28, C30, C32, C34, C43 and rejects C25-C27, C35, C38, C40-C42 ; COMPE/skip/credit tables asserted in `bank_statement_spec` ; C21 now also asserts persist and non-empty histories so skip members cannot pass on an empty list | yes |
| Decides, not reached across a boundary | `config/application.rb` Active Storage engine ; `config/environments/test.rb` Disk test service ; `BankStatement` attachment names | own layer C48, C50 ; blob presence after import C24 | yes |
| Entry point that decides nothing | `MonthsController#show` after guards ; absent `DELETE /months/:year_month` (no destroy in `config/routes.rb:24-26`) | boundary C7/C13/C14/C46 | yes |
| Instrumentation, pass-throughs | `app/models/inflow.rb` ; `app/models/payment.rb` ; `ApplicationHelper#format_reais` ; `ApplicationController#load_home` / `#load_month_page` | covered by consumer C18, C22, C11, C45 | yes |

## Faults injected

Verified at `0dd963f`. Real-tree porcelain recorded above; mutations ran in scratch worktree `/tmp/bsu-lean-verify-r2` at HEAD `0dd963f`; each file restored between faults; scratch discarded with `git worktree remove --force`; porcelain matched baseline. Cap 5. Surfaces the C21 fix touched or created: persist, non-empty histories, and both skip strings (round-1 empty-SKIP mutant re-injected).

| Mutation | Location | Killed |
| --- | --- | --- |
| BB `SKIP` list emptied to `[]` (round-1 mutant) | `app/models/banco_do_brasil_spreadsheet.rb:6` | yes |
| `persist_import` called with `movements: []` | `app/models/bank_statement.rb:62` | yes |
| `SKIP` dropped `"S A L D O"` (kept `"Saldo Anterior"`) | `app/models/banco_do_brasil_spreadsheet.rb:6` | yes |
| every BB `history` forced to `"Saldo Anterior"` | `app/models/banco_do_brasil_spreadsheet.rb:28` | yes |
| `persist_import` call removed | `app/models/bank_statement.rb:62` | yes |

F1 now fails C21 at `spec/models/bank_statement_spec.rb:58` (`be_persisted`) because the April `Saldo Anterior` row is no longer skipped and the date-outside-month reject leaves the statement unpersisted. F2 fails at `:61` (`not_to be_empty`). F3 fails at `:63` (`not_to include("S A L D O")`) while persist still succeeds. F4 fails at `:62` (`not_to include("Saldo Anterior")`). F5 fails at `:58` (`be_persisted`).

## Swept existing

Carried from `f0a61d4`. checks.md Swept has no `existing` rows (only check ids and `n/a`). Plan Observable `existing`: unauthenticated `/` is still 302 `/login` (`app/controllers/application_controller.rb:27` `require_account` ; C49). Revoke still confirms (`app/views/organizations/show.html.erb:50` `data-turbo-confirm`). Account cards still order by ascending name (`app/controllers/application_controller.rb:40` `@active_bank_accounts = ...order(:name)`). Month uniqueness index `db/schema.rb:126` ; BankStatement uniqueness index `db/schema.rb:86`.

## Gate

`python3 .cursor/skills/tlc-spec-lean/scripts/validate_verification.py bank-statement-upload` — 0 error(s), 0 warning(s), exit 0
