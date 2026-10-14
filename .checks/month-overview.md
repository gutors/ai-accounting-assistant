# Month overview

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/month-overview.md` marks screen `month` binding through `.design/month-overview.md` (criteria 1–22, 26).

Sources:

- `.tasks/month-overview.md` — criteria 1–27, one door, the sweep. Unresolved 1 stays at the transcribed answer: filtered `Casar pagamentos` `href` is `/months/2026-05/matches?bank_account_id=` that id; unfiltered stays `/months/2026-05/matches`. Nothing under Unresolved is settled beyond that transcription
- https://github.com/gutors/ai-accounting-assistant/issues/112 — **binding for this slice**: GET month is close status; Contas; Pagamentos / unmatched docs / Recebimentos last; Ações gone, Documento payee names, exception in Status; no Resolver / N:1 / Marcar / Desfazer; three `<details>` default open; filter `bank_account_id` like #111; `Voltar para Início` → `/`; pool Data / Favorecido / Tipo / Valor / foto; package checkboxes and Devolver stay. Out: PagSeguro, #108, #110, #111
- `.design/month-overview.md` — **binding for the interface**: screen `month`. Opened as a file in the repo (ASCII, Livro com bloqueio, folds always `open`, chips after Contas, Casar secondary open-and-confirmed only, stamp under title, Foto blob link). HTML mock `GET /prototypes/month-overview` is development only and is not a binding source
- Conversation, 14 Oct 2026 — folds always open; blockers then Contas then the book; chips after Contas; Casar secondary and open-only; stamp under title
- `.design/month-match.md` / `.tasks/month-match.md` — Casar entry; chip `404`; Devolver and unmatched-in-package stay on the month; month-match Unresolved 1 closed placement is superseded (Casar omitted while closed)
- `DESIGN.md` — livro-caixa; ruled sheet; one red margin; stamp; Fechar stays enabled — amend Ações in criterion 27
- `app/views/months/show.html.erb` — live chrome already has Casar secondary, stamp under title, Casar omitted while closed; still Resolver / N:1 / Ações / Recebimentos first / old pool
- `app/controllers/application_controller.rb` — `assign_matches_account_filter`, `load_month_page`
- `app/assets/tailwind/application.css` — `.month-fold`, `.ledger-overview-pay`, `.ledger-overview-pool`, `.stamp-closed`, `.ds-btn-primary` / `.ds-btn-secondary`
- `.specs/features/visual-identity/design.md` — amend in criterion 26
- Open default in Unresolved 1 as transcribed in the task

## Out of scope

- PagSeguro parser — #109
- Statement form and Contas Documentos column — #108; keep today’s disclosure and filenames
- Gate of confirmation — #110; keep today’s confirm step and `accounts_confirmed` / closed visibility
- Matching screen and gestures — #111; this cut only removes them from the month
- Reopening Match / exception domain rules
- HTML mock `GET /prototypes/month-overview` as a binding source — development only
- Preserving `bank_account_id` on close / reopen / restore / Devolver / confirm Locations — existing unfiltered paths (C25)
- Settling Unresolved 1 beyond the task’s transcribed filtered Casar `href`

## Landing

Touches `GET /months/:year_month` (Voltar, three open folds, chips, Documento column, matching gestures gone) and transcribes visual-identity `month` plus `DESIGN.md` ledger-row Ações. Reuses `assign_matches_account_filter` membership, `load_month_page` unmatched membership, `require_coordinator_organization`, month cell grammar (`is-block`, `format_reais`, `payment_status`, `text-margem`), package checkboxes / Devolver, and the matches GET from #111.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Month GET filter | `GET /months/:year_month` accepts optional `?bank_account_id=` (integer id of an active BankAccount on the focused organization); omit query for all. Filters Pagamentos and Recebimentos. Pool membership and Contas do not follow it. Missing-document count follows it. Unknown, foreign, or inactive id is `404` (same membership helper as matches) | Client-only chips without a query (HTML mock). Filtering the pool. Ignoring a bad id with `200` |

- Nothing else in this change is hard to reverse. Folds always `open`, blockers then Contas then the book, chips after Contas, Casar secondary and open-only, stamp under the title, and Documento payee names are product locks in `.design/month-overview.md` and reversible in that table

## Screens (ui)

Opened `.design/month-overview.md` as a file. Arrangement below is what C1–C23 plus the `month` section of `design.md` (C26) require. Tokens stay the month system (`caixa`, `margem`, `rule`, `ink-soft`, `ledger-overview-pay`, `month-fold`). Prototype `/prototypes/month-overview` is not a source for these rows.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `month` | `h1` month in words (`maio de 2026`); `2026-05` in `text-meta text-ink-soft` under it; first `<main>` link `Voltar para Início` to `/` (`text-caixa` underline); header `Início` to `/`; title-right `Casar pagamentos` `.ds-btn-secondary` then `Fechar para envio` `.ds-btn-primary` while open and confirmed; closed: `[data-stamp="closed"]` `Mês fechado` `.stamp-closed`, title-right `Restaurar pasta` / `Reabrir` `.ds-btn-secondary`, no Casar / Fechar; unconfirmed open: Voltar + Fechar, no Casar, no `Todas`, no `.month-fold`; Fechar present and not `disabled` while blocked; `h2` `Contas bancárias` not in `<details>`; blocking sentence above that `h2`; chips `role="group"` `aria-label` `Conta bancária` `Todas` then accounts by name; three `<details open class="month-fold">` summaries `Pagamentos` / `Documentos sem casamento` / `Recebimentos`; no `h2` with those three titles; Pagamentos head Data / Histórico / Valor / Status / Documento (no Ações); Status words + suggestion meta, Documento payees or empty; no Resolver / N:1 / Marcar / Desfazer / Desmarcar; pool Data / Favorecido / Tipo / Valor / Foto / Devolver; empty pool `Nenhum documento sem casamento`; Recebimentos last three columns, no `Documento faltante` | Voltar first in `<main>`; stamp in the title block under `YYYY-MM` (parent contains `h1`, not `Restaurar pasta`); blockers then Contas then chips then three folds Recebimentos last; chips after Contas (absent while unconfirmed); sheet grid from 768px; `ledger-overview-pay` 3px vertical | spacing, colour, type weight on Voltar, chips, folds, and sheets (except C13’s 768px grid and 3px `ledger-overview-pay` padding, which are proven) |

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
- `bank_account_id` membership is the existing `assign_matches_account_filter` decision — already proven at controller layer in `spec/controllers/month_match_decisions_spec.rb` (omit, valid, `0`, foreign, inactive); this cut adds the same members at the month GET boundary
- HTML copy, fold order, and Documento cells are view decisions; this repo has no view specs — request specs on `GET /months/:year_month`
- C13 768px grid / 3px padding is a user-visible flow a request spec cannot settle — system spec (cuprite), same stack as `spec/system/month_matches_spec.rb`
- C26 / C27 are document transcriptions — file-read specs like `spec/docs/visual_identity_month_bank_rows_spec.rb`
- No new Match domain table

Cost: request examples for C1–C12, C13 labels, C14–C25; system example for C13 density; file-read for C26–C27.

## Checks

Criteria 1–27 map to C1–C27. Unresolved 1 stays at the transcribed filtered Casar `href`.

### S1 - GET chrome · 3 files · 50 KB · ~13k

**C1** - Given a signed-in coordinator of the focused organization and open Month `2026-05` with `accounts_confirmed` true, when `GET /months/2026-05` runs, then the status is `200`, `h1` is `maio de 2026`, `2026-05` is in `text-meta text-ink-soft` under it, the first link in `<main>` has text `Voltar para Início` and `href` `/` and classes `text-caixa` plus underline, the header still includes a link `Início` to `/`, title-right includes `Casar pagamentos` with class `ds-btn-secondary` and `href` `/months/2026-05/matches` before `Fechar para envio` with class `ds-btn-primary`, and `[data-stamp="closed"]` is absent.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month chrome is Voltar title Casar Fechar and omits stamp"`

