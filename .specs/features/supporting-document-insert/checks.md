# Supporting document insert checks

Profile: standard
Plan: `.specs/features/supporting-document-insert/plan.md`

45 checks in 4 slices · 5 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.

## Checks

### S1 - Documents page

**C1** - Unauthenticated `GET /supporting_documents` responds `302` to `/login` (DOC-01, AC 1)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET /supporting_documents responds 302 to /login"`

**C2** - `GET /supporting_documents` with a session and no focused organization responds `302` to `/login` (DOC-01, AC 2)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents without focus responds 302 to /login"`

**C3** - Authenticated `GET /` includes a link whose text is `Documentos` and whose href is `/supporting_documents` (DOC-01, AC 3)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "organization home links Documentos to /supporting_documents"`

**C4** - Authenticated `GET /supporting_documents` responds `200`, uses locale `pt-BR`, and includes the heading `Documentos de suporte` (DOC-01, AC 4)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents responds 200 with pt-BR and Documentos de suporte"`

**C5** - `GET /supporting_documents` includes `Nenhum documento` when the focused organization has no SupportingDocument (DOC-01, AC 5)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents with no documents includes Nenhum documento"`

**C6** - `GET /supporting_documents` responds `200` when the focused organization has no Month (DOC-01, AC 6)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents with no Month responds 200"`

**C7** - `GET /supporting_documents` while focused on organization A does not include payee text that exists only on organization B’s supporting documents (DOC-01, AC 7)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "documents page does not include another organization payee"`

**C41** - Unauthenticated `GET /` responds `302` to `/login` (Surface `GET /`)
Proof: `bin/rspec spec/requests/sessions_spec.rb -e "unauthenticated GET / responds 302 to /login"`

### S2 - Recibo insert · door 1 · door 2 · door 3 · door 4 · door 5

**C8** - `POST /supporting_documents` with `kind=recibo`, amount `155,00`, date `2026-05-11`, payee `Padaria Central`, a `.jpg` photo, and no XML persists one SupportingDocument for the focused organization, responds `302` to `/supporting_documents`, and that page includes `11/05/2026`, `R$ 155,00`, `Padaria Central`, `Recibo`, and that photo’s original filename (DOC-02, AC 8, door 1, door 2, door 3)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo jpg persists Padaria Central Recibo and redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert recibo jpg persists one SupportingDocument for the organization"`

**C9** - That amount persists as integer cents `15500` (DOC-02, AC 9, door 3)
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert recibo amount_cents is Integer 15500"`

**C10** - A successful recibo insert attaches a photo blob through Active Storage, not through Drive, and has no XML blob (DOC-02, AC 10, door 4)
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert recibo attaches photo via Active Storage and no xml"`

**C11** - A successful insert belongs to the inserting Account and belongs to no Month (DOC-02, AC 11, door 1, door 5)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo belongs to inserting Account and creates no Month"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert recibo belongs to inserting Account and no Month"`

**C12** - `POST /supporting_documents` with `kind=recibo`, amount, date, and payee but no photo persists no SupportingDocument and responds `422` with `Envie a foto do recibo` (DOC-02, AC 12)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo without photo returns 422 Envie a foto do recibo"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects recibo without photo"`

**C13** - `POST /supporting_documents` with `kind=recibo`, a photo, and an XML file persists no SupportingDocument and responds `422` with `Recibo não tem XML` (DOC-02, AC 13)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo with xml returns 422 Recibo nao tem XML"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects recibo with xml"`

**C14** - Unauthenticated `POST /supporting_documents` persists no SupportingDocument and responds `302` to `/login` (DOC-02, AC 14)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated POST /supporting_documents responds 302 to /login"`

### S3 - Nota fiscal insert · door 2 · door 3 · door 4

**C15** - `POST /supporting_documents` with `kind=nota_fiscal`, amount `155,00`, date `2026-05-11`, payee `Padaria Central`, a `.jpg` photo, and no XML persists one SupportingDocument with a photo blob, no XML blob, responds `302` to `/supporting_documents`, and that page includes `Nota fiscal` and that photo’s original filename (DOC-03, AC 15, door 2)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal photo persists Nota fiscal and filename"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert nota_fiscal photo has photo and no xml"`

**C16** - `POST /supporting_documents` with `kind=nota_fiscal`, the same typed fields, an `.xml` file, and no photo persists one SupportingDocument with an XML blob, no photo blob, and `/supporting_documents` includes that XML’s original filename (DOC-03, AC 16, door 4)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal xml persists xml filename"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert nota_fiscal xml has xml and no photo"`

