# Close for send checks

Profile: standard
Plan: `.specs/features/close-for-send/plan.md`

74 checks in 5 slices · 5 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.

## Checks

### S1 - Close gates and freeze · door 1 · door 4

**C1** - `POST /months/2026-05/close` for an open Month whose one Payment of `22000` cents is a missing document persists that Month not closed, does not invoke the package-archive writer, and responds `422` with `Há documento faltante` (CLOSE-01, AC 1)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with missing document 22000 cents returns 422 Ha documento faltante"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close with missing document 22000 cents does not close and does not write"`

**C2** - `POST /months/2026-05/close` when active BankAccount `Conta Principal` has no BankStatement persists the Month not closed and responds `422` with `Importe o extrato de cada conta ativa` (CLOSE-01, AC 2)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with active account Falta returns 422 Importe o extrato"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close with active account without statement does not close"`

**C3** - `POST /months/2026-05/close` when the focused organization has no `package_archive_folder_id` persists the Month not closed and responds `422` with `Informe a pasta do arquivo do pacote` (CLOSE-01, AC 3)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close without archive folder id returns 422 Informe a pasta"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close without archive folder id does not close"`

**C4** - `POST /months/2026-05/close` when the focused organization has no accountant presentation name persists the Month not closed and responds `422` with `Cadastre o contador` (CLOSE-01, AC 4)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close without accountant name returns 422 Cadastre o contador"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close without accountant presentation name does not close"`

**C5** - `POST /months/2026-05/close` when every active BankAccount has a BankStatement, accountant presentation name is `Maria Contadora`, package-archive folder id is `15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl`, and every Payment is matched or excepted persists the Month closed, invokes the package-archive writer once, and responds `302` to `/months/2026-05` (CLOSE-01, AC 5, door 1, door 4)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close ready month persists closed 302 and writes once"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close ready month persists closed and writes once"`

**C6** - After that close succeeds, `GET /months/2026-05` responds `200` and includes `Mês fechado` and does not include `Fechar para envio` (CLOSE-01, AC 6)
Proof: `bin/rspec spec/requests/close_spec.rb -e "GET closed 2026-05 includes Mes fechado and omits Fechar para envio"`

**C7** - Unauthenticated `POST /months/2026-05/close` persists no Month closed and responds `302` to `/login` (CLOSE-01, AC 7)
Proof: `bin/rspec spec/requests/close_spec.rb -e "unauthenticated POST close responds 302 to /login"`

**C8** - When the package-archive writer raises, `POST /months/2026-05/close` persists the Month not closed and responds `422` with `Não foi possível gravar no arquivo do pacote` (CLOSE-01, AC 8, door 4)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close when writer raises returns 422 Nao foi possivel gravar"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close when writer raises leaves Month open"`

**C9** - `POST /months/2026-05/close` while the Month is already closed leaves it closed, does not invoke the writer, and responds `422` with `Mês fechado` (CLOSE-01, AC 9, door 1)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close while already closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close while already closed does not write"`

**C10** - `POST /months/2026-05/close` when an inactive BankAccount has no statement, every active BankAccount has a statement, and no Payment is a missing document persists the Month closed and responds `302` (CLOSE-01, AC 10)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with inactive account without statement succeeds 302"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close ignores inactive account without statement"`

### S2 - Summary spreadsheet · door 3

**C11** - After close succeeds for organization `ONG Norte` and Month `2026-05`, the written workbook has exactly one sheet named `2026-05` and includes `Planilha-resumo — ONG Norte` (SHEET-01, AC 11, door 3)
Proof: `bin/rspec spec/requests/close_spec.rb -e "closed package xlsx sheet is 2026-05 titled Planilha-resumo ONG Norte"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "workbook has one sheet 2026-05 titled Planilha-resumo ONG Norte"`

**C12** - When accountant presentation name is `Maria Contadora`, tax id `11222333000181`, and razão social `Contábil LTDA`, that sheet includes `Maria Contadora`, `Contábil LTDA`, and `11.222.333/0001-81` (SHEET-01, AC 12, door 3)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx includes Maria Contadora Contabil LTDA and formatted CNPJ"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "header includes name razao social and formatted CNPJ"`

