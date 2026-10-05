# Setup package archive storage Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 22d70867dada93796ea4758a959e8d0adee5b281..64a4f11436f6215b7b0ba312371c2a043d522d5e
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

Checklist `.checks/setup-package-archive-storage.md` (no `.specs/features/setup-package-archive-storage/checks.md`). Real-tree porcelain after proofs and after discarding the scratch worktree: `?? .checks/setup-package-archive-storage.verified.md` (same as baseline).

Proofs re-run in full at `64a4f11`. Sections mark `verified at 64a4f11` or `carried from 6b1363e`. Round 1 FAIL gaps (h2 order, `md:grid-cols-2`, Swept second PATCH) re-judged against the fix diff `6b1363e..64a4f11` (tests only; no product ERB/controller change).

## Binding sources

Interface unchanged this round — comparison **carried from 6b1363e**. Uncovered arrangement from round 1 re-judged at `64a4f11`.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| https://github.com/gutors/ai-accounting-assistant/issues/81 | yes - `gh issue view 81` | none vs C1–C8, C13 archive copy (Contador chrome is the task / user-delegated expansion) | issue does not draw arrangement; Contador is out of #81 — **carried from 6b1363e** |
| `.specs/features/visual-identity/design.md` section `setup` | yes - `### \`setup\` — \`GET /setup\`` | none vs C1–C13 copy | none for selector-reachable arrangement this cut binds: live h2 order Contador → Armazenamento do pacote mensal → Certificado SEFAZ asserted in C1; accountant `md:grid-cols-2` asserted in C9 leitura, cadastro helper, C12 form — **verified at 64a4f11** (was uncovered in round 1) |
| `.tasks/setup-package-archive-storage.md` | yes | none vs C1–C13 criteria text | Unresolved 1–2 remain GET-of-Editar / no Cancelar as written — **carried from 6b1363e** |

Visual unproven is enumerated (spacing, colour, type weight per archive mode and Contador leitura), not a blanket — **carried from 6b1363e**.

## Checks

