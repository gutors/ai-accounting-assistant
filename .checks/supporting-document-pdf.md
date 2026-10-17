# Supporting document image-PDF read and preview

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/supporting-document-pdf.md` marks screens `documents` insert and `documents` edit binding through `.specs/features/visual-identity/design.md` section `documents`.

Sources:

- `.tasks/supporting-document-pdf.md` - criteria 1–15, Poppler door, sweep, surface. Unresolved is empty
- Chat 2026-10-17 - image PDF (JPEG xobjects) preview + raster every page; recibo fields stay typed; no cloud
- `.specs/features/visual-identity/design.md` section `documents` - **binding for the interface**: screens `documents` insert and `documents` edit. Opened as a file in the repo. This cut amends that section: after identify, left proof previews the photo including an image PDF, plus `Limpar`; edit proof previews an attached PDF the same way as a JPEG, not filename-only
- `.impeccable/mocks/documents-intake.html` - **binding for the interface**: screen `documents` insert JPEG/XML. Opened as a file in the repo. No PDF-loaded state; this task wins for the PDF preview
- `.impeccable/mocks/document-edit.html` - **binding for the interface**: screen `documents` edit JPEG. Opened as a file in the repo. Proof is a receipt mock + `Foto ·` filename; this task wins for an attached PDF embed
- `GLOSSARY.md` Supporting document - image PDF of a DANFE or recibo counts as a photo
- `.tasks/nfe-photo-extraction.md` criterion 3 / issue #51 C3 - `.pdf` whose decode returns the chave; proven today with Fake
- `.tasks/nfe-photo-ocr.md` - Tesseract in-process; PDF Real decode was out of scope
- `.tasks/document-file-first-insert.md` - identify does not persist; image-PDF infers `nota_fiscal` when extraction delivers, else `recibo`
- `AGENTS.md` / `.cursor/rules/rails.mdc` - no cloud vendor; integer cents; Real proven at its own layer from fixtures; system specs only when a request spec cannot settle
- `app/models/photo_symbols.rb`, `app/models/photo_ocr.rb`, `app/models/photo_zbar.rb`, `app/javascript/controllers/document_identify_controller.js` `imageFile`, `app/views/supporting_documents/edit.html.erb` `content_type` `image/`

## Out of scope

- WebP Real decode — still deferred; this cut is `.pdf` only
- Reading recibo fields from a photo or PDF — #14 / #51 C7 / C31; C10
- Native PDF text extraction (`pdf-reader` / HexaPDF) as the read path — the triggering file is an image PDF
- Pulling embedded JPEG streams instead of rasterizing the composed page
- Cloud OCR / vision APIs — #51 Decided 2; `AGENTS.md`
- Bank-statement PDF — accountant copy; movements come from the spreadsheet
- HEIC and types outside JPEG, PNG, WebP, PDF — existing `PHOTO_TYPE`
- Replacing C4 / C26 Fake submit specs with Real — HTTP create of a PDF with Fake chave already exists
- Real DANFE PDFs or other financial data in the repo — proofs are generated pages
- Stitching a partial field triple across pages — first complete triple on a single page wins
- A separate page cap — existing `MAX_BYTES` `10485760` is the budget
- Changing `MAX_BYTES`, xor file, identify-does-not-persist, or origin stamps
- NF-e issuance, organization CNPJ as a setup field, accountant login — `AGENTS.md`

## Landing

Touches `PhotoSymbols::Real` and `PhotoFields::Real` (raster each PDF page to PNG, then the existing image path), a host `pdftoppm` helper, insert Stimulus preview, and edit proof ERB. Reuses `PhotoZbar` / `PhotoOcr` / identify-does-not-persist / Fake HTTP create. Runtime `Dockerfile` `base` and CI `test` install `poppler-utils`.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Production read of a supporting-document PDF is `pdftoppm` (Poppler) in the app container and CI, every page in order, then the existing image ports | Raster each page of the PDF bytes to PNG via the `pdftoppm` CLI and Open3 inside the Rails process host, in document order (page 1, then 2, …). Each PNG is what `PhotoZbar`, `PhotoOcr`, `PhotoSymbols::Real`, and `PhotoFields::Real` already know. Symbols stop at the first page that yields a 44-digit chave or a QR URL. Fields stop at the first page that yields a complete amount/date/payee triple. Runtime `Dockerfile` `base` (the final image inherits `base`, not only `build`) and the CI `test` job install `poppler-utils`. PDF bytes are not sent to a third-party OCR or vision API. Page count is bounded by existing `MAX_BYTES`; there is no separate page cap. How the spec builds the proof PDF, DPI, and tempfile names are placement. Door 1 reaches past this feature: a later read of a working-file PDF copies Poppler in the container plus raster-then-image-ports, not a cloud vision vendor and not a second text-PDF parser. | Cloud Vision / Textract — `AGENTS.md` / #51 Decided 2. `pdf-reader` / HexaPDF text only — cannot read the image PDF that triggered this work. Extract embedded JPEGs — page composition can slice the barcode. Ghostscript `gs` — heavier host package for the same raster. Leave Real as miss — the production hole #51 C3 named and nfe-photo-ocr deferred. Ship `poppler-utils` only in CI — proofs would pass and production would still miss. Page 1 only — closed by chat 2026-10-17. Stitch partial fields across pages — not asked; first complete page wins. |

- Nothing else in this change is hard to reverse. Client-side blob preview of the original PDF (insert) and `url_for` embed on edit, vs a server raster thumbnail, is placement.

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

- `.cursor/rules/rails.mdc` lines 39–42: decision at its own layer, one asserted case per enumerated member; HTTP also a request spec; system specs only when a request spec cannot settle
- `PhotoSymbols::Real` / `PhotoFields::Real` first-delivering-page and miss — own-layer table from generated PDFs, same shape as `spec/models/photo_symbols_spec.rb` CODE-128 PNG
- C10 `SupportingDocument.identify` with Real — model layer (identify does not persist; no HTTP claim in that criterion)
- C11 / C12 are HTTP contracts (`200` / `302`, persist, copy)
- C1 choosing a file paints a blob URL — browser File API; request spec cannot settle it. Closest analogue: `spec/system/document_identify_spec.rb` JPEG `img[src^='blob:']`
- C2 GET edit embed — request spec (same as `GET edit attached photo shows img`)
- `PhotoPdf` Open3 wrapper is instrumentation; missing/error branches are asserted through Real C13
- Host packages: `spec/config/application_spec.rb` reads Dockerfile / workflow, not HTTP

Cost: system proof for insert PDF preview; request proofs for edit embed, identify miss, create recibo; model proofs for Real PDF pages, identify Real, and pdftoppm failure; file assertions for two host assemblies and README.

## Screens (ui)

Opened: `.impeccable/mocks/documents-intake.html` (file), `.impeccable/mocks/document-edit.html` (file), `.specs/features/visual-identity/design.md` section `documents` (file). Intake and edit mocks have no PDF-loaded state; criteria 1–2 / this task win for that preview.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `documents` insert | `#identify-preview` page preview of chosen `.pdf`; copy `Foto · nota.pdf`; `Limpar` inside the square; JPEG/PNG `#identify-preview img[src^='blob:']` unchanged | Split unchanged: proof **first**, book `max-w-[28rem]`. PDF preview is an **embed of the file blob inside `#identify-preview`**, not filename-only in the square. `Limpar` remains inside the loaded square | `documents` insert spacing, colour, type weight |
| `documents` edit | `aside[data-edit=proof]` copy `Foto · nota.pdf` and `O arquivo não pode ser alterado. Exclua o documento e inclua novamente.` | Proof is an **embed of the photo blob** (`application/pdf`), not only the filename in the square. Existing split proof first / book `28rem` from 768px | `documents` edit spacing, colour, type weight |

