# Close for send verification

**Verdict**: FAIL
**Profile**: standard
**Diff range**: bdc0dec28bd1fdaa04129f0503cd2df73c9145e6..2eb7fadb1f9dbf0ac5001dda4a223c353c95ad84
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

User walk skipped: no design source for the screens; plan pins verification at `standard`, not `ui`.

Proofs run at HEAD `2eb7fad`: one `bin/rspec` invocation over the 18 proof files named in `checks.md` with every `-e` selector from that file. 116 examples, 0 failures. Each named selector existed (`it "..."` hit) and appeared individually in documentation output as having run.

Real-tree porcelain before faults and after scratch discard: empty (match). Scratch: `git worktree add /tmp/tlc-verify-close-for-send HEAD`; discarded with `git worktree remove --force`.

## Binding sources

No design source for the screens. Plan: "No design source for the screens. Verification stays on project profile `standard` (no screen mock, so not `ui`)." No arrangement enumeration required under `standard`.

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| #34 Fechar para envio | yes - https://github.com/gutors/ai-accounting-assistant/issues/34 | none | - |
| #6 O sistema envia o pacote ao contador ou só o prepara? | yes - issue + resolution comment | none — close does not complete without the Drive copy; no email | - |
| #18 Documentos sem casamento | yes - issue + resolution | none — this cut defers unmatched-in-package to #39 per #34; unmatched still do not block close | - |
| #19 O que o mês fechado impede | yes - issue + resolution | none — closed is read-only; reopen does not touch Drive | - |
| #20 Mês do documento | yes - issue + resolution | none — insert without a month stays allowed while closed | - |
| #22 Formato da planilha-resumo | yes - issue + resolution | none — PIX/email omitted; unmatched section omitted when empty | - |
| #23 Árvore do arquivo Drive | yes - issue + resolution | none — `{YYYY-MM}`, `resumo-`, `extratos/`, `notas/`; `notas-sem-casamento/` deferred to #39 | - |
| #26 Conta bancária / extrato em conta ativa | yes - issue + resolution | none — inactive without statement does not block; every active account needs a statement | - |
| `CONTEXT.md` Close-for-send / Closed month / Month folder / Monthly package / Summary spreadsheet / Package archive / Missing document / Unmatched document | yes | none | - |
| ADR-0001 Rails 8 + Hotwire | yes | none — close is an in-request Puma job; operator scopes stay `openid,email` | - |
| n/a — no binding screen | n/a | none | - |

## Checks

