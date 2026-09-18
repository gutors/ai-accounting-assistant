# Extra exception kinds

Sources:

- `.tasks/extra-exception-kinds.md` - this cut: criteria 1–50, doors, sweep, surface
- https://github.com/gutors/ai-accounting-assistant/issues/36 - unique name, include / deactivate / reactivate, no rename
- https://github.com/gutors/ai-accounting-assistant/issues/25#issuecomment-5639146328 - extra kind is an organization name besides the two base names
- `CONTEXT.md` - Extra exception kind, Document exception, Missing document, Organization
- `.specs/features/match-and-exception/plan.md` Landing door 3 - extras are a separate association
- https://github.com/gutors/ai-accounting-assistant/issues/5 - document exception exists only after the coordinator marks an allowed kind
- [ADR-0001](../docs/adr/0001-rails-8-hotwire.md) - Rails 8 + Hotwire; no new runtime
- user delegated in the task - unused DELETE is no Payment currently referencing the kind; setup copy; unknown-kind `422` is `Informe um tipo de exceção permitido`

No design source for the screens.

## Out of scope

- Exception suggestion of accountant’s fee or of any extra kind — #21 / #37; extra mark stays manual, no PIX, no history rule
- Renaming an extra exception kind — #25: deactivate and include another name
- Deactivating or listing tarifa bancária / honorário do contador as extra kinds — #25: the base is not this list
- Copying extra kinds from one organization onto another — #25
- Description, slug, or any field besides the name and active/inactive — #25
- Accountant login, Drive writes, Open Finance, SEFAZ, NF-e issuance
- Changing closed-month read-only for payments, matches, or statements — existing #34; this task only allows catalog edits while a month is closed

## Landing

Touches ExtraExceptionKind, Payment (`extra_exception_kind_id` and missing-document), DocumentExceptionsController, `/setup`, the month page, Match.confirm, Month#close_blocker, and SummarySpreadsheet. Reuses BankAccount include/deactivate/422-rerender, `require_coordinator_organization`, and `Payment#mark_document_exception` for the two base kinds.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Extra exception kind is an organization catalog row, not an enum value | `ExtraExceptionKind` belongs to `Organization`. Identity is the trimmed name, unique per organization including deactivated rows, compared case-insensitively (`Doação` occupies `doação`). Distinct from presentation names `Tarifa bancária` and `Honorário do contador` (same case-insensitive compare). Active boolean, default true. No rename. Unused row (no Payment currently references it) may be DELETEd; used row is `restrict`. `Payment.document_exception_kind` enum stays `{ bank_fee, accountant_fee }`. | Adding extra names to `document_exception_kind` — extras are organization catalog names, not a third enum value. A string column of free text on Payment — uniqueness, deactivate, and unused-remove live on the catalog. Never-delete like `BankAccount` — unused may leave. |
| Document exception extra mark is an optional Payment association, xor Match and xor base kind | `Payment` belongs to `ExtraExceptionKind` optionally (`extra_exception_kind_id`). Database check: at most one of `match_id`, `document_exception_kind`, `extra_exception_kind_id` is non-null. Missing document is all three absent. Mark POST accepts `kind=bank_fee` or `kind=accountant_fee` (unchanged) **or** `extra_exception_kind_id` of an **active** ExtraExceptionKind of the focused organization — not both. Confirming a Match still clears the extra FK. FK `ON DELETE restrict` is the unused-remove mechanism. | A `DocumentException` row — match-and-exception already rejected it for the two base kinds. Storing the extra name as text on Payment — deactivate would rename the mark or orphan the label. `kind=<name>` in the POST — a coordinator could include an extra named `bank_fee` and collide with the enum. |

- Nothing else in this change is hard to reverse

Unresolved 1 stays open (none).

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions):

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at the model layer **and** one request spec at HTTP | one asserted case per enumerated member at the model; status / who may call at the boundary | follow |
| Decides, not reached across a boundary | one at the model layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` lines 49–51 name the level and the sampling rule (one asserted case per enumerated member; HTTP also a request spec)
- `spec/models/bank_account_spec.rb` + `spec/requests/bank_accounts_spec.rb` — include / deactivate / uniqueness including inactive is the closest catalogue analogue
- `spec/models/payment_spec.rb` + `spec/requests/document_exceptions_spec.rb` — mark / unmark / unknown kind / matched / closed
- ExtraExceptionKindsController and DocumentExceptionsController stay pass-through once ExtraExceptionKind and Payment decide; HTTP status / who may call still need request specs

Cost: model specs for ExtraExceptionKind include/deactivate/remove and Payment extra-mark / missing-document / Match.confirm / Month#close_blocker / SummarySpreadsheet Exceção cell; request specs for every status/route claim below.

## Checks

### S1 - Include extra exception kinds · 11 files · 44 KB · ~11k

**C1** - When a coordinator of the focused organization opens `/setup` while that organization has zero extra exception kinds, then the response is `200` and includes the heading `Tipos extras de exceção` and the text `Nenhum tipo extra`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with zero extra exception kinds includes Tipos extras de excecao and Nenhum tipo extra"`

**C2** - When a coordinator submits name `Doação` as an extra exception kind, then the system persists one active ExtraExceptionKind named `Doação` on the focused organization, responds `302` to `/setup`, and that page includes `Doação`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST /extra_exception_kinds persists Doacao and redirects"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "create Doacao persists active ExtraExceptionKind"`

**C3** - When a coordinator submits name `  Doação  `, then the persisted name is `Doação`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST /extra_exception_kinds persists trimmed Doacao"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "create trims Doacao"`

**C4** - When organization B already has extra exception kind `Doação` and a coordinator of organization A submits `Doação`, then the system persists `Doação` on A and leaves B’s kind in place
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST /extra_exception_kinds on A leaves B Doacao in place"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "same name on another organization persists"`

**C5** - If a coordinator submits name `Doação` while that organization already has `Doação`, then the system persists no additional ExtraExceptionKind and responds `422`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST duplicate Doacao returns 422"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects duplicate Doacao"`

**C6** - If a coordinator submits name `doação` while that organization already has `Doação`, then the system persists no additional ExtraExceptionKind and responds `422`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST doacao when Doacao exists returns 422"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects doacao when Doacao exists"`

**C7** - If a coordinator submits name `Tarifa bancária`, then the system persists no ExtraExceptionKind and responds `422`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST Tarifa bancaria returns 422"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects Tarifa bancaria"`

**C8** - If a coordinator submits name `honorário do contador`, then the system persists no ExtraExceptionKind and responds `422`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST honorario do contador returns 422"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects honorario do contador"`

**C9** - If a coordinator submits a blank name, then the system persists no ExtraExceptionKind and responds `422`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST blank name returns 422"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects blank name"`

**C10** - If an unauthenticated request submits an extra exception kind, then the system persists none and responds `302` to `/login`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "unauthenticated POST /extra_exception_kinds responds 302 to /login"`

**C11** - When `/setup` lists extra exception kinds `Zeta` and `Alfa`, then `Alfa` appears before `Zeta`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup lists extra exception kinds Alfa before Zeta"`

**C12** - When `/setup` lists an extra exception kind, then it does not include a control that submits a new name for that kind
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup extra exception kind has no control that submits a new name"`

**C13** - If a coordinator PATCHes `name=Outro` on extra exception kind `Doação`, then the persisted name remains `Doação`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "PATCH name Outro leaves Doacao"`

**C14** - Always, `/setup` does not list `Tarifa bancária` or `Honorário do contador` as extra exception kinds
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup does not list Tarifa bancaria or Honorario do contador as extra exception kinds"`

### S2 - Deactivate, reactivate, remove unused · 7 files · 41 KB · ~10k

**C15** - When a coordinator PATCHes an active extra exception kind `Doação` to inactive, then the row remains, the response is `302` to `/setup`, and `/setup` includes `Doação` and `Desativado`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "PATCH extra exception kind inactive keeps row and shows Desativado"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "deactivate keeps the row"`

**C16** - When a coordinator PATCHes that deactivated kind to active, then `/setup` includes `Doação` and does not include `Desativado` on that kind’s row
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "PATCH extra exception kind active omits Desativado on that row"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "reactivate sets active"`

**C17** - When `/setup` lists an active extra exception kind, then it includes `Desativar`; when it lists a deactivated one, then it includes `Reativar`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup extra exception kinds show Desativar or Reativar"`

**C18** - When `/setup` lists extra exception kind `Folha` that no Payment references, then it includes `Excluir` for that kind
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup unused extra exception kind Folha includes Excluir"`

**C19** - While every extra exception kind of the focused organization is referenced by a Payment, `/setup` does not include `Excluir`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup includes no Excluir while every extra exception kind is referenced"`

**C20** - When a coordinator DELETEs extra exception kind `Folha` that no Payment references, then that row is gone, the response is `302` to `/setup`, and `/setup` does not include `Folha`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "DELETE unused Folha removes the row and redirects"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "destroy unused Folha deletes the row"`

**C21** - If a coordinator DELETEs extra exception kind `Doação` that a Payment of any month currently references, then the row remains and the response is `422`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "DELETE used Doacao returns 422"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "destroy used Doacao is rejected"`

**C22** - If a coordinator submits name `Doação` while a deactivated `Doação` exists on that organization, then the system persists no additional row, the existing row stays deactivated, and the response is `422`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST Doacao while deactivated Doacao exists returns 422"`
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "rejects Doacao while deactivated Doacao exists"`

**C23** - If a request DELETEs an extra exception kind that belongs only to another organization, then that row remains and the response is `404`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "DELETE extra exception kind of another organization returns 404"`

**C24** - If a request PATCHes an extra exception kind that belongs only to another organization, then that row remains unchanged and the response is `404`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "PATCH extra exception kind of another organization returns 404"`

### S3 - Mark an extra kind on a payment · 13 files · 82 KB · ~21k

**C25** - Given the focused organization has active extra exception kind `Doação`, when a coordinator POSTs `extra_exception_kind_id` of that kind on a missing-document Payment of `/months/2026-05`, then the system persists that mark, `document_exception_kind` on that payment is nil, the response is `302` to `/months/2026-05`, and that payment’s row includes `Doação` and does not include `Documento faltante`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST extra_exception_kind_id Doacao persists and redirects"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "mark extra Doacao on missing-document payment"`

**C26** - Always, `Payment.document_exception_kinds` keys and values are exactly `bank_fee` and `accountant_fee`
Proof: `bin/rspec spec/models/payment_spec.rb -e "document_exception_kind enum members are bank_fee and accountant_fee"`

**C27** - When a coordinator DELETEs the document exception on a payment marked with `Doação`, then `extra_exception_kind_id` is nil, the response is `302`, and that row includes `Documento faltante` and does not include `Doação`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "DELETE extra Doacao returns Documento faltante"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "unmark extra Doacao returns missing document"`

**C28** - When a coordinator has just persisted extra exception kind `Doação`, then `GET /months/2026-05` of an open month includes `Doação` as a mark choice on a missing-document payment
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 includes Doacao as a mark choice"`

**C29** - While extra exception kind `Doação` is deactivated, `GET /months/2026-05` of an open month does not include a mark control that submits that kind’s id, and a payment already marked with it still includes `Doação` and does not include `Documento faltante`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 deactivated Doacao is not offered and stays on the marked payment"`

**C30** - If a coordinator POSTs `extra_exception_kind_id` of a deactivated kind, then the system persists no mark and responds `422` with `Informe um tipo de exceção permitido`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST deactivated extra_exception_kind_id returns 422 Informe um tipo de excecao permitido"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "rejects deactivated extra Doacao"`

