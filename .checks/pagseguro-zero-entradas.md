# PagSeguro: zero Entradas is not an Inflow

Profile: `standard`. The task names no binding screen or design source.

Sources:

- `.tasks/pagseguro-zero-entradas.md` - criteria 1–8, sweep, out of scope, COMPE `290` only; Unresolved is empty
- https://github.com/gutors/ai-accounting-assistant/issues/109 - this cut: cell counts as crédito/débito iff `BrlCents.parse` is Integer `> 0`; `0` / `0,00` / Excel `0` absent; only `Saidas` valued → Payment; only `Entradas` valued → Inflow; both zero or empty → skip; both `> 0` → `Entradas` still wins
- `.specs/features/bank-statement-upload/plan.md` AC 30–33 - May 2026 fixture 64 Inflows / 7 Payments, skip `Saldo do dia`, Pix enviado Payment `151240`, rendimento Inflow `2` cents
- `app/models/pagseguro_spreadsheet.rb` - today’s `present_amount?` then `credit ? entradas : saidas`
- `app/models/statement_spreadsheet.rb` - `present_amount?` is non-blank string; only this reader calls it
- `spec/fixtures/files/extrato-pagseguro-maio-2026.xlsx` - May 2026 anonymized `report` sheet; Pix enviado row `Entradas` `nil`

No design source.

## Out of scope

- Statement upload, optional PDF, month vision and match screens — #109 recorte; existing `POST /months/:year_month/bank_statements` and `GET /months/:year_month`
- Spreadsheet parsers for catalog banks other than COMPE `290` — #109; BB `Inf.` `C`/`D` stays
- Changing skip of `Tipo` `Saldo do dia` — existing bank-statement-upload AC 31
- Backfilling already-imported PagSeguro statements — existing replace while the month is open
- A check constraint forbidding `amount_cents` `0` on `inflows` / `payments` — not in #109
- Open Finance, OFX, `.xls`, column-mapping UI — bank-statement-upload out of scope

## Landing

Touches `PagseguroSpreadsheet.read` and `StatementSpreadsheet.present_amount?` (only COMPE `290` calls it). Persistence stays `BankStatement#import` / `#submit`. Reuses rubyXL fixture construction in `spec/support/statement_helpers.rb` and the May 2026 PagSeguro xlsx. Banco do Brasil still uses `Inf.` `C`/`D`.

None - the presence threshold is a reversible parser rule (criteria 1–8). No schema, no new gem, no new HTTP contract.

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

These rows are the bar I build under — approving the checklist is enough for that. Writing them into `.cursor/rules/rails.mdc` needs an explicit yes, and it lands as its own commit before the build. Without one I build under them and leave the file alone.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at the model layer **and** one request spec at HTTP | one asserted case per enumerated member at the model; status / who may call at the boundary | follow |
| Decides, not reached across a boundary | one at the model layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` names the level and the sampling rule: a decision is proven at its own layer, one asserted case per enumerated member; HTTP also gets a request spec for status and who may call
- `PagseguroSpreadsheet.read` decides crédito / débito / skip from parsed `Entradas` / `Saidas` cents `> 0` (six combination members plus three zero encodings). Criteria name `BankStatement.import` persistence, which is the existing model-layer analogue (`spec/models/bank_statement_spec.rb` PagSeguro fixture examples)
- This cut does not change the HTTP contract. Existing `spec/requests/bank_statements_spec.rb` POST PagSeguro examples already cover who may call and the 64 / 7 counts at the boundary
- `BankStatement#submit` stays instrumentation for this cut: it still creates an Inflow when `movement.credit` and a Payment otherwise
- closest analogue: `spec/models/bank_statement_spec.rb` `PagSeguro May 2026 fixture yields 64 Inflows and 7 Payments`

Cost: eight model examples at `BankStatement.import` (C1–C6 one each, C7 reuses the three fixture examples, C8 the zero-cents invariant). No new request spec. Without the model cases, POST of the May fixture would stay green while `Entradas` `0` still became an Inflow.

## Checks

Criteria 1–8 map to C1–C8.

### S1 - Zero Entradas does not win over Saidas · 4 files · 15 KB · ~4k