Proofs at HEAD `64a4f11`: one `bin/rspec` invocation, 15 `-e` names, documentation/json: **15 passed, 0 failed**. Each name exists and ran (`setup_spec.rb`, `package_archives_spec.rb`, `setup_package_archive_storage_spec.rb`).

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | cadastro 200, heading, Google Drive copy, writable `#url`, no Editar/Confirmar in archive, no old Drive copy; h2 order Contador → Armazenamento → Certificado SEFAZ | `-e "GET /setup cadastro archive form is writable with Google Drive copy"` exit 0 | `spec/requests/setup_spec.rb:159` `:ok`; `:161-163` `headings.index("Contador")` `<` Armazenamento `<` `"Certificado SEFAZ"`; `spec/support/page_helpers.rb:126-144` heading include, Cole Google Drive, `Salvar arquivo`, `input#url` `border-rule`/`bg-sheet` not readonly/disabled, label, no archive Editar, no Confirmar, exact-text exclusions | PASS — **verified at 64a4f11** (order was FAIL in round 1) |
| C2 | PATCH folders URL 302 `/setup`, persist URL+id, GET leitura + toast `Pronto.` | `-e "PATCH /package_archive from cadastro persists folders URL and toasts Pronto"` exit 0 | `spec/requests/package_archives_spec.rb:12-21` `:found`, `redirect_to("/setup")`, url/id eqs, `expect_archive_leitura`, toast `success` / `Pronto.` | PASS — proof **verified at 64a4f11**; assertions **carried from 6b1363e** |
| C3 | standing URL labeled `p#url.font-medium`, Editar, no inputs/Salvar/Cole/Confirmar | `-e "GET /setup leitura archive is labeled text"` exit 0 | `setup_spec.rb:173` `:ok`; `page_helpers.rb:146-159` label, `p#url` `font-medium` text URL, not `border-rule`/`bg-sheet`, no `input/textarea/select`, no Salvar/Cole/Confirmar, Editar | PASS — proof **verified at 64a4f11**; assertions **carried from 6b1363e** |
| C4 | blank PATCH 302, URL/id absent, GET matches cadastro | `-e "PATCH /package_archive blank URL returns cadastro"` exit 0 | `package_archives_spec.rb:42-49` `:found`, `redirect_to("/setup")`, url/id `be_nil`, `expect_archive_cadastro` | PASS — proof **verified at 64a4f11**; assertions **carried from 6b1363e** |
| C5 | GET of archive Editar URL → 200 edição Confirmar, writable `#url` value standing URL, no Editar/Salvar/`p#url` | `-e "GET of Armazenamento Editar unlocks the writable archive form"` exit 0 | `setup_spec.rb:183-188` GET `archive_edit_control` href; `:ok`; `page_helpers.rb:162-175` Confirmar, `input#url` classes/value, no readonly, no Editar, no Salvar, no `p#url` | PASS — proof **verified at 64a4f11**; assertions **carried from 6b1363e** |
| C6 | PATCH new folders URL 302, persist new id, GET leitura + `Pronto.`; second identical PATCH still 302 and Leitura | `-e "PATCH /package_archive from Editar 302s to leitura and toasts Pronto"` exit 0 | `package_archives_spec.rb:60-69` first PATCH `:found`, redirect, url/id `1AbCdEfGhIjKlMnOpQrStUvWxYz123456`, `expect_archive_leitura` + toast; `:71-75` second PATCH same `new_url` `:found`, `redirect_to("/setup")`, GET `expect_archive_leitura` | PASS — **verified at 64a4f11** (second PATCH was FAIL in round 1) |
| C7 | file URL 422, stored URL unchanged, no toast, Confirmar form | `-e "PATCH /package_archive 422 file URL stays Confirmar"` exit 0 | `package_archives_spec.rb:103-106` `:unprocessable_content`, stored URL eq, `toast_node` nil, `expect_archive_edicao` | PASS — proof **verified at 64a4f11**; assertions **carried from 6b1363e** |
| C8 | wrong-host cadastro 422, url/id absent, no toast, Salvar arquivo form | `-e "PATCH /package_archive 422 during cadastro stays Salvar arquivo"` exit 0 | `package_archives_spec.rb:115-120` `:unprocessable_content`, url/id nil, toast nil, `expect_archive_cadastro` | PASS — proof **verified at 64a4f11**; assertions **carried from 6b1363e** |
| C9 | Contador leitura five `p.font-medium`, formatted CNPJ, labels, Editar, no inputs/Salvar/Cadastre; `md:grid-cols-2` | `-e "GET /setup leitura accountant fields are labeled text with formatted CNPJ"` exit 0 | `setup_spec.rb:76-77` `:ok` + `expect_accountant_leitura_cnpj_row`; `:78` `accountant_section` `div.grid` class includes `md:grid-cols-2`; `page_helpers.rb:104-123` five `p` texts including `11.222.333/0001-81`, `font-medium`, not border/sheet, labels, no Salvar/Cadastre, Editar | PASS — **verified at 64a4f11** (grid was FAIL in round 1) |
| C10 | CPF format + empty razão; blank optionals empty p + Editar; tax id stays digits after GET | three `-e` names all exit 0 | `setup_spec.rb:89-90` `p#tax_id` `390.533.447-05`, `p#legal_name` `""`; `:101-104` empty p ids + Editar; `:113` `11222333000181`; `:117` `39053344705` | PASS — proof **verified at 64a4f11**; assertions **carried from 6b1363e** |
| C11 | `edit=package_archive` archive edição + accountant leitura | `-e "GET /setup edit=package_archive unlocks archive and keeps accountant leitura"` exit 0 | `setup_spec.rb:199-201` `:ok`, `expect_archive_edicao`, `expect_accountant_leitura_cnpj_row` | PASS — proof **verified at 64a4f11**; assertions **carried from 6b1363e** |
| C12 | `edit=accountant` five writable inputs + digits tax id, no `p#presentation_name`, archive leitura; form `md:grid-cols-2` | `-e "GET /setup edit=accountant unlocks accountant and keeps archive leitura"` exit 0 | `setup_spec.rb:213-225` Salvar contador, each `input#` `border-rule` `bg-sheet` not readonly/disabled, `#tax_id` `11222333000181`, `form["class"]` includes `md:grid-cols-2`, `p#presentation_name` nil, `expect_archive_leitura`; cadastro helper `page_helpers.rb:97` same class | PASS — **verified at 64a4f11** (grid was FAIL in round 1) |
| C13 | design.md `setup` section archive cadastro/leitura/edição + Contador labeled text; no `Arquivo do pacote` / always-writable / `#81` / old Drive label | `-e "visual-identity setup archive is cadastro or labeled text"` exit 0 | `spec/docs/setup_package_archive_storage_spec.rb:9-26` includes heading, Cole/label Google Drive, `[Salvar arquivo]`, `font-medium`, `[Editar]`, `edit=package_archive`, `input#url`, `[Confirmar]`, `labeled`, `formatted CPF/CNPJ`, `edit=accountant`, `input chrome`; not `Arquivo do pacote`, `always-writable`, `#81`; stripped section not old Drive strings | PASS — proof **verified at 64a4f11**; assertions **carried from 6b1363e** (document; live composition now locked by C1/C9/C12) |

Most C1–C12 expected strings still sit in `PageHelpers` — readable at the cited helper lines; weak indirection, not missing evidence — **carried from 6b1363e**.

