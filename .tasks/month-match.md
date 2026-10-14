# Month match

> Build this with **tlc-implement**. Profile **`ui`**: screen `matches` is binding through
> `.design/month-match.md` (criteria 1–13, 24, 32).
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

Matching today lives on `GET /months/:year_month`: per-row `Resolver` and a second fold `Casar
vários pagamentos com um documento`, on the same page as statements, Recebimentos, Devolver,
unmatched-in-package checkboxes, and `Fechar para envio`. Issue #111 gives no conversion figure.
The cost is that after **accounts confirmation** the coordinator still marks 1:N / N:1 and
exceptions inside the month overview.

When this ships, `GET /months/:year_month/matches` is the matching screen: two facing sheets
(Pagamentos ~60%, Documentos sem casamento), account chips on Pagamentos only, confirm under the
pair. After a valid confirm the coordinator stays here; the payment restyles to `Casado` and the
documents leave the pool. Recebimentos stay on the month. The month keeps Resolver / N:1 until
#112. Binding design: `.design/month-match.md`. Cell grammar follows the live month sheet and
`DESIGN.md`.

32 criteria in 10 slices · 2 one-way doors · 3 open, of which 0 block

## Criteria

### GET `matches` chrome

1. Given a signed-in coordinator of the focused organization and Month `2026-05` with
   `accounts_confirmed` true, when `GET /months/2026-05/matches` runs, then the status is `200`,
   `h1` is `maio de 2026`, `2026-05` is in `text-meta text-ink-soft` under it, the body includes a
   link whose text is `Voltar ao mês` and `href` is `/months/2026-05`, and the body includes
   neither `Fechar para envio` nor `h2` `Recebimentos` nor `[data-stamp="closed"]`.
2. On that GET, `h2` `Pagamentos` appears before `h2` `Documentos sem casamento`, both sit inside
   an element with class `match-split`, and there is no `form#close-month` and no control whose
   text is `Devolver`.
3. From viewport width `1100px`, `.match-split` is two columns with Pagamentos the wider track;
   below `1100px` the sheets stack, Pagamentos first. From `768px` each sheet is a ruled grid;
   payment rows use `ledger-pay` density (3px vertical).

### Account filter and missing count

4. Given two active BankAccounts `Conta Alfa` and `Conta Principal` (ledger name order), when that
   GET runs with no `bank_account_id`, then a group of chips includes `Todas` with `aria-current`
   `true`, then `Conta Alfa`, then `Conta Principal`; `Todas` `href` is `/months/2026-05/matches`;
   `Conta Alfa` `href` is `/months/2026-05/matches?bank_account_id=` that account’s id.
5. Given `Conta Principal` has a missing-document Payment of `22000` cents (`Pix enviado — Padaria
   Central`) and `Conta Alfa` has a missing-document Payment of `45000` cents (`TED — Energia
   Ltda`), when `GET /months/2026-05/matches?bank_account_id=` the Principal id runs, then
   `aria-current` is on `Conta Principal` not `Todas`, the Pagamentos sheet includes `Pix enviado
   — Padaria Central` and that account’s name in meta, does not include `TED — Energia Ltda`, the
   summary is `1 pagamento com documento faltante.` in `text-margem`, and an unmatched SupportingDocument
   `Padaria Central` still appears on Documentos sem casamento.
6. When that GET runs unfiltered with those two missing payments, then the summary is
   `2 pagamentos com documento faltante.` in `text-margem`. When every payment on the filtered
   set is matched or excepted, the summary is `Nenhum documento faltante.` without `text-margem`.
7. Given `bank_account_id` is `0` or an id that is not an active BankAccount of the focused
   organization, when that GET runs, then the status is `404` (Unresolved 3).

### Pagamentos sheet

8. Given a missing-document Payment `22000` cents on `2026-05-11`, history `Pix enviado — Padaria
   Central`, account `Conta Principal`, and a 1:1 Suggestion whose payee is `Padaria Central`, when
   that GET runs, then `li[data-row="payment"][data-status="missing"]` includes a checkbox in the
   first cell, `time` `11/05/2026`, that history, meta `Conta Principal`, `R$ 220,00`,
   `Documento faltante` in `text-margem`, `Sugestão Padaria Central` under status, class `is-block`
   (3px `margem` left edge), and no `Resolver`.
