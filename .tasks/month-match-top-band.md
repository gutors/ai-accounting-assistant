# Month match top band

> Build this with **tlc-implement**. Profile **`ui`**: screen `matches` is binding through
> `.design/month-match.md` (criteria 1–17, 18).
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

`GET /months/:year_month/matches` already holds matching: facing sheets, chips on Pagamentos,
confirm **under** the pair. After accounts confirmation the coordinator still scrolls past two
ledgers to reach totals and `Confirmar casamento`. The payment row only names suggestion payees
(`Sugestão Padaria Central`). Pool rows follow `listed` (`document_on` desc). Dates include the
year (`11/05/2026`). Issue #111 and `.tasks/month-match.md` give no conversion figure; the cost
named on 15 Oct 2026 is that matching is a slog because totals sit under the sheets, and a
one-click pair needs day/month and amount, not only the payee.

When this ships, that GET keeps the two sheets and the same POST, but the totaling line, observação,
and confirm sit in a **sticky band above** the pair, under a `Próxima sugestão` control (payment |
`casar com` | document, day/month + amount + payee). Clicking it when sums match POSTs the existing
confirm; a lesser sum only checks the rows. Documents on this GET run oldest → newest. Dates omit
the year. There is no `Casar` on the payment row and no `Sugestão {payees}` under status.
Binding design: `.design/month-match.md` (amended 15 Oct 2026). Cell grammar follows the live month
sheet and `DESIGN.md`.

18 criteria in 7 slices · 0 one-way doors · 1 open, of which 0 block

## Criteria

### Sticky confirm above the sheets

1. Given a signed-in coordinator of the focused organization and open Month `2026-05` with
   `accounts_confirmed` true, when `GET /months/2026-05/matches` runs, then `#match-confirm`
   appears before `.match-split` in document order, includes `Pagamentos`, `Documentos`, field
   label `Observação do casamento`, primary `Confirmar casamento`, and — when those organization
   offers are active — secondary `Marcar tarifa` and `Marcar honorário`, then each active extra
   exception kind’s `name` in name order; the observation control’s border class is `border-rule`,
   not `margem`; and `#match-confirm` does not appear after `.match-split`.
2. On that GET, the region that contains `h2` `Próxima sugestão` when it exists and
   `#match-confirm` is `position: sticky` with `top: 0`, and that region has a `1px` ink bottom
   edge (`border-bottom` `1px solid` the ink token). `#match-confirm` itself has no `1px` ink
   `border-top`.
3. With one missing payment `22000` cents checked and one pool document `22000` cents checked, the
   totaling line in `#match-confirm` shows `Pagamentos R$ 220,00`, `Documentos R$ 220,00`, and
   `Soma igual`. With the document `20000` cents, `Documentos somam menos`. With `25000` cents,
   `Documentos somam mais`. With either side unchecked, the empty side is `R$ 0,00` and the three
   verdict phrases are omitted.

### Próxima sugestão

4. Given a missing-document Payment `22000` cents on `2026-05-11`, history `Pix enviado — Padaria
   Central`, and a 1:1 Suggestion whose document is `Padaria Central` `22000` cents on
   `2026-05-11`, when that GET runs, then `h2` `Próxima sugestão` sits in the sticky region before
   `#match-confirm`, and the suggestion control includes `Pagamento`, `casar com`, `Documento`,
   `11/05`, that history, `R$ 220,00` on the payment side, `Padaria Central`, and `R$ 220,00` on
   the document side.
5. Given a second missing-document Payment on `2026-05-04` with a 1:1 Suggestion (payee `Fornecedor
   Norte`) and the Padaria payment of criterion 4, when that GET runs unfiltered, then the
   suggestion control’s payment side includes `TED — Fornecedor Norte` and does not include `Pix
   enviado — Padaria Central`.
6. Given criterion 5’s two payments on different active accounts, when
   `GET /months/2026-05/matches?bank_account_id=` the Padaria account’s id runs, then the
   suggestion control’s payment side includes `Pix enviado — Padaria Central` and does not include
   `Fornecedor Norte`.
