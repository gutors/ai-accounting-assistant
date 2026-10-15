# Month match top band Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: aa54810..b7b9b46 (`aa54810..HEAD`)
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Opened `.design/month-match.md` as a file in the repo (ASCII `matches` screen: sticky band above the pair, `Próxima sugestão` Pagamento | `casar com` | Documento, click-equal confirms, dates `%d/%m`, pool oldest → newest). Opened `.tasks/month-match-top-band.md` criteria 1–18. Compared both to C1–C18 and Landing. No check contradicts a concrete design/task value. Visual unproven is enumerated (spacing, colour, type weight besides C2), not a blanket.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.design/month-match.md` screen `matches` | yes - repo file | none | live open-GET chrome/chips/missing-count/1100px split/empty pool copy are selector-reachable and sit in the Screens table, but C1–C17 do not name them (C18 is the visual-identity markdown). Extra shipped examples in the same request/system files still assert them. Next-control three-region *containment* (sides vs `casar com`) is copy-includes in C4, not region selectors |
| `.tasks/month-match-top-band.md` criteria 1–18 | yes - repo file | none — C1–C18 match the criteria | Unresolved 1 stays Skip (`format_2`); C9 asserts that skip |

## Checks

Named proofs exist in the feature diff and ran at `HEAD` (`./bin/rspec` four files, documentation formatter). First `-e` alternation matched nothing (pipes treated as literals); the four-file invocation listed every named example as passed.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | `#match-confirm` before `.match-split`; copy; extra kinds name order; `border-rule` not `margem`; confirm not after split | `month_matches_spec.rb` example ran, exit 0 | `spec/requests/month_matches_spec.rb:336` `confirm_at < split_at`; `:337` single confirm id; `:344-363` Pagamentos/Documentos/Observação/`Confirmar casamento` then tarifa/honorário/Doação/Zebra; `:348-349` `border-rule` not `margem` | PASS |
| C2 | sticky region contains next `h2` + `#match-confirm`; `position: sticky`; `top: 0`; 1px ink bottom; confirm no ink top | system + request examples ran, exit 0 | `spec/system/month_matches_spec.rb:171-176` computed `sticky` / `0px` / `1px` / confirm `0px`; `spec/requests/month_matches_spec.rb:339-343` CSS `position: sticky`, `top: 0`, `border-bottom: 1px solid var(--color-ink)`, no confirm ink `border-top` | PASS |
| C3 | totaling equal / menos / mais / empty `R$ 0,00` omits verdicts | system example ran, exit 0 | `spec/system/month_matches_spec.rb:110-112` `Pagamentos R$ 220,00` `Documentos R$ 220,00` `Soma igual`; `:118-119` menos; `:126-127` mais; `:132-136` and `:142-144` empty side `R$ 0,00` and no three phrases | PASS |
| C4 | Padaria 1:1 next above confirm | request + model ran, exit 0 | `spec/requests/month_matches_spec.rb:374-387` `h2` `Próxima sugestão` in `.match-top` (`next_band`), hit copy, index before confirm; `spec/models/suggestion_spec.rb:432` `next_one_payment(...) == payment` | PASS |
| C5 | unfiltered next is earlier Fornecedor Norte | request + model ran, exit 0 | `spec/requests/month_matches_spec.rb:400-401` includes `TED — Fornecedor Norte`, not Padaria history; `spec/models/suggestion_spec.rb:442` `[norte, padaria]` → `norte` | PASS |
| C6 | Principal filter next is Padaria | request + model ran, exit 0 | `spec/requests/month_matches_spec.rb:411-415` GET `bank_account_id: principal.id`, Padaria history, not Fornecedor; `spec/models/suggestion_spec.rb:443` filtered `[padaria]` → `padaria` | PASS |
| C7 | 1:N join payees + earliest date + sum | request + model ran, exit 0 | `spec/requests/month_matches_spec.rb:433-435` `13/05`, `Papelaria Norte, Papelaria Norte`, `R$ 155,00`; `spec/models/suggestion_spec.rb:452` returns that payment | PASS |
| C8 | omit next when only exception suggestion; row keeps `Sugestão de exceção` | request + model ran, exit 0 | `spec/requests/month_matches_spec.rb:445-450` h2 absent, confirm present, row includes `Sugestão de exceção`; `spec/models/suggestion_spec.rb:458` `next_one_payment` `be_nil` | PASS |
| C9 | omit next when only `format_2` remains | request + model ran, exit 0 | `spec/requests/month_matches_spec.rb:461-462` h2 absent, confirm present; `spec/models/suggestion_spec.rb:467-468` `payments.size == 2` and `next_one_payment` `be_nil` | PASS |
| C10 | equal click confirms, stay, Casado, drop pool, omit heading | system example ran, exit 0 | `spec/system/month_matches_spec.rb:184-191` click `.match-next__hit`, path `/months/2026-05/matches`, `Match.count == 1`, `matched`/`Casado`, no pool Padaria, no `h2` Próxima sugestão. **Precision:** 302, POST ids, and blank observation are not at the assertion (inferred from persist + stay) | PASS |
| C11 | lesser click checks only; blank POST `422` notice; obs POST `302` Casado | system + two request examples ran, exit 0 | `spec/system/month_matches_spec.rb:203-210` `Match.count == 0`, boxes checked, `Documentos somam menos`, observation `""`; `spec/requests/month_matches_spec.rb:578-582` `:unprocessable_content` and `[data-notice=error]` `Informe a observação do casamento`; `:598-603` `:found` redirect `/months/2026-05/matches` then Casado | PASS |
| C12 | N:1 checkbox POST `302` both Casado | request example ran, exit 0 | `spec/requests/month_matches_spec.rb:519-523` `:found` redirect matches; Dez and Doze include `Casado` | PASS |
| C13 | matches `time` `11/05` + ISO datetime; month GET `11/05/2026` | request example ran, exit 0 | `spec/requests/month_matches_spec.rb:473-474` text `11/05` datetime `2026-05-11`; `:481-482` month page `11/05/2026` | PASS |
| C14 | pool oldest first; index stays listed desc; closed membership this Month | request example ran, exit 0 | `spec/requests/month_matches_spec.rb:286` Padaria index before Mercado; `:304` documents index `[Mercado Silva, Padaria Central]`; `:311` closed payees `["No Pacote"]` | PASS |
| C15 | missing row checkbox, `Documento faltante` `text-margem` `is-block`, no Casar / sugestão payees / Resolver | request example ran, exit 0 | `spec/requests/month_matches_spec.rb:186-198` `is-block`, checkbox, `text-margem`, not Casar / `Sugestão Padaria Central` / Resolver | PASS |
| C16 | Casado `×` `Desfazer casamento`, payee, no checkbox | request example ran, exit 0 | `spec/requests/month_matches_spec.rb:216-223` `data-status=matched`, `×`, aria-label, Casado, Padaria Central, no checkbox | PASS |
| C17 | closed `200`, title, Voltar, no checkbox/next/confirm/marks/`×`/stamp; pool + day/month hold | request example ran, exit 0 | `spec/requests/month_matches_spec.rb:774-792` `:ok`, `maio de 2026`, Voltar, no checkbox/h2/confirm/marks/undo/stamp; payees Padaria then Mercado; times `11/05` `12/05` | PASS |
| C18 | visual-identity `matches` section amended | docs example ran, exit 0 | `spec/docs/visual_identity_month_bank_rows_spec.rb:92-99` includes sticky/`Próxima sugestão`/`casar com`/`11/05`/oldest/click equal/no Casar/`Sugestão {payees}`/`Sugestão de exceção` | PASS |

