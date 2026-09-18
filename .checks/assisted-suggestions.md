# Assisted suggestions

Sources:

- `.tasks/assisted-suggestions.md` - this cut: criteria 1–67, doors, sweep, surface
- https://github.com/gutors/ai-accounting-assistant/issues/37 - assisted match suggestion after the statement; exception suggestion of honorário from PIX or tax id
- https://github.com/gutors/ai-accounting-assistant/issues/12#issuecomment-5607855444 - system never confirms; clear candidate already linked; still missing document until confirm
- https://github.com/gutors/ai-accounting-assistant/issues/12#issuecomment-5628194387 / https://github.com/gutors/ai-accounting-assistant/issues/20#issuecomment-5628193823 - document has no month until match; closed month never
- https://github.com/gutors/ai-accounting-assistant/issues/21#issuecomment-5628538712 - exception suggestion is not a suggestion; honorário only; PIX or tax id; presentation name and razão social out
- https://github.com/gutors/ai-accounting-assistant/issues/10#issuecomment-5605280962 - format 1 vs format 2; rank equal, then greater, then lesser
- `CONTEXT.md` - Suggestion, Exception suggestion, Justification, Match, Missing document, Document exception
- `.specs/features/match-and-exception/plan.md` - confirm POSTs already exist; no second Match parent
- [ADR-0003](../docs/adr/0003-extra-exception-kinds.md) - no second extra-kind catalog
- [ADR-0001](../docs/adr/0001-rails-8-hotwire.md) - Rails 8 + Hotwire; no new runtime
- `.tasks/submitter-access.md` - turning a justification into a suggestion was deferred here
- `.tasks/extra-exception-kinds.md` - extra marks stay manual
- user delegated in the task - name hit is containment after downcase, collapsed whitespace, and Latin accent fold; 1:N grouping only through an existing Justification; lesser 1:1 still suppresses exception suggestion; copy is `Sugestão` and `Sugestão de exceção`; suggested ids are selected on the existing `POST /matches` form

No design source for the screens.

## Out of scope

- Automatic confirm when amounts, dates, or names agree — #12 / #10: the system never confirms
- Exception suggestion of tarifa bancária or of any extra exception kind — #21 / #25: those marks stay manual; ADR-0003
- Combining unmatched documents that do not already share a Justification into a 1:N suggestion — user delegated
- Open Finance JSON statement fields as a structured PIX/tax-id column — #21
- Parsing XML, identified SEFAZ consulta, reading the photo — #38
- Choosing unmatched documents into the package, or suggesting against a month assigned only at close-for-send — #39
- A dismiss / reject control for a suggestion — #12
- Accountant login, Drive writes, NF-e issuance

## Landing

