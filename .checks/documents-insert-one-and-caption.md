# Documents insert: one-file chrome, proof caption, readonly Tipo

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/documents-insert-one-and-caption.md` marks screen `documents` insert binding through `.impeccable/mocks/documents-insert-refine.html` (scenes `Um arquivo`, `XML (tipo travado)`, `Lote`).

Sources:

- `.tasks/documents-insert-one-and-caption.md` - criteria 1–18, states, sweep, no doors, Unresolved empty. Nothing under Unresolved is settled while building
- Conversation 2026-10-21 - one file is simple include; proof caption `FOTO`/`XML` bold uppercase before filename; Tipo readonly when it cannot change; no `#arquivo` field
- `.impeccable/mocks/documents-insert-refine.html` - **binding for the interface**: screen `documents` insert (coordinator). Opened as a file in the repo. Scenes `Um arquivo`, `XML (tipo travado)`, `Lote`. Where this mock’s idle `h2` is `Incluir documento` or scene `Um arquivo` paints a changeable `select#kind`, the task is the record: empty drop stays `Incluir documentos` (C1); after identify Tipo is a readonly `input#kind` and KIND_LOCKED stays (C13, C14). Mock control `Incluir outro arquivo` is not a criterion
- `.impeccable/surfaces/impeccable-mocks-documents-insert-refine-html.md` - direction contract for that mock. Opened as a file in the repo
- `.tasks/coordinator-batch-document-insert.md` - lote B for N files; C7 `#arquivo` and always-on lote toolbar are superseded for N=1 and for the Arquivo field / caption on every N
- `.tasks/lote-insert-proof-and-chave.md` - proof object-URL thumbs; chave immediately below Tipo (`#kind` is now an `input`)
- `DESIGN.md` - primary button caixa / sheet / `8px` `16px` / `4px`; The Sentence Case Rule does not apply to the `FOTO`/`XML` stamp
- `GLOSSARY.md` Supporting document — photo XOR XML on new writes

## Out of scope

- Submitter one-file insert chrome (caption, Arquivo field, Tipo select) — submitter already has `Incluir documento`
- `GET /supporting_documents/:id/edit` proof caption and Tipo — C17 keeps it
- Letting Tipo change after identify — `SupportingDocument::KIND_LOCKED` and infer-on-blank stay
- Changing `POST /supporting_documents/batch` shape, the 30-file cap, xor photo/XML, or identify-does-not-persist
- Lote sheet cell copy (Favorecido second line) beyond hiding the sheet when N is 1
- Queue (A) and dump-then-edit (C)
- Mock idle heading `Incluir documento` and mock unlocked Tipo select on `Um arquivo` — superseded by the task
- Mock `Incluir outro arquivo` on the one-file toolbar

## Landing

Touches coordinator `document-lote` insert HTML and Stimulus (`render` / `renderToolbar` / `renderSheet` / `paintBook`). Reuses identify, `POST /supporting_documents/batch`, xor SupportingDocument, submitter `_insert_book` / `_insert_preview`, edit page. No schema change.

None — nothing here is one-way. Same identify, same `POST /supporting_documents/batch`, same xor SupportingDocument. The chrome, caption, and readonly Tipo reverse by restoring the previous markup.

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
- Chrome branch `N=0` / `N=1` / `N≥2` lives in Stimulus. This repo has no JS unit runner. Closest analogue: `spec/system/document_lote_spec.rb`
- Persist of one ready file (C3, C5) and of two (C15) already sit at `insert_batch` / HTTP; this cut does not add a persist table
- Empty GET, submitter GET, unauthenticated GET, edit, Sem mês, Justificativas are request-spec claims

Cost: request proofs for C1, C16, C17, C18; system proofs for C2–C15 chrome and persist-from-UI; existing batch request/model for C15 persist. Without system proofs, one-file vs lote chrome would be unproven.

## Screens (ui)

Opened: `.impeccable/mocks/documents-insert-refine.html` (file), `.impeccable/surfaces/impeccable-mocks-documents-insert-refine-html.md` (file), `DESIGN.md` tokens (file). Four mock scenes are states of one screen.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `documents` insert coordinator empty | Insert `h2` `Incluir documentos`; one `input[type=file][multiple]`; no lote heading cells `Situação`; no `Incluir prontos` C1 | Insert section first; Sem mês next `section` (existing) | `documents` insert coordinator empty spacing, colour, type weight |
| `documents` insert coordinator one file | `h2` `Incluir documento`; no Situação sheet; no `Incluir prontos` / `Incluir este` / `Retirar`; proof `Limpar`; primary `Incluir documento` `.ds-btn-primary`; caption `FOTO`/`XML` in `strong` then ` - ` filename; no `label[for=arquivo]` / `input#arquivo`; `input#kind` readonly; no visible `select#kind`; identifying copy without sheet; unreadable XML notice plus `Limpar` C2–C5, C8–C11, C13, C14 | Split proof left / 28rem book right from `768px`. Caption is **under** the image (or XML has no visible `img`) inside the proof, Limpar in that caption row. Book: Tipo then `#chave` (NF) then Valor/Data pair then Favorecido. Toolbar is primary only — no lote sheet | `documents` insert coordinator one file spacing, colour, type weight except `font-weight` `600` on the stamp (C10, C11) and primary padding `8px` `16px` (C2) |
| `documents` insert coordinator lote N≥2 | `h2` `Incluir documentos`; lote head `Data`, `Favorecido`, `Tipo`, `Valor`, `Situação`; toolbar primary `Incluir prontos (`N`)` then secondary `Incluir este` then secondary `Retirar`; no `Limpar` in the proof; same caption and no `#arquivo`; selected `aria-selected="true"`; XML proof `img` not visible C6, C7, C12, C15 | Edit split **above** the lote; toolbar then lote sheet then Sem mês. Caption still under the image in the proof | `documents` insert coordinator lote spacing, colour, type weight |
| `documents` insert submitter | `h2` `Incluir documento`; file input not `multiple`; wait copy; no `Incluir prontos` C16 | Existing one-file proof square | `documents` insert submitter spacing, colour, type weight |
| `documents` Sem mês | Head `Data`, `Favorecido`, `Tipo`, `Valor`, `Ações` C17 | Existing columns; include only **adds** persisted rows C3, C15 | Sem mês spacing, colour, type weight |
| `documents` edit | `h1` `Editar documento` C17 | Existing split | `documents` edit spacing, colour, type weight |

## Checks

Criteria 1–18 map to C1–C18.

### S1 - One file is the simple include · 4 files · 47 KB · ~12k

**C1** - Given a signed-in coordinator of the focused organization with no SupportingDocument and no files in the lote, when `GET /supporting_documents` runs, then the status is `200`, the insert `h2` is `Incluir documentos`, that section has one `input[type=file][multiple]`, there is no lote sheet with heading cells `Situação`, and there is no `Incluir prontos`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET coordinator empty insert is lote drop"`

**C2** - Given that coordinator adds one authorized XML `proc-nfe-padaria.xml` (`vNF` `155.00` emitente `Padaria Central` `dhEmi` `2026-05-11`), when identify finishes, then the insert `h2` is `Incluir documento`, there is no lote sheet with heading cells `Situação`, there is no `Incluir prontos`, there is no `Incluir este`, there is no `Retirar`, the proof includes `Limpar`, and the primary control is `Incluir documento` with class `ds-btn-primary` (caixa fill, sheet text, padding `8px` `16px`)
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "one XML is simple include chrome"`

**C3** - When that `Incluir documento` runs, then one SupportingDocument persists for Padaria (`kind` `nota_fiscal`, `amount_cents` `15500`, that XML, no photo), Sem mês includes `Padaria Central` and `R$ 155,00`, the empty drop is visible again (`h2` `Incluir documentos`), and the response does not navigate away from `/supporting_documents` as a full-page `302` that would be needed only if lote remainder existed
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir documento one XML persists Padaria and empty drop"`

**C4** - After criterion 2, when `Limpar` runs, then SupportingDocument count stays `0`, the empty drop of criterion 1 is visible, and `Limpar` is gone
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Limpar one XML returns empty drop"`

**C5** - Given that coordinator adds one `.jpg` whose barcode, chave-digit, identified, public NFC-e, and field reading all miss, when Valor, Data, or Favorecido is empty, then activating `Incluir documento` persists no SupportingDocument
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir documento empty Digitar persists nothing"`

**C6** - After criterion 2, when that coordinator adds a second authorized XML `proc-nfe-farmacia.xml` (`vNF` `89.40` emitente `Farmácia São José` `dhEmi` `2026-05-03`), then the insert `h2` is `Incluir documentos`, a lote sheet is visible with head cells `Data`, `Favorecido`, `Tipo`, `Valor`, `Situação` and two rows for those filenames, the toolbar is primary `Incluir prontos (` with a count `)` then secondary `Incluir este` then secondary `Retirar`, and the proof does not include `Limpar`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "second XML opens lote chrome"`

**C7** - After criterion 6 with both Pronto, when `Retirar` runs on the Farmácia row, then one file remains, the insert `h2` is `Incluir documento`, there is no lote sheet with heading cells `Situação`, there is no `Incluir prontos`, and `Limpar` plus primary `Incluir documento` are back
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Retirar down to one restores simple include"`

**C8** - While `POST /supporting_documents/identify` for the only file `danfe-mercado.jpg` is in flight, then the page includes `Identificando o arquivo…`, there is no lote sheet with heading cells `Situação`, and SupportingDocument count stays `0`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "one file identify in flight has no Situacao sheet"`

**C9** - If the only file added is an XML that `AuthorizedNfe.parse` rejects, then count stays `0`, `[data-notice="error"]` or the error toast includes `O XML da nota fiscal não pôde ser lido`, there is no lote sheet with heading cells `Situação`, and `Limpar` is present
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "one unreadable XML has Limpar and no Situacao sheet"`

### S2 - Proof caption is one line · 3 files · 47 KB · ~12k

**C10** - After criterion 5’s Digitar row is on screen (one file), then the proof has no `label[for=arquivo]` and no `input#arquivo`, the caption under the image is one line whose first word is `FOTO` inside `strong` (computed `font-weight` `600`) followed by ` - ` and `empty.jpg` (or that file’s name), and the proof does not contain `sem leitura nesta versão` or a separate line whose only text is `Recibo` or `Nota fiscal`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "one jpg caption is FOTO filename under image"`

**C11** - After criterion 2, then that caption is `XML` inside `strong` (weight `600`) followed by ` - ` and `proc-nfe-padaria.xml`, with no `input#arquivo`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "one XML caption is XML filename"`

**C12** - After criterion 6, when the coordinator selects the Padaria row, then criterion 11’s caption still holds on the selected proof, the Padaria row is `aria-selected="true"`, and the proof `img` is not visible (XML). The object-URL thumb for a selected image or PDF stays as `.tasks/lote-insert-proof-and-chave.md` 9–11
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "lote selected Padaria caption is XML filename"`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "selected jpg proof is blob img"`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "selected XML proof img is not visible"`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "selected pdf proof is blob embed"`

### S3 - Tipo is a readonly field after identify · 4 files · 47 KB · ~12k

