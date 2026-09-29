# Administration access

The administrator moves coordinator Access to another email without rewriting `Account.email`, and deletes an organization that has no close data. Pending invites are mailed from the organization home.

## Status

accepted

## Considered options

- **Rewriting `Account.email` on a correction.** Rejected: that column is the Google identity `OperatorAuthenticator` looks up; the old address would stop being that Account.
- **Insert the new coordinator Access, delete a pending Invite for that email on that organization, then destroy the old Access, in one transaction. Create the Account when it is missing. Deliver the welcome after commit (chosen).** The organization never passes through a moment with no coordinator, and `Access#destroy` does not refuse the sole coordinator because the new Access exists first.

- **An `archived_at` flag.** Rejected: a removed organization would stay readable, which issue #63 refuses.
- **Delete Accesses (including the last coordinator) and Invites, then the Organization, only when `bank_accounts`, `months`, `supporting_documents`, `justifications`, and `extra_exception_kinds` are all empty (chosen).** Account rows stay. Accountant, package archive, and certificate columns go with the organization row. Removal does not call `Access#destroy`, so the last-coordinator refusal is not a veto.

## Consequences

- Callers that look up an Account by email still find the Google identity that signed in.
- `Access#destroy` of the last coordinator still returns false. `DELETE /accesses/:id` of a coordinator Access the caller may not revoke — including their own — answers `404` and does not call `destroy`.
- A later feature that needs a readable removed organization has to reopen this ADR.
