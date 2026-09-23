# Administration intake

The seller registers an organization and its coordinator from `/administration`. The console bootstrap stays, and it cannot open a second organization for an email that already has an Account.

## Status

accepted

## Considered options

- **An `administrators` table.** Rejected: a second person who must open the screen without a deploy is not the seller today.
- **`administrator?` is one normalized env email (chosen).** True only when `NormalizedEmail.normalize(ENV["ADMINISTRATOR_EMAIL"])` equals `current_account.email`. Blank or unset env is false.

- **Requiring a bootstrapped Access before the form.** Rejected: the seller is not a coordinator of the customer organization, and a verified email with zero Access currently ends on `/denied` without an Account.
- **Allowlisted sign-in with zero Access (chosen).** A verified email equal to `ADMINISTRATOR_EMAIL`, with zero Access and zero Invites, creates the Account when it is missing and signs in with no organization. `sign_in` stores `organization&.id`. The callback redirects to `/administration` when that result has no organization. Pending Invites for that email still accept first.

- **A case-sensitive unique index on `organizations.name`.** Rejected: `ONG Norte` and `ong norte` would be two organizations.
- **Leaving the name non-unique.** Rejected: two overlapping confirms could insert two rows. Coordinator access had allowed two NGOs to share a presentation name; that no longer holds.
- **Unique index on `lower((name)::text)` (chosen).** Index name `index_organizations_on_lower_name`. The stored name stays the stripped text the person typed. A taken name is `422` with `Já existe uma organização com esse nome.` and does not store a pending registration. A confirm that loses the insert rolls back, sends no mail, and responds `422` with that notice.

## Consequences

- Later administration screens reuse `administrator?`. They do not add a second allowlist.
- Creators of an Organization are `coordinator:bootstrap` and `Organization.register_coordinator`. The rake task is not taught to attach a second organization.
- A migration that builds this index fails if two existing rows already share a lowercased name. There is no backfill.
