# Coordinator access checks

Profile: standard
Plan: `.specs/features/coordinator-access/plan.md`

40 checks in 6 slices · 8 one-way doors · 0 open

`bin/rspec` does not exist yet; door 1 creates it. Proofs use that wrapper and `-e` as `.cursor/rules/rails.mdc` already names.

## Checks

### S1 - Planted coordinator signs in · rails new + auth · door 1 exceeds 150k alone

**C1** - Unauthenticated `GET /` responds `302` to `/login` (AUTH-01, AC 1)
Proof: `bin/rspec spec/requests/sessions_spec.rb -e "unauthenticated GET / responds 302 to /login"`

**C2** - `GET /login` responds `200` and includes `Entrar com Google` (AUTH-01, AC 2)
Proof: `bin/rspec spec/requests/sessions_spec.rb -e "GET /login responds 200 with Entrar com Google"`

**C3** - A verified Google callback for an email that already has coordinator Access sets the session, sets focus to that organization, and responds `302` to the organization home that includes that organization’s name (AUTH-01, AC 3)
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "verified coordinator callback redirects to organization home"`

**C4** - A second verified Google callback for an email that already has an Account persists no second Account and sets the session on the existing Account (AUTH-01, AC 4, door 3)
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "second callback reuses Account"`
Proof: `bin/rspec spec/models/account_spec.rb -e "rejects a second Account for the same normalized email"`

**C5** - A Google callback with `email_verified` not true persists no Account, sets no session, and responds `302` to `/login` (AUTH-01, AC 5)
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "unverified email persists no Account and redirects to /login"`

**C6** - A failed Google OIDC attempt sets no session and responds `302` to `/login` (AUTH-01, AC 6)
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "OmniAuth failure redirects to /login with no session"`

**C7** - `DELETE /session` clears the session and responds `302` to `/login` (AUTH-01, AC 7)
Proof: `bin/rspec spec/requests/sessions_spec.rb -e "DELETE /session clears session and redirects to /login"`

**C8** - Google OmniAuth is configured with scopes `openid` and `email` only (AUTH-01, AC 8, door 2)
Proof: `bin/rspec spec/config/omniauth_spec.rb -e "google_oauth2 scopes are openid and email only"`

**C9** - `/login` and the organization home render with default locale `pt-BR` (AUTH-01, AC 9, door 1)
Proof: `bin/rspec spec/requests/sessions_spec.rb -e "login and organization home use locale pt-BR"`

**C10** - The Rails app uses PostgreSQL, does not load Active Storage, and does not ship Kamal deploy config (door 1)
Proof: `bin/rspec spec/config/application_spec.rb -e "uses PostgreSQL, skips Active Storage, skips Kamal"`

**C11** - `POST /auth/google_oauth2` with CSRF responds `302` (AUTH-01, Surface)
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "POST /auth/google_oauth2 responds 302"`

**C12** - Account rejects a second row for the same Google uid when uid is present (door 3)
Proof: `bin/rspec spec/models/account_spec.rb -e "rejects a second Account for the same Google uid"`

### S2 - Uninvited Google is refused

**C13** - A verified Google callback for an email with no Account and no pending Invite persists no Account and responds `302` to `/denied` (AUTH-02, AC 10)
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "uninvited callback persists no Account and redirects to /denied"`

**C14** - `GET /denied` responds `200` and includes `não foi convidado` (AUTH-02, AC 11)
Proof: `bin/rspec spec/requests/denied_spec.rb -e "GET /denied responds 200 with nao foi convidado"`

**C15** - A second verified Google callback for the same uninvited email still persists no Account for that email (AUTH-02, AC 12)
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "second uninvited callback still persists no Account"`

### S3 - Invite another coordinator

**C16** - `POST /coordinator_invites` with a well-formed email that has neither standing Access nor a pending Invite on the focused organization persists one pending Invite of kind `coordinator` and responds `302` to the organization home (INVITE-01, AC 13, door 5)
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites persists a coordinator Invite and redirects"`
Proof: `bin/rspec spec/models/invite_spec.rb -e "persists kind coordinator"`

**C17** - `GET /` lists standing coordinator emails and pending Invite emails of the focused organization (INVITE-01, AC 14)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "organization home lists standing and pending coordinator emails"`

**C18** - `GET /` lists no pending-invite email when the focused organization has no pending Invite (INVITE-01, AC 15)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "organization home lists no pending invite when none exist"`

**C19** - A verified Google callback for an email matching a pending Invite reuses or creates the Account, persists coordinator Access, deletes that Invite, sets the session, and responds `302` to the organization home (INVITE-01, AC 16)
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "callback matching Invite grants Access and deletes Invite"`
Proof: `bin/rspec spec/models/invite_spec.rb -e "accept creates coordinator Access and deletes the Invite"`

**C20** - `POST /coordinator_invites` responds `422` and persists no Invite for each rejected email: standing coordinator Access, already-pending Invite, not-an-email (INVITE-01, AC 17, AC 18, AC 19)
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "rejected invite emails return 422"`
Proof: `bin/rspec spec/models/invite_spec.rb -e "rejects standing Access, pending duplicate, and invalid email"`

