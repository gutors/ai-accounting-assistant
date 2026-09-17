# Match and document exception verification

**Verdict**: FAIL
**Profile**: standard
**Diff range**: ce6362e..4d216912b3b2996667bd092084f01a80ea1a3a2f
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

User walk skipped: no binding screen; plan pins verification at `standard`, not `ui`. HTML request-spec feature; no human UI walk required.

Proofs re-run in full at HEAD `4d21691`: one `bin/rspec` invocation over the nine proof files (`spec/requests/months_spec.rb`, `spec/requests/matches_spec.rb`, `spec/requests/supporting_documents_spec.rb`, `spec/requests/document_exceptions_spec.rb`, `spec/requests/bank_statements_spec.rb`, `spec/models/payment_spec.rb`, `spec/models/match_spec.rb`, `spec/models/supporting_document_spec.rb`, `spec/models/bank_statement_spec.rb`) — 201 examples, 0 failures. Documentation capture listed every named selector from `checks.md` as passed. Each selector existed (`rg -n` / `it "..."` hit).

Real-tree porcelain at start and after worktree discard: empty. Scratch: `git worktree add /tmp/tlc-verify-match-and-exception-r1 HEAD`; discarded with `git worktree remove --force`.

## Binding sources

No design source for the screens. Plan: "No design source for the screens. Verification stays on project profile `standard` (no binding screen, so not `ui`)." No arrangement enumeration required under `standard`. GitHub issue URLs, `CONTEXT.md`, and ADR-0001 were opened (issues via `gh issue view`, not the 404 HTML fetch). They decide domain/cut, not a binding screen.

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| #33 Casamento e exceção documental | yes - `gh issue view 33` | none | - |
| #10 O que conta como casamento | yes - `gh issue view 10` plus resolution comments | none | - |
| #5 Como uma exceção documental é definida | yes - `gh issue view 5` plus resolution comments | none | - |
| #12 O casamento é automático, assistido, ou só manual | yes - `gh issue view 12` plus resolution comments | none — this cut is the manual confirm path; assisted suggestion stays #37 | - |
| #21 Sugestão de honorário | yes - `gh issue view 21` plus resolution comments | none — mark stays the coordinator’s; suggestion is later | - |
| #20 Mês do documento | yes - `gh issue view 20` plus resolution comments | none | - |
| `CONTEXT.md` Match / Document exception / Missing document / Observation / Unmatched document | yes - file | none | - |
| ADR-0001 Rails 8 + Hotwire, integer cents | yes - `docs/adr/0001-rails-8-hotwire.md` | none | - |
| n/a — no binding screen | n/a | none | - |

## Checks