Touches a derived `Suggestion` / `ExceptionSuggestion` computed when a coordinator GETs an open Month, the month page (`app/views/months/show.html.erb`), and `load_month_page`. Reuses existing `POST /matches`, `POST .../document_exception`, `Payment#missing_document?`, `Match.confirm` lesser observation, `NormalizedEmail`, `BrazilianTaxId.normalize`, and `require_coordinator_organization`. No `suggestions` table.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Suggestion and exception suggestion are derived at GET, not persisted rows | Identity is the proposed Payment id(s) plus SupportingDocument id(s) (or `accountant_fee` on one Payment) computed when a coordinator GETs an open Month. Confirm writes a `Match` or `document_exception_kind=accountant_fee` through the existing POSTs. No `suggestions` table. | A Suggestion / ExceptionSuggestion row — #12 never confirms by itself, so there is nothing to store until Match or mark; statement replace, document insert/PATCH/withdraw, leave-match, and accountant PIX/tax-id edits would all need rebuild. A new confirm route — the ids already POST to `/matches` and `/document_exception`. |
| Assignment rank is equal, then format-2, then greater, then lesser; at most one suggestion per Payment and per document (or Justification group) | Amount key is `supporting_document.amount_cents` when the document has no Justification; `justification.amount_cents` when it does, and every member document is the document side together. Equal: one missing-document Payment whose cents equal that key (Justification → format 1 with N docs). Else format-2: exactly two missing-document Payments of the **same** Month whose cents sum to the key, and the document side is **one** SupportingDocument (a multi-document Justification never takes this arm). Else one Payment with document-side cents **greater** than the payment. Else one Payment with document-side cents **lesser**. Within a rank: name hit before no name hit; then lowest Payment id; then lowest SupportingDocument id (or Justification id). Name hit: transliterate both payee and history (Latin accents to base letters), downcase, collapse whitespace, then either string contains the other. Documents in a Justification are never assigned as individuals. Format-2 never uses three or more Payments and never spans Months. Date is not a gate. Recibo, nota fiscal, and XML-backed rows share this rank. | Auto-confirm on equal — #12. Suggesting three-plus payments — #10. Format-2 for a multi-document Justification — #10 forbids N×M. Combining ungrouped receipts by subset-sum — user delegated. Ranking by `occurred_on` / `document_on` — #10 / #12. Equality-only name compare — user delegated: containment after accent fold. |
| Exception suggestion is `accountant_fee` only, on a missing-document Payment that has no match suggestion, when `history` hits normalized PIX or tax id | Hit if `accountant_pix_key` is present and matches, **or** `accountant_tax_id` is present and its digit form is a substring of the digit form of `history`. PIX: if `NormalizedEmail.valid?` on the trimmed key, downcased key is a substring of downcased `history`; else if the key has any digit, digit-only key is a substring of digit-only `history`; else case-insensitive substring of the trimmed key in `history`. Tax id uses `BrazilianTaxId.normalize`. Presentation name and razão social never hit. Catalog with neither PIX nor tax id never fires. Two hitting Payments each get a proposal. A match suggestion on that Payment suppresses it, including a lesser 1:1. Manual `bank_fee` / `accountant_fee` / extra mark still apply. Inflows never receive it. | Inferring tarifa from history text — #5 / #21. Suggesting extra kinds — #25 / ADR-0003. Matching presentation name or razão social — #21. A structured Payment PIX column this cut — #8. Writing the mark without confirm — #21. Letting lesser 1:1 keep showing honorário, or dropping lesser auto-link — user delegated: any match suggestion wins, including lesser. |

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

- `.cursor/rules/rails.mdc` lines 49–51 name the level and the sampling rule
- `spec/models/match_spec.rb` + `spec/requests/matches_spec.rb` — confirm shape / lesser observation is the closest analogue
- `spec/models/payment_spec.rb` + `spec/requests/document_exceptions_spec.rb` — mark / missing-document
- MonthsController#show and MatchesController stay pass-through once Suggestion / ExceptionSuggestion decide; HTTP status / copy / selected ids still need request specs

Cost: model specs for every rank arm, name-hit rule, PIX/tax-id arm, and at-most-one assignment; request specs for every status/route/copy claim below.

## Checks

### S1 - Clear 1:1 candidate is already linked · 9 files · 91 KB · ~23k

**C1** - Given open Month `2026-05` has a missing-document Payment of `22000` cents whose history is `Pix enviado — Padaria Central`, and the focused organization has one unmatched SupportingDocument of `22000` cents payee `Padaria Central` in no Justification, when a coordinator GETs `/months/2026-05`, then the response is `200`, that payment’s row includes `Documento faltante`, includes `Sugestão`, and includes `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET 1:1 equal Padaria Central includes Sugestao and Documento faltante"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "equal 1:1 name hit assigns Padaria Central"`

**C2** - When that GET succeeds, then that Payment still has `match_id` nil, `document_exception_kind` nil, and `extra_exception_kind_id` nil, and that SupportingDocument still has `month_id` nil and `match_id` nil
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET 1:1 equal leaves Payment unmatched and document without month"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "assign does not persist a Match"`