## Checks

Criteria 1–15 map to C1–C15.

### S1 - Proof preview of the PDF · 6 files · 207 KB · ~52k

**C1** - Given a signed-in coordinator of the focused organization on `GET /supporting_documents`, when they choose a `.pdf` file named `nota.pdf` (identify may miss), then the proof square `#identify-preview` shows a page preview of that file (not filename-only), the copy `Foto · nota.pdf`, and `Limpar` inside the square. JPEG/PNG preview via `#identify-preview img[src^='blob:']` is unchanged
Proof: `bin/rspec spec/system/document_identify_spec.rb -e "identify pdf shows the file in the proof square"`
Proof: `bin/rspec spec/system/document_identify_spec.rb -e "identify photo shows the image in the proof square"`

**C2** - Given a persisted SupportingDocument whose photo is `nota.pdf` with content type `application/pdf`, when `GET /supporting_documents/:id/edit` runs as that coordinator, then the status is `200`, `aside[data-edit=proof]` previews that PDF (an embed of the photo blob, not only the filename in the square), and the copy includes `Foto · nota.pdf` and `O arquivo não pode ser alterado. Exclua o documento e inclua novamente.`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit pdf photo embeds the blob in the proof square"`

### S2 - Pages of an image PDF are readable by production Real · 5 files · 18 KB · ~5k

