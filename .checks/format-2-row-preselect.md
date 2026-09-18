# Format-2 row preselect

## Intent

A 2:1 suggestion currently checks that document on each per-payment `Confirmar casamento` form. That form posts one `payment_ids[]`. Confirming one row therefore persists a greater 1:1 (document cents above the payment, observation blank) and leaves the other payment unmatched. Preselect on the 1:1 form only when the suggestion has exactly one payment. Format-2 stays preselected on the existing N:1 form.

Sources:

- https://github.com/gutors/ai-accounting-assistant/pull/52#discussion_r4050269648 - F1: 2:1 document is preselected on each 1:1 form; fix is `suggestion.payments.size == 1`
- `.checks/assisted-suggestions.md` C64–C68 / Landing row “Format-2 confirm ids are preselected on the existing N:1 form” - 1:1 and justification stay on the per-payment form; 2:1 uses the N:1 form
- `.tasks/assisted-suggestions.md` criteria 26, 27, 64, 66 - format-2 is two payments and one document; suggested ids on the existing `POST /matches` form
- `CONTEXT.md` - Suggestion, Match

No design source for the screens.

## Out of scope

- Refusing a hand-checked greater 1:1 when a 2:1 suggestion exists — Match.confirm already accepts 1 payment + 1 greater document with blank observation; this cut only stops the preselect
- Changing N:1 form preselect or the lowest-payment-id winner — assisted-suggestions C66 / C68
- Auto-confirm of format-2 — #12: the system never confirms

## Landing

Touches the per-payment `POST /matches` form on `app/views/months/show.html.erb` and `Suggestion#one_to_one_form_document_ids`. Reuses `covers_payment?` / `suggested_document?` / `format_2_for_n1_form` for the N:1 form, `payment_row_html` / `selected_named_values` in the specs, and existing `Match.confirm` `NO_DOCUMENTS` when the 1:1 form posts no document.

None - nothing here is one-way: the preselect predicate is a view/Suggestion guard, reversible by putting document ids back on the 1:1 form. `one_to_one_form_document_ids` is the same Suggestion-predicate convention as `suggested_document?`.

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions):

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at the model layer **and** one request spec at HTTP | one asserted case per enumerated member at the model; status / who may call at the boundary | follow |
| Decides, not reached across a boundary | one at the model layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` lines 49–51 name the level and the sampling rule
- `Suggestion#one_to_one_form_document_ids` decides the 1:1 form’s checked `supporting_document_ids[]` over three shapes (1:1, 1:N, 2:1) — same layer as `format_2_for_n1_form`
- MonthsController#show stays pass-through; the GET HTML and the POST of that form’s selected ids still need request specs
- closest analogue: `spec/models/suggestion_spec.rb` `format_2_for_n1_form` + `spec/requests/months_spec.rb` C66 — picker at Suggestion, selected ids at HTTP

Cost: three model examples (one per shape) and request specs for GET unselect, GET still-select on 1:1 and 1:N, and POST of the 1:1 form as shown.

## Checks

### S1 - Format-2 is not preselected on the 1:1 form · 5 files · 102 KB · ~25k

**C1** - Given unmatched SupportingDocument of `22000` cents payee `Padaria Central` and missing-document Payments of `10000` cents history `Pix enviado — Dez` and `12000` cents history `Pix enviado — Doze` on Month `2026-05`, when a coordinator GETs `/months/2026-05`, then the `10000`-cent payment’s `POST /months/2026-05/matches` form whose submit is `Confirmar casamento` does not have that SupportingDocument id selected, and the `12000`-cent payment’s same form does not have that SupportingDocument id selected
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET format-2 1:1 form does not select Padaria Central"`

**C2** - Given that same pair, when a coordinator POSTs to `/months/2026-05/matches` the `payment_ids[]` and `supporting_document_ids[]` that are selected on the `10000`-cent payment’s `Confirmar casamento` form, then the system persists no Match, responds `422` with `Selecione ao menos um documento`, and both payment rows still include `Documento faltante` and `Sugestão`
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST format-2 1:1 form as shown returns 422 and leaves both unmatched"`

**C3** - Given a missing-document Payment of `22000` cents history `Pix enviado — Padaria Central` and one unmatched SupportingDocument of `22000` cents payee `Padaria Central`, when a coordinator GETs `/months/2026-05`, then that payment’s `Confirmar casamento` form has that SupportingDocument id selected
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET 1:1 form selects Padaria Central when suggestion has one payment"`

**C4** - Given a Justification of `20000` cents whose members are unmatched SupportingDocuments payees `Padaria Central` (`15500`) and `Mercado Silva` (`4500`), and a missing-document Payment of `20000` cents history `Pix enviado — Gasto`, when a coordinator GETs `/months/2026-05`, then that payment’s `Confirmar casamento` form has both member SupportingDocument ids selected
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET justification form selects both members when suggestion has one payment"`

**C5** - Given a Suggestion of one Payment and one SupportingDocument, `one_to_one_form_document_ids` is an array of that SupportingDocument’s id
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "one_to_one_form_document_ids for 1:1 is the document id"`

**C6** - Given a Suggestion of two Payments and one SupportingDocument, `one_to_one_form_document_ids` is an empty array
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "one_to_one_form_document_ids for 2:1 is empty"`

**C7** - Given a Suggestion of one Payment and two SupportingDocuments, `one_to_one_form_document_ids` is those two SupportingDocument ids
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "one_to_one_form_document_ids for 1:N is both document ids"`

## Swept

- validation: C5, C6, C7 - preselect ids only when `payments.size == 1`
- failure modes: C2 - submitting the 1:1 form as shown does not persist a greater 1:1; `422` `Selecione ao menos um documento`
- idempotency and retry: existing - a second GET still derives the same 2:1; a second confirm of taken ids is existing `422` `Pagamento já está em um casamento`
- authorization: existing `require_coordinator_organization` on `GET /months/:year_month` and `POST /matches`
- concurrency and ordering: n/a - this cut does not change assignment rank or the N:1 winner
- data lifecycle: n/a - suggestions stay derived at GET; nothing to persist or backfill
- external-dependency failure: n/a - no new remote
- state transitions: C2 - both payments remain missing-document / `Sugestão` after the 1:1 form POST
- observability: n/a - no new log or metric

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| 1:1 form preselect shapes (3) | 1:1 C3, C5 · 1:N C4, C7 · 2:1 empty C1, C6 | - |
| POST of 1:1 form as shown on 2:1 (1) | C2 | - |
| startup config assemblies | no new process setting | - |

- Claims naming a status code, route or response shape: C1, C2, C3, C4 - each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 = 5 files · 102 KB · ~25k. Under 150k, one slice, no split.
