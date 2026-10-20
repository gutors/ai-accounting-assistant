# Lote insert proof and chave Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: `b263d9a53ca386fcbba1c1435bc9c2a02390d896`..`88be8a5562e16dd56522b8cc16009e5183e0030a` (`b263d9a`..HEAD)
**Round**: 2 - full (orchestrator asked every check re-proven, including C4 mutant)
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Opened as files in the repo (read, not URL-fetched).

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `app/views/supporting_documents/_insert_book.html.erb` (chave copy and Recibo hide) | yes - file | none on the bound slice: label is exactly `Chave de acesso (opcional)`; Recibo wraps `#chave` `hidden` and disables it | none on copy/hide. Field order in this file is arquivo → Tipo → Valor → Data → Favorecido → chave; the checklist binds this file for copy/hide only. Lote arrangement (chave immediately under Tipo) is the conversation + `_insert_lote.html.erb` |
| `DESIGN.md` The Chave Rule | yes - file | none. C7 records `font-mono` on `#chave`. Grouped eleven-of-four display is Out of scope (raw digits) | IBM Plex Mono stack / type weight enumerated unproven (screens table). “Mono only on the access key” as absence of `font-mono` on other lote book controls is not a check; treated as type, not a composition miss |
| `app/javascript/controllers/document_identify_controller.js` `paintProof` | yes - file | none. Identify uses `URL.createObjectURL`, image `thumb.src` + `alt = file.name`, PDF `embed` `src` blob | lote copies that pattern; C9–C11 cover image/PDF/XML. Retirar revoke is C12’s selected-XML-without-img, not `URL.revokeObjectURL` itself |

Screen `documents` insert coordinator lote (from `_insert_lote.html.erb` at HEAD): two regions — proof aside (`img` / `embed` / Arquivo) then book (`select#kind`, chave wrap, Valor/Data pair, Favorecido, Observação) plus toolbar/sheet. Arrangement checks: chave next named control after `#kind` (C7), Recibo chave not visible (C8), proof thumb inside `[data-document-lote-target=proof]` (C9, C11). Two-column `md:grid-cols` split is pre-existing lote, not this cut’s binding.

No blanket visual exemption: spacing, colour, type weight named for this screen.

## Checks

Proofs: one `bin/rspec` invocation over the three spec files with every `-e` name; documentation output 18 examples, 0 failures, 8.42s at `88be8a5`. Each name appeared as its own example.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | `insert_batch` JPEG+chave skips four photo ports; one row; chave and `15500`; failure `nil` | model + request `-e` both exit 0 | `spec/models/supporting_document_spec.rb:2033-2044` `not_to receive(:scan|:text|:fetch|:read)`; `failure` `nil`; `chave` `eq(nfe_chave)`; `amount_cents` `eq(15500)`. Request `spec/requests/supporting_documents_spec.rb:4175-4186` same ports + `:found`. Digit string is `nfe_chave` (`spec/models/supporting_document_spec.rb:28-29` / request `:26-27` = `43260511222333000181550010000000011123456781`), not at the `eq` line | PASS |
| C2 | identified consulta attaches XML; `15500`; `Padaria Central` | model + request `-e` both exit 0 | `spec/models/supporting_document_spec.rb:2055-2057` `doc.xml` `be_attached`; `amount_cents` `eq(15500)`; `payee` `eq("Padaria Central")`. Request `:4196-4200` same | PASS |
| C3 | create photo without typed chave still extracts | request + model `-e` both exit 0 (existing examples, still run at HEAD) | `spec/requests/supporting_documents_spec.rb:1960-1969` `post "/supporting_documents"` with no `chave` param; `chave` `eq(nfe_chave)` and `xml` `be_attached`. Model `:966-970` same persist | PASS |
| C4 | Incluir prontos FormData `documents[][chave]` equals identified chave | system `-e` exit 0 | interceptor `spec/system/document_lote_spec.rb:473-476` stores `chave` and `documents[][chave]` separately. `:492` `posted.first["chave"]` `eq([])`; `:493` `posted.first["documents"]` `include(lote_chave(0))` (`lote_chave(0)` = `…6780` at `:26-27`) | PASS |
| C5 | Incluir este POST includes `chave` | system `-e` exit 0 | `:506` `posted.first["documents"]` `eq([])`; `:507` `posted.first["chave"]` `eq([ lote_chave(0) ])` | PASS |
| C6 | recibo Incluir prontos: no/blank chave in FormData; persisted `chave` `nil` | system + request `-e` both exit 0 | `spec/system/document_lote_spec.rb:524-526` `chave` `eq([])`; `documents.all?(&:blank?)`; `find_by!(payee: "Mercado Bom Preço").chave` `be_nil`. Request `:4218-4219` `chave` `be_nil` | PASS |
| C7 | label exact; `#chave` next named after `#kind`; value; disabled; `font-mono` | system `-e` exit 0 | `spec/system/document_lote_spec.rb:535-547` `label[for=chave]` `eq("Chave de acesso (opcional)")`; disabled field; `class` `include("font-mono")`; `next_id` `eq("chave")`; value `eq(lote_chave(0))` | PASS |
| C8 | Recibo: Tipo Recibo; `#chave` not visible; disabled | system `-e` exit 0 | `spec/system/document_lote_spec.rb:556-558` `have_select("kind", selected: "Recibo", disabled: true)`; `not_to have_css("#chave", visible: true)`; `#chave` `disabled?` | PASS |
| C9 | selected jpg: proof `img` alt `empty.jpg`, `src` `blob:` | system `-e` exit 0 | `spec/system/document_lote_spec.rb:566-568` `img` inside proof; `alt` `eq("empty.jpg")`; `src` `start_with("blob:")` | PASS |
| C10 | selected XML: proof `img` not visible | system `-e` exit 0 | `spec/system/document_lote_spec.rb:577` `not_to have_css("[data-document-lote-target=proof] img", visible: true)` | PASS |
| C11 | selected pdf: visible `embed[type=application/pdf]` `blob:` | system `-e` exit 0 | `spec/system/document_lote_spec.rb:585-586` embed visible; `src` `start_with("blob:")` | PASS |
| C12 | Retirar jpg: filename gone; XML proof `img` not visible | system `-e` exit 0 | `spec/system/document_lote_spec.rb:597-599` `have_no_content("empty.jpg")`; padaria row present; proof `img` not visible | PASS |
| C13 | lote item photo+XML: `422` `Envie a foto ou o XML`; persist none | request + model `-e` both exit 0 | `spec/requests/supporting_documents_spec.rb:4236-4238` `count` `eq(0)`; `:unprocessable_content`; notice `eq("Envie a foto ou o XML")`. Model `:2073-2074` `count` `0`; `failure` `eq("Envie a foto ou o XML")` | PASS |

