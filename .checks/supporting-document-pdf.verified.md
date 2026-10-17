# Supporting document PDF Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 2d39d9c..bf15b24
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

Opened binding sources as files in the repo (not URL fetch): `.specs/features/visual-identity/design.md` section `documents`; `.impeccable/mocks/documents-intake.html`; `.impeccable/mocks/document-edit.html`. Intake mock has no PDF-loaded state (scenes are idle / XML / JPEG photo / JPEG recibo). Edit mock is a JPEG receipt card plus `Foto · nota-padaria-central.jpg`. Checklist and design amendment correctly win for the PDF embed; no check contradicts a concrete label or composition those sources decide for a PDF-loaded square.

## Binding sources

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.specs/features/visual-identity/design.md` section `documents` | yes - file in repo | none. C1/C2 match the amendment: left proof previews an image PDF + `Limpar` inside the square; edit proof is an embed of the photo blob, not filename-only; lock copy matches `O arquivo não pode ser alterado. Exclua o documento e inclua novamente.` | list / justifications on `GET /supporting_documents` are drawn in the same section and are outside this cut’s screens row (insert + edit) |
| `.impeccable/mocks/documents-intake.html` | yes - file in repo | none. Mock preview is a text receipt card; checklist says this task wins for PDF preview | no PDF-loaded state in the mock |
| `.impeccable/mocks/document-edit.html` | yes - file in repo | none. Mock proof is a JPEG receipt + `Foto · nota-padaria-central.jpg`; task wins for `application/pdf` embed and `Foto · nota.pdf` | no PDF-loaded state in the mock |

Screens exemption is enumerated (`documents` insert / edit — spacing, colour, type weight), not a blanket “visual fidelity” clause.

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | PDF in `#identify-preview` is a page preview (not filename-only), copy `Foto · nota.pdf`, `Limpar` inside the square; JPEG/PNG `img[src^='blob:']` unchanged | `bin/rspec … -E "identify pdf shows…\|identify photo shows…"` both passed | `spec/system/document_identify_spec.rb:51` - `have_css("#identify-preview embed[src^='blob:']")`; `:52` - `text: "Foto · nota.pdf"`; `:53` - `#identify-preview button` `Limpar`; `:64` - `have_css("#identify-preview img[src^='blob:']")`. JPEG example is pre-existing in this file; this range adds only the PDF example | PASS |
| C2 | `GET …/edit` `200`; `aside[data-edit=proof]` embeds the PDF blob; `Foto · nota.pdf`; lock copy | `GET edit pdf photo embeds the blob in the proof square` passed | `spec/requests/supporting_documents_spec.rb:3637` - `have_http_status(:ok)`; `:3640-3642` - `embed[type='application/pdf']` present and `src` includes `rails/active_storage`; `:3643-3644` - proof text includes `Foto · nota.pdf` and the lock sentence | PASS |
| C3 | one-page CODE-128 PDF → chave `43260511222333000181550010000000011123456781`, `qr_url` nil | named example passed | `spec/models/photo_symbols_spec.rb:96-97` - `expect(result.chave).to eq(nfe_chave)` with `nfe_chave` `"43260511222333000181550010000000011123456781"` at `:9-11`; `expect(result.qr_url).to be_nil` | PASS |
| C4 | printed-digit PDF → same chave, `qr_url` nil | named example passed | `spec/models/photo_symbols_spec.rb:103-104` - `eq(nfe_chave)` and `qr_url` `be_nil` | PASS |
| C5 | fields PDF → `15500` Integer, `2026-05-11`, `Padaria Central` | named example passed | `spec/models/photo_fields_spec.rb:12-16` - `amount_cents` `eq(15500)`, `be_a(Integer)`, `not_to be_a(Float)`; `document_on` `Date.new(2026, 5, 11)`; `payee` `"Padaria Central"` | PASS |
| C6 | blank PDF → symbols chave nil; fields `Miss` | both named examples passed | `spec/models/photo_symbols_spec.rb:110` - `chave` `be_nil`; `spec/models/photo_fields_spec.rb:22` - `be_a(PhotoFields::Miss)` | PASS |
| C7 | blank then CODE-128 → first delivering chave | named example passed | `spec/models/photo_symbols_spec.rb:118` - `eq(nfe_chave)` | PASS |
| C8 | two CODE-128 pages → first page chave (C3) | named example passed | `spec/models/photo_symbols_spec.rb:127` - `eq(nfe_chave)`. Page-2 digits `4326…21987654321` are `other_chave` in setup (`spec/support/photo_extract_helpers.rb:6-8`), not at the assertion; first-page value is at the assertion | PASS |
| C9 | blank then fields → `15500` / `2026-05-11` / `Padaria Central` | named example passed | `spec/models/photo_fields_spec.rb:31-33` - those three values | PASS |
| C10 | identify Real two-page C7 PDF: no persist, empty errors, `nota_fiscal`, that chave | named example passed | `spec/models/supporting_document_spec.rb:1894-1897` - `SupportingDocument.count` `eq(0)`; `errors` empty; `kind` `"nota_fiscal"`; `chave` `eq(nfe_chave)` (`:28-30` same digits). “No A1” is a given, not an assertion | PASS |
| C11 | POST identify miss PDF: no persist, `200`, Foto / Recibo disabled, no chave, empty enabled fields, `Digitado`, submit disabled | named example passed | `spec/requests/supporting_documents_spec.rb:3436-3450` - `count` `0`; `have_http_status(:ok)`; `#arquivo` `"Foto"`; `#kind` `"recibo"` disabled; chave not visible; amount/date/payee `""` enabled; origin `"Digitado"`; submit disabled | PASS |
| C12 | POST create typed recibo PDF: persist `recibo`, `chave` nil, photo, `15500`, `302` | named example passed | `spec/requests/supporting_documents_spec.rb:3659-3668` - `have_http_status(:found)`; `count` `1`; `kind` `"recibo"`; `chave` nil; xml not attached; photo `nota.pdf` `application/pdf`; `amount_cents` `15500` | PASS |
| C13 | missing / error `pdftoppm` → chave nil and fields `Miss` | all four named examples passed | `spec/models/photo_symbols_spec.rb:136` and `:145` - `chave` `be_nil`; `spec/models/photo_fields_spec.rb:42` and `:51` - `be_a(PhotoFields::Miss)` | PASS |
| C14 | Dockerfile `base` (final `FROM base`) and CI `test` install `poppler-utils` before `bin/rspec` | both named examples passed | `spec/config/application_spec.rb:80` - base-stage packages `include("poppler-utils")`; `:88` - `packages.index("poppler-utils")` `<` `index("bin/rspec")`. Assemblies read directly: `Dockerfile:19` `poppler-utils` in `base`; `:61` `FROM base`; `.github/workflows/ci.yml:69` then `:79` `bin/rspec` | PASS |
| C15 | README names `pdftoppm` (Poppler) next to `tesseract`; without it PDF read is empty and fields stay typed | named example passed | `spec/config/application_spec.rb:94-97` - includes `` `tesseract` ``, `` `pdftoppm` ``, `Poppler`; match `/pdftoppm.*vazia.*digitad/m`. README.md:116-118 | PASS |

