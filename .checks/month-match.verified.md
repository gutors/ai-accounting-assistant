# Month match Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 4c04d41759b3e46cb96f1aa34ba1d9451b3ec495..cefce6943d0a2427246a3b6913d5292321f87327
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

Proofs re-ran in full at `cefce694`. Other steps scoped to fix `cefce694` plus every round-1 non-PASS. Sections mark `verified at cefce694` or `carried from 1fb5663`.

Fix `cefce694` added request/system assertions, `spec/controllers/month_match_decisions_spec.rb`, stale Tailwind rebuild in `spec/rails_helper.rb`, and two C31 strip proofs on the checklist (additive proofs, bar not lowered).

## Binding sources

`verified at cefce694` (round-1 Uncovered / arrangement / `Sugestão de exceção` re-judged). Opened `.design/month-match.md` as a repo file; `gh issue view 111` (HTTP fetch of the private issue URL is 404); `.specs/features/visual-identity/design.md` `### matches` and month `Casar pagamentos`.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.design/month-match.md` — binding for the interface, screen `matches` | yes — repo file | none | `~60%` Pagamentos track (C3 asserts wider, not the ratio). Enumerated visual-unproven: spacing, colour, type weight |
| https://github.com/gutors/ai-accounting-assistant/issues/111 — binding for this slice | yes — `gh issue view 111` (HTTP fetch 404) | none | none beyond the design `~60%` note (issue defers interface to `.design/month-match.md`) |
| `.specs/features/visual-identity/design.md` — amended in C32 | yes — `### matches` and month `Casar pagamentos` bullets | none vs C32’s transcribed strings | C32 is a file-read of this artifact, not a second screen |

Round-1 arrangement holes now have checks: title-right `Voltar ao mês` (C1), chips then missing-count then `.match-split` (C2), totaling **under** both sheets (C14), pool ruled grid from 768px (C3 `poolDisplay`), `Sugestão de exceção` (C8). Screens table visual-unproven cells still name spacing, colour, and type weight per screen (plus C3’s proven 1100/stack/768/3px). That exemption is enumerated, not a blanket.

## Checks

