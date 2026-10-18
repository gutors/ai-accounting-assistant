# Supporting document image-PDF read and preview

> Build this with **tlc-implement**. Profile **`ui`**: screens `documents` insert and
> `documents` edit are binding through `.specs/features/visual-identity/design.md` section
> `documents` (this task amends that section). The intake mock has no PDF-loaded state; this
> task wins for the PDF preview. Raised from the repo floor `standard` because the task names
> those binding screens.
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

A coordinator or submitter can choose a `.pdf` on `GET /supporting_documents` (`PHOTO_EXT`
includes `.pdf`; `accept` already lists it). Identify does not persist. Production Real never
decodes PDF bytes: `PhotoZbar` and `PhotoOcr` return empty unless the magic is PNG or JPEG,
`PhotoSymbols::Real#load_image` returns no image, so chave and fields miss. Infer then locks
Tipo as `recibo` with empty Valor/Data/Favorecido. The proof square paints a preview only for
`image/` (or `.jpg`/`.png`/`.webp`); a PDF has no `<img>`, and `GET …/edit` shows only the
filename when `content_type` is not `image/`. Issue #51 criterion 3 already required a `.pdf`
whose decode returns the chave, but that POST is proven with `PhotoSymbols::Fake` and
`photo_with_ext("pdf")` bytes `bytes-pdf`, not a rendered page. `.tasks/nfe-photo-ocr.md` left
PDF Real decode out of scope. The conversation that produced this task gives no conversion
figure; the cost is a DANFE or recibo that the product already accepts as a photo showing
neither the page nor any field.

When this ships, choosing an image PDF on screen `documents` insert shows the file in the
proof square and runs the existing photo pipeline on a raster of **every page, in order**
(ZBar, then printed digits, then PhotoFields, then identified / public NFC-e). The first
page that yields a chave or QR URL wins; the first page that yields a complete field triple
wins. A delivering read is a nota fiscal; a miss is still a typed recibo. Edit shows that
PDF in the proof, not filename alone. Recibo fields stay typed. Bytes stay in the process
host.

15 criteria in 4 slices · 1 one-way door · 0 open, of which 0 block

## Criteria

### Proof preview of the PDF

1. Given a signed-in coordinator of the focused organization on `GET /supporting_documents`,
   when they choose a `.pdf` file named `nota.pdf` (identify may miss), then the proof square
   `#identify-preview` shows a page preview of that file (not filename-only), the copy
   `Foto · nota.pdf`, and `Limpar` inside the square. JPEG/PNG preview via
   `#identify-preview img[src^='blob:']` is unchanged.
2. Given a persisted SupportingDocument whose photo is `nota.pdf` with content type
   `application/pdf`, when `GET /supporting_documents/:id/edit` runs as that coordinator, then
   the status is `200`, `aside[data-edit=proof]` previews that PDF (an embed of the photo blob,
   not only the filename in the square), and the copy includes `Foto · nota.pdf` and
   `O arquivo não pode ser alterado. Exclua o documento e inclua novamente.`

### Pages of an image PDF are readable by production Real

3. Given a one-page PDF with no PDF text operators whose page, once rasterized, is the
   CODE-128 of `43260511222333000181550010000000011123456781` (same payload as the PNG in
   `spec/models/photo_symbols_spec.rb`), when `PhotoSymbols::Real#scan` is given those PDF
   bytes, then it returns `chave` that value and `qr_url` `nil`.
4. Given a one-page PDF with no QR and no CODE-128 whose pixels render the printed digits
   `43260511222333000181550010000000011123456781`, when `PhotoSymbols::Real#scan` is given
   those PDF bytes, then it returns `chave` that value and `qr_url` `nil`.
5. Given a one-page PDF with no QR and no CODE-128 whose pixels render emitente
   `Padaria Central`, destinatário `ONG Destinataria`, amount `R$ 155,00`, and date
   `11/05/2026`, when `PhotoFields::Real#read` is given those PDF bytes, then it returns
   `amount_cents` `15500` (Integer, never a `Float`), `document_on` `2026-05-11`, and `payee`
   `Padaria Central`.
6. If a one-page PDF has none of those amount, date, and emitente strings, and no
   QR/CODE-128/printed chave, then `PhotoSymbols::Real#scan` returns `chave` `nil` and
   `PhotoFields::Real#read` returns `Miss`.
