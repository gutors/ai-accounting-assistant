# Month match

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/month-match.md` marks screen `matches` binding through `.design/month-match.md` (criteria 1–13, 24, 32).

Sources:

- `.tasks/month-match.md` - criteria 1–32, two doors, the sweep, Unresolved 1–3 stay at the transcribed answers (title-right `Casar pagamentos` before Fechar / stamp; empty-side sums `R$ 0,00` and omit verdicts until both sides have a check; unknown `bank_account_id` is `404`). Nothing under Unresolved is settled beyond that transcription
- https://github.com/gutors/ai-accounting-assistant/issues/111 - **binding for this slice**: GET matches; POST create remains; filter `?bank_account_id=` default all; entry `Casar pagamentos`; same Match/exception rules; #110 gate; out: Fechar, upload, Devolver, unmatched-in-package, PagSeguro, #112. Recorte that still listed Recebimentos and filtering both lists is superseded by the design
- `.design/month-match.md` - **binding for the interface**: screen `matches`. Opened as a file in the repo (ASCII, Duas folhas, stay-after-confirm, N:1 on one totaling line, closed read-only, cell grammar = live month sheet). HTML mock `GET /prototypes/month-match` is development only and is not a binding source
- https://github.com/gutors/ai-accounting-assistant/issues/110 / `.tasks/confirm-accounts-before-movements.md` - `accounts_confirmed` / closed gate; unconfirmed match POST `404`
- `DESIGN.md` - livro-caixa; ruled sheet; one red margin; chips `aria-current`; notice under title
- `app/models/match.rb` - `BAD_SHAPE`, `LESSER`, `NO_PAYMENTS`, `NO_DOCUMENTS` (copy unchanged)
- `app/controllers/matches_controller.rb`, `document_exceptions_controller.rb` - today’s always-month redirect
- `app/views/months/show.html.erb` - Resolver / N:1 remain until #112
- `.specs/features/visual-identity/design.md` - amend in criterion 32
- Open defaults in Unresolved 1–3 as transcribed in the task

## Out of scope

- `Fechar para envio` on this screen — source Boundary
- Statement upload — stays on the month
- `Devolver` and unmatched-in-package checkboxes — stay on the month; #111 out
- Recebimentos — locked absent here; they stay on the month
- PagSeguro parser — #109
- Removing matching from the month (`Resolver`, N:1 fold) — #112
- Reopening Match / exception domain rules (1:N, N:1, lesser observation, taken payment/document)
- HTML mock `GET /prototypes/month-match` as a binding source — development only
- Settling Unresolved 1–3 beyond the task’s transcribed placement, empty-side verdicts, and `404` for a bad filter id

## Landing

Touches `GET /months/:year_month/matches` (two sheets, chips, totaling), origin-sensitive `302`/`422` on existing match and document-exception writes, month entry `Casar pagamentos`, and visual-identity section `matches`. Reuses `Match.confirm` / `dissolve`, `Payment#mark_document_exception`, `load_month_page` unmatched membership, `require_coordinator_organization`, `find_month_with_visible_movements`, month cell grammar (`ledger-pay`, `is-block`, `format_reais`, `payment_status`), and month-page Resolver / N:1 until #112.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Matching screen URL | `GET /months/:year_month/matches`. Filter `?bank_account_id=` (integer id of an active BankAccount on the focused organization); omit query for all. Pool membership does not follow the filter | Filtering the pool by inferred account — source. A query-less client-only chip (the HTML mock) — issue named the query. Recebimentos on this GET — locked 13 Oct 2026 |
| Return after mutate | Confirm / exception / undo **from this screen**: success `302` to this GET (keep `bank_account_id` when present); `422` re-renders this template. Confirm / exception / undo **from the month page**: existing `302` `/months/:year_month` and `422` `months/show` | Always redirect to `matches` — would fail shipped Resolver proofs and yank the coordinator off the month before #112 |

- Nothing else in this change is hard to reverse. Origin is a form field the month Resolver omits, not Referer. Strip exception marks POST the checked `payment_ids[]` (exactly one missing) while month Resolver still POSTs `/payments/:id/document_exception`

