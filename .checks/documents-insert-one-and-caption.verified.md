# Documents insert: one-file chrome, proof caption, readonly Tipo Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: `1cce389..294b44d` (`1cce389..HEAD`)
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)
**Prior round**: `.checks/documents-insert-one-and-caption.verified.md` at `5a44cdf` (FAIL — arrangement uncovered)
**Fix range**: `5a44cdf..294b44d` (`spec/system/document_lote_spec.rb`, `spec/system/document_lote_include_spec.rb`)

## Binding sources

Opened as files in the repo this round (step 1 re-done for coordinator insert). Mock idle `h2` `Incluir documento` and scene `Um arquivo` unlocked `select#kind` remain superseded by the task; those are not check-vs-source contradictions.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.impeccable/mocks/documents-insert-refine.html` scenes Vazio, Um arquivo, XML (tipo travado), Lote | yes - file (this round) | none vs checks once the task is the record for idle `h2` and locked Tipo | none that a selector reaches on coordinator insert. Split `minmax(0, 1fr) 28rem` from `768px` (`md:`), Limpar sharing the caption parent, lote stack split → toolbar → sheet then Sem mês are asserted on C2 and C6 |
| `.impeccable/surfaces/impeccable-mocks-documents-insert-refine-html.md` | yes - file (this round) | none (FIRST VIEWPORT idle heading and changeable select deferred to the task) | origin under book fields is existing, not this cut |
| `.tasks/documents-insert-one-and-caption.md` | carried from `5a44cdf` | none — C1–C18 match criteria 1–18 | - |
| `DESIGN.md` primary button | carried from `5a44cdf` | none — C2 asserts caixa `rgb(46, 107, 78)`, sheet `rgb(255, 255, 255)`, padding `8px` `16px`, class `ds-btn-primary` | colour beyond that primary is in Visual unproven |

Mock `Incluir outro arquivo` is Out of scope. Mock unlocked `select#kind` on Um arquivo and idle `h2` `Incluir documento` sit in Coverage Unproven as the task directed. Visual unproven columns name spacing, colour, type weight per screen (plus the C10/C11/C2 exceptions) — not a blanket exemption.

### Screen `documents` insert coordinator (step 1 this round)

Mock CSS `.split` at `min-width: 768px` is `grid-template-columns: minmax(0, 1fr) 28rem` (`.impeccable/mocks/documents-batch.css:180-182`). Mock caption holds stamp + Limpar (`.impeccable/mocks/documents-insert-refine.html:141-144`). Editor children are split, then one-file or lote toolbar, then lote sheet, then Sem mês (`:135-250`).

C2 now asserts computed two grid tracks, class `md:grid-cols-[minmax(0,1fr)_28rem]`, book `max-w-[28rem]`, and Limpar `parentElement` equal to caption. C6 now asserts editor children split → `toolbar` → `sheet`, sheet above `#sem-mes`, and the same split/book classes. Cuprite `screen_size: [1280, 900]` is above `md` (768px). Round-1 arrangement FAIL is closed.

## Checks