Proofs: batch 116 passed, 0 failed at `2eb7fad`. Every `-e` from `checks.md` ran.

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | POST close missing document 22000 cents: not closed, writer not called, 422 `Há documento faltante` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:23` - `have_http_status(:unprocessable_content)` ; `:24` - `include("Há documento faltante")` ; `:25` - `closed?).to eq(false)` ; `:26` - `writer.calls.size).to eq(calls)` ; `spec/models/month_spec.rb:82` - `include("Há documento faltante")` ; `:83` - `closed?).to eq(false)` ; `:84` - `writer.calls.size).to eq(calls)` | PASS |
| C2 | POST close active `Conta Principal` without statement: not closed, 422 `Importe o extrato de cada conta ativa` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:39` - `have_http_status(:unprocessable_content)` ; `:40` - `include("Importe o extrato de cada conta ativa")` ; `:41` - `closed?).to eq(false)` ; `spec/models/month_spec.rb:93` - `include("Importe o extrato de cada conta ativa")` ; `:94` - `closed?).to eq(false)` | PASS |
| C3 | POST close without archive folder id: not closed, 422 `Informe a pasta do arquivo do pacote` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:52` - `have_http_status(:unprocessable_content)` ; `:53` - `include("Informe a pasta do arquivo do pacote")` ; `:54` - `closed?).to eq(false)` ; `spec/models/month_spec.rb:102` - `include("Informe a pasta do arquivo do pacote")` ; `:103` - `closed?).to eq(false)` | PASS |
| C4 | POST close without accountant name: not closed, 422 `Cadastre o contador` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:65` - `have_http_status(:unprocessable_content)` ; `:66` - `include("Cadastre o contador")` ; `:67` - `closed?).to eq(false)` ; `spec/models/month_spec.rb:111` - `include("Cadastre o contador")` ; `:112` - `closed?).to eq(false)` | PASS |
| C5 | POST close ready month: closed, writer once, 302 to `/months/2026-05` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:75` - `have_http_status(:found)` ; `:76` - `redirect_to("/months/2026-05")` ; `:77` - `closed?).to eq(true)` ; `:78` - `writer.calls.size).to eq(1)` ; `spec/models/month_spec.rb:119` - `closed?).to eq(true)` ; `:120` - `writer.calls.size).to eq(1)` | PASS |
| C6 | GET closed `2026-05`: 200, `Mês fechado`, omits `Fechar para envio` | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/close_spec.rb:88` - `have_http_status(:ok)` ; `:89` - `include("Mês fechado")` ; `:90` - `not_to include("Fechar para envio")` | PASS |
| C7 | Unauthenticated POST close: not closed, 302 `/login` | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/close_spec.rb:100` - `have_http_status(:found)` ; `:101` - `redirect_to("/login")` ; `:102` - `closed?).to eq(false)` | PASS |
| C8 | Writer raises: not closed, 422 `Não foi possível gravar no arquivo do pacote` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:111` - `have_http_status(:unprocessable_content)` ; `:112` - `include("Não foi possível gravar no arquivo do pacote")` ; `:113` - `closed?).to eq(false)` ; `spec/models/month_spec.rb:132` - `include("Não foi possível gravar no arquivo do pacote")` ; `:133` - `closed?).to eq(false)` | PASS |
| C9 | POST close while already closed: stays closed, writer not called, 422 `Mês fechado` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:123` - `have_http_status(:unprocessable_content)` ; `:124` - `include("Mês fechado")` ; `:125` - `closed?).to eq(true)` ; `:126` - `writer.calls.size).to eq(calls)` ; `spec/models/month_spec.rb:142` - `include("Mês fechado")` ; `:144` - `writer.calls.size).to eq(calls)` | PASS |
| C10 | Inactive account without statement: closed, 302 | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:136` - `have_http_status(:found)` ; `:137` - `closed?).to eq(true)` ; `spec/models/month_spec.rb:154` - `closed?).to eq(true)` | PASS |
| C11 | Workbook one sheet `2026-05` titled `Planilha-resumo — ONG Norte` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:145` - `worksheets.size).to eq(1)` ; `:146` - `sheet_name).to eq("2026-05")` ; `:147` - `include("Planilha-resumo — ONG Norte")` ; `spec/models/summary_spreadsheet_spec.rb:31` - `eq(1)` ; `:32` - `eq("2026-05")` ; `:33` - `include("Planilha-resumo — ONG Norte")` | PASS |
| C12 | Header includes `Maria Contadora`, `Contábil LTDA`, `11.222.333/0001-81` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:164` - `include("Maria Contadora")` ; `:165` - `include("Contábil LTDA")` ; `:166` - `include("11.222.333/0001-81")` ; `spec/models/summary_spreadsheet_spec.rb:44-46` - same three `include` | PASS |
| C13 | CPF `390.533.447-05`, no razão social line | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:179` - `include("390.533.447-05")` ; `:180` - `not_to include("Contábil LTDA")` ; `spec/models/summary_spreadsheet_spec.rb:53-54` - same | PASS |
| C14 | Omits `chave-pix` and `ana@example.com` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:197` - `not_to include("chave-pix")` ; `:198` - `not_to include("ana@example.com")` ; `spec/models/summary_spreadsheet_spec.rb:65-66` - same | PASS |
| C15 | Recebimentos: `04/05/2026`, numeric `63`, `Conta Principal`, `Pix - Recebido` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:207` - find row with `"04/05/2026"` and `63` ; `:209` - `include("Conta Principal", "Pix - Recebido")` ; `spec/models/summary_spreadsheet_spec.rb:71` - same find ; `:73` - same `include` | PASS |
| C16 | `bank_fee` row: `Tarifa bancária`, numeric `155`, history, empty `Arquivo(s)` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:221` - find row with `"Tarifa bancária"` ; `:223` - `include(155, "Tarifa Pacote de Serviços")` ; `:224` - `eq("")` ; `spec/models/summary_spreadsheet_spec.rb:81-84` - same | PASS |
| C17 | 1:N `Arquivo(s)` joins `notas/` names with `; ` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:239` - `include(joined)` ; `:240` - `joined).to include("; ")` ; `spec/models/summary_spreadsheet_spec.rb:96-97` - same | PASS |
| C18 | N:1 both expense rows include the same `notas/` filename | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:254` - `rows.size).to eq(2)` ; `:255` - `all(include(filename))` ; `spec/models/summary_spreadsheet_spec.rb:108-109` - same | PASS |
| C19 | Observation `desconto não documentado` on the expense row | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:266` - `include("desconto não documentado")` ; `spec/models/summary_spreadsheet_spec.rb:118` - `row).to include("desconto não documentado")` | PASS |
| C20 | Labels `Receita total`, `Despesas total`, `Resultado mês`; two total value cells include `SUM`; Resultado formula includes `-` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:276` - `include("Receita total", "Despesas total", "Resultado mês")` ; `:277` - `formulas` with `"SUM"` count `>= 2` ; `:278` - any formula `include?("-")` ; `spec/models/summary_spreadsheet_spec.rb:126-128` - same. Labels are at the assertion. `SUM`/`-` are counted across all formulas, not on the two total value cells or the Resultado mês value cell the claim names. | FAIL |
| C21 | Workbook omits `sem casamento` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:285` - `not_to include("sem casamento")` ; `spec/models/summary_spreadsheet_spec.rb:132` - same | PASS |
| C22 | Custos rows `04/05/2026` then `20/05/2026` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:298` - `eq([ "04/05/2026", "20/05/2026" ])` ; `spec/models/summary_spreadsheet_spec.rb:142` - same | PASS |
| C50 | `accountant_fee` includes `Honorário do contador` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:308` - `include("Honorário do contador")` ; `spec/models/summary_spreadsheet_spec.rb:149` - same | PASS |
| C23 | Writer receives folder `2026-05` under archive parent with `resumo-2026-05.xlsx` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:316` - `call[:name]).to eq("2026-05")` ; `:318` - `include("resumo-2026-05.xlsx")` ; `spec/models/month_package_spec.rb:29` - `include("resumo-2026-05.xlsx")` | PASS |
| C24 | `extratos/extrato-conta-principal.pdf` and `.xlsx` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:327` - `include("extratos/extrato-conta-principal.pdf", "extratos/extrato-conta-principal.xlsx")` ; `spec/models/month_package_spec.rb:35-38` - same two paths | PASS |
| C25 | `.csv` present, `.xlsx` absent | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:336` - `include("extratos/extrato-conta-principal.csv")` ; `:337` - `not_to include("extratos/extrato-conta-principal.xlsx")` ; `spec/models/month_package_spec.rb:44-45` - same | PASS |
| C26 | Recibo path `notas/recibo-2026-05-11-padaria-central-{id}.jpg` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:349` - `include("notas/recibo-2026-05-11-padaria-central-#{document.id}.jpg")` ; `spec/models/month_package_spec.rb:53` - same path with `document.id` | PASS |
| C27 | Nota jpg and xml share stem `notas/nota-2026-05-11-mercado-silva-{id}` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:361` - `include("#{stem}.jpg", "#{stem}.xml")` ; `spec/models/month_package_spec.rb:62` - same | PASS |
| C28 | No path starting `notas-sem-casamento/` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:368` - `grep(/\Anotas-sem-casamento\//)).to eq([])` ; `spec/models/month_package_spec.rb:66` - same | PASS |
| C29 | First close stores writer folder id | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:375` - `month_folder_id).to eq(writer.folders.keys.first)` ; `spec/models/month_spec.rb:160` - same | PASS |
| C30 | Second close reuses same folder id, one `2026-05` under parent | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:386` - `month_folder_id).to eq(folder_id)` ; `:387` - count of name `2026-05` under parent `eq(1)` ; `:388` - `calls.last[:folder_id]).to eq(folder_id)` ; `spec/models/month_spec.rb:170-171` - folder id reused and one `2026-05` | PASS |
| C31 | OmniAuth scopes `openid` and `email` only | batch exit 0 at `2eb7fad`; `-e` passed | `spec/config/omniauth_spec.rb:5` - `contain_exactly("openid", "email")` ; `:8` - `not_to match(/drive/i)` — example existed before this range; ran at HEAD | PASS |
| C51 | Two `2026-05` folders: not closed, 422 write-failed | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/close_spec.rb:398` - `have_http_status(:unprocessable_content)` ; `:399` - `include("Não foi possível gravar no arquivo do pacote")` ; `:400` - `closed?).to eq(false)` ; `spec/models/package_archive_writer_spec.rb:55-57` - `raise_error(PackageArchiveWriter::AmbiguousFolder)` | PASS |
| C52 | Test writer stores in memory, not Google | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/models/package_archive_writer_spec.rb:69` - `folders[id][:name]).to eq("2026-05")` ; `:71` - `not_to be_a(PackageArchiveWriter::Drive)` ; `spec/config/application_spec.rb:20` - `be_a(PackageArchiveWriter::Memory)` ; `:21` - `not_to be_a(PackageArchiveWriter::Drive)` | PASS |
| C53 | Token present selects Drive adapter; Gemfile has `google-apis-drive_v3` and `googleauth` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/models/package_archive_writer_spec.rb:80` - `be_a(PackageArchiveWriter::Drive)` ; `spec/config/application_spec.rb:26` - `include("google-apis-drive_v3")` ; `:27` - `include("googleauth")` | PASS |
| C32 | GET closed: `Mês fechado`, `Reabrir`; omits `Enviar extrato`, `Confirmar casamento`, `Marcar tarifa`, `Desfazer casamento` | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/close_spec.rb:412` - `include("Mês fechado")` ; `:413` - `include("Reabrir")` ; `:414` - `not_to include("Enviar extrato")` ; `:415` - `not_to include("Confirmar casamento")` ; `:416` - `not_to include("Marcar tarifa")` ; `:417` - `not_to include("Desfazer casamento")` | PASS |
| C33 | GET closed still includes `Casado` and payment history | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/close_spec.rb:429` - `include("Casado")` ; `:430` - `include("Pix enviado")` | PASS |
| C34 | POST bank_statements while closed: statements kept, 422 `Mês fechado` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/bank_statements_spec.rb:346` - `have_http_status(:unprocessable_content)` ; `:347` - `include("Mês fechado")` ; `:348` - `payments.count).to be > 1` ; `spec/models/bank_statement_spec.rb:240` - `include("Mês fechado")` ; `:241` - `payments.count).to eq(payment_count)` | PASS |
| C35 | POST match while closed: no Match, 422 `Mês fechado` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/matches_spec.rb:344` - `have_http_status(:unprocessable_content)` ; `:345` - `include("Mês fechado")` ; `:346` - `Match.count).to eq(0)` ; `spec/models/match_spec.rb:280` - `include("Mês fechado")` ; `:281` - `Match.count).to eq(0)` | PASS |
| C36 | DELETE match while closed: Match kept, 422 `Mês fechado` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/matches_spec.rb:361` - `have_http_status(:unprocessable_content)` ; `:362` - `include("Mês fechado")` ; `:363` - `Match.exists?(match.id)).to eq(true)` ; `spec/models/match_spec.rb:292` - `include("Mês fechado")` ; `:293` - `Match.exists?(match.id)).to eq(true)` | PASS |
| C37 | POST exception while closed: no mark, 422 `Mês fechado` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/document_exceptions_spec.rb:137` - `have_http_status(:unprocessable_content)` ; `:138` - `include("Mês fechado")` ; `:139` - `document_exception_kind).to be_nil` ; `spec/models/payment_spec.rb:103` - `include("Mês fechado")` ; `:104` - `be_nil` | PASS |
| C38 | DELETE exception while closed: mark kept, 422 `Mês fechado` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/document_exceptions_spec.rb:150` - `have_http_status(:unprocessable_content)` ; `:151` - `include("Mês fechado")` ; `:152` - `eq("bank_fee")` ; `spec/models/payment_spec.rb:114` - `include("Mês fechado")` ; `:115` - `eq("bank_fee")` | PASS |
| C39 | PATCH payee `Outro` on closed-month document: payee unchanged, 422 `Mês fechado` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:474` - `have_http_status(:unprocessable_content)` ; `:475` - `include("Mês fechado")` ; `:476` - `payee).to eq("Padaria Central")` ; `spec/models/supporting_document_spec.rb:337` - `include("Mês fechado")` ; `:338` - `eq("Padaria Central")` | PASS |
| C40 | POST recibo while a month is closed: no Month, 302 `/supporting_documents` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:486` - `have_http_status(:found)` ; `:487` - `redirect_to("/supporting_documents")` ; `:488` - `month_id).to be_nil` ; `spec/models/supporting_document_spec.rb:347` - `be_persisted` ; `:348` - `month_id).to be_nil` | PASS |
| C41 | POST reopen: open, writer not called, 302 `/months/2026-05` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/reopen_spec.rb:22` - `have_http_status(:found)` ; `:23` - `redirect_to("/months/2026-05")` ; `:24` - `closed?).to eq(false)` ; `:25` - `writer.calls.size).to eq(calls)` ; `spec/models/month_spec.rb:180` - `closed?).to eq(false)` ; `:181` - `writer.calls.size).to eq(calls)` | PASS |
| C42 | GET after reopen: `Fechar para envio`, `Enviar extrato`, omits `Mês fechado` | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/reopen_spec.rb:34` - `include("Fechar para envio")` ; `:35` - `include("Enviar extrato")` ; `:36` - `not_to include("Mês fechado")` | PASS |
| C43 | Reopen keeps matches, payments, statements, `month_folder_id` | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/reopen_spec.rb:50` - `month_folder_id).to eq(folder_id)` ; `:51` - `Match.exists?` ; `:52` - `Payment.exists?` ; `:53` - `BankStatement.exists?` ; `spec/models/month_spec.rb:193` - `month_folder_id).to eq(folder_id)` ; `:194` - `Match.exists?(match.id)` | PASS |
| C44 | POST reopen while open: 422 `Mês aberto`, stays open | batch exit 0 at `2eb7fad`; both `-e` passed | `spec/requests/reopen_spec.rb:64` - `have_http_status(:unprocessable_content)` ; `:65` - `include("Mês aberto")` ; `:66` - `closed?).to eq(false)` ; `spec/models/month_spec.rb:200` - `include("Mês aberto")` ; `:201` - `closed?).to eq(false)` | PASS |
| C45 | Unauthenticated POST reopen: stays closed, 302 `/login` | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/reopen_spec.rb:77` - `have_http_status(:found)` ; `:78` - `redirect_to("/login")` ; `:79` - `closed?).to eq(true)` | PASS |
| C46 | POST close of another org month: B unchanged, 404 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/close_spec.rb:443` - `have_http_status(:not_found)` ; `:444` - `closed?).to eq(false)` | PASS |
| C47 | POST reopen of another org closed month: B stays closed, 404 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/reopen_spec.rb:93` - `have_http_status(:not_found)` ; `:94` - `closed?).to eq(true)` | PASS |
| C48 | Concurrent close: closed once, writer once | batch exit 0 at `2eb7fad`; `-e` passed | `spec/models/month_spec.rb:231` - `closed?).to eq(true)` ; `:232` - `memory.calls.size).to eq(1)` | PASS |
| C49 | Closed month page omits org B accountant name | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/close_spec.rb:458` - `not_to include("Contador Beta")` | PASS |
| C54 | POST close enqueues no job and persists closed | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/close_spec.rb:468` - `enqueued_jobs).to eq([])` ; `:469` - `closed?).to eq(true)` | PASS |
| C55 | `Month.open` 2026-05: `closed` false, no `closing` state | batch exit 0 at `2eb7fad`; `-e` passed | `spec/models/month_spec.rb:207` - `closed?).to eq(false)` ; `:208` - `closed).to eq(false)` ; `:209` - `column_names).not_to include("status")` ; `:210` - `not_to respond_to(:closing)` | PASS |
| C56 | POST close never-opened `2026-04`: 404 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/close_spec.rb:477` - `have_http_status(:not_found)` | PASS |
| C57 | POST reopen never-opened `2026-04`: 404 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/reopen_spec.rb:102` - `have_http_status(:not_found)` | PASS |
| C58 | Puma `worker_timeout` is 300 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/config/puma_spec.rb:5` - `match(/worker_timeout\s+300/)` against `config/puma.rb` | PASS |
| C59 | Unauthenticated GET `/months/2026-05`: 302 `/login` | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/months_spec.rb:7` - `have_http_status(:found)` ; `:8` - `redirect_to("/login")` — example existed before this range; ran at HEAD | PASS |
| C60 | GET `/months/2026-05` without focus: 302 `/login` | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/months_spec.rb:20` - `have_http_status(:found)` ; `:21` - `redirect_to("/login")` — existed before this range; ran at HEAD | PASS |
| C61 | GET never-opened `2026-04`: 404 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/months_spec.rb:118` - `have_http_status(:not_found)` — existed before this range; ran at HEAD | PASS |
| C62 | POST bank_statements open month: 302 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/bank_statements_spec.rb:19` - `have_http_status(:found)` | PASS |
| C63 | POST bank_statements other org: 404 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/bank_statements_spec.rb:201` - `have_http_status(:not_found)` | PASS |
| C64 | POST valid 1:1 match open month: 302 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/matches_spec.rb:100` - `have_http_status(:found)` | PASS |
| C65 | POST match other-org payment: 404 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/matches_spec.rb:286` - `have_http_status(:not_found)` | PASS |
| C66 | DELETE match open month: 302 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/matches_spec.rb:126` - `have_http_status(:found)` | PASS |
| C67 | DELETE missing match id: 404 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/matches_spec.rb:331` - `have_http_status(:not_found)` | PASS |
| C68 | POST `bank_fee` open month: 302 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/document_exceptions_spec.rb:17` - `have_http_status(:found)` | PASS |
| C69 | POST exception for 2026-04 payment on 2026-05: 404 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/document_exceptions_spec.rb:126` - `have_http_status(:not_found)` | PASS |
| C70 | DELETE exception open month: 302 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/document_exceptions_spec.rb:44` - `have_http_status(:found)` | PASS |
| C71 | DELETE exception other org: 404 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/document_exceptions_spec.rb:115` - `have_http_status(:not_found)` | PASS |
| C72 | PATCH payee while Month not closed: 302 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/supporting_documents_spec.rb:220` - `have_http_status(:found)` | PASS |
| C73 | PATCH other-org document: 404 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/supporting_documents_spec.rb:363` - `have_http_status(:not_found)` | PASS |
| C74 | POST recibo without photo: 422 | batch exit 0 at `2eb7fad`; `-e` passed | `spec/requests/supporting_documents_spec.rb:110` - `have_http_status(:unprocessable_content)` ; `:111` - `include("Envie a foto do recibo")` | PASS |

