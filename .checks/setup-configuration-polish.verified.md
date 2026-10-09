# Setup configuration polish Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: `1aa5afe..1d37e07` (`1aa5afe` merge of #104 .. `1d37e078ea960a8da0e8f33e674d7ff6bcbd360b`)
**Round**: 2 - full
**Verifier**: independent sub-agent (author != verifier)

Proofs re-run at HEAD in one RSpec invocation (42 examples, 0 failures). Prior `.verified.md` was not used as evidence. Porcelain after fault worktree removal matches the pre-fault baseline (`?? .checks/setup-configuration-polish.verified.md`, `?? vendor/bundle/`).

## Binding sources

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.tasks/setup-configuration-polish.md` | yes - repo file | none — C1–C28 match criteria 1–28 | - |
| https://github.com/gutors/ai-accounting-assistant/issues/105 | yes - `gh issue view 105` (anonymous HTTP fetch 404) | none — mask, labels, folds, Situação, org override, month hide, 422 | - |
| `.specs/features/visual-identity/design.md` `setup` | yes - repo file § `### \`setup\`` | none — `text-ink-soft` / `font-medium`, `tax-id-mask`, bank `<details>` `Adicionar conta`, `Ativa`/`Inativa`, extra `<details>` `Adicionar tipo extra`, `Ativo`/`Inativo`, base Desativar/Ativar no Excluir | - |
| `.specs/features/visual-identity/design.md` `month` | yes - repo file § `### \`month\`` | none — `Marcar tarifa` / `Marcar honorário` absent when that offer is inactive; marked `Tarifa bancária` + `Desmarcar exceção` stay | - |
| `docs/adr/0003-extra-exception-kinds.md` | yes - repo file | none — two Organization booleans, PATCH `:kind` ∈ {`bank_fee`,`accountant_fee`}, enum unchanged, no ExtraExceptionKind insert | - |