7. Given a two-page PDF whose first page is blank white and whose second page is the CODE-128
   of criterion 3, when `PhotoSymbols::Real#scan` is given those bytes, then it returns
   `chave` `43260511222333000181550010000000011123456781`.
8. Given a two-page PDF whose first page is the CODE-128 of criterion 3 and whose second page
   is a CODE-128 of `43260511222333000181550010000000021987654321`, when
   `PhotoSymbols::Real#scan` is given those bytes, then it returns `chave`
   `43260511222333000181550010000000011123456781` (first delivering page).
9. Given a two-page PDF whose first page is blank white and whose second page is the field
   layout of criterion 5, when `PhotoFields::Real#read` is given those bytes, then it returns
   `amount_cents` `15500`, `document_on` `2026-05-11`, and `payee` `Padaria Central`.

### Identify uses that read; miss is still typed recibo

10. Given `PhotoSymbols.current` is Real, the organization has no A1, and the file is the
    two-page PDF of criterion 7, when `SupportingDocument.identify` runs with that file, then
    no SupportingDocument is persisted, `errors` is empty, `kind` is `nota_fiscal`, and `chave`
    is `43260511222333000181550010000000011123456781`.
11. When a coordinator POSTs `POST /supporting_documents/identify` with a `.pdf` whose symbols
    and field reading miss, then no SupportingDocument is persisted, the status is `200`,
    Arquivo is `Foto`, Tipo is `Recibo` disabled, chave is not visible, Valor, Data, and
    Favorecido are empty and enabled, origin under each is `Digitado`, and `Incluir documento`
    is disabled.
12. When a coordinator POSTs `kind=recibo` with a `.pdf` whose raster would return the chave of
    criterion 3, and typed amount `155,00`, date `2026-05-11`, payee `Padaria Central`, then
    one SupportingDocument persists `kind` `recibo`, `chave` `nil`, no XML blob, that photo,
    `amount_cents` `15500`, and the status is `302`.

### Host rasterizer; failure is a miss

13. If the `pdftoppm` host binary is missing or the raster subprocess errors, then
    `PhotoSymbols::Real#scan` of a well-formed one-page PDF returns `chave` `nil` and
    `PhotoFields::Real#read` returns `Miss` (no exception into identify/submit).
14. Always, the production Dockerfile runtime image (the `base` stage the final `FROM base`
    inherits, not only `build`) installs `poppler-utils`, and the CI `test` job installs
    `poppler-utils` before `bin/rspec`.
15. Always, `README.md` names the `pdftoppm` binary (Poppler) for PDF photos the same way it
    names `tesseract` for JPEG/PNG: without it, PDF reading is empty and fields stay typed.

## Out of scope

- WebP Real decode — still deferred; this cut is `.pdf` only
- Reading recibo fields from a photo or PDF — #14 / #51 C7 / C31; criterion 10
- Native PDF text extraction (`pdf-reader` / HexaPDF) as the read path — the coordinator file
  that triggered this work is an image PDF (JPEG xobjects, no text, no 44-digit string in the
  bytes)
- Pulling embedded JPEG streams instead of rasterizing the composed page — those streams can
  be strips; the barcode can sit across slices
- Cloud OCR / vision APIs — #51 Decided 2; `AGENTS.md`
- Bank-statement PDF — still the accountant copy; movements come from the spreadsheet
- HEIC and types outside JPEG, PNG, WebP, PDF — existing `PHOTO_TYPE`
- Replacing C4 / C26 Fake submit specs with Real — HTTP create of a PDF with Fake chave
  already exists (`POST pdf photo chave with consulta XML redirects`)
- Real DANFE PDFs or other financial data in the repo — `AGENTS.md`; proofs are generated
  pages, same shape as the CODE-128 / printed-digit PNG fixtures
- Stitching a partial field triple across pages (amount on page 1, date on page 2) — first
  complete triple on a single page wins; splitting DANFE tables across pages is out
- A separate page cap — existing `MAX_BYTES` `10485760` is the budget; every page in that
  file is rasterized in order