**C3** - When a coordinator POSTs that Payment id and that SupportingDocument id with observation blank to `/months/2026-05/matches`, then the system persists one Match, responds `302` to `/months/2026-05`, and that page includes `Casado` and `Padaria Central` and does not include `Documento faltante` or `Sugestão` on that payment
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST suggested 1:1 equal persists Casado and omits Sugestao"`

**C4** - When that confirm succeeds, then `GET /supporting_documents` includes `Casado em 2026-05` for that document
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents after suggested 1:1 includes Casado em 2026-05"`

**C5** - Given that Payment and no unmatched SupportingDocument of `22000` cents, when a coordinator GETs `/months/2026-05`, then that payment’s row includes `Documento faltante` and does not include `Sugestão`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET missing-document payment with no unmatched document omits Sugestao"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "no unmatched document assigns nothing"`

**C6** - When `/months/2026-05` has zero Payments, then the page does not include `Sugestão`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 with zero Payments omits Sugestao"`

**C7** - While `/months/2026-05` lists an Inflow under `Recebimentos`, that section does not include `Sugestão` or `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "Recebimentos section omits Sugestao and Sugestao de excecao"`

**C8** - When the unmatched document is a `recibo` of `22000` cents payee `Padaria Central` and the Payment history contains `Padaria Central`, then that payment’s row includes `Sugestão` and `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET recibo 1:1 includes Sugestao and Padaria Central"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "recibo equal 1:1 is assigned"`

**C9** - When the unmatched document is a `nota_fiscal` of `22000` cents payee `Padaria Central` with XML attached and the Payment history contains `Padaria Central`, then that payment’s row includes `Sugestão` and `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET nota_fiscal with XML 1:1 includes Sugestao and Padaria Central"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "nota_fiscal equal 1:1 is assigned"`

**C10** - While a payment’s row includes `Sugestão` and `Padaria Central`, `Documentos sem casamento` still includes `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "unmatched pool still includes Padaria Central while Sugestao shows"`

### S2 - Later documents, value ties, open months · 6 files · 72 KB · ~18k

**C11** - Given the Payment of `22000` cents already exists, when a coordinator then inserts the unmatched SupportingDocument of `22000` cents payee `Padaria Central`, then `GET /months/2026-05` includes `Sugestão` and `Padaria Central` on that payment
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET after later document insert includes Sugestao"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "document inserted after payment is assigned"`

**C12** - Given two missing-document Payments of `22000` cents whose histories are `Pix enviado — Padaria Central` and `Pix enviado — Mercado Silva`, and one unmatched SupportingDocument of `22000` cents payee `Padaria Central`, then `GET /months/2026-05` includes `Sugestão` and `Padaria Central` on the Padaria payment and does not include `Sugestão` on the Mercado Silva payment
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET value tie name hit assigns Padaria not Mercado"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "equal rank name hit beats no name hit"`

**C13** - Given two missing-document Payments of `22000` cents that both have history `Pix enviado — Padaria Central`, and one unmatched SupportingDocument of `22000` cents payee `Padaria Central`, then `GET /months/2026-05` includes `Sugestão` on the lower-id payment only
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET two name-hit equals assigns lower-id payment only"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "equal name-hit tie breaks on lowest payment id"`

**C14** - Given two unmatched SupportingDocuments of `22000` cents payees `Padaria Central` and `Mercado Silva`, and one missing-document Payment of `22000` cents whose history is `Pix enviado — Padaria Central`, then that payment’s row includes `Sugestão` and `Padaria Central` and does not include `Mercado Silva`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET two equal docs name hit assigns Padaria Central not Mercado Silva"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "equal two docs name hit picks Padaria Central"`

**C15** - Given two unmatched SupportingDocuments of `22000` cents payees `Padaria Norte` (lower id) and `Padaria Sul`, and one missing-document Payment of `22000` cents whose history is `Pix`, then that payment’s row includes `Sugestão` and `Padaria Norte` and does not include `Padaria Sul`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET two equal docs no name hit assigns lower-id Padaria Norte"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "equal no-name-hit tie breaks on lowest document id"`

