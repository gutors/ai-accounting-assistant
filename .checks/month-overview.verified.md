# Month overview Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 73a1d2b..931c2e3
**Round**: 2 - full (every check re-proven at HEAD; C15 re-proved after N:1 plant)
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Opened as files in the repo, except #112 (HTTP fetch 404; opened with `gh issue view 112`). Prototype `GET /prototypes/month-overview` is not binding.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.tasks/month-overview.md` | yes — repo file | none vs C1–C27 | Unresolved 1 stays transcribed (filtered Casar `href`); not settled further |
| https://github.com/gutors/ai-accounting-assistant/issues/112 | yes — `gh issue view 112` | none vs the recorte (close status, folds, chips, Documento, Voltar, pool Foto). Default-open left to the prototype; design locked always `open` | - |
| `.design/month-overview.md` — screen `month` | yes — repo file (ASCII + Livro com bloqueio) | none on copy/order/containment. Density is named `ledger-pay` (3px); C13 names `.ledger-overview-pay` (rows keep both classes; 3px is the value) | spacing, colour, type weight (enumerated in Screens). Native “coordinator may collapse” is not a check |
| `DESIGN.md` ledger-row / Do | yes — Ledger row + Do lines | none vs C27 (Status + Documento; matching undo not a month-row action) | - |
| `.specs/features/visual-identity/design.md` section `month` | yes — `### month` | none vs C26 transcription. Unconfirmed ASCII omits Voltar; prose still requires Voltar first in `<main>` (C3) | - |

Screens table visual unproven is enumerated (spacing, colour, type weight on Voltar, chips, folds, and sheets except C13’s 768px grid and 3px padding). Not a blanket.

