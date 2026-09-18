# Unmatched documents in the package and restore month folder Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: fcaa6bccdeb42107a2d9b5bac72ccf082325a624..c25c2812259423674044ab82c257f410a74588fe
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

Proofs ran at `HEAD` `c25c281` in one invocation over the 13 spec files named by C1–C45 (`--format json`). 543 examples, 0 failures; all 78 named proof examples present and `passed`. Named tests are new in this range (not untouched pre-feature examples).

## Binding sources

No source marked binding. Checklist: "No design source for the screens." Sources listed are issues, task, CONTEXT, ADRs — not marked binding for the interface. Step 1 is a line, not an investigation.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| (none marked binding) | n/a | n/a | n/a |

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | close with Padaria id: 302 to `/months/2026-05`, closed, `month_id` set, `match_id` nil, `notas-sem-casamento/` path, not under `notas/` | batched JSON passed (`POST close with Padaria id…`; `close with Padaria assigns month_id…`; `unmatched-in-package recibo path…`) | `spec/requests/close_spec.rb:587-594` `have_http_status(:found)` `redirect_to("/months/2026-05")` `closed? == true` `month_id == month.id` `match_id` nil, path included, `notas/` grep empty; `spec/models/month_spec.rb:229-232` closed + `month_id` + `match_id` nil; `spec/models/month_package_spec.rb:73-74` literal `notas-sem-casamento/recibo-2026-05-11-padaria-central-#{id}.jpg` | PASS |
| C2 | omit or empty `supporting_document_ids`: 302, Padaria `month_id` nil, no `notas-sem-casamento/` | batched JSON passed (omit; empty list; model without documents) | `spec/requests/close_spec.rb:603-605` and `:614-616` `:found`, `month_id` nil, `grep(/\Anotas-sem-casamento\//) == []`; `spec/models/month_spec.rb:240` `month_id` nil | PASS |
| C3 | only Padaria id: Padaria assigned, Mercado `month_id` nil, writer has Padaria path, no Mercado id | batched JSON passed | `spec/requests/close_spec.rb:626-629` Padaria `month_id`, Mercado nil, Padaria path included, Mercado id grep empty; `spec/models/month_spec.rb:249-250` same `month_id` split | PASS |
| C4 | other-org id: 404, A open, B `month_id` nil, writer not invoked | batched JSON passed | `spec/requests/close_spec.rb:644-647` `:not_found`, `closed? == false`, `month_id` nil, `writer.calls.size == calls` | PASS |
| C5 | June unmatched-in-package: 422 `Documento já pertence a um mês`, May open, June doc unchanged, no write | batched JSON passed | `spec/requests/close_spec.rb:659-663` `:unprocessable_content`, body includes `Documento já pertence a um mês`, May open, `month_id == month_june.id`, writer unchanged; `spec/models/month_spec.rb:261-264` same error + no write | PASS |
| C6 | matched document: 422 `Documento já está em um casamento`, month open, no write | batched JSON passed | `spec/requests/close_spec.rb:675-678` 422 + message + open + writer unchanged; `spec/models/month_spec.rb:275-277` same | PASS |
| C7 | writer raise: 422 `Não foi possível gravar no arquivo do pacote`, open, Padaria `month_id` nil | batched JSON passed | `spec/requests/close_spec.rb:688-691` 422 + message + open + `month_id` nil; `spec/models/month_spec.rb:290-292` same | PASS |
| C8 | missing document 22000: 422 `Há documento faltante`, `month_id` nil, no write | batched JSON passed | `spec/requests/close_spec.rb:702-705` 422 + message + `month_id` nil + writer unchanged; `spec/models/month_spec.rb:302-304` same | PASS |
| C9 | GET open: 200, `Documentos sem casamento`, Padaria, close checkbox id, Fechar turbo confirm | batched JSON passed | `spec/requests/months_spec.rb:1201-1205` `:ok`, includes `Documentos sem casamento`, Padaria, `pool_close_document_ids` includes `document.id`, `data-turbo-confirm="Fechar o mês para envio?"`. Input name `supporting_document_ids[]` is in `spec/support/match_helpers.rb:36`, not at the assertion | PASS |
| C10 | GET closed: `Mês fechado`, `Restaurar pasta`, `Reabrir`, Padaria, no Fechar, no Mercado, two turbo confirms | batched JSON passed | `spec/requests/months_spec.rb:1219-1226` those strings / omissions and `data-turbo-confirm="Restaurar a pasta do mês no arquivo do pacote?"` / `"Reabrir o mês?"` | PASS |
| C11 | unauthenticated POST close: 302 `/login`, no `month_id` | batched JSON passed | `spec/requests/close_spec.rb:716-718` `:found` `redirect_to("/login")` `month_id` nil | PASS |
| C12 | submitter POST close: 404, month open, no `month_id` | batched JSON passed | `spec/requests/close_spec.rb:731-733` `:not_found`, `closed? == false`, `month_id` nil | PASS |
| C13 | reopen: month open, no write, Padaria `month_id` kept `match_id` nil; GET Fechar+confirm, Devolver, Padaria; no Restaurar / Mês fechado | batched JSON passed | `spec/requests/reopen_spec.rb:127-139` open, writer unchanged, `month_id`/`match_id`, GET copy; `spec/models/month_spec.rb:314-318` open, no write, `month_id` kept | PASS |
| C14 | POST return while open: `month_id` nil, 302 to month, pool has Padaria, no Devolver | batched JSON passed | `spec/requests/month_returns_spec.rb:20-25` `month_id` nil, `:found` `redirect_to("/months/2026-05")`, pool includes Padaria, not Devolver; `spec/models/supporting_document_spec.rb:891-892` `month_id` nil | PASS |
| C15 | return while closed: 422 `Mês fechado`, `month_id` stays | batched JSON passed | `spec/requests/month_returns_spec.rb:34-36` 422 + message + `month_id == month.id`; `spec/models/supporting_document_spec.rb:903-904` same | PASS |
| C16 | unauthenticated return: 302 `/login`, `month_id` stays | batched JSON passed | `spec/requests/month_returns_spec.rb:49-51` `:found` `redirect_to("/login")` `month_id == month.id` | PASS |
| C17 | submitter return: 404, `month_id` stays | batched JSON passed | `spec/requests/month_returns_spec.rb:61-62` `:not_found` `month_id == month.id` | PASS |
| C18 | return 404: matched / no-month / other org; document unchanged | batched JSON passed (three examples) | `spec/requests/month_returns_spec.rb:75-77` 404 + `match_id` present + `month_id`; `:88-89` 404 + `month_id` nil; `:106-107` 404 + `month_id == month_b.id` | PASS |
| C19 | match same-month unmatched-in-package: Match persists, `month_id` kept; GET Casado no Devolver; list `Casado em 2026-05` not `Sem casamento em 2026-05` | batched JSON passed | `spec/requests/matches_spec.rb:556-560` `Match.count == 1`, `month_id`, Casado, no Devolver; `spec/models/match_spec.rb:316-318` persisted + `month_id` + `match_id`; `spec/requests/supporting_documents_spec.rb:1459-1460` Casado / not Sem casamento | PASS |
| C20 | match May Padaria onto June: 422 `Documento já pertence a um mês`, no Match | batched JSON passed | `spec/requests/matches_spec.rb:576-578` 422 + message + `Match.count == 0`; `spec/models/match_spec.rb:329-331` not persisted + HAS_MONTH + `Match.count == 0` | PASS |
| C21 | GET June omits May Padaria from pool and close ids | batched JSON passed | `spec/requests/months_spec.rb:1240-1241` pool not Padaria; `page_close_document_ids` not Padaria id. Input name is in the helper, not at the assertion | PASS |
| C22 | re-close without ids: Padaria `month_id` kept `match_id` nil; writer has `notas-sem-casamento/` path | batched JSON passed | `spec/requests/close_spec.rb:744-746` `month_id`, `match_id` nil, path included; `spec/models/month_spec.rb:328-330` same ids | PASS |
| C23 | close after return: Padaria `month_id` nil, writer has no Padaria id | batched JSON passed | `spec/requests/close_spec.rb:758-759` `month_id` nil, writer id grep empty | PASS |
| C24 | GET June missing 22000: `Documento faltante`, no `Sugestão`; model does not assign other-month doc | batched JSON passed | `spec/requests/months_spec.rb:1257-1258` faltante, not Sugestão; `spec/models/suggestion_spec.rb:410` `proposal_for(payment)` nil | PASS |
| C25 | reopened May after DELETE exception: faltante + Sugestão + Padaria; model assigns same-month unmatched | batched JSON passed | `spec/requests/months_spec.rb:1276-1278` three includes; `spec/models/suggestion_spec.rb:419` `supporting_documents == [document]` | PASS |
| C26 | June does not suggest justification containing May Padaria | batched JSON passed | `spec/requests/months_spec.rb:1301` `not_to match(/Sugestão[\s\S]*Padaria Central/)`; `spec/models/suggestion_spec.rb:431` payees not include Padaria Central | PASS |
| C27 | DELETE match of former unmatched-in-package clears `month_id` | batched JSON passed | `spec/requests/matches_spec.rb:594` `month_id` nil; `spec/models/match_spec.rb:342-343` `month_id` and `match_id` nil | PASS |
| C28 | PATCH payee while closed unmatched-in-package: 422 `Mês fechado`, payee unchanged | batched JSON passed | `spec/requests/supporting_documents_spec.rb:1486-1488` 422 + message + `payee == "Padaria Central"` | PASS |
| C29 | PATCH payee while open: 302, payee `Mercado Silva` | batched JSON passed | `spec/requests/supporting_documents_spec.rb:1501-1502` `:found` `payee == "Mercado Silva"` | PASS |
| C30 | submitter PATCH/DELETE with `month_id`: 422 `Documento já pertence a um mês`, unchanged | batched JSON passed | `spec/requests/supporting_documents_spec.rb:1518-1520` 422 + message + payee unchanged; `:1536-1539` 422 + message + persisted + `month_id` present | PASS |
| C31 | concurrent May/June close same Padaria: exactly one closed, that `month_id`, other 422 message, loser does not write | batched JSON passed | `spec/requests/close_spec.rb:856-861` `closed.count == 1`, `month_id == closed.first.id`, statuses `302,422`, `writer.calls.size == 1`, loser body includes `Documento já pertence a um mês`; `spec/models/month_spec.rb:437-441` one closed, that `month_id`, one writer | PASS |
| C32 | GET `/supporting_documents` after unmatched close: `Sem casamento em 2026-05`, not `Casado em 2026-05` | batched JSON passed | `spec/requests/supporting_documents_spec.rb:1473-1474` those two | PASS |
| C33 | xlsx sheet `2026-05`, heading after `Resultado mês`, headers order, recibo row path/`Recibo`/155/`11/05/2026`/Padaria/`pago em dinheiro` | batched JSON passed | `spec/requests/close_spec.rb:773-783` sheet name, `heading > resultado`, header array, row include path/`Recibo`/155/date/payee/obs; `spec/models/summary_spreadsheet_spec.rb:166-169` same literals including path `notas-sem-casamento/recibo-2026-05-11-padaria-central-#{id}.jpg` | PASS |
| C34 | unmatched nota `Arquivo` jpg; xml join, `Tipo` `Nota fiscal` | batched JSON passed | `spec/requests/close_spec.rb:791-794` `row[0] == joined` + `Nota fiscal`; `spec/models/summary_spreadsheet_spec.rb:176-179` same joined string | PASS |
| C35 | unmatched rows `2026-05-04` then `2026-05-20` | batched JSON passed | `spec/models/summary_spreadsheet_spec.rb:189` `dates == ["04/05/2026", "20/05/2026"]` | PASS |
| C36 | no unmatched: workbook omits `sem casamento` | batched JSON passed | `spec/requests/close_spec.rb:801` `not_to include("sem casamento")`; `spec/models/summary_spreadsheet_spec.rb:152` same | PASS |
| C37 | matched Mercado under `notas/`, unmatched section omits Mercado | batched JSON passed | `spec/requests/close_spec.rb:815-816` `notas/recibo-2026-05-11-mercado-silva-#{id}.jpg`, unmatched text not Mercado; `spec/models/month_package_spec.rb:84-85` both folders; `spec/models/summary_spreadsheet_spec.rb:200-201` Padaria included, Mercado omitted | PASS |
| C38 | POST restore: 302 to month, stays closed, `month_folder_id` unchanged, Padaria `month_id` unchanged, no job, writer once with folder_id + Padaria unmatched + Mercado `notas/` + `resumo-2026-05.xlsx` | batched JSON passed | `spec/requests/restore_spec.rb:25-38` `:found` redirect, closed, folder_id, `month_id`, `enqueued_jobs == []`, `calls.size == 2`, last `folder_id` + three file keys; `spec/models/month_spec.rb:345-355` closed, folder_id, `month_id`, `calls + 1`, same keys | PASS |
| C39 | restore while open: 422 `Mês aberto`, writer not invoked | batched JSON passed | `spec/requests/restore_spec.rb:49-51` 422 + message + writer unchanged; `spec/models/month_spec.rb:363-364` `OPEN` + writer unchanged | PASS |
| C40 | restore writer raise: 422 write-failed, stays closed, folder_id unchanged | batched JSON passed | `spec/requests/restore_spec.rb:62-65` 422 + `Não foi possível gravar no arquivo do pacote` + closed + folder_id; `spec/models/month_spec.rb:378-380` same | PASS |
| C41 | unauthenticated restore: 302 `/login`, writer not invoked | batched JSON passed | `spec/requests/restore_spec.rb:77-79` `:found` `redirect_to("/login")` writer unchanged | PASS |
| C42 | submitter restore: 404, stays closed, writer not invoked | batched JSON passed | `spec/requests/restore_spec.rb:90-92` `:not_found` closed writer unchanged | PASS |
| C43 | restore other-org month: 404, B closed, writer not invoked | batched JSON passed | `spec/requests/restore_spec.rb:107-109` `:not_found` `month_b.closed?` writer unchanged | PASS |
| C44 | restore never-opened `2026-04`: 404 | batched JSON passed | `spec/requests/restore_spec.rb:117` `:not_found` | PASS |
| C45 | concurrent restore: stays closed, folder_id unchanged, both 302 | batched JSON passed | `spec/requests/restore_spec.rb:148-150` closed, folder_id, `statuses == [302, 302]`; `spec/models/month_spec.rb:466-467` closed + folder_id | PASS |

