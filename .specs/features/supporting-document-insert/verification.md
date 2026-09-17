# Supporting document insert verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: 4d884cb..HEAD (`82975200be36ade652ebe50eb588e39c9f07f306`)
**Round**: 3 - scoped
**Verifier**: independent sub-agent (author != verifier)

User walk skipped: no binding screen; plan pins verification at `standard`, not `ui`. HTML request-spec feature; no human UI walk required. Carried from `4f7d316`.

Proofs re-run in full at HEAD `8297520`: one `ruby bin/rspec` invocation over the five proof files (`spec/requests/supporting_documents_spec.rb`, `spec/models/supporting_document_spec.rb`, `spec/requests/organizations_spec.rb`, `spec/requests/sessions_spec.rb`, `spec/config/application_spec.rb`) — 85 examples, 0 failures. Every named selector from `checks.md` existed (`rg -n` / `it "..."` hit) and appeared as passed in that run.

Fix `8297520` touched only `spec/requests/supporting_documents_spec.rb` (C8/C15 list-row cluster `match`). Request-spec citations refreshed at `8297520`. Model, organizations, sessions, and application-config evidence carried from `4f7d316` (those files untouched; `rg -n` line numbers unchanged).

Real-tree porcelain at start and after worktree discard: empty. Scratch: `git worktree add /tmp/tlc-verify-sdi-r3 HEAD`; discarded with `git worktree remove --force`.

## Binding sources

Carried from `4f7d316`. Step 1 (`ui`) has empty input. Plan: "No design source for the screens. Verification stays on project profile `standard` (no binding screen, so not `ui`)." GitHub issue URLs, `CONTEXT.md`, and ADR-0001 are product/domain sources, not a binding screen. Fix did not touch the interface. Did not drop to light.

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| n/a — no binding screen | n/a | none | - |

## Checks

