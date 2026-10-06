# Setup: extra kinds with justification

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/setup-extra-kinds-justification.md` marks screen `setup` binding through `.specs/features/visual-identity/design.md` (criterion 15).

Sources:

- `.tasks/setup-extra-kinds-justification.md` - criteria 1–15, door 1, sweep, Unresolved 1–2 stay open (write-once justification plus backfill `Isento de documento de suporte.`; heading `Tipos extras de exceção` with no intro under the h2). Nothing under Unresolved is settled while building
- https://github.com/gutors/ai-accounting-assistant/issues/84 - this cut: fixed types at the top of the setup list with code-pinned justification; new extra requires Justificativa; list shows name + justification; column on `extra_exception_kinds`; month marking out of recorte
- https://github.com/gutors/ai-accounting-assistant/issues/75 - umbrella: extra justification required; fixed types at the top with non-editable justification
- `.tasks/extra-exception-kinds.md` - catalog, uniqueness, deactivate, unused delete, base names not extras; criterion 14 (do not list the base names) is superseded on the screen by this task, not in persistence
- [ADR-0003](../docs/adr/0003-extra-exception-kinds.md) - extras are catalog rows, not enum values
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screen `setup`. Opened as a file in the repo. Section `setup` today still draws extras as `Doação` / Desativar / Excluir and `form: Nome  [Adicionar tipo extra]` with no fixed pair. C15 amends that section. Contador, archive, A1, and banks stay as opened
- `GLOSSARY.md` - Extra exception kind, Document exception
- [ADR-0001](../docs/adr/0001-rails-8-hotwire.md) - Rails 8 + Hotwire; no new runtime
- Open defaults in Unresolved 1–2 - PATCH does not change `justification`; existing rows backfill `Isento de documento de suporte.` before NOT NULL; no intro sentence under the extras h2

## Out of scope

- How the month page marks tarifa, honorário, or extra — #84 Fora deste recorte
- Showing justification on `/months/:year_month`, on a payment row, or in the summary spreadsheet
- `Pronto.` toast on extra-kind create, deactivate, or delete — #76 listed other setup saves, not this resource; `ExtraExceptionKindsController` still `redirect_to "/setup"`
- Keeping typed extra-kind fields on `422` — #85 is document insert and A1
- Renaming an extra exception kind, deactivating the two base kinds, or persisting them as ExtraExceptionKind — `.tasks/extra-exception-kinds.md` / ADR-0003
- Accountant login, Drive writes, Open Finance, SEFAZ, NF-e issuance
- Settling Unresolved 1–2

## Landing

Touches ExtraExceptionKind (`justification` column, `create_for`), `GET /setup` extras HTML (`setup/show`), `POST /extra_exception_kinds`, and `PATCH` that ignores `justification`. Reuses `BASE_NAMES` (justification strings sit next to them), unique `(organization_id, lower(name))`, deactivate / unused delete, `require_coordinator_organization`, and 422 re-render of `setup/show`. Fixed pair is view chrome, not catalog rows.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Extra justification is a required column on the catalog row | `ExtraExceptionKind` has `justification`, required, trimmed, not unique. Identity remains the case-insensitive name per organization (ADR-0003). The two base kinds are not ExtraExceptionKind rows; their justification strings live in code next to `BASE_NAMES`. Existing rows backfill `Isento de documento de suporte.` then NOT NULL (Unresolved 1). | Optional justification — #84 required on a new extra. A justification column on Payment — ADR-0003 already rejected extra text on Payment; this sentence is catalog, not per mark. Persisting tarifa/honorário as ExtraExceptionKind so they can share the column — #84 not persisted as extra; ADR-0003 base names stay distinct from the catalog. |

- Nothing else in this change is hard to reverse

## Screens (ui)

Opened `.specs/features/visual-identity/design.md` section `setup` as a file. Today's drawing still omits the fixed pair and justification; C15 amends it. Arrangement below is what C15 plus criteria 1–4, 6, 11, 13 require.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `setup` extras | h2 `Tipos extras de exceção`; `Tarifa bancária` + `Tarifa cobrada pelo banco; não há documento fiscal a anexar.`; `Honorário do contador` + `Honorário do contador neste fechamento; isento de documento de suporte.`; extras `li[data-row="extra-exception-kind"]` name + justification; column heading `Justificativa`; form `Nome` / `#extra_exception_kind_name` / `Justificativa` / `name="justification"` / `Adicionar tipo extra`; no `Nenhum tipo extra`; fixed names are not `li[data-row="extra-exception-kind"]`; fixed rows omit `Desativar` `Reativar` `Excluir`; extra row has no control that submits a new `name` or `justification` | extras `section` is the last of five setup sections; h2 then the list with no intro paragraph; column heading `Justificativa` above the rows; fixed pair first (tarifa then honorário) then extras by ascending name; each extra row is name + justification then existing active/delete actions; form sits after the list | spacing, colour, type weight on extras |

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
- `ExtraExceptionKind#create_for` / presence+trim of `justification` / reserved `BASE_NAMES` decide persist-or-not. Closest analogue: `spec/models/extra_exception_kind_spec.rb` + `spec/requests/extra_exception_kinds_spec.rb`
- `ExtraExceptionKindsController#update` stays pass-through for `active`; ignoring `justification` on PATCH is the HTTP contract (C12), not a new model writer
- Fixed-pair HTML is a view decision; this repo has no view specs — request specs on `GET /setup`
- System specs are not required: every named observation is HTML, status, or a file read a request/docs spec can settle