9. Given that payment is Casado with payees `Padaria Central` and observation `desconto não
   documentado`, when that GET runs, then `data-status` is `matched`, the first cell is `×` with
   `aria-label` `Desfazer casamento` in `text-margem`, status includes `Casado`, `Padaria Central`,
   and `desconto não documentado`, and that row has no actions line and no checkbox.
10. Given that payment is `bank_fee`, when that GET runs, then status is `Tarifa bancária` and the
    first cell is `×` with `aria-label` `Desmarcar exceção`. The same first-cell `×` with that
    `aria-label` holds for `accountant_fee` / `extra`. There is no `Resolver`.
11. Payment rows on that GET follow existing month order (`occurred_on`, `id`). There is no
    `Casar vários pagamentos com um documento` on this screen.

### Documentos sem casamento sheet

12. Given unmatched listed documents, a recibo `Padaria Central` `22000` cents on `2026-05-11` and
    a nota fiscal `Mercado Silva` `18000` cents on `2026-05-12`, when that GET runs, then
    `li[data-row="pool-document"]` rows include a checkbox, `time` for `document_on`, Favorecido,
    `format_reais` Valor, and Tipo `Recibo` or `Nota fiscal`. Order is existing `listed`
    (`document_on` desc, `id` desc). Membership is existing unmatched-for-this-month (no
    `month_id` or this Month; closed month: this Month only).
13. Given no unmatched documents for that membership, when that GET runs, then the body includes
    `Nenhum documento sem casamento` and no `li[data-row="pool-document"]`.

### Confirm, stay, domain refusals

14. Under both sheets, a totaling line (1px ink rule above it) includes `Pagamentos`, `Documentos`,
    field label `Observação do casamento`, primary `Confirmar casamento`, and — when those
    organization offers are active — secondary `Marcar tarifa` and `Marcar honorário`, then each
    active extra exception kind’s `name` in name order. The observation control’s border class is
    the ruling line (`border-rule`), not `margem`.
15. Given one missing Payment `22000` cents and one unmatched document `22000` cents, when the
    confirm form on this GET POSTs those `payment_ids[]` and `supporting_document_ids[]` to
    `POST /months/2026-05/matches` with blank observation, then the status is `302` to
    `/months/2026-05/matches`, one Match persists, and the following GET of that path shows that
    payment `Casado` and omits that payee from Documentos sem casamento.
16. Given two missing Payments `10000` and `12000` cents and one unmatched document `22000` cents,
    when that same confirm form POSTs both payment ids and that document id, then the status is
    `302` to `/months/2026-05/matches` and both payments are `Casado` on the following GET.
17. When that confirm form POSTs two payment ids and two document ids, then no Match persists, the
    status is `422`, the body is this screen (`h1` `maio de 2026`, no `Fechar para envio`), and
    `[data-notice="error"]` is `Casamento é um pagamento com um ou mais documentos, ou vários
    pagamentos com um documento`.
18. Given one Payment `22000` cents and one document `20000` cents, when that form POSTs those ids
    with blank observation, then no Match persists, the status is `422`, `[data-notice="error"]`
    is `Informe a observação do casamento`, `h1` is `maio de 2026`, and the observation field
    border is still `border-rule`.
19. Given criterion 5’s filtered GET, when a valid 1:1 confirm POSTs from that form, then `302`
    Location is `/months/2026-05/matches?bank_account_id=` that Principal id.