7. Given a missing-document Payment `15500` cents and a Suggestion of two unmatched documents
   `10000` and `5500` cents payees `Papelaria Norte` and `Papelaria Norte`, `document_on`
   `2026-05-13` and `2026-05-14`, when that GET runs, then the suggestion control’s document side
   includes `13/05`, `Papelaria Norte, Papelaria Norte`, and `R$ 155,00`.
8. Given a missing-document Payment whose only suggestion is `Sugestão de exceção` (accountant PIX
   in history, no document Suggestion) and no other missing payment has a document Suggestion, when
   that GET runs, then `h2` `Próxima sugestão` is absent, `#match-confirm` remains, and that
   payment row includes `Sugestão de exceção`.
9. Given every missing-document Payment on the filtered set has no 1-payment document Suggestion,
   when that GET runs, then `h2` `Próxima sugestão` is absent and `#match-confirm` remains.

### Click equal vs lesser

10. Given criterion 4’s 1:1, when the suggestion control is activated, then the request is `POST
    /months/2026-05/matches` with that payment id, that document id, and blank observation, the
    status is `302` to `/months/2026-05/matches`, one Match persists, and the following GET shows
    that payment `Casado`, omits `Padaria Central` from Documentos sem casamento, and either shows
    the next remaining 1-payment document Suggestion as `Próxima sugestão` or omits that `h2` when
    none remain.
11. Given a missing-document Payment `150000` cents (`TED — Aluguel sede`) and its Suggestion
    document `140000` cents (`Imobiliária Serra`), when the suggestion control is activated, then
    no Match persists, that payment checkbox and that document checkbox are checked, `#match-confirm`
    shows `Documentos somam menos`, and `Observação do casamento` is empty. When `Confirmar
    casamento` then POSTs those ids with blank observation, the status is `422` and
    `[data-notice="error"]` is `Informe a observação do casamento`. When that form POSTs those ids
    with observation `desconto não documentado`, the status is `302` to `/months/2026-05/matches`
    and that payment is `Casado`.
12. Given two missing Payments `10000` and `12000` cents and one unmatched document `22000` cents,
    when the confirm form POSTs both payment ids and that document id (sheet checkboxes, not the
    suggestion control), then the status is `302` to `/months/2026-05/matches` and both payments
    are `Casado` on the following GET.

### Dates and pool order

13. On `GET /months/2026-05/matches`, each `li[data-row="payment"] time` and
    `li[data-row="pool-document"] time` visible text is day/month (`11/05`) and each `datetime` is
    that row’s ISO-8601 date. `GET /months/2026-05` still shows that payment’s `time` as
    `11/05/2026`.
14. Given unmatched listed documents, a recibo `Padaria Central` `22000` cents on `2026-05-11` and
    a nota fiscal `Mercado Silva` `18000` cents on `2026-05-12`, when `GET /months/2026-05/matches`
    runs, then `li[data-row="pool-document"]` payee order is `Padaria Central` then `Mercado Silva`.
    Membership stays existing unmatched-for-this-month (no `month_id` or this Month; closed month:
    this Month only). `GET /supporting_documents` still lists `Mercado Silva` before `Padaria
    Central` (`listed`, `document_on` desc).

### Payment row copy

15. Given criterion 4’s missing payment, when `GET /months/2026-05/matches` runs, then that
    `li[data-row="payment"][data-status="missing"]` includes a checkbox, `Documento faltante` in
    `text-margem`, class `is-block`, and includes neither `Casar` nor `Sugestão Padaria Central`
    nor `Resolver`.
16. Given a Casado payment with payees `Padaria Central`, when that GET runs, then `data-status` is
    `matched`, the first cell is `×` with `aria-label` `Desfazer casamento`, and status includes
    `Casado` and `Padaria Central`.

### Closed month

17. Given Month `2026-05` is closed, when `GET /months/2026-05/matches` runs, then the status is
    `200`, `h1` is `maio de 2026`, `Voltar ao mês` remains, there is no checkbox, no `h2` `Próxima
    sugestão`, no `Confirmar casamento`, no `Marcar tarifa` / `Marcar honorário` / extra buttons,
    no `×`, and `[data-stamp="closed"]` is absent. Pool order and day/month dates of criteria 13–14
    still hold.

