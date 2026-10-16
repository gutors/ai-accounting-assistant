# File-first supporting document insert Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 5a52b99..37cd1fe (HEAD)
**Round**: 2 - full
**Verifier**: independent sub-agent (author != verifier)

Raised from the repo floor `standard` because the checklist names binding screens. Step 1, Coverage, Test policy, and fault injection all ran. Proofs re-ran in full at `37cd1fe`. Round-1 FAIL items (arrangement, xor-neither own layer, Limpar containment, image-PDF) re-checked against the `37cd1fe` fix.

## Binding sources

Opened as files in the repo (not as URL fetches). Saw insert mock structure (`.split` → proof `aside` then `.book`; `@media (min-width: 768px)` `minmax(0, 1fr) 28rem`; `Limpar` inside `.preview`; drop helper copy) and edit mock (same split; Arquivo → Tipo → Valor/Data/Favorecido; lock sentence; no `input#xml`). Saw `design.md` section `documents` ASCII (proof square only file control, `Limpar` in loaded square, wait copy, xor sentence, edit without XML, 28rem book).

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.impeccable/mocks/documents-intake.html` | yes - file | none vs C1–C24 | `Observação (opcional)` has no C-number; still asserted by pre-feature HTTP examples (`supporting_documents_spec.rb:185`, edit `:190`). Not the distinguishing composition. |
| `.impeccable/mocks/document-edit.html` | yes - file | none — mock omits origin stamps; Sources already records criterion 22 / design.md wins | same Observação note; field *order* Arquivo→Tipo→fields is in the Screens table and in markup (`edit.html.erb:49-70`) but C18 asserts presence/lock/split, not sibling order |
| `.specs/features/visual-identity/design.md` section `documents` | yes - file | none vs C1–C24 copy the section decides | HTML `422` field echo is existing (`POST nota_fiscal without files echoes insert fields on 422` at `supporting_documents_spec.rb:358-377`), not a C15/C16 claim (xor has no filled book). `@insert_echo` remains in `_insert_book.html.erb:3` |

Visual unproven in the checklist is enumerated per screen as spacing, colour, type weight — not a blanket. Arrangement (proof first, `md:grid-cols-[minmax(0,1fr)_28rem]`, book `max-w-[28rem]`, square first in DOM) is now in C1 and C18.

## Checks

Proofs: one `bin/rspec` invocation over the four spec files with `--example-matches` covering every named example. **39 examples, 0 failures**. Each name exists in the tree (`rg`); the filter selected 39 examples and all passed at `37cd1fe`.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | empty GET insert file-first square + split | `GET empty insert is file-first proof square` exit 0 | `spec/requests/supporting_documents_spec.rb:3338-3361` — `:ok`; first `section` h2 `Incluir documento`; no `label[for=photo]`/`xml`; one file; `accept` includes `image/*` and `.xml`; wait copy; `#amount` `#date` `#payee` `#kind` `#arquivo` `html_visible? == false`; Sem mês `Nenhum documento`; form class includes `md:grid-cols-[minmax(0,1fr)_28rem]`; first child `aside`; last child `max-w-[28rem]`; drop copy `Solte a foto ou o XML…` | PASS (round-1 arrangement gap closed) |
| C2 | submitter empty insert same arrangement | `GET empty insert as submitter is file-first` exit 0 | `spec/requests/supporting_documents_spec.rb:3370-3376` — `:ok`; no photo/xml labels; one file; wait copy; `#amount` not visible | PASS on the parenthetical (chips, wait, one file). Does not repeat C1's `28rem` class |
| C3 | identify XML fills book, no persist; Limpar in square | `POST identify authorized XML fills book without persisting` exit 0 | `spec/requests/supporting_documents_spec.rb:3384-3404` — `count == 0`; `:ok`; streams do not retarget `file`; `#arquivo` `XML`; kind `nota_fiscal` disabled; `155,00` / `2026-05-11` / `Padaria Central`; chave; origin `XML autorizado` disabled; filename; Limpar button with ancestor `id == "identify-preview"` | PASS (containment now asserted) |
| C4 | identify photo fields unlocked | `POST identify photo fields fills book unlocked` exit 0 | `spec/requests/supporting_documents_spec.rb:3413-3425` — count 0; Arquivo `Foto`; kind `nota_fiscal` disabled; values; origin `Lido da foto`; not disabled | PASS |
| C5 | identify miss is typed recibo | `POST identify photo miss is recibo typed empty` exit 0 | `spec/requests/supporting_documents_spec.rb:3433-3447` — count 0; Arquivo `Foto`; kind `recibo` disabled; chave not visible; empty enabled fields; origin `Digitado`; Incluir disabled | PASS |
| C6 | identify photo chave identified XML | `POST identify photo chave identified XML locks fields` exit 0 | `spec/requests/supporting_documents_spec.rb:3458-3468` — count 0; kind `nota_fiscal`; values; origin `XML autorizado`; disabled | PASS |
| C7 | unreadable XML 422 keeps file | `POST identify unreadable XML 422 keeps file input` exit 0 | `spec/requests/supporting_documents_spec.rb:3479-3487` — count 0; `:unprocessable_content`; notice and toast include `O XML da nota fiscal não pôde ser lido`; streams do not retarget `file` or the create form | PASS |
| C8 | unauthenticated identify 302 | `unauthenticated POST identify 302 to login` exit 0 | `spec/requests/supporting_documents_spec.rb:3493-3495` — count 0; `:found`; `redirect_to("/login")` | PASS |
| C9 | Limpar returns empty square | `Limpar after identify XML returns empty square` exit 0 | `spec/system/document_identify_spec.rb:38-40` — wait target visible with C1 copy; `#amount` not visible; count 0 | PASS |
| C10 | in-flight wait copy | `identify in flight shows Identificando o arquivo` exit 0 | `spec/system/document_identify_spec.rb:62` — `have_content("Identificando o arquivo…")` | PASS |
| C11 | insert infers kind (xml / photo signals / image-PDF / miss) | seven model examples exit 0 | `spec/models/supporting_document_spec.rb:1734` xml `nota_fiscal`; `:1741` photo chave; `:1751` identified; `:1760` public NFC-e `nfc_e_public`; `:1768` photo fields `photo` / `15500`; `:1777` miss `recibo` / `typed`; `:1801-1802` image-PDF `photo_with_ext("pdf")` → `nota_fiscal` / `photo` | PASS including image-PDF |
| C12 | create XML no kind | `POST create authorized XML without kind persists nota_fiscal` exit 0 | `spec/requests/supporting_documents_spec.rb:3503-3510` — `:found`; `redirect_to("/supporting_documents")`; `kind nota_fiscal`; `fields_origin uploaded_xml`; xml attached; photo not; `amount_cents 15500` | PASS (`params[:xml]`, allowed by Landing) |
| C13 | create photo fields | `POST create photo fields persists photo origin` exit 0 | `spec/requests/supporting_documents_spec.rb:3521-3526` — `:found`; redirect; photo attached; xml not; `fields_origin photo` | PASS |
| C14 | create miss photo typed recibo | `POST create miss photo with typed values persists recibo` exit 0 | `spec/requests/supporting_documents_spec.rb:3536-3543` — `:found`; `recibo`; photo; no xml; `chave nil`; `typed`; `4890` | PASS |
| C15 | both files 422 xor | request + model examples exit 0 | `spec/requests/supporting_documents_spec.rb:3551-3553` — count 0; `:unprocessable_content`; notice `Envie a foto ou o XML`. `spec/models/supporting_document_spec.rb:1784-1786` — not persisted; same base error | PASS |
| C16 | neither file 422 xor | HTTP + model examples exit 0 | `spec/requests/supporting_documents_spec.rb:3561-3563` — count 0; `:unprocessable_content`; notice `Envie a foto ou o XML`. `spec/models/supporting_document_spec.rb:1792-1794` — not persisted; `errors[:base]` includes `Envie a foto ou o XML` | PASS at HTTP **and** own layer (round-1 gap closed) |
| C17 | submitter identify then create own account | `submitter identify then create XML is own account` exit 0 | `spec/requests/supporting_documents_spec.rb:3580-3584` — `account_id` submitter; GET `:ok`; includes `Padaria Central`; excludes `Outra ONG` | PASS |
| C18 | GET edit photo-only + split | `GET edit photo-only has Arquivo Foto and no xml picker` exit 0 | `spec/requests/supporting_documents_spec.rb:3596-3613` — `:ok`; no `label[for=xml]` / `input#xml`; Arquivo visible `Foto` disabled; kind `nota_fiscal` disabled; proof `Foto ·` + filename; lock sentence; `[data-edit=split]` includes `md:grid-cols-[minmax(0,1fr)_28rem]`; first child `data-edit=proof`; `[data-edit=book]` includes `max-w-[28rem]` | PASS (round-1 arrangement gap closed) |
| C19 | GET edit xml-only | `GET edit xml-only has Arquivo XML and no xml picker` exit 0 | `spec/requests/supporting_documents_spec.rb:3626-3628` — Arquivo `XML`; no `input#xml`; proof includes XML filename | PASS |
| C20 | PATCH xml → XML_LOCKED | request + model examples exit 0 | `spec/requests/supporting_documents_spec.rb:3639-3641` — `:unprocessable_content`; notice `eq(SupportingDocument::XML_LOCKED)`; xml still unattached. `spec/models/supporting_document_spec.rb:1810-1811` — `errors[:base]` includes the same constant. Literal at `supporting_document.rb:12`: `O XML não pode ser alterado. Exclua o documento e inclua novamente.` | PASS. HTTP expected value is the constant; checklist names both |
| C21 | legacy both blobs | `GET edit legacy both blobs Arquivo XML no picker PATCH keeps blobs` exit 0 | `spec/requests/supporting_documents_spec.rb:3655-3664` — Arquivo `XML`; no `input#xml`; proof may show photo filename; PATCH `:found`; both blobs still attached | PASS |
| C22 | edit origin stamps (4) | four GET edit examples exit 0 | `spec/requests/supporting_documents_spec.rb:3678-3679,3698-3699,3716-3717,3728-3729` — `uploaded_xml`/`identified` locked `XML autorizado`; `photo` unlocked `Lido da foto`; `typed` `Digitado` | PASS. `nfc_e_public` left Unproven (Unresolved 1) |
| C23 | design.md documents ASCII | `visual-identity documents file-first proof square xor edit without XML` exit 0 | `spec/docs/document_file_first_insert_spec.rb:8-13` — section includes proof square, `Limpar`, `Arquivo [Foto\|XML locked]`, wait copy, no XML on edit, xor sentence | PASS |
| C24 | auth on GET index/edit | four request examples exit 0 | `spec/requests/supporting_documents_spec.rb:55-56,68-69,3073-3074,3087` — unauth index `:found` `/login`; no focus `:found` `/login`; unauth edit `:found` `/login`; submitter other account `:not_found` | PASS (“stay” claims; examples predate the feature and still run) |

## Coverage (recomputed)

Authority: C11 / Landing for kind; C15–C16 / C12–C14 for xor; C3–C7 identify; C18/C19/C21 edit Arquivo; C22 origins; C8 identify HTTP; design.md + mocks for screens; C24 auth.

| Set (size) | Members from authority | Proof | Unproven |
|---|---|---|---|
| kind inference | C11: xml, photo chave, identified XML, public NFC-e, photo fields, all-miss recibo; image-PDF as photo-fields file type | seven C11 model examples | Landing also names QR URL as a classify signal (`submit` `photo_symbols.qr_url.present?` at `supporting_document.rb:341`). No example with QR URL and no public/chave/fields. Not a C11 member |
| create xor file | xml-only, photo-only, both, neither | C12 HTTP; C13/C14 HTTP; C15 HTTP+model; C16 HTTP+model | - |
| identify outcomes | xml, photo fields, miss recibo, identified from photo, unreadable XML | C3–C7 | - |
| GET edit Arquivo | photo-only Foto, xml-only XML, legacy both XML | C18, C19, C21 | - |
| origin stamps on edit | `uploaded_xml`, `identified`, `photo`, `typed` from C22 | four C22 examples | `nfc_e_public` — Unresolved 1, transcribed `Consulta NFC-e` |
| identify HTTP | 200, 422, 302 `/login` | C3, C7, C8 | - |
| designed screens (2) | insert, edit from design.md / mocks | insert copy+arrangement C1, C3, C10; edit copy+arrangement C18, C22 | Observação label not a C-check (existing HTTP `:185`/`:190`) |
| C24 auth | four members | four C24 examples | - |

HTTP claims C1–C8, C12–C21, C24 have request-spec proofs at the boundary. C9/C10 are system (browser). C11 own-layer. C23 file-read.

## Test policy rows

Bar: checklist rows (same allocation as `.cursor/rules/rails.mdc`).

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `SupportingDocument` insert/submit/identify (kind infer, xor file, PATCH xml always locked) | own layer per member **and** HTTP status/who | kind infer 6/6 + image-PDF at model + HTTP paths C12–C14; xor both model+HTTP; xor **neither** model+HTTP C16; XML_LOCKED model+HTTP C20 — **met** |
| Decides, not reached across a boundary | none new | own layer | n/a |
| Entry point that decides nothing | `SupportingDocumentsController#create` after infer; view HTML | request spec | C1, C12–C16, C18–C19, C21–C22 yes |
| Instrumentation / pass-through | slot_uploads mapping used by identify/create | consumer | C3/C12 consumers yes |
| `#identify` HTTP contract | `supporting_documents#identify` | 200 / 422 / 302 who may call | C3, C7, C8 yes |
| Stimulus Limpar / in-flight | `document_identify_controller.js` | system (request spec cannot settle) | C9, C10 yes |

## Swept existing

- `require_focused_organization` still `redirect_to login_path` (`application_controller.rb:52-53`) — C24 no-focus
- `mutate_document` still `head :not_found` when not coordinator and not owner (`supporting_documents_controller.rb:105-107`) — C24
- `XML_UNREADABLE` / `NF_FILES` / `XML_LOCKED` constants still the checklist strings (`supporting_document.rb:8-19`)
- `PHOTO_LOCKED` is the edit lock sentence C18 asserts (`supporting_document.rb:11`; `edit.html.erb:39`)
- Identify does not persist: `persist_document` `return if preview_only` (`supporting_document.rb:516`)

## Faults injected

Scratch worktree `/tmp/tlc-verify-doc-insert` at `HEAD`, then `git worktree remove --force`. Real-tree porcelain after discard matches baseline: `?? .checks/document-file-first-insert.verified.md`, `?? .impeccable/build/`, `?? spec/tmp-verify-out.txt`. Five surfaces (round-2 new assertions); each covering proof failed.

| Mutation | Location | Killed |
|---|---|---|
| insert form `md:grid-cols-[minmax(0,1fr)_28rem]` → `md:grid-cols-1` | `app/views/supporting_documents/index.html.erb` | yes — C1 `include("md:grid-cols-[minmax(0,1fr)_28rem]")` |
| xor neither `errors.add NF_FILES` → `next_kind = "recibo"` | `app/models/supporting_document.rb` | yes — C16 model expected `Envie a foto ou o XML`, got `Envie a foto do recibo` |
| `Limpar` moved outside `#identify-preview` | `app/views/supporting_documents/_insert_preview.html.erb` | yes — C3 ancestor `identify-preview` false |
| drop `.pdf` from `PHOTO_EXT` | `app/models/supporting_document.rb` | yes — C11 image-PDF `kind` got `nil` not `nota_fiscal` |
| edit split `28rem` columns → `md:grid-cols-1` | `app/views/supporting_documents/edit.html.erb` | yes — C18 split class |

No surviving mutant on the five injected surfaces.

## Gate

`bin/rspec` (four files, `--example-matches` all named proofs) — 39 passed, 0 failed.

## Round-1 findings

1. **Arrangement** — closed: C1/C18 assert proof-first + `28rem` split tokens.
2. **xor neither own layer** — closed: C16 model example.
3. **Limpar in square** — closed: C3 ancestor `#identify-preview`.
4. **image-PDF** — closed: C11 `insert infers nota_fiscal from photo fields on image-PDF`.
5. **Observação / 422 echo / QR URL** — not FAIL. Observação and 422 echo remain proven by pre-feature request examples; QR URL-only classify stays Unproven as a Landing extra outside C11’s six members; `nfc_e_public` origin stays Unresolved 1.
