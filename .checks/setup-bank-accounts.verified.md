# Setup bank accounts Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: `9b1ae73ce34b8c0fd2da6ee14612aade4e6fa19c`..`75f6d644da9635a819e4572aca5138f1899bd31c`
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| GitHub issue #83 | yes — `gh issue view 83` (WebFetch unavailable to this subagent) | none. Recorte label is written `Agencia/Conta Corrente`; task/design/checks use `Agência/Conta Corrente`. Same field; accent is the interface transcription C12 binds. Header-row vs cell-order is Unresolved 2, not a #83 concrete | none of the recorte controls: label, four-cell order, one section form, Adicionar/Editar fill, Desativar/Reativar on the row, stay on `/setup` |
| `.specs/features/visual-identity/design.md` screen `setup` | yes — file in the repo, section `### setup — GET /setup` | none. ASCII and bullets match C12: four cells, `Inativa` / `Desativar` / `Reativar` / `Editar` on the row, one section form, `Agência/Conta Corrente`, `Adicionar conta` / `Salvar conta`, `edit=bank_account`, no per-row fold | bank empty line is not in the ASCII (sample rows only) but is in task criterion 1 / C1. `Forms are two columns from 768px` names the accountant form as the example; this cut does not bind Contador. `Inativa` `ink-soft` and quiet row actions are colour/weight, enumerated unproven |
| `.tasks/setup-bank-accounts.md` | yes — file in the repo | none. C1–C12 are criteria 1–12 with the Until-answered values for Unresolved 1–4 | none of the named criteria |

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | `GET /setup` empty: `200`, empty line, no rows, no `Coordenadas`, add form labels and `Adicionar conta` | `bin/rspec spec/requests/setup_spec.rb spec/requests/bank_accounts_spec.rb spec/docs/setup_bank_accounts_spec.rb --example-matches "<C1–C12 names>"` — example passed (14 examples, 0 failures) | `spec/requests/setup_spec.rb:229` `have_http_status(:ok)`; `:231` `Nenhuma conta bancária`; `:232` no `li[data-row="bank-account"]`; `:233` not `Coordenadas`; `:234` `expect_bank_account_add_form` → `spec/support/page_helpers.rb:176-182` action `/bank_accounts`, submit `Adicionar conta`, labels `Nome` / `Banco` / `Agência/Conta Corrente` | PASS |
| C2 | listed four cells in order; `Inativa`; no `Coordenadas`; no header row; Alfa before Zeta | same invocation — passed | `spec/requests/setup_spec.rb:252-254` row hooks; `:254` Alfa < Zeta; `:256-258` Banco do Brasil < Conta Principal < ag 1234 < extrato-conta-principal; `:260-262` Santander < Parada < extrato-parada and `Inativa`; `:263-264` not `Coordenadas`; `:271` `headerish` `be_nil` | PASS |
| C3 | exactly one section form add; twelve-name `select#compe`; no `Outro`; no details `Editar`; row `Editar` on `/setup`; Desativar/Reativar forms lack `#name` | same invocation — passed | `spec/requests/setup_spec.rb:287` `forms.size` `eq(1)`; `:288` add form; `:304` options equal the twelve COMPE pairs; `:305` not `Outro`; `:306` no details summary `Editar`; `:310-311` `Editar` href includes `/setup`; `:317` deactivate forms `#name` `be_nil` | PASS |
| C4 | GET row Editar: `200`, both rows, PATCH action, `_method` patch, `Salvar conta`, filled fields, one named form | same invocation — passed | `spec/requests/setup_spec.rb:335` `:ok`; `:336-337` both rows; `:339` action `/bank_accounts/#{principal.id}`; `:340` `_method` patch; `:341` `Salvar conta`; `:342-344` name / compe `001` / `ag 1234`; `:345` labels; `:347` `named_forms.size` `eq(1)` | PASS |
| C5 | PATCH section form `302` `/setup`, name `Nova Conta` slug `nova-conta`, then add form and toast `Pronto.` | same invocation — passed | `spec/requests/bank_accounts_spec.rb:35-36` `:found` `redirect_to("/setup")`; `:38-39` name / slug; `:42` add form; `:43-44` toast kind `success` text `Pronto.` | PASS |
| C6 | POST persist BB `Conta Principal` `302`, four-cell row, toast `Pronto.` | same invocation — passed | `spec/requests/bank_accounts_spec.rb:10-15` `:found` `/setup`, count `1`, `be_active`, `Banco do Brasil`; `:19-21` four-cell order; `:22-23` toast `success` `Pronto.` | PASS |
| C7 | other-org and unknown `bank_account_id` stay add; no `Alheia` | same invocation — both examples passed | `spec/requests/setup_spec.rb:359-361` `:ok`, not `Alheia`, add form; `:370-371` `:ok`, add form | PASS |
| C8 | Desativar / Reativar / `Inativa`; no `Excluir`; DELETE `404` keeps row | same invocation — both examples passed | `spec/requests/setup_spec.rb:385-389` `Desativar` / `Reativar` / `Inativa` / not `Excluir`; `spec/requests/bank_accounts_spec.rb:249-250` `:not_found` and `BankAccount.find` still the row. DELETE example lives in this spec file on the feature branch (touched with the new examples) | PASS |
| C9 | PATCH `active` false `302`, row stays `Inativa`, add form, toast `Pronto.` | same invocation — passed | `spec/requests/bank_accounts_spec.rb:54-55` `:found` `/setup`; `:60-64` row present, `Conta Principal`, `Inativa`, add form; `:64-65` toast `Pronto.` | PASS |
| C10 | POST colliding slug: no extra row, `422`, add form submitted fields, no toast | same invocation — passed | `spec/requests/bank_accounts_spec.rb:75-76` count `1`, `:unprocessable_content`; `:78-79` action `/bank_accounts`, `Adicionar conta`; `:80-82` `Cafe` / `033` / `ag 9`; `:83` toast `be_nil` | PASS |
| C11 | PATCH colliding slug: name stays `Outra`, `422`, edit form submitted fields, no toast | same invocation — passed | `spec/requests/bank_accounts_spec.rb:94-95` name `Outra`, `:unprocessable_content`; `:97-98` action `/bank_accounts/#{other.id}`, `Salvar conta`; `:99-101` `Cafe` / `033` / `x`; `:102` toast `be_nil` | PASS |
| C12 | design `setup` four cells and one section form; visual-identity C42 follows | same invocation — passed | `spec/docs/setup_bank_accounts_spec.rb:8-20` section excludes `Coordenadas` / details Editar / `▸ Editar`; includes `li[data-row="bank-account"]`, `Agência/Conta Corrente`, `Adicionar conta`, `Salvar conta`, `Desativar`, `Reativar`, `edit=bank_account`, `one section form`, bank name before agência/conta corrente, `extrato-{slug}`; `:23-27` C42 excludes `<details>`/`<summary>`, includes `Editar`, `/setup`, `Salvar conta` | PASS |