Screens table visual unproven is enumerated (spacing, colour, type weight on Contador labels / folds / Situação, and on Resolver) — not a blanket fidelity clause.

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | `#tax_id` on `/accountant` form, not readonly, `inputmode` numeric, `tax-id-mask` typed | `spec/requests/setup_spec.rb` `GET /setup cadastro tax_id has tax-id-mask wiring` passed | `spec/requests/setup_spec.rb:648-652` - `accountant_form(...).at_css("#tax_id")`; `readonly` nil; `inputmode` `numeric`; `data-controller` `tax-id-mask`; `data-action` `input->tax-id-mask#typed` | PASS |
| C2 | type `11222333000` → `112.223.330-00`; then 1,8 → `11.222.333/0001-8`; then 1 → `11.222.333/0001-81` | `spec/system/tax_id_mask_spec.rb` `cadastro tax_id types CPF then CNPJ grouping` passed | `spec/system/tax_id_mask_spec.rb:27` `eq("112.223.330-00")`; `:30` `eq("11.222.333/0001-8")`; `:32` `eq("11.222.333/0001-81")` | PASS |
| C3 | fifteenth digit dropped; value stays `11.222.333/0001-81` | `spec/system/tax_id_mask_spec.rb` `cadastro tax_id drops a fifteenth digit` passed | `spec/system/tax_id_mask_spec.rb:44` `expect(field.value).to eq("11.222.333/0001-81")` after `send_keys("9")` | PASS |
| C4 | edit prefills CNPJ `11.222.333/0001-81` and CPF `390.533.447-05` | both system examples passed | `spec/system/tax_id_mask_spec.rb:53` CNPJ; `:62` CPF | PASS |
| C5 | PATCH masked CNPJ `302` `/setup`, store `11222333000181`; persist digits | both named examples passed | `spec/requests/accountants_spec.rb:16-18` `:found`, `redirect_to("/setup")`, `accountant_tax_id` `eq("11222333000181")`; `spec/models/organization_spec.rb:14` same stored digits via `update_accountant` | PASS |
| C6 | leitura Contador labels `text-ink-soft` not `font-medium`; five `p#` `font-medium`; `h2` Contador not `text-ink-soft` | `GET /setup leitura Contador labels are text-ink-soft` passed | `spec/requests/setup_spec.rb:665-669` five labels + `p##{id}` + `h2` class | PASS |
| C7 | cadastro and edit accountant labels same; other sections keep `font-medium` | both named examples passed | `spec/requests/setup_spec.rb:681-687` Contador labels + archive/certificate/bank/extras `font-medium`; `:700-701` edit labels | PASS |
| C8 | bank add form in closed `<details>` summary `Adicionar conta`; `#certificate` outside | named example passed | `spec/requests/setup_spec.rb:713-718` `open` false; summary `Adicionar conta`; submit `Adicionar conta`; `#certificate` not under that details | PASS |
| C9 | `Conta Principal` `Ativa`+`Desativar`; `Parada` `Inativa`+`Reativar` | named example passed | `spec/requests/setup_spec.rb:734-739` include/exclude those strings | PASS |
| C10 | edit bank opens details; PATCH `/bank_accounts/{id}`; `Salvar conta`; summary still `Adicionar conta` | named example passed | `spec/requests/setup_spec.rb:752-757` `open` true; `action` `/bank_accounts/#{id}`; `_method` patch; submit `Salvar conta` | PASS |
| C11 | blank name POST `422`, details `open`; valid POST then GET details closed | both named examples passed | `spec/requests/bank_accounts_spec.rb:74-77` `:unprocessable_content`, count `0`, `open` true; `:86-88` `:found` then `open` false | PASS |
| C12 | extra form in closed `<details>` summary `Adicionar tipo extra`; name, justification, submit | named example passed | `spec/requests/setup_spec.rb:768-773` `open` false; summary; `#extra_exception_kind_name`; `name="justification"`; submit | PASS |
| C13 | Doação `Ativo`/`Desativar`; Folha `Inativo`/`Ativar`/`Excluir`; no `Desativado`/`Reativar` | named example passed | `spec/requests/setup_spec.rb:791-801` those includes/excludes | PASS |
| C14 | blank-name POST `422` opens extra details; used DELETE `422` leaves details closed | both named examples passed | `spec/requests/extra_exception_kinds_spec.rb:106-108` `:unprocessable_content`, count `0`, `open` true; `:242-244` `:unprocessable_content`, row remains, `open` false | PASS |
| C15 | base rows `Ativo`/`Desativar`, no `Excluir`/`Ativar`/`Inativo`; not extra rows; ExtraExceptionKind count `0` | named example passed | `spec/requests/setup_spec.rb:810-825` defaults true; `span.text-ink-soft` `Ativo`; actions include `Desativar` not `Excluir`/`Ativar`; extra names omit both bases; count `0` | PASS |
| C16 | PATCH `bank_fee` false: flag, sibling true, `302` `/setup`, Inativo/Ativar, toast `Pronto.`, idempotent second PATCH | both named examples passed | `spec/requests/base_document_exceptions_spec.rb:10-29` `:found`, `redirect_to("/setup")`, flags, toast, row copy, second `:found` still false; `spec/models/organization_spec.rb:20-23` `apply_base_document_exception("bank_fee", false)` | PASS |
| C17 | PATCH `accountant_fee` false: flag, bank_fee unchanged, Honorário Inativo/Ativar, no Excluir | both named examples passed | `spec/requests/base_document_exceptions_spec.rb:39-49`; `spec/models/organization_spec.rb:30-32` | PASS |
| C18 | PATCH `bank_fee` true after false restores Ativo/Desativar | both named examples passed | `spec/requests/base_document_exceptions_spec.rb:59-66`; `spec/models/organization_spec.rb:39-40` | PASS |
| C19 | inactive bank_fee offer omits `kind=bank_fee` and `Marcar tarifa`; still `Marcar honorário` | named example passed | `spec/requests/months_spec.rb:1541-1543` bank_fee input nil; tarifa submit nil; honorário present | PASS |
| C20 | inactive accountant_fee offer omits `kind=accountant_fee` and `Marcar honorário` | named example passed | `spec/requests/months_spec.rb:1554-1555` | PASS |
| C21 | POST `bank_fee` while offer inactive: kind nil, `422`, `Informe um tipo de exceção permitido` | both named examples passed | `spec/requests/document_exceptions_spec.rb:58-60` `:unprocessable_content` + copy + nil kind; `spec/models/payment_spec.rb:66-67` same error + nil | PASS |
| C22 | POST `accountant_fee` while offer inactive: same 422 shape | both named examples passed | `spec/requests/document_exceptions_spec.rb:70-72`; `spec/models/payment_spec.rb:76-77` | PASS |
| C23 | already marked `bank_fee` stays `Tarifa bancária`, not `Documento faltante`, still `Desmarcar exceção` | named example passed | `spec/requests/months_spec.rb:1567-1569` | PASS |
| C24 | org B still `Marcar tarifa` while A bank_fee inactive; A flag unchanged | named example passed | `spec/requests/months_spec.rb:1583-1584` honorário/tarifa present on B; `org_a.bank_fee_exception_active` `false` | PASS |
| C25 | unauthenticated PATCH `302` `/login`; submitter `404`; flags unchanged | both named examples passed | `spec/requests/base_document_exceptions_spec.rb:75-77` `:found` `redirect_to("/login")` flag true; `:87-88` `:not_found` flag true | PASS |
| C26 | PATCH `not_a_kind` `404`; both flags unchanged | named example passed | `spec/requests/base_document_exceptions_spec.rb:97-100` | PASS |
| C27 | enum exactly `bank_fee`/`accountant_fee`; reserved extra POSTs `422`; deactivate inserts no ExtraExceptionKind | all four named examples passed | `spec/models/payment_spec.rb:103-104` `contain_exactly`; `spec/requests/extra_exception_kinds_spec.rb:83-84` and `:96-97` `:unprocessable_content` count `0`; `spec/requests/base_document_exceptions_spec.rb:109` count `0` | PASS |
| C28 | design.md `setup` and `month` record the polish | named example passed | `spec/docs/setup_configuration_polish_spec.rb:9-26` includes mask, folds, Situação copy, no Excluir, inactive marks | PASS |