## Screens (ui)

Opened `.design/month-match.md` as a file. Arrangement below is what C1–C14, C21, C24, C27–C28 plus the `matches` section of `design.md` (C32) require. Tokens stay the month system (`caixa`, `margem`, `rule`, `ink-soft`, `ledger-pay`). Prototype `/prototypes/month-match` is not a source for these rows.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `matches` | `h1` month in words (`maio de 2026`); `2026-05` in `text-meta text-ink-soft` under it; `Voltar ao mês` to `/months/2026-05`; chips `Todas` then active accounts by name with `aria-current`; missing-count `Nenhum documento faltante.` / `1 pagamento com documento faltante.` / `N pagamentos com documento faltante.` (`text-margem` when N > 0); `h2` `Pagamentos` then `h2` `Documentos sem casamento`; payment checkbox or `×`; no `Resolver`; pool checkbox + Data + Favorecido + Valor + Tipo; empty `Nenhum documento sem casamento`; totaling `Pagamentos` / `Documentos` / `Observação do casamento` / `Confirmar casamento` / active exception marks; three verdicts; no `Fechar para envio`, no `Recebimentos`, no `Devolver`, no stamp | title left, `Voltar ao mês` title-right; chips then missing count then `.match-split` (Pagamentos wider track from 1100px, stacked Pagamentos first below); sheets are ruled grids from 768px; totaling line under both sheets with 1px ink rule above; observation `border-rule` not `margem`; confirm primary then secondary marks in name order | spacing, colour, type weight on chips, sheets, and totaling (except C3’s 1100px columns, stack, 768px grid, and 3px `ledger-pay` padding, which are proven) |
| `month` entry | control text `Casar pagamentos`, `href` `/months/:year_month/matches` after confirmation or while closed; absent while unconfirmed and open | quiet link in the title-right cluster, before `Fechar para envio` (open) or before `[data-stamp="closed"]` (closed) — Unresolved 1 | spacing, colour, type weight of that link |

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
- Origin-sensitive redirect is a controller decision reached over HTTP — request spec per origin (matches vs month). No new Match domain table
- `bank_account_id` membership (active focused account vs not) is a GET guard — request spec per member (omit, valid, `0`, foreign/inactive)
- HTML copy and sheet order are view decisions; this repo has no view specs — request specs on `GET` / `POST` matches
- C3 columns/stack/3px padding and C21 live sums are user-visible flows a request spec cannot settle — system specs (cuprite), same stack as `spec/system/screens_spec.rb`
- Match `BAD_SHAPE` / `LESSER` stay proven at `Match` and at HTTP; this cut does not reopen those tables

Cost: request examples for C1–C2, C4–C20, C22–C31; system examples for C3, C21; file-read for C32.

## Checks

Criteria 1–32 map to C1–C32. Unresolved 1–3 stay at the transcribed placement, empty-side verdicts, and `404` filter.

### S1 - GET `matches` chrome · 6 files · 60 KB · ~15k

**C1** - Given a signed-in coordinator of the focused organization and Month `2026-05` with `accounts_confirmed` true, when `GET /months/2026-05/matches` runs, then the status is `200`, `h1` is `maio de 2026`, `2026-05` is in `text-meta text-ink-soft` under it, the body includes a link whose text is `Voltar ao mês` and `href` is `/months/2026-05`, and the body includes neither `Fechar para envio` nor `h2` `Recebimentos` nor `[data-stamp="closed"]`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches chrome is month title Voltar and omits Fechar Recebimentos stamp"`

**C2** - On that GET, `h2` `Pagamentos` appears before `h2` `Documentos sem casamento`, both sit inside an element with class `match-split`, and there is no `form#close-month` and no control whose text is `Devolver`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches Pagamentos precedes pool inside match-split and omits close Devolver"`

