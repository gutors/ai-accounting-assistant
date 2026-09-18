# Assisted suggestions Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: `56424dc3104bbdba014bbc7abddf85082d763c18..7b2a9cafea8ac894f21ded3bc6b35949f77ec661`
**Round**: 2 - full
**Verifier**: independent sub-agent (author != verifier)

Step 1 (binding screens) skipped: no source marked binding. Checklist: "No design source for the screens."

## Binding sources

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| (none marked binding) | n/a | n/a | n/a |

## Checks

Batched proof run at `7b2a9ca` (one invocation, 114 named examples from the checklist `-e` strings): 114 examples, 0 failures. Each named example appeared in the documentation formatter output.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | GET 1:1 equal 200, Sugestão, Documento faltante, Padaria Central | batched `-e` hit, exit 0 | `months_spec.rb:392` `have_http_status(:ok)`; `:394-396` `include("Documento faltante")` / `"Sugestão"` / `"Padaria Central"`; `suggestion_spec.rb:35-37` `be_present` and ids equal | PASS |
| C2 | GET leaves Payment unmatched and document without month | batched `-e` hit, exit 0 | `months_spec.rb:409-413` `match_id` / `document_exception_kind` / `extra_exception_kind_id` / `month_id` / `match_id` `be_nil`; `suggestion_spec.rb:46-51` `Match.count` `eq(0)` and same nils | PASS |
| C3 | POST 1:1 equal persists Match, 302, Casado, omits Sugestão | batched `-e` hit, exit 0 | `matches_spec.rb:100-102` `:found`, `redirect_to("/months/2026-05")`, `Match.count` `eq(1)`; `:106-109` `include("Casado")`, `not_to include("Sugestão")` | PASS |
| C4 | GET /supporting_documents includes Casado em 2026-05 | batched `-e` hit, exit 0 | `supporting_documents_spec.rb:446` `include("Casado em 2026-05")` | PASS |
| C5 | no unmatched document: Documento faltante, omits Sugestão | batched `-e` hit, exit 0 | `months_spec.rb:423-424` `include("Documento faltante")`, `not_to include("Sugestão")`; `suggestion_spec.rb:57-58` `be_nil` / `be_empty` | PASS |
| C6 | zero Payments omits Sugestão | batched `-e` hit, exit 0 | `months_spec.rb:435` `not_to include("Sugestão")` | PASS |
| C7 | Recebimentos omits Sugestão and Sugestão de exceção | batched `-e` hit, exit 0 | `months_spec.rb:448-449` `not_to include("Sugestão")` / `not_to include("Sugestão de exceção")` | PASS |
| C8 | recibo 1:1 includes Sugestão and Padaria Central | batched `-e` hit, exit 0 | `months_spec.rb:460-462` `include("Sugestão")`, `kind` `eq("recibo")`; `suggestion_spec.rb:65-66` documents eq, kind recibo | PASS |
| C9 | nota_fiscal with XML 1:1 includes Sugestão | batched `-e` hit, exit 0 | `months_spec.rb:472-476` `include("Sugestão")`, `kind` `eq("nota_fiscal")`, `xml` `be_attached`; `suggestion_spec.rb:73-75` same | PASS |
| C10 | unmatched pool still includes Padaria Central | batched `-e` hit, exit 0 | `months_spec.rb:487-489` status includes Sugestão; `pool_html` `include("Padaria Central")` | PASS |
| C11 | later document insert then GET includes Sugestão | batched `-e` hit, exit 0 | `months_spec.rb:502-503` `include("Sugestão")`; `suggestion_spec.rb:84` supporting_documents eq | PASS |
| C12 | value tie name hit assigns Padaria not Mercado | batched `-e` hit, exit 0 | `months_spec.rb:516-518` padaria includes Sugestão, mercado `not_to include`; `suggestion_spec.rb:92-93` same | PASS |
| C13 | two name-hit equals: lower-id payment only | batched `-e` hit, exit 0 | `months_spec.rb:532-534` `suggested.size` `eq(1)`, first id, not second; `suggestion_spec.rb:101-103` `first.id` `<` `second.id`, second `be_nil` | PASS |
| C14 | two equal docs name hit picks Padaria Central | batched `-e` hit, exit 0 | `months_spec.rb:546-548` includes Padaria Central, `not_to include("Mercado Silva")`; `suggestion_spec.rb:112-113` | PASS |
| C15 | two equal docs no name hit: lower-id Padaria Norte | batched `-e` hit, exit 0 | `months_spec.rb:561-563` Norte not Sul; `suggestion_spec.rb:121-122` `norte.id` `<` `sul.id`, documents eq norte | PASS |
| C16 | cross-month name hit assigns May not June | batched `-e` hit, exit 0 | `months_spec.rb:574` May includes Sugestão; `:577` June `not_to include`; `suggestion_spec.rb:130-131` | PASS |
| C17 | cross-month no name hit: lower-id payment month | batched `-e` hit, exit 0 | `months_spec.rb:592` lower month includes; `:595` other `not_to include`; `suggestion_spec.rb:141-142` | PASS |
| C18 | document_on before occurred_on still assigned | batched `-e` hit, exit 0 | `months_spec.rb:606-607` includes Sugestão / Padaria Central; `suggestion_spec.rb:149-150` assigned, `document_on` `eq(Date.new(2026, 4, 30))` | PASS |
| C19 | equal with no name hit still assigns | batched `-e` hit, exit 0 | `months_spec.rb:618-619` includes Sugestão / Padaria Central; `suggestion_spec.rb:157` | PASS |
| C20 | accent-fold José Silva / JOSE SILVA | batched `-e` hit, exit 0 | `months_spec.rb:632-634` jose includes `José Silva`, mercado `not_to include("Sugestão")`; `suggestion_spec.rb:165-166` | PASS |
| C21 | at most one suggestion per Payment and document | batched `-e` hit, exit 0 | `suggestion_spec.rb:174` count `eq(1)` for payment; `:182` count `eq(1)` for document | PASS |
| C22 | equal beats greater even when greater has name hit | batched `-e` hit, exit 0 | `months_spec.rb:646-649` copy after Sugestão includes Padaria Central, `not_to include("Mercado Silva")`; `suggestion_spec.rb:190` | PASS |
| C23 | greater beats lesser | batched `-e` hit, exit 0 | `months_spec.rb:661-663` Padaria Grande not Pequena; `suggestion_spec.rb:198` | PASS |
| C24 | lesser 1:1 assigned | batched `-e` hit, exit 0 | `months_spec.rb:674-675` Sugestão / Padaria Central; `suggestion_spec.rb:205` | PASS |
| C25 | POST lesser blank observation 422 + copy | batched `-e` hit, exit 0 | `matches_spec.rb:121-123` `:unprocessable_content`, `include("Informe a observação do casamento")`, `Match.count` `eq(0)` | PASS |
| C26 | format-2 both payments include Sugestão | batched `-e` hit, exit 0 | `months_spec.rb:688-691` both rows include Sugestão / Padaria Central; `suggestion_spec.rb:217-219` both payment ids | PASS |
| C27 | POST format-2 Casado on both, omits Sugestão | batched `-e` hit, exit 0 | `matches_spec.rb:136-145` `Match.count` `eq(1)`, both `include("Casado")`, `not_to include("Sugestão")` | PASS |
| C28 | equal beats format-2 | batched `-e` hit, exit 0 | `months_spec.rb:703-705` equal includes Sugestão, 10000 `not_to include`; `suggestion_spec.rb:229-230` | PASS |
| C29 | format-2 name hit beats no name hit | batched `-e` hit, exit 0 | `months_spec.rb:718-721` Padaria pair includes, Outro `not_to include`; `suggestion_spec.rb:240-243` | PASS |
| C30 | shape is 1:N or exactly 2:1 | batched `-e` hit, exit 0 | `suggestion_spec.rb:256-257` `one_to_many \|\| two_to_one` `eq(true)` | PASS |
| C31 | does not group three payments as one suggestion | batched `-e` hit, exit 0 | `suggestion_spec.rb:268` `payments.size < 3` settles the assign claim; HTTP `months_spec.rb:736` `be < 3` is a weaker companion (row count, not grouping identity) | PASS |
| C32 | justification equal both payees + Documento faltante | batched `-e` hit, exit 0 | `months_spec.rb:758-761` Sugestão, both payees, Documento faltante; `suggestion_spec.rb:286` `contain_exactly` both ids | PASS |
| C33 | POST justification equal Casado both payees | batched `-e` hit, exit 0 | `matches_spec.rb:164-172` `:found`, `Match.count` `eq(1)`, Casado, both payees, not Sugestão | PASS |
| C34 | justification member not assigned as individual | batched `-e` hit, exit 0 | `months_spec.rb:775` member `not_to include("Sugestão")`; `suggestion_spec.rb:297` `be_nil` | PASS |
| C35 | multi-document justification never format-2 | batched `-e` hit, exit 0 | `suggestion_spec.rb:310,315` two-and-two / together `be_nil`; HTTP `months_spec.rb:791` `be < 2` companion | PASS |
| C36 | justification amount_cents 18000 is the equal key | batched `-e` hit, exit 0 | `months_spec.rb:804-806` both payees; `suggestion_spec.rb:324` both ids | PASS |
| C37 | POST members greater than payment persists Match | batched `-e` hit, exit 0 | `matches_spec.rb:191-192` `:found`, `Match.count` `eq(1)` | PASS |
| C38 | justification 22000 with members 20000 includes Sugestão | batched `-e` hit, exit 0 | `months_spec.rb:819-821` Sugestão and both payees; `suggestion_spec.rb:333` | PASS |
| C39 | POST justification lesser 422 + observation copy | batched `-e` hit, exit 0 | `matches_spec.rb:211-213` `:unprocessable_content`, `include("Informe a observação do casamento")`, `Match.count` `eq(0)` | PASS |
| C40 | PIX chave-pix: Sugestão de exceção, not Honorário | batched `-e` hit, exit 0 | `months_spec.rb:835-839` `:ok`, `include("Sugestão de exceção")`, `not_to include("Honorário do contador")`; `exception_suggestion_spec.rb:36` `kind` `eq("accountant_fee")` | PASS |
| C41 | GET leaves document_exception_kind nil | batched `-e` hit, exit 0 | `months_spec.rb:850` `be_nil`; `exception_suggestion_spec.rb:46` `be_nil` | PASS |
| C42 | POST close while exception suggestion showing 422 | batched `-e` hit, exit 0 | `close_spec.rb:26-28` `:unprocessable_content`, `include("Há documento faltante")`, `closed?` `eq(false)` | PASS |
| C43 | POST accountant_fee shows Honorário, omits suggestion | batched `-e` hit, exit 0 | `document_exceptions_spec.rb:321-323` `include("Honorário do contador")`, `not_to include("Sugestão de exceção")` | PASS |
| C44 | tax id digits in history | batched `-e` hit, exit 0 | `months_spec.rb:861` `include("Sugestão de exceção")`; `exception_suggestion_spec.rb:53` `kind` `eq("accountant_fee")` | PASS |
| C45 | PIX email case-insensitive | batched `-e` hit, exit 0 | `months_spec.rb:872` include; `exception_suggestion_spec.rb:60` kind accountant_fee | PASS |
| C46 | PIX phone digits | batched `-e` hit, exit 0 | `months_spec.rb:881` include; `exception_suggestion_spec.rb:67` kind accountant_fee | PASS |
| C47 | PIX uuid digits | batched `-e` hit, exit 0 | `months_spec.rb:893` include; `exception_suggestion_spec.rb:74` kind accountant_fee | PASS |
| C48 | two PIX hits are two proposals | batched `-e` hit, exit 0 | `months_spec.rb:905-906` both include; `exception_suggestion_spec.rb:84` `proposals.size` `eq(2)` | PASS |
| C49 | presentation name never hits | batched `-e` hit, exit 0 | `months_spec.rb:917` `not_to include("Sugestão de exceção")`; `exception_suggestion_spec.rb:91` `be_nil` | PASS |
| C50 | razão social never hits | batched `-e` hit, exit 0 | `months_spec.rb:927` `not_to include`; `exception_suggestion_spec.rb:98` `be_nil` | PASS |
| C51 | blank PIX and tax id never proposes | batched `-e` hit, exit 0 | `months_spec.rb:938` `not_to include`; `exception_suggestion_spec.rb:104` `be_nil` | PASS |
| C52 | match suggestion suppresses exception suggestion | batched `-e` hit, exit 0 | `months_spec.rb:950-952` Sugestão / Padaria Central, `not_to include("Sugestão de exceção")`; `exception_suggestion_spec.rb:112` `be_nil` | PASS |
| C53 | lesser match suggestion suppresses exception suggestion | batched `-e` hit, exit 0 | `months_spec.rb:964-965` Sugestão, `not_to include("Sugestão de exceção")`; `exception_suggestion_spec.rb:120` `be_nil` | PASS |
| C54 | tarifa history omits exception suggestion | batched `-e` hit, exit 0 | `months_spec.rb:975` `not_to include`; `exception_suggestion_spec.rb:126` `be_nil` | PASS |
| C55 | POST bank_fee while exception suggestion showing | batched `-e` hit, exit 0 | `document_exceptions_spec.rb:335-337` `include("Tarifa bancária")`, `not_to include("Sugestão de exceção")` | PASS |
| C56 | extra kind is not Sugestão de exceção | batched `-e` hit, exit 0 | `months_spec.rb:986` `not_to include("Sugestão de exceção")`; `exception_suggestion_spec.rb:134-135` `kind` `eq("accountant_fee")` only | PASS |
| C57 | org A omits org B payee suggestion | batched `-e` hit, exit 0 | `months_spec.rb:1003-1004` `not_to include("Sugestão")` / `not_to include("Padaria Beta Isolada")`; `suggestion_spec.rb:342-343` | PASS |
| C58 | closed month omits both suggestion copies | batched `-e` hit, exit 0 | `months_spec.rb:1016-1017` `not_to include("Sugestão")` / `not_to include("Sugestão de exceção")`; `suggestion_spec.rb:352` `be_nil` | PASS |
| C59 | submitter GET 404 omits PIX Isolado, Sugestão, payee | batched `-e` hit, exit 0 | `months_spec.rb:1030-1033` `:not_found`, `not_to include("PIX Isolado")` / `"Sugestão"` / `"Padaria Central"` | PASS |
| C60 | coordinator GET includes submitter document suggestion | batched `-e` hit, exit 0 | `months_spec.rb:1050-1051` `include("Sugestão")` / `include("Padaria Central")` | PASS |
| C61 | DELETE match restores Sugestão | batched `-e` hit, exit 0 | `matches_spec.rb:539-541` Documento faltante, Sugestão, Padaria Central | PASS |
| C62 | PATCH payee reassigns to Mercado Silva payment | batched `-e` hit, exit 0 | `supporting_documents_spec.rb:719-720` mercado includes Sugestão, padaria `not_to include` | PASS |
| C63 | clearing PIX and tax id omits exception suggestion | batched `-e` hit, exit 0 | `accountants_spec.rb:179` `not_to include("Sugestão de exceção")` | PASS |
| C64 | 1:1 form selects payment id and document id | batched `-e` hit, exit 0 | `months_spec.rb:1062-1063` `selected_named_values` includes payment id and document id on the payment row form | PASS |
| C65 | 1:1 form does not select Mercado Silva | batched `-e` hit, exit 0 | `months_spec.rb:1075` `not_to include(mercado.id.to_s)` on that payment's form | PASS |
| C66 | format-2 N:1 form selects both payment ids and the document id | batched `-e` hit, exit 0 | `months_spec.rb:1086-1089` `n1_match_form_html` (submit `Confirmar casamento N:1`), `include("/months/2026-05/matches")`, selected `payment_ids[]` both ids, selected `supporting_document_ids[]` the document; `suggestion_spec.rb:361` `format_2_for_n1_form([proposal])` `eq(proposal)` | PASS |
| C67 | justification form selects both member document ids | batched `-e` hit, exit 0 | `months_spec.rb:1125` both member ids included on that payment's form | PASS |
| C68 | two 2:1s: N:1 form selects the pair with lowest payment id | batched `-e` hit, exit 0 | `months_spec.rb:1103-1111` N:1 form selects 10000/12000 and Padaria, not 14000/16000 or Mercado; `suggestion_spec.rb:374-375` `ten.id` `<` `fourteen.id`, `format_2_for_n1_form` `eq(padaria_pair)` | PASS |