20. Given the month-page `Resolver` form (still present until #112), when `POST
    /months/2026-05/matches` runs with a valid 1:1 from that form, then `302` Location remains
    `/months/2026-05` and GET month still includes `Resolver` and `Casar vários pagamentos com um
    documento` when those month conditions hold.
21. With one missing payment `22000` cents checked and one pool document `22000` cents checked,
    the totaling line shows `Pagamentos R$ 220,00`, `Documentos R$ 220,00`, and `Soma igual`. With
    the document `20000` cents, `Documentos somam menos`. With `25000` cents, `Documentos somam
    mais`. With either side unchecked, the sums are `R$ 0,00` for the empty side and the three
    verdict phrases are omitted (Unresolved 2).

### Exception marks and undo

22. Given one missing Payment and `bank_fee` active, when `Marcar tarifa` on this screen runs with
    exactly that payment checked, then the Payment is `bank_fee`, status is `302` to
    `/months/2026-05/matches` (preserving `bank_account_id` when the GET was filtered), and the
    following GET shows `Tarifa bancária` and `×` `Desmarcar exceção`. `Marcar honorário` and an
    active extra kind’s button behave the same with their existing kinds / `extra_exception_kind_id`.
23. When `Marcar tarifa` (or honorário / extra) runs with zero checked missing payments, or with
    two, then no Payment is excepted, the status is `422`, the body is this screen, and
    `[data-notice="error"]` is `Selecione um pagamento para marcar a exceção.`
24. When `bank_fee_exception_active` is false, `Marcar tarifa` is absent from this GET; the same
    for honorário. Inactive extra kinds are absent.
25. Given a Casado payment on this GET, when `×` `Desfazer casamento` runs, then that Match is
    gone, `302` is `/months/2026-05/matches` (filter preserved when present), the payment is
    `Documento faltante`, and its documents are back on the pool. `×` `Desmarcar exceção` DELETEs
    the existing document-exception route and stays on this GET. Neither `×` has
    `data-turbo-confirm`.
26. Given the month-page Desfazer / Desmarcar controls, when those existing POSTs/DELETEs run,
    then `302` Location remains `/months/2026-05`.

### Closed month

27. Given Month `2026-05` is closed, when `GET /months/2026-05/matches` runs, then the status is
    `200`, `h1` is `maio de 2026`, `Voltar ao mês` remains, there is no checkbox, no `Confirmar
    casamento`, no `Marcar tarifa` / `Marcar honorário` / extra buttons, no `×`, and
    `[data-stamp="closed"]` is absent.

### Month entry

28. Given `accounts_confirmed` true (or the month closed), when `GET /months/2026-05` runs, then
    the body includes a control whose text is `Casar pagamentos` and `href` is
    `/months/2026-05/matches` (Unresolved 1 for placement).
29. Given `accounts_confirmed` false and the month open, when that month GET runs, then the body
    does not include `Casar pagamentos`, and `GET /months/2026-05/matches` is `404`.

### Gate and who may call

30. Unauthenticated `GET /months/2026-05/matches` responds `302` to `/login`. A submitter with
    focus, when that GET runs, receives `404` and the body omits Payment history (existing
    coordinator-only month leak rule). `GET /months/2026-13` and a year_month never opened are
    `404`.
31. Unconfirmed `POST /months/2026-05/matches` and unconfirmed exception POST remain `404` with
    no persist (existing #110). Closed-month confirm/exception/undo remain `422` `Mês fechado`
    (existing).

### Binding visual-identity

32. `.specs/features/visual-identity/design.md` gains section `matches` — `GET
    /months/:year_month/matches` — transcribed from `.design/month-match.md`: title month in
    words + `2026-05`; quiet `Voltar ao mês`; no `Fechar para envio` and no stamp; chips `Todas`
    then active accounts by name, `?bank_account_id=`, default all, Pagamentos only; missing-count
    copy and `margem` when N > 0; two sheets from 1100px (Pagamentos wider), stacked below with
    Pagamentos first; payment first cell checkbox vs `×`; no `Resolver`; pool columns and empty
    `Nenhum documento sem casamento`; totaling line and the three verdicts; stay after confirm.
    Month section `month` adds the `Casar pagamentos` entry after confirmation or while closed.

## Out of scope

- `Fechar para envio` on this screen — source Boundary
- Statement upload — stays on the month
- `Devolver` and unmatched-in-package checkboxes — stay on the month; #111 out
- Recebimentos — locked absent here; they stay on the month
- PagSeguro parser — #109
- Removing matching from the month (`Resolver`, N:1 fold) — #112
- Reopening Match / exception domain rules (1:N, N:1, lesser observation, taken payment/document)
- HTML mock `GET /prototypes/month-match` as a binding source — development only

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `matches` | empty state | 13 — pool copy `Nenhum documento sem casamento`; 6 — `Nenhum documento faltante.` when the filtered Pagamentos set has no missing row |
| screen `matches` | loading | n/a — server-rendered GET |
| screen `matches` | error state | 17, 18, 23 — HTML `422`, first `:base` on `[data-notice="error"]`; observation border stays `border-rule` |
| screen `matches` | unauthorised | 30 — unauthenticated `302` `/login`; submitter `404` |
| screen `matches` | density and ordering | 3, 4, 11, 12 — 1100px split; 768px ruled sheet; `ledger-pay` 3px; chips name order; payments `occurred_on`; pool `listed` |
| screen `matches` | destructive action confirms | 25 — `×` one click, no `data-turbo-confirm` (same as today’s month Desfazer) |
| HTML `GET /months/:year_month/matches` | response shape | 1, 2, 27 — `200` HTML; closed is the same screen minus controls |
| HTML `GET /months/:year_month/matches` | error shape and codes | 7, 29, 30 — `404`; `302` `/login` |
| HTML `GET /months/:year_month/matches` | who may call | 30 — `require_coordinator_organization` |
| HTML `GET /months/:year_month/matches` | versioning | n/a — HTML GET |
| HTML `GET /months/:year_month/matches` | rate limit | n/a — no limit in this app |
| HTML `POST /months/:year_month/matches` | response shape | 15, 16, 19, 20 — `302` here when the confirm form is this screen’s; `302` month when the form is Resolver |
| HTML `POST /months/:year_month/matches` | error shape and codes | 17, 18 — `422` re-renders `matches`; existing `404` unconfirmed / foreign ids |
| HTML `POST /months/:year_month/matches` | who may call | existing — coordinator + focus |
| HTML `POST /months/:year_month/matches` | versioning | n/a — existing HTML form POST |
| HTML `POST /months/:year_month/matches` | rate limit | n/a — coordinator-only |
| HTML exception POST/DELETE | response shape | 22, 25, 26 — stay on `matches` when originated here; month Location unchanged from month-page controls |
| HTML exception POST/DELETE | error shape and codes | 23 — `422` selection notice; existing inactive-offer and closed copy |
| screen `month` | empty / loading / error | existing — unchanged by this cut |
| screen `month` | density and ordering | 28 — adds `Casar pagamentos`; 20 — Resolver / N:1 remain |
| document visual-identity `matches` | structure, tone, next action | 32 |
| collection account chips | grouping, naming, ordering, duplicates, exception | 4, 7 — one chip per active account, `order(:name)`; `Todas`; unknown id `404` (Unresolved 3) |
| collection Pagamentos / pool | grouping, naming, ordering, duplicates, exception | 11, 12 — existing payment and `listed` orders; pool membership unchanged by the account filter |

## Swept

- validation: 17, 18, 23 — N:M and lesser-without-observation keep existing `Match` strings; exception-from-strip requires exactly one checked missing payment
- failure modes: 17, 18, 23, 27, 31 — 422 on this template; closed GET is read-only; closed POST still `Mês fechado`
- idempotency and retry: existing — a second confirm of the same payment is `Match::PAYMENT_TAKEN` (`Pagamento já está em um casamento`); this cut does not add a new unique index
- authorization: 30 — coordinator + focus; submitter `404`; no Payment text
- concurrency and ordering: existing — `Match#persist_confirm` locks payments and documents; this screen does not change that write
- data lifecycle: n/a — no new table; nothing to backfill
- external-dependency failure: n/a — no Drive / SEFAZ / mail on this path
- state transitions: 15, 16, 22, 25, 29 — Match and exception rows are the existing states; unconfirmed GET is `404`; closed GET is read-only
- observability: n/a — source names no log, metric, or success toast; stay-and-restyle is the feedback (month match POST already has no toast)

## Impact

| Front | What changes |
|---|---|
| domain | no new term. **Match** / **Document exception** / **Accounts confirmation** keep their glossary meanings |
| domain | existing term: **Month page** still hosts Resolver and N:1 until #112; it gains entry `Casar pagamentos` after confirmation. Callers: `app/views/months/show.html.erb`, month request specs, visual-identity `month` |
| stored data | nothing to migrate |

`MatchesController#create` / `#destroy` and `DocumentExceptionsController#create` / `#destroy`
today always `redirect_to "/months/#{year_month}"` and `render "months/show"` on `422`. This cut
makes those responses origin-sensitive (criteria 15–20, 22, 25, 26). Shipped
`spec/requests/matches_spec.rb` and `document_exceptions_spec.rb` examples that POST from the
month page must keep `302` to `/months/2026-05`.

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| Matching screen URL | `GET /months/:year_month/matches`. Filter `?bank_account_id=` (integer id of an active BankAccount on the focused organization); omit query for all. Pool membership does not follow the filter | Filtering the pool by inferred account — source. A query-less client-only chip (the HTML mock) — issue named the query. Recebimentos on this GET — locked 13 Oct 2026 |
| Return after mutate | Confirm / exception / undo **from this screen**: success `302` to this GET (keep `bank_account_id` when present); `422` re-renders this template. Confirm / exception / undo **from the month page**: existing `302` `/months/:year_month` and `422` `months/show` | Always redirect to `matches` — would fail shipped Resolver proofs and yank the coordinator off the month before #112 |

Composition Duas folhas, stay-after-confirm, and N:1 on one totaling line are product locks in
`.design/month-match.md` and reversible in the design table; they are criteria, not schema doors.

## Surface

| Route | In | Out | Status | Criteria |
|---|---|---|---|---|
| `GET /months/:year_month/matches` | session, focus, optional `bank_account_id` | two sheets, chips, totaling, or `404` | `200`, `302`, `404` | 1–14, 27–30 |
| `POST /months/:year_month/matches` | existing `payment_ids[]`, `supporting_document_ids[]`, `observation` | `302` this GET or month GET; `422` matching template | `302`, `422`, `404` | 15–20, 31 |
| `DELETE /months/:year_month/matches/:id` | session, focus, id | `302` this GET or month GET | `302`, `404`, `422` | 25, 26, 31 |
| `POST /months/:year_month/payments/:id/document_exception` | existing `kind` / `extra_exception_kind_id`; this screen also needs a single selected missing payment | `302` this GET or month GET; `422` selection notice | `302`, `422`, `404` | 22–24, 26, 31 |
| `DELETE /months/:year_month/payments/:id/document_exception` | session, focus, id | `302` this GET or month GET | `302`, `404`, `422` | 25, 26, 31 |
| `GET /months/:year_month` | existing | adds `Casar pagamentos` after confirmation / closed | `200` | 28, 29 |

## Sources

- https://github.com/gutors/ai-accounting-assistant/issues/111 — **binding for this slice**: GET
  matches; POST create remains; filter `?bank_account_id=` default all; entry `Casar pagamentos`;
  same Match/exception rules; #110 gate; out: Fechar, upload, Devolver, unmatched-in-package,
  PagSeguro, #112. Recorte on the issue that still listed Recebimentos and filtering both lists
  is superseded by the design (Recebimentos absent; filter Pagamentos only)
- `.design/month-match.md` — **binding for the interface**: screen `matches`; Duas folhas;
  stay-after-confirm; N:1 on one confirm; closed read-only; cell grammar = live month sheet
- https://github.com/gutors/ai-accounting-assistant/issues/110 / `.tasks/confirm-accounts-before-movements.md`
  — `accounts_confirmed` / closed gate; unconfirmed match POST `404`
- `DESIGN.md` — livro-caixa; ruled sheet; one red margin; chips `aria-current`; notice under title
- `app/models/match.rb` — `BAD_SHAPE`, `LESSER`, `NO_PAYMENTS`, `NO_DOCUMENTS` (copy unchanged)
- `app/controllers/matches_controller.rb`, `document_exceptions_controller.rb` — today’s always-month redirect
- `app/views/months/show.html.erb` — Resolver / N:1 remain until #112
- `.specs/features/visual-identity/design.md` — amend in criterion 32
- Open defaults in Unresolved 1–3

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | open | Where does `Casar pagamentos` sit on the month page? | Quiet link in the title-right cluster, before `Fechar para envio` (open) or before the stamp (closed). Copy is exactly that phrase (28) |
| 2 | open | Totalling verdict when a side has no check? | Empty side sum `R$ 0,00`; omit `Soma igual` / `Documentos somam menos` / `Documentos somam mais` until both sides have at least one check (21) |
| 3 | open | `?bank_account_id=` that is not an active account of this organization? | `404` (7), same as a foreign month resource |
