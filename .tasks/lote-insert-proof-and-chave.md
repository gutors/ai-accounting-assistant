# Lote insert proof and chave

> Build this with **tlc-implement**. Profile **`ui`**: screen `documents` insert for the
> coordinator lote (compact book + proof). Binding copy and type for chave are
> `app/views/supporting_documents/_insert_book.html.erb` (`Chave de acesso (opcional)`,
> `font-mono`) and `DESIGN.md` The Chave Rule. Placement is the conversation below Tipo.
> Proof thumbs follow the existing one-file object-URL pattern in
> `app/javascript/controllers/document_identify_controller.js`. Nothing under `Unresolved`
> gets settled while building.

## Intent

The coordinator lote on `GET /supporting_documents` already identifies each dropped file and
holds the `File` in the browser. `Incluir prontos` posts every ready file again to
`POST /supporting_documents/batch`. `SupportingDocument.insert_batch` then runs `submit` per
row, which for a nota-fiscal photo still runs `PhotoSymbols` / `PhotoOcr` / public NFC-e /
`PhotoFields` even though identify just did that work. Identified `chave` is kept on the
lote item in JavaScript and never appended (`documents[][chave]` is absent;
`Incluir este` also omits `chave`). The compact proof is filename text only — no `<img>` or
PDF `<embed>`. The conversation that produced this task gives no conversion figure; the
cost is waiting on a second full photo pipeline for a pile of about 10 to 20 files, a proof
the coordinator cannot read, and notes that persist without the chave identify already had.

When this ships, `Incluir prontos` still posts the files, but `insert_batch` does not read
the photo again. A posted 44-digit chave still starts identified consulta when there is no
XML, so the note can attach. The book shows `Chave de acesso (opcional)` immediately below
Tipo (hidden for Recibo). The selected proof shows the image or PDF from an object URL.
Submitter one-file insert is unchanged.

13 criteria in 3 slices · 1 one-way door · 1 open, of which 0 block

## Criteria

### Incluir prontos does not read the photo again

1. Given `insert_batch` of one JPEG `danfe.jpg`, `kind` `nota_fiscal`, `chave`
   `43260511222333000181550010000000011123456781`, `amount` `155,00`, `date` `2026-05-11`,
   `payee` `Padaria Central`, when it runs, then `PhotoSymbols.current` does not receive
   `scan`, `PhotoOcr` does not receive `text`, `PublicNfceConsulta.current` does not receive
   `fetch`, `PhotoFields.current` does not receive `read`, one SupportingDocument persists
   with that chave and `amount_cents` `15500`, and failure is `nil`.
2. Given that organization has a valid A1 and identified consulta for that chave returns
   authorized XML of `vNF` `155.00` emitente `Padaria Central` `dhEmi` `2026-05-11`, when
   that same `insert_batch` runs, then that document has XML attached, `amount_cents`
   `15500`, and `payee` `Padaria Central`.
3. Always, `POST /supporting_documents` (not batch) of `kind` `nota_fiscal` and photo
   `danfe.jpg` with no `chave`, when `PhotoSymbols` returns that chave and identified
   consulta returns that XML, still persists that chave and attaches XML — photo extract on
   create is not this skip.
4. After the coordinator lote has identified authorized XML `proc-nfe-padaria.xml` whose
   chave is `43260511222333000181550010000000011123456780`, when `Incluir prontos` runs,
   then that request’s FormData includes `documents[][chave]` equal to that chave.
5. After that Padaria row is selected, when `Incluir este` runs, then
   `POST /supporting_documents` includes `chave` equal to that chave.
6. After a Digitar recibo row is filled Pronto (`amount` `10,00`, `date` `2026-05-10`,
   `payee` `Mercado Bom Preço`) and included with `Incluir prontos`, then that request’s
   FormData has no `documents[][chave]` (or only blank values), and the persisted row has
   `chave` `nil`.

### Chave sits under Tipo