**C17** - `POST /supporting_documents` with `kind=nota_fiscal` with both a photo and an XML file persists one SupportingDocument that has both blobs (DOC-03, AC 17, door 4)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal photo and xml persists both blobs"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert nota_fiscal with photo and xml attaches both"`

**C18** - `POST /supporting_documents` with `kind=nota_fiscal`, amount, date, and payee but neither photo nor XML persists no SupportingDocument and responds `422` with `Envie a foto e/ou o XML` (DOC-03, AC 18)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal without files returns 422 Envie a foto e/ou o XML"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects nota_fiscal without photo and xml"`

**C19** - `POST /supporting_documents` with `kind=nota_fiscal`, typed amount `155,00`, and an XML file whose bytes include `<vNF>100.00</vNF>` persists amount cents `15500` (DOC-03, AC 19, door 3)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal xml vNF 100.00 persists amount 15500"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert ignores xml vNF and keeps typed 15500"`

### S4 - List, edit, isolation, bounds · door 2 · door 4

**C20** - After a document dated `2026-05-12` is posted after one dated `2026-05-11`, `GET /supporting_documents` includes `12/05/2026` before `11/05/2026` (DOC-04, AC 20)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents lists 12/05/2026 before 11/05/2026"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "lists by document date descending then id descending"`

**C21** - A second `POST /supporting_documents` with the same amount, date, and payee as an existing one persists both (DOC-04, AC 21, door 1)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST duplicate amount date payee persists both"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert duplicate amount date payee persists both"`

**C22** - `PATCH /supporting_documents/:id` with payee `Mercado Silva` on a SupportingDocument of the focused organization persists that payee, responds `302` to `/supporting_documents`, and that page includes `Mercado Silva` and does not include the previous payee (DOC-04, AC 22)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH payee to Mercado Silva redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "update payee to Mercado Silva"`

**C23** - `PATCH /supporting_documents/:id` of only payee, omitting files, leaves the photo and XML blobs in place (DOC-04, AC 23, door 4)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH payee omits files and keeps blobs"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "update payee keeps photo and xml blobs"`

**C24** - `PATCH /supporting_documents/:id` with a new photo on a document that already has a photo makes `/supporting_documents` include the new original filename and not the previous photo filename (DOC-04, AC 24)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH new photo replaces filename"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "update photo replaces the photo blob"`

**C25** - `POST /supporting_documents` with observation `pago em dinheiro` makes `/supporting_documents` include `pago em dinheiro` (DOC-04, AC 25, door 3)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST observation pago em dinheiro appears"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert with observation pago em dinheiro"`

**C26** - `POST /supporting_documents` with observation blank persists the SupportingDocument and `/supporting_documents` does not include `pago em dinheiro` (DOC-04, AC 26, door 3)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST blank observation persists without pago em dinheiro"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert blank observation stores none"`

**C27** - `POST /supporting_documents` with amount `0` or a blank amount persists no SupportingDocument and responds `422` with `Informe valor, data e favorecido` (DOC-04, AC 27)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST amount 0 returns 422 Informe valor, data e favorecido"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects amount 0 and blank amount"`

**C28** - `POST /supporting_documents` with a blank payee persists no SupportingDocument and responds `422` with `Informe valor, data e favorecido` (DOC-04, AC 28)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST blank payee returns 422 Informe valor, data e favorecido"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects blank payee"`

**C29** - `POST /supporting_documents` with a date that is not a calendar date persists no SupportingDocument and responds `422` with `Informe valor, data e favorecido` (DOC-04, AC 29)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST invalid date returns 422 Informe valor, data e favorecido"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects invalid date"`

**C30** - `POST /supporting_documents` with `kind` that is neither `nota_fiscal` nor `recibo` persists no SupportingDocument and responds `422` with `Informe se é nota fiscal ou recibo` (DOC-04, AC 30, door 2)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST kind other returns 422 Informe se e nota fiscal ou recibo"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects kind that is not nota_fiscal or recibo"`

