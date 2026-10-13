# Pagseguro-zero-entradas Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: 56c84dd..06fdf42
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Profile `standard` does not run the `ui` screen comparison. The checklist marks no binding design or contract.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| none marked binding | n/a — "No design source." | - | - |

## Checks

Proofs run at `06fdf42` in one invocation:

`bin/rspec spec/models/bank_statement_spec.rb` with ten `-e` names (C1–C6, three C7 examples, C8) — **10 examples, 0 failures**.

C7's three examples pre-exist this cut; they still call `BankStatement.import` on the May 2026 fixture through the changed `present_amount?` at HEAD.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | Entradas `0`, Saidas `1512,40` → one Payment `151240` cents dated `2026-05-11`, zero Inflows | that invocation, example passed | `spec/models/bank_statement_spec.rb:149` `expect(statement.payments.count).to eq(1)` · `:150` `expect(statement.inflows.count).to eq(0)` · `:152` `expect(payment.amount_cents).to eq(151240)` · `:153` `expect(payment.occurred_on).to eq(Date.new(2026, 5, 11))` | PASS |
| C2 | Entradas `0,00`, Saidas `1512,40` → one Payment `151240`, zero Inflows | same invocation | `spec/models/bank_statement_spec.rb:163` `expect(statement.payments.count).to eq(1)` · `:164` `inflows.count` `eq(0)` · `:165` `amount_cents` `eq(151240)` | PASS |
| C3 | Excel numeric `0` Entradas, Saidas `1512.4` → one Payment `151240`, zero Inflows | same invocation | `spec/models/bank_statement_spec.rb:175` `payments.count` `eq(1)` · `:176` `inflows.count` `eq(0)` · `:177` `amount_cents` `eq(151240)` | PASS |
| C4 | only Entradas `155,00`, Saidas empty → one Inflow `15500`, zero Payments | same invocation | `spec/models/bank_statement_spec.rb:187` `inflows.count` `eq(1)` · `:188` `payments.count` `eq(0)` · `:189` `amount_cents` `eq(15500)` | PASS |
| C5 | Entradas `0` and Saidas `0` → zero Inflows and zero Payments (row skipped, statement persisted) | same invocation | `spec/models/bank_statement_spec.rb:199` `expect(statement).to be_persisted` · `:200` `inflows.count` `eq(0)` · `:201` `payments.count` `eq(0)` | PASS |
| C6 | both `> 0` prefers Entradas Inflow `15500`, zero Payments | same invocation | `spec/models/bank_statement_spec.rb:211` `inflows.count` `eq(1)` · `:212` `payments.count` `eq(0)` · `:213` `amount_cents` `eq(15500)` | PASS |
| C7 | May 2026 fixture: 64 Inflows / 7 Payments; Payment `151240` on `2026-05-11` history `Pix enviado — VITOR CASTRO FERREIRA`; Inflow `2` cents on `2026-05-01` history `Rendimento da conta — Rendimento líquido sobre dinheiro em conta` | same invocation (three examples) | `spec/models/bank_statement_spec.rb:116` `inflows.count` `eq(64)` · `:117` `payments.count` `eq(7)` · `:129` `find_by!(amount_cents: 151240)` · `:131` `occurred_on` `eq(Date.new(2026, 5, 11))` · `:132` `history` `eq("Pix enviado — VITOR CASTRO FERREIRA")` · `:137` `find_by!(amount_cents: 2, occurred_on: Date.new(2026, 5, 1))` · `:139` `history` `eq("Rendimento da conta — Rendimento líquido sobre dinheiro em conta")` | PASS |
| C8 | COMPE `290` import persists no Inflow or Payment with `amount_cents` `0` | same invocation | `spec/models/bank_statement_spec.rb:229` `zeros_statement.inflows.where(amount_cents: 0)` `be_empty` · `:230` `payments.where(amount_cents: 0)` `be_empty` · `:233`–`:234` same on the May fixture statement | PASS |

Setup cited by C1–C8: open Month `2026-05` (`spec/models/bank_statement_spec.rb:8-10`) and COMPE `290` (`:16-17` `compe: "290"`). C1–C3 encodings sit at the `pagseguro_movements_xlsx` call (`:144` `"0"` · `:158` `"0,00"` · `:170` `entradas: 0, saidas: 1512.4`).

