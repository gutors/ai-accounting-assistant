# Supporting-document insert deepen

Sources:

- `.tasks/supporting-document-insert-deepen.md` - this cut: criteria 1–10, doors, sweep, surface
- https://github.com/gutors/ai-accounting-assistant/issues/69 - deepen insert/apply in place; one OCR memo; pkcs12 from Organization; confirm stays sibling
- `.specs/features/supporting-document-insert/` - existing persist, blobs, 422 copy
- `.checks/nfe-photo-extraction.md`, `.checks/nfe-photo-ocr.md`, `.checks/sefaz-certificate-and-consulta.md` - origins, OCR Real, identified consulta, pending vs confirm
- [ADR-0004](../docs/adr/0004-sefaz-certificate-in-postgres.md) - A1 is a slot on organization
- `CONTEXT.md` - Supporting document, Nota fiscal, Recibo, Chave de acesso, SEFAZ consulta, SEFAZ certificate

No design source for the screens. Profile stays `standard`.

## Out of scope

- Changing operator-visible insert, apply, confirm, recibo, nota fiscal, chave, lock, pending, or 422 copy — already `.specs/features/supporting-document-insert/`, `.checks/nfe-photo-extraction.md`, `.checks/nfe-photo-ocr.md`, `.checks/sefaz-certificate-and-consulta.md`
- Folding `confirm_identified_sefaz` / `POST …/sefaz_confirm` / “Usar dados da SEFAZ” into the insert interface — grilling Q2
- A public PORO or DTO of field origin, a new file, or a nested type that tests call — grilling Q3, Q8
- A Fake/Real pair on `PhotoOcr`, eager OCR on every photo, or a process-global OCR cache — grilling Q4–Q7
- `has_one :sefaz_certificate` — ADR-0004
- `SupportingDocumentsController` growing past pass-through; withdraw; `return_to_no_month`; closed-month guards — existing
- Month page graph, Suggestion `Assigner`, administration session wizard, close-for-send / `MonthPackage` — other architecture candidates
- Specs that send messages to private cascade steps — grilling Q6
- New glossary terms — `CONTEXT.md` already names insert, supporting document, SEFAZ consulta, SEFAZ certificate
- Settling anything under the task `Unresolved` table — none; do not reopen

## Landing

Touches `SupportingDocument#submit` / `#apply` / `confirm_identified_sefaz` (persist stays on the record; internals stay private methods on that class) and `Organization` (pkcs12 or `nil`). Reuses `PhotoSymbols` / `PhotoFields` / `PhotoOcr` / `SefazConsulta.current.lookup` / `PublicNfceConsulta`. Controller stays pass-through. HTTP persist, 422 copy, and confirm route stay the values already proven.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Deepen in place | Persist (row lock, Active Storage, identified XML attach, pending flag) stays on `SupportingDocument`. Internals are private methods on that class. No public PORO or DTO of field origin. No new file. No nested type that tests call. | Extract a pipeline object tests construct; a DTO of field origin |
| OCR text is lazy-memoized per submit | At most one `PhotoOcr.text` per `insert` / `#apply` when printed-chave fallback or photo fields need that text. Memo lives in `#submit`, not on `PhotoOcr`. `PhotoSymbols::Real#scan` and `PhotoFields::Real#read` may take precomputed text; if it is absent they still OCR (existing adapter Real specs). Fakes still key on filename. `PhotoOcr` stays a process helper with no Fake/Real pair. | Eager OCR on every photo; a process-global cache on `PhotoOcr`; a Fake/Real `PhotoOcr` |
| Identified consulta pkcs12 seam | `SefazConsulta.current.lookup(pkcs12:, chave:)` stays the consulta port. `Organization` owns titular / expiry / wrap / unwrap and exposes pkcs12 or `nil`. Insert and confirm call that exposure; they do not copy the gate. A1 remains columns on `Organization`, not `has_one :sefaz_certificate`. | Duplicate titular/expiry/wrap on `SupportingDocument`; a certificate Active Record |
| Confirm stays a sibling | `confirm_identified_sefaz` / `POST …/sefaz_confirm` / “Usar dados da SEFAZ” are not part of the insert interface. Confirm reuses consulta + persist. It does not re-run PhotoSymbols, public NFC-e, or PhotoFields. | Fold confirm into `insert` / `#apply` |
| Precomputed OCR `text:` is a string or a zero-arg callable | `PhotoSymbols::Real#scan` and `PhotoFields::Real#read` take optional `text:`. A Proc is invoked only when that adapter would OCR (printed chave after QR/CODE-128 miss, or field reading). `#submit` memos with one lambda so the second adapter reuses the string. Absent `text:` still calls `PhotoOcr.text` (existing Real specs). Fakes accept and ignore `text:`. | OCR in `#submit` then pass a String — that runs Tesseract before QR/CODE-128 and fails C8 |
| Organization `sefaz_pkcs12` is the insert/confirm seam | `Organization#sefaz_pkcs12` returns `nil` when titular is blank, the certificate is expired, wrap is missing, or unwrap yields nothing; otherwise an `OpenSSL::PKCS12`. `unwrap_sefaz_pkcs12` stays decrypt-only so install specs can still open a stored slot. `SupportingDocument#consult_identified` calls `sefaz_pkcs12` and does not copy titular/expiry/wrap. | Fold the gate into `unwrap_sefaz_pkcs12` — install/replace proofs unwrap a just-stored pair and must not inherit insert skip rules |

