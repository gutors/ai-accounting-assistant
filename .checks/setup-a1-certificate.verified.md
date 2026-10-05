# Setup A1 certificate Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: d161878..HEAD (`fbf697f`)
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Opened as files in the repo except #82, which was opened with `gh issue view 82` (WebFetch from this agent was blocked).

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.tasks/setup-a1-certificate.md` | yes - repo file | none vs C1–C9 (Unresolved 1 stays the C1 empty-line sentence) | — |
| https://github.com/gutors/ai-accounting-assistant/issues/82 | yes - `gh issue view 82` | none: heading `Certificado Digital A1 - Para consulta na SEFAZ`; Arquivo/Senha hidden until `Instalar certificado` (same control on reinstall); empty line instead of titular; `Remover` when a certificate exists; 422 keeps install form open; keep `input type=file` on 422; file/passphrase restore is another child | — |
| `.specs/features/visual-identity/design.md` section `setup` | yes - repo file | none: heading, empty line, listed titular/validity/`Remover` (quiet, margem) outside the fold, Arquivo/Senha in `<details>` whose `<summary>` is `Instalar certificado`, 422 sets `open` | Contador, Arquivo do pacote, contas bancárias, tipos extras — other issues (#80–#81, #83–#84); spacing, colour, type weight (enumerated) |

Screens table vs design (selector-reachable), certificate block only: absent, listed, expired, 422, and after-302 each have a check. Visual unproven is enumerated (spacing, colour, type weight) per state — not a blanket fidelity waiver. `quiet, margem` on `Remover` is colour/type, named unproven.

Arrangement: Arquivo and Senha inside a closed `<details>` (C2, C3, C4); `Remover` not a descendant of that fold (C3); `open` on 422 (C6, C7); collapsed after success GET (C5, C8). Sibling order of empty line vs fold is not a separate CSS/XPath order assertion; presence plus containment is what C1–C4 name.

## Checks

Proofs run at `fbf697f` in one `bin/rspec` invocation (nine `-e` substring filters). **9 examples, 0 failures**. JSON list in `/tmp/setup-a1-verify.json`. Each named example exists under `spec/` (rg) and appears as `passed` in that run. Spec files and helpers are in `d161878..HEAD`.

Expected literals for C1–C3 live in `spec/support/page_helpers.rb` (called from the named examples). Cited below as the settling expects.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | GET `/setup` empty slot: `200`, A1 heading, empty line, no old heading/empty/titular/validity/confirm | `setup_spec.rb` `-e "GET /setup with no SEFAZ certificate includes A1 heading and empty line"` passed | `spec/requests/setup_spec.rb:45` `:ok`; `spec/support/page_helpers.rb:119–126` include heading + empty line; not `Certificado SEFAZ`, `Nenhum certificado`, `Válido até`, `Expirado em`, `Remover o certificado SEFAZ?`, formatted CNPJ regex | PASS |
| C2 | `#certificate` and `#passphrase` in closed `<details>` summary `Instalar certificado`; submit; `type=file` | `-e "GET /setup with no SEFAZ certificate keeps Arquivo and Senha in closed Instalar certificado details"` passed | `page_helpers.rb:132` `has_attribute?("open")` `eq(false)`; `:133` summary `Instalar certificado`; `:134–135` both inputs; `:137` submit `Instalar certificado`; `:138` `#certificate` `type` `file` | PASS |
| C3 | listed `11.222.333/0001-81`, `Válido até 18/09/2027`, `Remover` + Turbo confirm, no empty line, same closed fold, `Remover` outside details | `-e "GET /setup with listed A1 shows titular validity Remover outside closed install details"` passed | `setup_spec.rb:283` `:ok`; `page_helpers.rb:142–148` titular, validity, remover, `data-turbo-confirm="Remover o certificado SEFAZ?"`, not empty line, fold `open: false`, remover ancestors exclude install details | PASS |
| C4 | expired `Expirado em 11/05/2026`, `Remover`, no `Válido até`, details not `open` | `-e "GET /setup with expired certificate includes Expirado em 11/05/2026"` passed | `setup_spec.rb:316–319` include `Expirado em 11/05/2026` and `Remover`; not `Válido até`; fold `open: false` | PASS |
| C5 | DELETE `302` `/setup`, slot empty, GET matches C1–C2, toast `Pronto.` | `-e "DELETE /sefaz_certificate clears the slot and redirects"` passed | `sefaz_certificates_spec.rb:224–225` `:found` redirect `/setup`; `:226` titular nil; `:228–231` absent copy, fold closed, toast success `Pronto.` | PASS |
| C6 | POST passphrase `errada`: no persist, `422`, error notice, empty line, details `open`, file input, passphrase `""`, no `errada` | `-e "POST pfx with passphrase errada returns 422 with install details open"` passed | `sefaz_certificates_spec.rb:73–80` titular nil; `:unprocessable_content`; notice `Não foi possível abrir o certificado com essa senha`; empty line; fold `open: true`; `#certificate` `file`; `#passphrase` value `""`; not `errada` | PASS |
| C7 | POST e-CPF on listed: titular stays, `422`, e-CNPJ notice, listed row + `Remover`, details `open` | `-e "POST e-CPF against listed A1 returns 422 with install details open"` passed | `sefaz_certificates_spec.rb:95–100` titular `11222333000181`; `:unprocessable_content`; notice `O certificado deve ser e-CNPJ A1 vigente`; `11.222.333/0001-81`; remover present; fold `open: true` | PASS |
| C8 | POST persist: `302` `/setup`, GET matches C3 (details not `open`), toast `Pronto.` | `-e "POST /sefaz_certificate persists pfx and redirects"` passed | `sefaz_certificates_spec.rb:20–21` `:found` redirect `/setup`; `:23–24` titular + `2027-09-18`; `:27` listed helper (includes fold closed); `:29–30` success `Pronto.` | PASS |
| C9 | design.md `setup` certificate is A1 heading and folded install | `-e "visual-identity setup certificate is A1 heading and folded install"` passed | `spec/docs/setup_a1_certificate_spec.rb:8–19` section excludes `Certificado SEFAZ` / `Nenhum certificado`; includes A1 heading, empty line, `details`, `Instalar certificado`, `Remover`, `quiet, margem`, titular, `Válido até`, `Expirado em`, `<summary>` | PASS |