**C3** - From viewport width `1100px`, `.match-split` is two columns with Pagamentos the wider track; below `1100px` the sheets stack, Pagamentos first. From `768px` each sheet is a ruled grid; payment rows use `ledger-pay` density (3px vertical).
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "match-split is two columns at 1100px stacked below with ledger-pay 3px at 768px"`

### S2 - Account filter and missing count · 3 files · 40 KB · ~10k

**C4** - Given two active BankAccounts `Conta Alfa` and `Conta Principal` (ledger name order), when that GET runs with no `bank_account_id`, then a group of chips includes `Todas` with `aria-current` `true`, then `Conta Alfa`, then `Conta Principal`; `Todas` `href` is `/months/2026-05/matches`; `Conta Alfa` `href` is `/months/2026-05/matches?bank_account_id=` that account’s id.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches chips Todas Alfa Principal with Todas current"`

**C5** - Given `Conta Principal` has a missing-document Payment of `22000` cents (`Pix enviado — Padaria Central`) and `Conta Alfa` has a missing-document Payment of `45000` cents (`TED — Energia Ltda`), when `GET /months/2026-05/matches?bank_account_id=` the Principal id runs, then `aria-current` is on `Conta Principal` not `Todas`, the Pagamentos sheet includes `Pix enviado — Padaria Central` and that account’s name in meta, does not include `TED — Energia Ltda`, the summary is `1 pagamento com documento faltante.` in `text-margem`, and an unmatched SupportingDocument `Padaria Central` still appears on Documentos sem casamento.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches filter Principal hides Alfa payment and keeps Padaria in pool"`

**C6** - When that GET runs unfiltered with those two missing payments, then the summary is `2 pagamentos com documento faltante.` in `text-margem`. When every payment on the filtered set is matched or excepted, the summary is `Nenhum documento faltante.` without `text-margem`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches unfiltered missing count is two and filtered none omits margem"`

**C7** - Given `bank_account_id` is `0` or an id that is not an active BankAccount of the focused organization, when that GET runs, then the status is `404` (Unresolved 3).
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches unknown or inactive bank_account_id is 404"`

### S3 - Pagamentos sheet · 3 files · 35 KB · ~9k

**C8** - Given a missing-document Payment `22000` cents on `2026-05-11`, history `Pix enviado — Padaria Central`, account `Conta Principal`, and a 1:1 Suggestion whose payee is `Padaria Central`, when that GET runs, then `li[data-row="payment"][data-status="missing"]` includes a checkbox in the first cell, `time` `11/05/2026`, that history, meta `Conta Principal`, `R$ 220,00`, `Documento faltante` in `text-margem`, `Sugestão Padaria Central` under status, class `is-block` (3px `margem` left edge), and no `Resolver`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches missing payment checkbox suggestion and no Resolver"`

**C9** - Given that payment is Casado with payees `Padaria Central` and observation `desconto não documentado`, when that GET runs, then `data-status` is `matched`, the first cell is `×` with `aria-label` `Desfazer casamento` in `text-margem`, status includes `Casado`, `Padaria Central`, and `desconto não documentado`, and that row has no actions line and no checkbox.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches Casado row is times undo with payee observation and no checkbox"`

**C10** - Given that payment is `bank_fee`, when that GET runs, then status is `Tarifa bancária` and the first cell is `×` with `aria-label` `Desmarcar exceção`. The same first-cell `×` with that `aria-label` holds for `accountant_fee` / `extra`. There is no `Resolver`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches exception row times Desmarcar excecao"`

**C11** - Payment rows on that GET follow existing month order (`occurred_on`, `id`). There is no `Casar vários pagamentos com um documento` on this screen.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches payments follow occurred_on id and omit N:1 fold"`

### S4 - Documentos sem casamento sheet · 2 files · 20 KB · ~5k

**C12** - Given unmatched listed documents, a recibo `Padaria Central` `22000` cents on `2026-05-11` and a nota fiscal `Mercado Silva` `18000` cents on `2026-05-12`, when that GET runs, then `li[data-row="pool-document"]` rows include a checkbox, `time` for `document_on`, Favorecido, `format_reais` Valor, and Tipo `Recibo` or `Nota fiscal`. Order is existing `listed` (`document_on` desc, `id` desc). Membership is existing unmatched-for-this-month (no `month_id` or this Month; closed month: this Month only).
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches pool rows checkbox date payee amount tipo in listed order"`