- Nothing else in this change is hard to reverse. Proof surface (model `insert` / `#apply`, existing request specs, adapter Real `#scan` / `#read` / `#lookup` / `#fetch`; no private cascade examples) is the testing convention already in this repo.

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions):

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at the model layer **and** one request spec at HTTP | one asserted case per enumerated member at the model; status / who may call at the boundary | follow |
| Decides, not reached across a boundary | one at the model layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` lines 49–51 name the level and the sampling rule (one asserted case per enumerated member; HTTP also a request spec)
- `spec/models/supporting_document_spec.rb` + `spec/requests/supporting_documents_spec.rb` — insert/apply/confirm persist is the pipeline this cut deepens; C1–C6 and C10 name `insert` / `#apply` / `confirm_identified_sefaz`, not a status or route, so proofs sit at the model. HTTP status / who may call / 422 copy stay existing request specs (out of scope to change)
- `spec/models/organization_spec.rb` — A1 slot and unwrap; C9’s nil/PKCS12 table belongs here, not copied on `SupportingDocument`
- `spec/models/photo_symbols_spec.rb` + `spec/models/photo_fields_spec.rb` — Real `#scan` / `#read` still OCR when text is absent; C7–C8 prove the memo at `insert` with those Reals, not a Fake/Real `PhotoOcr`
- SupportingDocumentsController stays pass-through; this cut adds no HTTP claim

Cost: model specs for persist origins (C1–C6), OCR call count (C7–C8), Organization pkcs12 exposure plus lookup skip/pass (C9), confirm without photo/NFC-e/photo-fields (C10). No new request specs.

## Checks

### S1 - Persist through insert and apply · 2 files · 67 KB · ~17k

**C1** - When `SupportingDocument.insert` is called with `kind=recibo`, amount `155,00`, date `2026-05-11`, payee `Padaria Central`, a `.jpg` photo, and no XML, then one SupportingDocument persists for that organization with `amount_cents` Integer `15500`, `fields_origin` `typed`, that photo blob, no XML blob, and `chave` `nil`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert recibo jpg persists 15500 typed photo no xml chave nil"`

