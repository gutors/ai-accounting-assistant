# File-first supporting document insert

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/document-file-first-insert.md` marks screens `documents` insert and `documents` edit binding.

Sources:

- `.tasks/document-file-first-insert.md` - criteria 1–24, states, sweep, three doors, surface. Unresolved 1 stays transcribed (`Consulta NFC-e` for `nfc_e_public`). Nothing under Unresolved is settled while building
- `.impeccable/mocks/documents-intake.html` - **binding for the interface**: screen `documents` insert. Opened as a file in the repo
- `.impeccable/mocks/document-edit.html` - **binding for the interface**: screen `documents` edit. Opened as a file in the repo. Origin stamps on Valor/Data/Favorecido are criterion 22 / design.md (the mock omits them; the task wins)
- `.specs/features/visual-identity/design.md` section `documents` - **binding for the interface**. Opened as a file in the repo. Already amended by the task (proof square, xor file, edit without XML)
- `DESIGN.md` - tokens only (ledger paper, caixa, margem, IBM Plex)
- Existing `SupportingDocument#submit` extract order — identify reuses it; does not restipulate decode

## Out of scope

- Changing how PhotoSymbols, PhotoFields, PublicNfceConsulta, or identified SEFAZ consulta read a file
- Justificativas copy, list columns, and the submitter justify form
- Replacing a persisted file in place — delete and insert remains the path
- Backfilling or splitting legacy rows that already have both photo and XML
- Client-side XML parse or OCR in Stimulus
- Open Finance, NF-e issuance, accountant login
- Settling Unresolved 1 beyond the transcribed `Consulta NFC-e`

## Landing

