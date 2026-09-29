# Principal coordinator Verification

**Verdict**: FAIL
**Profile**: ui
**Diff range**: 4ff5bb9..8de3438
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

Proofs re-run at `8de3438`. Step 1 this round: screen `administration` only (fix `9261cbc..8de3438` removed `h2` `Organizações` from `app/views/administration/show.html.erb`). Other screens, check citations, Coverage rows whose authority the fix did not touch, Test policy, and Swept: carried from `9261cbc`. Working tree still has uncommitted view/header edits; proofs and screen comparison use **HEAD**.

## Binding sources

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.design/administration-list.md` screen `administration` | yes - repo file, re-opened at `8de3438` | none vs C13/C14 copy (headers, principal email, Status, `Editar`, no peer/`Corrigir`/`Remover`) | empty list `Nenhuma organização cadastrada.` (design decides it; no check in this artifact). Populated rest drawing has no `h2`; HEAD markup matches that, but no check asserts the heading is absent |
| `.design/administration-list.md` screens `administration/:id/edit`, `home` people | carried from `9261cbc` | none on `Corrigir`-only, `Remover` confirm, home order/`Revogar` | edit chrome `Administração` link (design does not draw it) — still in `HEAD` `app/views/administration/edit.html.erb` |
| `.tasks/principal-coordinator.md` | carried from `9261cbc` | none vs C1–C32 copy | - |
| GitHub #66 | carried from `9261cbc` | item 4 out of task / ADR-0007 | - |
| `CONTEXT.md` Principal coordinator | carried from `9261cbc` | none | - |
| `docs/adr/0007-administration-access.md` | carried from `9261cbc` | none (C29) | - |
| `app/models/invite.rb` `accept!` | carried from `9261cbc` | none (C27) | - |
| `app/models/access.rb` uniqueness | carried from `9261cbc` | none | - |
| `app/controllers/accesses_controller.rb` | carried from `9261cbc` | none | - |
| `DESIGN.md` (not interface-binding) | not required as binding | - | - |

**Screen `administration` (enumerated at `8de3438`)**: regions are (1) one row `h1` `Administração` + `Adicionar organização` (`bg-caixa`) (2) optional notices (3) populated: four-column header `Nome` / `Email coordenador` / `Status` / `Editar` then data rows name, principal email, Status, `Editar`; mail sentence under the four columns when present (4) empty: table omitted, `Nenhuma organização cadastrada.` No extra `h2` `Organizações` in HEAD. C13/C14/C23/C24 cover populated list copy and mail-on-row, not empty, not “no `h2`”. Screens table visual unproven remains spacing, colour, type weight per screen — not a blanket exemption.

## Checks

Proofs: one `./bin/rspec` over the ten spec files with one `-e` per named proof — **47 passed, 0 failed** at `8de3438`. Evidence citations carried from `9261cbc` (fix did not shift those spec lines).

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | home principal first; `Revogar` on peer+submitter; invites; no `coordenador principal` | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/organizations_spec.rb:232`; `:241`; `spec/models/organization_spec.rb:626` | PASS |
| C2 | peer: same order; no coordinator `Revogar`; submitter `Revogar`; invites | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/organizations_spec.rb:251-257` | PASS |
| C3 | principal DELETE peer `302` `/`; Access gone; pointer stays | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/accesses_spec.rb:132-136` | PASS |
| C4 | principal DELETE self `404` empty; Access and pointer stay | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/accesses_spec.rb:148-151` | PASS |
| C5 | peer DELETE principal `404` empty; Access stays | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/accesses_spec.rb:163-165` | PASS |
| C6 | peer DELETE other peer `404`; Access stays | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/accesses_spec.rb:178-179` | PASS |
| C7 | peer DELETE self `404` empty; zoe remains principal | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/accesses_spec.rb:190-193` | PASS |
| C8 | peer DELETE submitter `302` `/`; Access gone | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/accesses_spec.rb:206-208` | PASS |
| C9 | submitter `h1` `Início`; no `Revogar` / `Convidar coordenador` | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/organizations_spec.rb:268-270` | PASS |
| C10 | signed-out DELETE `302` `/login`; Access unchanged | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/accesses_spec.rb:218-221` | PASS |
| C11 | last coordinator `destroy` false, `:last_coordinator`, row remains | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/models/access_spec.rb:36-38` | PASS |
| C12 | concurrent self-DELETE both `404`; `destroy` not called | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/accesses_spec.rb:64-67` | PASS |
| C13 | list `200`, headers, principal email `Pendente`, `Editar` classes; no peer/submitter/`Corrigir`/`Remover` | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:19-42`; `spec/models/organization_spec.rb:600`. Does not assert absence of `h2` | PASS |
| C14 | Status `Ativa` when principal has `google_uid` | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:57`; `spec/models/organization_spec.rb:611-614` | PASS |
| C15 | edit: one `Corrigir` on principal; peer text; `Corrigir nome`; `Remover` confirm; no submitter | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:76-96` | PASS |
| C16 | `POST /administration/email` peer `404`; Access unchanged; not the field | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:247-252` | PASS |
| C17 | signed-out writes `302` `/login`; counts/deliveries unchanged | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_spec.rb:10-13` | PASS |
| C18 | non-admin `404` empty; counts/deliveries unchanged | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_spec.rb:24-27` | PASS |
| C19 | invalid Continuar `422`; notice under `h1`; field kept | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:163-170` | PASS |
| C20 | taken peer Continuar `422`; notice; field kept | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:187-191` | PASS |
| C21 | submitter Continuar not collision; confirm promotes, no mail | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:204-205`, `:227-236`; `spec/models/organization_spec.rb:643-647` | PASS |
| C22 | existing Account confirm: no new Account, no mail, list email | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:381-391`; `spec/models/organization_spec.rb:660-664` | PASS |
| C23 | new Account welcome copy + list sentence | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:352-368`; `spec/models/organization_spec.rb:465-469` | PASS |
| C24 | `deliver_now` raises: write kept; error notice + primary resend | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:427-436` | PASS |
| C25 | same-email confirm: no write, no mail | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:280-287`; `spec/models/organization_spec.rb:446-449` | PASS |
| C26 | raise before commit rolls back pointer, Access, Invite; no mail | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/models/organization_spec.rb:506-511` | PASS |
| C27 | register sets FK; accept does not; list and home stay principal | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/models/organization_spec.rb:671`; `spec/models/invite_spec.rb:40-43`; `spec/requests/administration_access_spec.rb:595-596`; `spec/requests/organizations_spec.rb:284` | PASS |
| C28 | bootstrap/seed set FK; bootstrap still aborts on existing Account | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/tasks/coordinator_bootstrap_spec.rb:32`; `:57-60`; `spec/models/development_coordinator_seed_spec.rb:19` | PASS |
| C29 | remove 302; org/Access/Invite gone; Accounts remain | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:616-626`; `spec/models/organization_spec.rb:524-528` | PASS |
| C30 | BankAccount remove `422`; notice on edit row; close data unchanged | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:672-678`; `spec/models/organization_spec.rb:536-537` | PASS |
| C31 | missing id `404`; other Organization remains | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/requests/administration_access_spec.rb:755-756` | PASS |
| C32 | backfill earliest `created_at` then `id`; column not null | named batch exit 0 at `8de3438` | carried from `9261cbc`: `spec/migrations/add_principal_coordinator_account_id_to_organizations_spec.rb:39-42`; assembly `db/schema.rb:170` `null: false` | PASS |

