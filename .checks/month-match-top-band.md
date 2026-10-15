# Month match top band

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/month-match-top-band.md` marks screen `matches` binding through `.design/month-match.md` (criteria 1–17, 18).

Sources:

- `.tasks/month-match-top-band.md` - criteria 1–18, the sweep, Unresolved 1 stays Skip (next is the first 1-payment document Suggestion on the filtered Pagamentos sheet; `format_2` stays checkboxes + Confirmar). Nothing under Unresolved is settled while building
- `.design/month-match.md` - **binding for the interface**: screen `matches`. Opened as a file in the repo (ASCII, sticky band above the pair, `Próxima sugestão` Pagamento | `casar com` | Documento, click-equal confirms, dates `%d/%m`, pool `document_on` asc, no per-row `Casar` / `Sugestão {payees}`, `Sugestão de exceção` stays on the row). HTML mock `GET /prototypes/month-match` is development only and is not a persistence source
- https://github.com/gutors/ai-accounting-assistant/issues/111 / `.tasks/month-match.md` - shipped GET, filter, stay-after-confirm, Match/exception rules, origin-sensitive redirects. Recorte that placed totaling under the pair is superseded
- `DESIGN.md` - livro-caixa; ruled sheet; one red margin
- `app/models/suggestion.rb` - 1:1 / 1:N / `format_2`; this cut does not reopen Assigner
- `.specs/features/visual-identity/design.md` - amend in criterion 18
- Conversation, 15 Oct 2026 / prototype handoff - winner “topo da A com o clique da C”
- Open default in Unresolved 1 as transcribed in the task

## Out of scope

- `Fechar para envio` on this screen — already out on #111
- Statement upload, `Devolver`, unmatched-in-package, Recebimentos — stay on the month
- PagSeguro parser — #109
- Removing matching from the month (`Resolver`, N:1 fold) — #112
- Reopening Match / exception domain rules (1:N, N:1, lesser observation, taken payment/document)
- Changing `SupportingDocument.listed` or the Sem mês order on `GET /supporting_documents`
- Putting `Sugestão de exceção` on the `Próxima sugestão` control
- Deleting or restyling `GET /prototypes/month-match` — throwaway; leave it
- Origin-sensitive `302`/`422` vs the month page — already shipped
- Settling Unresolved 1 beyond the task’s Skip (first 1-payment document Suggestion)

## Landing

Touches `GET /months/:year_month/matches` (sticky band, next control, day/month dates, this-GET pool order, payment-row copy) and the existing `POST /months/:year_month/matches` (suggestion click uses the same body). Reuses `Match.confirm`, `load_matches_page` unmatched membership, `require_coordinator_organization`, month cell grammar, origin-sensitive mutate redirects, and `Suggestion.assign` (no new Assigner).

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| None — composition, click, dates, and this-GET pool order are product locks in `.design/month-match.md` and reversible there. URL `GET /months/:year_month/matches` and origin-sensitive mutate redirects already shipped in #111; this cut does not reopen them | — | A new confirm endpoint for the suggestion click — would duplicate `POST /months/:year_month/matches` |
| Next pick is `Suggestion.next_one_payment(payments, proposals_by_payment_id)` | Returns the first `missing_document?` payment in the given array whose proposal has `payments.size == 1`; `nil` when none. Sheet order and the account filter are the array the loader already built | A second Assigner pass, or picking in the ERB — would duplicate `payments.size == 1` and hide the table from the model spec |
| Matches dates use locale `:day_month` `"%d/%m"` | `l(date, format: :day_month)` only in `matches/show` (sheets and next). Month GET keeps `l(date)` default `"%d/%m/%Y"` | Hardcoded `strftime` in the view — would skip the locale table the rest of the app uses |
| This-GET pool order is a loader reorder | `load_matches_page` reorders `@unmatched_documents` with `document_on` asc, `id` asc. `SupportingDocument.listed` stays `document_on` desc, `id` desc | A new model scope used from the matches loader — other listed callers would inherit oldest-first by accident |

- Nothing else in this change is hard to reverse

## Screens (ui)

Opened `.design/month-match.md` as a file. Arrangement below is what C1–C17 plus the amended `matches` section of `design.md` (C18) require. Tokens stay the month system (`caixa`, `margem`, `rule`, `ink`, `paper`, `ledger-pay`). Prototype `/prototypes/month-match` is not a source for these rows.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `matches` | `h1` `maio de 2026`; `2026-05` meta; `Voltar ao mês`; chips then missing-count; `h2` `Próxima sugestão` when a next 1-payment document Suggestion exists, with `Pagamento`, `casar com`, `Documento`, day/month, history, payee(s), `format_reais`; `#match-confirm` with `Pagamentos`, `Documentos`, `Observação do casamento`, primary `Confirmar casamento`, secondary `Marcar tarifa` / `Marcar honorário` when those offers are active then extra kind `name`s in name order; totaling verdicts `Soma igual` / `Documentos somam menos` / `Documentos somam mais`; observation `border-rule` not `margem`; payment missing: checkbox, `Documento faltante` `text-margem`, `is-block`, no `Casar`, no `Sugestão {payees}`, no `Resolver`; `Sugestão de exceção` stays on exception-only rows; Casado: `×` `Desfazer casamento`; pool `Nenhum documento sem casamento` empty; dates visible `11/05`; no `Fechar para envio`, no stamp | chips then missing-count then sticky region (contains `h2` `Próxima sugestão` when present **and** `#match-confirm`) **before** `.match-split`; next control is Pagamento side \| `casar com` \| Documento side; totaling / observação / confirm sit in that band, not after the sheets; sticky `top: 0` with 1px ink `border-bottom`; `#match-confirm` has no 1px ink `border-top`; sheets two columns from 1100px Pagamentos wider (unchanged); pool `li[data-row="pool-document"]` oldest → newest | spacing, colour, type weight on the band, next hit, and sheets (except C2 sticky/`top`/`border-bottom`/`border-top` which are proven) |

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