## Coverage (recomputed)

| Set (size) | Member -> proof | Gap |
|---|---|---|
| photo extract ports skipped (4) | `PhotoSymbols.scan` / `PhotoOcr.text` / `PublicNfceConsulta.fetch` / `PhotoFields.read` all C1 `not_to receive` | none |
| `insert_batch` still does (2) | identified consulta + XML attach C2; XML `AuthorizedNfe.parse` via existing `insert_batch two XMLs persists both or none` (`spec/models/supporting_document_spec.rb:1906`, persist both — not a C-check, not re-run) | none as a missing member; parse is outcome-not-call |
| create still extracts (1) | C3 | none |
| posted chave (3) | Incluir prontos `documents[][chave]` C4 isolated from `chave`; Incluir este `chave` C5 isolated from `documents[][chave]`; recibo nil C6 | none |
| lote chave chrome (2) | C7 · C8 | none |
| lote proof thumbs (4) | C9 · C10 · C11 · C12 | none |
| xor (1) | C13 | none |
| designed screens this cut (1) | `documents` insert coordinator lote C7–C12 | none |
| visual (3) | `font-mono` C7 | spacing, colour, type weight (enumerated) |

HTTP/status claims C1 request, C2 request, C3, C6 request, C13 sit at the request spec. C4/C5 are FormData at system, as the checklist allows for Stimulus.

## Test policy rows

Follows `.cursor/rules/rails.mdc` (decision at own layer + HTTP request spec; system only when request cannot settle).

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `SupportingDocument.insert_batch` / `submit(skip_photo_extract:)` | own layer C1/C2/C13 model · HTTP C1/C2/C13 request; create not-skip C3 | yes |
| Decides, not reached across a boundary | `document_lote_controller.js` FormData chave, Recibo hide, object-URL proof | system C4–C12 | yes — C4 now asserts `documents[][chave]` with `chave` empty; C5 the inverse; C6 both empty |
| Entry point that decides nothing | n/a this cut (`batch` still decides skip) | — | n/a |
| Instrumentation | identify `paintProof` copied, not re-specified | consumer C9–C11 | yes |

## Faults injected

Scratch: `git worktree add /tmp/lote-insert-verify-r2 HEAD`. Real-tree porcelain before and after: `?? .checks/lote-insert-proof-and-chave.verified.md` and `?? .impeccable/briefs/documents-batch-*.md`. Worktree removed.

| Mutation | Location | Killed |
|---|---|---|
| `documents[][chave]` → `chave` on Incluir prontos | `app/javascript/controllers/document_lote_controller.js` `includeReady` | yes — C4 `posted.first["chave"]` expected `[]` got two 44-digit keys |
| `chave` → `documents[][chave]` on Incluir este | same controller `postOne` | yes — C5 `posted.first["documents"]` expected `[]` got the Padaria chave |
| `skip_photo_extract: true` → `false` | `app/models/supporting_document.rb` `insert_batch` | yes — C1 model: `PhotoSymbols.current.scan` received 1 time |
| `chaveWrapTarget.hidden = false` always | `document_lote_controller.js` `paintBook` | yes — C8 `not_to have_css("#chave", visible: true)` |
| image `thumb.src = ""` instead of object URL | same controller `paintProof` | yes — C9 `src` `start_with("blob:")` |

Round-1 C13 xor mutant was not re-injected (surface untouched by the C4 interceptor fix; cap 5). C5 isolation is a new assertion surface from HEAD `88be8a5` and was injected.

## Swept existing (cited constraints)

- `require_coordinator_organization, only: :batch` — `app/controllers/supporting_documents_controller.rb:3`
- overlay `Incluindo documentos…` — `document_lote_controller.js:206`
- `Incluir prontos` disabled while `busy` — `:233`
- xor `NF_FILES` before skip extract — `supporting_document.rb:166-168`
- identified consulta not gated on `skip_photo_extract` — `should_consult` `:294-301`
- object URL revoke — `revokePreview` `:349-353`

## Gate

`bin/rspec` (18 named examples, 3 files, all `-e` names) — 18 passed, 0 failed at HEAD.

Verification **PASS**: 13/13 checks proven. 5/5 injected faults killed, including the round-1 C4 survivor.