## Coverage

Recomputed from plan Surface statuses, Landing doors 1–5, Relations entities, `SummarySpreadsheet::INFLOW_HEADERS` / `EXPENSE_HEADERS`, and the set tables in `checks.md`. Not copied from the author's table.

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| `POST /months/:year_month/close` statuses (3) | plan Surface | 302 C5 · 422 C1 · 404 C46 | - |
| `POST /months/:year_month/close` 422 reasons (7) | plan AC 1–4, 8, 9 + door 2 many-folders | missing document C1 · missing statement C2 · missing archive C3 · missing accountant C4 · writer raised C8 · already closed C9 · two `2026-05` folders C51 | - |
| `POST /months/:year_month/close` 404 reasons (2) | plan Surface + Observable | other organization C46 · never opened C56 | - |
| `POST /months/:year_month/reopen` statuses (3) | plan Surface | 302 C41 · 422 C44 · 404 C47 | - |
| `POST /months/:year_month/reopen` 404 reasons (2) | plan Surface | other organization C47 · never opened C57 | - |
| `GET /months/:year_month` statuses (3) | plan Surface | 200 C6 · 302 C59 · 404 C61 | - |
| `GET /months/:year_month` 302 reasons (2) | plan Observable | unauthenticated C59 · no focus C60 | - |
| `POST /months/:year_month/bank_statements` statuses (3) | plan Surface | 302 C62 · 422 C34 · 404 C63 | - |
| `POST /months/:year_month/matches` statuses (3) | plan Surface | 302 C64 · 422 C35 · 404 C65 | - |
| `DELETE /months/:year_month/matches/:id` statuses (3) | plan Surface | 302 C66 · 404 C67 · 422 C36 | - |
| `POST /months/:year_month/payments/:id/document_exception` statuses (3) | plan Surface | 302 C68 · 422 C37 · 404 C69 | - |
| `DELETE /months/:year_month/payments/:id/document_exception` statuses (3) | plan Surface | 302 C70 · 404 C71 · 422 C38 | - |
| `PATCH /supporting_documents/:id` statuses (3) | plan Surface | 302 C72 · 422 C39 · 404 C73 | - |
| `POST /supporting_documents` statuses (2) | plan Surface | 302 C40 · 422 C74 | - |
| Month closed transitions (4) | plan Relations + door 1 | open→closed C5 · closed→open C41 · close while closed C9 · reopen while open C44 | - |
| Close writer invocations (6) | plan Flow + door 4 | success once C5 · missing document none C1 · writer raised none C8 · already closed none C9 · reopen none C41 · concurrent once C48 | - |
| Drive folder name hits (3) | door 2 | zero create C29 · one reuse C30 · more than one raise C51 | - |
| Package file groups (4) | door 5 + #23 | `resumo-2026-05.xlsx` C23 · `extratos/` C24 · `notas/` C26 · no `notas-sem-casamento/` C28 | - |
| Statement filename extensions (3) | door 5 (`pdf` / `xlsx` / `csv`) | `.pdf` C24 · `.xlsx` C24 · `.csv` C25 | - |
| Document filename stems (2) | door 5 | recibo photo C26 · nota photo+xml same stem C27 | - |
| Spreadsheet exception copy (2) | door 3 `EXCEPTION_COPY` | `Tarifa bancária` C16 · `Honorário do contador` C50 | - |
| Accountant header (3) | door 3 + #22 | CNPJ + razão C12 · CPF no razão C13 · no PIX/email C14 | - |
| Writer adapter factory (2) | door 2 | in-memory C52 · Drive API v3 C53 | - |
| Relations entities (6) | plan Relations | Organization C49 · Month C5 · BankStatement C10 · Match C43 · SupportingDocument C40 · BankAccount C10 | - |
| Landing doors (5) | plan Landing | closed + folder id C5/C29/C41 · PackageArchiveWriter C23/C52 · summary xlsx C11 · in-request lock C54/C48 · stable stems C26 | - |
| Spreadsheet door-3 section titles (2) | door 3 sections Recebimentos and Custos/Despesas | no workbook assertion of either label (`rg` over `spec/` has zero `expect` of those strings on the xlsx) | Recebimentos, Custos/Despesas |
| Spreadsheet door-3 column headers (10) | door 3 + `SummarySpreadsheet::INFLOW_HEADERS` / `EXPENSE_HEADERS` | Data/Valor/Onde/Item as cell values C15 · O que/Exceção/Arquivo(s) C16 · Observação C19 · Arquivo(s) header index C16 | Detalhe, Detalhes |