These rows are the bar I build under — approving the checklist is enough for that. Writing them into `.cursor/rules/rails.mdc` needs an explicit yes, and it lands as its own commit before the build. Without one I build under them and leave the file alone.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at its own layer **and** one request spec at HTTP | one asserted case per enumerated member at its own layer; status and who may call at the boundary | follow |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` names the level and the sampling rule
- Next-suggestion pick is a decision table (`1:1`, `1:N`, skip `format_2`, skip exception-only, filtered sheet order, none) — own layer on `Suggestion` plus GET request specs C4–C9
- HTML copy, document order, pool order, dates are view / loader decisions; this repo has no view specs — request specs on `GET` / `POST` matches
- C2 sticky computed style, C3 live sums, C10 click-equal POST, C11 click-lesser (no POST) are user-visible flows a request spec cannot settle — system specs (cuprite), same stack as `spec/system/month_matches_spec.rb`. Stimulus has no JS unit runner in this repo
- Match `LESSER` / N:1 stay proven at `Match` and at HTTP; this cut does not reopen those tables
- Origin-sensitive redirect stays proven in shipped `spec/requests/matches_spec.rb` / `month_matches_spec.rb`; this cut must not send month-page confirms to `matches`

Cost: request examples for C1, C4–C9, C11 (POST halves), C12–C17; model examples for next-pick members; system examples for C2, C3, C10, C11 (click); file-read for C18.

## Checks

Criteria 1–18 map to C1–C18. Unresolved 1 stays Skip.

### S1 - Sticky confirm above the sheets · 4 files · 55 KB · ~14k

**C1** - Given a signed-in coordinator of the focused organization and open Month `2026-05` with `accounts_confirmed` true, when `GET /months/2026-05/matches` runs, then `#match-confirm` appears before `.match-split` in document order, includes `Pagamentos`, `Documentos`, field label `Observação do casamento`, primary `Confirmar casamento`, and — when those organization offers are active — secondary `Marcar tarifa` and `Marcar honorário`, then each active extra exception kind’s `name` in name order; the observation control’s border class is `border-rule`, not `margem`; and `#match-confirm` does not appear after `.match-split`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches confirm band sits above the split with observation border-rule"`