## Coverage (recomputed)

Members taken from `Suggestion.next_one_payment`, the totaling JS table, POST statuses in the checks, `.design/month-match.md` (one screen), and Landing — not from the author’s Coverage cells.

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| next-pick (6) | 1:1 C4 model+GET · sheet `occurred_on` C5 · filtered array/GET C6 · 1:N C7 · no document suggestion C8 · `format_2` C9 | - |
| totaling verdicts (4) | equal / menos / mais / empty omit C3 | - |
| suggestion click (2) | equal persist C10 · lesser check-only C11 | - |
| confirm HTTP (4) | lesser blank `422` C11 · lesser obs `302` C11 · N:1 `302` C12 · equal via click C10 (browser, not `have_http_status :found`) | C10 does not assert `302` at HTTP |
| dates (2) | matches day/month C13 · month GET with year C13 | - |
| pool (2) | matches asc C14 · documents index listed desc C14 | - |
| payment row copy (2) | missing C15 · Casado C16 | - |
| closed GET (1) | C17 | - |
| designed screens this cut binds (1) | `matches` C1–C18 | live chrome/chips/1100px/empty pool not a C-number |
| visual-identity screens this cut does not bind (6) | — | `login`, `denied`, `home`, `setup`, `documents`, `month` |
| `matches` visual (C2 + exemption) | sticky/`top`/1px ink bottom/no confirm top C2 | spacing, colour, type weight besides C2 |

