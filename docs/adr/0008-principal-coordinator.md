# Principal coordinator pointer

The sale identity of an organization is `organizations.principal_coordinator_account_id`, not the alphabetically first coordinator Access.

## Status

accepted

## Considered options

- **A `principal` boolean on `accesses`.** Rejected: two coordinator rows could both be true unless a partial unique index existed, and the sale identity would still be inferred from Access rather than from the organization the seller edits.
- **Treat the newly accepted invite as principal.** Rejected: a later invite would steal `Email coordenador`.
- **`organizations.principal_coordinator_account_id` `bigint NOT NULL`, FK to `accounts(id)`, `ON DELETE RESTRICT` (chosen).** One principal per organization by being a single column. `Invite#accept!` creates a coordinator Access and does not write this column. `register_coordinator`, bootstrap, and the development seed set it to the Account they create.

## Consequences

- The administration list column and `Ativa` / `Pendente` follow that Account.
- Home lists that coordinator first. Only that person may revoke a peer coordinator Access.
