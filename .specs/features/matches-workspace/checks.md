# Matches workspace checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/matches-workspace/plan.md`

## Checks

### S1 - Work through a payment

**C1** - WHEN a coordinator opens the matches screen THEN the system SHALL display `Casar pagamentos` and the selected month. (AC 1)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 01"`

**C2** - WHEN pending payments exist THEN the system SHALL select the payment with the earliest `occurred_on`, breaking ties by ascending id, even when no document suggestion exists. (AC 2)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 02"`
Proof: `bin/rspec spec/requests/matches_workspace_spec.rb -e "selects oldest pending payment even without a suggestion"`

**C3** - WHILE an account filter is active, WHEN the coordinator opens the screen THEN the system SHALL select the oldest pending payment within that account and keep the filter after a mutation. (AC 3)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 03"`

**C4** - WHEN the selected payment has a suggestion THEN the system SHALL display each suggested payment and each suggested document separately before confirmation. (AC 4)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 04"`

**C5** - WHEN the selected payment has no suggestion THEN the system SHALL display the payment and an empty document selection with an action to add eligible unmatched documents. (AC 5)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 05"`

**C6** - WHEN the coordinator adds or removes an eligible document THEN the system SHALL update the selection and payment and document totals without saving a match. (AC 6)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 06"`

**C7** - WHEN the coordinator adds another eligible payment THEN the system SHALL support the existing multiple-payments-to-one-document shape and update the totals. (AC 7)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 07"`

**C8** - IF the coordinator selects multiple payments and multiple documents THEN the system SHALL reject confirmation with the existing match shape error and persist no match. (AC 8)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 08"`

**C9** - WHEN the coordinator chooses a suggestion with equal totals THEN the system SHALL leave it unconfirmed until `Confirmar casamento` is used. (AC 9)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 09"`

**C10** - WHEN the coordinator expands `Observação` THEN the system SHALL show an editable observation field; otherwise it SHALL be collapsed. (AC 10)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 10"`

**C11** - IF documents total less than payments and observation is blank THEN the system SHALL refuse the match and show `Informe a observação do casamento`. (AC 11)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 11"`

**C12** - WHEN the coordinator submits a valid match THEN the system SHALL save it, show it in `Casamentos confirmados`, and present the next pending payment. (AC 12)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 12"`

**C13** - IF no pending payments exist in the selected filter THEN the system SHALL show an empty state and continue to display confirmed matches and exceptions. (AC 13)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 13"`

### S2 - Exceptions and completed work

**C14** - WHEN the coordinator opens `Escolher exceção` THEN the system SHALL show the active default and custom exception types in a dropdown following the header organization selector pattern. (AC 14)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 14"`

**C15** - WHEN the coordinator selects a type THEN the system SHALL display that type, clear selected documents, retain only the current payment, and change the primary action to `Marcar exceção` without persisting. (AC 15)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 15"`

**C16** - WHEN the coordinator cancels the exception choice THEN the system SHALL restore the match action and allow documents to be selected again. (AC 16)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 16"`

**C17** - WHEN the coordinator submits `Marcar exceção` THEN the system SHALL mark the selected payment with that active exception, display it in `Exceções marcadas`, and present the next pending payment. (AC 17)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 17"`

**C18** - IF an exception type is inactive or belongs to another organization THEN the system SHALL reject the request and not mark the payment. (AC 18)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 18"`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST deactivated extra_exception_kind_id returns 422"`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST extra_exception_kind_id of another organization returns 404"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "rejects deactivated extra Doacao"`

**C19** - WHEN the coordinator opens `Casamentos confirmados` THEN the system SHALL show each Match once in a single summary row including payment date, payment history, total, document summary and document total. (AC 19)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 19"`

**C20** - WHEN the coordinator expands a confirmed match THEN the system SHALL show every payment and document, their dates and amounts, document types and payees, and any observation. (AC 20)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 20"`

**C21** - WHEN the coordinator undoes a confirmed match THEN the system SHALL remove its row and return its payments and documents to the eligible pools under existing rules. (AC 21)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 21"`

**C22** - WHEN the coordinator opens `Exceções marcadas` THEN the system SHALL show one row per marked payment with date, history, account, amount, exception type and unmark action. (AC 22)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 22"`

**C23** - WHEN the coordinator unmarks an exception THEN the system SHALL remove its row and return the payment to the pending queue. (AC 23)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 23"`

**C24** - WHILE an account filter is active THEN the system SHALL show matches having at least one payment in the selected account, with all members visible in its details, and exceptions for that account. (AC 24)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 24"`

**C25** - WHILE a month is closed THEN the system SHALL display its matches and exceptions without selection, confirmation, exception marking, undo or unmark controls. (AC 25)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 25"`

**C26** - IF a mutation fails validation THEN the system SHALL display the existing error and retain the account filter without persisting an invalid change. (AC 26)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 26"`
Proof: `bin/rspec spec/requests/matches_workspace_spec.rb -e "rerenders the matches screen when exception selection is invalid"`
Proof: `bin/rspec spec/requests/matches_workspace_spec.rb -e "rerenders a closed month when exception marking is refused"`

**C27** - WHEN a coordinator views the screen at 375px or 1440px width THEN the system SHALL keep controls usable and allow wide ledgers to scroll horizontally without clipping their contents. (AC 27)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 27"`

**C28** - WHEN the coordinator operates the exception dropdown by keyboard THEN the system SHALL allow opening, choosing an option and dismissing it with Escape. (AC 28)
Proof: `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 28"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| Plan acceptance criteria (28) | 1 C1 · 2 C2 · 3 C3 · 4 C4 · 5 C5 · 6 C6 · 7 C7 · 8 C8 · 9 C9 · 10 C10 · 11 C11 · 12 C12 · 13 C13 · 14 C14 · 15 C15 · 16 C16 · 17 C17 · 18 C18 · 19 C19 · 20 C20 · 21 C21 · 22 C22 · 23 C23 · 24 C24 · 25 C25 · 26 C26 · 27 C27 · 28 C28 | - |
| Match shapes (3) | 1:N C6 · N:1 C7 · N:M rejected C8 | - |
| Exception types (3) | bank fee C14 · accountant fee C14 · custom C14 | - |
| States (4) | pending C2 · matched C12 · exception C17 · closed C25 | - |

## Swept

- validation: C8, C11, C18, C26; existing Match and Payment guards
- failure modes: C26; existing transactional Match persistence
- idempotency: existing - Match rejects previously matched payments and documents
- authorization: existing - require_coordinator_organization and focused organization lookups
- concurrency: existing - Match row locks and uniqueness validation
- data lifecycle: C12, C17, C21, C23, C25
- dependency failure: n/a - no external calls added
- state transitions: C12, C17, C21, C23, C25
- observability: n/a - no logging requirement in this change

## Handoff

- **Settled mid-build:** none
- **Dispatched:** Verifier at `389e2b3` - returned FAIL; six findings, including two surviving mutations
- **Boundary:** C1-C28 implemented at `389e2b3`; Verifier findings addressed in tests, final proofs and mutation gate pending
- **Abandoned:** GitHub issue creation rejected by automatic approval review
- **Walked:** Browser-driven system examples sign in as coordinator, open `/months/2026-05/matches`, adjust documents and payments, confirm a match, open the exception picker and mark or unmark an exception, expand match details, and view the screen at 375px and 1440px. The app was visually inspected from the system-browser capture.
