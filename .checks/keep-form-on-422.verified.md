# Keep form on 422 Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 82b0946..58076f32
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.tasks/keep-form-on-422.md` criteria 1–11, States, sweep, door, Unresolved 1 `Limpar` | yes - file | none | - |
| https://github.com/gutors/ai-accounting-assistant/issues/85 | yes - `gh issue view 85` (OPEN) | none (`Limpar` is the task transcription of Unresolved 1; #85 names the control, not the string) | - |
| `.specs/features/visual-identity/design.md` screens `documents` and `setup` | yes - file | none | spacing, colour, type weight (enumerated in Screens); Recibo hide, Data GET default, A1 fold chrome, ledger rows — out of this cut |

Issue #85, the task, and C1–C11 agree on: HTML `422` echo of document tipo/valor/data/favorecido/chave/observação; A1 senha not in HTML; Stream `422` must not replace the form node; `Limpar` beside Foto / XML / Arquivo without submit; no failed-upload stash; proofs NF without file, recibo+XML, chave `123`, A1 `errada`.

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | NF no files → no row, `422`, notice/toast `Envie a foto e/ou o XML`, echoed insert fields, empty `#photo`/`#xml` | `ruby bin/rspec … --example-matches "POST nota_fiscal without files echoes insert fields on 422"` exit 0 | `spec/requests/supporting_documents_spec.rb:366-376` — `have_http_status(:unprocessable_content)`, `error_notice_text` `eq("Envie a foto e/ou o XML")`, `fields[:kind].to eq("nota_fiscal")`, `expect_echoed_document_texts` (`:241-245` amounts `155,00` / `2026-05-11` / `Padaria Central` / `pago em dinheiro`), `expect_empty_file_input` photo and xml | PASS |
| C2 | Recibo+XML → no row, no blob, `422`, `Recibo não tem XML`, `#kind` `recibo`, texts, empty `#xml` | same batch, example ran | `spec/requests/supporting_documents_spec.rb:388-397` — count `0`, `:unprocessable_content`, notice/toast `Recibo não tem XML`, `fields[:kind].to eq("recibo")`, `expect_echoed_document_texts`, `expect_empty_file_input(fields[:xml])`; blob via `expect_no_stash` `:398` | PASS |
| C3 | NF chave `123` → no row, `422`, `Informe a chave de acesso com 44 dígitos`, `#chave` `123`, same texts | same batch | `spec/requests/supporting_documents_spec.rb:409-418` — count `0`, `:unprocessable_content`, notice/toast that string, `fields[:chave].to eq("123")`, `expect_echoed_document_texts` | PASS |
| C4 | A1 `errada` → no cert, `422`, open-failed copy, details `open`, empty file and passphrase, body has no `errada` | same batch | `spec/requests/sefaz_certificates_spec.rb:74-82` — `sefaz_titular_cnpj` `be_nil`, `:unprocessable_content`, notice `Não foi possível abrir o certificado com essa senha`, `expect_certificate_install_fold(..., open: true)`, `#certificate` type file value `""`, `#passphrase` `""`, `not_to include("errada")`; toast `:83-85` | PASS |
| C5 | Stream Accept → `422` turbo-stream, notice/toast that NF string, no `form[action="/supporting_documents"]` | same batch | `spec/requests/supporting_documents_spec.rb:430-436` — `:unprocessable_content`, `media_type` include `"turbo-stream"`, `turbo_stream_for(..., "[data-notice=error]")` and `[data-toast-kind=error]` include `Envie a foto e/ou o XML`, `at_css('form[action="/supporting_documents"]')` `be_nil` | PASS |
| C6 | Stream A1 `errada` → same transport, that open-failed string, no `errada`, no install form | same batch | `spec/requests/sefaz_certificates_spec.rb:108-115` — `:unprocessable_content`, `media_type` include `"turbo-stream"`, streams include the string, `not_to include("errada")`, form `be_nil` | PASS |
| C7 | Browser Recibo + `nota.xml` 422 keeps kind, texts, and `#xml` `nota.xml` | same batch | `spec/system/keep_form_on_422_spec.rb:43-50` — notice/toast `Recibo não tem XML`, `have_select("kind", selected: "Recibo")`, fields `155,00` / `2026-05-11` / `Padaria Central` / `pago em dinheiro`, `#xml` value include `"nota.xml"` | PASS |
| C8 | GET insert `Limpar` type=button next to `#photo` and `#xml`; click on photo clears without leaving the page | two examples in same batch | `spec/requests/supporting_documents_spec.rb:268-269` — `limpar_next_to` (`:210-214` parent `button` text `Limpar` `type=button` size 1); `spec/system/keep_form_on_422_spec.rb:62-65` — sibling `Limpar` click, `#photo` value `""`, `have_current_path("/supporting_documents")` | PASS |
| C9 | GET setup `Limpar` next to `#certificate`; click clears without leaving `/setup` | two examples in same batch | `spec/requests/setup_spec.rb:64-67` — sibling `Limpar` `type=button` size 1; `spec/system/keep_form_on_422_spec.rb:78-81` — click, `#certificate` `""`, path `/setup` | PASS |
| C10 | After C1–C4 `422`s: Blob count unchanged, A1 columns unchanged, session has no `errada` / PKCS12 bytes | C1–C4 examples | `expect_no_stash` on C1–C3 (`:377`, `:398`, `:419` → `:253-259` blobs and sefaz columns); C4 `:86-97` blobs, sefaz four nils, session `not_to include("errada")`, session values do not include PKCS12 der bytes | PASS |
| C11 | design.md `documents`/`setup`: Limpar beside Foto/XML/Arquivo; HTML 422 echo; senha not in HTML | same batch | `spec/docs/keep_form_on_422_spec.rb:9-22` — documents include `Limpar`, `Foto`, `XML`, `HTML 422 fallback`, field names, `file inputs stay empty`; setup include `Arquivo [Limpar]` and `HTML \`422\` does not write Senha into the HTML`. Adjacency in the live form is C8/C9, not this file-read | PASS |