## Coverage

Recomputed from code and Landing, not by reading the table.

| Set (authority) | Members from code / Landing | Proof | Unproven |
| --- | --- | --- | --- |
| close selected-document rejects | `lock_unmatched_selection`: match_id → `DOCUMENT_TAKEN`; month_id → `HAS_MONTH`. Controller other-org size mismatch → 404. `close_blocker` missing document → `MISSING_DOCUMENT` | C6 · C5 · C4 · C8 | existing close_blocker members (already closed, missing statement/archive/accountant) are prior feature, not this set |
| close auth | unauthenticated `require_account`/`require_coordinator_organization` 302 `/login`; submitter `head :not_found` | C11 · C12 | - |
| unmatched-in-package transitions | assign after write; omit ids; reopen keeps; return clears; match same month keeps; match other month HAS_MONTH; re-close keeps; dissolve clears | C1 · C2 · C13 · C14 · C19 · C20 · C22 · C27 | - |
| return 404 (`MonthReturnsController` find_by `month_id` + `match_id` nil) | in Match · no month · other org | C18 ×3 | - |
| return auth | unauthenticated · submitter | C16 · C17 | - |
| return closed vs open | open 302 · closed 422 `Mês fechado` | C14 · C15 | - |
| package folders (`MATCHED_FOLDER` / `UNMATCHED_FOLDER`) | unmatched prefix · omit when empty · matched `notas/` | C1 · C2 · C37 | Landing “folder omitted when no unmatched document has a blob” (blob-less row) is not a check |
| spreadsheet unmatched section | headers+recibo C33 · nota jpg+xml C34 · date order C35 · omitted C36 | those four | Landing “No `SUM` over that section” has no proof. Landing “rows by `document_on` then id”: C35 asserts dates only, not id tie-break |
| Tipo copy (`TIPO_COPY`) | `Recibo` · `Nota fiscal` | C33 · C34 | - |
| Suggestion vs assigned month (`documents_compatible?`) | other month no · same month yes · mixed justification | C24 · C25 · C26 | - |
| submitter mutate with `month_id` | PATCH (`submitter_month_locked?`) · DELETE (`withdraw` HAS_MONTH) | C30 ×2 | - |
| coordinator PATCH closed vs open | closed · open | C28 · C29 | - |
| restore rejects | open · writer fail · unauthenticated · submitter · other org · never opened | C39–C44 | invalid `year_month` shares `find_month` 404 with C44; not separately named |
| concurrency | two months one document · two restores | C31 · C45 | - |
| startup config assemblies | no new process setting in the range (`config/routes.rb` only) | n/a | - |