**C2** - Given that Month is closed, when that GET runs, then `Voltar para Início` remains first in `<main>`, `[data-stamp="closed"]` is `Mês fechado` with class `stamp-closed` and sits in the title block under `2026-05` (its parent contains `h1`, not `Restaurar pasta`), title-right includes `Restaurar pasta` and `Reabrir` each with class `ds-btn-secondary` and their existing `data-turbo-confirm` copy, and the body includes neither `Casar pagamentos` nor `Fechar para envio`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "closed GET month Voltar stamp under title Restaurar Reabrir omits Casar Fechar"`

**C3** - Given `accounts_confirmed` false and the month open, when that GET runs, then the body includes `Voltar para Início` and `Fechar para envio`, does not include `Casar pagamentos`, and includes no chip `Todas` and no `<details class="month-fold">`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed GET month Voltar Fechar omits Casar chips and folds"`

**C4** - While the month is open and either the missing-document count is greater than 0 or an active account lacks a statement, `Fechar para envio` remains present and is not `disabled`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "blocked open month Fechar para envio is present and not disabled"`

### S2 - Composition · 2 files · 28 KB · ~7k

**C5** - Given criterion 1’s confirmed open month, when that GET runs, then `h2` `Contas bancárias` is not inside `<details>`, the blocking sentence sits above that `h2`, and after Contas the document order is: the chip group, then `<details class="month-fold">` whose `<summary>` is `Pagamentos`, then one whose `<summary>` is `Documentos sem casamento`, then one whose `<summary>` is `Recebimentos`. There is no `h2` with those three titles.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month Contas then chips then three fold summaries Recebimentos last"`

