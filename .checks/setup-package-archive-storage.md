# Setup: package archive storage

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/setup-package-archive-storage.md` marks screen `setup` binding through `.specs/features/visual-identity/design.md` (criterion 11 / C13).

Sources:

- `.tasks/setup-package-archive-storage.md` - criteria 1–13, the state diagram, the sweep, zero doors, Unresolved 1–2 open (Editar is a GET; no `Cancelar`). Nothing under Unresolved is settled while building
- https://github.com/gutors/ai-accounting-assistant/issues/81 - **binding for this slice**: heading `Armazenamento do pacote mensal`; copy `Drive` → `Google Drive`; after `Salvar arquivo`, URL standing (not a second `Salvar arquivo`); `Editar` unlocks; `Confirmar` persists; toast on confirm; certificado out
- user delegated - Contador leitura must not use the same chrome as editable inputs; archive URL Leitura uses that same labeled-text style
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent: one tlc-plan slice; toast helper already shipped (#76); profile `ui`
- https://github.com/gutors/ai-accounting-assistant/issues/76 - `PATCH /package_archive` success already toasts `Pronto.`; field-only `422` has no toast
- https://github.com/gutors/ai-accounting-assistant/issues/80 - Contador `GET /setup?edit=accountant`; formatted CPF/CNPJ on read; C12 keeps edição as inputs
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screen `setup`. Opened as a file in the repo. Section `setup` today still draws `Arquivo do pacote` as always `URL da pasta do Drive` / `[Salvar arquivo]` and Contador leitura as read-only inputs. C13 amends that section. SEFAZ install form, banks (`details` `Editar`), and extras stay as opened except the archive heading
- `app/views/setup/show.html.erb` - today’s always-writable archive form and Contador `input[readonly]` on leitura
- `Organization#update_package_archive`, `DriveFolderUrl` - persist and reject; C7–C8 do not change the parse table
- Open defaults in Unresolved 1–2 - Editar is a GET; no `Cancelar`; `GET /setup` without the archive Editar URL is Leitura (C3)

## Out of scope

- Changing `PATCH /accountant` acceptance, labels, tax-id format, or cadastro / edição as inputs — #80; this cut only replaces leitura `input[readonly]` with labeled text (C9, C10, C12)
- Making the standing URL an `<a href>` to Drive
- Hiding empty optional accountant fields — empty values stay as empty `p` nodes (C10)
- Certificado SEFAZ, contas bancárias, tipos extras — #82–#84
- Keeping a typed invalid URL on `422` — #85 is document and A1; archive `422` still re-renders from the stored organization (C7, C8)
- Changing `DriveFolderUrl.parse` acceptance (HTTPS `drive.google.com` `/folders/<id>`, blank clears, file URL `422`)
- Glossary rename of **Package archive**; UI copy only
- Drive writer OAuth, close-for-send, month-folder restore
- `Cancelar` on edit — Unresolved 2; `GET /setup` without the archive Editar URL is Leitura (C3)
- Settling Unresolved 1–2

## Landing

Touches `GET /setup` Armazenamento and Contador leitura HTML (`setup/show`, `SetupController`) and the existing `PATCH /package_archive` `422` re-render (`PackageArchivesController`). Reuses `Organization#update_package_archive`, `DriveFolderUrl.parse`, `#76` `Pronto.` toast, `require_coordinator_organization`, and the #80 `params[:edit]` query. No schema change; no new named resource.

None — `PATCH /package_archive` and `DriveFolderUrl` already exist. Labeled-text Leitura copies the certificado titular `p.font-medium` already on this screen; it is reversible HTML. Editar as a GET (Unresolved 1) extends the existing `params[:edit]` query #80 used for Contador; it is not a new resource. `Confirmar` is the submit label on archive edição only.

- Nothing else in this change is hard to reverse

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at its own layer **and** one request spec at HTTP | one asserted case per enumerated member at its own layer; status and who may call at the boundary | follow |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` names the level and the sampling rule: a decision is proven at its own layer, one asserted case per enumerated member; HTTP also gets a request spec; system specs only when a request spec cannot settle the claim
- Armazenamento Cadastro / Leitura / Edicao and Contador leitura chrome are view decisions with no new model table. `Organization#update_package_archive` / `DriveFolderUrl.parse` stay existing. Closest analogue: `spec/requests/setup_spec.rb` and `spec/requests/package_archives_spec.rb` — request specs assert HTML. This repo has no view specs
- `PATCH /package_archive` 302 / 422 / auth stay existing (`package_archives_spec`, `organization_spec`). C7–C8 add the HTML of the mode that submitted (edição `Confirmar` vs cadastro `Salvar arquivo`). Own-layer parse rows already live in `organization_spec`
- System specs are not required: every named observation is HTML or status a request spec can read

Cost: request examples for C1–C12; file-read example for C13. No new model spec. Without the C7 HTML proof, a 422 after a standing URL could render `p#url` and every persist example would still pass.

## Checks

Criteria 1–13 map to C1–C13. Unresolved 1–2 stay GET-of-Editar and no `Cancelar`.

### S1 - Cadastro copy when there is no URL · 4 files · 35 KB · ~9k

**C1** - Given a signed-in coordinator of the focused organization with no `package_archive_url`, when `GET /setup` runs, then the status is `200`, the body includes heading `Armazenamento do pacote mensal` and `Cole a URL da pasta do Google Drive`, `form[action="/package_archive"]` includes `Salvar arquivo` and `input#url` whose classes include `border-rule` and `bg-sheet` and which does not have `readonly` or `disabled`, the label for `#url` is `URL da pasta do Google Drive`, the Armazenamento section (from heading `Armazenamento do pacote mensal` through heading `Certificado SEFAZ`) does not include a control whose text is `Editar` and does not include `Confirmar`, and the body does not include `Arquivo do pacote`, `Cole a URL da pasta do Drive`, or `URL da pasta do Drive`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup cadastro archive form is writable with Google Drive copy"`

**C2** - Given that empty organization, when `PATCH /package_archive` runs with `https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl`, then the response is `302` to `/setup`, that URL and folder id `15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl` are persisted, and the following `GET /setup` has `[data-toast-kind="success"]` text `Pronto.` and matches the read-only observations in criterion 3.
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive from cadastro persists folders URL and toasts Pronto"`

### S2 - Standing URL as labeled text · 3 files · 32 KB · ~8k

**C3** - Given the focused organization has `package_archive_url` `https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl`, when `GET /setup` runs, then the Armazenamento section has label text `URL da pasta do Google Drive`, has `p#url` with class `font-medium` and that URL as its text, has no `input` `textarea` or `select`, has no `Salvar arquivo`, has no `Cole a URL da pasta do Google Drive`, has no `Confirmar`, and includes a control whose text is `Editar`. `p#url` classes do not include `border-rule` or `bg-sheet`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup leitura archive is labeled text"`

**C4** - Given that standing URL, when `PATCH /package_archive` runs with `url` `""`, then the response is `302` to `/setup`, `package_archive_url` and `package_archive_folder_id` are absent, and the following `GET /setup` matches criterion 1.
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive blank URL returns cadastro"`

### S3 - Editar, then Confirmar or 422 · 5 files · 37 KB · ~9k

**C5** - Given the organization in criterion 3, when `GET` of the Armazenamento `Editar` control’s URL runs, then the status is `200`, `form[action="/package_archive"]` includes `Confirmar` and `input#url` whose classes include `border-rule` and `bg-sheet`, `#url` has no `readonly` or `disabled` and value `https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl`, the label matches criterion 1, and the Armazenamento section has no `Editar`, no `Salvar arquivo`, and no `p#url`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET of Armazenamento Editar unlocks the writable archive form"`

**C6** - Given that writable form, when `PATCH /package_archive` runs with `https://drive.google.com/drive/folders/1AbCdEfGhIjKlMnOpQrStUvWxYz123456`, then the response is `302` to `/setup`, that URL and folder id `1AbCdEfGhIjKlMnOpQrStUvWxYz123456` are persisted, and the following `GET /setup` matches the read-only observations in criterion 3 for the new URL and has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive from Editar 302s to leitura and toasts Pronto"`

**C7** - Given the organization in criterion 3, when `PATCH /package_archive` runs with `https://drive.google.com/file/d/0B_NiLAzvehC9R2stRmQyM3ZiVjQ/view`, then the status is `422`, the stored URL stays `https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl`, there is no `[data-toast]`, and `form[action="/package_archive"]` is the writable form in criterion 5 (`Confirmar` present, `input#url` not `readonly`).
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive 422 file URL stays Confirmar"`

**C8** - Given no `package_archive_url`, when `PATCH /package_archive` runs with `https://example.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl`, then the status is `422`, URL and folder id stay absent, there is no `[data-toast]`, and `form[action="/package_archive"]` is the cadastro form in criterion 1 (`Salvar arquivo` present, `input#url` with `border-rule` `bg-sheet`).
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive 422 during cadastro stays Salvar arquivo"`

### S4 - Contador leitura uses the same labeled-text chrome · 4 files · 32 KB · ~8k

**C9** - Given the focused organization has `accountant_presentation_name` `Ana Contábil`, `accountant_tax_id` `11222333000181`, `accountant_legal_name` `Contábil LTDA`, `accountant_pix_key` `chave-pix`, and `package_destination_email` `ana@example.com`, when `GET /setup` runs, then the Contador section (heading `Contador` through heading `Armazenamento do pacote mensal`) has no `input` `textarea` or `select`, has `p#presentation_name` `Ana Contábil`, `p#tax_id` `11.222.333/0001-81`, `p#legal_name` `Contábil LTDA`, `p#pix_key` `chave-pix`, and `p#destination_email` `ana@example.com`, each of those `p` nodes has class `font-medium` and does not have `border-rule` or `bg-sheet`, the labels for those ids stay `Nome de apresentação`, `CPF/CNPJ (preencher apenas números)`, `Razão social`, `PIX`, and `Email para envio`, there is no `Salvar contador` and no `Cadastre o contador`, and that section includes a control whose text is `Editar`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup leitura accountant fields are labeled text with formatted CNPJ"`

**C10** - Given `accountant_presentation_name` `Ana` and `accountant_tax_id` `39053344705` and no razão social, when `GET /setup` runs, then `p#tax_id` is `390.533.447-05` and `p#legal_name` is empty. Given `accountant_presentation_name` `Ana` and the four optional accountant fields blank, `p#tax_id` `p#legal_name` `p#pix_key` and `p#destination_email` are empty and `Editar` is still present. `accountant_tax_id` on `Organization` stays digits-only; those GETs do not persist punctuation.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup leitura formats CPF and empty razao social"`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup leitura with blank optionals still has Editar"`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup leitura does not persist tax id punctuation"`

### S5 - Shared edit query and binding setup wireframe · 4 files · 38 KB · ~10k

**C11** - Given the organization in criterion 9 and the archive URL in criterion 3, when `GET /setup?edit=package_archive` runs, then the Armazenamento form matches criterion 5 and the Contador section matches criterion 9 (labeled text, `Editar` present).
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup edit=package_archive unlocks archive and keeps accountant leitura"`

**C12** - Given that same organization, when `GET /setup?edit=accountant` runs, then `form[action="/accountant"]` includes `Salvar contador` and `input#presentation_name` `input#tax_id` `input#legal_name` `input#pix_key` `input#destination_email` whose classes include `border-rule` and `bg-sheet` and which have no `readonly` or `disabled`, `#tax_id` value is `11222333000181`, there is no `p#presentation_name`, and the Armazenamento section matches criterion 3 (`p#url`, `Editar` present, no `Confirmar`).
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup edit=accountant unlocks accountant and keeps archive leitura"`

**C13** - `.specs/features/visual-identity/design.md` section `setup` — `GET /setup` no longer shows `Arquivo do pacote` as an always-writable `URL da pasta do Drive` / `[Salvar arquivo]`, and no longer shows Contador leitura as the same bordered `sheet` inputs as cadastro. It shows heading `Armazenamento do pacote mensal`; cadastro when there is no URL (`Cole a URL da pasta do Google Drive`, label `URL da pasta do Google Drive`, `[Salvar arquivo]`); standing URL as labeled `font-medium` text plus `Editar`; `GET /setup?edit=package_archive` as `input#url` with `[Confirmar]`. Contador leitura is the same labeled-text chrome for the five values (formatted CPF/CNPJ on read); cadastro and `GET /setup?edit=accountant` keep the input chrome. The Contador bullet no longer says the archive stays always-writable for #81.
Proof: `bin/rspec spec/docs/setup_package_archive_storage_spec.rb -e "visual-identity setup archive is cadastro or labeled text"`

## Screens (ui)

