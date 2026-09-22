# NF-e photo OCR (printed chave and fields)

> Build this with **tlc-implement**.
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

`PhotoSymbols::Real` already decodes QR and CODE-128 from PNG/JPEG. Printed-digit reading is not implemented, and `PhotoFields::Real#read` always returns `Miss` (`app/models/photo_fields.rb`). Production insert of a nota fiscal photo without a barcode/QR and without typed amount, date, and payee therefore ends in `422 Informe valor, data e favorecido`. C4 and C26 of #51 pass only because submit specs stub `PhotoSymbols::Fake` / `PhotoFields::Fake`. Issue #56 gives no conversion figure; the cost is retyping the DANFE when the 44-digit chave is printed as digits and the three fields are on the photo.

When this ships, `PhotoSymbols::Real` returns the printed 44-digit chave after QR and CODE-128 miss, and `PhotoFields::Real` returns amount, date, and emitente after identified consulta and public NFC-e miss. Those values enter the pipeline #51 already wired (`fields_origin` `photo`, correctable). Proofs are PNG/JPEG bytes handed to Real, the same shape as C12/C13. Recibo photos stay unread. Photo bytes stay in the container; there is no third-party OCR or vision API.

9 criteria in 2 slices · 1 one-way door · 0 open, of which 0 block

## Criteria

### Printed 44-digit chave after QR and CODE-128 miss

1. Given a PNG with no QR and no CODE-128 whose pixels render the printed digits `43260511222333000181550010000000011123456781`, when `PhotoSymbols::Real#scan` is given those bytes, then it returns `chave` that value and `qr_url` `nil`.
2. When that same layout is a JPEG, then `PhotoSymbols::Real#scan` returns `chave` `43260511222333000181550010000000011123456781` and `qr_url` `nil`.
3. If a PNG has no QR, no CODE-128, and no 44-digit sequence, then `PhotoSymbols::Real#scan` returns `chave` `nil`.

### Amount, date, and emitente from the photo

4. Given a PNG with no QR and no CODE-128 whose pixels render emitente `Padaria Central`, destinatário `ONG Destinataria`, amount `R$ 155,00`, and date `11/05/2026`, when `PhotoFields::Real#read` is given those bytes, then it returns `amount_cents` `15500`, `document_on` `2026-05-11`, and `payee` `Padaria Central`.
5. When that same layout is a JPEG, then `PhotoFields::Real#read` returns those same three values.
6. Always, `amount_cents` from that read is Integer `15500`, never a `Float`.
7. If a PNG has none of those amount, date, and emitente strings, then `PhotoFields::Real#read` returns `Miss`.
8. If a PNG has `R$ 155,00` and neither a date nor an emitente name, then `PhotoFields::Real#read` does not return a complete triple (`Miss`, or `Fields` with `document_on` `nil` or `payee` `nil`).
9. If the Tesseract host binary is missing or the OCR subprocess errors, then `PhotoSymbols::Real#scan` returns `chave` `nil` and `PhotoFields::Real#read` returns `Miss`.

## Out of scope