Proofs all re-ran at `294b44d` (26 examples, 0 failed). Request-spec assertions the fix did not touch are `carried from 5a44cdf`. Citations in `spec/system/document_lote_spec.rb` are `verified at 294b44d`.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | empty GET `200`, `h2` `Incluir documentos`, one `input[type=file][multiple]`, no Situação sheet, no `Incluir prontos` | “GET coordinator empty insert is lote drop” passed at `294b44d` | carried from `5a44cdf`: `spec/requests/supporting_documents_spec.rb:4040` `:ok`; `:4042` `h2`; `:4044-4045` one file + `multiple`; `:4048-4049` no `Situação` / `Incluir prontos`. Also `:4050-4051` next `section` is Sem mês | PASS |
| C2 | one XML: `h2` `Incluir documento`, no Situação / prontos / este / Retirar, Limpar in proof, primary `Incluir documento` `ds-btn-primary` caixa/sheet/`8px` `16px` | “one XML is simple include chrome” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:76` heading; `:77` `expect_no_situacao_sheet`; `:78-80` no este/Retirar, Limpar in proof; `:81-88` Limpar and caption share `parentElement`; `:89-99` two computed columns, `md:grid-cols-[minmax(0,1fr)_28rem]`, book `max-w-[28rem]`; `:100-112` primary class + padding + `46, 107, 78` / `255, 255, 255` | PASS |
| C3 | Incluir documento persists Padaria XML xor, Sem mês, empty drop, stays on `/supporting_documents` | “Incluir documento one XML persists Padaria and empty drop” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:121-131` Sem mês texts, empty `h2`/`drop`, `have_current_path("/supporting_documents")`, `kind` `nota_fiscal`, `amount_cents` `15500`, xml attached, photo not, count `1`. Does not assert HTTP `302` vs Turbo `200` | PASS |
| C4 | Limpar: count `0`, empty drop, Limpar gone | “Limpar one XML returns empty drop” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:140-143` | PASS |
| C5 | empty Digitar Incluir documento persists nothing | “Incluir documento empty Digitar persists nothing” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:153` count `0` (toast is extra) | PASS |
| C6 | second XML opens lote heading, sheet heads, two filename rows, toolbar order, no Limpar | “second XML opens lote chrome” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:163-175` heading, heads, filenames, toolbar labels/classes, no Limpar; `:176-192` editor children split → toolbar → sheet and sheet above `#sem-mes`; `:193-202` two columns, `md:grid-cols-[minmax(0,1fr)_28rem]`, book `max-w-[28rem]` | PASS |
| C7 | Retirar to one restores simple include | “Retirar down to one restores simple include” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:212-215` | PASS |
| C8 | in-flight identify: copy, no Situação sheet, count `0` | “one file identify in flight has no Situacao sheet” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:233-235` | PASS |
| C9 | unreadable XML: count `0`, notice/toast, no sheet, Limpar | “one unreadable XML has Limpar and no Situacao sheet” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:242-245` | PASS |
| C10 | no `#arquivo`; caption `FOTO` `strong` weight `600` ` - ` filename under image; no stacked tipo lines | “one jpg caption is FOTO filename under image” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:253-272` | PASS |
| C11 | caption `XML` `strong` `600` ` - ` `proc-nfe-padaria.xml`, no `#arquivo` | “one XML caption is XML filename” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:280-285` | PASS |
| C12 | lote Padaria caption + `aria-selected`; XML `img` hidden; jpg/pdf object-URL thumbs | four examples passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:294-298` Padaria caption + selected + no visible img; `:391-393` jpg `blob:` img; `:402` XML img not visible; `:410-411` pdf `blob:` embed | PASS |
| C13 | `label[for=kind]` Tipo; `input#kind` `Nota fiscal` readonly not disabled; no visible `select#kind`; next named control `#chave` | “one XML Tipo is readonly input then chave” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:306-320` | PASS |
| C14 | `input#kind` readonly `Recibo`; Valor/Data/Favorecido empty enabled origin Digitado; chave hidden | “one jpg Tipo is readonly Recibo and hides chave” passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:327-334` | PASS |
| C15 | Incluir prontos (2) persists both XMLs into Sem mês | system + request passed at `294b44d` | verified at `294b44d`: `spec/system/document_lote_spec.rb:346-351`; carried from `5a44cdf`: `spec/requests/supporting_documents_spec.rb:4089-4094` `:found` + both rows | PASS |
| C16 | submitter GET: `h2` `Incluir documento`, file not `multiple`, wait copy, no `Incluir prontos` | “GET submitter empty insert stays one-file square” passed at `294b44d` | carried from `5a44cdf`: `spec/requests/supporting_documents_spec.rb:4061-4065` | PASS |
| C17 | edit / Sem mês / Justificativas / submitter justify unchanged | five examples passed at `294b44d` | carried from `5a44cdf`: `spec/requests/supporting_documents_spec.rb:3063-3064` `200` `Editar documento`; `:2635` Sem mês heads; `spec/requests/justifications_spec.rb:168-170` coordinator includes; `:139` submitter omits; `:27-30` POST `200,00` | PASS |
| C18 | unauthenticated GET `302` `/login` | “unauthenticated GET /supporting_documents responds 302 to /login” passed at `294b44d` | carried from `5a44cdf`: `spec/requests/supporting_documents_spec.rb:62-63` | PASS |

## Coverage (recomputed)

Authority for insert N / chrome did not change in `5a44cdf..HEAD` (tests only). Members carried from `5a44cdf`; join still holds at `294b44d`.