Status/route/shape claims C1–C23, C27–C32, C38–C45 each have a request-spec proof. C24–C26, C33–C37 that name HTTP or xlsx at the boundary have request specs except C35 (model-only date order; no status/route named).

## Test policy rows

Artifact follows `.cursor/rules/rails.mdc` 49–51 (level + one asserted case per enumerated member; HTTP also a request spec). Verdicts against those rows, not taste.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `app/models/month.rb` (`close_for_send`, `restore_month_folder`, `reopen`); `app/models/supporting_document.rb` (`return_to_no_month`); `app/models/match.rb` (HAS_MONTH / keep `month_id` / dissolve); `app/models/suggestion.rb` (`documents_compatible?`) | model **and** request; one asserted case per member | yes — C1/C5/C6/C7/C8/C13/C22/C31/C38–C40/C45 at Month; C14/C15 return; C19/C20/C27 Match; C24–C26 Suggestion. Other-org close/restore 404 is controller, not Month |
| Decides, not reached across a boundary | `app/models/month_package.rb` folder split; `app/models/summary_spreadsheet.rb` unmatched section | model; one case per enumerated member | yes — C1/C37 package; C33–C36 spreadsheet. Extra request specs on close xlsx/writer paths do not substitute |
| Entry point that decides nothing (pass-through + 404) | `MonthsController#close`/`#restore`; `MonthReturnsController#create` | request: accepted, each rejected, each error path | yes — other-org/missing-id 404 C4/C18/C43/C44; auth C11/C12/C16/C17/C41/C42; writer/open errors C7/C39/C40. Pool filter in `ApplicationController#load_month_page` is GET copy at C9/C10/C21 (request), matching the artifact’s GET-copy analogue |
| Instrumentation / pass-through | `require_coordinator_organization` (existing) | none of its own | covered by consumer auth checks above |