Swept existing (read against the code):

- validation: `Month#close_blocker` (`app/models/month.rb:64-70`) still returns the four gate strings C1–C4 name
- failure modes: `persist_closed_package` rescues `PackageArchiveWriter::Error` (`month.rb:89-90`); `AmbiguousFolder < Error` (`package_archive_writer.rb:5`)
- idempotency: already-closed returns `CLOSED` (`month.rb:65`); second close after reopen reuses `month_folder_id` (`month.rb:85`)
- authorization: unauthenticated HTML still `302 /login` via `ApplicationController`; focus-scoped `find_month` (`months_controller.rb:78`)
- concurrency: `with_lock` on close and reopen (`month.rb:38`, `:51`)
- data lifecycle: reopen `update!(closed: false)` does not clear `month_folder_id` (`month.rb:57`); migration `closed` boolean `null: false, default: false` (`db/migrate/20260917140000_add_closed_to_months.rb:3-4`)
- state transitions: no `status`/`closing` column (C55)
- observability: n/a as the checks record

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decides, reached across a boundary | `month.rb` close gates; `summary_spreadsheet.rb`; `month_package.rb`; closed guards on statement/match/payment/supporting_document; reopen | boundary + own layer | no — dual proofs exist for C1–C5, C8–C10, C11–C22, C50, C23–C30, C34–C41, C43–C44, C51, but C20 does not assert SUM/minus on the three named value cells the coverage expectation names |
| Decides, not reached across a boundary | concurrent close lock `month.rb`; writer factory; Drive many-folders | own layer | yes — C48, C52, C53, C51 own-layer raise |
| Entry point that decides nothing | existing Surface 302/404 on GET months and open-month mutations | boundary | yes — C59–C74 |
| Instrumentation, pass-throughs | MonthsController close/reopen after `close_for_send`/`reopen` | none of its own | yes — proven by consumer request specs |