**C1** - Given an open Month `2026-05` and an active COMPE `290` BankAccount, when `BankStatement.import` reads a PagSeguro `.xlsx` whose only movement row is dated `2026-05-11`, `Tipo` is not `Saldo do dia`, `Entradas` is `0`, and `Saidas` is `1512,40`, then that BankStatement persists exactly one Payment of `151240` cents dated `2026-05-11` and zero Inflows
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro Entradas 0 and Saidas 1512,40 persists one Payment 151240 cents"`

**C2** - When that same import uses `Entradas` `0,00` and `Saidas` `1512,40`, then that BankStatement persists exactly one Payment of `151240` cents and zero Inflows
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro Entradas 0,00 and Saidas 1512,40 persists one Payment 151240 cents"`

**C3** - When that same import uses `Entradas` as Excel numeric `0` and `Saidas` valued `1512,40` (or numeric `1512.4`), then that BankStatement persists exactly one Payment of `151240` cents and zero Inflows
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro Excel numeric 0 Entradas and Saidas 1512.4 persists one Payment 151240 cents"`

### S2 - Combinations and May 2026 fixture · 5 files · 19 KB · ~5k

**C4** - When that same import uses only `Entradas` valued (`155,00`) and `Saidas` empty, then that BankStatement persists exactly one Inflow of `15500` cents and zero Payments
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro only Entradas 155,00 persists one Inflow 15500 cents"`

**C5** - When that same import uses `Entradas` `0` and `Saidas` `0`, then that BankStatement persists zero Inflows and zero Payments from that row
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro Entradas 0 and Saidas 0 persists zero movements"`

**C6** - When that same import uses `Entradas` `155,00` and `Saidas` `1512,40` (both greater than zero), then that BankStatement persists exactly one Inflow of `15500` cents and zero Payments from that row
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro both columns greater than zero prefers Entradas Inflow 15500 cents"`

**C7** - When `BankStatement.import` reads the PagSeguro May 2026 fixture `spec/fixtures/files/extrato-pagseguro-maio-2026.xlsx` for that COMPE `290` account on Month `2026-05`, then that BankStatement persists exactly 64 Inflows and exactly 7 Payments, including Payment `151240` cents dated `2026-05-11` history `Pix enviado — VITOR CASTRO FERREIRA` and Inflow `2` cents dated `2026-05-01` history `Rendimento da conta — Rendimento líquido sobre dinheiro em conta`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro May 2026 fixture yields 64 Inflows and 7 Payments"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro Pix enviado is Payment 151240 cents on 2026-05-11"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "PagSeguro rendimento is Inflow 2 cents on 2026-05-01"`

**C8** - Always, a COMPE `290` import does not persist an Inflow or a Payment whose `amount_cents` is `0`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "COMPE 290 import does not persist amount_cents 0"`

## Swept

- validation: C1, C2, C3, C8 - `Entradas` / `Saidas` present only when `BrlCents.parse` is Integer `> 0`
- failure modes: C5 - a row whose amounts are both zero is skipped, not `StatementSpreadsheet::Unreadable`; other unreadable paths stay existing
- idempotency and retry: existing - a second POST for the same account and month still replaces that BankStatement
- authorization: existing - coordinator-only import; this cut does not add a route
- concurrency and ordering: n/a - the reader is a function of the file; two POSTs for the same pair remain the existing unique-BankStatement race
- data lifecycle: existing - already persisted Inflows and Payments stay until the coordinator replaces the statement; no backfill
- external-dependency failure: n/a - no new remote; the file is already on the blob
- state transitions: n/a - BankStatement / Inflow / Payment lifecycle is unchanged; only which PagSeguro rows become which
- observability: n/a - no operator metric or log line is required

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| Entradas / Saidas combinations (4) | only Saidas valued C1 · only Entradas valued C4 · both zero C5 · both `> 0` prefers Entradas C6 | - |
| Zero encodings treated as absent (3) | string `0` C1 · string `0,00` C2 · Excel numeric `0` C3 | - |
| May 2026 fixture (3) | counts 64 / 7 C7 · Payment `151240` C7 · Inflow `2` C7 | - |
| `amount_cents` `0` never persisted (1) | C8 | - |
| startup config assemblies | no new process setting | - |

- Claims naming a status code, route or response shape: none
- No other check claims more than the single case its proof exercises

## Handoff

S1 = 4 files · 15 KB · ~4k; S2 = 5 files · 19 KB · ~5k; running total ~9k, all in `PagseguroSpreadsheet` / `BankStatement.import`. Under 150k, both slices in one batch, no split.