C28/C29 are HTTP-only named proofs; `SupportingDocument#submit` closed-month reject is the same `month&.closed?` branch already asserted in prior model examples (`apply payee while document Month is closed`). Not a new model member. C30 PATCH is controller `submitter_month_locked?` (request is the layer). C30 DELETE is `withdraw` HAS_MONTH (existing model `withdraw month document is rejected`) plus request.

No unmet row.

## Swept existing

- `@month_error` on the month page: `MonthsController#close`/`#restore` set `@month_error`; `app/views/months/show.html.erb:24-26` renders it. C7/C40 assert the message in `response.body`.
- `require_coordinator_organization`: `ApplicationController` 40–47 (`302` `/login`, submitter `404`).
- `PackageArchiveWriter::Error` → `WRITE_FAILED` in `Month#persist_closed_package` and `#restore_month_folder`.
- Restore enqueues no job: C38 `enqueued_jobs == []`.
- Rows marked not in scope: policy, not code.

## Faults injected

Scratch: `git worktree add /tmp/tlc-verify-unmatched-docs-and-restore HEAD`. Real tree not mutated. One fault per surface, cap five. Scratch removed; porcelain matches baseline (` M AGENTS.md`, ` M README.md`, `?? .tasks/nfe-photo-extraction.md`). HEAD still `c25c281`.

