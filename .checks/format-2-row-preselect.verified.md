# Format-2 row preselect Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: `0b0151b610497989b18d14b385922d6a949dbb52..04103a33e9d4e7960a44c017027ebb7a108a163d`
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

Step 1 (binding screens) skipped: no source marked binding. Checklist: "No design source for the screens."

## Binding sources

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| (none marked binding) | n/a | n/a | n/a |

## Checks

Batched proof run at `04103a3` (one invocation: `env -u BUNDLE_PATH bin/rspec spec/requests/months_spec.rb spec/models/suggestion_spec.rb` with the seven checklist `-e` strings): **7 examples, 0 failures**. The include filter listed all seven full descriptions; each example exists in the tree (`rg -n`); 7 filters / 7 examples / no overlapping names, so each named proof ran.

Proofs are in the feature diff (`spec/requests/months_spec.rb`, `spec/models/suggestion_spec.rb`), not an untouched earlier suite.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | GET `/months/2026-05` 2:1: neither 10000 nor 12000 `Confirmar casamento` form selects Padaria Central | batched `-e` hit, exit 0 | `months_spec.rb:1134` `get "/months/2026-05"`; `:1138-1139` `selected_named_values(..., "supporting_document_ids[]").not_to include(document.id.to_s)` on both Dez and Doze rows | PASS |
| C2 | POST 1:1 form as shown: no Match, `422`, `Selecione ao menos um documento`, both rows still `Documento faltante` and `Sugestão` | batched `-e` hit, exit 0 | `months_spec.rb:1150` `post "/months/2026-05/matches"`; `:1155` `have_http_status(:unprocessable_content)` (422); `:1156` `include("Selecione ao menos um documento")`; `:1157` `Match.count` `eq(0)`; `:1162-1165` both statuses `include("Documento faltante")` and `include("Sugestão")` | PASS |
| C3 | GET 1:1 with one payment selects Padaria Central | batched `-e` hit, exit 0 | `months_spec.rb:1173` `get "/months/2026-05"`; `:1176` `selected_named_values(form, "supporting_document_ids[]").to include(document.id.to_s)` | PASS |
| C4 | GET justification 1:N selects both Padaria Central and Mercado Silva | batched `-e` hit, exit 0 | `months_spec.rb:1186` `get "/months/2026-05"`; `:1190` `include(padaria.id.to_s, mercado.id.to_s)` | PASS |
| C5 | `one_to_one_form_document_ids` for 1:1 is `[document.id]` | batched `-e` hit, exit 0 | `suggestion_spec.rb:383` `eq([ document.id ])` | PASS |
| C6 | `one_to_one_form_document_ids` for 2:1 is `[]` | batched `-e` hit, exit 0 | `suggestion_spec.rb:392` `eq([])` | PASS |
| C7 | `one_to_one_form_document_ids` for 1:N is both document ids | batched `-e` hit, exit 0 | `suggestion_spec.rb:401` `eq([ padaria.id, mercado.id ])` | PASS |

## Coverage (recomputed)

Authority for the three preselect shapes is the checklist Test policy / Coverage set (1:1, 1:N, 2:1), not a provider enum. Code under that set (`Suggestion#one_to_one_form_document_ids`): `return [] unless payments.size == 1` then `supporting_documents.map(&:id)`.

| Set (size) | Members from authority | Proof that asserts the member | Unproven |
|---|---|---|---|
| 1:1 form preselect shapes (3) | 1:1 · 1:N · 2:1 empty | 1:1 C3 HTTP + C5 `eq([ document.id ])` · 1:N C4 HTTP + C7 `eq([ padaria.id, mercado.id ])` · 2:1 C1 HTTP not selected + C6 `eq([])` | none |
| POST of 1:1 form as shown on 2:1 (1) | empty selected docs | C2 422 / `NO_DOCUMENTS` copy / `Match.count` 0 / both unmatched | none |
| startup config assemblies | no new process setting (diff is suggestion helper, month 1:1 form, two specs, checklist) | n/a | none |