- Changing `MAX_BYTES` `10485760`, xor file, identify-does-not-persist, or origin stamps
- NF-e issuance, organization CNPJ as a setup field, accountant login — `AGENTS.md`

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `documents` insert | empty state | existing - file-first C1 empty square and wait copy |
| screen `documents` insert | loading | existing - `Identificando o arquivo…` (file-first C10) |
| screen `documents` insert | error state | existing - Turbo Stream `422` copy; 13 is a miss, not a new status |
| screen `documents` insert | unauthorised | existing - identify `302` `/login` |
| screen `documents` insert | density and ordering | 1 - PDF page in the proof square with `Foto ·` filename and `Limpar`; JPEG `img` blob unchanged |
| screen `documents` insert | destructive action confirms | existing - `Limpar` does not persist; DELETE still Turbo-confirms |
| screen `documents` edit | empty / loading | n/a - edit is a persisted row |
| screen `documents` edit | error state | existing - `422` lock copy |
| screen `documents` edit | unauthorised | existing - focused Access / 404 |
| screen `documents` edit | density and ordering | 2 - PDF embed in `aside[data-edit=proof]`, lock sentence unchanged |
| screen `documents` edit | destructive action confirms | existing - file still locked; replace is delete then insert |
| HTML `POST /supporting_documents/identify` | who may call it | existing - focused Access |
| HTML `POST /supporting_documents/identify` | error shape and codes | existing - `422` unreadable XML / xor; PDF miss is `200` Recibo (11) |
| HTML `POST /supporting_documents/identify` | versioning / rate limit | n/a - existing HTML surface; small operator set |
| HTML `POST /supporting_documents` | who / error / versioning / rate limit | 12 - create of a typed recibo PDF; otherwise existing |
| HTML `GET /supporting_documents/:id/edit` | who / error | 2 |
| command / scheduled task | flags, exit codes, halfway failure | n/a - no CLI or job |
| document `README.md` | structure, tone, next step | 15 - name `pdftoppm` next to `tesseract` |
| collection supporting documents | grouping, naming, ordering, duplicates, exception | existing - list still date-desc; two PDFs with the same chave stay two rows (#51 C44) |

## Swept

- validation: 6, 11 - a PDF that does not yield chave or a complete field triple is a miss / typed recibo, not a new `422`; extension `.pdf` stays `PHOTO_EXT`
- failure modes: 13 - missing or failing `pdftoppm` is `Miss` / chave `nil`, not a raised error into identify/submit
- idempotency and retry: n/a - identify does not persist; a second identify of the same bytes is another read with no write; create of a PDF is one new row per POST (existing)
- authorization: existing - identify and create still require focused Access; the rasterizer is not an inbound API
- concurrency and ordering: 7, 8 - pages are rasterized in document order; the first delivering chave/QR wins over a later page; two identifies do not share writable raster state
- data lifecycle: n/a - the raster is not stored; existing PDF blobs are not backfilled; the original `.pdf` remains the Active Storage photo
- external-dependency failure: 13, 14 - Poppler missing in production/CI is the same miss as a missing `tesseract`; 14 is the host assembly
- state transitions: n/a - `fields_origin`, lock, and confirm stay #51; this cut only lets production Real reach those origins from PDF bytes
- observability: existing - `filter_parameters` already covers certificate/passphrase; PDF bytes are not a log field; no new operator metric

## Impact

| Front | What changes |
|---|---|
| domain | existing term: `Supporting document` photo — an image PDF is already a photo on disk (`PHOTO_EXT`, GLOSSARY). Production Real may now return chave and fields from any page of that PDF (first delivering page), so infer can lock `nota_fiscal` instead of `recibo`. Callers: `SupportingDocument#submit` / `.identify` via `PhotoSymbols.current.scan` and `PhotoFields.current.read` |
| domain | existing term: `Chave de acesso` — production `PhotoSymbols::Real` may now obtain the 44 digits from a rasterized PDF page, not only PNG/JPEG. Same callers |
| stored data | nothing to migrate; no backfill by re-reading stored PDFs; the blob stays the original PDF |

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| 1. Production read of a supporting-document PDF is `pdftoppm` (Poppler) in the app container and CI, every page in order, then the existing image ports | Raster each page of the PDF bytes to PNG via the `pdftoppm` CLI and Open3 inside the Rails process host, in document order (page 1, then 2, …). Each PNG is what `PhotoZbar`, `PhotoOcr`, `PhotoSymbols::Real`, and `PhotoFields::Real` already know. Symbols stop at the first page that yields a 44-digit chave or a QR URL. Fields stop at the first page that yields a complete amount/date/payee triple. Runtime `Dockerfile` `base` (the final image inherits `base`, not only `build`) and the CI `test` job install `poppler-utils`. PDF bytes are not sent to a third-party OCR or vision API. Page count is bounded by existing `MAX_BYTES`; there is no separate page cap. How the spec builds the proof PDF, DPI, and tempfile names are placement. Door 1 reaches past this feature: a later read of a working-file PDF copies Poppler in the container plus raster-then-image-ports, not a cloud vision vendor and not a second text-PDF parser. | Cloud Vision / Textract — `AGENTS.md` / #51 Decided 2. `pdf-reader` / HexaPDF text only — cannot read the image PDF that triggered this work (JPEG xobjects, no text, no 44-digit string). Extract embedded JPEGs — page composition can slice the barcode. Ghostscript `gs` — heavier host package for the same raster; Poppler matches the Tesseract CLI-via-Open3 pattern already in `PhotoOcr`. Leave Real as miss — that is the production hole #51 C3 named and nfe-photo-ocr deferred. Ship `poppler-utils` only in CI — proofs would pass and production would still miss. Page 1 only — closed by chat 2026-10-17: scan later pages when the file has 2+. Stitch partial fields across pages — not asked; first complete page wins. |

- Nothing else in this change is hard to reverse. Client-side blob preview of the original PDF (insert) and `url_for` embed on edit, vs a server raster thumbnail, is placement: identify still does not persist, and JPEG already uses a blob URL.

## Surface

| Route | In | Out | Status | Criteria |
|---|---|---|---|---|
| `POST /supporting_documents/identify` | `file` (`.pdf`) | Turbo Stream `identify-preview` + `identify-book` | `200`, `422`, `302` | 1, 10, 11 |
| `POST /supporting_documents` | `file` / `photo`, optional `kind` | redirect or `422` | `302`, `422` | 12 |
| `GET /supporting_documents/:id/edit` | id | proof embed of PDF blob | `200`, `404` | 2 |

## Sources

- Chat 2026-10-17 — coordinator could not preview or fill from
  `.scratch/monthly-package/notas/nota-cobertores-2105.pdf`. Decided option 1: raster and
  reuse the photo pipeline; preview the PDF; recibo fields stay typed; no cloud. Follow-up:
  “Varrer outras paginas, caso o documento tenha 2+ paginas” — every page in order, not page
  1 only. Quoted shape: image PDF (JPEG xobjects, no fonts, no 44-digit chave in the file
  bytes); upload is already allowed; Real decode is not.
- `GLOSSARY.md` Supporting document — image PDF of a DANFE or recibo counts as a photo; recibo
  photo is not read in this version
- `.tasks/nfe-photo-extraction.md` criterion 3 — `.pdf` whose decode returns the chave then
  identified XML; proven today only with Fake
- `.tasks/nfe-photo-ocr.md` — Tesseract in-process; PDF/WebP Real decode out of scope
- `.tasks/document-file-first-insert.md` — identify does not persist; image or image-PDF infers
  `nota_fiscal` when extraction delivers, else `recibo`; proof square + `Limpar`
- `.specs/features/visual-identity/design.md` section `documents` — **binding for the
  interface**: screens `documents` insert and `documents` edit. Amend: after identify, left
  proof is a preview of the photo including an image PDF, plus `Limpar`; edit proof previews
  an attached PDF the same way it previews a JPEG, not filename-only
- `.impeccable/mocks/documents-intake.html` / `document-edit.html` — binding for JPEG/XML
  insert and edit; no PDF-loaded state; this task wins for PDF preview
- https://github.com/gutors/ai-accounting-assistant/issues/51 — C3 PDF decode; Fake ports on
  HTTP create
- `AGENTS.md` / `.cursor/rules/rails.mdc` — no cloud vendor inside a feature; integer cents;
  Real proven at its own layer from fixtures
- `app/models/photo_symbols.rb`, `app/models/photo_ocr.rb`, `app/models/photo_zbar.rb`,
  `app/javascript/controllers/document_identify_controller.js` `imageFile`,
  `app/views/supporting_documents/edit.html.erb` `content_type` `image/`

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | | None | |
