# Quick selection checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/match-quick-selection/plan.md`

## Checks

### S1 - Select match members

**C1** - Payment and document choices toggle immediately, retain selection on close, and recalculate totals (AC 1, 2, 3, 5, 7)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "quick selection toggles payments and documents"`

**C2** - Selected rows do not toggle on body click and have explicit removal controls (AC 4)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "quick selection protects selected rows"`

**C3** - The current exception clears documents and extra payments (AC 8)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "quick selection preserves exception behavior"`

**C4** - Confirmation submits the selected members (AC 9)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "quick selection confirms selected members"`

**C5** - The two lists remain full width and keyboard-operable on a phone viewport (AC 6, 10)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "quick selection works at phone width"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| selection controls (6) | payment list C1 · document list C1 · payment choice C1 · document choice C1 · remove C2 · close C1 | - |
| existing form actions (2) | exception C3 · confirm C4 | - |

## Swept

- validation: existing - match model and request validations
- failure modes: existing - match submission validation
- idempotency: n/a - client selection only
- authorization: existing - match route access guards
- concurrency: existing - match persistence rules
- data lifecycle: existing - form submits existing IDs
- dependency failure: n/a - no new dependencies
- state transitions: C1, C2, C3, C4
- observability: n/a - no new server behavior

## Handoff

- **Settled mid-build:** user: "Não, seguir sem issue"
- **Dispatched:** Verifier at `334afa1` - pending
- **Boundary:** C1-C5 implemented at `334afa1`
- **Abandoned:** none
- **Walked:** system browser exercised selection, exception, confirmation and phone width; manual walk unavailable because the browser blocked the local prototype URL.
