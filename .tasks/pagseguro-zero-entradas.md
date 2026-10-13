# PagSeguro: zero Entradas is not an Inflow

> Build this with **tlc-implement**. Profile **`standard`**: no new screen; no binding design.
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

`PagseguroSpreadsheet` treats any non-blank `Entradas` cell as credit
(`StatementSpreadsheet.present_amount?` is `value.to_s.strip.present?`). A PagSeguro debit row
that puts `0`, `0,00`, or Excel `0` in `Entradas` therefore becomes an Inflow of `0` cents
(`BrlCents.parse` of those values is `0`), and `Saidas` is never read
(`cents = BrlCents.parse(credit ? entradas : saidas)`). The coordinator then sees a `R$ 0,00`
recebimento and does not see that line’s débito as a Payment. Issue #109 gives no conversion
figure; the cost is a false Inflow and a missing Payment on COMPE `290` statements whose export
fills zero instead of leaving the cell empty. The May 2026 fixture uses `nil` in `Entradas` on
the Pix enviado row, so it does not catch this.

When this ships, a COMPE `290` spreadsheet cell in `Entradas` or `Saidas` counts as crédito or
débito only when `BrlCents.parse` of that cell is an Integer greater than `0`. A typical row
`Entradas` `0` + `Saidas` `1512,40` persists one Payment of `151240` cents and no Inflow from
that row. `0`, `0,00`, and Excel `0` are absent. Both columns absent or zero skips the row.
Both greater than zero still prefers `Entradas`. Banco do Brasil is unchanged. The anonymized
May 2026 PagSeguro fixture still yields 64 Inflows and 7 Payments (that file has no zero
`Entradas` cells).

8 criteria in 2 slices · 0 one-way doors · 0 open, of which 0 block

## Criteria

### Zero Entradas does not win over Saidas

1. Given an open Month `2026-05` and an active COMPE `290` BankAccount, when `BankStatement.import`
   reads a PagSeguro `.xlsx` whose only movement row is dated `2026-05-11`, `Tipo` is not
   `Saldo do dia`, `Entradas` is `0`, and `Saidas` is `1512,40`, then that BankStatement persists
   exactly one Payment of `151240` cents dated `2026-05-11` and zero Inflows.
2. When that same import uses `Entradas` `0,00` and `Saidas` `1512,40`, then that BankStatement
   persists exactly one Payment of `151240` cents and zero Inflows.
3. When that same import uses `Entradas` as Excel numeric `0` and `Saidas` valued `1512,40` (or
   numeric `1512.4`), then that BankStatement persists exactly one Payment of `151240` cents and
   zero Inflows.

### Combinations and May 2026 fixture

4. When that same import uses only `Entradas` valued (`155,00`) and `Saidas` empty, then that
   BankStatement persists exactly one Inflow of `15500` cents and zero Payments.
5. When that same import uses `Entradas` `0` and `Saidas` `0`, then that BankStatement persists
   zero Inflows and zero Payments from that row.
6. When that same import uses `Entradas` `155,00` and `Saidas` `1512,40` (both greater than
   zero), then that BankStatement persists exactly one Inflow of `15500` cents and zero Payments
   from that row.
7. When `BankStatement.import` reads the PagSeguro May 2026 fixture
   `spec/fixtures/files/extrato-pagseguro-maio-2026.xlsx` for that COMPE `290` account on Month
   `2026-05`, then that BankStatement persists exactly 64 Inflows and exactly 7 Payments, including
   Payment `151240` cents dated `2026-05-11` history `Pix enviado — VITOR CASTRO FERREIRA` and
   Inflow `2` cents dated `2026-05-01` history
   `Rendimento da conta — Rendimento líquido sobre dinheiro em conta`.
8. Always, a COMPE `290` import does not persist an Inflow or a Payment whose `amount_cents` is `0`.

## Out of scope

- Statement upload, optional PDF, month vision and match screens — #109 recorte; existing
  `POST /months/:year_month/bank_statements` and `GET /months/:year_month`