## Coverage (recomputed)

Members taken from `Suggestion::RANK`, `candidates_for` / `sorted_candidates`, `pix_hit?` / `tax_id_hit?`, `SupportingDocument` kind enum, and Landing enumerations — not from the author's table.

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| assignment rank (4) from `Suggestion::RANK` | equal C1 · format_2 C26 · greater C23 · lesser C24 | - |
| rank precedence | equal > greater C22 · greater > lesser C23 · equal > format-2 C28 | format-2 > greater is implied by C26 (no equal payment; format-2 consumes both), not a named opposite-arm example |
| within-rank tie-break from `sorted_candidates` | name hit C12 · accent fold C20 · lowest payment id C13 · lowest document/`tie_id` C15 | Landing name-hit pipeline also names collapsed whitespace; no example plants extra spaces |
| open-month assignment | name across months C16 · lowest payment id C17 · date not a gate C18 | Landing "format-2 never spans Months" has no negative example (assign groups by `month_id`; C26 is same-month) |
| suggestion shapes | 1:1 C1 · 1:N C32 · 2:1 C26 · not 3+ C31 · not N×M C35 | - |
| at-most-one | Payment C21 · SupportingDocument C21 | - |
| document kinds from `SupportingDocument` enum (2) | recibo C8 · nota_fiscal+XML C9 | - |
| justification amount key | equal on `justification.amount_cents` C32 · members not individuals C34 · key 18000 vs members 20000 C36 | - |
| PIX/tax-id hit from `pix_hit?` / `tax_id_hit?` | else-substring C40 · tax id C44 · email C45 · digit arm C46 · digit arm UUID C47 | - |
| PIX/tax-id miss | presentation name C49 · legal name C50 · empty catalog C51 · tarifa C54 | - |
| exception vs match | equal suppresses C52 · lesser suppresses C53 · two hits C48 | - |
| isolation / closed / submitter | other org C57 · closed C58 · submitter 404 C59 · submitter insert C60 | ExceptionSuggestion closed-month skip has no own-layer example (HTTP C58 covers copy; `Suggestion` model C58 covers match assign) |
| selected ids | 1:1 C64 · not the other doc C65 · format-2 N:1 form C66 · justification members C67 · two 2:1 lowest payment id C68 | - |
| N:1 form winner (2) | single 2:1 C66 · two 2:1s lowest min payment id C68 | - |
| confirm from suggestion | equal 1:1 C3 · lesser 422 C25 · format-2 C27 · justification equal C33 · justification greater C37 · justification lesser 422 C39 | - |
| extra kind not exception-suggested | C56 (`KIND = "accountant_fee"`) | - |
| inflows / empty | inflows C7 · zero payments C6 | - |
| startup config assemblies | no new process setting | - |

