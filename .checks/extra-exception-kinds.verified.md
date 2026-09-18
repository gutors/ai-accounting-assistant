# Extra exception kinds Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: c6ee126..400764e
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

No source marked binding. Checklist line: "No design source for the screens." Step 1 (`ui`) did not run. Profile floor is `standard` (project `AGENTS.md`); the checklist names no binding design source, so `ui` was not raised.

## Checks

Batched proof run at `400764e` (one invocation, documentation formatter): `bin/rspec spec/requests/setup_spec.rb spec/requests/extra_exception_kinds_spec.rb spec/models/extra_exception_kind_spec.rb spec/requests/document_exceptions_spec.rb spec/models/payment_spec.rb spec/requests/months_spec.rb spec/models/month_spec.rb spec/models/summary_spreadsheet_spec.rb spec/requests/matches_spec.rb spec/models/match_spec.rb` — exit 0, 211 examples, 0 failures. Every named proof below appeared individually as passed.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | `/setup` empty extras is 200 with heading and `Nenhum tipo extra` | exit 0 | `spec/requests/setup_spec.rb:174` `have_http_status(:ok)`; `:175` `include("Tipos extras de exceção")`; `:176` `include("Nenhum tipo extra")` | PASS |
| C2 | POST `Doação` persists active kind, 302 to `/setup`, page includes `Doação` | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:10` `:found`; `:11` `redirect_to("/setup")`; `:13-14` `be_active` / `eq("Doação")`; `:17` `include("Doação")`. Model `spec/models/extra_exception_kind_spec.rb:11-14` persisted/active/`Doação`/org | PASS |
| C3 | trimmed name `Doação` | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:26` `eq("Doação")`. Model `spec/models/extra_exception_kind_spec.rb:21` `eq("Doação")` | PASS |
| C4 | same name on A leaves B in place | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:38-39` both orgs `count).to eq(1)`. Model `spec/models/extra_exception_kind_spec.rb:30-32` persisted and both counts `eq(1)` | PASS |
| C5 | duplicate `Doação` persists none, 422 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:49` `:unprocessable_content`; `:50` `count).to eq(1)`. Model `spec/models/extra_exception_kind_spec.rb:40-41` `not_to be_persisted` / count 1 | PASS |
| C6 | `doação` vs `Doação` persists none, 422 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:60` `:unprocessable_content`; `:61` `count).to eq(1)`. Model `spec/models/extra_exception_kind_spec.rb:49-50` | PASS |
| C7 | `Tarifa bancária` persists none, 422 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:70-71` `:unprocessable_content` / count 0. Model `spec/models/extra_exception_kind_spec.rb:56-57` | PASS |
| C8 | `honorário do contador` persists none, 422 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:80-81`. Model `spec/models/extra_exception_kind_spec.rb:63-64` | PASS |
| C9 | blank name persists none, 422 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:90-91`. Model `spec/models/extra_exception_kind_spec.rb:70-71` | PASS |
| C10 | unauthenticated POST persists none, 302 `/login` | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:97` `not_to change(...:count)`; `:99` `:found`; `:100` `redirect_to("/login")` | PASS |
| C11 | `Alfa` before `Zeta` on `/setup` | exit 0 | `spec/requests/setup_spec.rb:187` `index("Alfa")).to be < ...index("Zeta")` | PASS |
| C12 | listed kind has no control submitting a new name | exit 0 | `spec/requests/setup_spec.rb:198-199` row present / `not_to include('name="name"')` | PASS |
| C13 | PATCH `name=Outro` leaves `Doação` | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:110` `eq("Doação")` | PASS |
| C14 | `/setup` extras list omits base names | exit 0 | `spec/requests/setup_spec.rb:209-210` extras section `not_to include` `Tarifa bancária` / `Honorário do contador` | PASS |
| C15 | PATCH inactive keeps row, 302 `/setup`, page has `Doação` and `Desativado` | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:120-126` `:found` / `redirect_to("/setup")` / `not_to be_active` / include both strings. Model `spec/models/extra_exception_kind_spec.rb:78-79` | PASS |
| C16 | PATCH active: `/setup` has `Doação`, row omits `Desativado` | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:139-140` row `include("Doação")` / `not_to include("Desativado")`. Model `spec/models/extra_exception_kind_spec.rb:87` `be_active` | PASS |
| C17 | active row `Desativar`; deactivated `Reativar` | exit 0 | `spec/requests/setup_spec.rb:222-223` | PASS |
| C18 | unused `Folha` includes `Excluir` | exit 0 | `spec/requests/setup_spec.rb:233` `include("Excluir")` | PASS |
| C19 | every kind referenced: page has no `Excluir` | exit 0 | `spec/requests/setup_spec.rb:246` `not_to include("Excluir")` | PASS |
| C20 | DELETE unused `Folha` gone, 302 `/setup`, page omits `Folha` | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:150-155`. Model `spec/models/extra_exception_kind_spec.rb:93-94` | PASS |
| C21 | DELETE used `Doação` remains, 422 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:168-169` `:unprocessable_content` / `find(kind.id)).to eq(kind)`. Model `spec/models/extra_exception_kind_spec.rb:103-105` | PASS |
| C22 | POST `Doação` while deactivated exists: no extra row, stays deactivated, 422 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:180-182`. Model `spec/models/extra_exception_kind_spec.rb:114-116` | PASS |
| C23 | DELETE other org's kind remains, 404 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:193-194` `:not_found` / row still found | PASS |
| C24 | PATCH other org's kind unchanged, 404 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:205-206` `:not_found` / `be_active` | PASS |
| C25 | POST extra `Doação` on missing-document payment: mark persisted, enum nil, 302 `/months/2026-05`, row `Doação` not `Documento faltante` | exit 0 | `spec/requests/document_exceptions_spec.rb:174-181`. Model `spec/models/payment_spec.rb:125-127` extra id / enum nil / `not_to be_missing_document` | PASS |
| C26 | enum keys and values exactly `bank_fee` and `accountant_fee` | exit 0 | `spec/models/payment_spec.rb:83-84` `contain_exactly("bank_fee", "accountant_fee")` on keys and values | PASS |
| C27 | DELETE extra mark: FK nil, 302, row `Documento faltante` not `Doação` | exit 0 | `spec/requests/document_exceptions_spec.rb:192-198`. Model `spec/models/payment_spec.rb:137-138` | PASS |
| C28 | open month offers `Doação` as mark choice on missing-document payment | exit 0 | `spec/requests/months_spec.rb:308-312` include `Doação` / `name="extra_exception_kind_id"` / that id / `Documento faltante`; payment `be_missing_document` | PASS |
| C29 | deactivated `Doação` not offered; marked payment still shows `Doação` not `Documento faltante` | exit 0 | `spec/requests/months_spec.rb:327` `not_to include('name="extra_exception_kind_id"')`; `:330-331` status include `Doação` / not `Documento faltante` | PASS |
| C30 | POST deactivated extra id: no mark, 422 `Informe um tipo de exceção permitido` | exit 0 | `spec/requests/document_exceptions_spec.rb:209-211`. Model `spec/models/payment_spec.rb:148-149` | PASS |
| C31 | POST `kind=doacao` no extra id: no mark, 422 that message | exit 0 | `spec/requests/document_exceptions_spec.rb:57-59`. Model `spec/models/payment_spec.rb:65-66` | PASS |
| C32 | POST `kind=bank_fee` and extra id: no mark, 422 that message | exit 0 | `spec/requests/document_exceptions_spec.rb:222-225`. Model `spec/models/payment_spec.rb:158-160` | PASS |
| C33 | POST other org extra id: no mark, 404 | exit 0 | `spec/requests/document_exceptions_spec.rb:236-237` `:not_found` / extra id nil | PASS |
| C34 | POST extra on matched payment: Match stays, no extra mark, 422 `Desfaça o casamento...` | exit 0 | `spec/requests/document_exceptions_spec.rb:251-254`. Model `spec/models/payment_spec.rb:172-174` | PASS |
| C35 | POST `bank_fee` replaces extra: enum `bank_fee`, extra nil, row `Tarifa bancária` not `Doação` | exit 0 | `spec/requests/document_exceptions_spec.rb:265-269`. Model `spec/models/payment_spec.rb:184-185` | PASS |
| C36 | format-1 Match on extra payment: Match persists, extra nil, row `Casado` not `Doação` | exit 0 | `spec/requests/matches_spec.rb:283-287`. Model `spec/models/match_spec.rb:221-223` | PASS |
| C37 | every payment extra-excepted: GET omits `Documento faltante` | exit 0 | `spec/requests/months_spec.rb:344` `not_to include("Documento faltante")` | PASS |
| C38 | extra-marked payment: `close_for_send` does not add `Há documento faltante` | exit 0 | `spec/models/month_spec.rb:94` `not_to include("Há documento faltante")` | PASS |
| C39 | extra `Doação` expense Exceção cell is `Doação` | exit 0 | `spec/models/summary_spreadsheet_spec.rb:176` `eq("Doação")` | PASS |
| C40 | focus A omits B-only extra name on `/setup` and `/months/2026-05` | exit 0 | `spec/requests/setup_spec.rb:258` `not_to include("Só B Extra")`. `spec/requests/months_spec.rb:358` same | PASS |
| C41 | catalog POST while month closed still persists, 302 `/setup` | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:217-219` `:found` / `redirect_to("/setup")` / kind present | PASS |
| C42 | POST extra mark while closed: no mark, 422 `Mês fechado` | exit 0 | `spec/requests/document_exceptions_spec.rb:280-282`. Model `spec/models/payment_spec.rb:195-196` | PASS |
| C43 | DELETE extra mark while closed: mark remains, 422 `Mês fechado` | exit 0 | `spec/requests/document_exceptions_spec.rb:294-296`. Model `spec/models/payment_spec.rb:207-208` | PASS |
| C44 | closed month, deactivated `Doação` on payment: shows `Doação`, omits `Documento faltante` and `Desmarcar exceção` | exit 0 | `spec/requests/months_spec.rb:373-375` | PASS |
| C45 | concurrent POST same name: exactly one row | exit 0 | `spec/models/extra_exception_kind_spec.rb:132` `count).to eq(1)` | PASS |
| C46 | concurrent unused destroy and mark: kind+mark or neither; never orphan FK | exit 0 | `spec/models/extra_exception_kind_spec.rb:165` `remaining.present?).to eq(marked_id.present?)`; `:166` `find_by(id: marked_id)).to be_present if marked_id` | PASS |
| C47 | submitter POST catalog: none persisted, 404 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:227-231` `not_to change` / `:not_found` | PASS |
| C48 | submitter PATCH: unchanged, 404 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:242-243` `:not_found` / `be_active` | PASS |
| C49 | submitter DELETE: row remains, 404 | exit 0 | `spec/requests/extra_exception_kinds_spec.rb:254-255` `:not_found` / `find(kind.id)).to eq(kind)` | PASS |
| C50 | submitter POST extra mark: no mark, 404 | exit 0 | `spec/requests/document_exceptions_spec.rb:308-309` `:not_found` / extra id nil | PASS |

## Coverage (recomputed)

Members taken from `ExtraExceptionKind::BASE_NAMES`, `validates :name`, `Payment.document_exception_kinds`, `Payment#mark_document_exception` / `missing_document?`, routes, and Landing enumerations — not from the author's table.

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| ExtraExceptionKind include rejects (5) | duplicate C5 · case-insensitive C6 · `Tarifa bancária` C7 · `honorário do contador` C8 · blank C9 | - |
| ExtraExceptionKind name uniqueness (4) | same org exact C5 · same org case C6 · other org allowed C4 · deactivated occupies C22 | - |
| reserved base names (2) | `Tarifa bancária` C7 · `Honorário do contador` (case fold) C8 | - |
| ExtraExceptionKind lifecycle (5) | include active C2 · deactivate C15 · reactivate C16 · unused DELETE C20 · used DELETE refuse C21 | - |
| `document_exception_kind` enum members (2) | `bank_fee` C26 · `accountant_fee` C26 | - |
| Payment mark xor (5) | extra only C25 · both kind and extra C32 · extra on Match C34 · extra then `bank_fee` C35 · extra then Match C36 | - |
| mark POST rejects (5) | deactivated C30 · unknown `kind` C31 · both C32 · other org C33 · matched C34 | - |
| missing-document absences (3) | extra present is not missing C25 · unmark extra is missing C27 · all extra-excepted omits copy C37 | - |
| closed-month extra mark (3) | catalog POST still allowed C41 · mark refused C42 · unmark refused C43 | - |
| submitter extra-kind verbs (4) | POST catalog C47 · PATCH C48 · DELETE C49 · POST mark C50 | - |
| other-organization extra kind (3) | DELETE C23 · PATCH C24 · POST mark C33 | - |
| startup config assemblies | no new process setting — diff adds routes only, no env/credentials assembly | - |