**C13** - Given no unmatched documents for that membership, when that GET runs, then the body includes `Nenhum documento sem casamento` and no `li[data-row="pool-document"]`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches empty pool copy and no pool rows"`

### S5 - Confirm, stay, domain refusals · 5 files · 55 KB · ~14k

**C14** - Under both sheets, a totaling line (1px ink rule above it) includes `Pagamentos`, `Documentos`, field label `Observação do casamento`, primary `Confirmar casamento`, and — when those organization offers are active — secondary `Marcar tarifa` and `Marcar honorário`, then each active extra exception kind’s `name` in name order. The observation control’s border class is the ruling line (`border-rule`), not `margem`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches totaling line confirm marks and observation border-rule"`

**C15** - Given one missing Payment `22000` cents and one unmatched document `22000` cents, when the confirm form on this GET POSTs those `payment_ids[]` and `supporting_document_ids[]` to `POST /months/2026-05/matches` with blank observation, then the status is `302` to `/months/2026-05/matches`, one Match persists, and the following GET of that path shows that payment `Casado` and omits that payee from Documentos sem casamento.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches from this screen 302s here Casado and drops pool payee"`

**C16** - Given two missing Payments `10000` and `12000` cents and one unmatched document `22000` cents, when that same confirm form POSTs both payment ids and that document id, then the status is `302` to `/months/2026-05/matches` and both payments are `Casado` on the following GET.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches N:1 from this screen 302s here both Casado"`

**C17** - When that confirm form POSTs two payment ids and two document ids, then no Match persists, the status is `422`, the body is this screen (`h1` `maio de 2026`, no `Fechar para envio`), and `[data-notice="error"]` is `Casamento é um pagamento com um ou mais documentos, ou vários pagamentos com um documento`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches N:M from this screen 422s matches with BAD_SHAPE"`

**C18** - Given one Payment `22000` cents and one document `20000` cents, when that form POSTs those ids with blank observation, then no Match persists, the status is `422`, `[data-notice="error"]` is `Informe a observação do casamento`, `h1` is `maio de 2026`, and the observation field border is still `border-rule`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches lesser blank observation 422s matches with border-rule"`

**C19** - Given criterion 5’s filtered GET, when a valid 1:1 confirm POSTs from that form, then `302` Location is `/months/2026-05/matches?bank_account_id=` that Principal id.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches from filtered screen keeps bank_account_id"`

