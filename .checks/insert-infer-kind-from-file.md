# Insert infer kind from file

Profile: `standard`. No design source. Not raised to `ui`.

Sources:

- `.tasks/insert-infer-kind-from-file.md` - criteria 1–12, door 1, sweep, surface, Unresolved 1 (HTML 422 after infer still echoes posted empty kind). Nothing under Unresolved is settled while building
- Chat 2026-10-15 - infer on POST; `submit_blank_only`; **Incluir foto** is the file chip; submit is **Incluir documento**
- Cursor plan `ocr_e_tipo_documento` - POST-only; XML → NF; symbols chave/QR → NF; else photo → recibo; no recibo field OCR
- `.tasks/documents-list-mask-and-actions.md` criterion 25 - **this cut supersedes** empty `kind` + photo → `BAD_KIND`; empty `kind` with no file stays C6
- `.tasks/nfe-photo-extraction.md` - NF pipeline, recibo unread, Fake `PhotoSymbols` / `PhotoFields` on submit proofs
- `.tasks/nfe-photo-ocr.md` - Tesseract in-process; PNG/JPEG; recibo photos unread
- `.tasks/keep-form-on-422.md` - 422 echoes posted `kind`
- `GLOSSARY.md` / `CONTEXT.md` - Nota fiscal, Recibo, Supporting document; image PDF counts as a photo

No design source. Unresolved 1 stays open (does not block).

## Out of scope

- Filling Tipo or amount/date/payee when the **Incluir foto** chip chooses a file, before **Incluir documento** - user: infer on POST; no preview endpoint
- Reading a recibo photo for amount, date, or payee - #51 C7 / C31; nfe-photo-ocr; user: fields as today
- Overwriting a posted `nota_fiscal` or `recibo` from the file - user: `submit_blank_only`
- PDF/WebP Real decode - PhotoOcr / PhotoSymbols::Real already miss; a miss with empty kind is recibo (C2)
- PATCH inferring kind from a newly attached photo - kind is locked on persist (`KIND_LOCKED`); infer runs only on insert when posted kind is blank
- Cloud OCR / vision APIs - #51 Decided 2
- Changing GET insert chrome (empty Tipo, Recibo hides chave/XML) - documents-list-mask-and-actions 23–24
- HTML 422 selecting the inferred Tipo after a later `MISSING_FIELDS` - Unresolved 1; echo posted `kind`

## Landing