Sweep of sets named in Landing / Test policy / claims with no Coverage row: `covers_payment?` / `suggested_document?` / `format_2_for_n1_form` are reused N:1 preselect (out of scope). `Match.confirm` `NO_DOCUMENTS` is C2’s message. No hidden enumeration.

Claims naming a status, route or response shape (C1–C4) each have a request-spec proof at HTTP. C5–C7 sit at the model layer that owns the branch table. No level gap. No precision gap: cents, payees, `422`, `[]`, and both ids are literal at the assertion.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/suggestion.rb` `#one_to_one_form_document_ids` | model + request; one asserted case per member (1:1, 1:N, 2:1); status / who may call at the boundary | yes — C5/C6/C7 one model case each; C3/C4/C1 GET selected ids; C2 POST `422`. Who-may-call is existing `months_spec` unauthenticated GET 302 and `matches_spec` unauthenticated POST 302, not a new endpoint |
| Decides, not reached across a boundary | none in this cut | one at the model layer | n/a — no files |
| Entry point that decides nothing | `MonthsController#show` (pass-through `load_month_page`); `MatchesController#create` (existing `Match.confirm`) | request spec; accepted / rejected / error for this cut’s new input | yes — GET HTML C1/C3/C4; POST of the 1:1 form as shown C2. Hand-checked greater 1:1 remains out of scope |
| Instrumentation / pass-through | `app/views/months/show.html.erb` forwards `one_to_one_form_document_ids` into `check_box_tag` | none of its own; consumer | yes — C1/C3/C4 consume the checked `supporting_document_ids[]` |

## Swept existing (re-read)

- idempotency / retry: `load_month_page` → `suggestions_on_month` → `match_proposals_for_page` calls `Suggestion.assign(@organization)` per request (`application_controller.rb:76,90-99,116-117`); nothing persisted. Second confirm of taken ids: `Match#persist_confirm` `errors.add(:base, PAYMENT_TAKEN)` (`match.rb:7,80-82`) — copy `"Pagamento já está em um casamento"`. Present.
- authorization: `MonthsController` and `MatchesController` both `before_action :require_coordinator_organization` (line 2 each); `ApplicationController#require_coordinator_organization` (`application_controller.rb:40-46`) 302 without focus, 404 unless coordinator. Present.
- n/a rows (concurrency, data lifecycle, external-dependency, observability): policy; nothing in the code to be wrong about.

## Faults injected

Scratch: `git worktree add /tmp/format-2-row-preselect-verify HEAD`. Real-tree porcelain recorded first; scratch discarded after; porcelain unchanged (` M AGENTS.md`, ` M README.md`, `?? .tasks/sefaz-certificate-and-consulta.md`).

One fault per distinct assertion surface, cap 5. C2 shares the 2:1-not-preselected surface with C1 (view revert would POST a selected document). C4 shares 1:N cardinality with C7 and GET checked-state with C3.

| Mutation | Location | Covering proof | Killed |
|---|---|---|---|
| 1:1 form `suggested_ids` back to `supporting_documents.map(&:id)` | `app/views/months/show.html.erb:99` | C1 | yes — `months_spec.rb:1138` expected not to include the document id |
| drop `return [] unless payments.size == 1` | `app/models/suggestion.rb:30-33` | C6 | yes — `suggestion_spec.rb:392` expected `[]`, got `[id]` |
| `one_to_one_form_document_ids` returns `[]` when size is 1 | `app/models/suggestion.rb:30-33` | C5 | yes — `suggestion_spec.rb:383` expected `[document.id]`, got `[]` |
| map only `supporting_documents.first(1)` | `app/models/suggestion.rb:33` | C7 | yes — `suggestion_spec.rb:401` expected both ids, got `[padaria.id]` |
| `check_box_tag` checked arg forced `false` | `app/views/months/show.html.erb:101` | C3 | yes — `months_spec.rb:1176` expected to include the document id, got `[]` |

No surviving mutant.

## Gate

`env -u BUNDLE_PATH bin/rspec spec/requests/months_spec.rb spec/models/suggestion_spec.rb` with the seven checklist `-e` strings — 7 passed, 0 failed.