**C21** - Unauthenticated `POST /coordinator_invites` persists no Invite and responds `302` to `/login` (INVITE-01, AC 20)
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "unauthenticated POST /coordinator_invites responds 302 to /login"`

**C22** - Two concurrent `POST /coordinator_invites` for the same email and organization persist exactly one pending Invite (INVITE-01, AC 21, door 5)
Proof: `bin/rspec spec/models/invite_spec.rb -e "concurrent creates persist exactly one pending Invite"`

**C23** - Access rejects a second row for the same Account and Organization (door 4)
Proof: `bin/rspec spec/models/access_spec.rb -e "rejects a second Access for the same Account and Organization"`

**C24** - Access kind enum members are `coordinator` and `submitter`; invite and bootstrap persist `coordinator` (door 4)
Proof: `bin/rspec spec/models/access_spec.rb -e "kind enum members are coordinator and submitter"`

### S4 - Revoke without leaving zero

**C25** - Confirmed `DELETE /accesses/:id` of another coordinator Access, when at least one coordinator Access would remain, deletes that Access and responds `302` to the organization home (ACCESS-01, AC 22)
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "DELETE /accesses/:id of a non-last coordinator redirects"`

**C26** - The organization home revoke control includes `data-turbo-confirm` (ACCESS-01, AC 23)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "revoke control includes data-turbo-confirm"`

**C27** - `DELETE /accesses/:id` that would leave zero coordinator Accesses leaves Accesses unchanged and responds `422` (ACCESS-01, AC 24, door 6)
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "DELETE last coordinator Access returns 422"`
Proof: `bin/rspec spec/models/access_spec.rb -e "destroy is rejected when it is the last coordinator Access"`

**C28** - Two concurrent destroys that would drop coordinator Access count to zero persist exactly one remaining coordinator Access; the request that would take the last responds `422` (ACCESS-01, AC 25, door 6)
Proof: `bin/rspec spec/models/access_spec.rb -e "concurrent destroy of last two persists exactly one"`
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "concurrent DELETE of last two returns 422 to the loser"`

**C29** - `DELETE /coordinator_invites/:id` for a pending Invite on the focused organization deletes that Invite and responds `302` to the organization home (ACCESS-01, AC 26)
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "DELETE /coordinator_invites/:id redirects"`

**C30** - A verified Google callback for an Account with no remaining Access leaves the Account, sets no organization focus, and responds `302` to `/denied` (ACCESS-01, AC 27)
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "callback with zero Access redirects to /denied and keeps Account"`

**C31** - `DELETE /coordinator_invites/:id` for an Invite not on the focused organization responds `404` and leaves the Invite (Surface)
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "DELETE /coordinator_invites/:id of another organization returns 404"`

**C32** - `DELETE /accesses/:id` for an Access not on the focused organization responds `404` and leaves the Access (Surface)
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "DELETE /accesses/:id of another organization returns 404"`

### S5 - Focus across organizations

**C33** - `GET /` includes a control listing organization names when the Account holds coordinator Access on more than one organization (FOCUS-01, AC 28)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "home lists organization names when Account has multiple Accesses"`

**C34** - `POST /focus` with an `organization_id` the Account has coordinator Access on sets focus to that organization and responds `302` to that organization’s home (FOCUS-01, AC 29, door 7)
Proof: `bin/rspec spec/requests/focus_spec.rb -e "POST /focus to an Access organization redirects"`

**C35** - `GET /` while focused on organization A does not list Access or Invite emails that belong only to organization B (FOCUS-01, AC 30, door 7)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "focused home does not list another organization Access or Invite"`

**C36** - `POST /focus` with an `organization_id` the Account has no Access on responds `404` and leaves focus unchanged (FOCUS-01, AC 31)
Proof: `bin/rspec spec/requests/focus_spec.rb -e "POST /focus without Access returns 404"`

### S6 - Bootstrap the first organization

**C37** - `bin/rails coordinator:bootstrap` with `ORGANIZATION_NAME` and `COORDINATOR_EMAIL` set, when that email has no Account, persists one Organization, one Account for that normalized email, and one coordinator Access, then exits `0` (BOOT-01, AC 32, door 8)
Proof: `bin/rspec spec/tasks/coordinator_bootstrap_spec.rb -e "bootstrap persists Organization Account and coordinator Access"`

**C38** - `bin/rails coordinator:bootstrap` persists nothing and exits non-zero for each rejected `COORDINATOR_EMAIL`: missing, not-an-email (BOOT-01, AC 33)
Proof: `bin/rspec spec/tasks/coordinator_bootstrap_spec.rb -e "bootstrap rejects missing and invalid COORDINATOR_EMAIL"`

**C39** - `bin/rails coordinator:bootstrap` when that email already has an Account persists no second Account and exits non-zero (BOOT-01, AC 34)
Proof: `bin/rspec spec/tasks/coordinator_bootstrap_spec.rb -e "bootstrap rejects an email that already has an Account"`

**C40** - No public registration route persists an Account (door 8)
Proof: `bin/rspec spec/requests/sessions_spec.rb -e "no public registration route persists an Account"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| `GET /login` statuses (1) | 200 C2 | - |
| `POST /auth/google_oauth2` statuses (1) | 302 C11 | - |
| `GET /auth/google_oauth2/callback` statuses (1) | 302 C3 | - |
| callback outcomes (6) | Access home C3 · Invite accept C19 · uninvited `/denied` C13 · zero Access `/denied` C30 · unverified `/login` C5 · OmniAuth failure `/login` C6 | - |
| `DELETE /session` statuses (1) | 302 C7 | - |
| `GET /denied` statuses (1) | 200 C14 | - |
| `GET /` statuses (2) | 200 C17 · 302 C1 | - |
| `POST /coordinator_invites` statuses (2) | 302 C16 · 422 C20 | - |
| invite rejection reasons (3) | C20, table-driven over all 3 | - |
| `DELETE /coordinator_invites/:id` statuses (2) | 302 C29 · 404 C31 | - |
| `DELETE /accesses/:id` statuses (3) | 302 C25 · 422 C27 · 404 C32 | - |
| `POST /focus` statuses (2) | 302 C34 · 404 C36 | - |
| Google scopes (2) | `openid` C8 · `email` C8 | - |
| Account identity uniqueness (2) | normalized email C4 · Google uid C12 | - |
| Access kind enum (2) | `coordinator` C24 · `submitter` C24 | - |
| bootstrap `COORDINATOR_EMAIL` rejects (2) | missing C38 · not-an-email C38 | - |
| door 1 rails new (3) | PostgreSQL C10 · no Active Storage C10 · no Kamal C10 | - |
| last-coordinator destroy (2) | sequential last `422` C27 · concurrent last-two C28 | - |
| Relations entities (4) | Account C4 · Organization C37 · Access C23 · Invite C16 | - |
| startup config: OmniAuth Google (1 assembly) | Rails app and specs load the same initializer C8 | - |

- Claims naming a status code, route or response shape: C1, C2, C3, C5, C6, C7, C11, C13, C14, C16, C17, C20, C21, C25, C27, C29, C31, C32, C34, C36 - each has a proof that crosses the HTTP or command boundary
- No other check claims more than the single case its proof exercises, except C20 (3 rejection reasons) and C38 (2 bootstrap rejects), each table-driven over the whole set

## Test policy

`.cursor/rules/rails.mdc` already answers which level proves which code and how much of the input space counts. This build runs under those rows; they are not proposed as a new guideline commit.

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Decides, reached across a boundary | one at the boundary **and** one at its own layer | the contract at the boundary; one asserted case per row of the decision table at its own layer |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member |
| Entry point that decides nothing | one at the boundary | accepted input, each rejected input, each error path |
| Instrumentation, pass-throughs | none of its own | covered by its consumer's proof |

Evidence (classified from the approved plan; no product files exist yet):

- Google callback dispatch: 6 outcomes (Coverage `callback outcomes`) -> decides, reached across `GET /auth/google_oauth2/callback`
- Invite create: 4 outcomes (persist coordinator, standing Access, pending duplicate, invalid email) -> decides, reached across `POST /coordinator_invites`
- coordinator Access destroy: 2 outcomes (delete when remainder exists, abort at zero) plus concurrent last-two -> decides, reached across `DELETE /accesses/:id`
- Focus: 2 outcomes (Access org, no Access) -> decides, reached across `POST /focus`
- Bootstrap: 4 outcomes (ok, missing email, invalid email, existing Account) -> decides, reached across `bin/rails coordinator:bootstrap`
- OmniAuth scope config: configured values, no request-time branch -> own layer C8
- closest analogue in the repo: none — first product code; the house pattern is `.cursor/rules/rails.mdc` Tests (RSpec)

Cost: dual proofs on callback accept (C19), invite create/reject (C16, C20), last-coordinator destroy (C27, C28), Account email uniqueness (C4). Without those own-layer proofs the decision tables would be proven only by a path that happens to traverse them.

## Swept

- validation: C20, C38
- failure modes: C6
- idempotency: C4, C15
- authorization: C21, C31, C32, C36
- concurrency: C22, C28
- data lifecycle: C19, C29, C30 - Invite deleted on accept or cancel; Account remains after Access is gone
- dependency failure: C6
- state transitions: C19, C27
- observability: n/a - no logging or metrics criterion in the plan

## Handoff

- S1 includes `rails new` (door 1). The generated tree is expected to exceed 150k tokens by character count; one builder still, because splitting S1 mid-scaffold is not a slice boundary. S2–S6 are additive on that tree.
- S1-S6 = one builder
- **Boundary:** C1-C40 closed
- **Settled mid-build:** none
- **Abandoned:** JSON 3.0 broke encrypted session cookies (`JSON.parse` no longer takes a positional options hash); pinned `json ~> 2.13`. Concurrent last-two DELETE as cross-revoke 404'd the loser after their Access was gone; each coordinator revokes self so the lock's 422 is observable.