**C6** - On that GET, each of those three `<details>` has the `open` attribute. Given zero Payments, the Pagamentos fold is still `open` and has no `li[data-row="payment"]`. Given zero Inflows, the Recebimentos fold is still `open` and has no `li[data-row="inflow"]` (no new empty sentence). Empty pool copy is C21.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month three folds stay open with empty payments and inflows"`

**C7** - Given criterion 3’s unconfirmed open month, when that GET runs, then `h2` `Confirmar contas para fechamento` still follows `h2` `Contas bancárias`, submit `Iniciar fechamento` remains, and the three movement folds are absent.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed GET month confirm step follows Contas and omits folds"`

### S3 - Account filter · 4 files · 40 KB · ~10k

**C8** - Given two active BankAccounts `Conta Alfa` and `Conta Principal` (ledger name order) and movements visible, when `GET /months/2026-05` runs with no `bank_account_id`, then a group `role="group"` `aria-label` `Conta bancária` includes `Todas` with `aria-current` `true`, then `Conta Alfa`, then `Conta Principal`; `Todas` `href` is `/months/2026-05`; `Conta Alfa` `href` is `/months/2026-05?bank_account_id=` that account’s id. Contas still lists both accounts.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month chips Todas Alfa Principal with Todas current"`

**C9** - Given `Conta Principal` has a missing-document Payment of `22000` cents (`Pix enviado — Padaria Central`) and an Inflow of `6300` cents, and `Conta Alfa` has a missing-document Payment of `45000` cents (`TED — Energia Ltda`) and an Inflow whose history is `Pix Alfa`, when `GET /months/2026-05?bank_account_id=` the Principal id runs, then `aria-current` is on `Conta Principal` not `Todas`, Pagamentos includes `Pix enviado — Padaria Central` and that account’s name in meta and does not include `TED — Energia Ltda`, Recebimentos includes `R$ 63,00` and does not include `Pix Alfa`, the missing sentence is `1 pagamento com documento faltante.` in `text-margem`, an unmatched SupportingDocument `Padaria Central` still appears on Documentos sem casamento, `Falta o extrato` still follows every active account (not the chip), and `Casar pagamentos` `href` is `/months/2026-05/matches?bank_account_id=` that Principal id (Unresolved 1).
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month filter Principal hides Alfa movements keeps pool and Casar query"`

**C10** - When that GET runs unfiltered with those two missing payments, then the missing sentence is `2 pagamentos com documento faltante.` in `text-margem`. When every payment on the filtered set is matched or excepted, the missing sentence is `Nenhum documento faltante.` without `text-margem`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month unfiltered missing count is two and filtered none omits margem"`

**C11** - Given `bank_account_id` is `0`, an inactive BankAccount id of this organization, or an id that is not an active BankAccount of the focused organization, when `GET /months/2026-05` runs with that query, then the status is `404`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month unknown inactive or foreign bank_account_id is 404"`

**C12** - Given criterion 3’s unconfirmed open month and a valid active `bank_account_id`, when that GET runs with that query, then the status is `200` and movements stay hidden (criterion 3).
Proof: `bin/rspec spec/requests/months_spec.rb -e "unconfirmed GET month with valid bank_account_id is 200 and hides movements"`

### S4 - Pagamentos · 4 files · 45 KB · ~11k

**C13** - On criterion 1’s GET, the Pagamentos sheet head (from `768px`) is `Data`, `Histórico`, `Valor`, `Status`, `Documento`. There is no `Ações`. Rows use `ledger-overview-pay` density (`3px` vertical) and existing payment order (`occurred_on`, `id`).
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month Pagamentos head Data Historico Valor Status Documento no Acoes"`
Proof: `bin/rspec spec/system/month_overview_spec.rb -e "month Pagamentos ledger-overview-pay 3px grid at 768px"`

