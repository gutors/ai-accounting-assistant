# Month overview

> Build this with **tlc-implement**. Profile **`ui`**: screen `month` is binding through
> `.design/month-overview.md` (criteria 1–22, 26).
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

Matching still lives on `GET /months/:year_month` as per-row `Resolver`, `Marcar tarifa` /
`Marcar honorário` / extra, `Desfazer casamento` / `Desmarcar exceção`, and a second fold
`Casar vários pagamentos com um documento`, on the same page as Contas, Recebimentos, package
checkboxes, Devolver, and `Fechar para envio`. Recebimentos sit above Pagamentos. The pool is
Favorecido / Valor / Devolver. There are no account chips and no `Voltar para Início`. Title-right
Casar (`.ds-btn-secondary`, open and confirmed only) and stamp `.stamp-closed` under the title
already shipped with #111. Issue #112 gives no conversion figure. The cost is that the close
status and the matching bench are still one page.

When this ships, that GET is close status: blockers, Contas, then the book. Pagamentos,
Documentos sem casamento, Recebimentos last, each in `<details open class="month-fold">`. Account
chips after Contas filter Pagamentos and Recebimentos only (`?bank_account_id=` like #111). Ações
is gone; Documento holds matched payee names; matching gestures live only on
`GET /months/:year_month/matches`. Package checkboxes and Devolver stay. Binding design:
`.design/month-overview.md`. Cell grammar follows the live month sheet and `DESIGN.md`.

27 criteria in 7 slices · 1 one-way door · 1 open, of which 0 block

## Criteria

### GET chrome

1. Given a signed-in coordinator of the focused organization and open Month `2026-05` with
   `accounts_confirmed` true, when `GET /months/2026-05` runs, then the status is `200`, `h1` is
   `maio de 2026`, `2026-05` is in `text-meta text-ink-soft` under it, the first link in `<main>`
   has text `Voltar para Início` and `href` `/` and classes `text-caixa` plus underline, the
   header still includes a link `Início` to `/`, title-right includes `Casar pagamentos` with
   class `ds-btn-secondary` and `href` `/months/2026-05/matches` (Unresolved 1 when the GET is
   filtered) before `Fechar para envio` with class `ds-btn-primary`, and `[data-stamp="closed"]`
   is absent.
2. Given that Month is closed, when that GET runs, then `Voltar para Início` remains first in
   `<main>`, `[data-stamp="closed"]` is `Mês fechado` with class `stamp-closed` and sits in the
   title block under `2026-05` (its parent contains `h1`, not `Restaurar pasta`), title-right
   includes `Restaurar pasta` and `Reabrir` each with class `ds-btn-secondary` and their existing
   `data-turbo-confirm` copy, and the body includes neither `Casar pagamentos` nor
   `Fechar para envio`.
3. Given `accounts_confirmed` false and the month open, when that GET runs, then the body
   includes `Voltar para Início` and `Fechar para envio`, does not include `Casar pagamentos`,
   and includes no chip `Todas` and no `<details class="month-fold">`.
4. While the month is open and either the missing-document count is greater than 0 or an active
   account lacks a statement, `Fechar para envio` remains present and is not `disabled`.

### Composition

5. Given criterion 1’s confirmed open month, when that GET runs, then `h2` `Contas bancárias`
   is not inside `<details>`, the blocking sentence sits above that `h2`, and after Contas the
   document order is: the chip group, then `<details class="month-fold">` whose `<summary>` is
   `Pagamentos`, then one whose `<summary>` is `Documentos sem casamento`, then one whose
   `<summary>` is `Recebimentos`. There is no `h2` with those three titles.
6. On that GET, each of those three `<details>` has the `open` attribute. Given zero Payments,
   the Pagamentos fold is still `open` and has no `li[data-row="payment"]`. Given zero Inflows,
   the Recebimentos fold is still `open` and has no `li[data-row="inflow"]` (no new empty
   sentence). Empty pool copy is criterion 21.
7. Given criterion 3’s unconfirmed open month, when that GET runs, then `h2`
   `Confirmar contas para fechamento` still follows `h2` `Contas bancárias`, submit
   `Iniciar fechamento` remains, and the three movement folds are absent.

### Account filter

8. Given two active BankAccounts `Conta Alfa` and `Conta Principal` (ledger name order) and
   movements visible, when `GET /months/2026-05` runs with no `bank_account_id`, then a group
   `role="group"` `aria-label` `Conta bancária` includes `Todas` with `aria-current` `true`, then
   `Conta Alfa`, then `Conta Principal`; `Todas` `href` is `/months/2026-05`; `Conta Alfa` `href`
   is `/months/2026-05?bank_account_id=` that account’s id. Contas still lists both accounts.
9. Given `Conta Principal` has a missing-document Payment of `22000` cents (`Pix enviado —
   Padaria Central`) and an Inflow of `6300` cents, and `Conta Alfa` has a missing-document
   Payment of `45000` cents (`TED — Energia Ltda`) and an Inflow whose history is `Pix Alfa`,
   when `GET /months/2026-05?bank_account_id=` the Principal id runs, then `aria-current` is on
   `Conta Principal` not `Todas`, Pagamentos includes `Pix enviado — Padaria Central` and that
   account’s name in meta and does not include `TED — Energia Ltda`, Recebimentos includes
   `R$ 63,00` and does not include `Pix Alfa`, the missing sentence is
   `1 pagamento com documento faltante.` in `text-margem`, an unmatched SupportingDocument
   `Padaria Central` still appears on Documentos sem casamento, and `Falta o extrato` still
   follows every active account (not the chip).
10. When that GET runs unfiltered with those two missing payments, then the missing sentence is
    `2 pagamentos com documento faltante.` in `text-margem`. When every payment on the filtered
    set is matched or excepted, the missing sentence is `Nenhum documento faltante.` without
    `text-margem`.
11. Given `bank_account_id` is `0`, an inactive BankAccount id of this organization, or an id
    that is not an active BankAccount of the focused organization, when `GET /months/2026-05`
    runs with that query, then the status is `404`.
12. Given criterion 3’s unconfirmed open month and a valid active `bank_account_id`, when that
    GET runs with that query, then the status is `200` and movements stay hidden (criterion 3).

### Pagamentos

13. On criterion 1’s GET, the Pagamentos sheet head (from `768px`) is `Data`, `Histórico`,
    `Valor`, `Status`, `Documento`. There is no `Ações`. Rows use `ledger-overview-pay` density
    (`3px` vertical) and existing payment order (`occurred_on`, `id`).
14. Given a missing-document Payment `22000` cents on `2026-05-11`, history `Pix enviado —
    Padaria Central`, account `Conta Principal`, and a 1:1 Suggestion whose payee is
    `Padaria Central`, when that GET runs, then `li[data-row="payment"][data-status="missing"]`
    includes `time` for `occurred_on`, that history, meta `Conta Principal`, `R$ 220,00`,
    `Documento faltante` in `text-margem`, `Sugestão Padaria Central` under Status, class
    `is-block`, an empty Documento cell, and neither `Resolver` nor a `form` to
    `/months/2026-05/matches`.
15. Given that payment is Casado with payees `Padaria Central` and `Mercado Silva` and
    observation `desconto não documentado`, when that GET runs, then `data-status` is `matched`,
    Status includes `Casado` and `desconto não documentado` and does not include those payees,
    Documento is `Padaria Central, Mercado Silva`, and there is no `Desfazer casamento`. A
    second missing payment Casado N:1 with one document `Padaria Central` shows that payee
    alone in Documento.
16. Given that payment is `bank_fee`, when that GET runs, then Status is `Tarifa bancária`,
    Documento is empty, and there is no `Desmarcar exceção`. The same empty Documento and
    absent undo hold for `accountant_fee` / `extra` (Status is `Honorário do contador` or the
    extra kind `name`). Closed month with a deactivated extra kind still shows that `name` in
    Status (existing).
17. On that GET, the body includes neither `Casar vários pagamentos com um documento` nor
    `Marcar tarifa` nor `Marcar honorário` nor an extra-kind submit, including when those
    organization offers are active.

### Documentos sem casamento

18. Given unmatched listed documents, a recibo `Padaria Central` `22000` cents on `2026-05-11`
    with photo filename `foto.jpg` and a nota fiscal `Mercado Silva` `18000` cents on
    `2026-05-12` with no photo, when criterion 1’s GET runs, then `li[data-row="pool-document"]`
    rows are Data (`time` `document_on`), Favorecido, Tipo `Recibo` or `Nota fiscal`,
    `format_reais` Valor, Foto, then Devolver. Order is existing `listed` (`document_on` desc,
    `id` desc). Membership is existing unmatched-for-this-month. The sheet uses
    `ledger-overview-pool`. Head labels are `Data`, `Favorecido`, `Tipo`, `Valor`, `Foto`.
19. Given an open month, a document with `month_id` nil has a checkbox `form="close-month"`
    whose label is the payee; a document with `month_id` this Month has quiet `Devolver`
    (`text-margem` underline) posting to the existing return route and has no close checkbox.
20. On the recibo row, Foto is a `text-caixa` underlined link whose text is `foto.jpg` and
    whose `href` is `url_for` of that photo blob (same tab, no `target="_blank"`). On the nota
    fiscal row, Foto has no link and no filename.
21. Given no unmatched documents for that membership, when that GET runs, then the
    Documentos sem casamento fold includes `Nenhum documento sem casamento` and no
    `li[data-row="pool-document"]`. Given the month is closed, the pool has no checkbox and
    no `Devolver`.

### Recebimentos and closed lists

22. Recebimentos remains Data, Histórico (history + account name in meta), Valor; it is the
    last fold; it does not include `Documento faltante`. It follows the same `bank_account_id`
    filter as Pagamentos (criterion 9).
23. Given Month `2026-05` is closed, when that GET runs, then the three folds remain `open`,
    Contas has no `Incluir extrato` / `Substituir extrato`, and `GET /months/2026-05/matches`
    is still `200` (existing) while the month body omits `Casar pagamentos`.

### Who may call and existing writes

24. Unauthenticated `GET /months/2026-05` responds `302` to `/login`. A submitter with focus,
    when that GET runs, receives `404` and the body omits Payment history (existing
    coordinator-only month leak rule). `GET /months/2026-13` and a year_month never opened
    remain `404`.
25. `POST /months/2026-05/close`, `reopen`, `restore`, `account_confirmation`, and Devolver
    keep their existing statuses and Locations (no `bank_account_id` on those redirects).
    `422` re-renders this GET’s template without `Resolver`. Confirm / exception / undo
    **from the matches screen** keep #111 Locations. A `POST /months/2026-05/matches` that
    still omits `screen=matches` keeps `302` `/months/2026-05` (no month form posts it).

### Binding visual-identity

26. `.specs/features/visual-identity/design.md` section `month` — `GET /months/:year_month` —
    is transcribed from `.design/month-overview.md`: quiet `Voltar para Início` first in
    `<main>` to `/`; Casar `.ds-btn-secondary` only while open and confirmed, before Fechar;
    stamp under `YYYY-MM` not on the action row; closed title-right only Restaurar / Reabrir;
    blockers then Contas then chips then Pagamentos / Documentos sem casamento / Recebimentos
    last; three `<details open>` with summary headings; chips `Todas` then active accounts by
    name, `?bank_account_id=`, default all, Pagamentos + Recebimentos only, pool unfiltered,
    unknown id `404`; Pagamentos columns Data / Histórico / Valor / Status / Documento (payee
    names; empty on missing and exception); no Resolver / N:1 / Marcar / Desfazer; suggestion
    meta under Status; pool Data / Favorecido / Tipo / Valor / Foto / Devolver; package
    checkboxes and Devolver on open; Foto filename blob link.
27. `DESIGN.md` ledger-row and Do lines no longer require an Ações column on the month payment
    sheet; they name Status and Documento as separate columns on that sheet, and they no longer
    list Resolver / Desfazer / Desmarcar as month-row actions.

## Out of scope

- PagSeguro parser — #109
- Statement form and Contas Documentos column — #108; keep today’s disclosure and filenames
- Gate of confirmation — #110; keep today’s confirm step and `accounts_confirmed` / closed
  visibility
- Matching screen and gestures — #111; this cut only removes them from the month
- Reopening Match / exception domain rules
- HTML mock `GET /prototypes/month-overview` as a binding source — development only
- Preserving `bank_account_id` on close / reopen / restore / Devolver / confirm Locations —
  existing unfiltered paths (25)

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `month` | empty state | 6 — empty Pagamentos / Recebimentos folds stay `open` with no rows and no new copy; 21 — `Nenhum documento sem casamento` |
| screen `month` | loading | n/a — server-rendered GET |
| screen `month` | error state | existing — `@month_error` / `@import_error` `[data-notice="error"]` under the title (close `Importe o extrato de cada conta ativa`, `Há documento faltante`, confirm spreadsheet notice) |
| screen `month` | unauthorised | 24 — unauthenticated `302` `/login`; submitter `404` |
| screen `month` | density and ordering | 5, 6, 8, 13, 18, 22 — blockers, Contas, chips, three open folds, Recebimentos last, `ledger-overview-pay` 3px, pool columns, chips name order |
| screen `month` | destructive action confirms | existing — Fechar `Fechar o mês para envio?`; Restaurar `Restaurar a pasta do mês no arquivo do pacote?`; Reabrir `Reabrir o mês?`; Devolver has no `data-turbo-confirm` |
| HTML `GET /months/:year_month` | response shape | 1, 2, 3, 23 — `200` HTML; closed is the same book minus write controls |
| HTML `GET /months/:year_month` | error shape and codes | 11, 24 — `404`; `302` `/login` |
| HTML `GET /months/:year_month` | who may call | 24 — `require_coordinator_organization` |
| HTML `GET /months/:year_month` | versioning | n/a — HTML GET |
| HTML `GET /months/:year_month` | rate limit | n/a — no limit in this app |
| HTML `GET /months/:year_month` | optional `bank_account_id` | 8–12 — omit all; active id filters movements; bad id `404` |
| HTML month mutate POST/DELETE | response shape | 25 — existing Locations; `422` re-renders month without Resolver |
| HTML `POST /months/:year_month/matches` | response shape | 25 — matches-screen origin stays #111; omitted `screen` still `302` month |
| document visual-identity `month` | structure, tone, next action | 26 |
| document `DESIGN.md` ledger row | structure | 27 |
| collection account chips | grouping, naming, ordering, duplicates, exception | 8, 11 — one chip per active account, `order(:name)`; `Todas`; unknown id `404` |
| collection Pagamentos / Recebimentos / pool | grouping, naming, ordering, duplicates, exception | 13, 18, 22 — existing payment and `listed` orders; pool membership unchanged by the account filter; Recebimentos last |

## Swept

- validation: 11 — unknown / foreign / inactive `bank_account_id` is `404`; close-for-send still refuses missing statements and missing documents (existing strings)
- failure modes: 4, 25 — blocked close is a `margem` sentence with Fechar enabled; `422` re-renders this template without Resolver
- idempotency and retry: n/a — this cut is GET composition; existing close / reopen / confirm / Match uniqueness are unchanged
- authorization: 24 — coordinator + focus; submitter `404`; no Payment text
- concurrency and ordering: n/a — no new write; display order is existing `occurred_on` / `listed`
- data lifecycle: n/a — no new table; nothing to backfill
- external-dependency failure: n/a — no Drive / SEFAZ / mail on this GET; restore remains existing
- state transitions: 1, 2, 3, 7, 23 — Casar only while open and confirmed; closed GET is read-only lists; unconfirmed GET still hides movements; matches GET still exists
- observability: n/a — source names no log, metric, or toast; existing `Pronto.` on confirm / open-month stays

## Impact

| Front | What changes |
|---|---|
| domain | no new term |
| domain | existing term: **Month page** (`GET /months/:year_month`) stops hosting Resolver, N:1, Marcar, and Desfazer; it is close status with Documento payee names, three open folds, chips, and Voltar. Matching stays on **matches**. Callers: `app/views/months/show.html.erb`, `spec/requests/months_spec.rb` (Resolver / N:1 / Ações / Recebimentos-first / `month_h2s` / extra-kind mark offers / 1:1 form selects), `.specs/features/visual-identity/design.md` `month`, `DESIGN.md` ledger-row Ações, `.tasks/month-match.md` criteria 20, 26, 28, 32 (month-origin forms and Casar-while-closed) |
| stored data | nothing to migrate |

`assign_matches_account_filter` / `load_matches_page` today filter Payments on the matches GET
only. This cut applies the same membership to the month GET and also filters Inflows.
`load_month_page` still loads `@format_2_suggestion` for a fold this page must not render.

Shipped `spec/requests/months_spec.rb` examples that look for `Resolver`, `h2` movement titles,
Recebimentos before Pagamentos, Ações, or extra-kind mark inputs on this GET must move those
assertions to `month_matches_spec.rb` or drop them.

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| Month GET filter | `GET /months/:year_month` accepts optional `?bank_account_id=` (integer id of an active BankAccount on the focused organization); omit query for all. Filters Pagamentos and Recebimentos. Pool membership and Contas do not follow it. Missing-document count follows it. Unknown, foreign, or inactive id is `404` (same membership helper as matches) | Client-only chips without a query (HTML mock). Filtering the pool. Ignoring a bad id with `200` |

Folds always `open`, blockers then Contas then the book, chips after Contas, Casar secondary and
open-only, stamp under the title, and Documento payee names are product locks in
`.design/month-overview.md` and reversible in that table; they are criteria, not schema doors.

## Surface

| Route | In | Out | Status | Criteria |
|---|---|---|---|---|
| `GET /months/:year_month` | session, focus, optional `bank_account_id` | close-status HTML, or `404` | `200`, `302`, `404` | 1–24, 26 |
| `POST /months/:year_month/close` | existing `supporting_document_ids[]` | `302` month; `422` this template | `302`, `422`, `404` | 4, 19, 25 |
| `POST /months/:year_month/reopen` | existing | `302` month (Casar returns) | `302`, `422` | 1, 2, 25 |
| `POST /months/:year_month/restore` | existing | `302` month | `302`, `422` | 2, 25 |
| `POST /months/:year_month/account_confirmation` | existing | `302` month; `422` this template | `302`, `422` | 7, 25 |
| `POST /months/:year_month/supporting_documents/:id/return` | existing | `302` month | `302`, `404` | 19, 25 |
| `POST /months/:year_month/matches` | existing; month no longer posts this form | `302` matches when `screen=matches`; else `302` month | `302`, `422`, `404` | 17, 25 |

## Sources

- https://github.com/gutors/ai-accounting-assistant/issues/112 — **binding for this slice**: GET
  month is close status (profile ui); Contas; Pagamentos / unmatched docs / Recebimentos last;
  Ações gone, Documento payee names, exception in Status; no Resolver / N:1 / Marcar / Desfazer;
  three `<details>` default open; filter `bank_account_id` like #111; `Voltar para Início` → `/`;
  pool Data / Favorecido / Tipo / Valor / foto; package checkboxes and Devolver stay. Out:
  PagSeguro, #108, #110, #111
- `.design/month-overview.md` — **binding for the interface**: screen `month`; Livro com
  bloqueio; folds always `open`; chips after Contas before Pagamentos; Casar secondary
  open-and-confirmed only; stamp under title; Foto blob link (documents list does not open the
  file — source amended)
- Conversation, 14 Oct 2026 — folds always open; blockers then Contas then the book; chips
  after Contas; Casar secondary and open-only; stamp under title
- `.design/month-match.md` / `.tasks/month-match.md` — Casar entry; chip `404`; Devolver and
  unmatched-in-package stay on the month; month-match Unresolved 1 closed placement is
  superseded (Casar omitted while closed)
- `DESIGN.md` — livro-caixa; ruled sheet; one red margin; stamp; Fechar stays enabled — amend
  Ações in criterion 27
- `app/views/months/show.html.erb` — live chrome already has Casar secondary, stamp under
  title, Casar omitted while closed; still Resolver / N:1 / Ações / Recebimentos first / old pool
- `app/controllers/application_controller.rb` — `assign_matches_account_filter`,
  `load_month_page`
- `app/assets/tailwind/application.css` — `.month-fold`, `.ledger-overview-pay`,
  `.ledger-overview-pool`, `.stamp-closed`, `.ds-btn-primary` / `.ds-btn-secondary`
- `.specs/features/visual-identity/design.md` — amend in criterion 26
- Open default in Unresolved 1

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | open | Does `Casar pagamentos` keep `bank_account_id` when the month GET is filtered? | Yes — `href` is `/months/2026-05/matches?bank_account_id=` that id when the query is present; unfiltered stays `/months/2026-05/matches` (1) |
