# Insert infer kind from file

> Build this with **tlc-implement**.
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

`GET /supporting_documents` insert `select#kind` starts empty (documents-list-mask-and-actions
criterion 23). `POST /supporting_documents` with that empty kind, a photo, and typed amount, date,
and payee still 422s `Informe se é nota fiscal ou recibo` (that task’s criterion 25;
`spec/requests/supporting_documents_spec.rb` `POST empty kind returns 422`). `SupportingDocument#submit`
returns `BAD_KIND` before it reads the photo. OCR, QR, and CODE-128 run only when posted kind is
already `nota_fiscal`. Recibo photos are not scanned. The chip **Incluir foto** only chooses the
file; it is not a submit. There is no GitHub issue and no conversion figure; the cost is a second
mandatory Tipo click after the file is already in the form, and a nota fiscal photo posted with
Tipo still empty never starts the extraction pipeline.

When this ships, `POST /supporting_documents` with empty kind and a photo or XML infers `nota_fiscal`
or `recibo` from that file, then the existing insert pipeline fills fields. Posted `nota_fiscal` or
`recibo` is kept. Screen `documents` (`GET /supporting_documents` after the 302) shows the inferred
Tipo on the row. No live fill when the chip chooses the file.

12 criteria in 3 slices · 1 one-way door · 1 open, of which 0 block

## Criteria

### Infer kind when insert Tipo is empty

1. Given `PhotoSymbols` for filename `recibo.jpg` returns chave
   `43260511222333000181550010000000011123456781` and `qr_url` `nil`, when a coordinator POSTs
   `/supporting_documents` with `kind` empty, that JPEG photo, amount `155,00`, date `2026-05-11`,
   payee `Padaria Central`, and no XML, then one SupportingDocument persists with kind
   `nota_fiscal` and that chave, the status is `302` to `/supporting_documents`, and that GET’s row
   `[data-cell=kind]` is `Nota fiscal`.
2. Given `PhotoSymbols` for that filename returns `chave` `nil` and `qr_url` `nil`, when that same
   POST runs (empty kind, JPEG photo, those three typed fields, no XML), then one SupportingDocument
   persists with kind `recibo` and `chave` `nil`, no XML blob, the status is `302`, and that GET’s
   row `[data-cell=kind]` is `Recibo`.
3. When a coordinator POSTs empty `kind`, authorized XML of chave
   `43260511222333000181550010000000011123456781` `vNF` `155.00` emitente `Padaria Central`
   `dhEmi` `2026-05-11T10:00:00-03:00`, and no photo, then one SupportingDocument persists with kind
   `nota_fiscal`, that chave, `amount_cents` `15500`, `fields_origin` `uploaded_xml`, and the status
   is `302`.
4. When a coordinator POSTs empty `kind`, that authorized XML, and a JPEG whose `PhotoSymbols` chave
   is `43260511222333000181550010000000021987654321`, then the persisted chave is
   `43260511222333000181550010000000011123456781` (XML), kind is `nota_fiscal`, and the status is
   `302`.
5. Given `PhotoSymbols` for filename `recibo.jpg` returns `qr_url`
   `https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=43260511222333000181650010000000011123456781|2|1|1`
   and chave `43260511222333000181650010000000011123456781`, when a coordinator POSTs empty `kind`,
   that JPEG, those three typed fields, and no XML, then the persisted kind is `nota_fiscal` and
   chave is that 44-digit value.
6. When a coordinator POSTs empty `kind`, amount `155,00`, date `2026-05-11`, payee
   `Padaria Central`, and neither photo nor XML, then no SupportingDocument is persisted, the status
   is `422`, and `[data-notice="error"]` and `[data-toast-kind="error"]` are
   `Informe se é nota fiscal ou recibo`.

### Posted Tipo is kept

7. When a coordinator POSTs `kind=recibo`, a JPEG whose `PhotoSymbols` would return chave
   `43260511222333000181550010000000011123456781`, and typed `155,00` / `2026-05-11` /
   `Padaria Central`, then the persisted kind is `recibo`, `chave` is `nil`, and no XML is attached.
8. Given `PhotoSymbols` for the photo filename returns `chave` `nil` and `qr_url` `nil`, when a
   coordinator POSTs `kind=nota_fiscal`, that JPEG, and those three typed fields, then the persisted
   kind is `nota_fiscal` (not `recibo`).
9. When a coordinator POSTs `kind=invoice`, a JPEG photo, and those three typed fields, then no
   SupportingDocument is persisted, the status is `422`, and the notice and error toast are
   `Informe se é nota fiscal ou recibo`.

### Fields follow existing NF vs recibo paths

