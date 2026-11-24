# Matching workspace resolution checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/matches-resolution/plan.md`

## Checks

### S1 - Match review and resolution

**C1** - The pending count and inline matching error render after the title and before the selector. Empty and closed workspaces omit the form (AC 1)
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "renders notices before the account selector"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "omits the workspace in an empty queue"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches closed shows exceptions without mutation controls"`

**C2** - Selecting and clearing the account restores the respective pending count, payments, matches and exceptions and retains eligible document candidates (AC 2)
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "selects and clears the matching account"`
Proof: `bin/rspec spec/requests/matches_workspace_spec.rb -e "limits selectable unmatched documents to this organization and month"`

**C3** - Selected and offered rows keep metadata and amount on the first line and the full wrapping name on the next line (AC 3)
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "shows full names below the value line"`

**C4** - The payment and document plus controls reveal eligible checkboxes, update the totals on selection, and collapse only unselected candidates on completion (AC 4)
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "adds payments and documents in their own list"`

**C5** - The totals are below both lists and show the specified zero, negative, positive and empty-side states, including their amount, verdict, and tone (AC 5)
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "shows signed and colored differences"`

**C6** - The observation disclosure opens on activation and on a rejected shortfall with whitespace-only observation. The UI and direct request show the missing-observation validation (AC 6)
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "opens the required observation on shortfall"`
Proof: `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches lesser blank observation 422s matches with border-rule"`

**C7** - The exception control and confirmation have the same resting dimensions. The exception picker shows only active kinds. Selecting a kind keeps the current payment and clears documents. Canceling restores match mode. Match and exception submits retain the selected account and refresh the queue (AC 7)
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "chooses and cancels an outlined exception"`
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 03" -e "workspace criterion 17"`
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "confirms a match and advances within the account"`

**C8** - The balanced workspace follows `.specs/features/matches-resolution/captures/prototype.html` at desktop and phone widths as in `.specs/features/matches-resolution/captures/balanced-desktop.png` and `.specs/features/matches-resolution/captures/balanced-phone.png` (AC 8)
Proof: `bin/rspec spec/system/month_matches_spec.rb -e "workspace fits desktop and phone widths"`
Proof: walk - open the balanced workspace and compare the desktop and phone layout against the interactive source
Proof: browser - open the balanced workspace at 1280 × 900, save `captures/balanced-desktop.running.png`
Proof: browser - open the balanced workspace at 390 × 1080, save `captures/balanced-phone.running.png`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| workspace visibility (3) | open C8 · empty C1 · closed C1 | - |
| account selector states (2) | selected C2 · all C2 | - |
| selected and offered record types (2) | payments C3/C4 · documents C3/C4 | - |
| comparison states (5) | equal C5 · documents lower C5 · documents higher C5 · no documents C5 · no payments C5 | - |
| source controls (9) | account C2 · payment checkbox C4 · document checkbox C4 · add/finish payment C4 · add/finish document C4 · observation C6 · confirm C7 · choose exception C7 · cancel exception C7 | - |
| review widths (2) | desktop C8 · 390 CSS px C8 | - |

## Swept

- validation: C1, C6
- failure modes: C1, C6
- idempotency: existing - Match.confirm and exception marking retain their server-side guards
- authorization: existing - coordinator guard and active organization account lookup
- concurrency: existing - domain locks and validation still own persistence
- data lifecycle: existing - the match and exception actions persist the same records
- dependency failure: n/a - no new dependency
- state transitions: C2, C4, C5, C6, C7
- observability: n/a - no new operational event

## Handoff

- **Settled mid-build:** user authorized issue creation. Issue #185 tracks the approved changes.
- **Dispatched:** worker implementation from `a0eb0b1`
- **Boundary:** C1–C8 frozen, pending implementation.
- **Abandoned:** none
- **Walked:** Signed into the isolated development app as the fictional coordinator, opened October 2026 from the month, and entered Casar pagamentos. Observed the balanced total, unchecked the R$ 150,00 receipt and saw the red shortfall, then submitted without observation and saw the alert before the filter and the open field. Added the R$ 330,00 document and saw the blue surplus. Chose and canceled a bank-fee exception, selected Caixa and saw its single pending payment plus a balanced receipt, viewed the stacked workspace at 390 CSS pixels, then restored Todas as contas.
