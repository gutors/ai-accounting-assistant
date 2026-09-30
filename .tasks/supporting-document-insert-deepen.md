# Deepen supporting-document insert

> Build this with **tlc-implement**. Profile **standard** — no binding screen.
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

`SupportingDocument#submit` already runs PhotoSymbols then PhotoFields on a nota fiscal photo. `PhotoSymbols::Real` calls `PhotoOcr.text` when QR and CODE-128 miss; `PhotoFields::Real` calls `PhotoOcr.text` again when identified consulta and public NFC-e miss. That pair is two Tesseract processes on one insert. `consult_identified` copies titular / expiry / wrap checks that `Organization` already owns, then unwraps. The operator waits on the extra OCR; the next consulta caller can copy the duplicated gate. The grilling note gives no conversion figure.

When this ships, operator-visible insert, apply, confirm, recibo, nota fiscal, chave, lock, and pending stay the values already proven. Recibo and nota fiscal still write only through `SupportingDocument.insert` / `#apply`. Confirm stays `confirm_identified_sefaz` / `POST …/sefaz_confirm`. Internally, `#submit` memos OCR text at most once when printed chave or photo fields need it; insert and confirm take `pkcs12` or `nil` from the organization and do not copy that gate.

10 criteria in 2 slices · 3 one-way doors · 0 open, of which 0 block

## Criteria

### Persist through insert and apply

1. When `SupportingDocument.insert` is called with `kind=recibo`, amount `155,00`, date `2026-05-11`, payee `Padaria Central`, a `.jpg` photo, and no XML, then one SupportingDocument persists for that organization with `amount_cents` Integer `15500`, `fields_origin` `typed`, that photo blob, no XML blob, and `chave` `nil`.
2. When `SupportingDocument.insert` is called with `kind=nota_fiscal`, an authorized XML whose `vNF` is `155.00`, emitente `Padaria Central`, `dhEmi` `2026-05-11`, chave `43260511222333000181550010000000011123456781`, and no photo, then the document persists `amount_cents` `15500`, `document_on` `2026-05-11`, `payee` `Padaria Central`, that chave, `fields_origin` `uploaded_xml`, the XML blob, and a later `#apply` of amount `200,00` adds `Valor, data e favorecido vêm da nota e não podem ser alterados` and leaves `15500`.
3. Given a valid A1 and identified consulta for chave `43260511222333000181550010000000011123456781` returning authorized XML with `vNF` `155.00`, emitente `Padaria Central`, `dhEmi` `2026-05-11`, when `insert` is called with `kind=nota_fiscal`, a `.jpg` photo whose symbols scan returns that chave, and no typed amount, date, payee, XML, or chave, then the document persists `amount_cents` `15500`, that chave, `fields_origin` `identified`, that XML attached, and `sefaz_confirm_pending` `false`.
4. Given a persisted unlocked typed nota fiscal of `amount_cents` `15500` and a valid A1 whose consulta for that chave would return `vNF` `100.00`, when `#apply` is called with that chave, then `amount_cents` stays `15500`, `sefaz_confirm_pending` is `true`, and `fields_origin` is not `identified`.
5. Given identified consulta does not deliver and public NFC-e does not deliver, when `insert` is called with `kind=nota_fiscal`, a `.jpg` whose field read returns `amount_cents` `15500`, `document_on` `2026-05-11`, payee `Padaria Central`, and no typed triple, then the document persists those three, `fields_origin` `photo`, and a later `#apply` of payee `Mercado Silva` persists that payee.
6. Given identified consulta does not deliver, when `insert` is called with `kind=nota_fiscal`, a `.jpg` whose symbols scan returns an NFC-e QR URL whose public consulta returns `amount_cents` `15500`, `document_on` `2026-05-11`, payee `Padaria Central`, and no typed triple, then the document persists those three, `fields_origin` `nfc_e_public`, no XML blob, and a later `#apply` of amount `200,00` persists `20000`.

### OCR memo, pkcs12 seam, confirm sibling