**C20** - Given the month-page `Resolver` form (still present until #112), when `POST /months/2026-05/matches` runs with a valid 1:1 from that form, then `302` Location remains `/months/2026-05` and GET month still includes `Resolver` and `Casar vários pagamentos com um documento` when those month conditions hold.
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST 1 payment 2 documents persists Casado and redirects"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "month GET still has Resolver and N:1 fold after matches screen exists"`

**C21** - With one missing payment `22000` cents checked and one pool document `22000` cents checked, the totaling line shows `Pagamentos R$ 220,00`, `Documentos R$ 220,00`, and `Soma igual`. With the document `20000` cents, `Documentos somam menos`. With `25000` cents, `Documentos somam mais`. With either side unchecked, the sums are `R$ 0,00` for the empty side and the three verdict phrases are omitted (Unresolved 2).
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "totalling line sums and verdicts including empty side"`

### S6 - Exception marks and undo · 4 files · 45 KB · ~11k

**C22** - Given one missing Payment and `bank_fee` active, when `Marcar tarifa` on this screen runs with exactly that payment checked, then the Payment is `bank_fee`, status is `302` to `/months/2026-05/matches` (preserving `bank_account_id` when the GET was filtered), and the following GET shows `Tarifa bancária` and `×` `Desmarcar exceção`. `Marcar honorário` and an active extra kind’s button behave the same with their existing kinds / `extra_exception_kind_id`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST exception from matches strip with one payment stays here"`

**C23** - When `Marcar tarifa` (or honorário / extra) runs with zero checked missing payments, or with two, then no Payment is excepted, the status is `422`, the body is this screen, and `[data-notice="error"]` is `Selecione um pagamento para marcar a exceção.`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST exception from matches strip with zero or two payments 422s selection notice"`

**C24** - When `bank_fee_exception_active` is false, `Marcar tarifa` is absent from this GET; the same for honorário. Inactive extra kinds are absent.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches omits inactive exception mark buttons"`

**C25** - Given a Casado payment on this GET, when `×` `Desfazer casamento` runs, then that Match is gone, `302` is `/months/2026-05/matches` (filter preserved when present), the payment is `Documento faltante`, and its documents are back on the pool. `×` `Desmarcar exceção` DELETEs the existing document-exception route and stays on this GET. Neither `×` has `data-turbo-confirm`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "undo casamento and exception from matches stay here without turbo-confirm"`

**C26** - Given the month-page Desfazer / Desmarcar controls, when those existing POSTs/DELETEs run, then `302` Location remains `/months/2026-05`.
Proof: `bin/rspec spec/requests/matches_spec.rb -e "DELETE match returns payments to Documento faltante and documents to pool"`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST bank_fee persists Tarifa bancaria and redirects"`

### S7 - Closed month · 2 files · 15 KB · ~4k

**C27** - Given Month `2026-05` is closed, when `GET /months/2026-05/matches` runs, then the status is `200`, `h1` is `maio de 2026`, `Voltar ao mês` remains, there is no checkbox, no `Confirmar casamento`, no `Marcar tarifa` / `Marcar honorário` / extra buttons, no `×`, and `[data-stamp="closed"]` is absent.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches closed is read-only without stamp"`

### S8 - Month entry · 2 files · 90 KB · ~22k

**C28** - Given `accounts_confirmed` true (or the month closed), when `GET /months/2026-05` runs, then the body includes a control whose text is `Casar pagamentos` and `href` is `/months/2026-05/matches` (Unresolved 1 for placement).
Proof: `bin/rspec spec/requests/months_spec.rb -e "confirmed or closed month GET includes Casar pagamentos before Fechar or stamp"`

**C29** - Given `accounts_confirmed` false and the month open, when that month GET runs, then the body does not include `Casar pagamentos`, and `GET /months/2026-05/matches` is `404`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed open month GET omits Casar pagamentos"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches unconfirmed open is 404"`

### S9 - Gate and who may call · 3 files · 25 KB · ~6k

**C30** - Unauthenticated `GET /months/2026-05/matches` responds `302` to `/login`. A submitter with focus, when that GET runs, receives `404` and the body omits Payment history (existing coordinator-only month leak rule). `GET /months/2026-13` and a year_month never opened are `404`.
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches unauthenticated 302 login submitter and unknown month 404"`

**C31** - Unconfirmed `POST /months/2026-05/matches` and unconfirmed exception POST remain `404` with no persist (existing #110). Closed-month confirm/exception/undo remain `422` `Mês fechado` (existing).
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match on unconfirmed month returns 404"`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST document_exception on unconfirmed month returns 404"`
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match while closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/requests/matches_spec.rb -e "DELETE match while closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST extra_exception_kind_id while closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST strip exception on unconfirmed month returns 404"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST strip exception while closed returns 422 Mes fechado"`

### S10 - Binding visual-identity · 2 files · 30 KB · ~8k

**C32** - `.specs/features/visual-identity/design.md` gains section `matches` — `GET /months/:year_month/matches` — transcribed from `.design/month-match.md`: title month in words + `2026-05`; quiet `Voltar ao mês`; no `Fechar para envio` and no stamp; chips `Todas` then active accounts by name, `?bank_account_id=`, default all, Pagamentos only; missing-count copy and `margem` when N > 0; two sheets from 1100px (Pagamentos wider), stacked below with Pagamentos first; payment first cell checkbox vs `×`; no `Resolver`; pool columns and empty `Nenhum documento sem casamento`; totaling line and the three verdicts; stay after confirm. Month section `month` adds the `Casar pagamentos` entry after confirmation or while closed.
Proof: `bin/rspec spec/docs/visual_identity_month_bank_rows_spec.rb -e "visual-identity matches screen and month Casar pagamentos entry"`

## Swept

- validation: C17, C18, C23 — N:M and lesser-without-observation keep existing `Match` strings; exception-from-strip requires exactly one checked missing payment
- failure modes: C17, C18, C23, C27, C31 — 422 on this template; closed GET is read-only; closed POST still `Mês fechado`
- idempotency and retry: existing — a second confirm of the same payment is `Match::PAYMENT_TAKEN` (`Pagamento já está em um casamento`); this cut does not add a new unique index
- authorization: C30 — coordinator + focus; submitter `404`; no Payment text
- concurrency and ordering: existing — `Match#persist_confirm` locks payments and documents; this screen does not change that write
- data lifecycle: n/a — no new table; nothing to backfill
- external-dependency failure: n/a — no Drive / SEFAZ / mail on this path
- state transitions: C15, C16, C22, C25, C29 — Match and exception rows are the existing states; unconfirmed GET is `404`; closed GET is read-only
- observability: n/a — source names no log, metric, or success toast; stay-and-restyle is the feedback (month match POST already has no toast)

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| GET matches chrome (3) | title/Voltar/absences C1 · split order C2 · 1100/768 layout C3 | - |
| account chips and filter (4) | unfiltered Todas current C4 · Principal filter C5 · unfiltered count + none copy C6 · bad id `0` and foreign/inactive C7 | - |
| payment row statuses (5) | missing C8 · matched C9 · `bank_fee` C10 · `accountant_fee` C10 · `extra` C10 | - |
| payment order / N:1 absence (1) | C11 | - |
| pool (2) | listed rows C12 · empty C13 | - |
| confirm HTTP (6) | totaling chrome C14 · 1:1 stay C15 · N:1 stay C16 · N:M 422 C17 · lesser 422 C18 · filter preserved C19 | - |
| month origin unchanged (2) | match POST Location C20 · month Desfazer/Desmarcar C26 | - |
| totaling verdicts (4) | equal C21 · menos C21 · mais C21 · empty side omit C21 | - |
| exception strip (3) | one checked stay C22 (`bank_fee`, `accountant_fee`, extra) · zero or two 422 C23 · inactive omitted C24 (bank, honorário, extra) | - |
| undo from matches (2) | dissolve C25 · unmark C25 | - |
| closed GET (1) | C27 | - |
| month entry (2) | confirmed/closed link C28 · unconfirmed omit + GET 404 C29 | - |
| who may call GET (4) | unauthenticated 302 C30 · submitter 404 C30 · `2026-13` C30 · never opened C30 | - |
| existing write gates (5) | unconfirmed match C31 · unconfirmed exception C31 · closed match POST C31 · closed match DELETE C31 · closed extra POST C31 | - |
| designed screens this cut binds (2) | `matches` C1–C14, C21, C24, C27, C32 · `month` entry C28–C29, C32 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `setup`, `documents` — out of scope |
| `matches` visual (3 properties) | C3 columns, stack, 3px padding | spacing, colour, type weight besides C3 |
| `month` entry visual (3 properties) | — | spacing, colour, type weight of `Casar pagamentos` |

- Claims naming a status code, route or response shape: C1, C7, C15–C20, C22, C23, C25–C31 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~15k (new `matches/show`, `MatchesController#show`, CSS, `month_matches_spec`) + S2–S4 ~24k (same view counted once) + S5 ~14k (create origin + Stimulus + system totaling) + S6 ~11k (`DocumentExceptionsController` origin and strip selection) + S7 ~4k + S8 ~22k (`months/show.html.erb` + `months_spec.rb` 87 KB for the entry link) + S9 ~6k + S10 ~8k (`design.md`) = unique-file floor ~120k with `months_spec.rb` paid once in S8. Under 150k. No split. One batch.

- Where the boundary fell:
- What the user settled mid-build: Unresolved 1–3 stay at the task transcription (title-right before Fechar/stamp; empty-side `R$ 0,00` and omit verdicts; bad `bank_account_id` `404`). Prototype is not production.
- What was abandoned:
