# Coordinator batch document insert

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/coordinator-batch-document-insert.md` marks screen `documents` insert binding through `.impeccable/mocks/documents-batch-select.html`.

Sources:

- `.tasks/coordinator-batch-document-insert.md` - criteria 1–22, states, sweep, three doors, surface. Unresolved 1 stays transcribed (`No máximo 30 arquivos neste lote`; 31st file is not added). Nothing under Unresolved is settled while building
- Conversation 2026-10-19 - lote = N documents, one file each; coordinator laptop only; lock B with edit above the list, Arquivo under the photo, denser fields, secondary `Incluir este` / `Retirar`
- `.impeccable/mocks/documents-batch-select.html` - **binding for the interface**: screen `documents` insert (coordinator lote). Opened as a file in the repo
- `.impeccable/surfaces/impeccable-mocks-documents-batch-select-html.md` - direction contract for that mock. Opened as a file in the repo
- `DESIGN.md` - tokens only (secondary button: transparent, ink, `8px` `16px`, `4px`; margem only on error and Retirar). Opened as a file in the repo
- `GLOSSARY.md` Supporting document — photo and/or XML; new writes stay xor from `.tasks/document-file-first-insert.md`
- `.tasks/document-file-first-insert.md` - identify does not persist; kind inferred; one file on create; submitter may still identify and create one file

## Out of scope

- Submitter lote / `multiple` — this round is coordinator laptop only
- Pairing a photo and an XML of the same nota into one SupportingDocument
- Several files on one document (gallery)
- Changing PhotoSymbols, PhotoFields, PublicNfceConsulta, or identified SEFAZ consulta
- Persisting a draft blob before Incluir (identify stays non-persisting)
- Replacing a persisted file in place
- Justificativas (beyond proving they stay)
- Queue (prototype A) and dump-then-edit (prototype C)
- Settling Unresolved 1 beyond the transcribed 30-file cap

## Landing

Touches coordinator `GET /supporting_documents` insert HTML, the identify Stimulus lote, `POST /supporting_documents` Incluir este (Turbo, no full-page `302` that drops leftover Files), and new `POST /supporting_documents/batch`. Reuses `SupportingDocument.identify` / `.insert` / xor `NF_FILES`, per-file identify, `require_coordinator_organization` (`404`), Sem mês, edit, submitter one-file create. No schema change. No draft table.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Lote is not persisted | Identify stays `POST /supporting_documents/identify` (one file, no row). The browser keeps each `File` plus the last identify fields. Refresh of the page drops the lote | Draft SupportingDocument or object-store stash on drop — file-first already forbade persisting before Incluir; a new draft table would be a second lifecycle for the same evidence |
| Pronto subset is one transactional POST | `POST /supporting_documents/batch` multipart: repeated `documents[][file]`, `documents[][amount]`, `documents[][date]`, `documents[][payee]`, optional `documents[][chave]`, `documents[][observation]`. Kind inferred as today. All rows in that request persist or none do. Coordinator only (`404` otherwise) | N sequential `POST /supporting_documents` — create `302`s and would destroy leftover File objects. Persist-on-drop — Incluir prontos would disappear |
| Remainder must survive Incluir este | Incluir este persists one document and must not full-page `302` while other lote Files remain. Surgical update of Sem mês plus removal of that lote row. Incluir prontos may `302` only when no lote row remains; if Digitar/Erro remain, same surgical update as Incluir este | Always `302` after any include — the leftover recibo File cannot be restored |

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
- `SupportingDocument.insert` stays the per-row write. Batch all-or-none and missing amount/date/payee live in a new `insert_batch` (or equivalent) — own-layer table plus HTTP
- `#batch` HTTP contract: `302`/`200` turbo, `422`, submitter `404`, unauthenticated `302` `/login`
- `#create` Incluir este is a Turbo remainder path at HTTP; leftover Files are a browser API
- Lote assembly, row select, in-flight identify copy, in-flight disable, Retirar, 30-file cap are Stimulus. This repo has no JS unit runner. Closest analogue: `spec/system/document_identify_spec.rb`. C3–C11, C13 remainder, C15, C22, C23 are system proofs
- View HTML (empty coordinator lote drop vs submitter square) is a request-spec claim. This repo has no view specs

Cost: request examples for C1, C2, C12, C14, C16–C21; model examples for C12 all-or-none, C14 missing amount/date/payee, C19 xor; system examples for C3–C11, C13, C15, C22, C23. Without the model table, batch rollback would be one HTTP path. Without system proofs, the lote would be unproven.

## Screens (ui)