Arrangement the design decides: Voltar first in `<main>`; stamp under `YYYY-MM` inside the title block (parent contains `h1`, not Restaurar); blockers then Contas then chips then three `open` folds with Recebimentos last; Pagamentos five columns Data / Histórico / Valor / Status / Documento; pool Data / Favorecido / Tipo / Valor / Foto then Devolver. Covered by C1–C6, C8, C13, C18, C22.

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | 200, `maio de 2026`, `2026-05` meta, Voltar `/` `text-caixa` underline first in main, Início, Casar secondary then Fechar primary, no stamp | exit 0 | `spec/requests/months_spec.rb:2146-2169` — `have_http_status(:ok)`; `h1` `eq("maio de 2026")`; meta `eq("2026-05")` + `text-meta`/`text-ink-soft`; first main link `eq("Voltar para Início")` `eq("/")`; Casar `ds-btn-secondary` `eq("/months/2026-05/matches")` before Fechar `ds-btn-primary`; stamp `be_nil` | PASS |
| C2 | closed: Voltar first, stamp `Mês fechado` `.stamp-closed` under title (parent has `h1`, not Restaurar), Restaurar/Reabrir secondary + confirms, no Casar/Fechar | exit 0 | `spec/requests/months_spec.rb:2182-2197` — Voltar first; stamp text/class; `title_block.at_css("h1")`; `not_to include("Restaurar pasta")` on title_block; confirm copy; body omits Casar/Fechar | PASS |
| C3 | unconfirmed open: Voltar + Fechar, no Casar, no Todas, no `.month-fold` | exit 0 | `spec/requests/months_spec.rb:2207-2212` — include Voltar/Fechar; omit Casar; chip group `be_nil`; folds empty | PASS |
| C4 | blocked open: Fechar present and not `disabled` | exit 0 | `spec/requests/months_spec.rb:2224-2226` — submit present; `disabled` `be_nil` | PASS |
| C5 | Contas `h2` not in details; blocker above Contas; chips then three fold summaries Recebimentos last; no `h2` those titles | exit 0 | `spec/requests/months_spec.rb:2239-2253` — `ancestors("details")` empty; index blocker `<` Contas; summaries `eq([...])`; chips before folds; `month_h2s` omit the three titles | PASS |
| C6 | three folds `open`; empty payments/inflows stay open, no new empty sentence | exit 0 | `spec/requests/months_spec.rb:2263-2271` — `has_attribute?("open")`; payment/inflow rows empty; omit `Nenhum pagamento` / `Nenhum recebimento` | PASS |
| C7 | unconfirmed: confirm `h2` after Contas, `Iniciar fechamento`, no folds | exit 0 | `spec/requests/months_spec.rb:2281-2284` — heading order; submit present; folds empty | PASS |
| C8 | chips Todas current then Alfa then Principal; Contas lists both | exit 0 | `spec/requests/months_spec.rb:2296-2302` — names `eq(["Todas", "Conta Alfa", "Conta Principal"])`; `aria-current` `eq("true")` on Todas; Alfa href with id; bank-account names include both | PASS |
| C9 | filter Principal hides Alfa movements, keeps pool, missing `1 pagamento…` `text-margem`, Falta not on chips, Casar query | exit 0 | `spec/requests/months_spec.rb:2322-2341` — current Principal; omit TED/Pix Alfa; `eq("1 pagamento com documento faltante.")` + `text-margem`; pool Padaria; Casar `matches?bank_account_id=` | PASS |
| C10 | unfiltered `2 pagamentos…` `text-margem`; filtered none `Nenhum documento faltante.` without `text-margem` | exit 0 | `spec/requests/months_spec.rb:2356-2366` | PASS |
| C11 | `bank_account_id` `0` / inactive / foreign → `404` | exit 0 | `spec/requests/months_spec.rb:2378-2385` — three `have_http_status(:not_found)` | PASS |
| C12 | unconfirmed + valid id → `200`, movements hidden | exit 0 | `spec/requests/months_spec.rb:2396-2398` — `:ok`; no `.month-fold`; no payment rows | PASS |
| C13 | Pagamentos head Data/Histórico/Valor/Status/Documento, no Ações; `ledger-overview-pay` 3px; grid from 768px; order `occurred_on`, `id` | exit 0 (both) | `spec/requests/months_spec.rb:2411-2415` — head `eq([...])`; omit Ações; ids order. `spec/system/month_overview_spec.rb:50-54` — `display` `grid`; class `ledger-overview-pay`; padding `3px`; head labels | PASS |
| C14 | missing 22000 Padaria: time, history, meta, `R$ 220,00`, `Documento faltante` `text-margem`, suggestion, `is-block`, empty Documento, no Resolver / matches form | exit 0 | `spec/requests/months_spec.rb:2431-2442` | PASS |
| C15 | Casado 1:N payees in Documento not Status; observation in Status; no Desfazer; **N:1** two payments sharing one document `Padaria Central` alone in Documento | exit 0 | Plant `spec/requests/months_spec.rb:2458-2461` — `Match.confirm(..., payments: [ other, pair ], supporting_documents: [ n1 ])`. Assert `2472-2476` — 1:N `eq("Padaria Central, Mercado Silva")`; N:1 rows `eq("Padaria Central")`; Status omits payees, includes observation; omit Desfazer | PASS |
| C16 | exception Status words, empty Documento, no Desmarcar; closed deactivated extra keeps `name` | exit 0 | `spec/requests/months_spec.rb:2493-2505` — empty document cell; omit Desmarcar; include Tarifa / Honorário / Doação; closed still Doação | PASS |
| C17 | omit N:1 fold, Marcar tarifa/honorário, extra-kind submit while offers active | exit 0 | `spec/requests/months_spec.rb:2519-2522` | PASS |
| C18 | pool listed order; head Data/Favorecido/Tipo/Valor/Foto; `ledger-overview-pool`; Recibo/Nota fiscal amounts | exit 0 | `spec/requests/months_spec.rb:2551-2565` — head first 5; ids `[mercado, padaria]`; tipos and amounts; `.ledger-overview-pool` | PASS |
| C19 | open: checkbox `form="close-month"` payee label; packed Devolver `text-margem` underline to return route, no checkbox | exit 0 | `spec/requests/months_spec.rb:2579-2588` | PASS |
| C20 | Foto `foto.jpg` `text-caixa` underline blob href, no `target`; nota cell empty | exit 0 | `spec/requests/months_spec.rb:2617-2626` — text/class; `href` includes `/rails/active_storage/`; `target` `be_nil`; nota no link | PASS |
| C21 | empty pool copy; closed omits checkbox and Devolver | exit 0 | `spec/requests/months_spec.rb:2636-2646` | PASS |
| C22 | Recebimentos last, three columns, history+account+amount, omit `Documento faltante` | exit 0 | `spec/requests/months_spec.rb:2658-2665` — last summary; head three columns; inflow text; omit Documento faltante. Filter path is C9 | PASS |
| C23 | closed folds `open`, no statement forms, omit Casar, matches GET `200` | exit 0 | `spec/requests/months_spec.rb:2676-2683` | PASS |
| C24 | unauth `302` `/login`; submitter `404` omit PIX Isolado; `2026-13` and never-opened `404` | exit 0 (four) | `spec/requests/months_spec.rb:9-10`, `359-360`, `182`, `191` | PASS |
| C25 | existing close/reopen Locations; `422` month without Resolver; matches-origin `302` matches; omit `screen` `302` month | exit 0 (five named) | `spec/requests/close_spec.rb:126-127` `redirect_to("/months/2026-05")`; `spec/requests/reopen_spec.rb:22-23` same; `spec/requests/months_spec.rb:2694-2696` `unprocessable_content` omit Resolver; `spec/requests/month_matches_spec.rb:349-350` matches Location; `447` month Location | PASS |
| C26 | visual-identity `month` transcribed from `.design/month-overview.md` | exit 0 | `spec/docs/visual_identity_month_overview_spec.rb:9-33` — Voltar first in main, Casar secondary open+confirmed, stamp under YYYY-MM, folds, chips, 404, Documento, no Resolver/N:1, Foto `url_for`, close-month, Devolver | PASS |
| C27 | DESIGN ledger-row / Do: Status + Documento, not Ações / Resolver as month-row | exit 0 | `spec/docs/design_ledger_row_spec.rb:9-13` | PASS |

