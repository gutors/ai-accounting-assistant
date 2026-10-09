# Setup: configuration polish

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/setup-configuration-polish.md` marks screens `setup` and `month` binding through `.specs/features/visual-identity/design.md` (criterion 28).

Sources:

- `.tasks/setup-configuration-polish.md` - criteria 1–28, door 1 (Stimulus tax-id mask plus two Organization booleans), sweep, Unresolved 1 stays open. Nothing under Unresolved is settled while building
- https://github.com/gutors/ai-accounting-assistant/issues/105 - **binding for this slice**: Contador tax-id mask; label color; bank and extra create folds; Situação Ativa/Inativa and Ativo/Inativo; base kinds deactivate per organization without ExtraExceptionKind; month hides inactive mark
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent umbrella; one tlc-plan child (#105); profile `ui`
- `docs/adr/0003-extra-exception-kinds.md` - bases are not ExtraExceptionKind; Payment enum unchanged; amend with the offer booleans
- `.tasks/setup-a1-certificate.md` - `<details>` closed until `422` `open`; copy this for bank and extra create
- `.tasks/setup-extra-kinds-justification.md` criterion 3 - superseded for Desativar/Ativar only; `Excluir` stays absent on base rows
- `.tasks/extra-exception-kinds.md` criteria 15–17, 29–30 - deactivated extra copy and month hide; this cut changes that copy to `Inativo`/`Ativar` and extends hide to base kinds
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screens `setup` and `month`. Opened as a file in the repo. Section `setup` today still draws Contador labels as `font-medium`, `#tax_id` without a live mask, bank create as an always-open form, inactive bank Situação only (`Inativa`), extras create always open, extra inactive copy `Desativado`, and base rows without Situação or Desativar/Ativar. Section `month` still always draws `Marcar tarifa` / `Marcar honorário`. C28 amends those two sections
- `app/views/setup/show.html.erb`, `app/javascript/controllers/money_mask_controller.js`, `BrazilianTaxId` - wiring and persist patterns this cut copies
- `GLOSSARY.md` - Extra exception kind, Document exception; this cut adds **base document-exception offer**
- [ADR-0001](../docs/adr/0001-rails-8-hotwire.md) - Rails 8 + Hotwire; no new runtime
- Open default in Unresolved 1 - hide `Marcar honorário` / `kind=accountant_fee` (C20, C22). Leave suggestion copy as existing #37

## Out of scope