Opened: `.impeccable/mocks/documents-batch-select.html` (file), `.impeccable/surfaces/impeccable-mocks-documents-batch-select-html.md` (file), `DESIGN.md` tokens (file). The mock is a filled 14-file lote with a Digitar row selected; empty coordinator drop is criterion 1 (not drawn as its own mock).

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `documents` insert coordinator empty | First insert `h2` `Incluir documentos`; one `input[type=file][multiple]` accept includes `image/*` and `.xml`; no lote heading cells `Situação`; no `Incluir prontos`; Sem mês `Nenhum documento` C1 | Insert section is still first; Sem mês is the next `section` C1 | `documents` insert coordinator empty spacing, colour, type weight |
| `documents` insert coordinator lote | Lote head `Data`, `Favorecido`, `Tipo`, `Valor`, `Situação`; Situação `Pronto` / `Digitar` / `Erro`; selected `aria-selected="true"`; proof filename; `#arquivo` `XML` or `Foto` disabled; Tipo disabled; origins `XML autorizado` / `Digitado`; toolbar `Incluir prontos (`N`)` then `Incluir este` then `Retirar`; Digitar Valor `—`; identify wait `Identificando o arquivo…`; XML unread `O XML da nota fiscal não pôde ser lido` C3–C8, C22 | Edit split **above** the lote; `#arquivo` **inside** the proof aside, not the book column; Valor and Data share one row (two columns from `768px`); toolbar then lote sheet then Sem mês C7, C8, C22. `Incluir este` is `.ds-btn-secondary` (transparent, ink border, padding `8px` `16px`). `Retirar` is secondary plus margem border and text, same padding, no `data-turbo-confirm` C8, C11 | `documents` insert coordinator lote spacing, colour, type weight except the padding/border tokens named in C8 |
| `documents` insert submitter | `h2` `Incluir documento`; file input not `multiple`; wait copy `Inclua o documento. Valor, data e favorecido saem do arquivo.`; no `Incluir prontos` C2, C18 | Existing one-file proof square C2 | `documents` insert submitter spacing, colour, type weight |
| `documents` Sem mês | Empty `Nenhum documento`; with rows head `Data`, `Favorecido`, `Tipo`, `Valor`, `Ações` C1, C20 | Existing columns; lote include only **adds** persisted rows C9, C12, C13 | Sem mês spacing, colour, type weight |
| `documents` edit | Unchanged `Editar documento` C20 | Existing split C20 | `documents` edit spacing, colour, type weight |

## Checks

Criteria 1–22 map to C1–C22. Unresolved 1 stays transcribed as C23.

### S1 - Coordinator empty insert is a lote drop · 4 files · 168 KB · ~42k

**C1** - Given a signed-in coordinator of the focused organization with no SupportingDocument, when `GET /supporting_documents` runs, then the status is `200`, the insert `h2` is `Incluir documentos`, that section has one `input[type=file][multiple]` whose `accept` includes `image/*` and `.xml`, there is no lote sheet with heading cells `Situação`, there is no `Incluir prontos`, and Sem mês contains `Nenhum documento`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET coordinator empty insert is lote drop"`

**C2** - When that GET runs as a submitter with no document of their own, then the insert `h2` is `Incluir documento`, the file input is not `multiple`, the wait copy `Inclua o documento. Valor, data e favorecido saem do arquivo.` is present, and `Incluir prontos` is absent
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET submitter empty insert stays one-file square"`

### S2 - Identify many files without persisting · 6 files · 186 KB · ~47k

**C3** - Given two authorized XMLs, `vNF` `155.00` emitente `Padaria Central` `dhEmi` `2026-05-11` file `proc-nfe-padaria.xml` and `vNF` `89.40` emitente `Farmácia São José` `dhEmi` `2026-05-03` file `proc-nfe-farmacia.xml`, when that coordinator adds both through the insert file control, then SupportingDocument count stays `0`, a lote sheet is visible with head cells `Data`, `Favorecido`, `Tipo`, `Valor`, `Situação`, two rows include those filenames, after identify both rows show Situação `Pronto`, payees `Padaria Central` and `Farmácia São José`, amounts `R$ 155,00` and `R$ 89,40`, and Sem mês still contains `Nenhum documento`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "coordinator identify two XMLs fills lote without persisting"`

**C4** - Given a `.jpg` whose barcode, chave-digit, identified, public NFC-e, and field reading all miss, when that coordinator adds it to the lote, then count stays `0`, that row’s Tipo is `Recibo`, Situação is `Digitar`, Valor is `—`, and origin in the book when selected is `Digitado`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "coordinator photo miss lote row is Digitar Recibo"`