### Binding visual-identity

18. `.specs/features/visual-identity/design.md` section `matches` — `GET /months/:year_month/matches`
    — is amended: sticky band above the sheets with `Próxima sugestão` (Pagamento | `casar com` |
    Documento, day/month + amount + payee) then totaling / observação / confirm / marks; dates
    `11/05`; pool oldest → newest; click equal confirms; no `Casar` and no `Sugestão {payees}` on
    the payment row; `Sugestão de exceção` stays on the row. Title, chips, missing-count, two
    sheets from 1100px, stay after confirm, and `Voltar ao mês` remain as shipped in #111.

## Out of scope

- `Fechar para envio` on this screen — already out on #111
- Statement upload, `Devolver`, unmatched-in-package, Recebimentos — stay on the month
- PagSeguro parser — #109
- Removing matching from the month (`Resolver`, N:1 fold) — #112
- Reopening Match / exception domain rules (1:N, N:1, lesser observation, taken payment/document)
- Changing `SupportingDocument.listed` or the Sem mês order on `GET /supporting_documents`
- Putting `Sugestão de exceção` on the `Próxima sugestão` control
- Deleting or restyling `GET /prototypes/month-match` — throwaway; leave it
- Origin-sensitive `302`/`422` vs the month page — already shipped; this cut does not reopen it

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `matches` | empty state | 9 — no `Próxima sugestão` when no 1-payment document Suggestion remains; existing `Nenhum documento sem casamento` / `Nenhum documento faltante.` unchanged |
| screen `matches` | loading | n/a — server-rendered GET |
| screen `matches` | error state | 11 — HTML `422`, `Informe a observação do casamento` on `[data-notice="error"]` after Confirmar on a lesser pair; observation stays `border-rule` (existing #111) |
| screen `matches` | unauthorised | existing — unauthenticated `302` `/login`; submitter `404` (`spec/requests/month_matches_spec.rb`) |
| screen `matches` | density and ordering | 2, 5, 6, 13, 14 — sticky `top: 0`; next follows filtered `occurred_on`; dates `%d/%m`; pool `document_on` asc; existing 1100px split / `ledger-pay` 3px unchanged |
| screen `matches` | destructive action confirms | 10 — suggestion click with equal sums POSTs with no `data-turbo-confirm` (same as today’s `×` Desfazer); 16 — `×` unchanged |
| HTML `GET /months/:year_month/matches` | response shape | 1, 4, 17 — `200` HTML; closed omits the band controls |
| HTML `GET /months/:year_month/matches` | error shape and codes | existing — `404` unconfirmed / bad `bank_account_id`; `302` `/login` |
| HTML `GET /months/:year_month/matches` | who may call | existing — `require_coordinator_organization` |
| HTML `GET /months/:year_month/matches` | versioning | n/a — HTML GET |
| HTML `GET /months/:year_month/matches` | rate limit | n/a — no limit in this app |
| HTML `POST /months/:year_month/matches` | response shape | 10, 11, 12 — `302` this GET on valid confirm from click or checkboxes; `422` re-renders this template on LESSER |
| HTML `POST /months/:year_month/matches` | error shape and codes | 11 — existing `Match::LESSER` string; existing `BAD_SHAPE` unchanged |
| HTML `POST /months/:year_month/matches` | who may call | existing — coordinator + focus |
| HTML `POST /months/:year_month/matches` | versioning | n/a — existing HTML form POST |
| HTML `POST /months/:year_month/matches` | rate limit | n/a — coordinator-only |
| screen `month` | empty / loading / error / density | existing — date with year (13); matching UI until #112 unchanged |
| document visual-identity `matches` | structure, tone, next action | 18 |
| collection Pagamentos / next | grouping, naming, ordering, duplicates, exception | 5, 6, 8, 9 — first 1-payment document Suggestion on the filtered sheet; skip exception-only; Unresolved 1 for two-payment suggestions |
| collection pool on this GET | grouping, naming, ordering, duplicates, exception | 14 — `document_on` asc, `id` asc; membership unchanged |

## Swept

- validation: 11, 12 — lesser-without-observation and N:1 keep existing `Match` strings; this cut does not add a new shape
- failure modes: 11, 17 — `422` still this template; closed GET omits the band
- idempotency and retry: existing — a second confirm of the same payment is `Match::PAYMENT_TAKEN`; click uses the same POST
- authorization: existing — coordinator + focus; submitter `404`; no Payment text
- concurrency and ordering: existing — `Match#persist_confirm` locks payments and documents; the click does not add a second writer
- data lifecycle: n/a — no new table; nothing to backfill
- external-dependency failure: n/a — no Drive / SEFAZ / mail on this path
- state transitions: 10, 11 — Match rows are the existing states; click-equal is the existing confirm transition; click-lesser does not transition until Confirmar with observação
- observability: n/a — source names no log, metric, or success toast; stay-and-restyle remains the feedback

## Impact

| Front | What changes |
|---|---|
| domain | no new term. **Suggestion** still means the existing assigned proposal (`app/models/suggestion.rb`). **Next** is a view choice over that map (first 1-payment document Suggestion on the filtered sheet), not a new record |
| domain | existing term: **matches screen** totaling moves from under `.match-split` to the sticky band; callers: `app/views/matches/show.html.erb`, `app/javascript/controllers/month_match_controller.js`, `spec/requests/month_matches_spec.rb` (confirm after split, `11/05/2026`, `listed` desc, `Sugestão Padaria Central`), `spec/system/month_matches_spec.rb` (`.match-confirm` `border-top`) |
| stored data | nothing to migrate |

`MatchesController#create` stays origin-sensitive (`screen=matches`). This cut must not send month-page Resolver confirms to `matches`. Shipped `spec/requests/matches_spec.rb` examples that POST from the month page must keep `302` to `/months/2026-05`.

Changing `SupportingDocument.listed` would reorder `GET /supporting_documents`. Criterion 14 forbids that.

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| None — composition, click, dates, and this-GET pool order are product locks in `.design/month-match.md` and reversible there. URL `GET /months/:year_month/matches` and origin-sensitive mutate redirects already shipped in #111; this cut does not reopen them | — | A new confirm endpoint for the suggestion click — would duplicate `POST /months/:year_month/matches` |

## Surface

| Route | In | Out | Status | Criteria |
|---|---|---|---|---|
| `GET /months/:year_month/matches` | session, focus, optional `bank_account_id` | sticky band, next control, two sheets, or `404` | `200`, `302`, `404` | 1–9, 13–18 |
| `POST /months/:year_month/matches` | existing `payment_ids[]`, `supporting_document_ids[]`, `observation` (suggestion click uses the same body) | `302` this GET; `422` this template | `302`, `422`, `404` | 10–12 |

## Sources

- Conversation, 15 Oct 2026 / prototype handoff — **binding for this slice**: winner “topo da A com o clique da C”; drop per-row Casar; dates day/month; pool oldest → newest; click-equal confirms; lesser still needs observação
- `.design/month-match.md` — **binding for the interface**: screen `matches` as amended this session; Duas folhas stay; confirm-above + Próxima sugestão
- `GET /prototypes/month-match` (development) — composition values (`Próxima sugestão`, `casar com`, sticky, `%d/%m`, pool asc). Not a persistence source
- https://github.com/gutors/ai-accounting-assistant/issues/111 / `.tasks/month-match.md` — shipped GET, filter, stay-after-confirm, Match/exception rules, origin-sensitive redirects. Recorte that placed totaling **under** the pair is superseded
- `DESIGN.md` — livro-caixa; ruled sheet; one red margin
- `app/models/suggestion.rb` — 1:1 / 1:N / `format_2`; this cut does not reopen Assigner
- `.specs/features/visual-identity/design.md` — amend in criterion 18
- Open default in Unresolved 1

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | open | Does `Próxima sugestão` include a two-payment (`format_2`) Suggestion? | Skip. Next is the first **1-payment** document Suggestion on the filtered Pagamentos sheet (`payments.size == 1`). `format_2` stays sheet checkboxes + `Confirmar casamento` (12). The locked prototype never showed two payments on the band |