- Renaming an ExtraExceptionKind, copying kinds across organizations, or persisting Tarifa/Honorário as ExtraExceptionKind rows — ADR-0003; C27
- Changing `Excluir` copy to `Remover` on unused extras
- Renaming bank `Reativar` to `Ativar`
- Toast on extra-kind create / PATCH / DELETE — existing extra-kinds task left `redirect_to`
- Keeping typed extra-kind fields on create `422` — #85 is document insert and A1
- SEFAZ titular CNPJ mask, package-archive chrome, A1 install fold
- Close-for-send, summary spreadsheet, Match, exception suggestion catalog (#37)
- Changing closed-month refusal to mark or unmark — existing `Mês fechado`
- Accountant login, Drive, Open Finance, NF-e issuance, submitter `/setup`
- Settling Unresolved 1 (suggestion copy while honorário is hidden)

## Landing

Touches Contador `#tax_id` Stimulus mask, Contador label classes, bank and extra create `<details>`, bank/extra Situação copy, two Organization booleans, `PATCH /base_document_exceptions/:kind`, `Payment#mark_base`, month Resolver mark buttons, ADR-0003, and design.md `setup`/`month`. Reuses `BrazilianTaxId.normalize`, `money-mask` wiring, A1 `<details>` open-on-422, `require_coordinator_organization`, `redirect_success` `Pronto.`, ExtraExceptionKind catalog (not for bases), and `UNKNOWN_KIND`.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Base offer is two booleans on `organizations` | `bank_fee_exception_active` and `accountant_fee_exception_active`, `boolean`, `null: false`, default `true`. `PATCH /base_document_exceptions/:kind` with `:kind` ∈ {`bank_fee`,`accountant_fee`} and `active`. Amend ADR-0003: bases stay the Payment enum, not catalog rows; an organization may hide the mark without deleting historical `document_exception_kind` | Persist Tarifa/Honorário as ExtraExceptionKind so they share `active` — ADR-0003 and #84 already rejected that identity. A text/json array of inactive keys — two closed enum members do not need a list type this app does not use. Setup-only chrome with month still offering the mark — refused in planning (org_override) |
| Tax-id live mask is Stimulus | Eager-loaded controller identifier `tax-id-mask` on `#tax_id`, same wiring shape as `money-mask` (`inputmode` `numeric`, `typed` on `input`). Display: digits 1–11 CPF grouping `000.000.000-00`; digits 12–14 CNPJ grouping `00.000.000/0000-00`; extra digits dropped | `type=tel` without a controller — does not insert punctuation. Server-only format on GET — does not format as the person types (the Documentos pattern this slice copies) |

- Nothing else in this change is hard to reverse

## Screens (ui)

Opened `.specs/features/visual-identity/design.md` sections `setup` and `month` as files. Today's drawings omit the live mask, receding Contador labels, bank/extra create folds, Situação `Ativa`/`Ativo` on offered rows, Desativar/Ativar on base rows, and hiding inactive base marks on month. C28 amends those sections. Arrangement below is what C28 plus criteria 1–27 require.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `setup` | Contador `#tax_id` in `form[action="/accountant"]` with `tax-id-mask`; five Contador labels; `p#presentation_name` and sibling values; Contas bancárias `Adicionar conta` summary; bank `Ativa`/`Inativa`; extras `Adicionar tipo extra` summary; every exception-kind row `Ativo`/`Inativo`; base `Desativar`/`Ativar` and no `Excluir` | Contador labels recede (`text-ink-soft`) against `font-medium` values; bank create form nested in closed `<details>` (open on edit or bank `422`); extra create form nested in closed `<details>` (open on create `422`, not used DELETE `422`); `input#certificate` outside the bank details; base pair still first, not `li[data-row="extra-exception-kind"]` | spacing, colour, type weight on Contador labels (token class is checked; computed colour is not), bank/extra folds, Situação |
| `month` | Resolver omits `Marcar tarifa` / `kind=bank_fee` when bank-fee offer is inactive; omits `Marcar honorário` / `kind=accountant_fee` when accountant-fee offer is inactive; already-marked `Tarifa bancária` plus `Desmarcar exceção` stay | remaining mark buttons stay in the Resolver panel; no new layout region | spacing, colour, type weight on Resolver |

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at its own layer **and** one request spec at HTTP | one asserted case per enumerated member at its own layer; status and who may call at the boundary | follow |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` names the level and the sampling rule: a decision is proven at its own layer, one asserted case per enumerated member; HTTP also gets a request spec
- `Organization#update_accountant` + `BrazilianTaxId.normalize` already persist digits; the mask is display. Closest analogue: `spec/system/money_mask_spec.rb` + accountant request specs
- `Payment#mark_base` gains inactive-offer branches. Closest analogue: `spec/models/payment_spec.rb` extra inactive + `spec/requests/document_exceptions_spec.rb`
- New `PATCH /base_document_exceptions/:kind` is an HTTP contract; Organization persist of the two booleans is the decision table
- Stimulus `tax-id-mask` is a browser-only formatter; typing claims need a system spec (repo already uses Cuprite for `money-mask`)
- Fixed-pair HTML and folds are view decisions; this repo has no view specs — request specs on `GET /setup`

Cost: system examples for C2–C4; request examples for C1, C5–C26, C27 HTTP; model examples for inactive `mark_base` and Organization boolean persist; file-read example for C28.

These rows are the bar I build under — approving the checklist is enough for that. Writing them into `.cursor/rules/rails.mdc` needs an explicit yes, and it would land as its own commit before the build. Without one I build under them and leave the file alone.

## Checks

Criteria 1–28 map to C1–C28. Unresolved 1 stays hide `Marcar honorário` / `kind=accountant_fee` and leave suggestion copy as #37.

### S1 - CPF/CNPJ mask on Contador `#tax_id` · 8 files · 64 KB · ~16k

**C1** - Given a signed-in coordinator of the focused organization with no `accountant_presentation_name`, when `GET /setup` runs, then `#tax_id` is a descendant of `form[action="/accountant"]`, is not `readonly`, has `inputmode` `numeric`, and has `data-controller` `tax-id-mask` with `data-action` `input->tax-id-mask#typed`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup cadastro tax_id has tax-id-mask wiring"`

**C2** - Given that cadastro `#tax_id` is empty and the page is interactive, when the person types digits `11222333000` in order, then after the eleventh digit the field value is `112.223.330-00`. When they then type `1`, then `8`, then `1`, then the value is `11.222.333/0001-8` after the thirteenth digit and `11.222.333/0001-81` after the fourteenth
Proof: `bin/rspec spec/system/tax_id_mask_spec.rb -e "cadastro tax_id types CPF then CNPJ grouping"`

**C3** - Given `#tax_id` already shows `11.222.333/0001-81`, when the person types one more digit, then the value remains `11.222.333/0001-81`
Proof: `bin/rspec spec/system/tax_id_mask_spec.rb -e "cadastro tax_id drops a fifteenth digit"`

**C4** - Given the focused organization has `accountant_presentation_name` `Ana Contábil` and `accountant_tax_id` `11222333000181`, when `GET /setup?edit=accountant` runs and the page is interactive, then `#tax_id` value is `11.222.333/0001-81` with no extra digits typed. Given instead `accountant_tax_id` `39053344705`, then that value is `390.533.447-05`
Proof: `bin/rspec spec/system/tax_id_mask_spec.rb -e "edit accountant prefills formatted CNPJ"`
Proof: `bin/rspec spec/system/tax_id_mask_spec.rb -e "edit accountant prefills formatted CPF"`

**C5** - Given that writable form, when `PATCH /accountant` runs with `presentation_name` `Ana Contábil`, `tax_id` `11.222.333/0001-81`, `legal_name` `Contábil LTDA`, and the other accountant fields valid, then the response is `302` to `/setup` and stored `accountant_tax_id` is `11222333000181` (digits only). Always, `BrazilianTaxId.normalize` remains the persist path; the mask does not write punctuation into `organizations.accountant_tax_id`
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH accountant with masked CNPJ stores digits only"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "update_accountant with punctuated CNPJ stores digits"`

### S2 - Contador label color · 2 files · 46 KB · ~12k

**C6** - Given leitura (`accountant_presentation_name` present, not `?edit=accountant`), when `GET /setup` runs, then in the Contador section (from heading `Contador` through heading `Armazenamento do pacote mensal`) each of `label[for=presentation_name]`, `label[for=tax_id]`, `label[for=legal_name]`, `label[for=pix_key]`, and `label[for=destination_email]` includes class `text-ink-soft` and does not include class `font-medium`, and each of `p#presentation_name`, `p#tax_id`, `p#legal_name`, `p#pix_key`, and `p#destination_email` includes class `font-medium`. The `h2` whose text is `Contador` does not include class `text-ink-soft`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup leitura Contador labels are text-ink-soft"`

**C7** - Given cadastro or `GET /setup?edit=accountant`, when that GET runs, then those five labels still include `text-ink-soft` and still omit `font-medium`. Labels in Armazenamento do pacote mensal, Certificado, Contas bancárias, and Tipos extras de exceção are unchanged by this slice
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup cadastro Contador labels are text-ink-soft and other sections keep font-medium"`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup edit accountant Contador labels are text-ink-soft"`

### S3 - Bank create fold and Situação Ativa/Inativa · 4 files · 59 KB · ~15k

**C8** - Given a signed-in coordinator of the focused organization, when `GET /setup` runs with no `?edit=bank_account`, then the Contas bancárias section form (the one form in that section that contains `#name`, `#compe`, and `#coordinates`) is a descendant of a `<details>` that does not have the `open` attribute, whose `<summary>` text is `Adicionar conta`. That form’s submit is `Adicionar conta` when not editing. `input#certificate` is not a descendant of this `<details>`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup bank add form sits in closed Adicionar conta details"`

**C9** - Given that organization has active Banco do Brasil account `Conta Principal` and inactive Santander account `Parada`, when `GET /setup` runs, then the `Conta Principal` `li[data-row="bank-account"]` includes `Ativa` and does not include `Inativa`, and the `Parada` row includes `Inativa` and does not include `Ativa`. `Desativar` remains on the active row and `Reativar` remains on the inactive row
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup bank rows show Ativa and Inativa"`

**C10** - Given `GET /setup?edit=bank_account&bank_account_id={id}` for `Conta Principal`, then that Contas bancárias `<details>` has the `open` attribute, the form `action` is `/bank_accounts/{id}` with method PATCH, and submit is `Salvar conta`. The `<summary>` text is still `Adicionar conta`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup edit bank opens Adicionar conta details as PATCH"`

**C11** - If `POST /bank_accounts` runs with blank `name` (other fields present), then the status is `422`, no BankAccount is persisted, and that Contas bancárias `<details>` has the `open` attribute. When a valid `POST /bank_accounts` then `302`s, the following `GET /setup` matches criterion 8 (details not `open`)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST blank name opens Adicionar conta details on 422"`
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST valid bank account then GET setup keeps Adicionar conta details closed"`

### S4 - Extra-kind create fold and Situação Ativo/Inativo · 4 files · 61 KB · ~15k

**C12** - When `GET /setup` runs with no extra-kind create `422`, then `form[action="/extra_exception_kinds"]` is a descendant of a `<details>` that does not have the `open` attribute, whose `<summary>` text is `Adicionar tipo extra`, and that form still includes `#extra_exception_kind_name`, `name="justification"`, and submit `Adicionar tipo extra`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup extra kind form sits in closed Adicionar tipo extra details"`

**C13** - Given ExtraExceptionKind `Doação` is active and ExtraExceptionKind `Folha` is inactive and unused, when `GET /setup` runs, then the `Doação` `li[data-row="extra-exception-kind"]` includes `Ativo` and `Desativar` and does not include `Inativo`, `Desativado`, or `Reativar`, and the `Folha` row includes `Inativo` and `Ativar` and does not include `Ativo`, `Desativado`, or `Reativar`. Unused `Folha` still includes `Excluir`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup extra kind rows show Ativo Inativo Desativar Ativar"`

**C14** - If `POST /extra_exception_kinds` runs with blank `name` and a non-blank `justification`, then the status is `422`, ExtraExceptionKind count is unchanged, and that extra-kind `<details>` has the `open` attribute. If `DELETE /extra_exception_kinds/{id}` runs for a kind a Payment references, then the status is `422`, the row remains, and that extra-kind `<details>` does not have the `open` attribute
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST blank name with justification opens Adicionar tipo extra details"`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "DELETE used Doacao 422 leaves extra kind details closed"`

### S5 - Base kinds: Situação and per-organization offer · 14 files · 176 KB · ~44k

**C15** - Given ExtraExceptionKind count `0` on the focused organization and both base offers active (the migration default), when `GET /setup` runs, then each `li[data-row="base-document-exception"]` for `Tarifa bancária` and `Honorário do contador` includes `Ativo` and `Desativar` and does not include `Excluir`, `Ativar`, or `Inativo`. Those two names are still not `li[data-row="extra-exception-kind"]`. ExtraExceptionKind count stays `0`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup base exception rows show Ativo and Desativar"`

**C16** - When a coordinator PATCHes `/base_document_exceptions/bank_fee` with `active` `false`, then the focused organization’s `bank_fee_exception_active` is `false`, `accountant_fee_exception_active` stays `true`, the response is `302` to `/setup`, ExtraExceptionKind count is unchanged, and the following `GET /setup` shows the `Tarifa bancária` base row with `Inativo` and `Ativar` and without `Desativar` or `Excluir`. A second identical PATCH still leaves `bank_fee_exception_active` `false` and still `302`s. The following `GET /setup` has `[data-toast-kind="success"]` text `Pronto.` after the first PATCH
Proof: `bin/rspec spec/requests/base_document_exceptions_spec.rb -e "PATCH bank_fee inactive 302s Inativo and toasts Pronto"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "apply_base_document_exception bank_fee false leaves accountant_fee true"`

**C17** - When a coordinator PATCHes `/base_document_exceptions/accountant_fee` with `active` `false`, then `accountant_fee_exception_active` is `false`, `bank_fee_exception_active` is unchanged, ExtraExceptionKind count is unchanged, and the `Honorário do contador` base row matches the Situação/actions shape in criterion 16 (`Inativo`, `Ativar`, no `Excluir`)
Proof: `bin/rspec spec/requests/base_document_exceptions_spec.rb -e "PATCH accountant_fee inactive 302s Honorario Inativo"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "apply_base_document_exception accountant_fee false leaves bank_fee true"`

**C18** - When a coordinator PATCHes `/base_document_exceptions/bank_fee` with `active` `true` after criterion 16, then `bank_fee_exception_active` is `true` and the following `GET /setup` shows that base row with `Ativo` and `Desativar` as in criterion 15
Proof: `bin/rspec spec/requests/base_document_exceptions_spec.rb -e "PATCH bank_fee active after inactive restores Ativo Desativar"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "apply_base_document_exception bank_fee true after false"`

**C19** - Given `bank_fee_exception_active` `false` and an open Month `2026-05` with a missing-document Payment, when `GET /months/2026-05` runs, then that payment’s Resolver panel does not include a control that submits `kind` `bank_fee` and does not include `Marcar tarifa`, and it still includes `Marcar honorário` while `accountant_fee_exception_active` is `true`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month omits Marcar tarifa when bank_fee offer inactive"`

**C20** - Given `accountant_fee_exception_active` `false` and that same open month, when `GET /months/2026-05` runs, then that panel does not include a control that submits `kind` `accountant_fee` and does not include `Marcar honorário`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month omits Marcar honorario when accountant_fee offer inactive"`

**C21** - If a coordinator POSTs `/months/2026-05/payments/{id}/document_exception` with `kind` `bank_fee` while `bank_fee_exception_active` is `false`, then `document_exception_kind` stays nil, the status is `422`, and the body includes `Informe um tipo de exceção permitido`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST bank_fee while offer inactive returns 422"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "rejects bank_fee when organization offer is inactive"`

**C22** - If a coordinator POSTs that path with `kind` `accountant_fee` while `accountant_fee_exception_active` is `false`, then `document_exception_kind` stays nil, the status is `422`, and the body includes `Informe um tipo de exceção permitido`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST accountant_fee while offer inactive returns 422"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "rejects accountant_fee when organization offer is inactive"`

**C23** - Given a Payment already marked `bank_fee`, when `bank_fee_exception_active` later becomes `false` and `GET /months/2026-05` runs, then that payment’s row still includes `Tarifa bancária`, does not include `Documento faltante`, and still includes `Desmarcar exceção` while the month is open. Spreadsheet copy and close-for-send for that mark stay existing
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month keeps Tarifa bancaria after bank_fee offer hidden"`

**C24** - Given organization B still has both base offers active, while focus is organization A with `bank_fee_exception_active` `false`, when a coordinator of B `GET`s B’s open month, then that month still includes `Marcar tarifa`. A’s flag is unchanged
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET B month still Marcar tarifa while A bank_fee offer inactive"`

**C25** - If an unauthenticated request PATCHes `/base_document_exceptions/bank_fee`, then no Organization column changes and the response is `302` to `/login`. If a submitter of the focused organization sends that PATCH, then the flags are unchanged and the response is `404`
Proof: `bin/rspec spec/requests/base_document_exceptions_spec.rb -e "unauthenticated PATCH bank_fee 302s to login"`
Proof: `bin/rspec spec/requests/base_document_exceptions_spec.rb -e "submitter PATCH bank_fee returns 404"`

**C26** - If a coordinator PATCHes `/base_document_exceptions/not_a_kind` with `active` `false`, then both flags stay unchanged and the response is `404`
Proof: `bin/rspec spec/requests/base_document_exceptions_spec.rb -e "PATCH not_a_kind returns 404"`

**C27** - Always, `Payment.document_exception_kinds` keys and values remain exactly `bank_fee` and `accountant_fee`. Always, a POST of `name` `Tarifa bancária` or `Honorário do contador` to `/extra_exception_kinds` still persists no ExtraExceptionKind and responds `422`. Deactivating a base offer does not insert an ExtraExceptionKind row
Proof: `bin/rspec spec/models/payment_spec.rb -e "document_exception_kind enum members are bank_fee and accountant_fee"`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST Tarifa bancaria with justification returns 422"`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST honorario do contador returns 422"`
Proof: `bin/rspec spec/requests/base_document_exceptions_spec.rb -e "PATCH bank_fee inactive inserts no ExtraExceptionKind"`

**C28** - `.specs/features/visual-identity/design.md` section `setup` — Contador labels are `text-ink-soft` against `font-medium` values; `#tax_id` is masked as in criteria 1–4; Contas bancárias Situação is `Ativa` or `Inativa`; the add/edit bank form sits in `<details>` whose `<summary>` is `Adicionar conta` (`open` on edit or bank `422`); extra-kind create sits in `<details>` whose `<summary>` is `Adicionar tipo extra`; every exception-kind row including the two base names shows `Ativo` or `Inativo`; base rows have Desativar/Ativar and no Excluir. Section `month` — `Marcar tarifa` / `Marcar honorário` are absent from Resolver when that organization’s matching offer is inactive
Proof: `bin/rspec spec/docs/setup_configuration_polish_spec.rb -e "visual-identity setup and month record configuration polish"`

## Swept

- validation: C2, C3, C5 — mask length 14 and digit-only display; persist still `BrazilianTaxId.normalize` / accountant_shape; C21, C22, C26, C27 — inactive or unknown kind
- failure modes: C11, C14, C21, C22, C26 — `422` or `404` as named; bank/extra create fold `open` only for that resource’s `422`
- idempotency and retry: C16 — a second PATCH `active` `false` stays false and `302`s; C5 — a second identical accountant PATCH still stores digits
- authorization: C25 and existing `require_coordinator_organization` on setup, bank, extra, and document-exception routes
- concurrency and ordering: n/a — two overlapping PATCHes of the same boolean leave the last write; no new unique index. Extra-kind unique name index is existing
- data lifecycle: C15 — existing organizations receive `true`/`true` defaults; no backfill of ExtraExceptionKind rows; C23 — deactivating an offer does not clear Payment marks; unused extra DELETE is existing
- external-dependency failure: n/a — no Drive, SMTP, or SEFAZ call
- state transitions: C16, C17, C18, C21, C22, C23
- observability: n/a — the source names no log, metric, or trace; the person sees Situação, the fold, the month mark buttons, and existing `Pronto.` on the new PATCH (C16)

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| tax-id grouping by digit count (4) | 11 CPF C2 · 13 CNPJ C2 · 14 CNPJ C2 · 15 dropped C3 | - |
| prefilled tax-id shapes (2) | CNPJ C4 · CPF C4 | - |
| Contador label surfaces (3) | leitura C6 · cadastro C7 · edit C7 | - |
| bank details open/closed (3) | closed GET C8 · open edit C10 · open 422 C11 · closed after valid POST C11 | - |
| bank Situação (2) | `Ativa` C9 · `Inativa` C9 | - |
| extra details open/closed (3) | closed GET C12 · open create 422 C14 · closed used DELETE 422 C14 | - |
| extra Situação/actions (2) | active `Ativo`/`Desativar` C13 · inactive unused `Inativo`/`Ativar`/`Excluir` C13 | - |
| base offer kinds (2) | `bank_fee` C16, C18, C19, C21 · `accountant_fee` C17, C20, C22 | - |
| base offer states on setup (2) | offered `Ativo`/`Desativar` C15, C18 · hidden `Inativo`/`Ativar` C16, C17 | - |
| `PATCH /base_document_exceptions/:kind` callers (3) | coordinator C16 · unauthenticated C25 · submitter C25 | - |
| unknown kind token (1) | `not_a_kind` C26 | - |
| reserved extra names still refused (2) | `Tarifa bancária` C27 · `Honorário do contador` C27 | - |
| `Payment.document_exception_kinds` members (2) | `bank_fee` C27 · `accountant_fee` C27 | - |
| designed screens this cut binds (2) | `setup` C1, C6–C13, C15–C18, C28 · `month` C19, C20, C23, C24, C28 | - |
| visual-identity screens this cut does not bind (4) | — | `login`, `denied`, `home`, `documents` — out of scope |
| `setup` visual (3 properties) | — | spacing, colour, type weight on Contador labels, bank/extra folds, Situação |
| `month` visual (3 properties) | — | spacing, colour, type weight on Resolver |

- Claims naming a status code, route or response shape: C1, C5, C8, C10, C11, C12, C14, C15, C16, C17, C18, C19, C20, C21, C22, C23, C24, C25, C26, C27 — each has a request-spec or system-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~16k + S2 ~12k + S3 ~15k + S4 ~15k + S5 ~44k = ~102k token floor. S1–S4 share `setup/show.html.erb`; S5 enters Payment, month, and the two Organization booleans but the running total stays under 150k. No split. One batch.

- Where the boundary fell: one batch; C1–C28 closed on `5d7ff42` after checklist `88debd5`.
- What the user settled mid-build: none.
- What was abandoned: asserting month mark copy via `details.text` — submit values live on `input[type=submit][value]`, not in element text.