**C13** - When tax id is CPF `39053344705` and razão social is absent, that sheet includes `390.533.447-05` and does not include a razão social line for that accountant (SHEET-01, AC 13)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx CPF omits razao social and includes formatted CPF"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "CPF header includes formatted CPF and omits razao social"`

**C14** - When PIX `chave-pix` and destination email `ana@example.com` are set, that sheet does not include `chave-pix` and does not include `ana@example.com` (SHEET-01, AC 14, door 3)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx omits chave-pix and destination email"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "header omits PIX and destination email"`

**C15** - When the Month has an Inflow of `6300` cents on `2026-05-04` with history `Pix - Recebido` on BankAccount `Conta Principal`, the Recebimentos section includes `04/05/2026`, numeric `63`, `Conta Principal`, and `Pix - Recebido` (SHEET-01, AC 15)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx Recebimentos includes 04/05/2026 numeric 63 Conta Principal Pix - Recebido"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "Recebimentos row is date 63 Conta Principal Pix - Recebido"`

**C16** - When the Month has a Payment of `15500` cents marked `bank_fee` with history `Tarifa Pacote de Serviços`, the Custos/Despesas section includes `Tarifa bancária`, numeric `155`, that history, and an empty `Arquivo(s)` for that row (SHEET-01, AC 16, door 3)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx bank_fee row includes Tarifa bancaria numeric 155 empty files"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "bank_fee expense is Tarifa bancaria 155 empty Arquivos"`

**C17** - When a Payment of `22000` cents is matched to two recibos (`Padaria Central` on `2026-05-11` and `Mercado Silva` on `2026-05-12`), that expense row’s `Arquivo(s)` equals those two documents’ `notas/` filenames separated by `; ` (SHEET-01, AC 17, door 5)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx 1N Arquivos joins notas filenames with semicolon space"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "1N Arquivos is two notas names separated by semicolon space"`

**C18** - When two Payments are matched to one recibo `Padaria Central`, both expense rows include that document’s `notas/` filename in `Arquivo(s)` (SHEET-01, AC 18)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx N1 both expense rows include the same notas filename"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "N1 both rows carry the same notas filename"`

**C19** - When a Match has observation `desconto não documentado`, that expense row includes `desconto não documentado` (SHEET-01, AC 19)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx includes desconto nao documentado"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "observation desconto nao documentado is on the expense row"`

**C20** - After close succeeds, the sheet includes labels `Receita total`, `Despesas total`, and `Resultado mês`; the two total value cells contain a formula whose text includes `SUM`; `Resultado mês` contains a formula whose text includes `-` (SHEET-01, AC 20, door 3)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx totals are SUM formulas and Resultado uses minus"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "Receita and Despesas formulas include SUM and Resultado includes minus"`

**C21** - After close succeeds with no unmatched documents in the package, the workbook does not include `sem casamento` (SHEET-01, AC 21, door 3)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx omits sem casamento"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "workbook text does not include sem casamento"`

**C22** - When Custos/Despesas has two payments on `2026-05-04` and `2026-05-20`, those rows appear in that date order (SHEET-01, AC 22)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx Custos rows are 04/05/2026 then 20/05/2026"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "expense rows are ordered 2026-05-04 then 2026-05-20"`

**C50** - When a Payment of `15500` cents is marked `accountant_fee`, the Custos/Despesas section includes `Honorário do contador` (SHEET-01, door 3)
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx accountant_fee row includes Honorario do contador"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "accountant_fee expense is Honorario do contador"`

### S3 - Month folder on the archive · door 2 · door 5

**C23** - After close succeeds for `2026-05`, the writer receives a month folder named `2026-05` under parent `15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl` whose files include `resumo-2026-05.xlsx` (DRIVE-01, AC 23, door 2)
Proof: `bin/rspec spec/requests/close_spec.rb -e "writer receives 2026-05 under archive parent with resumo-2026-05.xlsx"`
Proof: `bin/rspec spec/models/month_package_spec.rb -e "package files include resumo-2026-05.xlsx"`

**C24** - When that Month’s BankAccount slug is `conta-principal` and the statement has a PDF and an `.xlsx` spreadsheet, the writer files include `extratos/extrato-conta-principal.pdf` and `extratos/extrato-conta-principal.xlsx` (DRIVE-01, AC 24, door 5)
Proof: `bin/rspec spec/requests/close_spec.rb -e "writer files include extrato-conta-principal pdf and xlsx"`
Proof: `bin/rspec spec/models/month_package_spec.rb -e "statement files are extratos/extrato-conta-principal.pdf and xlsx"`

**C25** - When that spreadsheet blob’s filename ends in `.csv`, the writer files include `extratos/extrato-conta-principal.csv` and do not include `extratos/extrato-conta-principal.xlsx` (DRIVE-01, AC 25, door 5)
Proof: `bin/rspec spec/requests/close_spec.rb -e "writer files include extrato-conta-principal.csv not xlsx"`
Proof: `bin/rspec spec/models/month_package_spec.rb -e "csv statement file is extratos/extrato-conta-principal.csv"`

**C26** - When a matched recibo has payee `Padaria Central`, `document_on` `2026-05-11`, and a `.jpg` photo, the writer files include `notas/recibo-2026-05-11-padaria-central-{id}.jpg` where `{id}` is that document’s persisted id (DRIVE-01, AC 26, door 5)
Proof: `bin/rspec spec/requests/close_spec.rb -e "writer files include notas recibo padaria-central jpg with document id"`
Proof: `bin/rspec spec/models/month_package_spec.rb -e "recibo photo path is notas/recibo-2026-05-11-padaria-central-id.jpg"`

**C27** - When a matched nota fiscal has payee `Mercado Silva`, `document_on` `2026-05-11`, a `.jpg` photo and a `.xml`, the writer files include `notas/nota-2026-05-11-mercado-silva-{id}.jpg` and `notas/nota-2026-05-11-mercado-silva-{id}.xml` with the same `{id}` (DRIVE-01, AC 27, door 5)
Proof: `bin/rspec spec/requests/close_spec.rb -e "writer files include nota mercado-silva jpg and xml same stem"`
Proof: `bin/rspec spec/models/month_package_spec.rb -e "nota photo and xml share notas/nota-2026-05-11-mercado-silva-id stem"`

**C28** - After close succeeds, the writer files do not include any path starting with `notas-sem-casamento/` (DRIVE-01, AC 28)
Proof: `bin/rspec spec/requests/close_spec.rb -e "writer files omit notas-sem-casamento"`
Proof: `bin/rspec spec/models/month_package_spec.rb -e "package files have no notas-sem-casamento prefix"`

**C29** - After the first close of `2026-05` succeeds, the Month’s month-folder identity equals the folder id the writer returned (DRIVE-01, AC 29, door 1, door 2)
Proof: `bin/rspec spec/requests/close_spec.rb -e "first close persists month_folder_id from writer"`
Proof: `bin/rspec spec/models/month_spec.rb -e "first close stores writer folder id on the Month"`

**C30** - After a later close of the same Month succeeds, the writer replaces contents of that same folder id and does not create a second folder named `2026-05` under the parent (DRIVE-01, AC 30, door 2)
Proof: `bin/rspec spec/requests/close_spec.rb -e "second close replaces the same folder id"`
Proof: `bin/rspec spec/models/month_spec.rb -e "second close reuses month_folder_id and does not create another 2026-05"`

**C31** - Operator OmniAuth scopes remain `openid` and `email` only (DRIVE-01, AC 31, door 2)
Proof: `bin/rspec spec/config/omniauth_spec.rb -e "google_oauth2 scopes are openid and email only"`

**C51** - When the writer lists more than one folder named `2026-05` under the parent, close persists the Month not closed and responds `422` with `Não foi possível gravar no arquivo do pacote` (DRIVE-01, door 2)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with two 2026-05 folders returns 422 Nao foi possivel gravar"`
Proof: `bin/rspec spec/models/package_archive_writer_spec.rb -e "replace_month_folder raises when two folders share the name"`

**C52** - The test package-archive writer stores the month folder in memory and does not call Google (door 2)
Proof: `bin/rspec spec/models/package_archive_writer_spec.rb -e "test adapter stores month folder in memory"`
Proof: `bin/rspec spec/config/application_spec.rb -e "test package archive writer is in-memory not Google"`

**C53** - `PackageArchiveWriter` with `GOOGLE_DRIVE_REFRESH_TOKEN` set uses the Drive API v3 adapter; `Gemfile` includes `google-apis-drive_v3` and `googleauth` (door 2)
Proof: `bin/rspec spec/models/package_archive_writer_spec.rb -e "token present selects Drive API v3 adapter"`
Proof: `bin/rspec spec/config/application_spec.rb -e "Gemfile includes google-apis-drive_v3 and googleauth"`