| Set (size) | Members from authority | Proof | Gap |
|---|---|---|---|
| coordinator insert N (3) | JS `items.length` 0 / 1 / `>=2` | empty C1 · one C2 · N≥2 C6 | none |
| one-file exits (3) | Incluir / Limpar / Retirar to one | C3 · C4 · C7 | none |
| caption stamps (2) | `arquivo` `XML` vs `Foto` → uppercase | `FOTO` C10 · `XML` C11 · lote XML C12 | none |
| Tipo after identify (2) | `Nota fiscal` / `Recibo` | C13 · C14 | none |
| persist from this chrome (3 listed as 2) | one XML · two XMLs · empty Digitar none | C3 · C15 · C5 | table size says 2; members are proven |
| other roles (3) | submitter · unauthenticated · edit/Sem mês/Justificativas | C16 · C18 · C17 | none |
| designed scenes (4) | mock Vazio, Um arquivo, XML (tipo travado), Lote | C1 · C2/C10/C14 · C2/C11/C13 · C6/C12 | mock idle `h2` and unlocked `select#kind` listed Unproven on purpose |
| lote proof thumbs (3) | jpg img · XML no img · pdf embed | C12 three examples | none |

Status/route claims C1, C16, C17, C18, C15 HTTP assert at the request boundary. C3’s “no remainder `302`” is proven only as `have_current_path` in a system spec.

## Test policy rows

File `spec/system/document_lote_spec.rb` was touched; that row re-judged at `294b44d`. Other rows carried from `5a44cdf`.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | persist `POST` batch / one include | HTTP C15 · UI C3, C5, C15 system | yes — carried from `5a44cdf` |
| Decides, not reached across a boundary | Stimulus `N=0/1/>=2`, caption stamp, readonly Tipo, now also split/stack | own layer; repo has no JS unit runner → system analogue `document_lote_spec.rb` | yes — C2–C14 plus arrangement on C2/C6 (`294b44d`) |
| Entry point that decides nothing | GET empty coordinator/submitter/unauthenticated | request C1, C16, C18 | yes — carried from `5a44cdf` |
| Instrumentation | helpers that only forward | none | n/a |

`.cursor/rules/rails.mdc` still answers both allocation questions. System specs for chrome match “only when a request spec cannot settle the claim.”

## Swept existing

Carried from `5a44cdf`; constraints re-confirmed present:

- `SupportingDocument::KIND_LOCKED` is in `app/models/supporting_document.rb:13`.
- xor slotting is `SupportingDocument.slot_uploads` (`app/models/supporting_document.rb:54`).
- Rows marked n/a or not in scope were not re-litigated.

## Faults injected

Round-1 kills (empty `h2`, `loteSheet() >= 1`, `includeOne()` no-op, caption stamp `"X"`, drop `readonly` on `#kind`) carried from `5a44cdf` — product code unchanged in the fix.

This round: scratch worktree `/tmp/tlc-verify-docs-insert-r2` at `294b44d`. Real-tree porcelain before and after: untracked `.checks/documents-insert-one-and-caption.verified.md` and four `.impeccable/briefs/*.md` only. Worktree removed.

| Mutation | Location | Killed |
|---|---|---|
| split class `md:grid-cols-[minmax(0,1fr)_28rem]` → `md:grid-cols-1` | `_insert_lote.html.erb:10` | yes — C2 `spec/system/document_lote_spec.rb:97` `split["cols"]` expected `2` got `1` |
| Limpar moved out of caption flex (still in proof) | `_insert_lote.html.erb` caption row | yes — C2 `:88` `caption_row` expected `true` got `false` |
| toolbar moved before the split as first editor child | `_insert_lote.html.erb` editor | yes — C6 `:189` `order["first"]` expected `"split"` got `"toolbar"` |

## Gate

`bin/rspec` with the 26 named `-e` filters on `spec/system/document_lote_spec.rb`, `spec/requests/supporting_documents_spec.rb`, `spec/requests/justifications_spec.rb` at `294b44d` — 26 passed, 0 failed (each `full_description` listed in `/tmp/tlc-verify-r2.json`).

## Gaps (ranked)

1. **C3 `302`** — Claim names a full-page `302`; the proof asserts path + empty drop, not status. Not a red test; thinner than the wording. Carried from `5a44cdf`.
2. **Coverage table size** — persist set listed as size 2 with three members. Proven; table arithmetic only.

Round-1 arrangement gaps (split `28rem`/`768px`, Limpar in the caption row, lote editor stack) are closed on C2 and C6.