10. Given `PhotoSymbols` for filename `recibo.jpg` returns that 44-digit chave and `qr_url` `nil`,
    the organization has no certificate, and `PhotoFields` for that filename returns `amount_cents`
    `15500`, `document_on` `2026-05-11`, payee `Padaria Central`, when a coordinator POSTs empty
    `kind`, that JPEG, no XML, and no typed amount, date, or payee that complete the triple, then
    the row persists those three values, `fields_origin` `photo`, kind `nota_fiscal`, and a later
    PATCH of payee `Mercado Silva` responds `302`.
11. Given `PhotoSymbols` miss (`chave` `nil`, `qr_url` `nil`) and `PhotoFields` for that filename
    would return payee `Mercado Silva`, when a coordinator POSTs empty `kind`, that JPEG, and typed
    `155,00` / `2026-05-11` / `Padaria Central`, then the persisted `payee` is `Padaria Central`
    and `fields_origin` is `typed`.
12. When `SupportingDocument.insert` runs with empty kind and a JPEG photo, then
    `PhotoSymbols.current#scan` is invoked with that photo’s bytes before persist or `BAD_KIND`.

## Out of scope

- Filling Tipo or amount/date/payee when the **Incluir foto** chip chooses a file, before **Incluir
  documento** — user: infer on POST; no preview endpoint
- Reading a recibo photo for amount, date, or payee — #51 C7 / C31; nfe-photo-ocr; user: fields as
  today
- Overwriting a posted `nota_fiscal` or `recibo` from the file — user: `submit_blank_only`
- PDF/WebP Real decode — PhotoOcr / PhotoSymbols::Real already miss; a miss with empty kind is
  recibo (2)
- PATCH inferring kind from a newly attached photo — kind is locked on persist
  (`KIND_LOCKED`)