## Coverage (recomputed)

Members taken from the task criteria / issue #82 / design `setup` certificate block, not from the author’s table as authority.

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| certificate slot display (3) | absent C1 · valid listed C3 · expired C4 | — |
| Arquivo/Senha fold (5) | GET absent closed C2 · GET listed closed C3 · GET expired closed C4 · POST 422 empty open C6 · POST 422 listed open C7 | GET after 302 closed is C5/C8 (same `open` attribute) |
| POST `/sefaz_certificate` outcomes this cut observes (3) | wrong passphrase `422` C6 · e-CPF on listed `422` C7 · valid persist `302` C8 | p12 / txt / oversized / wrap-key / replace / closed-month stay on existing `sefaz_certificates_spec` examples |
| DELETE then GET (1) | empty collapsed + `Pronto.` C5 | — |
| designed screens this cut binds (1) | `setup` C1–C9 | — |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `month`, `documents` — out of scope |
| `setup` certificate visual (3 properties × 5 states) | — | spacing, colour, type weight on absent, listed, expired, 422, and after 302 |

Status/route claims C1, C3, C5, C6, C7, C8 assert at the request boundary. No extra enumeration in Landing without a proof.

## Test policy rows

Follows `.cursor/rules/rails.mdc` (decision at own layer, one case per member; HTTP also a request spec). No view specs in this repo.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `Organization#install_sefaz_certificate` (unchanged); `SefazCertificatesController#create` `302` vs `422` | HTTP C6–C8; own-layer refuse copy stays on existing `organization_spec` | yes — this cut does not add install members |
| Decides, not reached across a boundary | none new | — | n/a |
| Entry point that decides nothing | `SetupController#show` HTML chrome | request C1–C4 | yes |
| Instrumentation / pass-through | `setup/show.html.erb` `details` `open` iff `@certificate_error` | covered by C2–C8 HTTP | yes — view forwards the error flag; C6/C7 vs closed GET examples |

## Swept existing

- `SefazCertificatesController` `before_action :require_coordinator_organization, except: :show` — present (`sefaz_certificates_controller.rb:3`)
- `Organization#install_sefaz_certificate` — present (`organization.rb:141`)
- `filter_parameters` includes `:passphrase` — present (`config/initializers/filter_parameter_logging.rb:7`)
- n/a and out-of-scope sweep rows: nothing in code for them to be wrong about

## Faults injected

Scratch worktree `/tmp/setup-a1-verify-scratch` from `HEAD`; discarded. Real-tree porcelain before and after: `?? GLOSSARY.md` only.

| Mutation | Location | Killed |
|---|---|---|
| heading `Certificado Digital A1 - Para consulta na SEFAZ` → `Certificado SEFAZ` | `app/views/setup/show.html.erb` h2 | yes — C1 |
| `<details>` never gets `open` | same, details tag | yes — C6 |
| `Remover` moved inside the install `<details>` | same | yes — C3 |
| expired branch `<% if false %>` (always `Válido até`) | same | yes — C4 |
| design heading first occurrence → `Certificado SEFAZ` | `.specs/features/visual-identity/design.md` | yes — C9 |

Cap five. Closed-fold GET (C2), DELETE (C5), listed 422 (C7), and persist (C8) share the `open` / listed-or-absent helpers already forced to fail above; not re-run.

## Gate

`bin/rspec` (nine named `-e` proofs) — 9 passed, 0 failed