**C3** - Given a one-page PDF with no PDF text operators whose page, once rasterized, is the CODE-128 of `43260511222333000181550010000000011123456781`, when `PhotoSymbols::Real#scan` is given those PDF bytes, then it returns `chave` that value and `qr_url` `nil`
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real CODE-128 PDF returns chave 43260511222333000181550010000000011123456781"`

**C4** - Given a one-page PDF with no QR and no CODE-128 whose pixels render the printed digits `43260511222333000181550010000000011123456781`, when `PhotoSymbols::Real#scan` is given those PDF bytes, then it returns `chave` that value and `qr_url` `nil`
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real printed-digit PDF returns chave 43260511222333000181550010000000011123456781"`

**C5** - Given a one-page PDF with no QR and no CODE-128 whose pixels render emitente `Padaria Central`, destinatário `ONG Destinataria`, amount `R$ 155,00`, and date `11/05/2026`, when `PhotoFields::Real#read` is given those PDF bytes, then it returns `amount_cents` `15500` (Integer, never a `Float`), `document_on` `2026-05-11`, and `payee` `Padaria Central`
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real PDF returns 15500 2026-05-11 Padaria Central Integer"`

**C6** - If a one-page PDF has none of those amount, date, and emitente strings, and no QR/CODE-128/printed chave, then `PhotoSymbols::Real#scan` returns `chave` `nil` and `PhotoFields::Real#read` returns `Miss`
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real blank PDF returns chave nil"`
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real blank PDF returns Miss"`

**C7** - Given a two-page PDF whose first page is blank white and whose second page is the CODE-128 of C3, when `PhotoSymbols::Real#scan` is given those bytes, then it returns `chave` `43260511222333000181550010000000011123456781`
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real two-page PDF blank then CODE-128 returns first delivering chave"`

**C8** - Given a two-page PDF whose first page is the CODE-128 of C3 and whose second page is a CODE-128 of `43260511222333000181550010000000021987654321`, when `PhotoSymbols::Real#scan` is given those bytes, then it returns `chave` `43260511222333000181550010000000011123456781` (first delivering page)
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real two-page PDF two CODE-128 returns first page chave"`

**C9** - Given a two-page PDF whose first page is blank white and whose second page is the field layout of C5, when `PhotoFields::Real#read` is given those bytes, then it returns `amount_cents` `15500`, `document_on` `2026-05-11`, and `payee` `Padaria Central`
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real two-page PDF blank then fields returns Padaria Central"`

### S3 - Identify uses that read; miss is still typed recibo · 3 files · 250 KB · ~62k

**C10** - Given `PhotoSymbols.current` is Real, the organization has no A1, and the file is the two-page PDF of C7, when `SupportingDocument.identify` runs with that file, then no SupportingDocument is persisted, `errors` is empty, `kind` is `nota_fiscal`, and `chave` is `43260511222333000181550010000000011123456781`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "identify Real two-page PDF CODE-128 is nota_fiscal chave without persisting"`

**C11** - When a coordinator POSTs `POST /supporting_documents/identify` with a `.pdf` whose symbols and field reading miss, then no SupportingDocument is persisted, the status is `200`, Arquivo is `Foto`, Tipo is `Recibo` disabled, chave is not visible, Valor, Data, and Favorecido are empty and enabled, origin under each is `Digitado`, and `Incluir documento` is disabled
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify pdf miss is recibo typed empty"`