**C16** - Given open Months `2026-05` and `2026-06` each have a missing-document Payment of `22000` cents, May history `Pix enviado — Padaria Central`, June history `Pix enviado — Mercado Silva`, and one unmatched no-month SupportingDocument of `22000` cents payee `Padaria Central`, then `GET /months/2026-05` includes `Sugestão` on May’s payment and `GET /months/2026-06` does not include `Sugestão` on June’s payment
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET cross-month name hit assigns May not June"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "open-month name hit assigns May payment not June"`

**C17** - Given those two months’ Payments both have history `Pix` and the document payee is `Padaria Central`, then `GET` of the month that holds the lower-id Payment includes `Sugestão` and the other month’s payment row does not
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET cross-month no name hit assigns lower-id payment month"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "cross-month equal tie breaks on lowest payment id"`

**C18** - Given a Payment of `22000` cents on `2026-05-20` whose history contains `Padaria Central`, and an unmatched SupportingDocument of `22000` cents payee `Padaria Central` on `2026-04-30`, then `GET /months/2026-05` includes `Sugestão` and `Padaria Central` on that payment
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET document_on before occurred_on still includes Sugestao"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "document_on before occurred_on is still assigned"`

**C19** - Given a missing-document Payment of `22000` cents whose history is `Pix enviado — Outro` and the only unmatched SupportingDocument is `22000` cents payee `Padaria Central`, then that payment’s row includes `Sugestão` and `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET equal with no name hit still includes Sugestao"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "equal with no name hit still assigns"`

**C20** - Given two missing-document Payments of `22000` cents whose histories are `Pix enviado — JOSE SILVA` and `Pix enviado — Mercado Silva`, and one unmatched SupportingDocument of `22000` cents payee `José Silva`, then `GET /months/2026-05` includes `Sugestão` and `José Silva` on the JOSE SILVA payment and does not include `Sugestão` on the Mercado Silva payment
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET accent-fold name hit assigns Jose Silva not Mercado"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "name hit folds Jose to JOSE"`

**C21** - Always, a Payment belongs to at most one suggestion and a SupportingDocument belongs to at most one suggestion
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "a Payment belongs to at most one suggestion"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "a SupportingDocument belongs to at most one suggestion"`

### S3 - Amount ranking and two-payment format · 6 files · 69 KB · ~17k

**C22** - Given a missing-document Payment of `22000` cents whose history is `Pix enviado — Mercado Silva`, an unmatched SupportingDocument of `22000` cents payee `Padaria Central`, and an unmatched SupportingDocument of `25000` cents payee `Mercado Silva`, then that payment’s row includes `Sugestão` and `Padaria Central` and does not include `Mercado Silva`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET equal beats greater even when greater has name hit"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "equal rank beats greater rank"`

**C23** - Given a missing-document Payment of `22000` cents, no unmatched document of `22000` cents, and unmatched documents of `25000` and `20000` cents, then that payment’s row includes `Sugestão` and the `25000`-cent document’s payee and does not include the `20000`-cent document’s payee
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET greater beats lesser"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "greater rank beats lesser rank"`

**C24** - Given a missing-document Payment of `22000` cents and the only unmatched SupportingDocument is `20000` cents payee `Padaria Central`, then that payment’s row includes `Sugestão` and `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET lesser 1:1 includes Sugestao and Padaria Central"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "lesser 1:1 is assigned"`

**C25** - If a coordinator POSTs that lesser suggestion with observation blank, then the system persists no Match and responds `422` with `Informe a observação do casamento`
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST suggested lesser without observation returns 422"`

**C26** - Given unmatched SupportingDocument of `22000` cents payee `Padaria Central`, two missing-document Payments of `10000` and `12000` cents on Month `2026-05`, and no Payment of `22000` cents, then both payment rows include `Sugestão` and `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET format-2 both payments include Sugestao and Padaria Central"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "format-2 assigns both payments and one document"`