Proofs verified at `4d21691`. Batch: 201 passed, 0 failed. Named example listed in documentation output unless noted.

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | GET `/months/2026-05` Payment 22000 cents unmatched: 200 and `Documento faltante` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/months_spec.rb:164` - `have_http_status(:ok)` ; `spec/requests/months_spec.rb:165` - `include("Documento faltante")` ; `spec/requests/months_spec.rb:166` - `include("R$ 220,00")` ; `spec/models/payment_spec.rb:27` - `be_missing_document` | PASS |
| C2 | zero Payments omits `Documento faltante` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/months_spec.rb:176` - `not_to include("Documento faltante")` | PASS |
| C3 | heading `Documentos sem casamento` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/months_spec.rb:186` - `include("Documentos sem casamento")` | PASS |
| C4 | empty unmatched pool includes `Nenhum documento sem casamento` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/months_spec.rb:196` - `include("Nenhum documento sem casamento")` | PASS |
| C5 | pool includes unmatched `Padaria Central` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/months_spec.rb:207` - `pool_html(...).to include("Padaria Central")` ; `spec/models/supporting_document_spec.rb:288` - `unmatched.map(&:payee)).to include("Padaria Central")` | PASS |
| C6 | focused org A omits org B payee | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/months_spec.rb:220` - `not_to include("Only Org B")` | PASS |
| C7 | unmatched document listing omits `Casado em 2026-05` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/supporting_documents_spec.rb:427` - `not_to include("Casado em 2026-05")` | PASS |
| C8 | Recebimentos Inflow omits `Documento faltante` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/months_spec.rb:232` - `recebimentos_html(...).not_to include("Documento faltante")` ; `spec/requests/months_spec.rb:233` - `include("R$ 63,00")` | PASS |
| C44 | unauthenticated GET months is 302 to `/login` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/months_spec.rb:7` - `have_http_status(:found)` ; `spec/requests/months_spec.rb:8` - `redirect_to("/login")` | PASS |
| C45 | GET months without focus is 302 to `/login` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/months_spec.rb:20` - `have_http_status(:found)` ; `spec/requests/months_spec.rb:21` - `redirect_to("/login")` | PASS |
| C46 | never-opened `2026-04` is 404 | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/months_spec.rb:118` - `have_http_status(:not_found)` | PASS |
| C47 | authenticated GET `/supporting_documents` is 200 | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/supporting_documents_spec.rb:43` - `have_http_status(:ok)` | PASS |
| C48 | unauthenticated GET `/supporting_documents` is 302 to `/login` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/supporting_documents_spec.rb:21` - `have_http_status(:found)` ; `spec/requests/supporting_documents_spec.rb:22` - `redirect_to("/login")` | PASS |
| C9 | POST 1 payment 2 documents: one Match, 302 to `/months/2026-05`, `Casado`, omits `Documento faltante` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:21` - `have_http_status(:found)` ; `spec/requests/matches_spec.rb:22` - `redirect_to("/months/2026-05")` ; `spec/requests/matches_spec.rb:23` - `Match.count).to eq(1)` ; `spec/requests/matches_spec.rb:26` - `include("Casado")` ; `spec/requests/matches_spec.rb:29` - `not_to include("Documento faltante")` ; `spec/models/match_spec.rb:40` - `be_persisted` ; `spec/models/match_spec.rb:41` - `count).to eq(1)` | PASS |
| C10 | after confirm, GET documents includes `Casado em 2026-05` for both | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:441` - `include("Casado em 2026-05")` ; `spec/models/supporting_document_spec.rb:299` - `doc_a.reload.month.year_month).to eq("2026-05")` ; `spec/models/supporting_document_spec.rb:300` - `doc_b.reload.month.year_month).to eq("2026-05")` | PASS |
| C11 | confirmed payees leave unmatched pool | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:43` - `pool_html(...).not_to include("Padaria A")` ; `spec/requests/matches_spec.rb:44` - `not_to include("Padaria B")` ; `spec/models/supporting_document_spec.rb:310` - `unmatched).to be_empty` | PASS |
| C12 | lesser with observation `desconto não documentado` persists and shows copy | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:58` - `have_http_status(:found)` ; `spec/requests/matches_spec.rb:59` - `Match.count).to eq(1)` ; `spec/requests/matches_spec.rb:61` - `include("desconto não documentado")` ; `spec/models/match_spec.rb:54` - `observation).to eq("desconto não documentado")` | PASS |
| C13 | lesser without observation: no Match, 422 `Informe a observação do casamento` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:73` - `have_http_status(:unprocessable_content)` ; `spec/requests/matches_spec.rb:74` - `include("Informe a observação do casamento")` ; `spec/requests/matches_spec.rb:75` - `Match.count).to eq(0)` ; `spec/models/match_spec.rb:64` - `errors[:base]).to include("Informe a observação do casamento")` | PASS |
| C14 | greater without observation: Match, 302 | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:87` - `have_http_status(:found)` ; `spec/requests/matches_spec.rb:88` - `Match.count).to eq(1)` ; `spec/models/match_spec.rb:74` - `be_persisted` | PASS |
| C15 | equal 1:1 without observation: Match, 302 | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:100` - `have_http_status(:found)` ; `spec/requests/matches_spec.rb:101` - `Match.count).to eq(1)` ; `spec/models/match_spec.rb:83` - `be_persisted` | PASS |
| C16 | 1 payment 0 documents: no Match, 422 `Selecione ao menos um documento` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:110` - `have_http_status(:unprocessable_content)` ; `spec/requests/matches_spec.rb:111` - `include("Selecione ao menos um documento")` ; `spec/requests/matches_spec.rb:112` - `Match.count).to eq(0)` ; `spec/models/match_spec.rb:92` - `errors[:base]).to include("Selecione ao menos um documento")` | PASS |
| C17 | DELETE match: no Match, 302, `Documento faltante`, pool, omits `Casado em 2026-05` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:126` - `have_http_status(:found)` ; `spec/requests/matches_spec.rb:127` - `redirect_to("/months/2026-05")` ; `spec/requests/matches_spec.rb:128` - `Match.count).to eq(0)` ; `spec/requests/matches_spec.rb:131` - `include("Documento faltante")` ; `spec/requests/matches_spec.rb:132` - `pool_html(...).to include("Padaria Central")` ; `spec/requests/matches_spec.rb:135` - `not_to include("Casado em 2026-05")` ; `spec/models/match_spec.rb:104` - `Match.count).to eq(0)` ; `spec/models/match_spec.rb:107` - `document.month_id).to be_nil` | PASS |
| C18 | already matched payment: no second Match, 422 `Pagamento já está em um casamento` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:151` - `have_http_status(:unprocessable_content)` ; `spec/requests/matches_spec.rb:152` - `include("Pagamento já está em um casamento")` ; `spec/requests/matches_spec.rb:153` - `Match.count).to eq(1)` ; `spec/models/match_spec.rb:120` - `errors[:base]).to include("Pagamento já está em um casamento")` | PASS |
| C19 | already matched document: no second Match, 422 `Documento já está em um casamento` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:169` - `have_http_status(:unprocessable_content)` ; `spec/requests/matches_spec.rb:170` - `include("Documento já está em um casamento")` ; `spec/requests/matches_spec.rb:171` - `Match.count).to eq(1)` ; `spec/models/match_spec.rb:133` - `errors[:base]).to include("Documento já está em um casamento")` | PASS |
| C20 | unauthenticated POST matches: no Match, 302 to `/login` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/matches_spec.rb:177` - `not_to change(Match, :count)` ; `spec/requests/matches_spec.rb:179` - `have_http_status(:found)` ; `spec/requests/matches_spec.rb:180` - `redirect_to("/login")` | PASS |
| C21 | unauthenticated DELETE match: keeps Match, 302 to `/login` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/matches_spec.rb:192` - `have_http_status(:found)` ; `spec/requests/matches_spec.rb:193` - `redirect_to("/login")` ; `spec/requests/matches_spec.rb:194` - `Match.exists?(match.id)).to be true` | PASS |
| C22 | PATCH payee on matched document keeps Match and `Casado` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:456` - `Match.count).to eq(1)` ; `spec/requests/supporting_documents_spec.rb:458` - `include("Casado")` ; `spec/models/supporting_document_spec.rb:324` - `Match.exists?(match.id)).to be true` ; `spec/models/supporting_document_spec.rb:325` - `payment.reload.match_id).to eq(match.id)` — HTTP does not assert 302 | PASS |
| C49 | PATCH kind recibo on xml-only NF without photo is 422 | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/supporting_documents_spec.rb:374` - `have_http_status(:unprocessable_content)` ; `spec/requests/supporting_documents_spec.rb:375` - `include("Envie a foto do recibo")` | PASS |
| C50 | PATCH other-org document is 404 | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/supporting_documents_spec.rb:363` - `have_http_status(:not_found)` ; `spec/requests/supporting_documents_spec.rb:364` - `payee).to eq("Payee B")` | PASS |
| C52 | Payment and SupportingDocument at most one Match via `match_id` | batch exit 0 at `4d21691`; `-e` passed | `spec/models/match_spec.rb:144` - `payment.reload.match_id).to eq(match.id)` ; `spec/models/match_spec.rb:151` - `second).not_to be_persisted` ; `spec/models/match_spec.rb:152` - `Match.count).to eq(1)` — asserts application reject, not `unique: true` on the index | PASS |
| C23 | POST 2 payments 1 document: one Match, 302, `Casado` on both, omits `Documento faltante` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:207` - `have_http_status(:found)` ; `spec/requests/matches_spec.rb:209` - `include("Casado")` ; `spec/requests/matches_spec.rb:210` - `not_to include("Documento faltante")` ; `spec/requests/matches_spec.rb:211` - `payment_a.reload.match_id).to be_present` ; `spec/requests/matches_spec.rb:212` - `payment_b.reload.match_id).to be_present` ; `spec/models/match_spec.rb:163` - `Match.count).to eq(1)` — `include("Casado")` is once on the page, not per row | PASS |
| C24 | POST 3 payments 1 document: one Match, 302 | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:224` - `have_http_status(:found)` ; `spec/requests/matches_spec.rb:225` - `Match.count).to eq(1)` ; `spec/models/match_spec.rb:174` - `be_persisted` | PASS |
| C25 | POST 2×2: no Match, 422 shape copy | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:239` - `have_http_status(:unprocessable_content)` ; `spec/requests/matches_spec.rb:240` - `include("Casamento é um pagamento com um ou mais documentos, ou vários pagamentos com um documento")` ; `spec/requests/matches_spec.rb:241` - `Match.count).to eq(0)` ; `spec/models/match_spec.rb:187` - `errors[:base]).to include(...)` | PASS |
| C26 | POST 0 payments 1 document: no Match, 422 `Selecione ao menos um pagamento` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:250` - `have_http_status(:unprocessable_content)` ; `spec/requests/matches_spec.rb:251` - `include("Selecione ao menos um pagamento")` ; `spec/requests/matches_spec.rb:252` - `Match.count).to eq(0)` ; `spec/models/match_spec.rb:197` - `errors[:base]).to include("Selecione ao menos um pagamento")` | PASS |
| C27 | POST `bank_fee`: persist, 302, `Tarifa bancária`, omits `Documento faltante` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/document_exceptions_spec.rb:17` - `have_http_status(:found)` ; `spec/requests/document_exceptions_spec.rb:18` - `redirect_to("/months/2026-05")` ; `spec/requests/document_exceptions_spec.rb:19` - `document_exception_kind).to eq("bank_fee")` ; `spec/requests/document_exceptions_spec.rb:22` - `include("Tarifa bancária")` ; `spec/requests/document_exceptions_spec.rb:23` - `not_to include("Documento faltante")` ; `spec/models/payment_spec.rb:37` - `eq("bank_fee")` | PASS |
| C28 | POST `accountant_fee`: `Honorário do contador`, omits `Documento faltante` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/document_exceptions_spec.rb:33` - `include("Honorário do contador")` ; `spec/requests/document_exceptions_spec.rb:34` - `not_to include("Documento faltante")` ; `spec/models/payment_spec.rb:46` - `eq("accountant_fee")` | PASS |
| C29 | DELETE `bank_fee`: no mark, 302, `Documento faltante`, omits `Tarifa bancária` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/document_exceptions_spec.rb:44` - `have_http_status(:found)` ; `spec/requests/document_exceptions_spec.rb:45` - `document_exception_kind).to be_nil` ; `spec/requests/document_exceptions_spec.rb:47` - `include("Documento faltante")` ; `spec/requests/document_exceptions_spec.rb:48` - `not_to include("Tarifa bancária")` ; `spec/models/payment_spec.rb:56` - `document_exception_kind).to be_nil` | PASS |
| C30 | POST kind neither: no mark, 422 `Informe se é tarifa bancária ou honorário do contador` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/document_exceptions_spec.rb:57` - `have_http_status(:unprocessable_content)` ; `spec/requests/document_exceptions_spec.rb:58` - `include("Informe se é tarifa bancária ou honorário do contador")` ; `spec/requests/document_exceptions_spec.rb:59` - `document_exception_kind).to be_nil` ; `spec/models/payment_spec.rb:65` - `errors[:base]).to include("Informe se é tarifa bancária ou honorário do contador")` — HTTP `include` is not unique to month-page copy (see Faults) | PASS |
| C31 | POST exception on matched payment: Match remains, no mark, 422 `Desfaça o casamento...` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/document_exceptions_spec.rb:72` - `have_http_status(:unprocessable_content)` ; `spec/requests/document_exceptions_spec.rb:73` - `include("Desfaça o casamento antes de marcar a exceção")` ; `spec/requests/document_exceptions_spec.rb:74` - `Match.count).to eq(1)` ; `spec/models/payment_spec.rb:77` - `errors[:base]).to include("Desfaça o casamento antes de marcar a exceção")` | PASS |
| C32 | confirm on `bank_fee` payment: Match, mark cleared, `Casado`, omits `Tarifa bancária` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/matches_spec.rb:265` - `Match.count).to eq(1)` ; `spec/requests/matches_spec.rb:266` - `document_exception_kind).to be_nil` ; `spec/requests/matches_spec.rb:268` - `include("Casado")` ; `spec/requests/matches_spec.rb:269` - `not_to include("Tarifa bancária")` ; `spec/models/match_spec.rb:209` - `document_exception_kind).to be_nil` | PASS |
| C33 | unauthenticated POST exception: no mark, 302 to `/login` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/document_exceptions_spec.rb:85` - `have_http_status(:found)` ; `spec/requests/document_exceptions_spec.rb:86` - `redirect_to("/login")` ; `spec/requests/document_exceptions_spec.rb:87` - `document_exception_kind).to be_nil` | PASS |
| C34 | unauthenticated DELETE exception: keeps mark, 302 to `/login` | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/document_exceptions_spec.rb:98` - `have_http_status(:found)` ; `spec/requests/document_exceptions_spec.rb:99` - `redirect_to("/login")` ; `spec/requests/document_exceptions_spec.rb:100` - `eq("bank_fee")` | PASS |
| C51 | `document_exception_kind` enum members `bank_fee` and `accountant_fee` | batch exit 0 at `4d21691`; `-e` passed | `spec/models/payment_spec.rb:83` - `keys).to contain_exactly("bank_fee", "accountant_fee")` ; `spec/models/payment_spec.rb:84` - `values).to contain_exactly("bank_fee", "accountant_fee")` | PASS |
| C53 | DELETE exception of other org: keeps mark, 404 | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/document_exceptions_spec.rb:115` - `have_http_status(:not_found)` ; `spec/requests/document_exceptions_spec.rb:116` - `eq("bank_fee")` | PASS |
| C35 | POST match with other-org payment: org B unchanged, 404 | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/matches_spec.rb:286` - `have_http_status(:not_found)` ; `spec/requests/matches_spec.rb:287` - `foreign_payment.reload.match_id).to be_nil` ; `spec/requests/matches_spec.rb:288` - `Match.count).to eq(0)` | PASS |
| C36 | POST match with other-org document: org B unchanged, 404 | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/matches_spec.rb:304` - `have_http_status(:not_found)` ; `spec/requests/matches_spec.rb:305` - `foreign_doc.reload.match_id).to be_nil` ; `spec/requests/matches_spec.rb:306` - `Match.count).to eq(0)` | PASS |
| C37 | POST exception for payment of `2026-04` on `2026-05`: no mark, 404 | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/document_exceptions_spec.rb:126` - `have_http_status(:not_found)` ; `spec/requests/document_exceptions_spec.rb:127` - `document_exception_kind).to be_nil` | PASS |
| C38 | DELETE other-org match: keeps Match, 404 | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/matches_spec.rb:322` - `have_http_status(:not_found)` ; `spec/requests/matches_spec.rb:323` - `Match.exists?(foreign_match.id)).to be true` | PASS |
| C39 | replace statement dissolves Match; documents return to pool; omit `Casado em 2026-05` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/bank_statements_spec.rb:326` - `Match.count).to eq(0)` ; `spec/requests/bank_statements_spec.rb:328` - `pool_html(...).to include("Padaria Central")` ; `spec/requests/bank_statements_spec.rb:330` - `not_to include("Casado em 2026-05")` ; `spec/models/bank_statement_spec.rb:228` - `Match.count).to eq(0)` ; `spec/models/bank_statement_spec.rb:230` - `document.month_id).to be_nil` | PASS |
| C40 | concurrent confirms sharing a document persist exactly one Match | batch exit 0 at `4d21691`; `-e` passed | `spec/models/match_spec.rb:236` - `where(supporting_documents: { id: document.id }).count).to eq(1)` ; `spec/models/match_spec.rb:237` - `match_id).to be_present` | PASS |
| C41 | concurrent confirms sharing a payment persist exactly one Match | batch exit 0 at `4d21691`; `-e` passed | `spec/models/match_spec.rb:266` - `where(payments: { id: payment.id }).count).to eq(1)` ; `spec/models/match_spec.rb:267` - `match_id).to be_present` | PASS |
| C42 | every payment matched or excepted omits `Documento faltante` | batch exit 0 at `4d21691`; both `-e` passed | `spec/requests/months_spec.rb:248` - `not_to include("Documento faltante")` ; `spec/models/payment_spec.rb:94` - `missing_document).to be_empty` | PASS |
| C43 | DELETE missing match id is 404 | batch exit 0 at `4d21691`; `-e` passed | `spec/requests/matches_spec.rb:331` - `have_http_status(:not_found)` | PASS |

## Coverage

Recomputed from plan Surface / Relations / Landing / door 3 enum, not copied from the author’s table. Members taken from those authorities; each confirmed against a proof that asserts it.

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| `GET /months/:year_month` statuses (3) | plan Surface | 200 C1 `have_http_status(:ok)` · 302 C44 `have_http_status(:found)` · 404 C46 `have_http_status(:not_found)` | - |
| `GET /months/:year_month` 302 reasons (2) | plan Surface + Observable who-may-call | unauthenticated C44 · no focus C45 | - |
| `POST /months/:year_month/matches` statuses (3) | plan Surface | 302 C9 `have_http_status(:found)` · 422 C13 `have_http_status(:unprocessable_content)` · 404 C35 `have_http_status(:not_found)` | - |
| `POST /months/:year_month/matches` 422 reasons (6) | plan Observable error codes AC 13, 16, 18, 19, 25, 26 | lesser no observation C13 · 0 documents C16 · payment already matched C18 · document already matched C19 · N×M C25 · 0 payments C26 | - |
| `POST /months/:year_month/matches` 404 reasons (2) | plan AC 35, 36 | other-org payment C35 · other-org document C36 | - |
| `DELETE /months/:year_month/matches/:id` statuses (2) | plan Surface | 302 C17 `have_http_status(:found)` · 404 C43 `have_http_status(:not_found)` | - |
| `DELETE /months/:year_month/matches/:id` 404 reasons (2) | plan AC 38, 43 | other org C38 · missing id C43 | - |
| `POST .../document_exception` statuses (3) | plan Surface | 302 C27 `have_http_status(:found)` · 422 C30 `have_http_status(:unprocessable_content)` · 404 C37 `have_http_status(:not_found)` | - |
| `POST .../document_exception` 422 reasons (2) | plan AC 30, 31 | unknown kind C30 · already matched C31 | - |
| `DELETE .../document_exception` statuses (2) | plan Surface | 302 C29 `have_http_status(:found)` · 404 C53 `have_http_status(:not_found)` | - |
| `GET /supporting_documents` statuses (2) | plan Surface | 200 C47 `have_http_status(:ok)` · 302 C48 `have_http_status(:found)` | - |
| `PATCH /supporting_documents/:id` statuses (3) | plan Surface | 422 C49 `have_http_status(:unprocessable_content)` · 404 C50 `have_http_status(:not_found)` | 302 — C22 named proofs do not assert 302; author’s join listed C22 |
| Match shapes accepted (4) | Landing door 2 | 1:N C9 · 1:1 C15 · 2:1 C23 · 3:1 C24 | - |
| Match shapes rejected (3) | Landing door 2 | 0 documents C16 · 0 payments C26 · 2×2 C25 | - |
| Amount vs observation (4) | #10 / AC 12–15 | equal C15 · greater C14 · lesser with observation C12 · lesser without C13 | - |
| Payment trichotomy (3) | #5 / CONTEXT | missing document C1 · matched C9 · exception C27 | - |
| Payment transitions (6) | plan criteria | missing→matched C9 · missing→exception C27 · exception→missing C29 · exception→matched C32 · matched→missing C17 · matched→exception forbidden C31 | - |
| Exception kinds (2) | Landing door 3 / AC 27–28 | `bank_fee` C27 · `accountant_fee` C28 | - |
| Exception kind enum (2) | door 3 persisted values | C51 `contain_exactly("bank_fee", "accountant_fee")` | - |
| At most one Match per member (2) | Relations / door 1 membership | Payment C18 · SupportingDocument C19 | - |
| Relations entities (5) | plan Relations | Month C9 · Match C9 · Payment C9 · SupportingDocument C9 · Organization C6 | - |
| Landing doors (5) | plan Landing | Match entity C9 · shape 1:N or N:1 C25 · exception xor Match C31 · optional Month C10 · destroy Payment dissolves Match C39 | - |

Sweep of plan Landing / Relations / Surface: every Surface route has a status row; every Relations entity has a row; every Landing door has a row. Door 1’s written unique index on `match_id` is not in schema (`index_payments_on_match_id` is non-unique); checks Handoff abandoned it because a unique index would forbid 1:N and N:1. Membership “at most one Match” is the FK plus C18/C19/C52, not a unique index. No extra Surface route without a row.

HTTP-boundary claims listed in checks.md each have a request-spec proof that ran. C40/C41 stay model-layer as the checks state.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decides, reached across a boundary | `app/models/match.rb`, `app/models/payment.rb` exception API, month show labels, `BankStatement` replace dissolve | boundary and own layer; contract at HTTP; one case per decision-table row at own layer | yes for confirm accepts/rejects C9, C12–C16, C18, C19, C23–C26, C32; leave-match C17; exception mark/unmark C27–C31; month assignment C10, C11, C22; replace C39 — except C30 HTTP copy is not unique (Faults) |
| Decides, not reached across a boundary | concurrent unique `match_id` in `app/models/match.rb` | own layer C40, C41 | yes |
| Entry point that decides nothing | GET months unauth / no-focus / never-opened; DELETE 404; GET documents 200/302; PATCH 422/404 | boundary: accepted, rejected, error paths | yes for those named guards; PATCH success 302 has no check assertion |
| Instrumentation, pass-throughs | none in this cut | none of its own | yes — n/a |

## Faults injected

Baseline real-tree `git status --porcelain`: empty. Scratch at HEAD `4d21691`. Each mutation reverted before the next. Scratch removed; real-tree porcelain empty again.

| Mutation | Location | Killed |
| --- | --- | --- |
| `Payment#missing_document?` always `false` | `app/models/payment.rb` (scratch) | yes — C1 `spec/requests/months_spec.rb:165` `include("Documento faltante")` failed |
| `Match#valid_shape?` always `true` | `app/models/match.rb` (scratch) | yes — C25 `spec/requests/matches_spec.rb:239` expected 422, got 302 |
| Removed `bank_fee`/`accountant_fee` allow-list in `mark_document_exception` | `app/models/payment.rb` (scratch) | no — C30 HTTP `spec/requests/document_exceptions_spec.rb:57-58` still passed (Rails 8.1 maps `ActiveRecord::RecordInvalid` to 422; debug exception page still contains the `UNKNOWN_KIND` string). Own-layer C30 was killed (`RecordInvalid` at `payment.rb:27`) |
| Dropped `payment_ids` size mismatch `404` | `app/controllers/matches_controller.rb` (scratch) | yes — C35 expected 404, got 422 |
| `Payment#dissolve_own_match` no-op | `app/models/payment.rb` (scratch) | yes — C39 `spec/models/bank_statement_spec.rb:228` `Match.count` expected 0, got 1 |