Design opened: `.specs/features/visual-identity/design.md` (file in the repo). Until C13 lands, Armazenamento copy and Cadastro / Leitura / Edicao arrangement values are the task transcription; Contador leitura labeled `p.font-medium` is the task transcription; two-column accountant form from 768px, SEFAZ, banks (`details` `Editar`), and extras come from the opened `setup` section.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `setup` Armazenamento, cadastro | heading `Armazenamento do pacote mensal`; `Cole a URL da pasta do Google Drive`; label `URL da pasta do Google Drive`; `input#url` `border-rule` `bg-sheet` not `readonly`; `Salvar arquivo`; no `Editar`; no `Confirmar`; body has no `Arquivo do pacote`, `Cole a URL da pasta do Drive`, or `URL da pasta do Drive` C1 | h2 after Contador, before `Certificado SEFAZ`; writable field lives in `form[action="/package_archive"]` C1, C13 | spacing, colour, type weight |
| `setup` Armazenamento, leitura | label `URL da pasta do Google Drive`; `p#url.font-medium` (not `border-rule` `bg-sheet`); `Editar`; no `input`/`textarea`/`select` in the section; no `Salvar arquivo`; no `Cole a URL da pasta do Google Drive`; no `Confirmar` C3 | standing value is a `p`, not an `input`; `Editar` is in the Armazenamento section (not bank-account `details`) C3, C13 | spacing, colour, type weight |
| `setup` Armazenamento, edicao | `Confirmar`; `input#url` `border-rule` `bg-sheet` not `readonly`; current URL as value; same label; no `Editar`; no `Salvar arquivo`; no `p#url` C5, C7 | GET of the Armazenamento `Editar` URL (or `422` re-render) is still `GET /setup` HTML, not a new resource C5, C7, C11 | spacing, colour, type weight |
| `setup` Contador, leitura | five `p.font-medium` values (ids `presentation_name` `tax_id` `legal_name` `pix_key` `destination_email`); formatted CNPJ or CPF on `#tax_id`; empty optionals as empty `p`; `Editar`; no `input`/`textarea`/`select`; no `Salvar contador`; no `Cadastre o contador`; same five labels C9, C10 | labeled text in the Contador section through heading `Armazenamento do pacote mensal`; two-column order unchanged C9, C13 | spacing, colour, type weight |
| `setup` Contador, cadastro and edicao | cadastro and `GET /setup?edit=accountant` keep five `input` `border-rule` `bg-sheet` and `Salvar contador` C12 | `edit=accountant` does not unlock Armazenamento; `edit=package_archive` does not unlock Contador C11, C12 | spacing, colour, type weight |

## Swept

- validation: existing `DriveFolderUrl.parse` / `Organization#update_package_archive`; C7, C8 — rejected URLs still `422` and do not persist
- failure modes: C7 — `422` during edição re-renders `Confirmar` and `input#url`, not `p#url`; C8 — `422` during cadastro re-renders `Salvar arquivo`
- idempotency and retry: C6 — a second identical `PATCH` still `302` and Leitura; C3 — a second `GET /setup` stays Leitura
- authorization: existing — `require_coordinator_organization` on `SetupController` and `PackageArchivesController`; this cut does not add a route
- concurrency and ordering: n/a — two overlapping `PATCH /package_archive` leave the last write; no new unique index or ordering
- data lifecycle: C3, C9 — organizations that already have `package_archive_url` or `accountant_presentation_name` render labeled text on first `GET /setup` after this ships; no backfill; clearing the URL (C4) returns Cadastro
- external-dependency failure: n/a — archive save parses the URL in-process and does not call the Drive writer
- state transitions: C1, C2, C4, C5, C6, C7, C8
- observability: n/a — the source names no log, metric, or trace; the person sees the form and the existing toast

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| Armazenamento form modes (3) | Cadastro C1 · Leitura C3 · Edicao C5 | - |
| `PATCH /package_archive` outcomes this cut observes (5) | cadastro persist `302` C2 · clear URL `302` C4 · edit persist `302` C6 · file URL `422` C7 · wrong host cadastro `422` C8 | existing http / missing `/folders/` / u/0 query / auth stay in `package_archives_spec` |
| Contador leitura samples (3) | full CNPJ row C9 · CPF without razão C10 · name only C10 | - |
| `#tax_id` display on leitura (3) | formatted CNPJ C9 · formatted CPF C10 · blank empty `p` C10 | digits on Edicao stay C12 |
| `params[:edit]` isolation (2) | `package_archive` C11 · `accountant` C12 | - |
| tax id storage after GET (2) | CNPJ digits C10 · CPF digits C10 | - |
| designed screens this cut binds (1) | `setup` C1, C3, C5, C9–C13 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `month`, `documents` — out of scope |
| `setup` visual (3 properties × Armazenamento 3 modes + Contador leitura) | — | spacing, colour, type weight on archive cadastro, leitura, edicao, and Contador leitura |

- Claims naming a status code, route or response shape: C1, C2, C4, C5, C6, C7, C8, C9, C11, C12 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~9k + S2 ~8k + S3 ~9k + S4 ~8k + S5 ~10k = ~44k token floor. All five slices share `setup/show.html.erb` and `setup_spec.rb`; unique files sit under ~40k bytes plus the opened design (~20 KB). All five stay under 150k and share screen `setup`. No split. One batch.

- Where the boundary fell: one batch; C1–C13 closed on this branch after the product commit.
- What the user settled mid-build: none.
- What was abandoned: wrapping standing Leitura in `form_with` and swapping `input[readonly]` for `p` — the authenticity token is an `input`, which C3 and C9 forbid.
