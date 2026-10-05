# Setup: Certificado Digital A1

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/setup-a1-certificate.md` marks screen `setup` binding through `.specs/features/visual-identity/design.md` (criterion 9).

Sources:

- `.tasks/setup-a1-certificate.md` - criteria 1–9, the state diagram, the sweep, zero doors, Unresolved 1 open (empty line is the criterion-1 sentence). Nothing under Unresolved is settled while building
- https://github.com/gutors/ai-accounting-assistant/issues/82 - **binding for this slice**: heading `Certificado Digital A1 - Para consulta na SEFAZ`; Arquivo and Senha hidden until `Instalar certificado` (same control on reinstall); empty line instead of the titular block; `Remover` stays when a certificate exists; 422 keeps the install form open; keep `input type=file` on 422; file/passphrase restore is another child
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent: one tlc-plan slice; #82 is this certificate chrome; #85 is keep-form-on-422; profile `ui`
- https://github.com/gutors/ai-accounting-assistant/issues/85 - out: restore file/passphrase; do not echo A1 passphrase; do not stash a failed `.pfx`
- https://github.com/gutors/ai-accounting-assistant/issues/76 - success `Pronto.`; certificate `:base` 422 still has error toast
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screen `setup`. Opened as a file in the repo. Section `setup` today still draws heading `Certificado SEFAZ` and always-visible Arquivo / Senha. C9 amends that section. Empty line, fold, and 422 `open` values are the task transcription
- `app/views/setup/show.html.erb` - today’s always-visible Arquivo / Senha / `Instalar certificado` under `Certificado SEFAZ` / `Nenhum certificado`
- Open default in Unresolved 1 - empty line `Não há certificado A1 instalado. Use Instalar certificado.`

## Out of scope

- Restoring the chosen `.pfx` or typed passphrase on `422` — #85 (`input type=file` stays empty; passphrase is not echoed)
- Turbo Stream / morph that updates only the notice — #85
- Changing `Organization#install_sefaz_certificate` acceptance, wrap-key `422` copy, replace, size limit, or `GET /sefaz_certificate` `404` — existing `#38`
- Submitter seeing the certificate; unauthenticated install — existing `require_coordinator_organization`
- Contador read-after-save, arquivo Editar → Confirmar, contas bancárias, tipos extras — #80, #81, #83, #84
- `Cancelar` on the install fold — closed `<details>` on the next `GET /setup` (C1–C4, C8)
- Glossary rename of **SEFAZ certificate**; UI heading only
- Changing Turbo confirm `Remover o certificado SEFAZ?`
- Settling Unresolved 1

## Landing

Touches `GET /setup` certificate HTML (`setup/show`) and the existing `POST`/`DELETE /sefaz_certificate` re-render (`SefazCertificatesController`). Reuses `Organization#install_sefaz_certificate` / `#remove_sefaz_certificate`, `#76` `Pronto.` toast, `require_coordinator_organization`, and the existing setup/ledger `<details>` fold. No schema change; no new named resource.

None — `POST`/`DELETE /sefaz_certificate` and the one-slot A1 already exist. Folding Arquivo/Senha into `<details>` with summary `Instalar certificado` copies the existing setup/ledger fold. `422` sets `open` on that same element via the existing `@certificate_error` (already assigned on failed install). Stimulus hide, or a query like Contador `?edit=accountant`, is not required.

- Nothing else in this change is hard to reverse (heading, empty line, `<details open>` on 422)

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
- Certificate Absent / Valid / Expired install rules stay on `Organization` (existing `#38`). This cut is view chrome: heading, empty line, listed block vs fold, `details` `open` on 422. Closest analogue: `spec/requests/setup_spec.rb` Contador Cadastro / Leitura — request specs assert HTML. This repo has no view specs
- `SefazCertificatesController#create` already chooses `302` vs `422` from `install_sefaz_certificate`. The new branch is only whether the re-rendered `<details>` has `open`. That is asserted at HTTP (C6, C7). Own-layer refuse copy stays in `organization_spec`
- System specs are not required: every named observation is HTML or status a request spec can read

Cost: request examples for C1–C8; file-read example for C9. No new model spec. Without the C6/C7 `open` proofs, a 422 could re-render a collapsed fold and every listed/empty GET example would still pass.

## Checks

Criteria 1–9 map to C1–C9. Unresolved 1 stays the empty-line sentence in C1.