**C2** - On that GET, the region that contains `h2` `Próxima sugestão` when it exists and `#match-confirm` is `position: sticky` with `top: 0`, and that region has a `1px` ink bottom edge (`border-bottom` `1px solid` the ink token). `#match-confirm` itself has no `1px` ink `border-top`.
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "match top band is sticky with ink bottom and confirm has no ink top"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches confirm band sits above the split with observation border-rule"`

**C3** - With one missing payment `22000` cents checked and one pool document `22000` cents checked, the totaling line in `#match-confirm` shows `Pagamentos R$ 220,00`, `Documentos R$ 220,00`, and `Soma igual`. With the document `20000` cents, `Documentos somam menos`. With `25000` cents, `Documentos somam mais`. With either side unchecked, the empty side is `R$ 0,00` and the three verdict phrases are omitted.
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "totalling line sums and verdicts including empty side"`

### S2 - Próxima sugestão · 5 files · 52 KB · ~13k

**C4** - Given a missing-document Payment `22000` cents on `2026-05-11`, history `Pix enviado — Padaria Central`, and a 1:1 Suggestion whose document is `Padaria Central` `22000` cents on `2026-05-11`, when that GET runs, then `h2` `Próxima sugestão` sits in the sticky region before `#match-confirm`, and the suggestion control includes `Pagamento`, `casar com`, `Documento`, `11/05`, that history, `R$ 220,00` on the payment side, `Padaria Central`, and `R$ 220,00` on the document side.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches next suggestion is Padaria 1:1 above confirm"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "next_one_payment picks the first 1:1 on the sheet"`

**C5** - Given a second missing-document Payment on `2026-05-04` with a 1:1 Suggestion (payee `Fornecedor Norte`) and the Padaria payment of criterion 4, when that GET runs unfiltered, then the suggestion control’s payment side includes `TED — Fornecedor Norte` and does not include `Pix enviado — Padaria Central`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches next suggestion is the earlier Fornecedor Norte payment"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "next_one_payment follows occurred_on on the filtered sheet"`

**C6** - Given criterion 5’s two payments on different active accounts, when `GET /months/2026-05/matches?bank_account_id=` the Padaria account’s id runs, then the suggestion control’s payment side includes `Pix enviado — Padaria Central` and does not include `Fornecedor Norte`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches next suggestion follows the Principal account filter"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "next_one_payment follows occurred_on on the filtered sheet"`

**C7** - Given a missing-document Payment `15500` cents and a Suggestion of two unmatched documents `10000` and `5500` cents payees `Papelaria Norte` and `Papelaria Norte`, `document_on` `2026-05-13` and `2026-05-14`, when that GET runs, then the suggestion control’s document side includes `13/05`, `Papelaria Norte, Papelaria Norte`, and `R$ 155,00`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches next suggestion 1:N joins payees and earliest date"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "next_one_payment includes a 1:N justification group"`

**C8** - Given a missing-document Payment whose only suggestion is `Sugestão de exceção` (accountant PIX in history, no document Suggestion) and no other missing payment has a document Suggestion, when that GET runs, then `h2` `Próxima sugestão` is absent, `#match-confirm` remains, and that payment row includes `Sugestão de exceção`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches omits next suggestion when only exception suggestion remains"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "next_one_payment skips a payment with no document suggestion"`

**C9** - Given every missing-document Payment on the filtered set has no 1-payment document Suggestion, when that GET runs, then `h2` `Próxima sugestão` is absent and `#match-confirm` remains.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches omits next suggestion when only format_2 remains"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "next_one_payment skips format_2"`