**C27** - When a coordinator POSTs those two Payment ids and that SupportingDocument id with observation blank, then the system persists one Match, both rows include `Casado`, and neither includes `Documento faltante` or `Sugestão`
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST suggested format-2 persists Casado on both payments"`

**C28** - Given a Payment of `22000` cents and also Payments of `10000` and `12000` cents, and one unmatched SupportingDocument of `22000` cents, then the `22000`-cent payment’s row includes `Sugestão` and that payee, and the `10000`-cent payment’s row does not include `Sugestão`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET equal beats format-2"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "equal rank beats format-2 rank"`

**C29** - Given unmatched SupportingDocument of `22000` cents payee `Padaria Central`, Payments of `10000` and `12000` cents whose histories contain `Padaria Central`, and Payments of `10000` and `12000` cents whose histories are `Outro`, then the Padaria pair’s rows include `Sugestão` and `Padaria Central` and the Outro pair’s rows do not
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET format-2 name hit beats format-2 no name hit"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "format-2 name hit beats format-2 no name hit"`

**C30** - Always, a suggestion is one Payment with one or more SupportingDocuments, or exactly two Payments with one SupportingDocument
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "suggestion shape is 1:N or exactly 2:1"`

**C31** - Given three missing-document Payments of `7000`, `7000`, and `8000` cents and one unmatched SupportingDocument of `22000` cents, then `GET /months/2026-05` does not include a suggestion that groups all three payments
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET three payments does not group all three as one suggestion"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "does not assign three payments to one document"`

### S4 - Justification becomes a suggestion · 6 files · 78 KB · ~20k

**C32** - Given a Justification of `20000` cents whose members are unmatched SupportingDocuments payees `Padaria Central` (`15500`) and `Mercado Silva` (`4500`), and a missing-document Payment of `20000` cents, when a coordinator GETs `/months/2026-05`, then that payment’s row includes `Sugestão`, `Padaria Central`, and `Mercado Silva`, and includes `Documento faltante`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET justification equal includes both payees and Documento faltante"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "justification equal assigns all members"`

**C33** - When a coordinator POSTs that Payment id and both member ids with observation blank, then the system persists one Match, responds `302`, and that row includes `Casado` and both payees and does not include `Documento faltante` or `Sugestão`
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST suggested justification equal persists Casado with both payees"`

**C34** - While those two documents belong to that Justification of `20000` cents, a missing-document Payment of `15500` cents does not include `Sugestão` of `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET justification member is not assigned as an individual"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "justification members are never assigned as individuals"`

**C35** - Given that two-document Justification of `20000` cents, two missing-document Payments of `10000` cents, and no Payment of `20000` cents, then `GET /months/2026-05` does not include `Sugestão` on both `10000` payments together (that would be two payments with two documents)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET does not format-2 a multi-document justification"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "multi-document justification never takes format-2"`

**C36** - Given a Justification of `18000` cents whose members sum to `20000` cents, and a missing-document Payment of `18000` cents, then that payment’s row includes `Sugestão` and both member payees
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET justification amount_cents 18000 equal includes both payees"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "justification amount_cents is the equal key"`

**C37** - When a coordinator POSTs that Payment and both members with observation blank, then the Match persists (`20000` greater than `18000`)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST justification members greater than payment persists Match"`

**C38** - Given a Justification of `22000` cents whose members sum to `20000` cents, and a missing-document Payment of `22000` cents, then that payment’s row includes `Sugestão` and both member payees
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET justification 22000 with members 20000 includes Sugestao"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "justification 22000 equal assigns members summing 20000"`

**C39** - If a coordinator POSTs that Payment and both members with observation blank, then the system persists no Match and responds `422` with `Informe a observação do casamento`
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST justification lesser without observation returns 422"`

### S5 - Exception suggestion of accountant’s fee · 8 files · 110 KB · ~28k