**C31** - If a coordinator POSTs `kind=doacao` and no `extra_exception_kind_id`, then the system persists no mark and responds `422` with `Informe um tipo de exceção permitido`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST kind doacao returns 422 Informe um tipo de excecao permitido"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "rejects kind doacao"`

**C32** - If a coordinator POSTs both `kind=bank_fee` and an `extra_exception_kind_id`, then the system persists no mark and responds `422` with `Informe um tipo de exceção permitido`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST kind bank_fee and extra_exception_kind_id returns 422"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "rejects kind bank_fee together with extra Doacao"`

**C33** - If a coordinator POSTs `extra_exception_kind_id` of another organization’s kind, then the system persists no mark and responds `404`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST extra_exception_kind_id of another organization returns 404"`

**C34** - If a coordinator POSTs `extra_exception_kind_id` on a Payment that belongs to a Match, then the Match stays, no extra mark is persisted, and the response is `422` with `Desfaça o casamento antes de marcar a exceção`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST extra_exception_kind_id on matched payment returns 422 Desfaca o casamento"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "rejects extra Doacao on a matched payment"`

**C35** - When a coordinator POSTs `kind=bank_fee` on a payment marked with `Doação`, then that payment is `bank_fee`, `extra_exception_kind_id` is nil, and the row includes `Tarifa bancária` and does not include `Doação`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST bank_fee replaces extra Doacao"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "mark bank_fee clears extra Doacao"`

**C36** - When a coordinator POSTs a valid format-1 Match for a payment marked with `Doação`, then the Match persists, `extra_exception_kind_id` is nil, and the row includes `Casado` and does not include `Doação`
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST format-1 Match on extra Doacao payment clears the extra mark"`
Proof: `bin/rspec spec/models/match_spec.rb -e "confirm on extra Doacao payment clears the extra mark"`

**C37** - While every Payment of `/months/2026-05` is marked with extra exception kind `Doação`, `GET /months/2026-05` does not include `Documento faltante`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 with every payment extra-excepted omits Documento faltante"`

**C38** - When the month’s only Payment is marked with extra exception kind `Doação`, then `Month#close_for_send` does not add `Há documento faltante` to errors
Proof: `bin/rspec spec/models/month_spec.rb -e "close with extra Doacao payment does not add Ha documento faltante"`

**C39** - When a Payment is marked with extra exception kind `Doação`, then that payment’s Custos/Despesas Exceção cell in the summary spreadsheet is `Doação`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "extra Doacao expense Excecao cell is Doacao"`

### S4 - Isolation, closed month, submitter, concurrency · 6 files · 54 KB · ~14k

**C40** - While focus is organization A, `/setup` and `GET /months/2026-05` do not include extra exception kind names that belong only to organization B
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup does not list another organization extra exception kind"`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 does not include another organization extra exception kind"`

**C41** - When Month `2026-05` is closed, a coordinator POST of extra exception kind `Doação` still persists the kind and responds `302` to `/setup`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST /extra_exception_kinds while month closed persists and redirects"`

**C42** - If a coordinator POSTs `extra_exception_kind_id` while the Month is closed, then no mark is persisted and the response is `422` with `Mês fechado`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST extra_exception_kind_id while closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "mark extra Doacao while Month closed persists no mark"`

**C43** - If a coordinator DELETEs a document exception marked with an extra kind while the Month is closed, then the mark remains and the response is `422` with `Mês fechado`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "DELETE extra Doacao while closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "unmark extra Doacao while Month closed keeps the mark"`

**C44** - When Month `2026-05` is closed and a payment is marked with deactivated `Doação`, then `GET /months/2026-05` includes `Doação` and does not include `Documento faltante` or `Desmarcar exceção` for that payment
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET closed month shows deactivated Doacao without Desmarcar excecao"`

