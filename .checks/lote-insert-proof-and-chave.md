# Lote insert proof and chave

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/lote-insert-proof-and-chave.md` marks screen `documents` insert (coordinator lote) binding through `_insert_book.html.erb` chave copy/hide, `DESIGN.md` The Chave Rule, and placement immediately below Tipo.

Sources:

- `.tasks/lote-insert-proof-and-chave.md` - criteria 1–13, skip extract on `insert_batch` only, chave under Tipo, object-URL proof, one door, Unresolved 1 stays transcribed (`Incluir este` does not skip). Nothing under Unresolved is settled while building
- Conversation 2026-10-20 - chave below Tipo; skip photo extract on persist when the lote already identified; still consult SEFAZ when NF has chave and no XML; object URL for the selected file
- `.tasks/coordinator-batch-document-insert.md` - lote is not persisted; batch multipart already named optional `documents[][chave]`; client never sent it
- `app/views/supporting_documents/_insert_book.html.erb` - **binding for chave copy and hide**: label `Chave de acesso (opcional)`; Recibo hides and disables `#chave`. Opened as a file in the repo
- `DESIGN.md` - **binding for the interface**: The Chave Rule (IBM Plex Mono / `font-mono` only on the access key). Opened as a file in the repo. Screen `documents` insert coordinator lote
- `app/javascript/controllers/document_identify_controller.js` `paintProof` - existing image `blob:` / PDF `embed` pattern the lote proof copies. Opened as a file in the repo
- `.tasks/nfe-photo-extraction.md` criterion 5 - photo-obtained chave beats typed chave on create; that is why this skip is `insert_batch` only (C3)

## Out of scope

- Stashing blobs or identified XML between identify and Incluir — lote stays unpersisted Files
- Skipping photo extract on `POST /supporting_documents` create / `Incluir este` / `apply`
- Parallel SEFAZ lookups inside `insert_batch`
- Changing the wait overlay, the 30-file cap, submitter one-file insert, Sem mês, or Editar
- Grouped chave display in the input (raw digits)
- Settling Unresolved 1 (Incluir este skip) — transcribed No

## Landing

Touches `SupportingDocument.insert_batch` (skip photo extract, still parse XML, still identified consulta when chave is present and there is no XML), coordinator lote book `#chave` under Tipo, and lote proof thumbs via object URL. Reuses `submit` persist, xor `NF_FILES`, identify pipeline, `document_identify_controller.js` `paintProof` pattern, `_insert_book.html.erb` chave copy. No schema change.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Photo extract is not a second identify inside `insert_batch` | `insert_batch` does not call `PhotoSymbols.current.scan`, `PhotoOcr.text`, `PublicNfceConsulta.current.fetch`, or `PhotoFields.current.read`. XML `AuthorizedNfe.parse` still runs. Identified consulta still runs when posted/derived chave is 44 digits, there is no parsed XML, and fields are not locked. `SupportingDocument.identify` and `POST /supporting_documents` `submit` keep today’s photo pipeline (photo chave still beats a typed chave on create) | Skip extract on every `submit` whenever `kind` is posted — `POST /supporting_documents` of a NF photo with `kind` and no `chave` must still read the photo. Stash bytes/XML from identify — lote-is-not-persisted already rejected a draft lifecycle |
| `insert_batch` skip is a `submit` keyword | `submit(..., skip_photo_extract: true)` from `insert_batch` only. Create, identify, and apply omit it | A second persist writer beside `submit` — xor, `CHAVE_DIGITS`, and identified consulta would fork |

- Nothing else in this change is hard to reverse

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