**C40** - Given the focused organization has `accountant_pix_key` `chave-pix` and no `accountant_tax_id`, Month `2026-05` has a missing-document Payment whose history is `Pix enviado chave-pix`, and the organization has no unmatched SupportingDocument, when a coordinator GETs `/months/2026-05`, then that payment’s row includes `Sugestão de exceção` and `Documento faltante` and does not include `Honorário do contador`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET PIX chave-pix includes Sugestao de excecao and Documento faltante"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "PIX substring hit proposes accountant_fee"`

**C41** - When that GET succeeds, then that Payment still has `document_exception_kind` nil
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET exception suggestion leaves document_exception_kind nil"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "assign does not persist accountant_fee"`

**C42** - If a coordinator POSTs `/months/2026-05/close` while that exception suggestion is showing, then the month remains not closed and the response is `422` with `Há documento faltante`
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close while exception suggestion showing returns 422 Ha documento faltante"`

**C43** - When a coordinator POSTs `kind=accountant_fee` on that payment, then the row includes `Honorário do contador` and does not include `Documento faltante` or `Sugestão de exceção`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST accountant_fee on exception suggestion shows Honorario and omits Sugestao de excecao"`

**C44** - Given `accountant_tax_id` `39053344705` and blank `accountant_pix_key`, and a missing-document Payment whose history is `Pix 390.533.447-05`, and no unmatched SupportingDocument, then that payment’s row includes `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET tax id digits in history includes Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "tax id digit form hits history digits"`

**C45** - Given `accountant_pix_key` `ana@example.com` and a missing-document Payment whose history is `Pix Ana@Example.com`, and no unmatched SupportingDocument, then that payment’s row includes `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET PIX email case-insensitive includes Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "PIX email downcased is a substring of history"`

**C46** - Given `accountant_pix_key` `51999999999` and a missing-document Payment whose history is `Pix +55 51 99999-9999`, and no unmatched SupportingDocument, then that payment’s row includes `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET PIX phone digits includes Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "PIX with digits hits digit-only history"`

**C47** - Given `accountant_pix_key` `f9c8d7e6-1234-4abc-9def-0123456789ab` and a missing-document Payment whose history contains `F9C8D7E6-1234-4ABC-9DEF-0123456789AB`, and no unmatched SupportingDocument, then that payment’s row includes `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET PIX uuid digits includes Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "PIX uuid with digits hits digit-only history"`

**C48** - Given two missing-document Payments whose histories both include `chave-pix`, `accountant_pix_key` `chave-pix`, and no unmatched SupportingDocument, then both payment rows include `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET two PIX hits both include Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "two PIX hits are two proposals"`

**C49** - Given `accountant_presentation_name` `Ana Contadora`, blank PIX, blank tax id, and a missing-document Payment whose history is `Pix Ana Contadora`, then that payment’s row does not include `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET presentation name does not include Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "presentation name never hits"`

**C50** - Given `accountant_legal_name` `Ana Contabilidade LTDA`, blank PIX, blank tax id, and a missing-document Payment whose history includes that razão social, then that payment’s row does not include `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET razao social does not include Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "legal name never hits"`

**C51** - Given blank PIX and blank tax id, and a missing-document Payment whose history is `Pix 390.533.447-05`, then that payment’s row does not include `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET empty PIX and tax id omits Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "blank PIX and tax id never proposes"`

**C52** - Given `accountant_pix_key` `chave-pix`, a missing-document Payment of `22000` cents whose history is `Pix enviado chave-pix — Padaria Central`, and an unmatched SupportingDocument of `22000` cents payee `Padaria Central`, then that payment’s row includes `Sugestão` and `Padaria Central` and does not include `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET match suggestion suppresses Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "match suggestion suppresses exception suggestion"`

**C53** - Given `accountant_pix_key` `chave-pix`, a missing-document Payment of `50000` cents whose history is `Pix enviado chave-pix`, and the only unmatched SupportingDocument is `20000` cents, then that payment’s row includes `Sugestão` and does not include `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET lesser match suggestion suppresses Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "lesser match suggestion suppresses exception suggestion"`