- Cloud OCR / vision APIs — #51 Decided 2
- Changing GET insert chrome (empty Tipo, Recibo hides chave/XML) — documents-list-mask-and-actions
  23–24

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `documents` insert | empty Tipo | existing - GET `select#kind` selected empty (documents-list-mask-and-actions 23); this task does not change GET |
| screen `documents` insert | loading | n/a - Turbo full-page / redirect; no progress state added |
| screen `documents` insert | error state | 6, 9 - `422` `Informe se é nota fiscal ou recibo`; other insert 422s unchanged (`MISSING_FIELDS`, `PHOTO_TYPE`, XML) |
| screen `documents` insert | unauthorised | existing - session + focused Access; unauthenticated POST still 302 `/login` |
| screen `documents` insert | density and ordering | n/a - no new controls; **Incluir foto** stays the file chip |
| screen `documents` insert | destructive action confirms | n/a - insert is not destructive |
| screen `documents` row | empty state | n/a - list empty copy unchanged |
| screen `documents` row | error / loading | n/a - success is 302 then GET |
| screen `documents` row | density | 1, 2 - `[data-cell=kind]` `Nota fiscal` or `Recibo` |
| screen `documents` row | destructive action confirms | existing - Excluir Turbo confirm |
| HTML `POST /supporting_documents` | who may call it | existing - focused coordinator or submitter |
| HTML `POST /supporting_documents` | error shape and codes | 6, 9 - `422` + existing `:base` notice and error toast |
| HTML `POST /supporting_documents` | versioning | n/a - existing HTML form fields; `kind` may be empty when a file is present |
| HTML `POST /supporting_documents` | rate limit | n/a - small operator set |
| collection supporting documents | grouping / naming / ordering | existing - focused organization; date desc |
| collection supporting documents | duplicates | existing - two POSTs still two rows (#51 C44) |
| collection supporting documents | exception that does not fit | 7, 9 - posted recibo ignores NF symbols; garbage `kind` does not infer |

## Swept

- validation: 6, 9 - empty kind without a file, and `kind` that is not `nota_fiscal` or `recibo`,
  stay `BAD_KIND`; file type and size stay existing `PHOTO_TYPE` / `OVERSIZE` / `XML_UNREADABLE`
- failure modes: 2, 11 - `PhotoSymbols` miss with empty kind is recibo and typed fields, not
  `BAD_KIND`; `PhotoFields` is not used on that path
- idempotency and retry: existing - a retried POST creates a second SupportingDocument (#51 C44);
  no unique chave
- authorization: existing - `SupportingDocumentsController` focused organization; submitter insert
  unchanged
- concurrency and ordering: n/a - two in-flight inserts do not share a slot; each POST is its own
  row
- data lifecycle: n/a - no backfill of stored photos; existing rows keep their `kind`; nothing to
  migrate
- external-dependency failure: 2, 12 - Tesseract / decode miss is empty `PhotoSymbols`, which
  lands as recibo when kind was empty; identified / public miss stay the existing NF pipeline
  after kind is `nota_fiscal` (10)
- state transitions: 1, 2, 3, 7, 8 - empty posted kind becomes persisted `nota_fiscal` or
  `recibo`; posted kind does not change
- observability: existing - no new log of OCR text or photo bytes; `filter_parameters` unchanged

## Impact

| Front | What changes |
|---|---|
| domain | existing term: insert Tipo — documents-list-mask-and-actions 25 meant empty posted `kind` with a photo is `BAD_KIND`. Now empty `kind` with a photo or XML infers (1–6). Callers: `SupportingDocument#submit` `BAD_KIND` guard; `spec/requests/supporting_documents_spec.rb` `POST empty kind returns 422`; `.checks/documents-list-mask-and-actions.md` C25 |
| domain | existing term: Nota fiscal / Recibo on insert — kind came only from the select. Now it may come from XML presence or `PhotoSymbols` `chave` / `qr_url` when the select was empty. Callers: `#submit` extract_source gated on `next_kind == "nota_fiscal"` |
| stored data | nothing to migrate; `kind` enum unchanged; no new `fields_origin` |

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| 1. Empty insert kind is classified from the file using existing ports, then the existing submit pipeline | On `POST /supporting_documents` (and `SupportingDocument.insert` / `#submit`): if posted `kind` is `nota_fiscal` or `recibo`, use it. Else if an XML file is uploaded, `nota_fiscal`. Else if a photo is uploaded, run `PhotoSymbols.current.scan` on those bytes (same Fake/Real as #51); `nota_fiscal` when `chave` is present (44 digits) or `qr_url` is present, otherwise `recibo`. Else `BAD_KIND`. One scan per insert; NF field fill stays identified → public → `PhotoFields` → typed. Recibo stays typed. Photo bytes stay in-process. | Live preview when **Incluir foto** fires — user chose POST. Override posted kind — user `submit_blank_only`. Treat `PhotoFields` complete triple or `EMITENTE` as an NF signal — would classify a recibo with `R$` as NF once a later recibo parser exists; #51 already uses symbols for “this photo is a nota”. Filename heuristics (`danfe.jpg`) — not a document fact. Infer on PATCH — `KIND_LOCKED`. |

- Nothing else is hard to reverse. Where scan is called in `#submit` is placement. Door 1 reaches past this feature: a later “detect more kinds” copies XML-or-PhotoSymbols-then-default-recibo, not a cloud classifier and not overwriting a posted kind.

## Surface

| Route | In | Out | Status | Criteria |
|---|---|---|---|---|
| `POST /supporting_documents` | session, focus, existing fields; `kind` may be empty when `photo` or `xml` is present | SupportingDocument with inferred or posted `kind` | `302`, `422` | 1–11 |
| `GET /supporting_documents` | session, focus | list `[data-cell=kind]` | `200` | 1, 2 |

## Sources

- Chat 2026-10-15 (no URL) — quote: OCR when the user submits the photo file, to identify tipo (recibo or nota) and fields as they exist today; kind infer `submit_blank_only` (empty Tipo only; do not overwrite a chosen Tipo). **Incluir foto** is the file chip, not the form submit; the submit is **Incluir documento**.
- Cursor plan `ocr_e_tipo_documento` — POST-only; PNG/JPEG through existing OCR/symbols; XML → NF; symbols chave/QR → NF; else photo → recibo; no recibo field OCR; no PDF/WebP Real.
- `.tasks/documents-list-mask-and-actions.md` criterion 25 — **this cut supersedes** empty `kind` + photo → `BAD_KIND`; empty `kind` with no file stays 6.
- `.tasks/nfe-photo-extraction.md` — NF pipeline, recibo unread, Fake `PhotoSymbols` / `PhotoFields` on submit proofs; C7 posted recibo ignores decode.
- `.tasks/nfe-photo-ocr.md` — Tesseract in-process; recibo photos unread; PNG/JPEG only.
- `.tasks/keep-form-on-422.md` — Turbo Stream 422 keeps the form node (posted empty kind stays empty on that 422); HTML 422 echoes params.
- `GLOSSARY.md` / `CONTEXT.md` — Nota fiscal, Recibo, Supporting document; image PDF counts as a photo (decode miss → 2).

No design source. Verification stays on project profile `standard`.

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | open | After infer succeeds and a later validation 422s (`MISSING_FIELDS`), should HTML 422 select the inferred Tipo? | Existing keep-form-on-422: echo posted `kind` (still empty); Turbo Stream does not replace the form. Success path is 1–5. |