### S3 - Click equal vs lesser · 4 files · 40 KB · ~10k

**C10** - Given criterion 4’s 1:1, when the suggestion control is activated, then the request is `POST /months/2026-05/matches` with that payment id, that document id, and blank observation, the status is `302` to `/months/2026-05/matches`, one Match persists, and the following GET shows that payment `Casado`, omits `Padaria Central` from Documentos sem casamento, and either shows the next remaining 1-payment document Suggestion as `Próxima sugestão` or omits that `h2` when none remain.
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "next suggestion click with equal sums confirms and omits the heading"`

**C11** - Given a missing-document Payment `150000` cents (`TED — Aluguel sede`) and its Suggestion document `140000` cents (`Imobiliária Serra`), when the suggestion control is activated, then no Match persists, that payment checkbox and that document checkbox are checked, `#match-confirm` shows `Documentos somam menos`, and `Observação do casamento` is empty. When `Confirmar casamento` then POSTs those ids with blank observation, the status is `422` and `[data-notice="error"]` is `Informe a observação do casamento`. When that form POSTs those ids with observation `desconto não documentado`, the status is `302` to `/months/2026-05/matches` and that payment is `Casado`.
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "next suggestion click with lesser sums checks rows and does not persist"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches lesser Aluguel blank observation 422s Informe a observacao"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches lesser Aluguel with observation 302s Casado"`

**C12** - Given two missing Payments `10000` and `12000` cents and one unmatched document `22000` cents, when the confirm form POSTs both payment ids and that document id (sheet checkboxes, not the suggestion control), then the status is `302` to `/months/2026-05/matches` and both payments are `Casado` on the following GET.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches N:1 from this screen 302s here both Casado"`

### S4 - Dates and pool order · 4 files · 45 KB · ~11k

**C13** - On `GET /months/2026-05/matches`, each `li[data-row="payment"] time` and `li[data-row="pool-document"] time` visible text is day/month (`11/05`) and each `datetime` is that row’s ISO-8601 date. `GET /months/2026-05` still shows that payment’s `time` as `11/05/2026`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches dates are day month and month page keeps the year"`

**C14** - Given unmatched listed documents, a recibo `Padaria Central` `22000` cents on `2026-05-11` and a nota fiscal `Mercado Silva` `18000` cents on `2026-05-12`, when `GET /months/2026-05/matches` runs, then `li[data-row="pool-document"]` payee order is `Padaria Central` then `Mercado Silva`. Membership stays existing unmatched-for-this-month (no `month_id` or this Month; closed month: this Month only). `GET /supporting_documents` still lists `Mercado Silva` before `Padaria Central` (`listed`, `document_on` desc).
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches pool is oldest first and documents index stays listed desc"`

### S5 - Payment row copy · 2 files · 42 KB · ~11k

**C15** - Given criterion 4’s missing payment, when `GET /months/2026-05/matches` runs, then that `li[data-row="payment"][data-status="missing"]` includes a checkbox, `Documento faltante` in `text-margem`, class `is-block`, and includes neither `Casar` nor `Sugestão Padaria Central` nor `Resolver`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches missing payment omits Casar and suggestion payees"`

**C16** - Given a Casado payment with payees `Padaria Central`, when that GET runs, then `data-status` is `matched`, the first cell is `×` with `aria-label` `Desfazer casamento`, and status includes `Casado` and `Padaria Central`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches Casado row is times undo with payee observation and no checkbox"`

### S6 - Closed month · 2 files · 41 KB · ~10k