### S1 - Heading and empty slot · 3 files · 31 KB · ~8k

**C1** - Given a signed-in coordinator of the focused organization with no SEFAZ certificate, when `GET /setup` runs, then the status is `200`, the body includes the heading `Certificado Digital A1 - Para consulta na SEFAZ` and the text `Não há certificado A1 instalado. Use Instalar certificado.`, and it does not include `Certificado SEFAZ`, `Nenhum certificado`, a formatted titular CNPJ, `Válido até`, `Expirado em`, or `Remover o certificado SEFAZ?`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with no SEFAZ certificate includes A1 heading and empty line"`

**C2** - When `GET /setup` runs as in criterion 1, then `input#certificate` and `input#passphrase` are descendants of a `<details>` that does not have the `open` attribute, whose `<summary>` text is `Instalar certificado`, and `form[action="/sefaz_certificate"]` includes submit `Instalar certificado`. `#certificate` is `input type=file`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with no SEFAZ certificate keeps Arquivo and Senha in closed Instalar certificado details"`

### S2 - Listed slot, Remover, same disclosure · 4 files · 41 KB · ~10k

**C3** - Given that organization has titular CNPJ `11222333000181` and `sefaz_not_after` `2027-09-18`, when `GET /setup` runs, then the status is `200`, the body includes `11.222.333/0001-81`, `Válido até 18/09/2027`, and `Remover` with Turbo confirm `Remover o certificado SEFAZ?`, and it does not include `Não há certificado A1 instalado. Use Instalar certificado.` The Arquivo and Senha controls match criterion 2 (same closed `<details>`, same summary, same submit). `Remover` is not a descendant of that `<details>`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with listed A1 shows titular validity Remover outside closed install details"`

**C4** - Given installed `sefaz_not_after` `2026-05-11`, while today is `2026-05-12`, when `GET /setup` runs, then the body includes `Expirado em 11/05/2026` and `Remover`, does not include `Válido até`, and the Arquivo/Senha `<details>` still does not have `open`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with expired certificate includes Expirado em 11/05/2026"`

**C5** - When `DELETE /sefaz_certificate` runs after the organization in criterion 3, then the response is `302` to `/setup`, the slot is empty, and the following `GET /setup` matches criteria 1–2 and has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "DELETE /sefaz_certificate clears the slot and redirects"`

### S3 - 422 keeps the install form open · 3 files · 21 KB · ~5k

**C6** - Given no certificate, when `POST /sefaz_certificate` runs with a valid `.pfx` and passphrase `errada`, then no certificate is persisted, the status is `422`, `[data-notice="error"]` is `Não foi possível abrir o certificado com essa senha`, the empty line from criterion 1 is present, the Arquivo/Senha `<details>` has the `open` attribute, `#certificate` is `input type=file`, `#passphrase` value is `""`, and the body does not include `errada`.
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST pfx with passphrase errada returns 422 with install details open"`

**C7** - Given the organization in criterion 3, when `POST /sefaz_certificate` runs with an e-CPF A1, then the stored titular stays `11222333000181`, the status is `422`, `[data-notice="error"]` is `O certificado deve ser e-CNPJ A1 vigente`, the page still includes `11.222.333/0001-81` and `Remover`, and the Arquivo/Senha `<details>` has the `open` attribute.
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST e-CPF against listed A1 returns 422 with install details open"`

**C8** - When `POST /sefaz_certificate` persists the A1 in criterion 3, then the response is `302` to `/setup`, and the following `GET /setup` matches criterion 3 (details not `open`) and has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST /sefaz_certificate persists pfx and redirects"`

### S4 - Binding setup wireframe · 2 files · 22 KB · ~5k

**C9** - `.specs/features/visual-identity/design.md` section `setup` — the certificate block is no longer heading `Certificado SEFAZ` with always-visible Arquivo / Senha. It is heading `Certificado Digital A1 - Para consulta na SEFAZ`; empty line as in criterion 1; when a certificate exists, titular / validity / `Remover` (quiet, margem) stay outside the fold; Arquivo / Senha sit in `<details>` whose `<summary>` is `Instalar certificado`.
Proof: `bin/rspec spec/docs/setup_a1_certificate_spec.rb -e "visual-identity setup certificate is A1 heading and folded install"`

## Screens (ui)