**C31** - `POST /supporting_documents` with a photo or XML larger than `10485760` bytes persists no SupportingDocument and responds `422` with `Cada arquivo pode ter no máximo 10 MB` (DOC-04, AC 31)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST photo of 10485761 bytes returns 422 max 10 MB"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects photo or xml larger than 10485760 bytes"`

**C32** - `POST /supporting_documents` with a photo whose filename extension is `.heic` persists no SupportingDocument and responds `422` with `A foto deve ser JPEG, PNG, WebP ou PDF` (DOC-04, AC 32)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST photo .heic returns 422 A foto deve ser JPEG, PNG, WebP ou PDF"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects photo extension heic"`

**C33** - `POST /supporting_documents` with an XML whose filename extension is `.txt` persists no SupportingDocument and responds `422` with `O XML deve ser um arquivo .xml` (DOC-04, AC 33)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST xml .txt returns 422 O XML deve ser um arquivo .xml"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects xml extension txt"`

**C34** - `POST /supporting_documents` with a payee longer than 200 characters persists no SupportingDocument and responds `422` with `Favorecido pode ter no máximo 200 caracteres` (DOC-04, AC 34)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST payee of 201 characters returns 422 Favorecido pode ter no maximo 200 caracteres"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects payee longer than 200 characters"`

**C35** - `PATCH /supporting_documents/:id` of an id that belongs only to organization B, while focused on organization A, leaves organization B unchanged and responds `404` (DOC-04, AC 35)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH supporting_document of another organization returns 404"`

**C36** - `PATCH /supporting_documents/:id` with `kind=recibo` on a nota fiscal that has XML and no photo, without attaching a photo, leaves the document unchanged and responds `422` with `Envie a foto do recibo` (DOC-04, AC 36, door 2)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH kind recibo on xml-only nota_fiscal without photo returns 422 Envie a foto do recibo"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects kind recibo on xml-only without photo"`

**C37** - `PATCH /supporting_documents/:id` with `kind=recibo` together with a photo on a nota fiscal that had an XML blob leaves kind recibo, that photo, and no XML blob (DOC-04, AC 37, door 2, door 4)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH kind recibo with photo purges xml"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "update kind recibo with photo purges xml"`

**C38** - Two concurrent `POST /supporting_documents` that each insert a valid recibo persist two SupportingDocuments (DOC-04, AC 38)
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "concurrent recibo inserts persist two SupportingDocuments"`

**C39** - `DELETE /supporting_documents/:id` leaves the SupportingDocument in place and responds `404` (DOC-04, AC 39)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "DELETE /supporting_documents/:id returns 404 and keeps the row"`

**C40** - Unauthenticated `PATCH /supporting_documents/:id` leaves the SupportingDocument unchanged and responds `302` to `/login` (DOC-04, AC 40)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated PATCH /supporting_documents/:id responds 302 to /login"`

**C42** - `SupportingDocument.kind` enum members are `nota_fiscal` and `recibo` (door 2)
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "kind enum members are nota_fiscal and recibo"`

**C43** - `SupportingDocument` attaches files as `photo` and `xml` (door 4)
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "has_one_attached photo and xml"`

**C44** - The Rails app loads Active Storage; the test service is Disk with root `tmp/storage`; `config/storage.yml` defines no Drive service (door 4)
Proof: `bin/rspec spec/config/application_spec.rb -e "loads Active Storage Disk test service, skips Drive and Kamal"`

**C45** - Insert accepts photo filename extensions `.jpg`, `.jpeg`, `.png`, `.webp`, and `.pdf` (AC 32 accepted members)
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert accepts photo extensions jpg jpeg png webp pdf"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| `GET /` statuses (2) | 200 C3 · 302 C41 | - |
| `GET /supporting_documents` statuses (2) | 200 C4 · 302 C1 | - |
| `GET /supporting_documents` 302 reasons (2) | unauthenticated C1 · no focus C2 | - |
| `POST /supporting_documents` statuses (2) | 302 C8 · 422 C12 | - |
| `PATCH /supporting_documents/:id` statuses (3) | 302 C22 · 422 C36 · 404 C35 | - |
| `DELETE /supporting_documents/:id` statuses (1) | 404 C39 | - |
| kind enum (2) | `recibo` C8 · `nota_fiscal` C15 | - |
| recibo file rules (2) | no photo C12 · with XML C13 | - |
| nota fiscal files (4) | photo only C15 · XML only C16 · both C17 · neither C18 | - |
| POST 422 reasons (12) | recibo no photo C12 · recibo XML C13 · NF neither C18 · amount 0 C27 · blank amount C27 · blank payee C28 · invalid date C29 · bad kind C30 · oversized C31 · `.heic` C32 · `.txt` XML C33 · payee 201 C34 | - |
| amount rejects (2) | `0` C27 · blank C27, table-driven over 2 | - |
| oversized files (2) | photo C31 · xml C31, table-driven over 2 | - |
| photo extensions accepted (5) | C45, table-driven over all 5 | - |
| observation (2) | present C25 · blank C26 | - |
| Active Storage attachments (2) | `photo` C43 · `xml` C43 | - |
| Relations entities (3) | Organization C8 · SupportingDocument C8 · Account C11 | - |
| Landing doors (5) | no Month C11 · kind enum C42 · typed amount/date/payee C9 · Active Storage C44 · inserter C11 | - |
| startup config: Active Storage (1 assembly) | Rails test app C44 | - |