## Coverage (recomputed where the fix touched)

| Set | Members from authority | Proof | Unproven |
|---|---|---|---|
| designed screens (3) | design: `administration`, `administration/:id/edit`, `home` people — `administration` recomputed at `8de3438` | C13 · C15 · C1 | empty `administration` (no check in this artifact; `spec/requests/administration_spec.rb:33` `expect_empty_list` exists outside these proofs). No-`h2` not in C13. Edit `Administração` link — carried from `9261cbc`. `home` invites — Out of scope |
| coordinator DELETE callers (6) | carried from `9261cbc` | C3–C8 | - |
| signed-out / non-admin writes | carried from `9261cbc` | C17 · C18 | - |
| list Status (2) | `Pendente` / `Ativa` — recomputed (list markup) | C13 · C14 | - |
| Continuar (3) | carried from `9261cbc` | C19 · C20 · C21 | - |
| principal-email writes (6) | carried from `9261cbc` | C21–C26 | overlapping confirms — Unresolved 2 |
| pointer writers (4) | carried from `9261cbc` | C27 · C28 | - |
| last-coordinator destroy (1) | carried from `9261cbc` | C11 | - |
| concurrent self-DELETE (1) | carried from `9261cbc` | C12 | - |
| removal (3) | carried from `9261cbc` | C29–C31 | other close-data members — named as already proven elsewhere |
| backfill (2) | carried from `9261cbc` | C32 | - |
| startup NOT NULL | carried from `9261cbc` `db/schema.rb:170` | C32 | - |

## Test policy rows

Carried from `9261cbc`. Fix touched only `show.html.erb` (not classified as a decision table). No unmet row to re-judge.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `organization.rb`; `accesses_controller.rb` revoke guard | own layer + HTTP | yes — carried from `9261cbc` |
| Decides, not reached across a boundary | `access.rb` last coordinator; migration backfill | own layer | yes C11 · C32 |
| Entry point that decides nothing | not the shape of the new revoke/email write | - | n/a |
| Instrumentation / pass-through | listed_coordinator_account forwards the FK | consumer | yes C13/C14 |

## Swept existing

Carried from `9261cbc`: `Access#destroy` `:last_coordinator`; removal `delete_all` Accesses then org; `Invite#accept!` does not write the FK.

## Faults injected

Scratch: `git worktree add /tmp/principal-coordinator-verify-r2 HEAD`. Real-tree porcelain unchanged after `worktree remove`. Surfaces this round: list markup in `show.html.erb` only. Round-1 faults on controller/model/migration carried as killed at `9261cbc` (those files unchanged).

| Mutation | Location | Killed |
|---|---|---|
| header `Email coordenador` → `Email do coordenador` | `app/views/administration/show.html.erb` | yes — C13 `header_row` nil |
| restored `h2` `Organizações` above the four columns | `app/views/administration/show.html.erb` | **no** — C13 and C14 still pass |

## Gate

`./bin/rspec` on the ten spec files with one `-e` per named proof — **47 passed, 0 failed** (`8de3438`).

Overall FAIL: empty-list coverage gap; extra edit `Administração` link (carried); surviving mutant for the extra `h2` this fix removed. Named proofs green. Extra `h2` is absent in HEAD markup.