Cost: request examples for C1–C14 HTML/HTTP; model examples for create/trim/reject justification and reserved name with justification; file-read example for C15.

## Checks

Criteria 1–15 map to C1–C15. Unresolved 1–2 stay write-once plus that backfill string, and no intro under the extras h2.

### S1 - Fixed types at the top of the setup list · 5 files · 56 KB · ~14k

**C1** - Given a signed-in coordinator of the focused organization with zero ExtraExceptionKind rows, when `GET /setup` runs, then the status is `200`, the body includes the heading `Tipos extras de exceção`, then `Tarifa bancária` with `Tarifa cobrada pelo banco; não há documento fiscal a anexar.`, then `Honorário do contador` with `Honorário do contador neste fechamento; isento de documento de suporte.`, it does not include `Nenhum tipo extra`, and ExtraExceptionKind count on that organization is `0`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with zero extra exception kinds lists fixed Tarifa then Honorario"`

**C2** - Always, `Tarifa bancária` and `Honorário do contador` on `/setup` are not `li[data-row="extra-exception-kind"]`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup Tarifa and Honorario are not extra-exception-kind rows"`

**C3** - While those two names are on `/setup`, their rows do not include `Desativar`, `Reativar`, or `Excluir`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup fixed exception rows omit Desativar Reativar Excluir"`

**C4** - Given ExtraExceptionKind rows `Zeta` and `Alfa` on the focused organization, when `GET /setup` runs, then in the `Tipos extras de exceção` section the first occurrence of `Tarifa bancária` precedes `Honorário do contador`, which precedes `Alfa`, which precedes `Zeta`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup extras section order is Tarifa Honorario Alfa Zeta"`

**C5** - If a coordinator POSTs `/extra_exception_kinds` with `name` `Tarifa bancária` and a non-blank `justification`, then ExtraExceptionKind count stays `0`, the status is `422`, and `GET /setup` still includes exactly one `Tarifa bancária`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST Tarifa bancaria with justification returns 422"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects Tarifa bancaria with justification"`

### S2 - Extra kind justification · 8 files · 54 KB · ~14k

**C6** - When `GET /setup` runs, then `form[action="/extra_exception_kinds"]` includes `#extra_exception_kind_name` whose label is `Nome`, an input `name="justification"` whose label is `Justificativa`, and submit `Adicionar tipo extra`. The `Tipos extras de exceção` section includes the column heading `Justificativa`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup extra kind form has Nome Justificativa and Adicionar tipo extra"`

**C7** - When a coordinator POSTs `name` `Doação` and `justification` `Doação pontual sem nota.`, then the system persists one ExtraExceptionKind with those two values on the focused organization, responds `302` to `/setup`, and that extra-exception-kind row includes `Doação` and `Doação pontual sem nota.`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST /extra_exception_kinds persists Doacao with justification and redirects"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "create Doacao persists name and justification"`

**C8** - When a coordinator POSTs `name` `  Doação  ` and `justification` `  Doação pontual sem nota.  `, then the persisted name is `Doação` and the persisted justification is `Doação pontual sem nota.`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST /extra_exception_kinds persists trimmed Doacao and justification"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "create trims Doacao name and justification"`