Proofs: one `ruby bin/rspec` invocation, 45 examples (41 checklist proofs + 4 own-layer), 0 failures at `cefce694`. System examples C3 and C21 ran, not skipped.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | 200, `h1` `maio de 2026`, `2026-05` `text-meta text-ink-soft`, `Voltar ao mês` → `/months/2026-05` title-right, no Fechar / Recebimentos / stamp | exit 0 | `spec/requests/month_matches_spec.rb:46-62` — `:ok`, `h1` `eq("maio de 2026")`, meta classes, `href` `/months/2026-05`, `justify-between`, kids `[0]` title `[1]` Voltar, omit Fechar / Recebimentos / stamp | PASS |
| C2 | Pagamentos before pool inside `.match-split`; chips then count then split; no `form#close-month`; no `Devolver` | exit 0 | `month_matches_spec.rb:71-83` — headings `eq(["Pagamentos", "Documentos sem casamento"])`, `chip_at < count_at < split_at`, `form#close-month` nil, controls omit `Devolver` | PASS |
| C3 | 1100px two columns Pagamentos wider; below 1100 stack; 768px grid including pool; `ledger-pay` 3px vertical | exit 0 | `spec/system/month_matches_spec.rb:47-50,64-65,67-69,89-94` — `trackCount` 2 and `tracks[0] > tracks[1]`; at 1099 `trackCount` 1; source `@media (min-width: 1100px)` / `768px`; `rowDisplay`/`poolDisplay` `grid`; padding `eq("3px")`; `borderLeft` `eq("3px")` | PASS |
| C4 | chips `Todas` current, then Alfa, Principal; hrefs | exit 0 | `month_matches_spec.rb:92-96` — texts `eq(["Todas", "Conta Alfa", "Conta Principal"])`, `aria-current` `true` on Todas, Alfa href with id | PASS |
| C5 | Principal filter: current chip, Padaria payment, hide Energia, missing `1 …` `text-margem`, pool keeps Padaria | exit 0 | `month_matches_spec.rb:108-118` — current `Conta Principal`, pay includes Padaria not TED, summary `eq("1 pagamento com documento faltante.")` `text-margem`, pool includes Padaria | PASS |
| C6 | unfiltered `2 pagamentos…` `text-margem`; filtered none `Nenhum documento faltante.` without `text-margem` | exit 0 | `month_matches_spec.rb:129-139` — both summary strings and class include / omit `text-margem` | PASS |
| C7 | `bank_account_id` `0` / foreign / inactive → 404 | exit 0 | `month_matches_spec.rb:150-156` — three `have_http_status(:not_found)` | PASS |
| C8 | missing row checkbox, `time` 11/05/2026, history, meta account, `R$ 220,00`, `Documento faltante` `text-margem`, suggestion, `is-block`, 3px `margem` edge, no Resolver; `Sugestão de exceção` on exception-suggestion row | exit 0 | `month_matches_spec.rb:172-190` — checkbox, time, copy, `is-block`, omit Resolver, CSS `border-left: 3px solid var(--color-margem)`, Padaria omits `Sugestão de exceção`, chave-pix includes it | PASS |
| C9 | matched: `×` `Desfazer casamento` `text-margem`, Casado + payee + observation, no checkbox / actions | exit 0 | `month_matches_spec.rb:204-210` — `×`, aria-label, `text-margem`, Casado / Padaria / observation, no checkbox, omits `Ações` | PASS |
| C10 | `bank_fee` / `accountant_fee` / `extra`: status copy, `×` `Desmarcar exceção`, no Resolver | exit 0 | `month_matches_spec.rb:227-231` — loop over three statuses, label include, `×` aria-label, omit Resolver | PASS |
| C11 | payment order `occurred_on`, `id`; no N:1 fold copy | exit 0 | `month_matches_spec.rb:245-246` — ids `eq([earlier.id, same_b.id, same_a.id, later.id])` (same-date id tie-break), body omits `Casar vários pagamentos com um documento` | PASS |
| C12 | pool checkbox, date, payee, `format_reais`, Tipo, listed order; membership unmatched-for-this-month / closed this Month only | exit 0 | `month_matches_spec.rb:271-288` — Mercado then Padaria then `No Pacote`, omit `Outro Mês`; checkbox, time, amounts, Tipo; closed payees `eq(["No Pacote"])` | PASS |
| C13 | empty pool copy; no pool rows | exit 0 | `month_matches_spec.rb:296-297` — include `Nenhum documento sem casamento`, empty `li[data-row="pool-document"]` | PASS |
| C14 | totaling under sheets, 1px ink above, Pagamentos / Documentos, observação `border-rule` not `margem`, confirm then marks in name order | exit 0 | `month_matches_spec.rb:311-335` — `split_at < confirm_at`; source CSS `border-top: 1px solid var(--color-ink)`; `border-rule` not `margem`; Confirmar < tarifa < honorário < Doação < Zebra. Computed 1px also `spec/system/month_matches_spec.rb:121` | PASS |
| C15 | POST from this screen 302 here, Match persists, Casado, payee leaves pool | exit 0 | `month_matches_spec.rb:349-357` — `:found`, `redirect_to("/months/2026-05/matches")`, `Match.count` 1, `data-status` matched, pool omits Padaria | PASS |
| C16 | N:1 302 here, both Casado | exit 0 | `month_matches_spec.rb:373-376` — `redirect_to` matches, both histories include Casado | PASS |
| C17 | N:M no Match, 422, this screen, `BAD_SHAPE` notice | exit 0 | `month_matches_spec.rb:392-398` — `Match.count` 0, `:unprocessable_content`, `h1` maio, omit Fechar, notice eq `BAD_SHAPE` string | PASS |
| C18 | lesser blank obs: no Match, 422, `LESSER` notice, `h1`, `border-rule` | exit 0 | `month_matches_spec.rb:412-417` — count 0, 422, notice `Informe a observação do casamento`, `border-rule` | PASS |
| C19 | filtered confirm keeps `bank_account_id` on Location | exit 0 | `month_matches_spec.rb:432-433` — `redirect_to("…/matches?bank_account_id=#{principal.id}")` | PASS |
| C20 | month-origin POST still 302 `/months/2026-05`; month GET still Resolver and N:1 fold | exit 0 (both) | `spec/requests/matches_spec.rb:21-22` — `redirect_to("/months/2026-05")` (`carried from 1fb5663`); `month_matches_spec.rb:444-445` — include Resolver and N:1 fold | PASS |
| C21 | equal / menos / mais / empty-side `R$ 0,00` and omit three verdicts | exit 0 | `spec/system/month_matches_spec.rb:110-152` — `Soma igual`, `Documentos somam menos`, `Documentos somam mais`, empty-side `R$ 0,00` and `have_no_text` all three | PASS |
| C22 | one checked missing: persist kind, 302 here (filter kept), following GET `×`; honorário / extra same | exit 0 | `month_matches_spec.rb:460-480` — `bank_fee` + Location with query; accountant_fee and extra persist + `redirect_to` matches | PASS |
| C23 | zero or two checked: no except, 422, this screen, selection notice | exit 0 | `month_matches_spec.rb:491-502` — still missing, 422, `h1` maio, notice `Selecione um pagamento para marcar a exceção.` twice | PASS |
| C24 | inactive tarifa / honorário / extra marks absent | exit 0 | `month_matches_spec.rb:518-520` — labels omit `Marcar tarifa`, `Marcar honorário`, `Doação` | PASS |
| C25 | undo casamento / unmark stay here, docs return, no `data-turbo-confirm`; filter preserved when present | exit 0 | `month_matches_spec.rb:531-558` — turbo-confirm nil, `Match.count` 0, `redirect_to` matches, filtered dissolve Location with `bank_account_id`, Documento faltante, pool Padaria, exception DELETE `redirect_to` matches with query | PASS |
| C26 | month-page Desfazer / Desmarcar still 302 `/months/2026-05` | exit 0 (both) | `matches_spec.rb:251-252` — DELETE `redirect_to("/months/2026-05")`; `document_exceptions_spec.rb:17-18` — POST bank_fee `redirect_to("/months/2026-05")` (`carried from 1fb5663`) | PASS |
| C27 | closed GET 200, title, Voltar, no checkbox / confirm / marks / `×`, no stamp | exit 0 | `month_matches_spec.rb:570-580` — `:ok`, h1, Voltar present, checkbox nil, omit confirm/marks, undo aria nil, stamp nil | PASS |
| C28 | confirmed or closed month GET `Casar pagamentos` → matches, before Fechar or stamp | exit 0 | `spec/requests/months_spec.rb:2083-2093` — href matches; `index("Casar pagamentos") < index("Fechar para envio")` and `< data-stamp="closed"` (`carried from 1fb5663`) | PASS |
| C29 | unconfirmed open: omit Casar; GET matches 404 | exit 0 (both) | `months_spec.rb:2104` — texts omit Casar (`carried from 1fb5663`); `month_matches_spec.rb:589` — `:not_found` | PASS |
| C30 | unauth 302 `/login`; submitter 404 omit payment history; `2026-13` and never-opened 404 | exit 0 | `month_matches_spec.rb:594-615` — login redirect, submitter 404 omit `PIX Isolado`, `2026-13` and `2026-06` 404 | PASS |
| C31 | unconfirmed match/exception POST 404 no persist; closed confirm/undo/extra 422 `Mês fechado`; unconfirmed/closed strip POST | exit 0 (seven) | `matches_spec.rb:627` unconfirmed 404; `document_exceptions_spec.rb:403` unconfirmed 404; `matches_spec.rb:487-488` closed POST 422 `Mês fechado`; `matches_spec.rb:504-505` closed DELETE; `document_exceptions_spec.rb:304-305` closed extra POST (`carried from 1fb5663`); `month_matches_spec.rb:627-628` strip unconfirmed 404; `month_matches_spec.rb:640-641` strip closed 422 `Mês fechado` | PASS |
| C32 | `design.md` `matches` section + month Casar entry transcribed | exit 0 | `spec/docs/visual_identity_month_bank_rows_spec.rb:71-93` — include title, Voltar, no Fechar/stamp, chips, 1100px, stacked, checkbox/`×`, empty pool, three verdicts, stay after confirm, month Casar + after confirmation (`carried from 1fb5663`) | PASS |