Touches `SupportingDocument.insert` / `#submit` (infer kind; xor file; PATCH xml always locked), `SupportingDocumentsController#identify` plus create/edit/update, insert and edit ERB, `config/routes.rb`, and a Stimulus identify/Limpar controller. Reuses extract order, `XML_UNREADABLE`, `XML_LOCKED`, Turbo Stream 422 notice+toast, `mutate_document`, focused Access. No schema change.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Identify does not persist | `POST /supporting_documents/identify` (multipart file). `200` Turbo Stream fills the book and preview and does not replace the file input node. `SupportingDocument` count unchanged. Incluir remains `POST /supporting_documents` | Persist-on-drop — the list would update before the person confirmed values. Staging blob in the object store — #85 already forbade stashing a failed upload |
| Kind is inferred from the file | `.xml` → `nota_fiscal`. Image or image-PDF → `nota_fiscal` if extraction delivers chave, authorized XML, public NFC-e fields, or photo field reading, else `recibo`. Tipo is disabled after identify. `params[:kind]` is not required on insert | Ask Tipo after an image, before identify. Keep posting kind — the empty square has no Tipo |
| One file per new document | Create accepts photo XOR XML. Both or neither → `422` `Envie a foto ou o XML`. Edit has no XML control; PATCH of xml → `422` `XML_LOCKED` even when XML is not attached | Keep `foto e/ou XML`. Incluir XML on edit |
| Identify and create share one `file` slot | `params[:file]` is XML when the filename ends `.xml`, otherwise photo. Existing `photo` / `xml` params still map for callers that do not send `file`. | Stimulus renaming `#photo`/`#xml` — the empty square has one control |
| Blank-kind infer uses the full extract, not only symbols | When posted kind is blank and the file is a photo, classify `nota_fiscal` if symbols chave, QR URL, identified XML, public NFC-e fields, or photo field reading deliver; else `recibo`. Posted `nota_fiscal`/`recibo` still wins (#125 `submit_blank_only`). | Keep symbols-only classify — C4/C11 photo-fields would persist `recibo` |

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
- Kind inference and xor-file / PATCH xml-always-locked live in `SupportingDocument` (`insert` / `submit` / `identify`) — own-layer table plus HTTP
- `#identify` HTTP contract: 200 / 422 / 302 who may call
- `#create` stays pass-through after infer; `#update` refuses xml at the model
- Stimulus Limpar and in-flight wait copy are browser APIs. Closest analogue: `spec/system/keep_form_on_422_spec.rb`. C9 and C10 are system proofs
- View HTML (empty square, origins, no XML chip) is a request-spec claim. This repo has no view specs

Cost: request examples for C1–C8, C12–C22, C24; model examples for C11, C12–C16, C20; system examples for C9, C10; file-read for C23. Without the model table, kind inference would be one HTTP path.

## Screens (ui)

Opened: `.impeccable/mocks/documents-intake.html` (file), `.impeccable/mocks/document-edit.html` (file), `.specs/features/visual-identity/design.md` section `documents` (file).

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `documents` insert | First `section` h2 `Incluir documento`; no `label[for=photo]` / `label[for=xml]`; one `input[type=file]` accept includes `image/*` and `.xml`; empty book `Inclua o documento. Valor, data e favorecido saem do arquivo.`; `#amount` `#date` `#payee` `#kind` `#arquivo` not visible until identify; Sem mês `Nenhum documento`; after identify Arquivo Foto\|XML, Tipo disabled, origins under Valor/Data/Favorecido (`XML autorizado` / `Lido da foto` / `Digitado`), `Limpar` in the proof, `Identificando o arquivo…` while identify in flight; 422 `O XML da nota fiscal não pôde ser lido` / `Envie a foto ou o XML` | Split: proof **first** (square), book **second** `max-w-[28rem]`. From 768px `minmax(0,1fr)` + `28rem`. Square stacks first below 768px. `Limpar` inside the loaded square, not a Foto/XML chip | `documents` insert spacing, colour, type weight |
| `documents` edit | No `label[for=xml]` / `input#xml`; Arquivo disabled Foto\|XML; Tipo disabled; proof `Foto ·` + filename or XML filename; lock `O arquivo não pode ser alterado. Exclua o documento e inclua novamente.`; origin under Valor/Data/Favorecido as C22 | Existing split proof first / book `28rem` from 768px. No XML chip under the sheet. Arquivo then Tipo then the three fields | `documents` edit spacing, colour, type weight |

## Checks

Criteria 1–24 map to C1–C24. Unresolved 1 stays: origin copy `Consulta NFC-e` for `nfc_e_public`.

### S1 - Empty insert · 3 files · 143 KB · ~36k

**C1** - Given a signed-in coordinator of the focused organization with no SupportingDocument, when `GET /supporting_documents` runs, then the status is `200`, the first `section` heading is `Incluir documento`, that section has no `label[for=photo]` and no `label[for=xml]`, it has one `input[type=file]` whose `accept` includes `image/*` and `.xml`, the book contains `Inclua o documento. Valor, data e favorecido saem do arquivo.`, `#amount`, `#date`, `#payee`, `#kind`, and `#arquivo` are not visible, and Sem mês contains `Nenhum documento`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET empty insert is file-first proof square"`

**C2** - When that GET runs as a submitter with no document of their own, then the same empty insert arrangement as C1 is present (proof square, wait copy, no Foto/XML chips)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET empty insert as submitter is file-first"`

### S2 - Identify without persisting · 8 files · 228 KB · ~57k

**C3** - Given authorized XML of `vNF` `155.00`, emitente `Padaria Central`, `dhEmi` `2026-05-11`, chave `43260511222333000181550010000000011123456781`, when that coordinator POSTs `POST /supporting_documents/identify` with that file and no other fields, then no SupportingDocument is persisted, the status is `200`, the Turbo Stream (or HTML that keeps the same file input node) shows Arquivo `XML`, Tipo `Nota fiscal` disabled, Valor `155,00`, Data `2026-05-11`, Favorecido `Padaria Central`, that chave, origin text `XML autorizado` under Valor, Data, and Favorecido, those three inputs disabled, preview copy including that XML filename, and a `Limpar` control inside the proof square
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify authorized XML fills book without persisting"`

**C4** - Given a `.jpg` whose field reading returns `amount_cents` `15500`, `document_on` `2026-05-11`, payee `Padaria Central`, and identified and public NFC-e miss, when that coordinator POSTs identify with that photo, then no SupportingDocument is persisted, Arquivo is `Foto`, Tipo is `Nota fiscal` disabled, Valor/Data/Favorecido match those values and are not disabled, and origin under each of the three is `Lido da foto`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify photo fields fills book unlocked"`

**C5** - Given a `.jpg` whose barcode, chave-digit, identified, public NFC-e, and field reading all miss, when that coordinator POSTs identify with that photo, then no SupportingDocument is persisted, Arquivo is `Foto`, Tipo is `Recibo` disabled, chave is not visible, Valor, Data, and Favorecido are empty and enabled, origin under each is `Digitado`, and `Incluir documento` is disabled
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify photo miss is recibo typed empty"`

**C6** - Given a `.jpg` whose decode returns chave `43260511222333000181550010000000011123456781` and identified consulta returns authorized XML of `vNF` `155.00` emitente `Padaria Central` `dhEmi` `2026-05-11`, when that coordinator POSTs identify with that photo, then no SupportingDocument is persisted, Tipo is `Nota fiscal`, the three fields show those values disabled, and origin under each is `XML autorizado`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify photo chave identified XML locks fields"`

**C7** - If identify is posted an XML that `AuthorizedNfe.parse` rejects, then no SupportingDocument is persisted, the status is `422`, `[data-notice="error"]` and the error toast are `O XML da nota fiscal não pôde ser lido`, and the proof square's file input node is still present (Turbo Stream 422 does not replace the form's file control)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify unreadable XML 422 keeps file input"`