**C5** - If the coordinator adds an XML that `AuthorizedNfe.parse` rejects, then count stays `0`, that row’s Situação is `Erro`, the row includes `O XML da nota fiscal não pôde ser lido`, and the other lote rows are unchanged
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "coordinator unreadable XML is Erro and leaves other lote rows"`

**C6** - While `POST /supporting_documents/identify` for `danfe-mercado.jpg` is in flight, that lote row includes `Identificando o arquivo…`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "lote identify in flight shows Identificando o arquivo"`

**C23** - Until Unresolved 1 is answered: when the coordinator adds 31 files through the insert file control, the 31st is not added to the lote and `[data-notice="error"]` is `No máximo 30 arquivos neste lote`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "31st file is not added to the lote"`

### S3 - Selected row fills the compact book · 4 files · 175 KB · ~44k

**C7** - After criterion 3, when the coordinator selects the Padaria row, then that row is `aria-selected="true"`, the proof shows `proc-nfe-padaria.xml`, `#arquivo` sits under the proof (not in the book column) with value `XML` disabled, the book has Tipo `Nota fiscal` disabled, Valor `155,00`, Data `2026-05-11`, Favorecido `Padaria Central`, those three show origin `XML autorizado` and are disabled, and Valor and Data share one row (two columns from `768px`)
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "select Padaria fills compact book from XML"`

**C8** - After criterion 4, when that Digitar row is selected, then `#arquivo` under the proof is `Foto` disabled, Tipo is `Recibo` disabled, Valor, Data, and Favorecido are empty and enabled with origin `Digitado`, the toolbar has primary `Incluir prontos (` with a count `)`, secondary `Incluir este` (ink border, transparent fill, padding `8px` `16px`), and secondary `Retirar` (margem border and text, same padding)
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "select Digitar fills typed book and secondary toolbar"`

### S4 - Incluir este and Retirar · 5 files · 190 KB · ~48k

**C9** - After criterion 3 with Padaria selected, when `Incluir este` runs, then one SupportingDocument persists for Padaria (`kind` `nota_fiscal`, `amount_cents` `15500`, that XML, no photo), Sem mês includes `Padaria Central` and `R$ 155,00`, the lote no longer includes `proc-nfe-padaria.xml`, the Farmácia row remains in the lote with its file, and the response does not navigate away from `/supporting_documents` (no full-page `302` that drops the lote)
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir este persists Padaria and keeps Farmácia in lote"`

**C10** - When the Digitar row of criterion 4 is selected and Valor, Data, or Favorecido is empty, then activating `Incluir este` persists no SupportingDocument
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir este empty Digitar persists nothing"`

**C11** - After criterion 3, when `Retirar` runs on the Padaria row, then count stays `0`, that filename is gone from the lote, Farmácia remains, and there is no `data-turbo-confirm`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Retirar drops Padaria without confirm"`

### S5 - Incluir prontos · 5 files · 241 KB · ~60k

**C12** - After criterion 3 (both Pronto, Sem mês empty), when `Incluir prontos (2)` runs, then two SupportingDocuments persist those two XMLs, the response is `302` to `/supporting_documents` or a same-page update that leaves the lote empty, and the following GET Sem mês includes `Padaria Central`, `Farmácia São José`, `R$ 155,00`, and `R$ 89,40`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST batch two authorized XMLs persists both"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert_batch two XMLs persists both or none"`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir prontos two XMLs empties lote into Sem mes"`

**C13** - Given lote rows of twelve Pronto plus the Digitar of criterion 4 plus the Erro of criterion 5, when `Incluir prontos (12)` runs, then twelve SupportingDocuments persist, the Digitar and Erro filenames remain in the lote, and Sem mês includes those twelve payees and does not include the Digitar filename as a persisted row
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST batch twelve ready omits Digitar and Erro files"`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir prontos twelve leaves Digitar and Erro in lote"`

**C14** - If `Incluir prontos` is posted with one of the ready items missing amount, date, or payee, then no SupportingDocument from that request persists, status is `422`, `[data-notice="error"]` names that filename and `Faltam valor, data ou favorecido.`, and the lote still holds every file
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST batch missing amount 422 names filename"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert_batch missing amount persists none"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert_batch missing date persists none"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert_batch missing payee persists none"`
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "batch 422 keeps every lote file"`

**C15** - While that batch POST is in flight, `Incluir prontos` is disabled
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir prontos disabled while batch in flight"`

**C16** - When a submitter POSTs `/supporting_documents/batch`, then no SupportingDocument persists and the status is `404`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter POST batch persists none and 404"`