C15 plant at HEAD is N:1 (`other` + `pair` on one `n1` document), not a second 1:1. A 1-payment-only Documento cell leaves N:1 empty; that mutant is killed (faults).

C25’s prose also names restore, account_confirmation, and Devolver Locations. Those are not on the named Proof lines; existing examples `spec/requests/restore_spec.rb:26`, `spec/requests/months_spec.rb:1844`, `spec/requests/month_returns_spec.rb:22` still assert `redirect_to("/months/2026-05")` with no query. Not treated as a missing assertion on the named proofs.

## Coverage (recomputed)

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| designed screens (1) | `month` C1–C23, C26 | - |
| month chrome states (3) | open confirmed C1 · closed C2 · unconfirmed open C3 | - |
| `bank_account_id` membership (5) | omit C8 · valid Principal C9 · `0` C11 · inactive C11 · foreign C11 | - |
| payment Status/Documento display (5) | missing C14 · matched 1:N C15 · N:1 C15 · `bank_fee`/`accountant_fee`/`extra` C16 · closed deactivated extra C16 | - |
| who may call month GET (4) | unauthenticated C24 · submitter C24 · invalid year_month C24 · never opened C24 | - |

Authority for designed screens is `.design/month-overview.md` (one screen `month`). Payment display members taken from the design (missing, Casado 1:N and N:1, exception kinds). Membership members taken from Landing / C11 (omit, valid, `0`, inactive, foreign).

No extra enumeration in Landing without a proof: `apply_bank_account_movement_filter` on payments, missing count, and inflows is C9/C10 at the HTTP boundary.

## Test policy rows

Bar: `.cursor/rules/rails.mdc` (decision at own layer + request spec at HTTP; no view specs in this repo).

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `assign_matches_account_filter` | own layer + HTTP | yes — `spec/controllers/month_match_decisions_spec.rb` (existing omit/valid/`0`/foreign/inactive) · C11 HTTP |
| Decides, reached across a boundary | `apply_bank_account_movement_filter` | own layer + HTTP | HTTP C8–C10 yes. Own-layer not added; checklist evidence scoped own-layer to the 404 membership helper. Filter of inflows/payments is asserted only at the request boundary |
| Entry / view HTML | `app/views/months/show.html.erb` | request spec (repo has no view specs) | yes — C1–C23, C25 `422` |
| User-visible CSS density | `application.css` `.ledger-overview-pay` | system spec | yes — C13 cuprite |
| Document transcription | `design.md` `month`, `DESIGN.md` ledger-row | file-read spec | yes — C26, C27 |

## Swept existing

- validation / close refusals: `app/models/month.rb:5-6` still `MISSING_DOCUMENT` / `MISSING_STATEMENT`
- authorization: `require_coordinator_organization` `app/controllers/application_controller.rb:56-63` — no focus → `/login`; non-coordinator `head :not_found`
- C11 membership helper still `find_by(id:, active: true)` then `head :not_found` (`application_controller.rb:135-138`)

## Faults injected

Scratch worktree `/tmp/month-overview-verify-scratch` at `931c2e3`. Real-tree porcelain unchanged after remove.

| Mutation | Location | Killed |
|---|---|---|
| Documento payees only when `match.payments.size == 1` (N:1 empty) | `app/views/months/show.html.erb` matched cell | yes — C15 `eq("Padaria Central")` got `""` (`months_spec.rb:2475`) |
| skip `@inflows` filter | `apply_bank_account_movement_filter` | yes — C9 `not_to include("Pix Alfa")` |
| Voltar `href` `/` → `/home` | `app/views/months/show.html.erb` | yes — C1 `eq("/")` got `"/home"` |
| bad `bank_account_id` returns true instead of 404 | `assign_matches_account_filter` | yes — C11 expected 404 got 200 |
| `.ledger-overview-pay` padding `3px` → `4px` | `app/assets/tailwind/application.css` | yes — C13 `paddingTop` `4px` |

Cap 5; each killed a different named proof.

## Gate

`bin/rspec` one invocation, 35 named examples, 0 failed (includes cuprite C13). HEAD `931c2e3`.