### S4 - Closed month is read-only · door 1

**C32** - While `2026-05` is closed, `GET /months/2026-05` includes `Mês fechado` and `Reabrir` and does not include `Enviar extrato`, `Confirmar casamento`, `Marcar tarifa`, or `Desfazer casamento` (FROZEN-01, AC 32)
Proof: `bin/rspec spec/requests/close_spec.rb -e "GET closed month is view-only with Reabrir"`

**C33** - While `2026-05` is closed, `GET /months/2026-05` still includes a matched payment’s `Casado` label and history text (FROZEN-01, AC 33)
Proof: `bin/rspec spec/requests/close_spec.rb -e "GET closed month still includes Casado and payment history"`

**C34** - `POST /months/2026-05/bank_statements` while the Month is closed leaves existing statements in place and responds `422` with `Mês fechado` (FROZEN-01, AC 34)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST bank_statements while closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "import while Month closed does not replace"`

**C35** - `POST /months/2026-05/matches` while the Month is closed persists no new Match and responds `422` with `Mês fechado` (FROZEN-01, AC 35)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match while closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/match_spec.rb -e "confirm while Month closed persists no Match"`

**C36** - `DELETE /months/2026-05/matches/:id` while the Month is closed leaves that Match in place and responds `422` with `Mês fechado` (FROZEN-01, AC 36)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "DELETE match while closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/match_spec.rb -e "dissolve while Month closed keeps the Match"`

**C37** - `POST` document exception while the Month is closed persists no mark and responds `422` with `Mês fechado` (FROZEN-01, AC 37)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST exception while closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "mark exception while Month closed persists no mark"`

**C38** - `DELETE` document exception while the Month is closed leaves the mark in place and responds `422` with `Mês fechado` (FROZEN-01, AC 38)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "DELETE exception while closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "unmark exception while Month closed keeps the mark"`

**C39** - `PATCH /supporting_documents/:id` with payee `Outro` on a SupportingDocument whose Month is the closed `2026-05` leaves the payee unchanged and responds `422` with `Mês fechado` (FROZEN-01, AC 39)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH payee Outro on closed-month document returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply payee while document Month is closed leaves payee"`

**C40** - `POST /supporting_documents` of a new recibo while `2026-05` is closed persists that SupportingDocument with no Month and responds `302` to `/supporting_documents` (FROZEN-01, AC 40)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo while a month is closed persists no Month 302"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert while a month is closed assigns no Month"`

### S5 - Reopen, isolation, concurrency · door 1 · door 4

**C41** - `POST /months/2026-05/reopen` on a closed Month persists the Month not closed, does not invoke the package-archive writer, and responds `302` to `/months/2026-05` (OPEN-01, AC 41, door 1, door 4)
Proof: `bin/rspec spec/requests/reopen_spec.rb -e "POST reopen persists open 302 and does not write"`
Proof: `bin/rspec spec/models/month_spec.rb -e "reopen sets closed false and does not write"`

**C42** - After that reopen succeeds, `GET /months/2026-05` includes `Fechar para envio` and `Enviar extrato` and does not include `Mês fechado` (OPEN-01, AC 42)
Proof: `bin/rspec spec/requests/reopen_spec.rb -e "GET after reopen includes Fechar para envio and omits Mes fechado"`

**C43** - After that reopen succeeds, Matches, Payments, and BankStatements of `2026-05` remain, and the persisted month-folder identity remains (OPEN-01, AC 43, door 1)
Proof: `bin/rspec spec/requests/reopen_spec.rb -e "reopen keeps matches payments statements and month_folder_id"`
Proof: `bin/rspec spec/models/month_spec.rb -e "reopen keeps month_folder_id and does not destroy matches"`

**C44** - `POST /months/2026-05/reopen` while the Month is open responds `422` with `Mês aberto` and leaves it open (OPEN-01, AC 44)
Proof: `bin/rspec spec/requests/reopen_spec.rb -e "POST reopen while open returns 422 Mes aberto"`
Proof: `bin/rspec spec/models/month_spec.rb -e "reopen while open leaves closed false"`

**C45** - Unauthenticated `POST /months/2026-05/reopen` leaves the Month closed and responds `302` to `/login` (OPEN-01, AC 45)
Proof: `bin/rspec spec/requests/reopen_spec.rb -e "unauthenticated POST reopen responds 302 to /login"`

**C46** - `POST /months/2026-05/close` focused on organization A for a `2026-05` that exists only on organization B leaves B unchanged and responds `404` (OPEN-01, AC 46)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close of another organization month returns 404"`