## Coverage (recomputed)

Arrangement and C6 idempotency rows **verified at 64a4f11**. Remaining member→proof cells **carried from 6b1363e** (authority unchanged; proofs re-ran).

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| Armazenamento form modes (3) | Cadastro C1 · Leitura C3 · Edicao C5 | live h2 order now C1 |
| `PATCH /package_archive` outcomes this cut (5) | C2 · C4 · C6 · C7 · C8 | Swept second identical PATCH now in C6 example |
| Contador leitura samples (3) | C9 · C10 CPF · C10 blanks | two-column grid now C9 |
| `#tax_id` display (3) | C9 CNPJ · C10 CPF · C10 blank | — |
| `params[:edit]` isolation (2) | C11 · C12 | C12 also asserts accountant form `md:grid-cols-2` |
| tax id storage after GET (2) | C10 CNPJ · C10 CPF | — |
| designed screens this cut binds (1) | `setup` | composition: section order C1; accountant 2-col C9/C12 |
| visual-identity screens not bound (5) | — | `login`, `denied`, `home`, `month`, `documents` |
| `setup` visual | — | spacing, colour, type weight (enumerated) |

Own-layer parse still in `spec/models/organization_spec.rb:129-180` — **carried from 6b1363e**; not in this feature diff.

## Test policy rows

Classified product files not in the fix diff — **carried from 6b1363e**. Request-spec files the fix touched still meet the HTML bar.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `Organization#update_package_archive` / `DriveFolderUrl` (existing); `PATCH /package_archive` HTML modes | own layer + request | own layer existing in `organization_spec`; HTTP/HTML C2, C4, C6, C7, C8 yes |
| Decides, not reached across a boundary | none new | own layer | n/a |
| Entry point that decides nothing | — | — | n/a |
| View / `GET /setup` chrome (checklist: request specs; no view specs in repo) | `setup/show.html.erb`, `SetupController#show` | request HTML per mode | C1, C3, C5, C9–C12 yes, including C1 h2 order and C9/C12 grid |
| Instrumentation | toast `#76` | consumer | C2, C6 toast assertions |

## Swept existing

| Row | Cited constraint | Present |
|---|---|---|
| idempotency C6 | second identical `PATCH` still `302` and Leitura | yes `package_archives_spec.rb:71-75` — **verified at 64a4f11** |
| authorization | `require_coordinator_organization` on Setup and PackageArchives | yes `setup_controller.rb:2`, `package_archives_controller.rb:2`, definition `application_controller.rb:56-62` — **carried from 6b1363e** |
| validation parse table | `DriveFolderUrl` / `update_package_archive` unchanged | yes; C7–C8 add HTML only — **carried from 6b1363e** |
| not in scope | Cancelar, `<a href>` Drive, hiding empty p, SEFAZ/banks/extras | policy — **carried from 6b1363e** |

## Faults injected

Scratch: `git worktree add /tmp/tlc-verify-worktrees/setup-package-archive-storage-r2 HEAD`. Real-tree porcelain matched baseline before add and after remove. Cap 5. Re-injected only surfaces the fix created (new assertions). Round 1 mutants **carried from 6b1363e** (not re-run; product code untouched).

| Mutation | Location | Killed |
|---|---|---|
| swap Contador and Armazenamento `<section>` blocks | `app/views/setup/show.html.erb` | yes - C1 `setup_spec.rb:162` `headings.index("Contador")` `<` Armazenamento |
| leitura wrapper `md:grid-cols-2` → `md:grid-cols-1` | same, accountant leitura `div.grid` | yes - C9 `setup_spec.rb:78` |
| accountant `form_with` `md:grid-cols-2` → `md:grid-cols-1` | same, `/accountant` form | yes - C12 `setup_spec.rb:223` |
| identical `params[:url]` renders `422` | `app/controllers/package_archives_controller.rb` | yes - C6 second PATCH `package_archives_spec.rb:72` expected `:found` |

C13 document proof not mutated (cap; fix did not touch it). Cadastro helper `page_helpers.rb:97` shares the accountant form class with C12.

Round 1 (carried): `p#url`→readonly input killed C3; always `Confirmar` killed C1; `@package_archive_editing = false` killed C5; 422 omit editing flag killed C7; `accountant_reading = false` killed C9.

## Gate

`bin/rspec spec/requests/setup_spec.rb spec/requests/package_archives_spec.rb spec/docs/setup_package_archive_storage_spec.rb` with the 15 checklist `-e` names — 15 passed, 0 failed.

## Ranked gaps

None that fail the gate. Enumerated visual-unproven remains spacing, colour, type weight. Helper-indirection of expected copy is unchanged and still not a missing `file:line`.