**C54** - Given a missing-document Payment whose history is `Tarifa Pacote de Serviços`, blank PIX, blank tax id, then that payment’s row does not include `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET tarifa history omits Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "tarifa history without PIX does not propose"`

**C55** - When a coordinator POSTs `kind=bank_fee` on a payment whose row includes `Sugestão de exceção`, then that row includes `Tarifa bancária` and does not include `Sugestão de exceção` or `Documento faltante`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST bank_fee while exception suggestion showing marks Tarifa bancaria"`

**C56** - Always, `GET /months/2026-05` does not include `Sugestão de exceção` for an extra exception kind
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET extra exception kind is not Sugestao de excecao"`
Proof: `bin/rspec spec/models/exception_suggestion_spec.rb -e "never proposes an extra exception kind"`

### S6 - Isolation, closed month, submitter · 6 files · 71 KB · ~18k

**C57** - While focus is organization A, `GET /months/2026-05` does not include `Sugestão` of a payee that exists only on organization B’s unmatched SupportingDocument of the same cents
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET org A omits Sugestao of org B payee"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "does not assign another organization document"`

**C58** - When Month `2026-05` is closed, then `GET /months/2026-05` does not include `Sugestão` or `Sugestão de exceção`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET closed month omits Sugestao and Sugestao de excecao"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "closed month payments are not assigned"`

**C59** - If a submitter GETs `/months/2026-05` of an organization whose payment history is `PIX Isolado` and whose unmatched document payee is `Padaria Central`, then the response is `404` and the body does not include `PIX Isolado`, `Sugestão`, or `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "submitter GET omits PIX Isolado Sugestao and Padaria Central"`

**C60** - When a submitter of that organization has inserted unmatched SupportingDocument payee `Padaria Central` of `22000` cents, then a coordinator `GET /months/2026-05` of the payment whose history contains `Padaria Central` and amount `22000` includes `Sugestão` and `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "coordinator GET includes Sugestao of submitter document"`

**C61** - When a coordinator DELETEs the Match that those ids confirmed, then `GET /months/2026-05` includes `Documento faltante` and `Sugestão` and `Padaria Central` on that payment again
Proof: `bin/rspec spec/requests/matches_spec.rb -e "DELETE match restores Sugestao on the payment"`

**C62** - When a coordinator PATCHes that unmatched document’s payee from `Padaria Central` to `Mercado Silva` while two `22000`-cent payments have histories `Pix enviado — Padaria Central` and `Pix enviado — Mercado Silva`, then `GET /months/2026-05` includes `Sugestão` on the Mercado Silva payment and does not include `Sugestão` on the Padaria payment
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH payee reassigns Sugestao to Mercado Silva payment"`

**C63** - When a coordinator clears `accountant_pix_key` and `accountant_tax_id`, then `GET /months/2026-05` of the payment whose history still contains `chave-pix` does not include `Sugestão de exceção`
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "clearing PIX and tax id omits Sugestao de excecao"`

### S7 - Suggested ids are selected on confirm · 3 files · 32 KB · ~8k

**C64** - Given the 1:1 of criterion 1, when a coordinator GETs `/months/2026-05`, then that payment’s `POST /months/2026-05/matches` form includes that Payment id and that SupportingDocument id as selected (`checked` checkbox or `type="hidden"` input named `payment_ids[]` / `supporting_document_ids[]`)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET 1:1 form selects payment id and document id"`

**C65** - Given that same 1:1 and a second unmatched SupportingDocument payee `Mercado Silva`, then `Mercado Silva` is not selected on that payment’s match form
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET 1:1 form does not select Mercado Silva"`

**C66** - Given the format-2 of criterion 26, when a coordinator GETs `/months/2026-05`, then the page includes both Payment ids and that SupportingDocument id as selected toward `POST /months/2026-05/matches`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET format-2 selects both payment ids and the document id"`

**C67** - Given the Justification of criterion 32, when a coordinator GETs `/months/2026-05`, then that payment’s match form includes both member SupportingDocument ids as selected
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET justification form selects both member document ids"`