**C13** - After criterion 2, then the book has `label[for=kind]` `Tipo`, `input#kind` with value `Nota fiscal` is `readonly` and not `disabled`, there is no visible `select#kind`, and `input#chave` is the next named control after `#kind` in document order
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "one XML Tipo is readonly input then chave"`

**C14** - After criterion 5, then `input#kind` is `readonly` with value `Recibo`, Valor, Data, and Favorecido are empty and enabled with origin `Digitado`, and the chave control is not visible
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "one jpg Tipo is readonly Recibo and hides chave"`

**C15** - After criterion 6 (both Pronto), when `Incluir prontos (2)` runs, then two SupportingDocuments persist those two XMLs and Sem mês includes `Padaria Central`, `Farmácia São José`, `R$ 155,00`, and `R$ 89,40`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir prontos two XMLs empties lote into Sem mes"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST batch two authorized XMLs persists both"`

**C16** - When that GET runs as a submitter with no document of their own, then the insert `h2` is `Incluir documento`, the file input is not `multiple`, the wait copy `Inclua o documento. Valor, data e favorecido saem do arquivo.` is present, and `Incluir prontos` is absent
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET submitter empty insert stays one-file square"`

**C17** - Always, `GET /supporting_documents/:id/edit`, Sem mês columns, Justificativas, and submitter justify stay as they are after this ships
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit coordinator 200 Editar documento"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Sem mes head is Data Favorecido Tipo Valor Acoes"`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "coordinator GET /supporting_documents includes justification and member payees"`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "submitter GET /supporting_documents omits another Account justification"`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "POST justification of 200,00 with two documents redirects"`

**C18** - Unauthenticated `GET /supporting_documents` stays `302` to `/login`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET /supporting_documents responds 302 to /login"`

## Swept

- validation: C5 — empty Digitar cannot include; xor and batch missing amount/date/payee stay existing
- failure modes: C9 — unreadable XML is the existing notice/toast; no lote sheet when N is 1
- idempotency and retry: n/a — a second successful include of the same file still creates a second document (existing: no unique chave)
- authorization: C16, C18 — submitter keeps one-file create; unauthenticated `302` `/login`; batch stays coordinator
- concurrency and ordering: n/a — chrome only; existing in-flight disable of `Incluir prontos` is unchanged for N≥2
- data lifecycle: n/a — no draft table; Files live in the lote until Incluir, Limpar, or Retirar; nothing to backfill
- external-dependency failure: C8, C9 — same identify as today; in-flight copy; unreadable XML
- state transitions: C2, C3, C4, C6, C7, C15 — one file is simple include; two files open lote B; Retirar to one restores simple
- observability: existing `:base` notice plus error toast on identify `422` (C9); no new metric

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| coordinator insert N (3) | empty C1 · one file C2 · N≥2 C6 | - |
| one-file exits (3) | Incluir documento C3 · Limpar C4 · Retirar down to one C7 | - |
| caption stamps (2) | `FOTO` C10 · `XML` C11 · lote selected XML C12 | - |
| Tipo after identify (2) | `Nota fiscal` readonly C13 · `Recibo` readonly C14 | - |
| persist from this chrome (2) | one XML C3 · two XMLs C15 · empty Digitar none C5 | - |
| other roles (3) | submitter insert C16 · unauthenticated GET C18 · edit / Sem mês / Justificativas C17 | - |
| designed scenes (4) | Vazio C1 · Um arquivo C2, C10, C14 · XML (tipo travado) C2, C11, C13 · Lote C6, C12 | mock idle `h2` `Incluir documento`; mock unlocked `select#kind` on Um arquivo |
| lote proof thumbs (3) | jpg C12 · XML no img C12 · pdf C12 | - |

- Claims naming a status code, route or response shape: C1, C3 (no remainder `302`), C16, C17, C18, C15 HTTP — each has a proof that crosses the boundary. C2–C14 chrome sit in the browser
- No other check claims more than the single case its proof exercises

## Handoff

S1–S3 unique files (`document_lote_controller.js`, `_insert_lote.html.erb`, `spec/system/document_lote_spec.rb`) = 47 KB · ~12k tokens, all on coordinator insert. Request proofs reuse existing examples. Under 150k, **one batch, no mid-feature handoff**.