**C47** - `POST /months/2026-05/reopen` focused on organization A for a closed `2026-05` that exists only on organization B leaves B closed and responds `404` (OPEN-01, AC 47)
Proof: `bin/rspec spec/requests/reopen_spec.rb -e "POST reopen of another organization month returns 404"`

**C48** - Two concurrent `POST /months/2026-05/close` of the same open Month persist that Month closed exactly once and invoke the writer exactly once (OPEN-01, AC 48, door 4)
Proof: `bin/rspec spec/models/month_spec.rb -e "concurrent closes persist closed once and write once"`

**C49** - `GET /months/2026-05` while focused on organization A after A’s close does not include organization B’s accountant presentation name (OPEN-01, AC 49)
Proof: `bin/rspec spec/requests/close_spec.rb -e "closed month page omits another organization accountant name"`

**C54** - `POST /months/2026-05/close` does not enqueue an Active Job; the Month is closed in that response (door 4)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close enqueues no job and persists closed"`

**C55** - `Month.open` for `2026-05` persists `closed` false; the Month has no `closing` state (door 1)
Proof: `bin/rspec spec/models/month_spec.rb -e "open 2026-05 persists closed false with no closing state"`

**C56** - `POST /months/2026-04/close` when that organization has no Month for `2026-04` responds `404` (Surface `POST /months/:year_month/close`)
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close of never-opened 2026-04 returns 404"`

**C57** - `POST /months/2026-04/reopen` when that organization has no Month for `2026-04` responds `404` (Surface `POST /months/:year_month/reopen`)
Proof: `bin/rspec spec/requests/reopen_spec.rb -e "POST reopen of never-opened 2026-04 returns 404"`

**C58** - Puma `worker_timeout` is `300` seconds (door 4)
Proof: `bin/rspec spec/config/puma_spec.rb -e "worker_timeout is 300"`

**C59** - Unauthenticated `GET /months/2026-05` responds `302` to `/login` (Surface `GET /months/:year_month`)
Proof: `bin/rspec spec/requests/months_spec.rb -e "unauthenticated GET /months/2026-05 responds 302 to /login"`

**C60** - `GET /months/2026-05` with a session and no focused organization responds `302` to `/login` (Surface `GET /months/:year_month`)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 without focus responds 302 to /login"`

**C61** - `GET /months/2026-04` when that organization has no Month for `2026-04` responds `404` (Surface `GET /months/:year_month`)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-04 when never opened responds 404"`

**C62** - Authenticated `POST /months/2026-05/bank_statements` of PDF and spreadsheet while the Month is open responds `302` (Surface `POST /months/:year_month/bank_statements`)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST BB xlsx persists statement Presente and filenames"`

**C63** - `POST /months/2026-05/bank_statements` of another organization’s account responds `404` (Surface `POST /months/:year_month/bank_statements`)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST bank_statements of another organization returns 404"`

**C64** - Authenticated `POST /months/2026-05/matches` of a valid 1:1 match while the Month is open responds `302` (Surface `POST /months/:year_month/matches`)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST 1 payment 1 document equal persists Match 302"`

**C65** - `POST /months/2026-05/matches` with a Payment id that belongs only to organization B responds `404` (Surface `POST /months/:year_month/matches`)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match with another organization payment returns 404"`

**C66** - Authenticated `DELETE /months/2026-05/matches/:id` while the Month is open responds `302` (Surface `DELETE /months/:year_month/matches/:id`)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "DELETE match returns payments to Documento faltante and documents to pool"`

**C67** - `DELETE /months/2026-05/matches/:id` for an id that does not exist on that Month responds `404` (Surface `DELETE /months/:year_month/matches/:id`)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "DELETE missing match id returns 404"`