**C17** - When an unauthenticated request POSTs `/supporting_documents/batch` with a file, then no SupportingDocument persists and the status is `302` to `/login`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated POST batch 302 to login"`

### S6 - Unchanged one-file paths · 4 files · 178 KB · ~45k

**C18** - When a submitter POSTs `POST /supporting_documents` of authorized XML as today (one file, no lote), then one SupportingDocument persists on that Account and the response is `302` to `/supporting_documents`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter POST XML one-file persists 302"`

**C19** - Always, a new SupportingDocument from lote include is still photo XOR XML; posting both on one lote item is `422` `Envie a foto ou o XML` and persists no row from that request
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST batch photo and XML on one item 422 xor"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert_batch both photo and XML persists none"`

**C20** - Always, `GET /supporting_documents/:id/edit`, Sem mês columns, Justificativas, and submitter justify stay as they are after this ships
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit coordinator 200 Editar documento"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Sem mes head is Data Favorecido Tipo Valor Acoes"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET submitter justification amount fields have inputmode numeric"`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "POST justification of 200,00 with two documents redirects"`

**C21** - Unauthenticated `GET /supporting_documents` stays `302` to `/login`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET /supporting_documents responds 302 to /login"`

**C22** - The coordinator insert matches `.impeccable/mocks/documents-batch-select.html`: edit split above the lote, Arquivo under the proof, Valor/Data paired, toolbar `Incluir prontos` then secondary `Incluir este` then secondary `Retirar`, then the lote sheet, then Sem mês
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "coordinator lote arrangement matches batch-select mock"`

## Swept

- validation: C10, C14, C19, C23 — empty Digitar cannot Incluir este; batch missing amount/date/payee rolls back; xor file; 31st file refused
- failure modes: C5, C14 — unreadable XML is Erro on the row; batch `422` persists none of that request
- idempotency and retry: n/a — a second successful batch of the same files creates a second set of documents (existing: no unique chave). C15 only disables the control in flight
- authorization: C2, C16, C17, C18, C21 — submitter keeps one-file create; batch is coordinator; `require_coordinator_organization` pattern (`404`)
- concurrency and ordering: n/a — two coordinators including different files persist two sets; no new uniqueness. Identify order is the drop order (C3)
- data lifecycle: n/a — no draft table; Files live in the lote until Incluir; nothing to backfill
- external-dependency failure: C4, C5 — same identify fallbacks as today; miss is Digitar (C4), unreadable XML is Erro (C5)
- state transitions: C9, C11, C12, C13 — Incluir este leaves remainder; Retirar drops one file; Incluir prontos persists Pronto only
- observability: existing `:base` notice plus error toast on `422` (C14); no new metric

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| insert modes (2) | coordinator lote drop C1 · submitter one-file C2, C18 | - |
| lote Situação (3) | Pronto C3 · Digitar C4 · Erro C5 | Identifying is in-flight copy C6, not a persisted Situação |
| selected book (2) | XML Pronto C7 · Digitar typed C8 | - |
| lote mutations (3) | Incluir este remainder C9 · empty Incluir este C10 · Retirar C11 | - |
| `POST /supporting_documents/batch` who may call (3) | coordinator C12 · submitter `404` C16 · unauthenticated `302` `/login` C17 | - |
| `insert_batch` outcomes (5) | two XMLs persist C12 · twelve ready omit others C13 · missing amount C14 · missing date C14 · missing payee C14 | - |
| xor on lote item (1) | both photo and XML C19 | neither-file on batch is existing create `NF_FILES` via the same `insert` |
| designed screens this cut binds (1) | `documents` insert coordinator C1, C7, C8, C22 | - |
| designed screens this cut does not bind | — | prototypes A and C; submitter square is existing not this mock |
| `documents` insert visual (3 properties) | C8 padding/border via `.ds-btn-secondary` and margem on Retirar | spacing, colour, type weight on coordinator empty, coordinator lote (beyond C8 tokens), submitter, Sem mês, edit |

- Claims naming a status code, route or response shape: C1, C9, C12, C14, C16, C17, C18, C19, C21 — each has a proof that crosses the HTTP boundary (C9’s remainder is system because leftover Files are not on the server)
- No other check claims more than the single case its proof exercises except C14 (three missing-field members at the model) and C12 (HTTP + model + system), enumerated above

## Handoff

S1–S6 unique files (controller, model, index + insert ERBs, Stimulus, routes, request spec 152 KB, model spec, new system spec, mock) ≈ 272 KB · ~68k tokens. All stay on the documents insert surface. Under 150k, **one batch, no mid-feature handoff**.
