# Development coordinator seed

> Build this with **tlc-implement**.
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

A freshly prepared local database has the bank catalog and no Account. Google sign-in for `gutors@gmail.com` matches nothing, so the callback leaves no session and redirects to `/denied`. There is no screen that creates or renames an Organization, so that person cannot get past the door from the UI. Issue #60 gives no volume figure; the cost is that local monthly close cannot be opened.

When this ships, `bin/rails db:seed` in development persists Organization `ONG Exemplo`, Account `gutors@gmail.com` with `google_uid` nil, and one coordinator Access between them. The next verified Google callback for that email signs in and stores the uid. A second seed writes nothing, including when that Account already exists. Loading the seed outside development does not persist that Account. The local note in the README says so.

6 criteria in 2 slices · 1 one-way door · 0 open, of which 0 block

## Criteria

### Development seed

1. Given no Organization, Account, or Access, when the planter runs, then the database has exactly one Organization named `ONG Exemplo`, exactly one Account with email `gutors@gmail.com` and `google_uid` nil, exactly one Access of kind `coordinator` linking them, no Invite, and no Access of kind `submitter`.
2. When the planter runs again after that, then `Organization.count`, `Account.count`, and `Access.count` are unchanged, because the planter returns without writing when an Account with email `gutors@gmail.com` already exists.
3. Given an Account with email `gutors@gmail.com` and no Organization named `ONG Exemplo`, when the planter runs, then `Organization.count` and `Access.count` are unchanged and that Account’s `google_uid` is unchanged.
4. If the planter raises before commit, then `Organization.count`, `Account.count`, and `Access.count` are unchanged from before the call, because the Organization, Account, and Access writes share one transaction.
5. When `db/seeds.rb` is loaded and `Rails.env.development?` is false, then no Account with email `gutors@gmail.com` is persisted.

### Local note

6. The local setup note in `README.md` states that `bin/rails db:seed` in development persists Organization `ONG Exemplo` and coordinator Account `gutors@gmail.com`.

## Out of scope

- Submitter Invite or Access — declined in #60; after login the coordinator invites from `/`, and that person also signs in with Google
- Month, bank account, statement, or supporting-document rows — #60 asks only for the coordinator who can enter
- A schema migration that inserts these rows — it runs in production, and `db:schema:load` does not replay it
- Changing `coordinator:bootstrap` — it remains the path for another email or name, and it still aborts when that email already has an Account
- A screen to create or rename an Organization — login needs the one organization the seed inserts; rename stays unavailable
- Setting `google_uid` in the seed — `assign_uid!` does not replace a uid that is already present; the first verified callback stores it

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| command `bin/rails db:seed` | output format and verbosity | existing - Rails seed runner; no new message |
| command `bin/rails db:seed` | flags and defaults | n/a - no new flag; the planter runs only when `Rails.env.development?` (5) |
| command `bin/rails db:seed` | exit codes | existing - an exception aborts the seed process |
| command `bin/rails db:seed` | failure halfway | 4 |
| document `README.md` local setup note | structure, tone, depth, next action | 6 |

## Swept

- validation: existing - `Account` rejects a duplicate or ill-formed email (`app/models/account.rb`); `gutors@gmail.com` is already normalized
- failure modes: 4
- idempotency and retry: 2
- authorization: n/a - no HTTP boundary; kind `coordinator` is the existing sign-in gate in `OperatorAuthenticator`
- concurrency and ordering: n/a - one local `db:seed`; two overlapping planters are not a case this task takes
- data lifecycle: n/a - the rows have no expiry; they leave when the development database is dropped
- external-dependency failure: n/a - the planter does not call Google; `google_uid` stays nil until the existing callback
- state transitions: n/a - no status field; row presence is 1–3
- observability: n/a - no new log, metric, or seed message

## Impact

| Front | What changes |
|---|---|
| domain | existing terms `Organization`, `Account`, `Access` — meanings unchanged; the seed inserts rows and no caller branches on a new meaning |
| stored data | nothing to migrate; development seed inserts rows on an empty local database, no backfill |

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| Development seed, not a migration | `db/seeds.rb` invokes the planter only when `Rails.env.development?` | A data migration: it runs in production, and `db:schema:load` does not replay the insert |

## Sources

- https://github.com/gutors/ai-accounting-assistant/issues/60 — the slice: development seed of Organization `ONG Exemplo`, Account `gutors@gmail.com` with `google_uid` nil, coordinator Access; no submitter; not a migration
- Conversation, 22 Sep 2026 — "use my email gutors@gmail.com to log with Google"; "Não plante submitter; eu convido depois, já logado como gutors@gmail.com"; "So adicionar o coordenador inicial." The UI cannot create an Organization (`config/routes.rb` has no organization create; `OrganizationsController` only shows the focused one)

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| | | None | |