7. After criterion 4’s identify, when the Padaria row is selected, then the book has
   `label[for=chave]` whose text is exactly `Chave de acesso (opcional)`, `input#chave` is
   the next named control after `select#kind` in document order, its value is
   `43260511222333000181550010000000011123456780`, it is `disabled`, and its classes include
   `font-mono`.
8. After a `.jpg` whose barcode, chave-digit, identified, public NFC-e, and field reading
   all miss is selected, then Tipo is `Recibo`, the chave control is not visible, and
   `input#chave` is `disabled`.

### Selected proof shows the file

9. Given that coordinator adds `empty.jpg`, when that lote row is selected, then the proof
   contains `img` whose `alt` is `empty.jpg` and whose `src` starts with `blob:`.
10. After two authorized XMLs are in the lote and Padaria is selected, then that proof
    `img` is not visible.
11. Given that coordinator adds `danfe.pdf` (`application/pdf`), when that row is selected,
    then the proof contains `embed[type="application/pdf"]` that is visible and whose `src`
    starts with `blob:`.
12. After criterion 9 with an XML still in the lote, when `Retirar` runs on `empty.jpg`,
    then that filename is gone from the lote and the selected XML row’s proof `img` is not
    visible.
13. Always, a new SupportingDocument from lote include is still photo XOR XML; posting both
    on one lote item is `422` `Envie a foto ou o XML` and persists no row from that request.

## Out of scope

- Stashing blobs or identified XML between identify and Incluir — lote stays unpersisted
  Files in the browser (`.tasks/coordinator-batch-document-insert.md` Decided)
- Skipping photo extract on `POST /supporting_documents` create / `Incluir este` / `apply`
  — those keep today’s `submit` pipeline so photo chave still wins over a typed chave
- Parallel SEFAZ lookups inside `insert_batch`
- Changing the wait overlay, the 30-file cap, submitter one-file insert, Sem mês, or Editar
- Grouped chave display in the input (raw digits, same as insert/Editar `#chave`)

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `documents` insert (coordinator lote) | empty state | existing — drop is empty; editor (book, proof, chave) is `hidden` until a file is in the lote |
| screen `documents` insert (coordinator lote) | loading | existing — `wait:start` copy `Identificando o arquivo…` / `Incluindo documentos…` |
| screen `documents` insert (coordinator lote) | error state | existing — `422` `[data-notice="error"]` plus error toast; invalid chave still `Informe a chave de acesso com 44 dígitos` |
| screen `documents` insert (coordinator lote) | unauthorised | existing — batch `404` for submitter; unauthenticated `302` `/login` |
| screen `documents` insert (coordinator lote) | density and ordering | 7, 8, 9, 10, 11 — chave immediately after Tipo; Recibo hides chave; proof image/PDF object URL; XML has no thumb |
| screen `documents` insert (coordinator lote) | destructive action confirms | existing — `Retirar` has no `data-turbo-confirm` |
| API `POST /supporting_documents/batch` | who may call | existing — coordinator only |
| API `POST /supporting_documents/batch` | response shape | existing — turbo replace Sem mês or `302`; `422` rolls the request back |
| API `POST /supporting_documents/batch` | error shape and codes | existing — `422` with `:base` notice; `404`; `302` `/login` |
| API `POST /supporting_documents/batch` | versioning / rate limit | n/a — same unversioned cookie session as the rest of the app |
| API `POST /supporting_documents` | Incluir este chave | 5 |
| API `POST /supporting_documents` | photo extract without typed chave | 3 |
| document (agent task) | structure / next | n/a — this file is the record; no user-facing copy doc |

## Swept

