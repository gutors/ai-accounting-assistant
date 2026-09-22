# Development coordinator seed

Sources:

- `.tasks/development-coordinator-seed.md` - criteria 1–6, the development-only door, the sweep
- https://github.com/gutors/ai-accounting-assistant/issues/60 - Organization `ONG Exemplo`, Account `gutors@gmail.com` with `google_uid` nil, one coordinator Access; no submitter; not a migration
- Conversation, 22 Sep 2026 - that email is the local Google login; no submitter in the seed; the UI cannot create an Organization

No design source. No binding screen.

## Out of scope

- Submitter Invite or Access - #60; after login the coordinator invites from `/`
- Month, bank account, statement, or supporting-document rows - #60 asks only for the coordinator who can enter
- A schema migration that inserts these rows - it runs in production, and `db:schema:load` does not replay it
- Changing `coordinator:bootstrap` - it remains the path for another email or name, and it still aborts when that email already has an Account
- A screen to create or rename an Organization
- Setting `google_uid` in the seed - the first verified callback stores it

## Landing

Touches `db/seeds.rb` and a planter the seed invokes. Reuses `Organization.create!`, `Account.create!`, and `Access.create!` as `coordinator:bootstrap` already does (`lib/tasks/coordinator.rake`). Does not change that task.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Development seed, not a migration | `db/seeds.rb` invokes the planter only when `Rails.env.development?` | A data migration: it runs in production, and `db:schema:load` does not replay the insert |

- Nothing else in this change is hard to reverse

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions):

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across HTTP | one at the model layer and one request spec | one asserted case per enumerated member; status and who may call at HTTP | follow — this change has no HTTP boundary |
| Decides, not reached across HTTP | one at its own layer | one asserted case per enumerated member | follow |
| Entry point or adapter that decides nothing | one at the boundary | accepted input, each rejected input, each error path | follow — no such adapter here |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` names the level (model/job for a decision; HTTP also a request spec) and the sampling rule (one asserted case per enumerated member)
- `DevelopmentCoordinatorSeed` decides on account presence (2 members: absent, present) and wraps the three writes in one transaction. Proven in a model spec
- `db/seeds.rb` decides on `Rails.env.development?` (2 members: false, true). Proven by loading that file, the same shape as `spec/tasks/coordinator_bootstrap_spec.rb` invoking the rake task that holds its decision
- Closest analogue: `lib/tasks/coordinator.rake` proven at the task in `spec/tasks/coordinator_bootstrap_spec.rb` (create, invalid email, existing Account)

Cost: four model examples for the planter (plant, second run, pre-existing Account, raise before commit) and two examples that load `db/seeds.rb` (development false, development true), plus one example that reads the README note.

These rows are the bar this build uses. They already live in `.cursor/rules/rails.mdc`, so that file stays as it is.

## Checks

### S1 - Development seed · 6 files · 9 KB · ~2k

`db/seeds.rb` 19, `app/models/account.rb` 832, `app/models/access.rb` 516, `app/models/invite.rb` 1170, `app/models/organization.rb` 5667, `lib/tasks/coordinator.rake` 725. 8929 bytes / 4 ≈ 2.2k.

**C1** - Given no Organization, Account, or Access, when the planter runs, then the database has exactly one Organization named `ONG Exemplo`, exactly one Account with email `gutors@gmail.com` and `google_uid` nil, exactly one Access of kind `coordinator` linking them, no Invite, and no Access of kind `submitter` (criterion 1)
Proof: `bin/rspec spec/models/development_coordinator_seed_spec.rb -e "plants ONG Exemplo and gutors@gmail.com with nil google_uid"`

**C2** - When the planter runs again after that, then `Organization.count`, `Account.count`, and `Access.count` are unchanged, because the planter returns without writing when an Account with email `gutors@gmail.com` already exists (criterion 2)
Proof: `bin/rspec spec/models/development_coordinator_seed_spec.rb -e "second plant leaves Organization Account and Access counts unchanged"`

**C3** - Given an Account with email `gutors@gmail.com` and `google_uid` `uid-existing`, and no Organization named `ONG Exemplo`, when the planter runs, then `Organization.count` and `Access.count` are unchanged and that Account’s `google_uid` is still `uid-existing` (criterion 3)
Proof: `bin/rspec spec/models/development_coordinator_seed_spec.rb -e "existing gutors@gmail.com leaves counts and google_uid unchanged"`

**C4** - If `Account.create!` inserts the Account and then raises before the planter’s transaction commits, then `Organization.count`, `Account.count`, and `Access.count` are unchanged from before the call, because the Organization, Account, and Access writes share one transaction (criterion 4)
Proof: `bin/rspec spec/models/development_coordinator_seed_spec.rb -e "raise from Account.create! before commit leaves counts unchanged"`

**C5** - When `db/seeds.rb` is loaded and `Rails.env.development?` is false, then no Account with email `gutors@gmail.com` is persisted (criterion 5)
Proof: `bin/rspec spec/db/seeds_spec.rb -e "loading seeds.rb when not development persists no gutors@gmail.com Account"`

**C7** - When `db/seeds.rb` is loaded and `Rails.env.development?` is true and no Account with email `gutors@gmail.com` exists, then the database has exactly one Organization named `ONG Exemplo`, exactly one Account with that email and `google_uid` nil, and exactly one coordinator Access linking them (intent: `bin/rails db:seed` in development persists those rows; the true member of the env gate in the decided shape)
Proof: `bin/rspec spec/db/seeds_spec.rb -e "loading seeds.rb in development plants ONG Exemplo and gutors@gmail.com"`

### S2 - Local note · 1 file · 4 KB · ~1k

`README.md` 4030 bytes / 4 ≈ 1.0k.

**C6** - The local setup note under `## Estado` in `README.md` includes `bin/rails db:seed`, `development`, `ONG Exemplo`, `gutors@gmail.com`, and `coordenador` (criterion 6)
Proof: `bin/rspec spec/db/seeds_spec.rb -e "README local note states development db:seed persists ONG Exemplo and gutors@gmail.com"`

## Swept

- validation: existing - `Account` rejects a duplicate or ill-formed email; `gutors@gmail.com` is already normalized
- failure modes: C4
- idempotency: C2
- authorization: n/a - no HTTP boundary; kind `coordinator` is the existing sign-in gate in `OperatorAuthenticator`
- concurrency: n/a - one local `db:seed`; two overlapping planters are not a case this task takes
- data lifecycle: n/a - the rows have no expiry; they leave when the development database is dropped
- dependency failure: n/a - the planter does not call Google; `google_uid` stays nil until the existing callback
- state transitions: n/a - no status field; row presence is C1–C3
- observability: n/a - no new log, metric, or seed message

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| planter account presence (2) | absent C1 · present C2, C3 | - |
| planter transaction (1) | raise before commit C4 | - |
| `db/seeds.rb` `Rails.env.development?` (2) | false C5 · true C7 | - |

- Claims naming a status code, route, or response shape: none
- No other check claims more than the single case its proof exercises

## Handoff

profile: standard. handoff: on. budget: 150k.

S1 ≈ 2k and S2 ≈ 1k. Running total ≈ 3k, under 150k. Both slices are the seed and the note that describes it, so they stay in one batch. No handoff boundary.