## Screens (ui)

Nine Screens rows match the opened wireframes. Distinguishing arrangement this cut adds (Limpar beside file controls; Stream replaces notice/toast only; HTML file inputs empty; A1 senha absent) has checks. Visual unproven is enumerated as spacing, colour, type weight — not a blanket.

Pre-existing insert/setup composition (h1, notice under title, insert as first `section`, chave full width, Recibo hide, A1 fold) is already shipped (#79 / #82) and listed out of scope; C1’s named proof does not re-assert first-section / Foto-then-XML order. Not scored as a gap for this slice.

## Coverage

Recomputed from the checklist sets and the proofs above — not from the author’s table.

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| HTML `POST /supporting_documents` `422` echoes (3) | NF no file C1 · recibo+XML C2 · chave `123` C3 | - |
| HTML `POST /sefaz_certificate` passphrase `422` (1) | `errada` C4 | e-CPF / expired / wrap-key stay outside this cut |
| Turbo Stream `422` POSTs (2) | documents C5 · sefaz C6 | - |
| browser keep-file after Stream `422` (1) | Recibo + `nota.xml` C7 | - |
| `Limpar` file controls (3) | `#photo` C8 · `#xml` C8 presence · `#certificate` C9 | XML *click* not required by C8 (only photo click) |
| no failed-upload stash (3) | Blob C1–C4 · A1 columns C1–C4 · session `errada`/PKCS12 C4 | session PKCS12 on document `422`s not separately asserted (those POSTs have no pfx) |
| `422` transport (2) | HTML C1–C4 · Stream C5–C6 | - |
| designed screens this cut binds (2) | `documents` C1, C8, C11 · `setup` C4, C9, C11 | - |
| visual-identity screens this cut does not bind (4) | — | `login`, `denied`, `home`, `month` |
| `documents` / `setup` visual (3 × 9) | — | spacing, colour, type weight |

Status/route/shape claims C1–C6 are asserted in request specs (HTTP), not only below the boundary.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `SupportingDocument.insert` / `Organization#install_sefaz_certificate` (existing `:base` tables; this cut does not add a domain branch) | own layer already in model specs; HTTP echo/empty/stash C1–C4, C10 | yes — no new domain member |
| Decides, reached across a boundary | Accept dispatch `turbo_stream_refusal?` + `render_refusal_streams` in `ApplicationController`, called from the two creates | two-member HTTP contract: HTML C1–C4 · Stream C5–C6 | yes — both members asserted at the boundary where the branch lives |
| Entry point that decides nothing | n/a beyond the dispatch | — | n/a |
| Instrumentation / pass-through | `file_clear_controller.js` consumed by C8/C9 system clicks | consumer | yes |
| Browser APIs a request spec cannot settle | live file after Stream C7; Limpar click C8/C9 | system specs | yes |

## Swept existing

- `SupportingDocumentsController` `before_action :require_focused_organization` (`app/controllers/supporting_documents_controller.rb:2`)
- `SefazCertificatesController` `before_action :require_coordinator_organization` (`app/controllers/sefaz_certificates_controller.rb:3`)
- `filter_parameters` includes `:passphrase` (`config/initializers/filter_parameter_logging.rb:7`)
- Layout GET toast host: hidden `data-toast-kind="error"` without `data-toast` (`app/views/layouts/application.html.erb:27`); documents/setup always render `[data-notice=error]` (`_notice.html.erb:1`)

## Faults injected

Scratch: `git worktree add /tmp/keep-form-on-422-fault-verify HEAD`. Real-tree porcelain before: empty. After remove: empty. HEAD `58076f32`.

| Mutation | Location | Killed |
|---|---|---|
| `#amount` always `nil` | `app/views/supporting_documents/index.html.erb` | yes — C1 `expect(fields[:amount]).to eq("155,00")` |
| `turbo_stream_refusal?` always `false` | `app/controllers/application_controller.rb` | yes — C5/C6 `media_type` `text/html`; C7 `#xml` value `""` |
| passphrase field bound to `params[:passphrase]` | `app/views/setup/show.html.erb` | yes — C4 `#passphrase` got `"errada"` |
| removed `Limpar` buttons on photo, xml, certificate | insert + setup ERB | yes — C8/C9 GET size 0; system `ElementNotFound` sibling Limpar |
| dropped `Arquivo [Limpar]` (and insert Limpar marks) from design.md | `.specs/features/visual-identity/design.md` | yes — C11 `include("Arquivo [Limpar]")` |

C2/C3 share C1’s echo helper; C10 rides C1–C4. No surviving mutant. Cap 5.

## Gate

`ruby bin/rspec spec/requests/supporting_documents_spec.rb spec/requests/sefaz_certificates_spec.rb spec/requests/setup_spec.rb spec/system/keep_form_on_422_spec.rb spec/docs/keep_form_on_422_spec.rb --example-matches "<C1–C11 example names>"` — 12 passed, 0 failed (HEAD `58076f32`).
