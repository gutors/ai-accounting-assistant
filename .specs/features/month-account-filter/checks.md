# Month account filter checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/month-account-filter/plan.md`

## Checks

### S1 - Month heading and movement filter

**C1** - The heading and selector match `.specs/features/month-account-filter/captures/option-a.png` (AC 1, 3)
Proof: browser - reach the state, save `captures/option-a.running.png`

**C2** - The home link opens `/` (AC 2)
Proof: `bin/rspec spec/system/month_account_filter_spec.rb -e "opens home"`

**C3** - The selector is labeled, described, ordered and omitted before confirmation (AC 3, 4)
Proof: `bin/rspec spec/system/month_account_filter_spec.rb -e "shows the account selector"`

**C4** - Selecting and clearing an account scopes movements, retains statements and unmatched documents, and preserves sort, disclosures, focus and scroll (AC 5, 7)
Proof: `bin/rspec spec/system/list_scroll_position_spec.rb -e "changes and clears the month account in place"`

**C5** - An empty account displays the two account-specific empty messages (AC 6)
Proof: `bin/rspec spec/system/month_account_filter_spec.rb -e "shows empty account messages"`

**C6** - Month-wide missing document and statement totals remain visible when filtered (AC 8)
Proof: `bin/rspec spec/system/month_account_filter_spec.rb -e "keeps month totals"`

**C7** - At 390 CSS pixels the heading, home link and labeled selector fit without horizontal scrolling (AC 9)
Proof: `bin/rspec spec/system/month_account_filter_spec.rb -e "fits a phone viewport"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| source controls (2) | home C2 · account select C4 | - |
| account selection (3) | selected C4 · all C4 · empty C5 | - |
| month states (2) | confirmed C3 · awaiting confirmation C3 | - |

## Swept

- validation: existing - account filter checks active organization account
- failure modes: n/a - read-only filter
- idempotency: n/a - GET only
- authorization: existing - focused organization account guard
- concurrency: n/a - read-only filter
- data lifecycle: n/a - no stored data
- dependency failure: n/a - no new dependency
- state transitions: C3
- observability: n/a - no logging requirement

## Handoff

- **Settled mid-build:** none
- **Dispatched:** Verifier and screens round 1 at `76dfc88` - returned
- **Boundary:** C1-C7 implemented and independently verified at `76dfc88`
- **Abandoned:** none
- **Walked:** In local development, signed in and opened October 2026, collapsed Pagamentos, selected Conta Alfa, observed the empty receipts message and month-wide blockers, then selected Todas as contas and saw the payments return while the disclosure stayed closed. Captured option A at 1000 × 570 without resizing.