7. Given `PhotoSymbols::Real` and `PhotoFields::Real`, a PNG or JPEG with no QR and no CODE-128, identified consulta does not deliver, and public NFC-e does not deliver, when `insert` or `#apply` runs for `kind=nota_fiscal` with that photo and OCR text is needed for printed chave or photo fields, then `PhotoOcr.text` is invoked at most once for that submit.
8. Given a JPEG whose QR decode yields chave `43260511222333000181650010000000011123456781` and identified consulta delivers authorized XML for that chave, when `insert` runs for `kind=nota_fiscal` with that photo and no typed triple, then `PhotoOcr.text` is not invoked.
9. When the organization’s pkcs12 exposure returns `nil` (no titular, expired certificate, or unwrap miss), then `insert`, `#apply`, and `confirm_identified_sefaz` do not call `SefazConsulta.current.lookup`; a `kind=nota_fiscal` insert with that chave, a photo, and typed `155,00` / `2026-05-11` / `Padaria Central` still persists `amount_cents` `15500` and a later `#apply` of payee `Mercado Silva` persists that payee. When that exposure returns an `OpenSSL::PKCS12`, `lookup` is called with that object and the 44-digit chave.
10. Given a persisted unlocked nota fiscal with `sefaz_confirm_pending` `true` and chave `43260511222333000181550010000000011123456781`, when `confirm_identified_sefaz` runs and identified consulta returns XML with `vNF` `100.00`, then the document persists `amount_cents` `10000`, `fields_origin` `identified`, `sefaz_confirm_pending` `false`, and that submit does not call `PhotoSymbols.current.scan`, `PhotoFields.current.read`, or `PublicNfceConsulta.current.fetch`.

## Out of scope

- Changing operator-visible insert, apply, confirm, recibo, nota fiscal, chave, lock, pending, or 422 copy — already `.specs/features/supporting-document-insert/`, `.checks/nfe-photo-extraction.md`, `.checks/nfe-photo-ocr.md`, `.checks/sefaz-certificate-and-consulta.md`
- Folding `confirm_identified_sefaz` / `POST …/sefaz_confirm` / “Usar dados da SEFAZ” into the insert interface — grilling Q2
- A public PORO or DTO of field origin, a new file, or a nested type that tests call — grilling Q3, Q8
- A Fake/Real pair on `PhotoOcr`, eager OCR on every photo, or a process-global OCR cache — grilling Q4–Q7
- `has_one :sefaz_certificate` — [ADR-0004](../docs/adr/0004-sefaz-certificate-in-postgres.md)
- `SupportingDocumentsController` growing past pass-through; withdraw; `return_to_no_month`; closed-month guards — existing
- Month page graph, Suggestion `Assigner`, administration session wizard, close-for-send / `MonthPackage` — other architecture candidates
- Specs that send messages to private cascade steps — grilling Q6
- New glossary terms — `CONTEXT.md` already names insert, supporting document, SEFAZ consulta, SEFAZ certificate

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `/supporting_documents` | empty state | existing - `Nenhum documento` when the focused organization has no SupportingDocument |
| screen `/supporting_documents` | loading | n/a - Turbo full-page / redirect; this cut adds no progress state |
| screen `/supporting_documents` | error state | existing - `422` base copy (`Informe valor, data e favorecido`, `Informe a chave de acesso com 44 dígitos`, `Valor, data e favorecido vêm da nota e não podem ser alterados`, `Mês fechado`) |
| screen `/supporting_documents` | unauthorised | existing - unauthenticated `302` `/login`; other-organization `404` |
| screen `/supporting_documents` | density and ordering | existing - date descending then id; no origin badge |
| screen `/supporting_documents` | destructive action confirms | existing - withdraw still Turbo-confirms |
| HTML `POST /supporting_documents` | who may call it | existing - focused Access |
| HTML `POST /supporting_documents` | response / error shape and codes | existing - `302` `/supporting_documents` or `422` with the first base error; 1–6 are the same persist |
| HTML `POST /supporting_documents` | versioning | n/a - existing HTML form; no new resource |
| HTML `POST /supporting_documents` | rate limit | n/a - small operator set |
| HTML `PATCH /supporting_documents/:id` | who / error / versioning / rate limit | existing - `#apply`; 4 is pending vs apply-consulta-immediately |
| HTML `POST /supporting_documents/:id/sefaz_confirm` | who / error shape | existing - sibling confirm; 10 is consulta + persist without photo/NFC-e/photo-fields |
| command or scheduled task | flags, exit codes, halfway failure | n/a - no CLI or job |
| document or copy | structure, tone, next step | n/a - no new user-facing copy |
| collection supporting documents | grouping, naming, ordering, duplicates, exception | existing - two identical inserts still persist two rows |

## Swept