**C2** - When `SupportingDocument.insert` is called with `kind=nota_fiscal`, an authorized XML whose `vNF` is `155.00`, emitente `Padaria Central`, `dhEmi` `2026-05-11`, chave `43260511222333000181550010000000011123456781`, and no photo, then the document persists `amount_cents` `15500`, `document_on` `2026-05-11`, `payee` `Padaria Central`, that chave, `fields_origin` `uploaded_xml`, the XML blob, and a later `#apply` of amount `200,00` adds `Valor, data e favorecido vêm da nota e não podem ser alterados` and leaves `15500`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert authorized XML persists 15500 uploaded_xml blob and apply 200,00 keeps 15500"`

**C3** - Given a valid A1 and identified consulta for chave `43260511222333000181550010000000011123456781` returning authorized XML with `vNF` `155.00`, emitente `Padaria Central`, `dhEmi` `2026-05-11`, when `insert` is called with `kind=nota_fiscal`, a `.jpg` photo whose symbols scan returns that chave, and no typed amount, date, payee, XML, or chave, then the document persists `amount_cents` `15500`, that chave, `fields_origin` `identified`, that XML attached, and `sefaz_confirm_pending` `false`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert photo chave with consulta XML persists 15500 identified xml not pending"`

**C4** - Given a persisted unlocked typed nota fiscal of `amount_cents` `15500` and a valid A1 whose consulta for that chave would return `vNF` `100.00`, when `#apply` is called with that chave, then `amount_cents` stays `15500`, `sefaz_confirm_pending` is `true`, and `fields_origin` is not `identified`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply chave on typed nota keeps 15500 pending not identified"`

**C5** - Given identified consulta does not deliver and public NFC-e does not deliver, when `insert` is called with `kind=nota_fiscal`, a `.jpg` whose field read returns `amount_cents` `15500`, `document_on` `2026-05-11`, payee `Padaria Central`, and no typed triple, then the document persists those three, `fields_origin` `photo`, and a later `#apply` of payee `Mercado Silva` persists that payee
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert photo field reading persists 15500 origin photo"`

**C6** - Given identified consulta does not deliver, when `insert` is called with `kind=nota_fiscal`, a `.jpg` whose symbols scan returns an NFC-e QR URL whose public consulta returns `amount_cents` `15500`, `document_on` `2026-05-11`, payee `Padaria Central`, and no typed triple, then the document persists those three, `fields_origin` `nfc_e_public`, no XML blob, and a later `#apply` of amount `200,00` persists `20000`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFC-e QR public consulta persists 15500 origin nfc_e_public"`

### S2 - OCR memo, pkcs12 seam, confirm sibling · 9 files · 116 KB · ~29k

**C7** - Given `PhotoSymbols::Real` and `PhotoFields::Real`, a PNG or JPEG with no QR and no CODE-128, identified consulta does not deliver, and public NFC-e does not deliver, when `insert` or `#apply` runs for `kind=nota_fiscal` with that photo and OCR text is needed for printed chave or photo fields, then `PhotoOcr.text` is invoked at most once for that submit
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert Real photo OCR text is invoked at most once"`

**C8** - Given a JPEG whose QR decode yields chave `43260511222333000181650010000000011123456781` and identified consulta delivers authorized XML for that chave, when `insert` runs for `kind=nota_fiscal` with that photo and no typed triple, then `PhotoOcr.text` is not invoked
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert Real QR identified XML does not invoke PhotoOcr text"`

**C9** - When the organization’s pkcs12 exposure returns `nil` (no titular, expired certificate, or unwrap miss), then `insert`, `#apply`, and `confirm_identified_sefaz` do not call `SefazConsulta.current.lookup`; a `kind=nota_fiscal` insert with that chave, a photo, and typed `155,00` / `2026-05-11` / `Padaria Central` still persists `amount_cents` `15500` and a later `#apply` of payee `Mercado Silva` persists that payee. When that exposure returns an `OpenSSL::PKCS12`, `lookup` is called with that object and the 44-digit chave
Proof: `bin/rspec spec/models/organization_spec.rb -e "sefaz pkcs12 exposure is nil without titular"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "sefaz pkcs12 exposure is nil when expired"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "sefaz pkcs12 exposure is nil on unwrap miss"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "sefaz pkcs12 exposure returns PKCS12 for a valid A1"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert apply confirm skip lookup when pkcs12 is nil and persist 15500"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert lookup receives PKCS12 and 44-digit chave"`