- Reading a recibo photo — #14 this version; #51 C7 / C31
- Sending photo bytes to a third-party OCR or vision API — #51 Decided 2; issue #56
- Replacing C4 / C26 Fake submit specs with Real — issue #56 asks C12/C13-shaped Real proofs; the pipeline stays #51
- Typed chave, identified consulta, public NFC-e GET, lock, confirm — already #38 / #51
- PDF or WebP Real decode — `PhotoSymbols::Real#load_image` already returns no image for those; this cut is PNG/JPEG
- HEIC and types outside JPEG, PNG, WebP, PDF — existing `PHOTO_TYPE`
- Re-running extraction when PATCH replaces the photo — #51 Unresolved 1 (no)
- Backfilling existing photos — #51 C40
- Real DANFE photos or other financial data in the repo — `AGENTS.md`
- NF-e issuance, organization CNPJ as a setup field, accountant login — `AGENTS.md`

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `/supporting_documents` include | empty amount/date/payee | existing - #51 C30 / C46 `422` `Informe valor, data e favorecido` when Real misses (3, 7, 9) |
| screen `/supporting_documents` include | loading | n/a - Turbo full-page / redirect; this cut does not add a progress state |
| screen `/supporting_documents` include | error state | existing - #51 C30, C33, C46 |
| screen `/supporting_documents` include | unauthorised | existing - #51 C42 |
| screen `/supporting_documents` include | density and ordering | existing - filled amount, date, payee, chave on the date-desc list; no origin badge |
| screen `/supporting_documents` include | destructive action confirms | existing - document DELETE still Turbo-confirms |
| HTML `POST /supporting_documents` | who may call it | existing - focused Access |
| HTML `POST /supporting_documents` | error shape and codes | existing - `422` copy unchanged; 9 keeps miss rather than a new status |
| HTML `POST /supporting_documents` | versioning | n/a - existing HTML surface; production Real now reads printed digits and fields |
| HTML `POST /supporting_documents` | rate limit | n/a - small operator set |
| HTML `PATCH /supporting_documents/:id` | who / error / versioning / rate limit | n/a - this cut does not change PATCH; `photo` origin stays correctable (#51 C26) |
| command / scheduled task | flags, exit codes, halfway failure | n/a - no CLI or job |
| document or copy | structure, tone, next step | n/a - no new user-facing copy |
| collection supporting documents | grouping, naming, ordering, duplicates, exception | existing - #51; recibo still ignores photo |

## Swept

- validation: 3, 8 - a photo with no 44-digit sequence is a chave miss, not `422` at the port; a photo that lacks date or emitente is not a complete triple
- failure modes: 7, 9 - blank/unreadable field image is `Miss`; missing or failing Tesseract is `Miss`, not a raised error into submit
- idempotency and retry: n/a - the ports do not persist; a second scan of the same bytes is another read with no write
- authorization: existing - `POST /supporting_documents` still requires focused Access (#51 C42); the ports are not an inbound API
- concurrency and ordering: n/a - no one-slot resource; two scans do not share writable state
- data lifecycle: n/a - nothing stored by this task; existing photos are not re-read (#51 C40)
- external-dependency failure: 9 - Tesseract missing or subprocess error is `Miss`, then the #51 pipeline (typed or `422`)
- state transitions: n/a - `fields_origin` `photo`, lock, and confirm stay #51; this cut only makes production Real able to reach that origin
- observability: existing - `filter_parameters` already covers certificate/passphrase; photo bytes are not a log field; no new operator metric

## Impact

| Front | What changes |
|---|---|
| domain | existing term: `Chave de acesso` - production `PhotoSymbols::Real` may now return the printed 44 digits after QR and CODE-128 miss, not only those two encodings. Caller: `SupportingDocument#submit` / `#apply` via `PhotoSymbols.current.scan` |
| domain | existing term: `Supporting document` - production `PhotoFields::Real` may now fill amount, date, and payee (emitente) as origin `photo`. Caller: same submit/apply via `PhotoFields.current.read`. Suggestions still read the three columns and must not treat `photo` as locked (#51 door 1) |
| stored data | nothing to migrate; no backfill by re-reading stored photos |

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| 1. Production Real for printed digits and fields is Tesseract in the app container and CI | `PhotoSymbols::Real` (after QR then CODE-128 miss) and `PhotoFields::Real` run Tesseract on PNG/JPEG bytes inside the Rails process host. Runtime `Dockerfile` stage (the final `FROM base`, not only `build`) and the CI `test` job install `tesseract-ocr` and `tesseract-ocr-por`. Photo bytes are not sent to a third-party OCR or vision API. This supersedes #51 Landing door 5 (`PhotoFields::Real` miss / printed-digit Real miss). How the spec rasterizes the proof PNG/JPEG, and CLI vs FFI vs wrapper gem, are placement. | Cloud Vision / Textract — `AGENTS.md` does not pick a cloud vendor inside a feature; photos are working files with financial data; #51 Decided 2. Pure-Ruby OCR with no native lib — cannot read DANFE emitente/amount/date for criteria 4–5. Leave Real as miss — that is the production hole #56 names. Ship Tesseract only in CI and not in the runtime image — proofs would pass and production would still `Miss`. |

- Nothing else in this change is hard to reverse. Door 1 reaches past this feature: a later read of a working-file image that needs OCR copies Tesseract in the container plus in-process ports with fakes, not a cloud vision vendor. #51 door 2 (allowlisted public GET; bytes stay off third-party APIs) still holds.

## Sources

- https://github.com/gutors/ai-accounting-assistant/issues/56 - this cut: printed 44-digit chave after QR and CODE-128 miss; amount, date, emitente from the photo after identified and public NFC-e miss; origin `photo`, correctable; recibo unread; bytes in-process, no cloud OCR; choose the Real; prove with PNG/JPEG of DANFE in the C12/C13 shape
- https://github.com/gutors/ai-accounting-assistant/issues/51 - pipeline, Fake ports, C4 / C26; closed by PR #55
- `.checks/nfe-photo-extraction.md` Landing door 5 - printed-digit and `PhotoFields::Real` miss was deferred so this cut can prove Tesseract (or another Real) with C12/C13-shaped fixtures
- `.tasks/nfe-photo-extraction.md` - extraction order; all-three-or-miss at field reading; payee is emitente; submit specs fake the ports; Real CODE-128 / QR are C12 / C13
- https://github.com/gutors/ai-accounting-assistant/issues/14#issuecomment-5611316484 - steps 1 (printed chave after barcode/QR) and 4 (fields on the photo); recibo this version typed only
- `CONTEXT.md` - Supporting document, Chave de acesso, Nota fiscal, Recibo; image PDF counts as a photo
- `AGENTS.md` / `.cursor/rules/rails.mdc` - no cloud vendor inside a feature; money is integer cents; Real decoder proven at its own layer from fixtures
- `app/models/photo_symbols.rb` / `app/models/photo_fields.rb` - production `build` is already Real; test `reset!` is Fake

No design source for the screens. Verification stays on project profile `standard`.

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | | None | |