- Claims naming a status code, route or response shape: C1, C2, C3, C4, C6, C8, C12, C13, C14, C15, C18, C22, C27, C28, C29, C30, C31, C32, C33, C34, C35, C36, C39, C40, C41 - each has a proof that crosses the HTTP boundary
- No other check claims more than the single case its proof exercises, except C27 (amount `0` and blank), C31 (photo and xml oversize), and C45 (5 photo extensions), each table-driven over the whole set

## Test policy

`.cursor/rules/rails.mdc` already answers which level proves which code and how much of the input space counts. This build runs under those rows; they are not proposed as a new guideline commit.

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Decides, reached across a boundary | one at the boundary **and** one at its own layer | the contract at the boundary; one asserted case per row of the decision table at its own layer |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member |
| Entry point that decides nothing | one at the boundary | accepted input, each rejected input, each error path |
| Instrumentation, pass-throughs | none of its own | covered by its consumer's proof |

Evidence (classified from the approved plan):

- SupportingDocument insert: kind file rules (`recibo` photo required / XML forbidden; `nota_fiscal` photo and/or XML), typed amount/date/payee, observation, extensions, 10 MiB, opaque XML -> decides, reached across `POST /supporting_documents`
- SupportingDocument update: payee, omit-files keeps blobs, replace photo, `nota_fiscal`→`recibo` purges XML -> decides, reached across `PATCH /supporting_documents/:id`
- Kind enum two members plus reject other -> decides, own layer C42, C30
- List order date desc then id desc -> decides, reached across `GET /supporting_documents`
- Concurrent append of two recibos -> decides, not a uniqueness collision; own layer C38
- GET empty/unauth/no-focus and DELETE 404 -> entry / guard, boundary
- Active Storage service and attachment names: startup plus model declarations -> own layer C43, C44; blob presence after insert C10
- closest analogue in the repo: `spec/models/bank_statement_spec.rb` + `spec/requests/bank_statements_spec.rb` — persist, attachments, 10 MiB, extension, 422 at the HTTP boundary, concurrent write at own layer

Cost: dual proofs on insert accepts (C8, C11, C15–C17, C19, C21, C25, C26) and rejects (C12, C13, C18, C27–C34, C36) and on PATCH writes (C22–C24, C37). Without those own-layer proofs the kind file table and the opaque-XML rule would be proven only by a path that happens to traverse them.

## Swept

- validation: C27, C28, C29, C30, C31, C32, C33, C34
- failure modes: C12, C13, C18
- idempotency: C21, C38 - two identical inserts persist two rows; there is no dedup key
- authorization: C1, C2, C14, C35, C40
- concurrency: C38
- data lifecycle: C23, C24, C37, C39 - omit files keeps blobs; replace photo; kind change to recibo purges XML; DELETE does not destroy
- dependency failure: n/a - no SEFAZ or Drive in this cut; blobs are local Disk
- state transitions: C8, C15, C37 - kind `recibo` vs `nota_fiscal` at insert; `nota_fiscal`→`recibo` on PATCH
- observability: n/a - no logging or metrics criterion in the plan

## Handoff

- S1–S4 share `SupportingDocument` and `/supporting_documents`. Estimated ~12 product/spec files (model, migration, controller, index, home link, request spec, model spec, upload helper) ≪ 150k tokens. One builder, no split.
- S1-S4 = one builder
- **Boundary:** C1-C45 closed at `29de132`
- **Settled mid-build:** none
- **Abandoned:** none