## Coverage (recomputed)

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| list occupancy (2) | empty C1 · listed C2 | - |
| cell members (4) | bank presentation name · account name · coordinates text · `extrato-{slug}` — all asserted on `Conta Principal` in C2 (`setup_spec.rb:256-258`) | blank coordinates cell on `Parada` is only order-to-slug, not an empty-node assert |
| section form mode (8) | GET add empty C1 · GET add listed C3 · GET edit C4 · GET other-org C7 · GET unknown id C7 · POST 422 add C10 · PATCH 422 edit C11 · GET after 302 add C5, C6, C9 | - |
| POST /bank_accounts outcomes this cut observes (2) | persist `302` + `Pronto.` C6 · colliding slug `422` C10 | empty slug / unknown COMPE left in existing `bank_accounts_spec` as the checklist says |
| PATCH /bank_accounts/:id outcomes this cut observes (3) | section-form save `302` C5 · `active` false `302` C9 · colliding slug `422` C11 | other-org `404` existing; DELETE `404` C8 |
| designed screens this cut binds (1) | authority: visual-identity `## Screens` members `login`, `denied`, `home`, `setup`, `month`, `documents`. This cut binds `setup` via C1–C12 | `login`, `denied`, `home`, `month`, `documents` — out of scope (checklist) |
| visual-identity screens this cut does not bind (5) | — | those five |
| `setup` banks visual (3 × 6 states) | — | spacing, colour, type weight — enumerated, not a blanket |

Landing set: 422 redisplays submitted fields without dirtying the list — C10 (add) and C11 (edit keeps persisted `Outra`). No extra enumeration in Landing without a join.

No level gap: C1–C11 name HTTP status/HTML and assert in request specs. C12 names the design document and asserts file text.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `BankAccount` persist (`create_for` / `apply_from`) unchanged; HTTP chrome on `BankAccountsController`, `load_setup` / `assign_editing_bank_account_from_query` | own layer for persist members; request spec for status and who may call | persist uniqueness stays in existing model validations / `bank_account_spec` (out of this cut). New 302/422 HTML, toast, add vs edit, org-scoped edit query asserted at HTTP C1–C11. Closest analogue: Contador `?edit=accountant` request specs. Follow |
| Decides, not reached across a boundary | none added | own layer | n/a — no new isolated decision table |
| Entry point that decides nothing | `SetupController#show` loads setup | request spec | C1–C4, C7, C8 HTML |
| Instrumentation / pass-through | `redirect_success` → `Pronto.` | consumer | C5, C6, C9 |

`.cursor/rules/rails.mdc` names own-layer + request spec for decisions over HTTP; system specs only when request cannot settle. Every named observation is HTML or status. Rows met.

## Swept existing

- `BankAccountsController` and `SetupController` `before_action :require_coordinator_organization` — present (`bank_accounts_controller.rb:2`, `setup_controller.rb:2`); helper redirects unauthenticated to login and `head :not_found` unless coordinator (`application_controller.rb:56-62`)
- unique `(organization_id, name)` / `(organization_id, slug)` — `app/models/bank_account.rb:10-11`
- success toast helper — `redirect_success` sets `Pronto.` (`application_controller.rb:183-184`)

## Faults injected

Scratch: `git worktree add /tmp/tlc-verify-sba HEAD`. Real tree porcelain empty before and after. Cap 5 distinct surfaces.

| Mutation | Location | Killed |
|---|---|---|
| label `Agência/Conta Corrente` → `Coordenadas` | `app/views/setup/show.html.erb` | yes — C1 |
| swap first two list cells (name before bank) | `app/views/setup/show.html.erb` | yes — C2 |
| edit query `BankAccount.find_by` unscoped | `application_controller.rb` `assign_editing_bank_account_from_query` | yes — C7 other-org |
| `redirect_success("/setup")` → `redirect_to "/setup"` (no flash) on create and update | `bank_accounts_controller.rb` | yes — C6 |
| omit `assign_bank_account_form_from_params` on POST 422 | `bank_accounts_controller.rb#create` | yes — C10 |

Worktree removed; main porcelain still empty.

## Gate

`bin/rspec spec/requests/setup_spec.rb spec/requests/bank_accounts_spec.rb spec/docs/setup_bank_accounts_spec.rb --example-matches "<fourteen named examples>"` — 14 passed, 0 failed.