**C68** - Authenticated `POST` document exception `bank_fee` while the Month is open responds `302` (Surface `POST /months/:year_month/payments/:id/document_exception`)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST bank_fee persists Tarifa bancaria and redirects"`

**C69** - `POST` document exception for a Payment of Month `2026-04` on `/months/2026-05/...` responds `404` (Surface `POST /months/:year_month/payments/:id/document_exception`)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST exception for payment of 2026-04 on 2026-05 returns 404"`

**C70** - Authenticated `DELETE` document exception while the Month is open responds `302` (Surface `DELETE /months/:year_month/payments/:id/document_exception`)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "DELETE bank_fee returns Documento faltante"`

**C71** - `DELETE` document exception of another organization responds `404` (Surface `DELETE /months/:year_month/payments/:id/document_exception`)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "DELETE document_exception of another organization returns 404"`

**C72** - Authenticated `PATCH /supporting_documents/:id` payee while the document’s Month is not closed responds `302` (Surface `PATCH /supporting_documents/:id`)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH payee to Mercado Silva redirects"`

**C73** - `PATCH /supporting_documents/:id` of an id that belongs only to organization B responds `404` (Surface `PATCH /supporting_documents/:id`)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH supporting_document of another organization returns 404"`

**C74** - `POST /supporting_documents` recibo without photo responds `422` (Surface `POST /supporting_documents`)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo without photo returns 422 Envie a foto do recibo"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| `POST /months/:year_month/close` statuses (3) | 302 C5 · 422 C1 · 404 C46 | - |
| `POST /months/:year_month/close` 422 reasons (7) | missing document C1 · missing statement C2 · missing archive C3 · missing accountant C4 · writer raised C8 · already closed C9 · two `2026-05` folders C51 | - |
| `POST /months/:year_month/close` 404 reasons (2) | other organization C46 · never opened C56 | - |
| `POST /months/:year_month/reopen` statuses (3) | 302 C41 · 422 C44 · 404 C47 | - |
| `POST /months/:year_month/reopen` 404 reasons (2) | other organization C47 · never opened C57 | - |
| `GET /months/:year_month` statuses (3) | 200 C6 · 302 C59 · 404 C61 | - |
| `GET /months/:year_month` 302 reasons (2) | unauthenticated C59 · no focus C60 | - |
| `POST /months/:year_month/bank_statements` statuses (3) | 302 C62 · 422 C34 · 404 C63 | - |
| `POST /months/:year_month/matches` statuses (3) | 302 C64 · 422 C35 · 404 C65 | - |
| `DELETE /months/:year_month/matches/:id` statuses (3) | 302 C66 · 404 C67 · 422 C36 | - |
| `POST /months/:year_month/payments/:id/document_exception` statuses (3) | 302 C68 · 422 C37 · 404 C69 | - |
| `DELETE /months/:year_month/payments/:id/document_exception` statuses (3) | 302 C70 · 404 C71 · 422 C38 | - |
| `PATCH /supporting_documents/:id` statuses (3) | 302 C72 · 422 C39 · 404 C73 | - |
| `POST /supporting_documents` statuses (2) | 302 C40 · 422 C74 | - |
| Month closed transitions (4) | open→closed C5 · closed→open C41 · close while closed C9 · reopen while open C44 | - |
| Close writer invocations (6) | success once C5 · missing document none C1 · writer raised none C8 · already closed none C9 · reopen none C41 · concurrent once C48 | - |
| Drive folder name hits (3) | zero create C29 · one reuse C30 · more than one raise C51 | - |
| Package file groups (4) | `resumo-2026-05.xlsx` C23 · `extratos/` C24 · `notas/` C26 · no `notas-sem-casamento/` C28 | - |
| Statement filename extensions (2) | `.xlsx` C24 · `.csv` C25 | - |
| Document filename stems (2) | recibo photo C26 · nota photo+xml same stem C27 | - |
| Spreadsheet exception copy (2) | `Tarifa bancária` C16 · `Honorário do contador` C50 | - |
| Accountant header (3) | CNPJ + razão C12 · CPF no razão C13 · no PIX/email C14 | - |
| Writer adapter factory (2) | in-memory C52 · Drive API v3 C53 | - |
| Relations entities (6) | Organization C49 · Month C5 · BankStatement C10 · Match C43 · SupportingDocument C40 · BankAccount C10 | - |
| Landing doors (5) | closed + folder id C5 · PackageArchiveWriter C23 · summary xlsx C11 · in-request lock C54 · stable stems C26 | - |

