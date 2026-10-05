# Setup accountant read-after-save Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 37fe43bdbf7b3e2fc2526faed7af79d74c419339..7ed6dfc31bf52ab41d06aee15908feed6413030a
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Opened #80 via `gh issue view 80` (`gutors/ai-accounting-assistant`). Opened `.specs/features/visual-identity/design.md` as a file; screen `setup` at `### setup — GET /setup` (ASCII plus bullets). `.tasks/setup-accountant-read-after-save.md` is criteria source, not a second checklist. No `.specs/features/setup-accountant-read-after-save/checks.md`.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| https://github.com/gutors/ai-accounting-assistant/issues/80 | yes - `gh issue view 80` | none — `CPF/CNPJ (preencher apenas números)` / `Email para envio`; after standing data: read-only + `Editar`; formatted CPF/CNPJ on read; empty stays cadastro; toast on save; archive is #81 | C2’s following `GET /setup` asserts only `Pronto.`; leitura HTML after a first save is C3/C5 as a given GET, not chained on that PATCH |
| `.specs/features/visual-identity/design.md` screen `setup` | yes - file in the repo | none — cadastro field line + `[Salvar contador]`; leitura five fields read-only, formatted CPF/CNPJ, `[Editar]`; `GET /setup?edit=accountant` writable; archive `URL da pasta do Drive` `[Salvar arquivo]` | SEFAZ, bank `details` `Editar`, extras — out of scope (#82–#84). Two-column from 768px, `Nome de apresentação` / `Razão social` / `PIX`, and field order are pre-existing Contador chrome (unchanged `md:grid-cols-2`); Screens table names `md:grid-cols-2` under C1/C11 but neither proof asserts the class. Spacing, colour, type weight enumerated unproven |
| `.tasks/setup-accountant-read-after-save.md` | yes - criteria 1–11 | none — C1–C11 match; Unresolved 1–2 stay GET-of-Editar and no `Cancelar` | Unresolved 1–2 left open |

Screens (ui) vs design: one bound screen (`setup`) for this cut’s Contador modes. Distinguishing arrangement vs always-writable Contador — cadastro `Salvar contador` and writable inputs (C1); leitura `readonly` + Contador-section `Editar` and no submit (C3–C5); edição still `GET /setup` HTML with digits on `#tax_id` (C7, C9); archive stays the URL form (C11 on the design file). Visual unproven is enumerated (spacing, colour, type weight on cadastro / leitura / edição), not a blanket fidelity clause.

## Checks

Proofs run at `7ed6dfc` in one `bin/rspec` invocation over three spec files with eleven `-e` names. A single `|` string matched **0 examples with exit 0**; re-run with one `-e` per name. **11 examples, 0 failures**. JSON: `/tmp/setup-accountant-c1-c11.json`. Each named example exists under `spec/` (`rg`) and appears as `passed`. Spec files are in `37fe43b..HEAD`.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | `GET /setup` 200; `Cadastre o contador`; writable `#presentation_name` `#tax_id` `#legal_name` `#pix_key` `#destination_email`; labels `CPF/CNPJ (preencher apenas números)` and `Email para envio`; no `Id fiscal` / `Destino do pacote`; no Contador `Editar` | ran, passed | `spec/requests/setup_spec.rb:65` `have_http_status(:ok)` · `:66` `expect_accountant_cadastro` → `spec/support/page_helpers.rb:68` include `Cadastre o contador` · `:70` submit `Salvar contador` · `:71-75` five ids present, `readonly` `nil` · `:63-64` those two labels · `:77-78` not `Id fiscal` / `Destino do pacote` · `:79` edit control `nil` | PASS |
| C2 | `PATCH /accountant` `presentation_name` `Ana` → 302 `/setup`, name persisted, following GET `[data-toast-kind=success]` `Pronto.` | ran, passed | `spec/requests/accountants_spec.rb:10-12` `:found` · `redirect_to("/setup")` · `accountant_presentation_name` `eq("Ana")` · `:15-16` `data-toast-kind` `eq("success")` · text include `Pronto.` | PASS |
| C3 | Standing CNPJ row: five `readonly` values including `#tax_id` `11.222.333/0001-81`; same labels; no `Salvar contador` / `Cadastre o contador`; Contador `Editar` | ran, passed | `spec/requests/setup_spec.rb:76` `:ok` · `:77` `expect_accountant_leitura_cnpj_row` → `page_helpers.rb:84-88` those five values · `:89-91` `readonly` `eq("readonly")` · `:92` labels · `:93-95` submit nil, no `Cadastre o contador`, edit text `Editar` | PASS |
| C4 | Name + CPF `39053344705`: `#tax_id` `readonly` `390.533.447-05`; `#legal_name` `readonly` `""` | ran, passed | `spec/requests/setup_spec.rb:89-92` `readonly` `eq("readonly")` · `value` `eq("390.533.447-05")` · legal `readonly` · `value` `eq("")` | PASS |
| C5 | Name only: five `readonly`; `#tax_id` `""`; Contador `Editar` | ran, passed | `spec/requests/setup_spec.rb:103-107` each id `readonly` `eq("readonly")` · `#tax_id` `eq("")` · edit text `eq("Editar")` | PASS |
| C6 | `accountant_tax_id` stays digits after C3/C4 GETs | ran, passed | `spec/requests/setup_spec.rb:116` `eq("11222333000181")` · `:120` `eq("39053344705")` | PASS |
| C7 | GET of Contador `Editar` URL: 200; `Salvar contador`; five not `readonly`; `#tax_id` `11222333000181`; C1 labels; no Contador `Editar` | ran, passed | `spec/requests/setup_spec.rb:133` `:ok` · `:135` submit `Salvar contador` · `:136-138` `readonly` `nil` · `:139` `eq("11222333000181")` · `:140` `expect_accountant_labels` · `:141` edit `nil`. Href string `/setup?edit=accountant` is followed, not `eq`’d | PASS |
| C8 | Same PATCH as standing row → 302 `/setup`, stored tax `11222333000181`, GET matches C3 + toast `Pronto.` | ran, passed | `spec/requests/accountants_spec.rb:32-34` `:found` · `redirect_to("/setup")` · `eq("11222333000181")` · `:37` `expect_accountant_leitura_cnpj_row` · `:38-39` success toast include `Pronto.` | PASS |
| C9 | Standing name + CNPJ without razão: 422, tax unchanged, `[data-notice=error]` `Informe a razão social`, writable form | ran, passed | `spec/requests/accountants_spec.rb:50-56` `:unprocessable_content` · tax `eq(tax_id_before)` (same example) · `error_notice_text` `eq("Informe a razão social")` · submit `Salvar contador` · `readonly` `nil` | PASS |
| C10 | PATCH empty name → 302 `/setup`, five fields absent, GET matches C1 | ran, passed | `spec/requests/accountants_spec.rb:67-74` `:found` · `redirect_to("/setup")` · five columns `be_nil` · `:77` `expect_accountant_cadastro` | PASS |
| C11 | Design `setup` drops always `Id fiscal` / `Destino do pacote` / always `[Salvar contador]`; new labels; cadastro vs leitura+`Editar`; archive `Salvar arquivo` #81 | ran, passed | `spec/docs/setup_accountant_read_after_save_spec.rb:8-19` not `Id fiscal` / `Destino do pacote` · include `CPF/CNPJ (preencher apenas números)` · `Email para envio` · `cadastro` · `presentation name` · `Editar` · `read-only` · `Salvar arquivo` · `#81` · `Arquivo do pacote`. Does not `include("formatted")` | PASS |

## Coverage (recomputed)

Members taken from the checklist sets and the design `setup` Contador/archive ASCII; proofs from the table above.

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| Contador form modes (3) | Cadastro C1 · Leitura C3 · Edicao C7 | - |
| standing-data Leitura samples (3) | full CNPJ row C3 · CPF without razão C4 · name only C5 | - |
| `#tax_id` display (4) | formatted CNPJ C3 · formatted CPF C4 · blank `""` C5 · digits on Edicao C7 | - |
| `PATCH /accountant` outcomes this cut observes (4) | cadastro persist `302` C2 · edit persist `302` C8 · CNPJ without razão `422` C9 · clear name `302` C10 | existing satellite-without-name / invalid tax / CPF-with-razão / invalid email remain in `accountants_spec` (out of this cut) |
| tax id storage after GET (2) | CNPJ digits C6 · CPF digits C6 | - |
| designed screens this cut binds (1) | `setup` C1, C3–C5, C7, C11 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `month`, `documents` |
| `setup` Contador visual (3 × 3 modes) | — | spacing, colour, type weight |

Landing `params[:edit] == "accountant"` and 422 `@accountant_editing = true` are exercised by C7 and C9 (writable HTML), not named as extra set members in the artifact.

Swept **existing**: `Organization#update_accountant` / `accountant_shape` (`app/models/organization.rb:120-128`, `:254`); `require_coordinator_organization` on `SetupController` and `AccountantsController`; unauthenticated `GET /setup` already in `setup_spec.rb:6`. Swept **idempotency** cites a second identical `PATCH` as C8 — C8 runs one PATCH; not a missing check, the sweep overclaims.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | Contador Cadastro/Leitura/Edicao in `setup/show` + `SetupController#show` / `AccountantsController#update` | own layer **and** request spec; one case per mode | yes — repo has no view specs; request specs assert the HTML for each mode (C1, C3, C7) and HTTP 200/302/422 (C1, C2, C7–C10). Artifact priced that |
| Decides, not reached across a boundary | none new (`update_accountant` / `BrazilianTaxId` stay existing) | own layer | n/a this cut |
| Entry point that decides nothing | none added | request spec | n/a |
| Instrumentation / pass-through | `#76` toast helper, `readonly_if` consumed by the form | consumer | yes — C2/C8 toast; C3–C5 `readonly` |

## Faults injected

Scratch worktree at `7ed6dfc`; real tree porcelain unchanged (`?? GLOSSARY.md`). Cap five; five distinct proofs failed.

| Mutation | Location | Killed |
|---|---|---|
| tax_id label `CPF/CNPJ (preencher apenas números)` → `Id fiscal` | `app/views/setup/show.html.erb` | yes — C1 (`page_helpers.rb:63`) |
| `readonly_if` always `{}` | `app/helpers/application_helper.rb` | yes — C3 (`readonly` expected) |
| `@accountant_editing = false` always | `app/controllers/setup_controller.rb` | yes — C7 (no `Salvar contador`) |
| omit `@accountant_editing = true` on 422 | `app/controllers/accountants_controller.rb` | yes — C9 (no `Salvar contador`) |
| `redirect_success("/setup")` → `redirect_to("/setup")` | `app/controllers/accountants_controller.rb` | yes — C2 (toast node nil) |

## Gate

`bin/rspec spec/requests/setup_spec.rb spec/requests/accountants_spec.rb spec/docs/setup_accountant_read_after_save_spec.rb` with the eleven checklist `-e` names — 11 passed, 0 failed (at `7ed6dfc`).
