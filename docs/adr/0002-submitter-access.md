# Submitter Access, focus, and Justification

A coordinator invites a submitter by email. That person signs in with Google, works inside organizations they have Access on, and must not see payments, statements, matches, close-for-send, or setup. Spent amounts they declare live beside supporting documents, not on a payment.

## Status

accepted

## Considered options

- **Keep `focused_organization` coordinator-only.** Rejected: a signed-in submitter would `302` `/login` on `/` despite `account_id`.
- **Expand focus without a coordinator 404.** Rejected: one missed guard on `MonthsController#show` leaks payments.
- **Focus is any Access; coordinator-only HTML is 404 for submitter (chosen).** Session `organization_id` may be an organization the Account holds Access on, of either kind. HTML that lists or mutates months, statements, payments, matches, document exceptions, close-for-send, setup, accountant, package archive, Invites, or Accesses requires coordinator Access on the focused organization and otherwise responds `404` with no Payment / Bank statement body.

- **A second `SubmitterInvite` table.** Rejected: the glossary is one Invite.
- **Accept always coordinator.** Rejected: a submitter invite would grant the close ritual.
- **Invite.kind is the Access that accept persists (chosen).** `Invite.create_pending` takes the kind; `accept!` creates `Access` with `invite.kind` and deletes the Invite. Unique pending Invite per Organization per email still covers both kinds. Standing Access of either kind blocks a new Invite on that organization.

- **Spent amount on `SupportingDocument`.** Rejected: cannot express more than one document toward one amount.
- **`Justification` belongs to `Access`.** Rejected: revoke would cascade or strand the grouping while documents must remain on Account.
- **Justification is its own row, document at most one (chosen).** `Justification` belongs to `Organization` and to `Account` (the declarer). `SupportingDocument` belongs to at most one `Justification`. Spent amount is integer cents.

- **Destroy while a Match exists.** Rejected: would dissolve the Match as a side effect; leave-match is the path back to no month.
- **Submitter destroy after month assignment.** Rejected: the author may only withdraw documents that still have no month.
- **Destroy SupportingDocument only while it has no month (chosen).** `DELETE` succeeds only when `month_id` is nil, and only for the inserting Account (submitter) or a coordinator of that organization. Blobs go with the row.

## Consequences

- `focused_organization` looks up any Access. Coordinator controllers use `require_coordinator_organization`.
- Submitter home omits close-ritual chrome. `/supporting_documents` lists only the session Account’s documents for a submitter.
- Later features that add coordinator HTML must 404 for submitter Access on the focused organization.