Proofs verified at `8297520`. Request-spec `file:line` refreshed at `8297520`. Other-file evidence carried from `4f7d316`. C8 and C15 re-proven at this HEAD (round-2 non-PASS).

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | unauthenticated GET /supporting_documents is 302 to /login | batch exit 0 at `8297520`; `-e "unauthenticated GET /supporting_documents responds 302 to /login"` passed | `spec/requests/supporting_documents_spec.rb:21` - `have_http_status(:found)` ; `spec/requests/supporting_documents_spec.rb:22` - `redirect_to("/login")` | PASS |
| C2 | GET /supporting_documents without focus is 302 to /login | batch exit 0 at `8297520`; `-e "GET /supporting_documents without focus responds 302 to /login"` passed | `spec/requests/supporting_documents_spec.rb:34` - `have_http_status(:found)` ; `spec/requests/supporting_documents_spec.rb:35` - `redirect_to("/login")` | PASS |
| C3 | authenticated GET / includes link text `Documentos` and href `/supporting_documents` | batch exit 0 at `8297520`; `-e "organization home links Documentos to /supporting_documents"` passed | `spec/requests/organizations_spec.rb:71` - `have_http_status(:ok)` ; `spec/requests/organizations_spec.rb:72` - `include("Documentos")` ; `spec/requests/organizations_spec.rb:73` - `include('href="/supporting_documents"')` (two includes, not one node) — carried from `4f7d316` | PASS |
| C4 | GET /supporting_documents is 200, pt-BR, heading `Documentos de suporte` | batch exit 0 at `8297520`; `-e "GET /supporting_documents responds 200 with pt-BR and Documentos de suporte"` passed | `spec/requests/supporting_documents_spec.rb:43` - `have_http_status(:ok)` ; `spec/requests/supporting_documents_spec.rb:44` - `include('lang="pt-BR"')` ; `spec/requests/supporting_documents_spec.rb:45` - `include("Documentos de suporte")` | PASS |
| C5 | empty list includes `Nenhum documento` | batch exit 0 at `8297520`; `-e "GET /supporting_documents with no documents includes Nenhum documento"` passed | `spec/requests/supporting_documents_spec.rb:53` - `include("Nenhum documento")` | PASS |
| C6 | GET /supporting_documents with no Month is 200 | batch exit 0 at `8297520`; `-e "GET /supporting_documents with no Month responds 200"` passed | `spec/requests/supporting_documents_spec.rb:61` - `have_http_status(:ok)` ; `spec/requests/supporting_documents_spec.rb:62` - `Month.count).to eq(0)` | PASS |
| C7 | focused org A omits org B payee | batch exit 0 at `8297520`; `-e "documents page does not include another organization payee"` passed | `spec/requests/supporting_documents_spec.rb:75` - `not_to include("Only Org B")` | PASS |
| C8 | POST recibo jpg persists one, 302 to /supporting_documents, page includes `11/05/2026`, `R$ 155,00`, `Padaria Central`, `Recibo`, filename | batch exit 0 at `8297520`; both `-e` passed | persist/redirect: `spec/requests/supporting_documents_spec.rb:83-85` - `:found`, `redirect_to("/supporting_documents")`, `count).to eq(1)` ; list cluster: `spec/requests/supporting_documents_spec.rb:89` - `match(%r{<time datetime="2026-05-11">11/05/2026</time>\\s*R\\$ 155,00\\s*Recibo\\s*Padaria Central}m)` — `\s*` is whitespace only, so insert-form options (before `Sem mês` slice) and the per-row PATCH `options_for_select` (HTML between amount and select) cannot satisfy `Recibo` between `R$ 155,00` and `Padaria Central` ; `spec/requests/supporting_documents_spec.rb:90` - `include("recibo.jpg")` ; model persist: `spec/models/supporting_document_spec.rb:30-32` - `be_persisted`, `eq(organization)`, `count).to eq(1)` — carried from `4f7d316` | PASS |
| C9 | amount persists as Integer `15500` | batch exit 0 at `8297520`; `-e "insert recibo amount_cents is Integer 15500"` passed | `spec/models/supporting_document_spec.rb:38` - `be_a(Integer)` ; `spec/models/supporting_document_spec.rb:39` - `eq(15500)` — carried from `4f7d316` | PASS |
| C10 | recibo photo via Active Storage, no XML, not Drive | batch exit 0 at `8297520`; `-e "insert recibo attaches photo via Active Storage and no xml"` passed | `spec/models/supporting_document_spec.rb:45` - `photo).to be_attached` ; `spec/models/supporting_document_spec.rb:46` - `service_name).to eq("test")` ; `spec/models/supporting_document_spec.rb:47` - `xml).not_to be_attached` ; `spec/models/supporting_document_spec.rb:48` - `storage.yml` `not_to match(/Drive/)` — carried from `4f7d316` | PASS |
| C11 | insert belongs to Account and no Month | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:98` - `not_to change(Month, :count)` ; `spec/requests/supporting_documents_spec.rb:100` - `last.account).to eq(account)` ; `spec/models/supporting_document_spec.rb:54` - `doc.account).to eq(account)` ; `spec/models/supporting_document_spec.rb:55` - `reflect_on_association(:month)).to be_nil` ; `spec/models/supporting_document_spec.rb:56` - `column_names).not_to include("month_id")` | PASS |
| C12 | POST recibo without photo: no row, 422 `Envie a foto do recibo` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:110-112` - `:unprocessable_content`, `include("Envie a foto do recibo")`, `count).to eq(0)` ; `spec/models/supporting_document_spec.rb:62-63` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C13 | POST recibo with XML: no row, 422 `Recibo não tem XML` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:120-122` - `:unprocessable_content`, `include("Recibo não tem XML")`, `count).to eq(0)` ; `spec/models/supporting_document_spec.rb:69-70` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C14 | unauthenticated POST persists none, 302 to /login | batch exit 0 at `8297520`; `-e "unauthenticated POST /supporting_documents responds 302 to /login"` passed | `spec/requests/supporting_documents_spec.rb:128` - `not_to change(SupportingDocument, :count)` ; `spec/requests/supporting_documents_spec.rb:130-131` - `:found`, `redirect_to("/login")` | PASS |
| C15 | POST nota_fiscal photo: photo, no XML, 302, page includes `Nota fiscal` and filename | batch exit 0 at `8297520`; both `-e` passed | blobs/redirect: `spec/requests/supporting_documents_spec.rb:139-143` - `:found`, `redirect_to("/supporting_documents")`, `photo).to be_attached`, `xml).not_to be_attached` ; list cluster: `spec/requests/supporting_documents_spec.rb:147` - `match(%r{<time datetime="2026-05-11">11/05/2026</time>\\s*R\\$ 155,00\\s*Nota fiscal\\s*Padaria Central}m)` — same whitespace-only conjunct as C8, so insert-form and PATCH `options_for_select` cannot supply `Nota fiscal` ; `spec/requests/supporting_documents_spec.rb:148` - `include("danfe.jpg")` ; model: `spec/models/supporting_document_spec.rb:76-78` - `be_persisted`, `photo).to be_attached`, `xml).not_to be_attached` — carried from `4f7d316` | PASS |
| C16 | POST nota_fiscal XML only: xml blob, no photo, page includes XML filename | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:156-159` - `:found`, `xml).to be_attached`, `photo).not_to be_attached` ; `spec/requests/supporting_documents_spec.rb:162` - `include("autorizada.xml")` ; `spec/models/supporting_document_spec.rb:84-86` - `be_persisted`, `xml).to be_attached`, `photo).not_to be_attached` | PASS |
| C17 | POST nota_fiscal photo and XML attaches both | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:170-173` - `:found`, `photo).to be_attached`, `xml).to be_attached` ; `spec/models/supporting_document_spec.rb:92-94` - `be_persisted`, both `be_attached` | PASS |
| C18 | POST nota_fiscal with neither file: no row, 422 `Envie a foto e/ou o XML` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:181-183` - `:unprocessable_content`, `include("Envie a foto e/ou o XML")`, `count).to eq(0)` ; `spec/models/supporting_document_spec.rb:100-101` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C19 | typed `155,00` with XML `<vNF>100.00</vNF>` persists `15500` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:191` - `amount_cents).to eq(15500)` ; `spec/models/supporting_document_spec.rb:107` - `amount_cents).to eq(15500)` | PASS |
| C20 | list shows `12/05/2026` before `11/05/2026` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:201` - `index("12/05/2026")).to be < ...index("11/05/2026")` ; `spec/models/supporting_document_spec.rb:113` - `listed).to eq([ newer, older ])` ; `spec/models/supporting_document_spec.rb:118` - tied ids `[ second, first ]` | PASS |
| C21 | duplicate amount/date/payee persists both | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:210` - `count).to eq(2)` ; `spec/models/supporting_document_spec.rb:125` - `count).to eq(2)` | PASS |
| C22 | PATCH payee `Mercado Silva` 302, page includes new payee not old | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:220-224` - `:found`, `redirect_to("/supporting_documents")`, `include("Mercado Silva")`, `not_to include("Padaria Central")` ; `spec/models/supporting_document_spec.rb:132` - `payee).to eq("Mercado Silva")` | PASS |
| C23 | PATCH payee omitting files keeps photo and XML blobs | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:235-238` - both `be_attached`, filenames `danfe.jpg` / `autorizada.xml` ; `spec/models/supporting_document_spec.rb:140-141` - same filenames | PASS |
| C24 | PATCH new photo replaces filename on the page | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:249-250` - `include("foto-nova.jpg")`, `not_to include("foto-antiga.jpg")` ; `spec/models/supporting_document_spec.rb:148` - `filename.to_s).to eq("foto-nova.jpg")` | PASS |
| C25 | POST observation `pago em dinheiro` appears on the page | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:259` - `include("pago em dinheiro")` ; `spec/models/supporting_document_spec.rb:154` - `observation).to eq("pago em dinheiro")` | PASS |
| C26 | blank observation persists; page omits `pago em dinheiro` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:268-269` - `count).to eq(1)`, `not_to include("pago em dinheiro")` ; `spec/models/supporting_document_spec.rb:160-161` - `be_persisted`, `observation).to be_nil` | PASS |
| C27 | amount `0` or blank: no row, 422 `Informe valor, data e favorecido` | batch exit 0 at `8297520`; both `-e` passed | HTTP `0` only: `spec/requests/supporting_documents_spec.rb:277-279` - `:unprocessable_content`, `include("Informe valor, data e favorecido")`, `count).to eq(0)` ; own layer both: `spec/models/supporting_document_spec.rb:165-169` - `[ "0", "" ]` `not_to be_persisted`, `count).to eq(0)` | PASS |
| C28 | blank payee: no row, 422 `Informe valor, data e favorecido` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:287-289` - `:unprocessable_content`, `include("Informe valor, data e favorecido")`, `count).to eq(0)` ; `spec/models/supporting_document_spec.rb:175-176` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C29 | invalid date: no row, 422 `Informe valor, data e favorecido` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:297-299` - `:unprocessable_content`, `include("Informe valor, data e favorecido")`, `count).to eq(0)` ; `spec/models/supporting_document_spec.rb:182-183` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C30 | kind other: no row, 422 `Informe se é nota fiscal ou recibo` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:307-309` - `:unprocessable_content`, `include("Informe se é nota fiscal ou recibo")`, `count).to eq(0)` ; `spec/models/supporting_document_spec.rb:189-190` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C31 | photo or XML > `10485760`: no row, 422 `Cada arquivo pode ter no máximo 10 MB` | batch exit 0 at `8297520`; both `-e` passed | HTTP photo: `spec/requests/supporting_documents_spec.rb:317-319` - `:unprocessable_content`, `include("Cada arquivo pode ter no máximo 10 MB")`, `count).to eq(0)` ; own layer both: `spec/models/supporting_document_spec.rb:197-199` - photo and xml `not_to be_persisted`, `count).to eq(0)` | PASS |
| C32 | photo `.heic`: no row, 422 `A foto deve ser JPEG, PNG, WebP ou PDF` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:327-329` - `:unprocessable_content`, `include("A foto deve ser JPEG, PNG, WebP ou PDF")`, `count).to eq(0)` ; `spec/models/supporting_document_spec.rb:205-206` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C33 | XML `.txt`: no row, 422 `O XML deve ser um arquivo .xml` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:337-339` - `:unprocessable_content`, `include("O XML deve ser um arquivo .xml")`, `count).to eq(0)` ; `spec/models/supporting_document_spec.rb:212-213` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C34 | payee 201 chars: no row, 422 `Favorecido pode ter no máximo 200 caracteres` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:347-349` - `:unprocessable_content`, `include("Favorecido pode ter no máximo 200 caracteres")`, `count).to eq(0)` ; `spec/models/supporting_document_spec.rb:219-220` - `not_to be_persisted`, `count).to eq(0)` | PASS |
| C35 | PATCH other-org id: 404, org B unchanged | batch exit 0 at `8297520`; `-e "PATCH supporting_document of another organization returns 404"` passed | `spec/requests/supporting_documents_spec.rb:363` - `have_http_status(:not_found)` ; `spec/requests/supporting_documents_spec.rb:364` - `payee).to eq("Payee B")` | PASS |
| C36 | PATCH kind recibo on xml-only NF without photo: unchanged, 422 `Envie a foto do recibo` | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:374-378` - `:unprocessable_content`, `include("Envie a foto do recibo")`, `kind).to eq("nota_fiscal")`, `xml).to be_attached` ; `spec/models/supporting_document_spec.rb:227-229` - `errors[:base]).to include("Envie a foto do recibo")`, `kind).to eq("nota_fiscal")`, `xml).to be_attached` | PASS |
| C37 | PATCH kind recibo with photo: kind recibo, that photo, no XML | batch exit 0 at `8297520`; both `-e` passed | `spec/requests/supporting_documents_spec.rb:389-392` - `kind).to eq("recibo")`, `photo).to be_attached`, `filename ... eq("recibo-novo.jpg")`, `xml).not_to be_attached` ; `spec/models/supporting_document_spec.rb:237-239` - same kind / filename / xml gone | PASS |
| C38 | concurrent valid recibo POSTs persist two | batch exit 0 at `8297520`; `-e "concurrent recibo inserts persist two SupportingDocuments"` passed | `spec/models/supporting_document_spec.rb:280` - `where(organization: org).count).to eq(2)` — carried from `4f7d316` | PASS |
| C39 | DELETE /supporting_documents/:id is 404 and keeps the row | batch exit 0 at `8297520`; `-e "DELETE /supporting_documents/:id returns 404 and keeps the row"` passed | `spec/requests/supporting_documents_spec.rb:402` - `have_http_status(:not_found)` ; `spec/requests/supporting_documents_spec.rb:403` - `find(id)).to be_persisted` ; `config/routes.rb:28-30` has no DELETE | PASS |
| C40 | unauthenticated PATCH unchanged, 302 to /login | batch exit 0 at `8297520`; `-e "unauthenticated PATCH /supporting_documents/:id responds 302 to /login"` passed | `spec/requests/supporting_documents_spec.rb:415-417` - `:found`, `redirect_to("/login")`, `payee).to eq("Padaria Central")` | PASS |
| C41 | unauthenticated GET / is 302 to /login | batch exit 0 at `8297520`; `-e "unauthenticated GET / responds 302 to /login"` passed | `spec/requests/sessions_spec.rb:7` - `have_http_status(:found)` ; `spec/requests/sessions_spec.rb:8` - `redirect_to("/login")` — carried from `4f7d316` (example not in `4d884cb..HEAD`) | PASS |
| C42 | kind enum members are `nota_fiscal` and `recibo` | batch exit 0 at `8297520`; `-e "kind enum members are nota_fiscal and recibo"` passed | `spec/models/supporting_document_spec.rb:243` - `kinds.keys).to contain_exactly("nota_fiscal", "recibo")` — carried from `4f7d316` | PASS |
| C43 | attachments `photo` and `xml` | batch exit 0 at `8297520`; `-e "has_one_attached photo and xml"` passed | `spec/models/supporting_document_spec.rb:247` - `reflect_on_attachment(:photo)).to be_present` ; `spec/models/supporting_document_spec.rb:248` - `reflect_on_attachment(:xml)).to be_present` — carried from `4f7d316` | PASS |
| C44 | Active Storage loaded; test Disk `tmp/storage`; no Drive service | batch exit 0 at `8297520`; `-e "loads Active Storage Disk test service, skips Drive and Kamal"` passed | `spec/config/application_spec.rb:9-13` - `defined?(ActiveStorage::Engine)).not_to be_nil`, `service).to eq(:test)`, `be_a(ActiveStorage::Service::DiskService)`, `root ... include("tmp/storage")`, `storage.yml` `not_to match(/Drive/)` — carried from `4f7d316`; evidence about the **test** boot | PASS |
| C45 | insert accepts photo extensions jpg jpeg png webp pdf | batch exit 0 at `8297520`; `-e "insert accepts photo extensions jpg jpeg png webp pdf"` passed | `spec/models/supporting_document_spec.rb:251-257` - `%w[jpg jpeg png webp pdf].each` `be_persisted` and `filename ... eq("foto.#{ext}")`, `count).to eq(5)` — carried from `4f7d316` | PASS |

## Coverage

Carried from `70cfd5b` (recomputed at `4f7d316`). Fix only strengthened C8/C15 assertions; set members and authorities unchanged. Kind list copy `Recibo` / `Nota fiscal` is named by C8 and C15 and is now uniquely asserted by the row-cluster `match`; it is not an extra Coverage set.

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| `GET /` statuses (2) | plan Surface | 200 C3 · 302 C41 | - |
| `GET /supporting_documents` statuses (2) | plan Surface | 200 C4 · 302 C1 | - |
| `GET /supporting_documents` 302 reasons (2) | plan AC 1–2 | unauthenticated C1 · no focus C2 | - |
| `POST /supporting_documents` statuses (2) | plan Surface | 302 C8 · 422 C12 | - |
| `PATCH /supporting_documents/:id` statuses (3) | plan Surface | 302 C22 · 422 C36 · 404 C35 | - |
| `DELETE /supporting_documents/:id` statuses (1) | plan Surface | 404 C39 | - |
| kind enum (2) | Landing door 2 | keys C42 · insert path recibo C8 · insert path nota_fiscal C15 | - |
| recibo file rules (2) | plan AC 12–13 | no photo C12 · with XML C13 | - |
| nota fiscal files (4) | plan AC 15–18 | photo only C15 · XML only C16 · both C17 · neither C18 | - |
| POST 422 reasons (11) | plan POST error ACs 12, 13, 18, 27–34 | recibo no photo C12 · recibo XML C13 · NF neither C18 · amount 0 or blank C27 · blank payee C28 · invalid date C29 · bad kind C30 · oversized C31 · `.heic` C32 · `.txt` XML C33 · payee 201 C34 | - |
| amount rejects (2) | plan AC 27 | `0` C27 · blank C27, table-driven over 2 at own layer; HTTP 422 is the `0` case | - |
| oversized files (2) | plan AC 31 | photo C31 · xml C31, table-driven over 2 at own layer; HTTP 422 is the photo case | - |
| photo extensions accepted (5) | plan assumption / AC 32 accepted members | C45, table-driven over all 5 | - |
| observation (2) | plan AC 25–26 | present C25 · blank C26 | - |
| Active Storage attachments (2) | Landing door 4 | `photo` C43 · `xml` C43 | - |
| Relations entities (3) | plan Relations | Organization C8 · SupportingDocument C8 · Account C11 | - |
| Landing doors (5) | plan Landing | no Month C11 · kind enum C42 · typed amount C9 / date+payee C8 / observation optional C26 · Active Storage C44 · inserter C11 | - |
| startup config: Active Storage (1 assembly) | Landing door 4 + `config/application.rb:8` + `config/environments/test.rb:31` + `config/storage.yml` | Rails test app C44 | - |

Swept `existing`: carried from `4f7d316`. Checks.md Swept has no `existing` rows. Plan Observable `existing` on `/` was not in the fix blast radius.

## Test policy rows

C8/C15 kind-label conjunct re-judged at `8297520`. Other rows carried from `4f7d316`.

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decides, reached across a boundary | `app/models/supporting_document.rb` insert/submit/apply; `app/controllers/supporting_documents_controller.rb` create/update/index | boundary + own layer: insert file rules C8/C12/C13/C15–C18; typed fields C8/C9/C19/C27–C29/C34; observation C25–C26; extensions C32+C45; 10 MiB C31; opaque XML C19; PATCH C22–C24/C36–C37; list order C20 | yes — dual proofs present; C8/C15 kind-label conjunct is now the list-row cluster `match` (time, `R$ 155,00`, kind, payee) so insert-form and nested PATCH select labels cannot satisfy it |
| Decides, not reached across a boundary | kind enum `supporting_document.rb`; concurrent insert | own layer C42, C38 | yes — carried from `4f7d316` |
| Entry point that decides nothing | GET guards / empty / DELETE 404 / unauth POST·PATCH / cross-org PATCH | boundary C1 C2 C4 C5 C6 C14 C35 C39 C40 C41 | yes — carried from `4f7d316` |
| Instrumentation, pass-throughs | controller delegates to `SupportingDocument.insert` / `apply` | none of its own | yes — carried from `4f7d316` |

## Faults injected

Re-injected at `8297520` on the list-row cluster `match` surface (the only surface the spec-only fix created). Four already-killed round-1 mutants carried from `4f7d316` (this fix could not have changed them). Scratch `/tmp/tlc-verify-sdi-r3`. Real-tree porcelain matched the empty baseline after discard.

| Mutation | Location | Killed |
| --- | --- | --- |
| removed list kind interpolation `document.recibo? ? "Recibo" : "Nota fiscal"` | `app/views/supporting_documents/index.html.erb:53` | yes — `spec/requests/supporting_documents_spec.rb` `-e "POST recibo jpg persists Padaria Central Recibo and redirects"` exited 1 at `:89` (`expected ... to match` the time/amount/`Recibo`/payee cluster; PATCH select still rendered `Recibo` and did not satisfy `\s*`) |
| listed order `document_on/id` desc → asc | `app/models/supporting_document.rb:23` | yes — carried from `4f7d316` |
| skipped recibo photo-required guard | `app/models/supporting_document.rb:99-103` | yes — carried from `4f7d316` |
| skipped `xml.purge` when kind is recibo | `app/models/supporting_document.rb:133` | yes — carried from `4f7d316` |
| PATCH `find_by` unscoped to `SupportingDocument.find_by` | `app/controllers/supporting_documents_controller.rb:44` | yes — carried from `4f7d316` |

## Gate

`ruby bin/rspec spec/requests/supporting_documents_spec.rb spec/models/supporting_document_spec.rb spec/requests/organizations_spec.rb spec/requests/sessions_spec.rb spec/config/application_spec.rb` at HEAD `8297520` — 85 passed, 0 failed.
