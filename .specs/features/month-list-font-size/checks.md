# Month list font size checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`

## Intent

The month overview uses different sizes for primary row text across its three lists. Set primary row text, dates and amounts to 15px in Pagamentos, Documentos sem casamento and Recebimentos, keeping headings and secondary metadata unchanged.

1 check in 1 slice · 0 one-way doors · 0 open, of which 0 block

## Out of scope

Other screens and list behavior do not change.

## Checks

### S1 - List typography

**C1** - Primary row text, dates and amounts in each of the three month overview lists render at 15px; headings and secondary metadata retain their sizes.
Proof: walk - open the month overview and inspect the three lists and their computed font sizes

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| Month lists (3) | Pagamentos C1 · Documentos sem casamento C1 · Recebimentos C1 | - |

## Swept

- validation: n/a - presentational change
- failure modes: n/a - presentational change
- idempotency: n/a - presentational change
- authorization: existing - month access unchanged
- concurrency: n/a - presentational change
- data lifecycle: n/a - presentational change
- dependency failure: n/a - presentational change
- state transitions: n/a - presentational change
- observability: n/a - presentational change

## Handoff

- **Settled mid-build:** none
- **Dispatched:** none
- **Boundary:** not yet built
- **Abandoned:** none
- **Walked:** pending