Proofs at HEAD (one invocation, `-E` regex; a first `-e` substring+pipes matched 0 examples and was discarded): **21 examples, 0 failures**. Each named proof appeared as `passed`.

## Coverage (recomputed)

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| designed screens (2) | `documents` insert C1 · `documents` edit C2 | list/justifications on the same design section are outside this cut |
| insert preview kinds (2) | PDF `embed[src^='blob:']` C1 · JPEG `img[src^='blob:']` C1 | - |
| Real PDF symbols (5) | CODE-128 C3 · printed digits C4 · blank miss C6 · later page C7 · first delivering C8 | Landing also names QR URL as a first-delivering stop; no PDF-QR example in this range (image QR remains a prior suite) |
| Real PDF fields (3) | Integer triple C5 · blank Miss C6 · later page C9 | - |
| identify / create (3) | Real delivering C10 · HTTP miss recibo C11 · HTTP typed recibo C12 | - |
| pdftoppm failure (2×2) | missing/error × symbols/fields C13 | - |
| Poppler host packages (2) | Dockerfile `base` C14 · CI `test` C14 | - |
| operator docs (1) | README `pdftoppm` C15 | - |
| startup config | `PhotoPdf.binary` default `"pdftoppm"` (`app/models/photo_pdf.rb:8-10`); `reset!` clears override (`:12-14`) | - |

HTTP claims C2 / C11 / C12 assert at the request layer (`:ok` / `:found`). No level gap.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | identify/create HTTP (`supporting_documents` requests) plus own-layer Real | boundary C11/C12 · own-layer C3–C10 | follow — status/persist at HTTP; one asserted PDF case per enumerated Real member at model |
| Decides, not reached across a boundary | `PhotoSymbols::Real` / `PhotoFields::Real` page walk | C3–C9, C13 | follow — one asserted case per member including miss and first-delivering |
| Entry point that decides nothing | n/a this cut | - | no set rows |
| Instrumentation / pass-through | `PhotoPdf` Open3 wrapper | none of its own; C13 through Real | follow |

## Swept existing (re-read)

- `PHOTO_EXT` still includes `.pdf` (`app/models/supporting_document.rb:3`)
- `MAX_BYTES` still `10_485_760` (`:2`)
- `PHOTO_LOCKED` is the C2 lock sentence (`:11`)
- unauthenticated `POST identify` still `302` to `/login` (`spec/requests/supporting_documents_spec.rb:3530`)
- `filter_parameters` still includes `:passphrase` and `:certificate` (`config/initializers/filter_parameter_logging.rb:6-8`)

## Faults injected

Scratch worktree `/tmp/sdp-verify-faults` at HEAD; real-tree porcelain empty before and after. Cap 5; one fault per assertion surface.

| Mutation | Location | Killed |
|---|---|---|
| `pdfFile` always `false` | `app/javascript/controllers/document_identify_controller.js` | yes — C1 `#identify-preview embed[src^='blob:']` missing |
| drop PDF `<embed>` on edit | `app/views/supporting_documents/edit.html.erb` | yes — C2 `embed` `present?` false |
| PDF branch of `PhotoSymbols::Real#scan` always `chave` nil | `app/models/photo_symbols.rb` | yes — C3 expected C3 chave, got nil |
| PDF branch of `PhotoFields::Real#read` always `Miss` | `app/models/photo_fields.rb` | yes — C5 expected `Fields` |
| remove `poppler-utils` from Dockerfile `base` apt line | `Dockerfile` | yes — C14 base packages exclude `poppler-utils` |

## Gate

`bin/rspec` (21 named proofs, `-E`) — 21 passed, 0 failed. Five mutants killed. No check without `file:line`. Binding sources opened. Profile `ui`.