## Faults injected

Scratch `/tmp/tlc-verify-close-for-send` at HEAD `2eb7fad`. Real-tree porcelain empty before and after.

| Mutation | Location | Killed |
| --- | --- | --- |
| drop `return MISSING_DOCUMENT if …` | `app/models/month.rb:66` | yes — `spec/requests/close_spec.rb:16` expected 422, got 302 |
| `sheet.sheet_name = "Sheet1"` | `app/models/summary_spreadsheet.rb:29` | yes — `spec/models/summary_spreadsheet_spec.rb:32` expected `"2026-05"` |
| `kind = "nota"` for every document stem | `app/models/month_package.rb:60` | yes — `spec/models/month_package_spec.rb:53` expected `recibo-…` |
| remove closed guard in `SupportingDocument#submit` | `app/models/supporting_document.rb:41-44` | yes — `spec/requests/supporting_documents_spec.rb:474` expected 422, got 302 |
| reopen `update!(closed: true)` | `app/models/month.rb:57` | yes — `spec/requests/reopen_spec.rb:24` expected `closed?` false |

## Gate

`python3 .cursor/skills/tlc-spec-lean/scripts/validate_verification.py close-for-send --root /Users/gutors/Developer/ai-accounting-assistant` — run after this file; FAIL verdict is the finding, not a malformed report.