## Coverage (recomputed)

`verified at cefce694` (rows the fix’s assertions and C31 proofs touch). Authority for designed screens is `.design/month-match.md`, not the view.

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| GET matches chrome (3) | title/Voltar/absences + title-right C1 · split order + chips→count→split C2 · 1100/768 layout C3 | `~60%` track ratio |
| account chips and filter (4) | unfiltered Todas C4 · Principal C5 · count C6 · `0`/foreign/inactive C7 | - |
| payment row statuses (5) | missing C8 · matched C9 · `bank_fee` C10 · `accountant_fee` C10 · `extra` C10 · `Sugestão de exceção` C8 | - |
| payment order / N:1 absence (1) | C11 including same-date `id` | - |
| pool (2) | listed rows C12 · empty C13 · open unmatched + this-Month / closed this-Month-only C12 | - |
| confirm HTTP (6) | chrome C14 (under sheets + 1px ink) · 1:1 C15 · N:1 C16 · N:M C17 · lesser C18 · filter C19 | - |
| month origin unchanged (2) | match POST Location C20 · month Desfazer/Desmarcar C26 | - |
| totaling verdicts (4) | equal · menos · mais · empty omit C21 | - |
| exception strip (3) | one checked C22 (three kinds) · zero/two C23 · inactive omitted C24 | - |
| undo from matches (2) | dissolve C25 · unmark C25 · filter preserved C25 | - |
| closed GET (1) | C27 | - |
| month entry (2) | confirmed/closed C28 · unconfirmed omit + GET 404 C29 | - |
| who may call GET (4) | unauth · submitter · `2026-13` · never opened C30 | - |
| existing write gates (7) | unconfirmed match · unconfirmed exception (month-page route) · closed match POST · closed DELETE · closed extra POST · unconfirmed strip · closed strip C31 | - |
| designed screens this cut binds (2) | `matches` C1–C14, C21, C24, C27, C32 · `month` entry C28–C29, C32 | `~60%` only |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `setup`, `documents` — out of scope |
| `matches` visual (3 properties) | C3 columns, stack, 3px vertical padding, pool grid | spacing, colour, type weight besides C3 |
| `month` entry visual (3 properties) | — | spacing, colour, type weight of `Casar pagamentos` |