Landing enumerations not given their own Coverage row are still proven as checks: no rename C13; missing document is all three absences C25/C27; Match.confirm clears extra C36; FK restrict C21/C46. Status/route claims C1, C2, C5–C10, C15, C20, C21, C23–C25, C27, C30–C34, C41–C43, C47–C50 each have a request-spec proof at HTTP.

## Test policy rows

Checklist follows `.cursor/rules/rails.mdc` (already answers both allocation questions). Verdicts against those rows:

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/extra_exception_kind.rb`, `app/models/payment.rb`, `app/models/match.rb` (clears extra FK) | model case per member **and** request spec for status/who | yes — include/lifecycle/mark/xor/rejects have both layers; C33 other-org 404 is decided in `DocumentExceptionsController` (`find_by` then `head :not_found`) and proven at HTTP; C38 close_blocker is the Month decision the Cost line assigns to a model spec (`month_spec.rb:94`), matching existing close_blocker proofs |
| Decides, not reached across a boundary | `app/models/summary_spreadsheet.rb#exception_label`, `Month#close_for_send` missing-document use of `Payment.missing_document` | own layer, one case per member | yes — C39 Exceção cell; C38 `Há documento faltante` |
| Entry point that decides nothing | `ExtraExceptionKindsController`, `DocumentExceptionsController` (pass-through of model result; HTTP status / who may call still needed) | request spec: accepted, each reject, each error path | yes — catalog C2/C5–C10/C15/C20/C21/C23/C24/C41/C47–C49; mark C25/C27/C30–C34/C42/C43/C50 |
| Instrumentation / pass-through | same controllers once ExtraExceptionKind/Payment decide | none of their own beyond consumer + HTTP who/status | yes — no extra controller-layer decision table beyond the 404/422 pass-through of model errors |