**C14** - Given a missing-document Payment `22000` cents on `2026-05-11`, history `Pix enviado — Padaria Central`, account `Conta Principal`, and a 1:1 Suggestion whose payee is `Padaria Central`, when that GET runs, then `li[data-row="payment"][data-status="missing"]` includes `time` for `occurred_on`, that history, meta `Conta Principal`, `R$ 220,00`, `Documento faltante` in `text-margem`, `Sugestão Padaria Central` under Status, class `is-block`, an empty Documento cell, and neither `Resolver` nor a `form` to `/months/2026-05/matches`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month missing payment suggestion empty Documento and no Resolver"`

**C15** - Given that payment is Casado with payees `Padaria Central` and `Mercado Silva` and observation `desconto não documentado`, when that GET runs, then `data-status` is `matched`, Status includes `Casado` and `desconto não documentado` and does not include those payees, Documento is `Padaria Central, Mercado Silva`, and there is no `Desfazer casamento`. A second missing payment Casado N:1 with one document `Padaria Central` shows that payee alone in Documento.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month Casado Documento payees observation not in Status no Desfazer"`

**C16** - Given that payment is `bank_fee`, when that GET runs, then Status is `Tarifa bancária`, Documento is empty, and there is no `Desmarcar exceção`. The same empty Documento and absent undo hold for `accountant_fee` / `extra` (Status is `Honorário do contador` or the extra kind `name`). Closed month with a deactivated extra kind still shows that `name` in Status (existing).
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month exception Status empty Documento no Desmarcar including closed deactivated extra"`

**C17** - On that GET, the body includes neither `Casar vários pagamentos com um documento` nor `Marcar tarifa` nor `Marcar honorário` nor an extra-kind submit, including when those organization offers are active.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month omits N:1 Marcar tarifa honorario and extra kind submit"`

### S5 - Documentos sem casamento · 2 files · 25 KB · ~6k

**C18** - Given unmatched listed documents, a recibo `Padaria Central` `22000` cents on `2026-05-11` with photo filename `foto.jpg` and a nota fiscal `Mercado Silva` `18000` cents on `2026-05-12` with no photo, when criterion 1’s GET runs, then `li[data-row="pool-document"]` rows are Data (`time` `document_on`), Favorecido, Tipo `Recibo` or `Nota fiscal`, `format_reais` Valor, Foto, then Devolver. Order is existing `listed` (`document_on` desc, `id` desc). Membership is existing unmatched-for-this-month. The sheet uses `ledger-overview-pool`. Head labels are `Data`, `Favorecido`, `Tipo`, `Valor`, `Foto`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month pool rows date payee tipo valor foto in listed order"`

**C19** - Given an open month, a document with `month_id` nil has a checkbox `form="close-month"` whose label is the payee; a document with `month_id` this Month has quiet `Devolver` (`text-margem` underline) posting to the existing return route and has no close checkbox.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month open pool close checkbox and Devolver"`

**C20** - On the recibo row, Foto is a `text-caixa` underlined link whose text is `foto.jpg` and whose `href` is `url_for` of that photo blob (same tab, no `target="_blank"`). On the nota fiscal row, Foto has no link and no filename.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month pool Foto filename blob link or empty"`

**C21** - Given no unmatched documents for that membership, when that GET runs, then the Documentos sem casamento fold includes `Nenhum documento sem casamento` and no `li[data-row="pool-document"]`. Given the month is closed, the pool has no checkbox and no `Devolver`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month empty pool copy and closed pool omits checkbox Devolver"`

### S6 - Recebimentos and closed lists · 3 files · 25 KB · ~6k

**C22** - Recebimentos remains Data, Histórico (history + account name in meta), Valor; it is the last fold; it does not include `Documento faltante`. It follows the same `bank_account_id` filter as Pagamentos (C9).
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET month Recebimentos last fold three columns omits Documento faltante"`