**C10** - Given a persisted unlocked nota fiscal with `sefaz_confirm_pending` `true` and chave `43260511222333000181550010000000011123456781`, when `confirm_identified_sefaz` runs and identified consulta returns XML with `vNF` `100.00`, then the document persists `amount_cents` `10000`, `fields_origin` `identified`, `sefaz_confirm_pending` `false`, and that submit does not call `PhotoSymbols.current.scan`, `PhotoFields.current.read`, or `PublicNfceConsulta.current.fetch`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "confirm identified SEFAZ persists 10000 identified without photo pipeline"`

## Swept

- validation: existing - kind, files, 10 MiB, extensions, 44-digit chave, missing triple; this cut does not add a validator
- failure modes: existing - unreadable XML `422`; consulta Error / NotFound / WindowExpired fall through; Tesseract miss is empty text then existing Real miss
- idempotency and retry: existing - two inserts with the same amount, date, and payee persist two rows; there is no dedup key
- authorization: existing - focused Access; submitter still never sees the certificate
- concurrency and ordering: existing - two concurrent recibo inserts persist two rows; the OCR memo is per submit on one document instance, not a shared slot
- data lifecycle: existing - photo and XML stay Active Storage on SupportingDocument; persist stays inside `persist_document`; no backfill of existing photos
- external-dependency failure: existing - Tesseract missing or non-zero is empty text; identified timeout / PKCS12 error is `SefazConsulta::Error`; C9 is skip lookup when pkcs12 is `nil`, not a new error payload
- state transitions: C3, C4, C10 - first insert or recibo→nota still applies consulta; apply chave on an existing unlocked nota_fiscal still sets pending; confirm still moves pending to identified without re-running PhotoSymbols / NFC-e / PhotoFields
- observability: existing - `filter_parameters` already covers certificate/passphrase; no new operator metric or log field

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| persist `fields_origin` this cut names (5) | `typed` C1 · `uploaded_xml` C2 · `identified` C3, C10 · `photo` C5 · `nfc_e_public` C6 | - |
| apply-chave pending vs identified (1) | pending and not `identified` C4 | - |
| OCR invocations on Real submit (2) | needed: at most once C7 · QR+identified: zero C8 | - |
| pkcs12 exposure nil (3) | no titular C9 · expired C9 · unwrap miss C9 | - |
| pkcs12 exposure PKCS12 (1) | valid A1 C9 | - |
| skip `lookup` when nil (3) | `insert` C9 · `#apply` C9 · `confirm_identified_sefaz` C9 | - |
| `lookup` args when PKCS12 (2) | `OpenSSL::PKCS12` object C9 · 44-digit chave C9 | - |
| confirm does not re-run (3) | `PhotoSymbols.current.scan` C10 · `PhotoFields.current.read` C10 · `PublicNfceConsulta.current.fetch` C10 | - |
| startup config assemblies | no new process setting; `PhotoSymbols` / `PhotoFields` / `SefazConsulta` `current` / `Fake` / `Real` already share one module each | - |

- Claims naming a status code, route or response shape: none - C1–C10 are `insert` / `#apply` / `confirm_identified_sefaz` / Organization pkcs12 / `PhotoOcr.text`
- No other check claims more than the single case its proof exercises

## Handoff

S1 = `app/models/supporting_document.rb` + `spec/models/supporting_document_spec.rb` = 66804 bytes ≈ 17k tokens. S2 adds `photo_symbols.rb`, `photo_fields.rb`, `photo_ocr.rb`, `organization.rb`, and their specs (116151 bytes ≈ 29k including the shared SupportingDocument files). S1+S2 stay under 150k. Surface changes at S2 (Real OCR memo + Organization pkcs12), but the running total never reaches the budget, so both slices are one batch.