These rows are the bar I build under — approving the checklist is enough for that. Writing them into `.cursor/rules/rails.mdc` needs an explicit yes, and it lands as its own commit before the build. Without one I build under them and leave the file alone.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at its own layer **and** one request spec at HTTP | one asserted case per enumerated member at its own layer; status and who may call at the boundary | follow |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc`: decision at its own layer, one asserted case per enumerated member; HTTP also a request spec; system specs only when a request spec cannot settle the claim
- `insert_batch` skip of four photo ports is a decision table (skip vs still consult vs still parse XML) reached via `POST /supporting_documents/batch`
- `POST /supporting_documents` create still extracts — C3 at HTTP; photo-vs-typed chave remains existing create
- Lote chave paint, Recibo hide, FormData `documents[][chave]`, object-URL proof, Retirar revoke are Stimulus. This repo has no JS unit runner. Closest analogue: `spec/system/document_lote_spec.rb`

Cost: model + request for C1, C2, C13; request for C3; system for C4–C12; request for C6 persist `chave` nil. Without the model table, skip extract would be one HTTP path. Without system proofs, posted chave and proof thumbs would be unproven.

## Screens (ui)

Opened: `app/views/supporting_documents/_insert_book.html.erb` (file), `DESIGN.md` The Chave Rule (file), `app/javascript/controllers/document_identify_controller.js` `paintProof` (file). No new mock; arrangement is the conversation (chave immediately below Tipo) plus the existing lote split.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `documents` insert coordinator lote | `label[for=chave]` exactly `Chave de acesso (opcional)`; `input#chave` `font-mono` disabled; Recibo hides chave; selected image `img[alt]` `blob:`; selected PDF `embed[type="application/pdf"]` `blob:`; XML has no visible proof `img` C7–C12 | `input#chave` is the next named control after `select#kind` in document order C7. Recibo: chave not visible C8. Proof thumb lives in the proof aside | `documents` insert coordinator lote spacing, colour, type weight (`font-mono` class is C7; IBM Plex Mono stack is existing stylesheet) |

## Checks

Criteria 1–13 map to C1–C13. Unresolved 1 stays transcribed (No — only `insert_batch` skips).

### S1 - Incluir prontos does not read the photo again · 6 files · 297 KB · ~74k

**C1** - Given `insert_batch` of one JPEG `danfe.jpg`, `kind` `nota_fiscal`, `chave` `43260511222333000181550010000000011123456781`, `amount` `155,00`, `date` `2026-05-11`, `payee` `Padaria Central`, when it runs, then `PhotoSymbols.current` does not receive `scan`, `PhotoOcr` does not receive `text`, `PublicNfceConsulta.current` does not receive `fetch`, `PhotoFields.current` does not receive `read`, one SupportingDocument persists with that chave and `amount_cents` `15500`, and failure is `nil`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert_batch JPEG with chave skips photo extract"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST batch JPEG with chave persists without photo extract"`

**C2** - Given that organization has a valid A1 and identified consulta for that chave returns authorized XML of `vNF` `155.00` emitente `Padaria Central` `dhEmi` `2026-05-11`, when that same `insert_batch` runs, then that document has XML attached, `amount_cents` `15500`, and `payee` `Padaria Central`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert_batch JPEG with chave consulta attaches XML"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST batch JPEG with chave consulta attaches XML"`

**C3** - Always, `POST /supporting_documents` (not batch) of `kind` `nota_fiscal` and photo `danfe.jpg` with no `chave`, when `PhotoSymbols` returns that chave and identified consulta returns that XML, still persists that chave and attaches XML — photo extract on create is not this skip
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST photo chave with consulta XML fills fields and redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert photo chave with consulta XML persists 15500 and attaches xml"`

**C4** - After the coordinator lote has identified authorized XML `proc-nfe-padaria.xml` whose chave is `43260511222333000181550010000000011123456780`, when `Incluir prontos` runs, then that request’s FormData includes `documents[][chave]` equal to that chave
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir prontos posts documents chave from identified XML"`

**C5** - After that Padaria row is selected, when `Incluir este` runs, then `POST /supporting_documents` includes `chave` equal to that chave
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir este posts chave from identified XML"`

**C6** - After a Digitar recibo row is filled Pronto (`amount` `10,00`, `date` `2026-05-10`, `payee` `Mercado Bom Preço`) and included with `Incluir prontos`, then that request’s FormData has no `documents[][chave]` (or only blank values), and the persisted row has `chave` `nil`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir prontos recibo FormData has no chave"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST batch recibo without chave persists chave nil"`

### S2 - Chave sits under Tipo · 3 files · 37 KB · ~9k

**C7** - After criterion 4’s identify, when the Padaria row is selected, then the book has `label[for=chave]` whose text is exactly `Chave de acesso (opcional)`, `input#chave` is the next named control after `select#kind` in document order, its value is `43260511222333000181550010000000011123456780`, it is `disabled`, and its classes include `font-mono`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "select Padaria chave sits under Tipo"`