Touches `SupportingDocument#submit` / `.insert` (blank posted `kind` on insert is classified from XML or one `PhotoSymbols` scan, then the existing NF vs recibo pipeline). Reuses `PhotoSymbols.current` Fake/Real, `PhotoFields`, identified/public fill, `BAD_KIND` copy, and `SupportingDocumentsController#create` pass-through. No schema change. GET insert chrome unchanged.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Empty insert kind is classified from the file using existing ports, then the existing submit pipeline | On `POST /supporting_documents` (`SupportingDocument.insert` / `#submit`): if posted `kind` is `nota_fiscal` or `recibo`, use it. If posted `kind` is non-blank and not those two, `BAD_KIND` (do not infer). Else on insert: if an XML file is uploaded, `nota_fiscal`. Else if a photo is uploaded, run `PhotoSymbols.current.scan` once on those bytes (same Fake/Real as #51); `nota_fiscal` when `chave` is 44 digits or `qr_url` is present, otherwise `recibo`. Else `BAD_KIND`. Infer does not run on a persisted row. NF field fill stays identified → public → `PhotoFields` → typed. Recibo stays typed. Photo bytes stay in-process. | Live preview when **Incluir foto** fires — user chose POST. Override posted kind — user `submit_blank_only`. Infer garbage `kind` (`invoice`) — C9 / sweep. Infer on PATCH — `KIND_LOCKED`. Treat `PhotoFields` complete triple or `EMITENTE` as an NF signal — would classify a recibo with `R$` as NF once a later recibo parser exists. Filename heuristics (`danfe.jpg`) — not a document fact. A second scan after classify — door says one scan per insert. |

- Nothing else in this change is hard to reverse. Where scan is called in `#submit` is placement. Door 1 reaches past this feature: a later “detect more kinds” copies XML-or-PhotoSymbols-then-default-recibo, not a cloud classifier and not overwriting a posted kind.

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

These rows are the bar I build under — approving the checklist is enough for that. Writing them into `.cursor/rules/rails.mdc` needs an explicit yes, and it lands as its own commit before the build. Without one I build under them and leave the file alone.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at the model layer **and** one request spec at HTTP | one asserted case per enumerated member at the model; status / who may call at the boundary | follow |
| Decides, not reached across a boundary | one at the model layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` names the level and the sampling rule: a decision is proven at its own layer, one asserted case per enumerated member; HTTP also gets a request spec
- `SupportingDocument#submit` gains blank-kind classify (XML / PhotoSymbols chave / qr_url / miss / no file / garbage posted kind / posted kind kept). Closest analogue: existing Recibo XML / MISSING_FIELDS / BAD_KIND / photo-chave cases in `spec/models/supporting_document_spec.rb` plus matching request examples
- `SupportingDocumentsController#create` stays pass-through: `insert` → `302` or `422`
- C12 (`scan` invoked) is a call-order claim at the model; it is not an HTTP contract

Cost: request + model examples for C1–C11; model example for C12. Without the model table, a controller that hardcoded `nota_fiscal` on any photo would still look green at HTTP for C1 only.

## Checks

Criteria 1–12 map to C1–C12.

### S1 - Infer kind when insert Tipo is empty · 3 files · 204 KB · ~51k

**C1** - Given `PhotoSymbols` for filename `recibo.jpg` returns chave `43260511222333000181550010000000011123456781` and `qr_url` `nil`, when a coordinator POSTs `/supporting_documents` with `kind` empty, that JPEG photo, amount `155,00`, date `2026-05-11`, payee `Padaria Central`, and no XML, then one SupportingDocument persists with kind `nota_fiscal` and that chave, the status is `302` to `/supporting_documents`, and that GET’s row `[data-cell=kind]` is `Nota fiscal`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST empty kind photo chave infers Nota fiscal"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert empty kind photo chave persists nota_fiscal"`

**C2** - Given `PhotoSymbols` for that filename returns `chave` `nil` and `qr_url` `nil`, when that same POST runs (empty kind, JPEG photo, those three typed fields, no XML), then one SupportingDocument persists with kind `recibo` and `chave` `nil`, no XML blob, the status is `302`, and that GET’s row `[data-cell=kind]` is `Recibo`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST empty kind photo miss infers Recibo"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert empty kind photo miss persists recibo"`

**C3** - When a coordinator POSTs empty `kind`, authorized XML of chave `43260511222333000181550010000000011123456781` `vNF` `155.00` emitente `Padaria Central` `dhEmi` `2026-05-11T10:00:00-03:00`, and no photo, then one SupportingDocument persists with kind `nota_fiscal`, that chave, `amount_cents` `15500`, `fields_origin` `uploaded_xml`, and the status is `302`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST empty kind XML infers nota_fiscal uploaded_xml"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert empty kind XML persists nota_fiscal uploaded_xml"`

**C4** - When a coordinator POSTs empty `kind`, that authorized XML, and a JPEG whose `PhotoSymbols` chave is `43260511222333000181550010000000021987654321`, then the persisted chave is `43260511222333000181550010000000011123456781` (XML), kind is `nota_fiscal`, and the status is `302`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST empty kind XML chave wins over photo chave"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert empty kind XML chave wins over photo chave"`

**C5** - Given `PhotoSymbols` for filename `recibo.jpg` returns `qr_url` `https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=43260511222333000181650010000000011123456781|2|1|1` and chave `43260511222333000181650010000000011123456781`, when a coordinator POSTs empty `kind`, that JPEG, those three typed fields, and no XML, then the persisted kind is `nota_fiscal` and chave is that 44-digit value.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST empty kind photo QR infers nota_fiscal"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert empty kind photo QR persists nota_fiscal"`

**C6** - When a coordinator POSTs empty `kind`, amount `155,00`, date `2026-05-11`, payee `Padaria Central`, and neither photo nor XML, then no SupportingDocument is persisted, the status is `422`, and `[data-notice="error"]` and `[data-toast-kind="error"]` are `Informe se é nota fiscal ou recibo`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST empty kind without file returns 422 Informe se e nota fiscal ou recibo"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert empty kind without file is BAD_KIND"`

### S2 - Posted Tipo is kept · 3 files · 204 KB · ~51k (same files as S1)

**C7** - When a coordinator POSTs `kind=recibo`, a JPEG whose `PhotoSymbols` would return chave `43260511222333000181550010000000011123456781`, and typed `155,00` / `2026-05-11` / `Padaria Central`, then the persisted kind is `recibo`, `chave` is `nil`, and no XML is attached.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST kind recibo keeps recibo when photo has chave"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert kind recibo keeps recibo when photo has chave"`

**C8** - Given `PhotoSymbols` for the photo filename returns `chave` `nil` and `qr_url` `nil`, when a coordinator POSTs `kind=nota_fiscal`, that JPEG, and those three typed fields, then the persisted kind is `nota_fiscal` (not `recibo`).
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST kind nota_fiscal keeps nota_fiscal on photo miss"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert kind nota_fiscal keeps nota_fiscal on photo miss"`

**C9** - When a coordinator POSTs `kind=invoice`, a JPEG photo, and those three typed fields, then no SupportingDocument is persisted, the status is `422`, and the notice and error toast are `Informe se é nota fiscal ou recibo`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST kind invoice with photo returns 422 Informe se e nota fiscal ou recibo"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert kind invoice with photo is BAD_KIND"`

### S3 - Fields follow existing NF vs recibo paths · 3 files · 204 KB · ~51k (same files as S1)

**C10** - Given `PhotoSymbols` for filename `recibo.jpg` returns that 44-digit chave and `qr_url` `nil`, the organization has no certificate, and `PhotoFields` for that filename returns `amount_cents` `15500`, `document_on` `2026-05-11`, payee `Padaria Central`, when a coordinator POSTs empty `kind`, that JPEG, no XML, and no typed amount, date, or payee that complete the triple, then the row persists those three values, `fields_origin` `photo`, kind `nota_fiscal`, and a later PATCH of payee `Mercado Silva` responds `302`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST empty kind photo fields origin photo then PATCH payee redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert empty kind photo fields origin photo stays correctable"`

**C11** - Given `PhotoSymbols` miss (`chave` `nil`, `qr_url` `nil`) and `PhotoFields` for that filename would return payee `Mercado Silva`, when a coordinator POSTs empty `kind`, that JPEG, and typed `155,00` / `2026-05-11` / `Padaria Central`, then the persisted `payee` is `Padaria Central` and `fields_origin` is `typed`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST empty kind photo miss keeps typed payee"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert empty kind photo miss keeps typed payee"`

**C12** - When `SupportingDocument.insert` runs with empty kind and a JPEG photo, then `PhotoSymbols.current#scan` is invoked with that photo’s bytes before persist or `BAD_KIND`.
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert empty kind photo scans PhotoSymbols before persist"`

## Swept

- validation: C6, C9 - empty kind without a file, and `kind` that is not `nota_fiscal` or `recibo`, stay `BAD_KIND`; file type and size stay existing `PHOTO_TYPE` / `OVERSIZE` / `XML_UNREADABLE`
- failure modes: C2, C11 - `PhotoSymbols` miss with empty kind is recibo and typed fields, not `BAD_KIND`; `PhotoFields` is not used on that path
- idempotency and retry: existing - a retried POST creates a second SupportingDocument (#51 C44); no unique chave
- authorization: existing - `SupportingDocumentsController` focused organization; submitter insert unchanged
- concurrency and ordering: n/a - two in-flight inserts do not share a slot; each POST is its own row
- data lifecycle: n/a - no backfill of stored photos; existing rows keep their `kind`; nothing to migrate
- external-dependency failure: C2, C12 - Tesseract / decode miss is empty `PhotoSymbols`, which lands as recibo when kind was empty; identified / public miss stay the existing NF pipeline after kind is `nota_fiscal` (C10)
- state transitions: C1, C2, C3, C7, C8 - empty posted kind becomes persisted `nota_fiscal` or `recibo`; posted kind does not change
- observability: existing - no new log of OCR text or photo bytes; `filter_parameters` unchanged

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| blank-kind classify (5) | empty+XML `nota_fiscal` C3 · empty+photo 44-digit chave C1 · empty+photo `qr_url` C5 · empty+photo miss `recibo` C2 · empty no file `BAD_KIND` C6 | - |
| posted kind kept (3) | `recibo` C7 · `nota_fiscal` C8 · garbage `invoice` `BAD_KIND` C9 | - |
| XML vs photo chave when kind empty (1) | XML chave wins C4 | - |
| field path after infer (3) | NF `PhotoFields` `photo` C10 · recibo typed ignores `PhotoFields` C11 · scan before persist/`BAD_KIND` C12 | - |
| startup config assemblies | no new process setting; `PhotoSymbols` / `PhotoFields` `current` / `Fake` / `Real` already share one module each | - |

- Claims naming a status code, route or response shape: C1, C2, C3, C4, C6, C7, C8, C9, C10, C11 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~51k + S2 ~51k + S3 ~51k if the 131 KB request spec and 58 KB model spec are counted in every slice they touch. Unique files on this cut (`supporting_document.rb`, both specs, the task) ≈ 204 KB / 4 ≈ 51k. Running total stays under 150k and the surface stays `SupportingDocument#submit` plus the supporting-documents HTTP insert. No split. One batch.

- Where the boundary fell: not yet — extract only.
- What the user settled mid-build: none.
- What was abandoned: none.