**C9** - If a coordinator POSTs `name` `Doação` and `justification` blank, missing, or whitespace-only, then the system persists no ExtraExceptionKind and responds `422`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST blank justification returns 422"`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST missing justification returns 422"`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST whitespace justification returns 422"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects blank justification"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects missing justification"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects whitespace justification"`

**C10** - If a coordinator POSTs `justification` `Doação pontual sem nota.` and blank `name`, then the system persists no ExtraExceptionKind and responds `422`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST blank name with justification returns 422"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects blank name with justification"`

**C11** - When `/setup` lists extra exception kind `Doação`, then that `li[data-row="extra-exception-kind"]` includes its justification and does not include a control that submits a new `name` or `justification` for that kind
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup extra exception kind row shows justification and has no name or justification fields"`

**C12** - If a coordinator PATCHes `justification=Outro texto` on extra exception kind `Doação`, then the persisted justification remains `Doação pontual sem nota.` (Unresolved 1)
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "PATCH justification Outro texto leaves Doacao pontual"`

**C13** - When `/setup` lists deactivated extra exception kind `Doação`, then that row still includes `Doação pontual sem nota.`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup deactivated extra exception kind still includes justification"`

**C14** - If a coordinator POSTs `name` `Doação` and `justification` `Outro texto` while `Doação` already exists with `Doação pontual sem nota.`, then ExtraExceptionKind count stays `1`, the justification stays `Doação pontual sem nota.`, and the status is `422`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST duplicate Doacao with other justification returns 422"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects duplicate Doacao and keeps original justification"`

**C15** - `.specs/features/visual-identity/design.md` section `setup` lists `Tarifa bancária` and `Honorário do contador` with the two strings in criterion 1 at the top of `Tipos extras de exceção`, extra rows as name plus justification, the form as `Nome` / `Justificativa` / `Adicionar tipo extra`, and does not show `Nenhum tipo extra`
Proof: `bin/rspec spec/docs/setup_extra_kinds_justification_spec.rb -e "visual-identity setup extras list fixed kinds and justification"`

## Swept

- validation: C8, C9, C10, C14
- failure modes: C5, C9, C10, C14
- idempotency and retry: C14 - a second include of the same name does not create a second row or replace justification
- authorization: existing - coordinator-only extra-kind routes; submitter `404`; unauthenticated `302` `/login`
- concurrency and ordering: existing - unique index on `(organization_id, lower(name))` still serializes two concurrent creates of the same name; justification is not a second identity
- data lifecycle: C7, C12, C13, Unresolved 1 - justification is stored on the catalog row; deactivate keeps it; unused DELETE still removes the row; existing rows need a NOT NULL backfill
- external-dependency failure: n/a - no new remote
- state transitions: n/a - ExtraExceptionKind active/deactivated/delete is unchanged; justification is not a lifecycle
- observability: n/a - no operator metric or log line is required

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| reserved names refused as extras (2) | `Tarifa bancária` C5 · `Honorário do contador` existing `POST honorario do contador returns 422` (kept, with justification) | - |
| POST justification absence (3) | blank C9 · missing C9 · whitespace-only C9 | - |
| list order tokens (4) | `Tarifa bancária` then `Honorário do contador` then `Alfa` then `Zeta` C4 | - |
| ExtraExceptionKind create outcomes this cut names (6) | persist C7 · trim C8 · blank/missing/whitespace justification C9 · blank name C10 · duplicate keeps original justification C14 · reserved C5 | - |
| PATCH fields that must not rewrite identity (2) | `name` existing `PATCH name Outro leaves Doacao` · `justification` C12 | - |
| extras list row kinds (2) | fixed chrome C2, C3 · catalog `li[data-row="extra-exception-kind"]` C7, C11, C13 | - |
| designed screens this cut binds (1) | `setup` C1–C4, C6, C11, C13, C15 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `month`, `documents` — out of scope |
| `setup` extras visual (3 properties) | — | spacing, colour, type weight on extras |

- Claims naming a status code, route or response shape: C1, C5, C7, C9, C10, C12, C14 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~14k + S2 ~14k = ~28k token floor. Both slices share `setup/show.html.erb`, ExtraExceptionKind, and the opened design. All stay under 150k. No split. One batch.

- Where the boundary fell: one batch; C1–C15 closed on this branch after the product commit.
- What the user settled mid-build: none.
- What was abandoned: none yet.