**C23** - Given Month `2026-05` is closed, when that GET runs, then the three folds remain `open`, Contas has no `Incluir extrato` / `Substituir extrato`, and `GET /months/2026-05/matches` is still `200` (existing) while the month body omits `Casar pagamentos`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "closed GET month folds open no statement forms omits Casar matches still 200"`

### S7 - Who may call, existing writes, binding docs · 6 files · 80 KB · ~20k

**C24** - Unauthenticated `GET /months/2026-05` responds `302` to `/login`. A submitter with focus, when that GET runs, receives `404` and the body omits Payment history (existing coordinator-only month leak rule). `GET /months/2026-13` and a year_month never opened remain `404`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "unauthenticated GET /months/2026-05 responds 302 to /login"`
Proof: `bin/rspec spec/requests/months_spec.rb -e "submitter GET /months/2026-05 responds 404 and omits PIX Isolado"`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-13 responds 404"`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-04 when never opened responds 404"`

**C25** - `POST /months/2026-05/close`, `reopen`, `restore`, `account_confirmation`, and Devolver keep their existing statuses and Locations (no `bank_account_id` on those redirects). `422` re-renders this GET’s template without `Resolver`. Confirm / exception / undo **from the matches screen** keep #111 Locations. A `POST /months/2026-05/matches` that still omits `screen=matches` keeps `302` `/months/2026-05` (no month form posts it).
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close ready month persists closed 302 and writes once"`
Proof: `bin/rspec spec/requests/reopen_spec.rb -e "POST reopen persists open 302 and does not write"`
Proof: `bin/rspec spec/requests/months_spec.rb -e "422 close re-renders month without Resolver"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches from this screen 302s here Casado and drops pool payee"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches omitting screen still 302s month"`

**C26** - `.specs/features/visual-identity/design.md` section `month` — `GET /months/:year_month` — is transcribed from `.design/month-overview.md`: quiet `Voltar para Início` first in `<main>` to `/`; Casar `.ds-btn-secondary` only while open and confirmed, before Fechar; stamp under `YYYY-MM` not on the action row; closed title-right only Restaurar / Reabrir; blockers then Contas then chips then Pagamentos / Documentos sem casamento / Recebimentos last; three `<details open>` with summary headings; chips `Todas` then active accounts by name, `?bank_account_id=`, default all, Pagamentos + Recebimentos only, pool unfiltered, unknown id `404`; Pagamentos columns Data / Histórico / Valor / Status / Documento (payee names; empty on missing and exception); no Resolver / N:1 / Marcar / Desfazer; suggestion meta under Status; pool Data / Favorecido / Tipo / Valor / Foto / Devolver; package checkboxes and Devolver on open; Foto filename blob link.
Proof: `bin/rspec spec/docs/visual_identity_month_overview_spec.rb -e "visual-identity month is close status folds chips Documento no Resolver"`

**C27** - `DESIGN.md` ledger-row and Do lines no longer require an Ações column on the month payment sheet; they name Status and Documento as separate columns on that sheet, and they no longer list Resolver / Desfazer / Desmarcar as month-row actions.
Proof: `bin/rspec spec/docs/design_ledger_row_spec.rb -e "DESIGN ledger row Status and Documento not Acoes Resolver"`

## Swept

- validation: C11 — unknown / foreign / inactive `bank_account_id` is `404`; close-for-send still refuses missing statements and missing documents (existing strings)
- failure modes: C4, C25 — blocked close is a `margem` sentence with Fechar enabled; `422` re-renders this template without Resolver
- idempotency and retry: n/a — this cut is GET composition; existing close / reopen / confirm / Match uniqueness are unchanged
- authorization: C24 — coordinator + focus; submitter `404`; no Payment text
- concurrency and ordering: n/a — no new write; display order is existing `occurred_on` / `listed`
- data lifecycle: n/a — no new table; nothing to backfill
- external-dependency failure: n/a — no Drive / SEFAZ / mail on this GET; restore remains existing
- state transitions: C1, C2, C3, C7, C23 — Casar only while open and confirmed; closed GET is read-only lists; unconfirmed GET still hides movements; matches GET still exists
- observability: n/a — source names no log, metric, or toast; existing `Pronto.` on confirm / open-month stays

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| designed screens (1) | `month` C1–C23, C26 | - |
| month chrome states (3) | open confirmed C1 · closed C2 · unconfirmed open C3 | - |
| `bank_account_id` membership (5) | omit C8 · valid Principal C9 · `0` C11 · inactive C11 · foreign C11 | - |
| payment Status/Documento display (5) | missing C14 · matched 1:N C15 · N:1 C15 · `bank_fee`/`accountant_fee`/`extra` C16 · closed deactivated extra C16 | - |
| who may call month GET (4) | unauthenticated C24 · submitter C24 · invalid year_month C24 · never opened C24 | - |

- Claims naming a status code, route or response shape: C1, C2, C11, C12, C23, C24, C25 — each has a proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1–S7 = ~73k tokens of reading floor (`spec/requests/months_spec.rb` 94 KB shared once, `show.html.erb` 17 KB, `application_controller.rb`, `month_matches_spec.rb` 31 KB, `DESIGN.md` + visual-identity 45 KB). All slices stay on the month GET / `months_spec` surface; S7’s docs files are small. Under the 150k budget this is one batch. No mid-feature handoff.