- validation: existing - kind, files, 10 MiB, extensions, 44-digit chave, missing triple; this cut does not add a validator
- failure modes: existing - unreadable XML `422`; consulta Error / NotFound / WindowExpired fall through; Tesseract miss is empty text then existing Real miss
- idempotency and retry: existing - two inserts with the same amount, date, and payee persist two rows; there is no dedup key
- authorization: existing - focused Access; submitter still never sees the certificate
- concurrency and ordering: existing - two concurrent recibo inserts persist two rows; the OCR memo is per submit on one document instance, not a shared slot
- data lifecycle: existing - photo and XML stay Active Storage on SupportingDocument; persist stays inside `persist_document`; no backfill of existing photos
- external-dependency failure: existing - Tesseract missing or non-zero is empty text; identified timeout / PKCS12 error is `SefazConsulta::Error`; 9 is skip lookup when pkcs12 is `nil`, not a new error payload
- state transitions: 3, 4, 10 - first insert or recibo→nota still applies consulta; apply chave on an existing unlocked nota_fiscal still sets pending; confirm still moves pending to identified without re-running PhotoSymbols / NFC-e / PhotoFields
- observability: existing - `filter_parameters` already covers certificate/passphrase; no new operator metric or log field

## Impact

| Front | What changes |
|---|---|
| domain | existing term: `Supporting document` - `insert` / `#apply` remain the write interface for recibo and nota fiscal; persist (row, blobs, pending) stays on the record. Callers: `SupportingDocumentsController#create` / `#update` |
| domain | existing term: `SEFAZ certificate` - still one A1 slot on `Organization` (ADR-0004). Insert and confirm consume `pkcs12` or `nil` from that organization; they must not copy titular / expiry / wrap. Callers today: `SupportingDocument#consult_identified` (insert and confirm) |
| stored data | nothing to migrate |

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| Deepen in place | Persist (row lock, Active Storage, identified XML attach, pending flag) stays on `SupportingDocument`. Internals are private methods on that class. No public PORO or DTO of field origin. No new file. No nested type that tests call. | Extract a pipeline object tests construct; a DTO of field origin |
| OCR text is lazy-memoized per submit | At most one `PhotoOcr.text` per `insert` / `#apply` when printed-chave fallback or photo fields need that text. Memo lives in `#submit`, not on `PhotoOcr`. `PhotoSymbols::Real#scan` and `PhotoFields::Real#read` may take precomputed text; if it is absent they still OCR (existing adapter Real specs). Fakes still key on filename. `PhotoOcr` stays a process helper with no Fake/Real pair. | Eager OCR on every photo; a process-global cache on `PhotoOcr`; a Fake/Real `PhotoOcr` |
| Identified consulta pkcs12 seam | `SefazConsulta.current.lookup(pkcs12:, chave:)` stays the consulta port. `Organization` owns titular / expiry / wrap / unwrap and exposes pkcs12 or `nil`. Insert and confirm call that exposure; they do not copy the gate. A1 remains columns on `Organization`, not `has_one :sefaz_certificate`. | Duplicate titular/expiry/wrap on `SupportingDocument`; a certificate Active Record |
| Confirm stays a sibling | `confirm_identified_sefaz` / `POST …/sefaz_confirm` / “Usar dados da SEFAZ” are not part of the insert interface. Confirm reuses consulta + persist. It does not re-run PhotoSymbols, public NFC-e, or PhotoFields. | Fold confirm into `insert` / `#apply` |
| Proof surface | Prove this deepen through `SupportingDocument.insert` / `#apply` (model), the existing request specs, and adapter Real `#scan` / `#read` / `#lookup` / `#fetch`. Do not spec private cascade steps. | Examples that call private methods on `SupportingDocument` |

## Sources

- https://github.com/gutors/ai-accounting-assistant/issues/69 - this cut: deepen insert/apply in place; one OCR memo; pkcs12 from Organization; confirm stays sibling
- `/var/folders/jb/080tpwgx2m7bn25mh_6y76pc0000gn/T/handoff-supporting-document-insert-deepen.md` - grilling Q1–Q8 (accepted): one insert/apply interface; confirm sibling; deepen in place; lazy OCR memo; pkcs12 from Organization; proof surface; private methods on the same class. Quote: “At most one `PhotoOcr.text` per insert/apply when that text is needed (printed chave fallback **or** photo fields).” Quote: “tlc-plan must **not** rewrite those outcomes.”
- `.specs/features/supporting-document-insert/` - existing persist, blobs, 422 copy
- `.checks/nfe-photo-extraction.md`, `.checks/nfe-photo-ocr.md`, `.checks/sefaz-certificate-and-consulta.md` - origins, OCR Real, identified consulta, pending vs confirm
- [ADR-0004](../docs/adr/0004-sefaz-certificate-in-postgres.md) - A1 is a slot on organization
- `CONTEXT.md` - Supporting document, Nota fiscal, Recibo, Chave de acesso, SEFAZ consulta, SEFAZ certificate

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 |  | None |  |