| Mutation | Location | Killed |
|---|---|---|
| skip `selected.each { document.update!(month_id: id) }` after a successful write | `app/models/month.rb` `persist_closed_package` | yes — C1 model: expected `month_id`, got nil (`month_spec.rb:231`) |
| skip `writer.replace_month_folder` in restore | `app/models/month.rb` `restore_month_folder` | yes — C38 model: `writer.calls.size` expected 2 got 1 (`month_spec.rb:348`) |
| skip `update!(month_id: nil)` on return | `app/models/supporting_document.rb` `return_to_no_month` | yes — C14 model: expected nil, got month id (`supporting_document_spec.rb:892`) |
| skip `write_unmatched` | `app/models/summary_spreadsheet.rb` `write_custos` | yes — C33 model: `heading` nil vs `> 10` (`summary_spreadsheet_spec.rb:167`) |
| `documents_compatible?` always `true` | `app/models/suggestion.rb` Assigner | yes — C24 model: expected nil proposal, got a Suggestion (`suggestion_spec.rb:410`) |

## Gaps (non-blocking)

1. Landing “No `SUM` over that section” is not a check and has no assertion; Coverage hid it.
2. Landing “Rows by `document_on` then id”: C35 proves date order only.
3. C9/C21: `supporting_document_ids[]` lives in `spec/support/match_helpers.rb`, not at the assertion (id inclusion is asserted).

## Gate

`unset BUNDLE_PATH && bin/rspec spec/requests/close_spec.rb spec/models/month_spec.rb spec/models/month_package_spec.rb spec/requests/months_spec.rb spec/requests/reopen_spec.rb spec/requests/month_returns_spec.rb spec/models/supporting_document_spec.rb spec/requests/matches_spec.rb spec/models/match_spec.rb spec/requests/supporting_documents_spec.rb spec/models/suggestion_spec.rb spec/models/summary_spreadsheet_spec.rb spec/requests/restore_spec.rb --format json` — 543 passed, 0 failed; 78/78 named proofs passed.