**C8** - If an unauthenticated request POSTs identify with a `.jpg`, then no SupportingDocument is persisted and the response is `302` to `/login`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated POST identify 302 to login"`

**C9** - After C3, when `Limpar` runs (no persist), then the square is empty again, the wait copy of C1 is visible, `#amount` is not visible, and SupportingDocument count is still unchanged
Proof: `bin/rspec spec/system/document_identify_spec.rb -e "Limpar after identify XML returns empty square"`

**C10** - While `POST /supporting_documents/identify` is in flight, the book shows `Identificando o arquivo…` (user-triggered; no page-load choreography)
Proof: `bin/rspec spec/system/document_identify_spec.rb -e "identify in flight shows Identificando o arquivo"`

### S3 - Kind from the file · 3 files · 204 KB · ~51k

**C11** - Always, insert infers kind and does not require `params[:kind]`: a `.xml` file is `nota_fiscal`; an image or image-PDF is `nota_fiscal` when identify/submit extraction delivers chave, authorized XML, public NFC-e fields, or photo field reading, and `recibo` when those all miss
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert infers kind from xml"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert infers nota_fiscal from photo chave"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert infers nota_fiscal from identified XML"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert infers nota_fiscal from public NFC-e"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert infers nota_fiscal from photo fields"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert infers recibo when photo extraction misses"`

**C12** - When `POST /supporting_documents` is that authorized XML of C3 and no `kind`, no photo, then one SupportingDocument persists `kind` `nota_fiscal`, `fields_origin` `uploaded_xml`, that XML blob, no photo blob, `amount_cents` `15500`, and the response is `302` to `/supporting_documents`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST create authorized XML without kind persists nota_fiscal"`

### S4 - One file on persist · 3 files · 204 KB · ~51k

**C13** - When `POST /supporting_documents` is the photo of C4, typed-or-identified values matching that reading, and no XML, then one SupportingDocument persists that photo, no XML blob, `fields_origin` `photo`, and `302` to `/supporting_documents`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST create photo fields persists photo origin"`

**C14** - When `POST /supporting_documents` is the miss photo of C5 plus amount `48,90`, date `2026-05-12`, payee `Papelaria Lume`, then one SupportingDocument persists `kind` `recibo`, that photo, no XML, `chave` `nil`, `fields_origin` `typed`, `amount_cents` `4890`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST create miss photo with typed values persists recibo"`

**C15** - When `POST /supporting_documents` includes both a `.jpg` photo and an authorized XML, then no SupportingDocument is persisted, the status is `422`, and `[data-notice="error"]` is `Envie a foto ou o XML`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST create both photo and XML 422 xor"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert both photo and xml is xor"`

**C16** - When `POST /supporting_documents` has neither photo nor XML, then no SupportingDocument is persisted, the status is `422`, and `[data-notice="error"]` is `Envie a foto ou o XML`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST create neither file 422 xor"`

**C17** - When a submitter POSTs identify then create as in C12 with XML they uploaded, then that document's `account_id` is the submitter, `GET /supporting_documents` is `200` and includes `Padaria Central`, and it does not include another organization's documents
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter identify then create XML is own account"`

### S5 - Edit: no second file · 3 files · 143 KB · ~36k

**C18** - Given a persisted nota fiscal with a photo and no XML, when `GET /supporting_documents/:id/edit` runs as that coordinator, then the status is `200`, there is no `label[for=xml]` and no `input#xml`, Arquivo is visible disabled value `Foto`, Tipo is disabled `Nota fiscal`, the proof contains `Foto ·` and that filename, and the lock sentence is `O arquivo não pode ser alterado. Exclua o documento e inclua novamente.`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit photo-only has Arquivo Foto and no xml picker"`

**C19** - Given a persisted nota fiscal with XML and no photo, when that GET edit runs, then Arquivo is `XML`, there is no `input#xml`, and the proof shows that XML filename
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit xml-only has Arquivo XML and no xml picker"`

**C20** - Given a persisted nota fiscal with a photo and no XML, when `PATCH /supporting_documents/:id` includes an XML file, then the document still has no XML blob, the status is `422`, and `[data-notice="error"]` is `O XML não pode ser alterado. Exclua o documento e inclua novamente.` (`SupportingDocument::XML_LOCKED`)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH xml onto photo-only 422 XML_LOCKED"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply xml on photo-only is XML_LOCKED"`

**C21** - Given a legacy row that already has both photo and XML attached, when GET edit runs, then Arquivo is `XML`, there is still no XML picker, the proof may show the photo, and PATCH does not purge either blob
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit legacy both blobs Arquivo XML no picker PATCH keeps blobs"`

### S6 - Origin stamps and binding wire · 4 files · 168 KB · ~42k

**C22** - When GET edit runs for a `fields_origin` `uploaded_xml` or `identified` document, then Valor, Data, and Favorecido are not editable and each has origin `XML autorizado`. When GET edit runs for `fields_origin` `photo`, then those three are editable and each has origin `Lido da foto`. When GET edit runs for `fields_origin` `typed` (recibo or typed NF), then origin under each is `Digitado`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit uploaded_xml origins XML autorizado locked"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit identified origins XML autorizado locked"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit photo origins Lido da foto unlocked"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit typed origins Digitado"`

**C23** - `.specs/features/visual-identity/design.md` section `documents` describes the proof square as the only insert file control, `Limpar` inside the loaded square, Arquivo Foto|XML, identify wait copy, edit without XML, and `Envie a foto ou o XML` — the ASCII already amended by this task stays that arrangement
Proof: `bin/rspec spec/docs/document_file_first_insert_spec.rb -e "visual-identity documents file-first proof square xor edit without XML"`

**C24** - Unauthenticated `GET /supporting_documents` and `GET /supporting_documents/:id/edit` stay `302` to `/login`; no focused organization stays `302` to `/login`; a submitter GET edit of another Account's document stays `404`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET /supporting_documents responds 302 to /login"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET edit responds 302 to /login"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents without focus responds 302 to /login"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter GET edit on another Account document returns 404"`

## Swept

- validation: C11, C15, C16 — xor file; kind inferred; both-files and no-file `422`
- failure modes: C7 — unreadable XML on identify; create still uses existing oversize and type messages
- idempotency and retry: n/a — identify does not persist; a second create is a second document (existing, no unique chave)
- authorization: C8, C17, C24 — existing focused organization and submitter-own-row rules
- concurrency and ordering: n/a — two identify-then-create sequences persist two rows; no new uniqueness
- data lifecycle: C21 — legacy dual-attachment rows are not migrated or purged
- external-dependency failure: C4, C5, C6 — identify uses the existing identified / public / photo fallbacks; a miss is recibo (C5), not a new error
- state transitions: C9, C12, C18, C20 — Limpar returns to empty; create persists; edit cannot add XML
- observability: existing — `:base` notice plus error toast on `422`; no new metric

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| kind inference (6) | xml C11 · photo chave C11 · identified XML C11 · public NFC-e C11 · photo fields C11 · all miss recibo C11 | - |
| create xor file (4) | xml-only C12 · photo-only C13/C14 · both C15 · neither C16 | - |
| identify outcomes (5) | xml C3 · photo fields C4 · miss recibo C5 · identified from photo C6 · unreadable XML C7 | - |
| GET edit Arquivo (3) | photo-only Foto C18 · xml-only XML C19 · legacy both XML C21 | - |
| origin stamps on edit (4 named by C22) | `uploaded_xml` C22 · `identified` C22 · `photo` C22 · `typed` C22 | `nfc_e_public` — Unresolved 1, render `Consulta NFC-e` until answered |
| identify HTTP (3) | `200` C3 · `422` C7 · `302` `/login` C8 | - |
| designed screens (2) | `documents` insert C1, C3, C10 · `documents` edit C18, C22 | - |
| C24 auth (4) | unauthenticated GET index · unauthenticated GET edit · no focus GET index · submitter GET edit other Account | - |

- Claims naming a status code, route or response shape: C1–C8, C12–C21, C24 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises except C11 (table of 6) and C22 (4 origins), enumerated above
- `documents` insert spacing, colour, type weight unproven
- `documents` edit spacing, colour, type weight unproven

## Handoff

S1–S6 unique files (model, controller, both ERBs, routes, request spec, model spec, design.md, mocks, new system spec) ≈ 306 KB · ~77k tokens. All stay on the documents surface. Under 150k, **one batch, no mid-feature handoff**.