- Claims naming a status code, route or response shape: C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C32, C34, C35, C36, C37, C38, C39, C40, C41, C44, C45, C46, C47, C51, C54, C56, C57, C59, C61, C62, C63, C64, C65, C66, C67, C68, C69, C70, C71, C72, C73, C74 - each has a proof that crosses the HTTP boundary
- No other check claims more than the single case its proof exercises
- C48 asserts uniqueness under concurrency at the model layer; it does not substitute for C9 at the HTTP boundary
- C59–C74 reuse existing request examples for Surface statuses this cut does not change; C34–C40 add the closed `422` (and insert-while-closed `302`) on those same routes

## Test policy

`.cursor/rules/rails.mdc` already answers which level proves which code and how much of the input space counts. This build runs under those rows; they are not proposed as a new guideline commit.

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Decides, reached across a boundary | one at the boundary **and** one at its own layer | the contract at the boundary; one asserted case per row of the decision table at its own layer |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member |
| Entry point that decides nothing | one at the boundary | accepted input, each rejected input, each error path |
| Instrumentation, pass-throughs | none of its own | covered by its consumer's proof |

Evidence (classified from the approved plan):

- Month close gates: missing document / missing statement / missing archive / missing accountant / ready / writer raised / already closed / inactive without statement -> decides, reached across `POST /months/:year_month/close`
- Summary spreadsheet: sheet name, accountant header (CNPJ/CPF/PIX), Recebimentos, exception rows, 1:N / N:1 `Arquivo(s)`, observation, SUM/minus, no unmatched section, date order -> decides, reached across close (writer receives the xlsx) and at `SummarySpreadsheet` own layer
- Month package filenames: `resumo-`, `extrato-{slug}.{ext}`, `{nota|recibo}-{date}-{slug}-{id}` -> decides, reached across close and at `MonthPackage` own layer
- PackageArchiveWriter: in-memory vs Drive adapter; 0 / 1 / many folders named `{YYYY-MM}` -> decides; HTTP close is the consumer; factory and Drive-list table at own layer
- Closed-month mutations: statement / match / exception / matched-document PATCH refused; insert without month allowed -> decides, reached across those routes
- Reopen: closed→open, folder id kept, writer not called, reopen while open -> decides, reached across `POST /months/:year_month/reopen`
- Concurrent close lock -> decides, not reached as HTTP in this cut; own layer C48
- GET unauth / no-focus / never-opened and existing open-month 302/404 on mutation routes -> entry / guard, boundary
- closest analogue in the repo: `spec/models/match_spec.rb` + `spec/requests/matches_spec.rb` — persist and 422 at the HTTP boundary, concurrent unique write at own layer; `spec/config/omniauth_spec.rb` for operator scopes

Cost: dual proofs on close gates (C1–C5, C8–C10), spreadsheet cells (C11–C22, C50), package files (C23–C30), writer many-folders (C51), closed mutations (C34–C40), reopen (C41, C43, C44). Without those own-layer proofs the close table, the workbook, and the filename stems would be proven only by a path that happens to traverse them.

## Swept

- validation: C1, C2, C3, C4
- failure modes: C8, C51
- idempotency: C9, C30 - a second close while closed is `422`; a close after reopen replaces the same folder id
- authorization: C7, C45, C46, C47, C49, C59, C60
- concurrency: C48
- data lifecycle: C43, C55 - reopen keeps matches, payments, statements, and folder id; new months open (`closed` false); no backfill
- dependency failure: C8, C51
- state transitions: C5, C9, C41, C44
- observability: n/a - no logging or metrics criterion in the plan

## Handoff

- S1–S5 share `Month`, the package-archive writer, the summary workbook, and `/months/:year_month`. Estimated ~22 product/spec files (Month close/reopen + migration, PackageArchiveWriter + memory/Drive adapters, SummarySpreadsheet, MonthPackage filenames, close/reopen controllers, closed guards on existing mutations, month show, request specs, model specs, puma timeout) ≪ 150k tokens. One builder, no split.
- S1-S5 = one builder
- **Boundary:** C1–C74 closed; proofs green on `bin/rspec`
- **Settled mid-build:** none
- **Abandoned:** none