**C17** - Given Month `2026-05` is closed, when `GET /months/2026-05/matches` runs, then the status is `200`, `h1` is `maio de 2026`, `Voltar ao mês` remains, there is no checkbox, no `h2` `Próxima sugestão`, no `Confirmar casamento`, no `Marcar tarifa` / `Marcar honorário` / extra buttons, no `×`, and `[data-stamp="closed"]` is absent. Pool order and day/month dates of criteria 13–14 still hold.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches closed is read-only without stamp next or confirm"`

### S7 - Binding visual-identity · 2 files · 34 KB · ~9k

**C18** - `.specs/features/visual-identity/design.md` section `matches` — `GET /months/:year_month/matches` — is amended: sticky band above the sheets with `Próxima sugestão` (Pagamento | `casar com` | Documento, day/month + amount + payee) then totaling / observação / confirm / marks; dates `11/05`; pool oldest → newest; click equal confirms; no `Casar` and no `Sugestão {payees}` on the payment row; `Sugestão de exceção` stays on the row. Title, chips, missing-count, two sheets from 1100px, stay after confirm, and `Voltar ao mês` remain as shipped in #111.
Proof: `bin/rspec spec/docs/visual_identity_month_bank_rows_spec.rb -e "visual-identity matches screen sticky band next suggestion and day month dates"`

## Swept

- validation: C11, C12 — lesser-without-observation and N:1 keep existing `Match` strings; this cut does not add a new shape
- failure modes: C11, C17 — `422` still this template; closed GET omits the band
- idempotency and retry: existing — a second confirm of the same payment is `Match::PAYMENT_TAKEN`; click uses the same POST
- authorization: existing — coordinator + focus; submitter `404`; no Payment text (`spec/requests/month_matches_spec.rb` shipped)
- concurrency and ordering: existing — `Match#persist_confirm` locks payments and documents; the click does not add a second writer
- data lifecycle: n/a — no new table; nothing to backfill
- external-dependency failure: n/a — no Drive / SEFAZ / mail on this path
- state transitions: C10, C11 — Match rows are the existing states; click-equal is the existing confirm transition; click-lesser does not transition until Confirmar with observação
- observability: n/a — source names no log, metric, or success toast; stay-and-restyle remains the feedback

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| next-pick (6) | 1:1 C4 · earlier sheet order C5 · account filter C6 · 1:N C7 · exception-only skip C8 · `format_2` skip C9 | - |
| totaling verdicts (4) | equal C3 · menos C3 · mais C3 · empty side omit C3 | - |
| suggestion click (2) | equal POST C10 · lesser check-only C11 | - |
| confirm HTTP (4) | lesser blank `422` C11 · lesser with obs `302` C11 · N:1 `302` C12 · (equal via click C10) | - |
| dates (2) | matches day/month C13 · month GET with year C13 | - |
| pool (2) | matches `document_on` asc C14 · `GET /supporting_documents` listed desc C14 | - |
| payment row copy (2) | missing omits Casar / payee suggestion C15 · Casado `×` C16 | - |
| closed GET (1) | C17 | - |
| designed screens this cut binds (1) | `matches` C1–C18 | - |
| visual-identity screens this cut does not bind (6) | — | `login`, `denied`, `home`, `setup`, `documents`, `month` — out of scope |
| `matches` visual (3 properties) | C2 sticky, `top: 0`, 1px ink bottom, no confirm top | spacing, colour, type weight besides C2 |

- Claims naming a status code, route or response shape: C1, C10, C11, C12, C17 — each has a proof that crosses the HTTP or browser boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1–S7 unique-file floor: `matches/show.html.erb` 10 KB + `application_controller.rb` 10 KB + `suggestion.rb` 5 KB + `application.css` 8 KB + `month_matches_spec.rb` 31 KB + `month_matches` system 6 KB + `visual-identity/design.md` 29 KB + `visual_identity_month_bank_rows_spec.rb` 5 KB ≈ 104 KB (~26k tokens) with the large request spec paid once. Under 150k. No split. One batch.

- Where the boundary fell:
- What the user settled mid-build: Unresolved 1 stays Skip.
- What was abandoned:
