# Coordinator batch document insert Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: fd6690127aae1f0bf9eb183efd6fc9280d30ded4..42bd88255a3e84104235e239419ee518385d0a90
**Round**: 2 - full
**Verifier**: independent sub-agent (author != verifier)

Round 1 FAIL at `bde5a06` (C8 missing ink/margem borders and Retirar padding; Observação control unproven). This round re-ran every named proof at `42bd882` and re-opened the binding sources. Fix diff `bde5a06..42bd882` adds those C8/C22 assertions and names Observação in the Screens table; check prose C1–C23 is otherwise unchanged.

## Binding sources

Opened as files in the repo (not URLs): `.impeccable/mocks/documents-batch-select.html`, `.impeccable/surfaces/impeccable-mocks-documents-batch-select-html.md`, `DESIGN.md` tokens (`button-secondary` padding `8px 16px`, transparent fill, 1px ink border, ink text; `action-destructive` / margem text; `.ds-btn-secondary.ds-btn-danger` margem border in CSS; button shape 4px).

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.impeccable/mocks/documents-batch-select.html` | yes - file | none vs C3–C8, C22 on labels/order/containment the checks name. Surface OWN-WORLD “margem only on the error row” disagrees with this mock’s `.danger` Retirar; C8 follows the mock + DESIGN, not that sentence | Mock Erro instance is photo `danfe-borrada.jpg` / “não leu valor, data nem favorecido”; checks cover Erro as unreadable XML (C5). Lede “14 arquivos neste lote…” is count copy already on `Incluir prontos (N)` and Situação |
| `.impeccable/surfaces/impeccable-mocks-documents-batch-select-html.md` | yes - file | OWN-WORLD “margem only on the error row” vs C8 Retirar margem. FIRST VIEWPORT arrangement (edit split above lote, Arquivo under proof, valor/data paired, toolbar then lote then Sem mês) matches C22 | proto A/B/C bar — prototype chrome, not shipping |
| `DESIGN.md` tokens | yes - file | none vs C8’s named secondary padding/fill/ink border and margem on Retirar | spacing, colour, type weight beyond those named tokens |

Screens (ui): empty coordinator drop is criterion 1 (not its own mock). Submitter square, Sem mês, edit are existing screens this cut does not rebind. Visual unproven is enumerated per screen (spacing, colour, type weight), not a blanket fidelity clause. Arrangement the mock decides that a selector reaches has checks (C7, C8, C22). **Observação (opcional)** is asserted at `document_lote_spec.rb:153` (C8) and `:293` (C22).

## Checks

Proofs: one `ruby bin/rspec` invocation, 34 `-e` filters. **34 examples, 0 failures** at `42bd882`. Named examples exist (`rg -n`) in `spec/requests/supporting_documents_spec.rb`, `spec/models/supporting_document_spec.rb`, `spec/system/document_lote_spec.rb`, `spec/requests/justifications_spec.rb`. New lote/batch examples sit in `fd66901..HEAD`; C20/C21 reuse pre-existing examples (justifications file untouched) and still ran at HEAD.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | GET 200; h2 `Incluir documentos`; one `input[type=file][multiple]`; accept `image/*` and `.xml`; no `Situação` / `Incluir prontos`; Sem mês `Nenhum documento` | ran, passed | `supporting_documents_spec.rb:4042` `:ok` · `:4044` h2 `eq("Incluir documentos")` · `:4046-4049` one file, `multiple` present, accept includes `image/*` and `.xml` · `:4050-4051` not `Situação` / `Incluir prontos` · `:4052-4054` next section `Sem mês` includes `Nenhum documento` | PASS |
| C2 | submitter h2 `Incluir documento`; file not `multiple`; wait copy; no `Incluir prontos` | ran, passed | `supporting_documents_spec.rb:4063-4067` h2 · `multiple` `be_nil` · include wait copy · not `Incluir prontos` | PASS |
| C3 | two XMLs; count 0; lote heads; filenames; Pronto; payees; amounts; Sem mês empty | ran, passed | `document_lote_spec.rb:56-66` heads + filenames + payees + `R$ 155,00` / `R$ 89,40` · Pronto `count: 2` · `Nenhum documento` · `SupportingDocument.count` `eq(0)` | PASS |
| C4 | photo miss: count 0; Tipo `Recibo`; Situação `Digitar`; Valor `—`; origin `Digitado` | ran, passed | `document_lote_spec.rb:73-78` `Digitar` · `Recibo` · `[data-lote-id]` text `—` · origin amount `Digitado` · count `0` | PASS |
| C5 | unreadable XML: count 0; Situação `Erro`; `O XML da nota fiscal não pôde ser lido`; other rows remain | ran, passed | `document_lote_spec.rb:87-91` padaria filename · `Pronto` · `Erro` · XML unread copy · count `0` | PASS |
| C6 | in-flight identify `Identificando o arquivo…` | ran, passed | `document_lote_spec.rb:109` `have_content("Identificando o arquivo…")` | PASS |
| C23 | 31st file not added; `[data-notice="error"]` `No máximo 30 arquivos neste lote` | ran, passed | `document_lote_spec.rb:117-118` notice text · `[data-lote-id]` `count: 30` | PASS |
| C7 | Padaria selected: `aria-selected`; proof filename; `#arquivo` XML disabled under proof not book; Tipo NF disabled; fields + `XML autorizado`; Valor/Data two columns | ran, passed | `document_lote_spec.rb:127-137` `aria-selected` · proof text · arquivo `XML` disabled inside proof · not `book #arquivo` · kind · amount `155,00` · date `2026-05-11` · payee · origins · `gridTemplateColumns` split length `2` | PASS |
| C8 | Digitar book; Observação; toolbar primary `Incluir prontos (N)`; secondary `Incluir este` ink border, transparent, padding `8px` `16px`; `Retirar` margem border and text, same padding | ran, passed | `document_lote_spec.rb:146-165` Foto/Recibo/empty enabled fields/Digitado · `Observação (opcional)` · `Incluir prontos (0)` · `ds-btn-secondary` · computed paddingTop `8px` paddingLeft `16px` background `rgba(0, 0, 0, 0)` · `borderTopColor` includes `27, 50, 41` (ink `#1b3229`) · Retirar color + `borderTopColor` `180, 55, 42` (margem `#b4372a`) · Retirar paddingTop `8px` paddingLeft `16px` | PASS |
| C9 | Incluir este persists Padaria XML; Sem mês; Farmácia remains; stays on `/supporting_documents` | ran, passed | `document_lote_spec.rb:175-185` `#sem-mes` payee/amount · padaria gone · farmacia content · `have_current_path("/supporting_documents")` · kind `nota_fiscal` · `amount_cents` `15500` · xml attached, photo not · count `1` | PASS |
| C10 | empty Digitar Incluir este persists none | ran, passed | `document_lote_spec.rb:195` count `eq(0)` | PASS |
| C11 | Retirar drops Padaria; Farmácia remains; count 0; no `data-turbo-confirm` | ran, passed | `document_lote_spec.rb:203-208` no confirm · padaria gone · farmacia remains · count `0` | PASS |
| C12 | two XMLs persist; 302 or empty lote; Sem mês four strings | ran, passed (HTTP+model+system) | HTTP `:4080-4085` `:found` `redirect_to("/supporting_documents")` count `2` Sem mês strings · model `:1926-1928` failure `nil` size `2` count `2` · system `:217-222` `#sem-mes` strings · no `[data-lote-status]` · count `2` | PASS |
| C13 | twelve persist; Digitar+Erro remain in lote; Sem mês omits Digitar filename | ran, passed (HTTP+system) | HTTP `:4096-4100` count `12` payees included, `empty.jpg` not in Sem mês (HTTP posts only the twelve) · system `:242-249` count `12` · `empty.jpg` / `nota.xml` / `Digitar` / `Erro` · `#sem-mes` not `empty.jpg` | PASS |
| C14 | missing amount/date/payee: persist none; HTTP `422`; notice filename + `Faltam valor, data ou favorecido.`; lote kept | ran, passed | HTTP `:4113-4117` count `0` `:unprocessable_content` notice includes filename + BATCH_MISSING (`error_notice_text` → `p[role=alert][data-notice=error]`) · model `:1951-1953` `:1968-1969` `:1984-1985` count `0` + message · system `:264-267` notice + both filenames + count `0` | PASS |
| C15 | Incluir prontos disabled in flight | ran, passed | `document_lote_spec.rb:286` `[data-lote-ready][disabled]` | PASS |
| C16 | submitter POST batch none + `404` | ran, passed | `supporting_documents_spec.rb:4127-4128` count `0` `:not_found` | PASS |
| C17 | unauthenticated POST batch none + `302` `/login` | ran, passed | `supporting_documents_spec.rb:4136-4138` count `0` `:found` `redirect_to("/login")` | PASS |
| C18 | submitter POST one XML: persist + `302` `/supporting_documents` | ran, passed | `supporting_documents_spec.rb:4146-4150` `:found` redirect · `doc.account` · xml attached | PASS |
| C19 | lote item photo+XML: `422` `Envie a foto ou o XML`; persist none | ran, passed | HTTP `:4166-4168` count `0` `:unprocessable_content` notice `eq("Envie a foto ou o XML")` · model `:2001-2002` count `0` `failure` `eq("Envie a foto ou o XML")` | PASS |
| C20 | edit / Sem mês heads / submitter justify / POST justification unchanged | ran, passed | `supporting_documents_spec.rb:3065-3066` `:ok` h1 `Editar documento` · `:2637` heads `Data Favorecido Tipo Valor Ações` · `:2626-2627` `inputmode` `numeric` · `justifications_spec.rb:27-34` `:found` redirect, `amount_cents` `20000`, GET includes `R$ 200,00`. Last file not in `fd66901..HEAD` | PASS |
| C21 | unauthenticated GET `302` `/login` | ran, passed | `supporting_documents_spec.rb:62-63` `:found` `redirect_to("/login")` | PASS |
| C22 | edit split above lote; Arquivo under proof; Observação; toolbar order; lote then Sem mês | ran, passed | `document_lote_spec.rb:293-303` Observação field · editor first child contains proof `#arquivo` · toolbar then sheet · labels `Incluir prontos` / `Incluir este` / `Retirar` · `sheet_top < sem_top` | PASS |

## Coverage (recomputed)

Authority for screens: the mock + surface FIRST VIEWPORT, not the ERB. Decision members from `SupportingDocument.insert_batch` (`app/models/supporting_document.rb:71-108`) and `SupportingDocumentsController#batch` (`only: :batch` `require_coordinator_organization`).

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| insert modes (2) | coordinator lote drop C1 · submitter one-file C2, C18 | - |
| lote Situação (3) | Pronto C3 · Digitar C4 · Erro C5 | Identifying is in-flight copy C6. Mock’s photo Erro row copy is not a fourth status; that seed text is unproven |
| selected book (2) | XML Pronto C7 · Digitar typed C8 (incl. Observação) | - |
| lote mutations (3) | Incluir este remainder C9 · empty Incluir este C10 · Retirar C11 | - |
| `POST /supporting_documents/batch` who may call (3) | coordinator C12 · submitter `404` C16 · unauthenticated `302` `/login` C17 | - |
| `insert_batch` outcomes | two XMLs persist C12 · missing amount/date/payee C14 · xor both files C19 | “twelve ready omit others” is not an `insert_batch` branch (client posts Pronto only; C13 HTTP+system). Empty `documents[]` → `NF_FILES` in `#batch` (`inserted.empty?`) has no example |
| xor on lote item (1) | both photo and XML C19 | neither-file uses existing `insert` `NF_FILES` |
| designed screens this cut binds (1) | `documents` insert coordinator C1, C7, C8, C22 | - |
| designed screens this cut does not bind | — | prototypes A and C; submitter square existing |
| `documents` insert visual (3 properties) | C8 padding + transparent fill + ink border + Retirar margem border/text | spacing, colour, type weight on empty/lote/submitter/Sem mês/edit beyond C8 tokens |

Status/route claims C1, C9, C12, C14, C16, C17, C18, C19, C21 have HTTP or (C9) system remainder proofs. C9 remainder is system because leftover `File` objects are not on the server.

## Test policy rows

Checklist follows `.cursor/rules/rails.mdc` (decision at own layer + HTTP when reached; system when request cannot settle).

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `SupportingDocument.insert_batch`; `SupportingDocumentsController#batch` who-may-call | own layer + HTTP | yes — C12/C14/C19 model; C12/C14/C16/C17/C19 HTTP. Missing date/payee are own-layer members; HTTP samples amount |
| Decides, not reached across a boundary | Stimulus lote (`document_lote_controller.js`: MAX, Situação, remainder Files) | own layer; repo has no JS unit runner | yes — system C3–C11, C13, C15, C22, C23 as the checklist priced |
| Entry point that decides nothing | `#create` Incluir este Turbo remainder is a transport choice over `insert` | request cannot keep leftover Files | yes — C9/C10 system; C18 submitter create still HTTP |
| Instrumentation / pass-through | `batch_documents` param shape | consumer | yes — C12 HTTP |

Swept **existing**: `XML_UNREADABLE` `supporting_document.rb:19`; `NF_FILES` `:8`; `require_coordinator_organization` `supporting_documents_controller.rb:3` and `application_controller.rb:56`. Stimulus `MAX = 30` / `MAX_NOTICE` `document_lote_controller.js:3-4`. n/a rows (no draft table, no unique chave, no new metric) left as policy.

## Faults injected

Scratch: `git worktree add /tmp/coordinator-batch-document-insert-verify-r2 HEAD`. Mutants only there. Worktree removed. Real tree porcelain still `?? .checks/coordinator-batch-document-insert.verified.md` and `?? .impeccable/briefs/` (unchanged by this run).

Round 2 re-injected the C8 assertion surfaces the fix added (cap 5). Round 1 already killed h2, `insert_batch` blank guard, `require_coordinator_organization`, Stimulus MAX, and `finish_insert` always-redirect.

| Mutation | Location | Killed |
|---|---|---|
| label `Observação (opcional)` → `Observação` | `_insert_lote.html.erb` | yes — C8 `have_field("Observação (opcional)")` |
| `.ds-btn-secondary` border ink → rule | `application.css` | yes — C8 `borderTopColor` expected `27, 50, 41`, got `199, 213, 202` |
| `.ds-btn-danger` border margem → ink | `application.css` | yes — C8 Retirar `borderTopColor` expected `180, 55, 42`, got `27, 50, 41` |
| shared button padding `8px 16px` → `4px 4px` | `application.css` | yes — C8 `paddingTop` expected `8px`, got `4px` |
| `.ds-btn-secondary` fill transparent → sheet | `application.css` | yes — C8 `backgroundColor` expected `rgba(0, 0, 0, 0)`, got `rgb(255, 255, 255)` |

## Gate

`ruby bin/rspec` (34 named examples) — 34 passed, 0 failed at `42bd882`. Verification **PASS**.

## Ranked gaps

1. Mock Erro photo copy vs C5 XML unread only — Situação `Erro` is proven; that seed row is not.
2. `insert_batch` “twelve omit” is client-side; empty batch → `NF_FILES` unproven.
3. Visual spacing/colour/type weight beyond C8 tokens, enumerated per screen in the checklist.
