# Setup: accountant read-only after save

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/setup-accountant-read-after-save.md` marks screen `setup` binding through `.specs/features/visual-identity/design.md` (criterion 11).

Sources:

- `.tasks/setup-accountant-read-after-save.md` - criteria 1–11, the state diagram, the sweep, zero doors, Unresolved 1–2 open (Editar is a GET; no `Cancelar`). Nothing under Unresolved is settled while building
- https://github.com/gutors/ai-accounting-assistant/issues/80 - **binding for this slice**: labels `CPF/CNPJ (preencher apenas números)` and `Email para envio`; after the first save with data, read-only fields plus `Editar`; formatted CPF/CNPJ on read; empty stays cadastro; toast on save; package archive is #81
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent: one tlc-plan slice; #80 is Contador read after save; toast helper already shipped (#76); profile `ui`
- https://github.com/gutors/ai-accounting-assistant/issues/76 - `PATCH /accountant` success already toasts `Pronto.`; field-only accountant `422` has no toast
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screen `setup`. Opened as a file in the repo. Section `setup` today still draws Contador as always `Id fiscal` / `Destino do pacote` / `[Salvar contador]`. C11 amends that section. Two-column accountant form from 768px, archive `Salvar arquivo`, SEFAZ, banks, and extras stay as opened except Contador
- `app/views/setup/show.html.erb` - today’s always-writable accountant form (`Id fiscal`, `Destino do pacote`, `Salvar contador`)
- `Organization#update_accountant`, `BrazilianTaxId` - persist digits and format; C6 forbids storing the display punctuation
- Open defaults in Unresolved 1–2 - Editar is a GET; no `Cancelar`; `GET /setup` without the Editar URL is Leitura (C3–C5)

## Out of scope

- Arquivo do pacote read-only / `Editar` → `Confirmar` — #81
- Certificado SEFAZ, contas bancárias, tipos extras — #82–#84
- Keeping typed values on document or A1 `422` — #85
- Changing `PATCH /accountant` acceptance (CPF/CNPJ check digits, razão social with CNPJ only, PIX length, `NormalizedEmail`, blank name with satellites `422`)
- Storing formatted punctuation on `accountant_tax_id`
- Glossary rename of **Package destination** or **Accountant**; UI copy only
- Accountant login, outbound mail to the destination, package archive Drive writes
- `Cancelar` on edit — Unresolved 2; `GET /setup` without the Editar URL is Leitura (C3–C5)
- Settling Unresolved 1–2

## Landing

Touches `GET /setup` Contador HTML (`setup/show`, `SetupController`) and the existing `PATCH /accountant` `422` re-render (`AccountantsController`). Reuses `Organization#update_accountant`, `BrazilianTaxId.normalize` / `format`, `#76` `Pronto.` toast, and `require_coordinator_organization`. No schema change; no new named resource.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Editar unlocks via query on the existing show | Contador `Editar` is `a` with `href="/setup?edit=accountant"`. `SetupController#show` sets `@accountant_editing` when `params[:edit]` is `accountant`. `AccountantsController` `422` sets `@accountant_editing = true` so the re-render is Edicao without that query. `GET /setup` with no query is Leitura | `details/summary` like bank accounts: Unresolved 2 has no `Cancelar`, and `GET /setup` without the Editar URL must be Leitura. A new `GET /accountant/edit` route: Unresolved 1 says no new resource |

- Nothing else in this change is hard to reverse (read-only HTML, labels, `BrazilianTaxId.format` on `#tax_id`)

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
- Contador Cadastro / Leitura / Edicao is a view decision with no new model table. `Organization#update_accountant` / `accountant_shape` stay existing. Closest analogue: `spec/requests/setup_spec.rb` and `spec/requests/accountants_spec.rb` — request specs assert HTML. This repo has no view specs
- `BrazilianTaxId.format` already exists and is used by `SummarySpreadsheet`. This cut only chooses when `#tax_id` shows that string (Leitura) versus stored digits (Cadastro / Edicao). C3, C4, C7 assert the displayed value at HTTP; C6 asserts the column stays digits after those GETs
- `PATCH /accountant` 302 / 422 / auth stay existing (`accountants_spec`, `organization_spec`). C9 adds the 422-when-a-name-already-exists HTML (writable, not Leitura). Own-layer CNPJ-without-razão already lives in `organization_spec`
- System specs are not required: every named observation is HTML or status a request spec can read

Cost: request examples for C1–C10; file-read example for C11. No new model spec. Without the C9 HTML proof, a 422 after standing data could render Leitura and every other accountant example would still pass.

## Checks

Criteria 1–11 map to C1–C11. Unresolved 1–2 stay GET-of-Editar and no `Cancelar`.

### S1 - Cadastro when there is no presentation name · 4 files · 32 KB · ~8k

**C1** - Given a signed-in coordinator of the focused organization with no `accountant_presentation_name`, when `GET /setup` runs, then the status is `200`, the body includes `Cadastre o contador`, `form[action="/accountant"]` includes `Salvar contador` and inputs `#presentation_name`, `#tax_id`, `#legal_name`, `#pix_key`, and `#destination_email` none of which has `readonly`, the label for `#tax_id` is `CPF/CNPJ (preencher apenas números)`, the label for `#destination_email` is `Email para envio`, the body does not include `Id fiscal` or `Destino do pacote`, and the Contador section (from heading `Contador` through heading `Arquivo do pacote`) does not include a control whose text is `Editar`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup cadastro accountant form is writable with CPF/CNPJ labels"`

**C2** - Given that empty organization, when `PATCH /accountant` runs with `presentation_name` `Ana`, then the response is `302` to `/setup`, the name is persisted, and the following `GET /setup` has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant from cadastro persists Ana and toasts Pronto"`

### S2 - Read-only after standing data · 3 files · 25 KB · ~6k

**C3** - Given the focused organization has `accountant_presentation_name` `Ana Contábil`, `accountant_tax_id` `11222333000181`, `accountant_legal_name` `Contábil LTDA`, `accountant_pix_key` `chave-pix`, and `package_destination_email` `ana@example.com`, when `GET /setup` runs, then `form[action="/accountant"]` has those five inputs with `readonly`, `#presentation_name` value `Ana Contábil`, `#tax_id` value `11.222.333/0001-81`, `#legal_name` value `Contábil LTDA`, `#pix_key` value `chave-pix`, `#destination_email` value `ana@example.com`, the same two labels as criterion 1, no `Salvar contador` in that form, no `Cadastre o contador`, and the Contador section (from heading `Contador` through heading `Arquivo do pacote`) includes a control whose text is `Editar`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup leitura accountant fields are readonly with formatted CNPJ"`

**C4** - Given `accountant_presentation_name` `Ana` and `accountant_tax_id` `39053344705` and no razão social, when `GET /setup` runs, then `#tax_id` is `readonly` with value `390.533.447-05` and `#legal_name` is `readonly` with value `""`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup leitura formats CPF and empty razao social"`

**C5** - Given `accountant_presentation_name` `Ana` and the four optional accountant fields blank, when `GET /setup` runs, then the five inputs are `readonly`, `#tax_id` value is `""`, and `Editar` is present in that Contador section as in criterion 3.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup leitura with blank optionals still has Editar"`

**C6** - Always, `accountant_tax_id` on `Organization` stays digits-only; `GET /setup` in criteria 3–4 does not persist punctuation. `BrazilianTaxId.format` is display on the read-only `#tax_id` only.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup leitura does not persist tax id punctuation"`

### S3 - Editar, then save or 422 · 5 files · 42 KB · ~11k

**C7** - Given the organization in criterion 3, when `GET` of the Contador `Editar` control’s URL runs, then the status is `200`, `form[action="/accountant"]` includes `Salvar contador`, the five inputs have no `readonly`, `#tax_id` value is `11222333000181`, the labels match criterion 1, and the Contador section has no `Editar`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET of Contador Editar unlocks the writable accountant form"`

**C8** - Given that writable form, when `PATCH /accountant` runs with `presentation_name` `Ana Contábil`, `tax_id` `11222333000181`, `legal_name` `Contábil LTDA`, `pix_key` `chave-pix`, and `destination_email` `ana@example.com`, then the response is `302` to `/setup`, stored tax id stays `11222333000181`, and the following `GET /setup` matches the read-only observations in criterion 3 and has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant from Editar 302s to leitura and toasts Pronto"`

**C9** - Given `accountant_presentation_name` `Ana` already persisted, when `PATCH /accountant` runs with `presentation_name` `Ana` and `tax_id` `11222333000181` and blank `legal_name`, then the status is `422`, the tax id on the organization stays unchanged, `[data-notice="error"]` is `Informe a razão social`, and `form[action="/accountant"]` is the writable form in criterion 7 (no `readonly`, `Salvar contador` present).
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant 422 after standing name stays writable"`

**C10** - Given the organization in criterion 3, when `PATCH /accountant` runs with `presentation_name` `""` and the optional fields blank, then the response is `302` to `/setup`, those five standing fields are absent, and the following `GET /setup` matches criterion 1.
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant clearing the name returns cadastro"`