## Swept existing

No Swept row resolves to **existing**. Rows map to C-ids or `n/a` (no new remote; no new operator metric). Out-of-scope rows are policy, not code to re-read.

## Faults injected

Scratch worktree `/tmp/tlc-verify-worktrees/extra-exception-kinds` at `400764e`. Real tree porcelain before and after: `M AGENTS.md`, `M README.md` (unrelated; not in range). No mutation tooling in the Gemfile; five manual behaviour faults, one per assertion surface. Worktree discarded.

| Mutation | Location | Killed |
|---|---|---|
| reserved-name validator no-ops | `app/models/extra_exception_kind.rb` `name_is_not_base` | yes — C7 `rejects Tarifa bancaria` expected `not_to be_persisted`, record persisted |
| successful catalog create renders 422 instead of 302 | `app/controllers/extra_exception_kinds_controller.rb#create` | yes — C2 expected `:found`, got `:unprocessable_content` |
| `mark_extra` writes `extra_exception_kind_id: nil` | `app/models/payment.rb#mark_extra` | yes — C25 model expected extra id, got nil |
| extra Exceção cell always `Tarifa bancária` | `app/models/summary_spreadsheet.rb#exception_label` | yes — C39 expected `eq("Doação")` (example failed locating the row) |
| `Match#persist_confirm` stops clearing extra FK | `app/models/match.rb` payment update | yes — C36 model raised `PG::CheckViolation` on `payments_match_xor_document_exception` |

## Gate

`bin/rspec` (ten proof files, documentation format) — 211 examples, 0 failures. All 50 checks' named examples ran and passed. Five injected faults killed. No spec-lean `validate_verification.py` gate on this flow.