## Test policy rows

Re-judged from `.checks/pagseguro-zero-entradas.md` `## Test policy` against `.cursor/rules/rails.mdc` and the tree at HEAD.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/pagseguro_spreadsheet.rb` (`read`), consumed by `BankStatement.import` / HTTP POST | model: one asserted case per combination / zero encoding (C1–C6); HTTP: status / who may call, plus existing PagSeguro POST counts | model yes (C1–C8). Boundary: `spec/requests/bank_statements_spec.rb:147` POST 64/7 · `:159` Pix `151240` · `:136` unauthenticated 302 · `:360` submitter 404. Cut does not change the HTTP contract. |
| Decides, not reached across a boundary | none this cut | n/a | n/a |
| Entry point that decides nothing | none this cut | n/a | n/a |
| Instrumentation / pass-through | `BankStatement#submit` / `persist_import` (`app/models/bank_statement.rb:106-110` Inflow iff `movement.credit`) | none of its own | yes — covered by import proofs |

`present_amount?` is only called from `PagseguroSpreadsheet` (`rg` two hits: definition + those two call sites). BB still uses `Inf.` `C`/`D` (`app/models/banco_do_brasil_spreadsheet.rb:20-33`).

## Coverage (recomputed)

Authority: issue #109 / checklist sets, not the author's table copy.

| Set (size) | Members from authority | Proof | Unproven |
|---|---|---|---|
| Entradas / Saidas combinations (4) | only Saidas valued · only Entradas valued · both zero · both `> 0` prefers Entradas | C1 · C4 · C5 · C6 | none |
| Zero encodings treated as absent (3) | string `0` · string `0,00` · Excel numeric `0` | C1 · C2 · C3 | none |
| May 2026 fixture (3) | counts 64 / 7 · Payment `151240` · Inflow `2` | C7 three examples | none |
| `amount_cents` `0` never persisted (1) | C8 | C8 | none |
| startup config assemblies | no new process setting | n/a | - |

No check names a status code, route, or response shape. No other enumerated set in Landing / Test policy / claims.

## Swept (existing)

| Row | Cited constraint in code? |
|---|---|
| idempotency and retry | yes — `BankStatement.import` `find_or_initialize_by` then `submit` destroys and rewrites (`app/models/bank_statement.rb:16-18`, `:99-103`); `spec/models/bank_statement_spec.rb:237` replace; `spec/requests/bank_statements_spec.rb:171` POST replace |
| authorization | yes — `BankStatementsController` `require_coordinator_organization`; submitter POST 404 (`spec/requests/bank_statements_spec.rb:360`) |
| data lifecycle | yes — replace `inflows.destroy_all` / `payments.destroy_all`; no backfill in this diff |

## Faults injected

Scratch worktree `/tmp/pagseguro-zero-entradas-verify` at HEAD; discarded after. Real-tree porcelain empty before and after.

| Mutation | Location | Killed |
|---|---|---|
| `present_amount?` restored to non-blank string (old rule) | `statement_spreadsheet.rb` | yes — C1 payments `eq(1)` got `0`; C5 inflows `eq(0)` got `1`; C8 `amount_cents: 0` inflows not empty. C2/C3 share this surface. |
| `credit = false if debit` (Saidas wins when both valued) | `pagseguro_spreadsheet.rb` | yes — C6 inflows `eq(1)` got `0` |
| `next unless debit` (skip Entradas-only) | `pagseguro_spreadsheet.rb` | yes — C4 inflows `eq(1)` got `0` |
| `next if tipo.start_with?("Pix enviado")` | `pagseguro_spreadsheet.rb` | yes — C7 counts payments `eq(7)` got `0`; Pix `find_by!(amount_cents: 151240)` RecordNotFound |
| `next if tipo.start_with?("Rendimento")` | `pagseguro_spreadsheet.rb` | yes — C7 rendimento `find_by!(amount_cents: 2, …)` RecordNotFound |

No surviving mutant.

## Gate

`bin/rspec spec/models/bank_statement_spec.rb` (ten named examples) — 10 passed, 0 failed at `06fdf42`.