No extra set named in Landing/test-policy prose without a row. Claims that name status/route (C1 GET, C10–C12, C17) have a request or browser proof; C10 is the thin one (no located `302`).

## Test policy rows

Bar is the checklist section (follows `.cursor/rules/rails.mdc`). Each row judged against files it classifies.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/suggestion.rb` `next_one_payment`; GET matches HTML for next | own layer C4–C9 model · HTTP C4–C9 | yes — six members asserted at `Suggestion`; GET examples for the same members |
| Decides, not reached across a boundary | totaling / sticky CSS / click in Stimulus and CSS | own layer as named | yes — C3/C2/C10/C11 click are system specs; repo has no JS unit runner |
| Entry point that decides nothing | `POST /months/:year_month/matches` origin already shipped; this cut’s lesser/N:1 | request contract | yes — C11 `422`/`302`, C12 `302`; shipped `POST matches omitting screen still 302s month` still in the request file |
| Instrumentation / pass-through | `load_matches_page` reorder; locale `:day_month` | consumer | yes — C14 and C13 request specs |

No unmet row.

## Swept existing (re-read)

- validation / LESSER string: `Match::LESSER` still `"Informe a observação do casamento"` (`app/models/match.rb:7`); C11 asserts it
- idempotency `PAYMENT_TAKEN`: still on `Match` (`app/models/match.rb:7`); request/model examples in `spec/requests/matches_spec.rb` and `spec/models/match_spec.rb`
- concurrency: `persist_confirm` still `Payment.lock` / `SupportingDocument.lock` (`app/models/match.rb:77-78`)
- authorization: GET unauthenticated `302` `/login` and submitter `404` still in `spec/requests/month_matches_spec.rb:804-817`
- `SupportingDocument.listed` still `document_on: :desc, id: :desc` (`app/models/supporting_document.rb:39`); C14
- origin-sensitive month redirect: `POST matches omitting screen still 302s month` still present

## Faults injected

Scratch: `git worktree add /tmp/month-match-top-band-verify HEAD`. Real-tree porcelain recorded first and matched after `git worktree remove --force`. Never mutated the real tree; no stash.

| Mutation | Location | Killed |
|---|---|---|
| `next_one_payment` returns first `missing_document?` (ignores 1-payment proposal) | `app/models/suggestion.rb` | yes — C9 model expected `nil`, got Payment |
| invert `if (this.equalSums())` → `if (!this.equalSums())` before `requestSubmit` | `app/javascript/controllers/month_match_controller.js` | yes — C10 `Match.count` expected 1 got 0 |
| `"Soma igual"` → `"Somas iguais"` | same JS `recompute` | yes — C3 `have_text("Soma igual")` |
| `.match-top` `position: sticky` → `relative` | `app/assets/tailwind/application.css` | yes — C2 computed `position` `relative` |
| `Próxima sugestão` → `Sugestão seguinte` in visual-identity `matches` section | `.specs/features/visual-identity/design.md` | yes — C18 `include("Próxima sugestão")` |

Cap five. Distinct surfaces. No survivor.

## Gate

`./bin/rspec spec/requests/month_matches_spec.rb spec/system/month_matches_spec.rb spec/models/suggestion_spec.rb spec/docs/visual_identity_month_bank_rows_spec.rb --format documentation` — 92 passed, 0 failed (includes extras in those files; every C1–C18 named example appeared and passed).