## Coverage (recomputed)

Authority: Landing / ADR-0003 / `Organization::BASE_DOCUMENT_EXCEPTION_COLUMNS` / `Payment` enum / design screen list — not the author's table alone.

| Set (size) | Members from authority | Proofs that assert them | Unproven |
| --- | --- | --- | --- |
| tax-id grouping by digit count (4) | 11 CPF · 13 CNPJ · 14 CNPJ · 15 dropped — Landing | C2 `:27` `:30` `:32` · C3 `:44` | - |
| prefilled tax-id shapes (2) | CNPJ · CPF — C4 | C4 `:53` `:62` | - |
| Contador label surfaces (3) | leitura · cadastro · edit | C6 · C7 · C7 | - |
| bank details open/closed (4 listed; table said 3) | closed GET · open edit · open 422 · closed after valid POST | C8 · C10 · C11 · C11 | - |
| bank Situação (2) | `Ativa` · `Inativa` | C9 | - |
| extra details open/closed (3) | closed GET · open create 422 · closed used DELETE 422 | C12 · C14 · C14 | - |
| extra Situação/actions (2) | active Ativo/Desativar · inactive unused Inativo/Ativar/Excluir | C13 | - |
| base offer kinds (2) | `bank_fee` · `accountant_fee` from `BASE_DOCUMENT_EXCEPTION_COLUMNS` (`organization.rb:21-24`) | C16/C18/C19/C21 · C17/C20/C22 | - |
| base offer states on setup (2) | offered Ativo/Desativar · hidden Inativo/Ativar | C15/C18 · C16/C17 | - |
| `PATCH /base_document_exceptions/:kind` callers (3) | coordinator · unauthenticated · submitter | C16 · C25 · C25 | - |
| unknown kind token (1) | `not_a_kind` | C26 | - |
| reserved extra names (2) | `Tarifa bancária` · `Honorário do contador` from `ExtraExceptionKind::BASE_NAMES` | C27 | - |
| `Payment.document_exception_kinds` (2) | `bank_fee` · `accountant_fee` (`payment.rb:9`) | C27 | - |
| designed screens this cut binds (2) | `setup` · `month` from design.md | C1, C6–C18, C28 · C19, C20, C23, C24, C28 | - |
| visual-identity screens this cut does not bind (4) | `login`, `denied`, `home`, `documents` | — (out of scope) | those four, as declared |
| `setup` visual (3) | spacing, colour, type weight | — | declared |
| `month` visual (3) | spacing, colour, type weight | — | declared |