## Swept existing

Re-read against code at `4d21691`:

- `ApplicationController#require_account` still `redirect_to login_path, status: :found` (`app/controllers/application_controller.rb:27`)
- GET months never-opened still 404 (C46 example unchanged; `MatchesController#find_opened_month` / months show)
- `BankStatement` still `has_many :payments, dependent: :destroy`; replace still `payments.destroy_all`; `Payment#before_destroy :dissolve_own_match` is the new dissolve
- XOR check `payments_match_xor_document_exception` present in `db/schema.rb:163`
- Money remains `amount_cents` bigint / Ruby Integer
- `PATCH /supporting_documents/:id` still routed (`config/routes.rb:34`)

n/a rows (dependency failure, observability) stay policy.

## Gate

`python3 .cursor/skills/tlc-spec-lean/scripts/validate_verification.py match-and-exception` — exit 1: `verdict is FAIL - route the ranked gaps back as fixes, then re-verify` (1 error, 0 warnings). Honest FAIL; report structure held (profile `standard`, Coverage, Faults, Binding sources, Test policy).

**Ranked gaps**:
1. Surviving mutant — C30 HTTP — removing the kind allow-list still satisfies `have_http_status(:unprocessable_content)` and `include("Informe se é tarifa bancária ou honorário do contador")` because `RecordInvalid` is 422 and the debug page quotes `UNKNOWN_KIND`
2. Coverage unproven member — `PATCH /supporting_documents/:id` status 302 — C22 does not assert 302; no other check does