Claims naming a status/route/response shape have a request-spec assertion at that boundary (C1–C7, C10, C11, C25, C27, C33, C37, C39, C40–C43, C55, C57–C68). C66 now reads selected ids from the N:1 form, not the whole page.

Unproven Landing notes above are pipeline/negative members with no dedicated check; they do not leave a checklist member without a proof.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/suggestion.rb` (rank, name hit, at-most-one, shapes, `format_2_for_n1_form`); `app/models/exception_suggestion.rb` (PIX/tax-id arms, suppression, kind) | model + request; one asserted case per member | yes — rank/PIX/suppression members have model examples and GET copy proofs; N:1 picker has model C66/C68 and request C66/C68 |
| Decides, not reached across a boundary | none in this change | own layer | no files |
| Entry point that decides nothing | `MonthsController#show`, `MatchesController`, `DocumentExceptionsController` | request: status / who may call / copy | yes — C1/C59/C3/C43/C55 |
| Instrumentation / pass-through | `months/show.html.erb` copy; `load_month_page` wiring; `ApplicationController#format_2_suggestion_on_month` forwards `Suggestion.format_2_for_n1_form` | consumer | yes — copy C1/C40; N:1 preselect is decided on `Suggestion` and consumed by C66/C68 (round-1 gap closed) |