**C8** - After a `.jpg` whose barcode, chave-digit, identified, public NFC-e, and field reading all miss is selected, then Tipo is `Recibo`, the chave control is not visible, and `input#chave` is `disabled`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "select Digitar Recibo hides chave"`

### S3 - Selected proof shows the file · 3 files · 37 KB · ~9k

**C9** - Given that coordinator adds `empty.jpg`, when that lote row is selected, then the proof contains `img` whose `alt` is `empty.jpg` and whose `src` starts with `blob:`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "selected jpg proof is blob img"`

**C10** - After two authorized XMLs are in the lote and Padaria is selected, then that proof `img` is not visible
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "selected XML proof img is not visible"`

**C11** - Given that coordinator adds `danfe.pdf` (`application/pdf`), when that row is selected, then the proof contains `embed[type="application/pdf"]` that is visible and whose `src` starts with `blob:`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "selected pdf proof is blob embed"`

**C12** - After criterion 9 with an XML still in the lote, when `Retirar` runs on `empty.jpg`, then that filename is gone from the lote and the selected XML row’s proof `img` is not visible
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Retirar jpg leaves XML proof without img"`

**C13** - Always, a new SupportingDocument from lote include is still photo XOR XML; posting both on one lote item is `422` `Envie a foto ou o XML` and persists no row from that request
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST batch photo and XML on one item 422 xor"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert_batch both photo and XML persists none"`

## Swept

- validation: C6, C13 — recibo stores `chave` `nil`; xor file unchanged. 44-digit chave when present without a photo chave is existing `CHAVE_DIGITS` on `submit`
- failure modes: existing — `insert_batch` still returns the first `:base` and persists none of that request (including a bad chave)
- idempotency and retry: existing — a second successful batch of the same files creates a second set (no unique chave)
- authorization: existing — `require_coordinator_organization` on `batch`; create still coordinator or submitter of the focused organization
- concurrency and ordering: existing — `Incluir prontos` stays disabled while the batch POST is in flight; two tabs are two lotes
- data lifecycle: C9, C11, C12 — object URLs live only for lote items; Retirar drops that proof. Nothing to backfill
- external-dependency failure: C2 — identified consulta still runs on `insert_batch` when chave is present and there is no XML; consulta miss stays existing persist of posted amount/date/payee
- state transitions: n/a — Situação Pronto / Digitar / Erro and identify-does-not-persist are unchanged
- observability: existing — overlay copy `Incluindo documentos…`; no new metric

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| photo extract ports skipped on `insert_batch` (4) | `PhotoSymbols.scan` C1 · `PhotoOcr.text` C1 · `PublicNfceConsulta.fetch` C1 · `PhotoFields.read` C1 | - |
| `insert_batch` still does (2) | identified consulta when chave and no XML C2 · XML `AuthorizedNfe.parse` existing two-XML batch | - |
| create still extracts (1) | `POST /supporting_documents` photo no typed chave C3 | - |
| posted chave (3) | XML Incluir prontos `documents[][chave]` C4 · Incluir este `chave` C5 · recibo absent/blank and persisted `nil` C6 | - |
| lote chave chrome (2) | NF under Tipo C7 · Recibo hidden+disabled C8 | - |
| lote proof thumbs (4) | jpg `blob:` img C9 · XML no img C10 · pdf `embed` C11 · Retirar drops jpg thumb C12 | - |
| xor on lote item (1) | both photo and XML C13 | - |
| designed screens this cut binds (1) | `documents` insert coordinator lote C7–C12 | - |
| `documents` insert coordinator lote visual (3 properties) | `font-mono` class C7 | spacing, colour, type weight |

- Claims naming a status code, route or response shape: C1 (batch persist), C2, C3, C5, C6, C13 — each has a proof that crosses the HTTP boundary except C1’s skip-ports half (model). C3, C5, C6 persist, C13 sit at HTTP
- No other check claims more than the single case its proof exercises

## Handoff

S1 files (model, controller, lote JS, model spec, request spec, system spec) ≈ 297 KB · ~74k. S2+S3 add lote ERB and more system examples on the same surface (~9k each, overlapping). S1–S3 unique files ≈ 301 KB · ~75k tokens, all on documents insert. Under 150k, **one batch, no mid-feature handoff**.