**C12** - When a coordinator POSTs `kind=recibo` with a `.pdf` whose raster would return the chave of C3, and typed amount `155,00`, date `2026-05-11`, payee `Padaria Central`, then one SupportingDocument persists `kind` `recibo`, `chave` `nil`, no XML blob, that photo, `amount_cents` `15500`, and the status is `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST create recibo pdf with raster chave persists typed recibo"`

### S4 - Host rasterizer; failure is a miss · 4 files · 16 KB · ~4k

**C13** - If the `pdftoppm` host binary is missing or the raster subprocess errors, then `PhotoSymbols::Real#scan` of a well-formed one-page PDF returns `chave` `nil` and `PhotoFields::Real#read` returns `Miss` (no exception into identify/submit)
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real scan misses when pdftoppm binary is missing"`
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real read misses when pdftoppm binary is missing"`
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real scan misses when pdftoppm subprocess errors"`
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real read misses when pdftoppm subprocess errors"`

**C14** - Always, the production Dockerfile runtime image (the `base` stage the final `FROM base` inherits, not only `build`) installs `poppler-utils`, and the CI `test` job installs `poppler-utils` before `bin/rspec`
Proof: `bin/rspec spec/config/application_spec.rb -e "production runtime image installs poppler-utils"`
Proof: `bin/rspec spec/config/application_spec.rb -e "CI test job installs poppler-utils before rspec"`

**C15** - Always, `README.md` names the `pdftoppm` binary (Poppler) for PDF photos the same way it names `tesseract` for JPEG/PNG: without it, PDF reading is empty and fields stay typed
Proof: `bin/rspec spec/config/application_spec.rb -e "README names pdftoppm for PDF photos next to tesseract"`

## Swept

- validation: C6, C11 - a PDF that does not yield chave or a complete field triple is a miss / typed recibo, not a new `422`; extension `.pdf` stays `PHOTO_EXT`
- failure modes: C13 - missing or failing `pdftoppm` is `Miss` / chave `nil`, not a raised error into identify/submit
- idempotency and retry: n/a - identify does not persist; a second identify of the same bytes is another read with no write; create of a PDF is one new row per POST (existing)
- authorization: existing - identify and create still require focused Access; the rasterizer is not an inbound API
- concurrency and ordering: C7, C8 - pages are rasterized in document order; the first delivering chave/QR wins over a later page; two identifies do not share writable raster state
- data lifecycle: n/a - the raster is not stored; existing PDF blobs are not backfilled; the original `.pdf` remains the Active Storage photo
- external-dependency failure: C13, C14 - Poppler missing in production/CI is the same miss as a missing `tesseract`; C14 is the host assembly
- state transitions: n/a - `fields_origin`, lock, and confirm stay #51; this cut only lets production Real reach those origins from PDF bytes
- observability: existing - `filter_parameters` already covers certificate/passphrase; PDF bytes are not a log field; no new operator metric

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| designed screens (2) | `documents` insert C1 · `documents` edit C2 | - |
| insert preview kinds (2) | PDF embed C1 · JPEG `img[src^='blob:']` C1 | - |
| Real PDF symbols (5) | CODE-128 C3 · printed digits C4 · blank miss C6 · later page C7 · first delivering C8 | - |
| Real PDF fields (3) | fields + Integer cents C5 · blank Miss C6 · later page C9 | - |
| identify / create (3) | Real delivering C10 · HTTP miss recibo C11 · HTTP typed recibo C12 | - |
| pdftoppm failure (2 modes × 2 ports) | missing symbols C13 · missing fields C13 · subprocess symbols C13 · subprocess fields C13 | - |
| Poppler host packages (2 assemblies) | Dockerfile `base` / runtime C14 · CI `test` job C14 | - |
| operator docs (1) | README `pdftoppm` C15 | - |
| startup config assemblies | `PhotoPdf` binary default lives in one module; test `reset!` and production `pdftoppm` share it (same as `PhotoOcr`) | - |

- Claims naming a status code, route or response shape: C2, C11, C12 - each has a proof that crosses the HTTP boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~52k (dominated by `spec/requests/supporting_documents_spec.rb`) + S2 ~5k + S3 ~62k counting that request spec again + S4 ~4k. Unique files across S1–S4 ≈ 329k bytes ≈ 82k tokens floor, under 150k. One agent, one batch.