- validation: 6, 13 — recibo stores `chave` `nil`; xor file unchanged. 44-digit chave when present without a photo chave is existing `CHAVE_DIGITS` on `submit`
- failure modes: existing — `insert_batch` still returns the first `:base` and persists none of that request (including a bad chave)
- idempotency and retry: existing — a second successful batch of the same files creates a second set (no unique chave)
- authorization: existing — `require_coordinator_organization` on `batch`; create still coordinator or submitter of the focused organization
- concurrency and ordering: existing — `Incluir prontos` stays disabled while the batch POST is in flight; two tabs are two lotes
- data lifecycle: 9, 11, 12 — object URLs live only for lote items; Retirar drops that proof. Nothing to backfill
- external-dependency failure: 2 — identified consulta still runs on `insert_batch` when chave is present and there is no XML; consulta miss stays existing persist of posted amount/date/payee
- state transitions: n/a — Situação Pronto / Digitar / Erro and identify-does-not-persist are unchanged
- observability: existing — overlay copy `Incluindo documentos…`; no new metric

## Impact

| Front | What changes |
|---|---|
| domain | existing term: `insert_batch` already accepted optional `chave` per item and still ran full `submit` photo extract. It now skips photo extract (`PhotoSymbols`, `PhotoOcr`, `PublicNfceConsulta`, `PhotoFields`) and still parses uploaded XML and still consults SEFAZ when a chave is present and there is no XML. Callers: `SupportingDocumentsController#batch` only |
| domain | existing term: lote item already had a `chave` string in Stimulus that was never painted or posted. It is now the book field and the include payload. Callers: `document_lote_controller.js`, `_insert_lote.html.erb` |
| stored data | nothing to migrate |

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| Photo extract is not a second identify inside `insert_batch` | `insert_batch` does not call `PhotoSymbols.current.scan`, `PhotoOcr.text`, `PublicNfceConsulta.current.fetch`, or `PhotoFields.current.read`. XML `AuthorizedNfe.parse` still runs. Identified consulta still runs when posted/derived chave is 44 digits, there is no parsed XML, and fields are not locked. `SupportingDocument.identify` and `POST /supporting_documents` `submit` keep today’s photo pipeline (photo chave still beats a typed chave on create) | Skip extract on every `submit` whenever `kind` is posted — `POST /supporting_documents` of a NF photo with `kind` and no `chave` must still read the photo (existing nfe-photo-extraction). Stash bytes/XML from identify — lote-is-not-persisted already rejected a draft lifecycle |

## Surface

| Route | In | Out | Status | Criteria |
|---|---|---|---|---|
| `POST /supporting_documents/batch` | `documents[]` file, kind, amount, date, payee, optional chave, optional observation | N rows or none | `200` turbo, `302`, `422`, `404`, `302` `/login` | 1, 2, 4, 6, 13 |
| `POST /supporting_documents` | file, kind, amount, date, payee, optional chave, optional observation | one row or 422; lote remainder stays | `200` turbo, `302`, `422` | 3, 5 |
| `GET /supporting_documents` | session · focus | coordinator lote book includes `#chave` under Tipo; proof thumb for the selected File | `200` | 7–12 |

## Sources

- Conversation 2026-10-20 — three lote gaps in one cycle: Incluir prontos slowness, proof images, chave in multi-insert. Quote: “pensei em colocar abaixo do tipo de Arquivo para compor melhor o espaço na tela”; skip photo extract on persist when the lote already identified; still consult SEFAZ when NF has chave and no XML; object URL for the selected file
- `.tasks/coordinator-batch-document-insert.md` — lote is not persisted; batch multipart already named optional `documents[][chave]`; client never sent it
- `app/views/supporting_documents/_insert_book.html.erb` — **binding for chave copy and hide**: label `Chave de acesso (opcional)`; Recibo hides and disables `#chave`
- `DESIGN.md` — The Chave Rule: IBM Plex Mono only on the access key
- `app/javascript/controllers/document_identify_controller.js` `paintProof` — existing image `blob:` / PDF `embed` pattern the lote proof copies
- `.tasks/nfe-photo-extraction.md` criterion 5 — photo-obtained chave beats typed chave on create; that is why this skip is `insert_batch` only (3)

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | open | Does `Incluir este` (`POST /supporting_documents`) also skip photo extract when it posts a 44-digit chave? | No. Only `insert_batch` skips (Decided). One-file include keeps create’s pipeline so photo-vs-typed chave on create stays intact |