## Swept

- validation: C20, C22, C23, C24, C30, C44, C45, C46, C47 - name hit including accent fold; amount rank; match shape; PIX/tax-id normalize
- failure modes: C25, C39, C42, C57, C58, C59
- idempotency and retry: C1, C3 - a second GET still shows the same derived suggestion; a second confirm is existing `422` `Pagamento já está em um casamento`
- authorization: C59, C60
- concurrency and ordering: C13, C16, C17, C20, C21 - assignment is deterministic (name including accent fold, then lowest id); two concurrent confirms of the same ids are existing Match uniqueness
- data lifecycle: C11, C61, C62, C63 - derived at GET; insert, leave-match, payee PATCH, and clearing PIX/tax id change the next GET; nothing to backfill or delete
- external-dependency failure: n/a - no new remote; Drive writer and Google OIDC are unchanged
- state transitions: C1, C3, C27, C33, C40, C43, C55, C61
- observability: n/a - no operator metric or log line is required; Rails request logging already covers HTML

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| assignment rank (4) | equal C1 · format-2 C26 · greater C23 · lesser C24 | - |
| rank precedence (3) | equal > greater C22 · greater > lesser C23 · equal > format-2 C28 | - |
| within-rank tie-break (4) | name hit C12 · accent fold C20 · lowest payment id C13 · lowest document id C15 | - |
| open-month assignment (3) | name across months C16 · lowest payment id across months C17 · date is not a gate C18 | - |
| suggestion shapes (4) | 1:1 C1 · 1:N justification C32 · 2:1 C26 · not 3+ C31 · not N×M C35 | - |
| at-most-one (2) | per Payment C21 · per SupportingDocument C21 | - |
| document kinds (2) | recibo C8 · nota_fiscal with XML C9 | - |
| justification amount key (3) | equal on `amount_cents` C32 · members not individuals C34 · key 18000 vs members 20000 C36 | - |
| PIX/tax-id hit (5) | random key C40 · tax id C44 · email C45 · phone digits C46 · UUID digits C47 | - |
| PIX/tax-id miss (4) | presentation name C49 · razão social C50 · empty catalog C51 · tarifa text C54 | - |
| exception vs match (3) | equal suppresses C52 · lesser suppresses C53 · two hits two proposals C48 | - |
| isolation / closed / submitter (4) | other org C57 · closed C58 · submitter 404 C59 · submitter insert still suggests C60 | - |
| selected ids (4) | 1:1 C64 · not the other doc C65 · format-2 C66 · justification members C67 | - |
| confirm from suggestion (6) | equal 1:1 C3 · lesser 422 C25 · format-2 C27 · justification equal C33 · justification greater persist C37 · justification lesser 422 C39 | - |
| extra kind not exception-suggested (1) | C56 | - |
| inflows / empty (2) | inflows C7 · zero payments C6 | - |
| startup config assemblies | no new process setting | - |

- Claims naming a status code, route or response shape: C1–C7, C10, C11, C25, C27, C33, C37, C39, C40–C43, C55, C57–C67 - each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~23k + S2 ~18k + S3 ~17k + S4 ~20k = ~78k (match assignment, month page). S5 enters exception PIX/tax-id at ~28k (running ~106k). S6 ~18k + S7 ~8k = ~132k floor. All seven slices stay under 150k. Surface changes at S5 (NormalizedEmail / BrazilianTaxId / accountant fields) but the running total never reaches the budget, so no split.

Boundary: S1–S4 closed at `7cf30f3` (S3) plus the S4 commit on this branch; remaining is S5–S7 (C40–C67).
User settled mid-build: none.
Abandoned: none. `Suggestion.assign` already ranks equal / format-2 / greater / lesser and groups Justification members. Do not re-derive that. S5 is a new `ExceptionSuggestion` PORO; match suggestion on a payment suppresses it, including lesser 1:1. S7 preselects ids on the existing `POST /matches` forms (per-payment checkboxes for 1:1 and justification; N:1 form for format-2).