**C45** - If two concurrent POSTs submit extra exception kind name `Doação` on the same organization, then the system persists exactly one ExtraExceptionKind
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "concurrent creates persist exactly one ExtraExceptionKind"`

**C46** - If a DELETE of unused extra exception kind `Folha` runs concurrently with a POST that marks a payment with that kind, then the system persists either the kind plus the mark, or neither a mark nor that kind row, and never a Payment whose `extra_exception_kind_id` points at a missing ExtraExceptionKind
Proof: `bin/rspec spec/models/extra_exception_kind_spec.rb -e "concurrent unused destroy and mark persist kind plus mark or neither"`

**C47** - If a submitter POSTs an extra exception kind, then the system persists none and responds `404`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "submitter POST /extra_exception_kinds persists none and responds 404"`

**C48** - If a submitter PATCHes an extra exception kind, then that row remains unchanged and the response is `404`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "submitter PATCH extra exception kind returns 404"`

**C49** - If a submitter DELETEs an extra exception kind, then that row remains and the response is `404`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "submitter DELETE extra exception kind returns 404"`

**C50** - If a submitter POSTs `extra_exception_kind_id` as a document exception, then the system persists no mark and responds `404`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "submitter POST extra_exception_kind_id persists no mark and responds 404"`

## Swept

- validation: C3, C5, C6, C7, C8, C9, C22, C30, C31, C32
- failure modes: C21, C23, C24, C30, C33, C34, C42, C43
- idempotency and retry: C5, C22 - a second include of the same name does not create a second row; deactivated name stays occupied
- authorization: C10, C23, C24, C33, C40, C47, C48, C49, C50
- concurrency and ordering: C45, C46
- data lifecycle: C15, C16, C20, C21 - deactivate keeps the row and the unique name; unused DELETE removes the row; used DELETE is refused because a Payment still references it
- external-dependency failure: n/a - no new remote; Drive writer and Google OIDC are unchanged
- state transitions: C2, C15, C16, C20, C25, C27, C29, C35, C36
- observability: n/a - no operator metric or log line is required; Rails request logging already covers HTML

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| ExtraExceptionKind include rejects (5) | duplicate C5 · case-insensitive C6 · `Tarifa bancária` C7 · `honorário do contador` C8 · blank C9 | - |
| ExtraExceptionKind name uniqueness (4) | same org exact C5 · same org case C6 · other org allowed C4 · deactivated occupies C22 | - |
| reserved base names (2) | `Tarifa bancária` C7 · `honorário do contador` C8 | - |
| ExtraExceptionKind lifecycle (5) | include Active C2 · deactivate C15 · reactivate C16 · unused DELETE C20 · used DELETE refuse C21 | - |
| `document_exception_kind` enum members (2) | `bank_fee` C26 · `accountant_fee` C26 | - |
| Payment mark xor (5) | extra only C25 · both kind and extra C32 · extra on Match C34 · extra then `bank_fee` C35 · extra then Match C36 | - |
| mark POST rejects (5) | deactivated C30 · unknown `kind` C31 · both C32 · other org C33 · matched C34 | - |
| missing-document absences (3) | extra present is not missing C25 · unmark extra is missing C27 · all extra-excepted omits copy C37 | - |
| closed-month extra mark (3) | catalog POST still allowed C41 · mark refused C42 · unmark refused C43 | - |
| submitter extra-kind verbs (4) | POST catalog C47 · PATCH C48 · DELETE C49 · POST mark C50 | - |
| other-organization extra kind (3) | DELETE C23 · PATCH C24 · POST mark C33 | - |
| startup config assemblies | no new process setting | - |

- Claims naming a status code, route or response shape: C1, C2, C5–C10, C15, C20, C21, C23–C25, C27, C30–C34, C41–C43, C47–C50 - each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~11k + S2 ~10k + S3 ~21k + S4 ~14k = ~56k tokens floor. All four slices stay under 150k. Surface changes at S3 (setup catalog → payment/month) but the running total never reaches the budget, so no split.