`.cursor/rules/rails.mdc` 49–51 is the allocation the rows follow.

## Swept existing

- Close missing-document: `Month::MISSING_DOCUMENT` `app/models/month.rb:5` `"Há documento faltante"` — C42 reuses it.
- Second confirm: `Match::PAYMENT_TAKEN` `app/models/match.rb:7`; lock+check `app/models/match.rb:80-82`; request `spec/requests/matches_spec.rb:277`; model `spec/models/match_spec.rb:120`.
- `Payment#missing_document?` still `match_id` / `document_exception_kind` / `extra_exception_kind_id` all nil (`app/models/payment.rb:16-18`).

## Faults injected

Scratch: `git worktree add /tmp/caa-assisted-suggestions-verify-r2 HEAD`. Real-tree porcelain before and after: `M AGENTS.md`, `M README.md`, `?? .checks/assisted-suggestions.verified.md`, `?? .tasks/sefaz-certificate-and-consulta.md`. Worktree removed.

| Mutation | Location | Killed |
|---|---|---|
| skip equal-amount candidates (`next` on `amount_cents == amount_key`) | `suggestion.rb` `candidates_for` | yes — `equal 1:1 name hit assigns Padaria Central` (`suggestion_spec.rb:35`) |
| `hit?` always `false` | `exception_suggestion.rb` | yes — `PIX substring hit proposes accountant_fee` (`exception_suggestion_spec.rb:35`) |
| drop `next if covered[payment.id]` | `exception_suggestion.rb` `proposals` | yes — `match suggestion suppresses exception suggestion` (`exception_suggestion_spec.rb:112`) |
| omit the `Sugestão` copy, keep payees | `months/show.html.erb` | yes — `GET 1:1 equal Padaria Central includes Sugestao and Documento faltante` (`months_spec.rb:395`) |
| `format_2_suggestion_on_month` returns `nil` | `application_controller.rb` | yes — `GET format-2 N:1 form selects both payment ids and the document id` (`months_spec.rb:1088` expected selected ids, got `[]`) |

## Gate

`bin/rspec` on the eight proof files with all 114 checklist `-e` names — **114 passed, 0 failed**.

Named examples exist (`it "…"` hits in those files) and appeared in that run (114/114, no empty filter).