## Test policy rows

`verified at cefce694` (row 1 was unmet; own-layer file is new). Judged against the checklist’s `## Test policy` table.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `application_controller.rb` (`after_month_mutate_path`, `assign_matches_account_filter`, `render_after_month_mutate`), `matches_controller.rb` create/destroy origin, `document_exceptions_controller.rb` strip selection | own layer **and** HTTP; one case per member | HTTP: origin matches vs month C15/C20/C17/C26; filter omit/valid/`0`/foreign C4–C7; strip 0/1/2 C22–C23. Own layer: `spec/controllers/month_match_decisions_spec.rb` — month vs matches vs matches+query; omit/valid/`0`/foreign/inactive; matches vs month `render`; strip zero / two / one / missing-id |
| Decides, not reached across a boundary | `app/javascript/controllers/month_match_controller.js` (equal/menos/mais/empty) | own layer, one case per member | met by Cost’s system allocation C21 (four members asserted). No JS unit spec (`carried from 1fb5663`) |
| Entry point that decides nothing | GET `matches#show` chrome/copy | request spec, accepted/rejected/error | C1–C13, C27, C30 (`carried from 1fb5663` classification) |
| Instrumentation / pass-through | view helpers reused (`format_reais`, `payment_status`) | none of its own | follow — covered by request specs (`carried from 1fb5663`) |

## Swept existing

`carried from 1fb5663` (fix did not touch these files).

- `Match::PAYMENT_TAKEN` still `"Pagamento já está em um casamento"` (`app/models/match.rb:7`); `persist_confirm` still `Payment.lock` / `SupportingDocument.lock` (`match.rb:77-78`)
- unconfirmed movements still 404 in `find_month_with_visible_movements` (`application_controller.rb:116-118`)
- closed writes still `Mês fechado` on the named existing POSTs/DELETEs (C31 proofs)

## Faults injected

`verified at cefce694`. Scratch: `git worktree add /tmp/month-match-tlc-verify-r2 HEAD`. Real-tree porcelain before and after: `?? .checks/month-match.verified.md`. Worktree removed.

| Mutation | Location | Killed |
|---|---|---|
| `.match-split` breakpoint `1100px` → `2000px` in source `application.css` | `app/assets/tailwind/application.css` | yes — C3 `trackCount` expected 2 got 1 after `rails_helper` rebuilt Tailwind (`≈ tailwindcss v4.3.3`) |
| closed pool membership always `[nil, month.id]` | `application_controller.rb` `load_month_page` | yes — C12 `closed_payees` expected `["No Pacote"]` |
| `after_month_mutate_path` drops `bank_account_id` query | `application_controller.rb` | yes — own-layer expected `…/matches?bank_account_id=9` |
| `.match-confirm` `border-top` `1px` → `2px` | `application.css` | yes — C14 source regex `1px solid var(--color-ink)` |
| strip selection `ids.size != 1` → `ids.empty?` | `document_exceptions_controller.rb` | yes — own-layer two-id case returned a Payment |

## Gate

`ruby bin/rspec` (45 named examples: 41 checklist proofs + 4 own-layer) — 45 passed, 0 failed at `cefce694`.

## Findings (ranked)

None that fail the gate. Remaining non-blocking: design `~60%` wider track is still only asserted as “wider”; spacing, colour, and type weight stay in the Screens visual-unproven cells.