Design opened: `.specs/features/visual-identity/design.md` (file in the repo). Until C9 lands, certificate heading, empty line, fold, and 422 `open` values are the task transcription; two-column form from 768px, Contador, `Arquivo do pacote`, banks (`details` `Editar`), and extras come from the opened `setup` section.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `setup` certificate, absent | heading `Certificado Digital A1 - Para consulta na SEFAZ`; empty line `Não há certificado A1 instalado. Use Instalar certificado.`; no `Certificado SEFAZ`; no `Nenhum certificado`; no titular; no `Válido até`; no `Expirado em`; no `Remover o certificado SEFAZ?`; summary `Instalar certificado`; submit `Instalar certificado`; `#certificate` `type=file` C1, C2 | Arquivo and Senha inside a `<details>` that does not have `open`; that form is after the empty line; no `Remover` C1, C2 | spacing, colour, type weight |
| `setup` certificate, listed | formatted titular `11.222.333/0001-81`; `Válido até 18/09/2027`; `Remover`; Turbo confirm `Remover o certificado SEFAZ?`; no empty line C3 | titular then validity then `Remover` outside the fold; same closed Arquivo/Senha `<details>` as absent C3 | spacing, colour, type weight |
| `setup` certificate, expired | `Expirado em 11/05/2026`; `Remover`; no `Válido até` C4 | Arquivo/Senha `<details>` still not `open` C4 | spacing, colour, type weight |
| `setup` certificate, 422 | empty: error notice + empty line C6; listed: error notice + titular + `Remover` C7; `#certificate` still `type=file`; `#passphrase` `""`; no `errada` C6 | Arquivo/Senha `<details>` has `open` C6, C7 | spacing, colour, type weight |
| `setup` certificate, after 302 | empty collapsed + `Pronto.` C5; listed collapsed + `Pronto.` C8 | details not `open` after success GET C5, C8 | spacing, colour, type weight |

## Swept

- validation: existing `Organization#install_sefaz_certificate`; C6, C7 reuse wrong passphrase and e-CPF `422` copy; this cut does not add a rule
- failure modes: C6, C7 — `422` re-renders setup with the Arquivo/Senha `<details>` `open`; file input stays `type=file` with no server-filled value
- idempotency and retry: C2, C3 — a second `GET /setup` stays collapsed; C8 — a successful POST still `302` and collapsed
- authorization: existing — `SefazCertificatesController` `require_coordinator_organization`; this cut does not add a route
- concurrency and ordering: n/a — two overlapping POSTs still leave one slot (#38 criterion 19); opening `<details>` is not a write
- data lifecycle: C3, C5 — organizations that already have a titular render the listed block on next `GET /setup`; no backfill; DELETE returns the empty line
- external-dependency failure: n/a — this cut does not call SEFAZ; wrap-key `422` copy is unchanged
- state transitions: C1, C2, C5, C6, C7, C8
- observability: n/a — the source names no log, metric, or trace; `filter_parameters` already covers passphrase; the person sees the fold and the existing toast

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| certificate slot display (3) | absent C1 · valid listed C3 · expired C4 | - |
| Arquivo/Senha fold (5) | GET absent closed C2 · GET listed closed C3 · GET expired closed C4 · POST 422 empty open C6 · POST 422 listed open C7 | - |
| POST /sefaz_certificate outcomes this cut observes (3) | wrong passphrase `422` C6 · e-CPF on listed `422` C7 · valid persist `302` C8 | existing p12 / txt / oversized / wrap-key / replace / closed-month stay in `sefaz_certificates_spec` |
| DELETE then GET (1) | empty collapsed + `Pronto.` C5 | - |
| designed screens this cut binds (1) | `setup` C1–C9 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `month`, `documents` — out of scope |
| `setup` certificate visual (3 properties × 5 states) | — | spacing, colour, type weight on absent, listed, expired, 422, and after 302 |

- Claims naming a status code, route or response shape: C1, C3, C5, C6, C7, C8 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~8k + S2 ~10k + S3 ~5k + S4 ~5k = ~28k token floor. All four slices share `setup/show.html.erb`; unique bytes sit under ~64k plus the opened design (~20 KB). All four stay under 150k and share the certificate section. No split. One batch.

Batch closed. Checks C1–C9 on this branch. No mid-build clarification. Abandoned: locating `form[action="/sefaz_certificate"]` with `at_css` on the section (the Remover `button_to` is the first match); the install form is the one inside the `<details>`.