- Status/route/shape claims C1, C5, C8, C10, C11, C12, C14–C27 sit in request or system specs, not only model.
- Checklist Coverage size “bank details (3)” under-counts four members; all four have proofs.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `Organization#apply_base_document_exception`; `Payment#mark_base`; `BaseDocumentExceptionsController#update` | own layer + HTTP; one case per member | yes — both kinds at model (`organization_spec.rb:17-40`, `payment_spec.rb:60-77`) and HTTP (`base_document_exceptions_spec.rb`, `document_exceptions_spec.rb:51-73`); callers unauth/submitter/unknown at HTTP (C25–C26) |
| Decides, not reached across a boundary | `tax_id_mask_controller.js` grouping | own layer (system, per checklist evidence) | yes — C2–C4 |
| Entry point that decides nothing | GET `/setup` wiring/folds/copy; GET `/months/:year_month` mark buttons | request spec (no view specs in repo) | yes — C1, C6–C15, C19, C20, C23, C24 |
| Instrumentation / pass-through | `BrazilianTaxId.normalize` persist (`organization.rb:137`) | consumer | yes — C5 stored digits |

## Swept existing

- `BrazilianTaxId.normalize` still assigns `accountant_tax_id` (`organization.rb:137`).
- `require_coordinator_organization` on `BaseDocumentExceptionsController` (`app/controllers/base_document_exceptions_controller.rb:2`).
- Migration defaults both offer columns `true` (`db/migrate/20261009120000_add_base_document_exception_offers_to_organizations.rb:3-4`).
- Rows marked n/a (concurrency, external deps, observability) have no code obligation.

## Faults injected

Scratch: `git worktree add /tmp/setup-polish-verify-r2 HEAD`. Real tree not mutated. Worktree removed after.

| Mutation | Location | Covering proof | Killed |
|---|---|---|---|
| `digits().slice(0, 14)` → `slice(0, 15)` | `app/javascript/controllers/tax_id_mask_controller.js` | C3 `cadastro tax_id drops a fifteenth digit` | **yes** — expected `11.222.333/0001-81`, got `11.222.333/0001-819` (`tax_id_mask_spec.rb:44`) |
| `tax-id-mask` wiring → `money-mask` | `app/views/setup/show.html.erb` | C1 | **yes** — expected `tax-id-mask`, got `money-mask` (`setup_spec.rb:651`) |
| bank Situação `Ativa` → `Aberta` | `app/views/setup/show.html.erb` | C9 | **yes** (`setup_spec.rb:734`) |
| `if @organization.bank_fee_exception_active?` → `if true` | `app/views/months/show.html.erb` | C19 | **yes** — `kind=bank_fee` input present (`months_spec.rb:1541`) |
| `offered` always `true` in `mark_base` | `app/models/payment.rb` | C21 model | **yes** — errors `[]` (`payment_spec.rb:66`) |

## Gate

`bin/rspec` (11 files, 42 `-e` names, `--format documentation`) — 42 passed, 0 failed, exit 0 at `1d37e07`.