- Spreadsheet parsers for catalog banks other than COMPE `290` — #109; BB `Inf.` `C`/`D` stays
- Changing skip of `Tipo` `Saldo do dia` — existing bank-statement-upload AC 31
- Backfilling already-imported PagSeguro statements — existing replace while the month is open
- A check constraint forbidding `amount_cents` `0` on `inflows` / `payments` — not in #109
- Open Finance, OFX, `.xls`, column-mapping UI — bank-statement-upload out of scope

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `/months/:year_month` | empty | existing - month with a present statement and zero movements after skips still uploads (`zero movements after skips still persist BankStatement`) |
| screen `/months/:year_month` | loading | n/a - Turbo full-page / redirect |
| screen `/months/:year_month` | error | existing - unreadable / wrong month / unsupported bank stay `422` copy already on `BankStatement` |
| screen `/months/:year_month` | unauthorised | existing - unauthenticated POST `302` `/login`; submitter does not import |
| screen `/months/:year_month` | density and ordering | existing - `Recebimentos` / `Pagamentos` still list persisted rows; this cut does not change layout. 1–3 make the débito a Payment instead of a `R$ 0,00` Inflow |
| screen `/months/:year_month` | destructive action confirms | existing - replace is the same POST, no confirm |
| HTML `POST /months/:year_month/bank_statements` | who may call it | existing - coordinator with focus |
| HTML `POST /months/:year_month/bank_statements` | response shape | existing - `302` to the month; Inflows and Payments as today. 1–8 change which rows the COMPE `290` reader yields |
| HTML `POST /months/:year_month/bank_statements` | error shape and codes | existing - no new status or copy |
| HTML `POST /months/:year_month/bank_statements` | versioning | n/a - existing HTML surface |
| HTML `POST /months/:year_month/bank_statements` | rate limit | n/a - coordinator-only, small operator set |
| command or scheduled task | flags, exit, halfway | n/a - no CLI or job |
| document or copy | structure, tone, next | n/a - no new user-facing copy |
| collection PagSeguro movements | grouping | 1, 4, 6 - `Entradas` with parsed cents `> 0` is Inflow; only `Saidas` with parsed cents `> 0` is Payment |
| collection PagSeguro movements | naming | existing - `Tipo` then ` — ` plus `Descrição` |
| collection PagSeguro movements | ordering | existing - date then id on the month lists |
| collection PagSeguro movements | duplicates | existing - replace destroys previous children |
| collection PagSeguro movements | exception that does not fit | 5, 8 - both absent or zero skips the row; parsed `0` never persists |

## Swept

- validation: 1, 2, 3, 8 - `Entradas` / `Saidas` present only when `BrlCents.parse` is Integer `> 0`
- failure modes: 5 - a row whose amounts are both zero is skipped, not `StatementSpreadsheet::Unreadable`; other unreadable paths stay existing
- idempotency and retry: existing - a second POST for the same account and month still replaces that BankStatement
- authorization: existing - coordinator-only import; this cut does not add a route
- concurrency and ordering: n/a - the reader is a function of the file; two POSTs for the same pair remain the existing unique-BankStatement race
- data lifecycle: existing - already persisted Inflows and Payments stay until the coordinator replaces the statement; no backfill
- external-dependency failure: n/a - no new remote; the file is already on the blob
- state transitions: n/a - BankStatement / Inflow / Payment lifecycle is unchanged; only which PagSeguro rows become which
- observability: n/a - no operator metric or log line is required

## Impact

| Front | What changes |
|---|---|
| domain | existing term: `Inflow` meant a PagSeguro row whose `Entradas` cell was non-blank, including `0`. It now means a PagSeguro row whose parsed `Entradas` cents are `> 0`. Callers: `PagseguroSpreadsheet.read`, `BankStatement#submit` (`inflows.create!` when `movement.credit`), `GET /months/:year_month` `Recebimentos` (`app/views/months/show.html.erb`), `SummarySpreadsheet` income rows |
| domain | existing term: `Payment` on COMPE `290` was skipped when `Entradas` was a present zero because credit won first. It now is created when only `Saidas` parses to cents `> 0`. Callers: same submit path (`payments.create!` when not credit), month `Pagamentos`, match and missing-document |
| stored data | nothing to migrate. Rows already imported with `amount_cents` `0` stay until replace. No new constraint on `inflows.amount_cents` / `payments.amount_cents`. May 2026 fixture counts stay 64 / 7 (file uses blank `Entradas`, not `0`) |

## Decided

None - the presence threshold is a reversible parser rule (criteria 1–8). No schema, no new gem, no new HTTP contract. Banco do Brasil still uses `Inf.` `C`/`D` and does not call `present_amount?`.

## Sources

- https://github.com/gutors/ai-accounting-assistant/issues/109 - this cut: COMPE `290` only; cell counts as crédito/débito iff parsed value `> 0`; `0` / `0,00` / Excel `0` absent; only `Saidas` valued → Payment; only `Entradas` valued → Inflow; both zero or empty → skip; both `> 0` → `Entradas` still wins; typical line `Entradas` `0` + `Saidas` `1512,40`; recount May 2026 fixture if it has zeros in `Entradas` (it does not)
- `.specs/features/bank-statement-upload/plan.md` AC 30–33 - fixture 64 Inflows / 7 Payments, skip `Saldo do dia`, Pix enviado Payment `151240`, rendimento Inflow `2` cents; Landing door 4 credit/`Entradas` vs debit/`Saidas` unchanged
- `app/models/pagseguro_spreadsheet.rb` - current `present_amount?` then `credit ? entradas : saidas`
- `app/models/statement_spreadsheet.rb` - `present_amount?` is non-blank string; only this reader calls it
- `spec/fixtures/files/extrato-pagseguro-maio-2026.xlsx` - May 2026 anonymized `report` sheet; Pix enviado row `Entradas` `nil`, `Saidas` `-1512.4`

No design source. Verification stays on project profile `standard`.

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | | None | |