**C11** - `.specs/features/visual-identity/design.md` section `setup` — `GET /setup` no longer shows Contador as always `Id fiscal` / `Destino do pacote` / `[Salvar contador]`. It shows those two labels as `CPF/CNPJ (preencher apenas números)` and `Email para envio`; cadastro when there is no presentation name; read-only fields plus `Editar` when that name exists; formatted CPF/CNPJ on read. `Arquivo do pacote` stays the always-writable URL form (`Salvar arquivo`) — #81.
Proof: `bin/rspec spec/docs/setup_accountant_read_after_save_spec.rb -e "visual-identity setup Contador is cadastro or leitura"`

## Screens (ui)

Design opened: `.specs/features/visual-identity/design.md` (file in the repo). Until C11 lands, Contador copy and the Cadastro / Leitura / Edicao arrangement values are the task transcription; two-column form from 768px, `Arquivo do pacote` `Salvar arquivo`, SEFAZ, banks (`details` `Editar`), and extras come from the opened `setup` section.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `setup` Contador, cadastro | `Cadastre o contador`; labels `CPF/CNPJ (preencher apenas números)` and `Email para envio`; five inputs without `readonly`; `Salvar contador`; no `Id fiscal`; no `Destino do pacote`; no `Editar` in the Contador section C1 | h2 `Contador` then `form[action="/accountant"]` (`md:grid-cols-2`) then h2 `Arquivo do pacote`; submit lives in that form C1, C11 | spacing, colour, type weight |
| `setup` Contador, leitura | five `readonly` inputs; formatted CNPJ or CPF on `#tax_id`; `Editar`; no `Salvar contador`; no `Cadastre o contador` C3–C5 | same two-column form; `Editar` is in the Contador section (not bank-account `details`) C3, C5, C11 | spacing, colour, type weight |
| `setup` Contador, edicao | `Salvar contador`; five inputs without `readonly`; `#tax_id` digits; same two labels; no `Editar` in the Contador section C7, C9 | GET of the Contador `Editar` URL (or `422` re-render) is still `GET /setup` HTML, not a new resource C7, C9 | spacing, colour, type weight |
| `setup` Arquivo do pacote | `Salvar arquivo`; URL field stays writable C11 | always-writable URL form after Contador; this cut does not add archive `Editar` / `Confirmar` C11 | spacing, colour, type weight |

## Swept

- validation: existing `Organization#update_accountant` / `accountant_shape`; C6 — display format is not a new stored shape; C9 — CNPJ without razão social still `422`
- failure modes: C9 — `422` re-renders the writable accountant form, not Leitura
- idempotency and retry: C8 — a second identical `PATCH` still `302` and Leitura; C3 — a second `GET /setup` stays Leitura
- authorization: existing — `require_coordinator_organization` on `SetupController` and `AccountantsController`; this cut does not add a named resource
- concurrency and ordering: n/a — two overlapping `PATCH /accountant` leave the last write; no new unique index or ordering
- data lifecycle: C3, C5 — organizations that already have a presentation name render Leitura on first `GET /setup` after this ships; no backfill; clearing the name (C10) returns Cadastro
- external-dependency failure: n/a — accountant save does not call Drive, SMTP, or SEFAZ
- state transitions: C1, C2, C7, C8, C9, C10
- observability: n/a — the source names no log, metric, or trace; the person sees the form and the existing toast

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| Contador form modes (3) | Cadastro C1 · Leitura C3 · Edicao C7 | - |
| standing-data Leitura samples (3) | full CNPJ row C3 · CPF without razão C4 · name only C5 | - |
| `#tax_id` display (4) | formatted CNPJ C3 · formatted CPF C4 · blank `""` C5 · digits on Edicao C7 | - |
| `PATCH /accountant` outcomes this cut observes (4) | cadastro persist `302` C2 · edit persist `302` C8 · CNPJ without razão `422` C9 · clear name `302` C10 | existing satellite-without-name / invalid tax / CPF-with-razão / invalid email stay in `accountants_spec` |
| tax id storage after GET (2) | CNPJ digits C6 · CPF digits C6 | - |
| designed screens this cut binds (1) | `setup` C1, C3–C5, C7, C11 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `month`, `documents` — out of scope |
| `setup` Contador visual (3 properties × 3 modes) | — | spacing, colour, type weight on cadastro, leitura, and edicao |

- Claims naming a status code, route or response shape: C1, C2, C7, C8, C9, C10 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~8k + S2 ~6k + S3 ~11k = ~25k token floor. The three slices share `setup/show.html.erb` and `setup_spec.rb`; unique files sit under ~40k bytes plus the opened design (~20 KB). All three stay under 150k and share the Contador form. No split. One batch.

Batch closed. Checks C1–C11 on this branch. No mid-build clarification. Abandoned: `readonly: false` on tag helpers (HTML treats the attribute as on); omitted unless Leitura.
