# Coordinator access verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: 3950cf4..c48e19fcde189d5ac5fd037eec82befca53f4ec8
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

User walk skipped: HTML request-spec feature; no human UI walk required.

## Checks

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | Unauthenticated GET / is 302 to /login | `bin/rspec spec/requests/sessions_spec.rb -e "unauthenticated GET / responds 302 to /login"` exit 0 | `spec/requests/sessions_spec.rb:7` - `expect(response).to have_http_status(:found)` and `spec/requests/sessions_spec.rb:8` - `expect(response).to redirect_to("/login")` | PASS |
| C2 | GET /login is 200 with Entrar com Google | `bin/rspec spec/requests/sessions_spec.rb -e "GET /login responds 200 with Entrar com Google"` exit 0 | `spec/requests/sessions_spec.rb:14` - `expect(response).to have_http_status(:ok)` and `spec/requests/sessions_spec.rb:15` - `expect(response.body).to include("Entrar com Google")` | PASS |
| C3 | Verified coordinator callback sets session and focus, 302 home with org name | `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "verified coordinator callback redirects to organization home"` exit 0 | `spec/requests/omniauth_callbacks_spec.rb:13` - `expect(response).to have_http_status(:found)` ; `spec/requests/omniauth_callbacks_spec.rb:16` - `expect(session[:organization_id]).to eq(organization.id)` ; `spec/requests/omniauth_callbacks_spec.rb:19` - `expect(response.body).to include("ONG Norte")` | PASS |
| C4 | Second callback reuses Account; unique normalized email | `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "second callback reuses Account"` exit 0; `bin/rspec spec/models/account_spec.rb -e "rejects a second Account for the same normalized email"` exit 0 | `spec/requests/omniauth_callbacks_spec.rb:28` - `expect(Account.where(email: "coord@example.com").count).to eq(1)` ; `spec/models/account_spec.rb:9` - `expect(duplicate).not_to be_valid` | PASS |
| C5 | Unverified email: no Account, no session, 302 /login | `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "unverified email persists no Account and redirects to /login"` exit 0 | `spec/requests/omniauth_callbacks_spec.rb:35` - `end.not_to change(Account, :count)` ; `spec/requests/omniauth_callbacks_spec.rb:38` - `expect(response).to redirect_to("/login")` ; `spec/requests/omniauth_callbacks_spec.rb:39` - `expect(session[:account_id]).to be_nil` | PASS |
| C6 | OmniAuth failure: no session, 302 /login | `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "OmniAuth failure redirects to /login with no session"` exit 0 | `spec/requests/omniauth_callbacks_spec.rb:48` - `expect(response).to redirect_to("/login")` ; `spec/requests/omniauth_callbacks_spec.rb:49` - `expect(session[:account_id]).to be_nil` | PASS |
| C7 | DELETE /session clears session, 302 /login | `bin/rspec spec/requests/sessions_spec.rb -e "DELETE /session clears session and redirects to /login"` exit 0 | `spec/requests/sessions_spec.rb:25` - `expect(response).to redirect_to("/login")` ; `spec/requests/sessions_spec.rb:26` - `expect(session[:account_id]).to be_nil` | PASS |
| C8 | Google scopes are openid and email only | `bin/rspec spec/config/omniauth_spec.rb -e "google_oauth2 scopes are openid and email only"` exit 0 | `spec/config/omniauth_spec.rb:5` - `expect(GoogleOauth.scopes).to contain_exactly("openid", "email")` ; `spec/config/omniauth_spec.rb:7` - `expect(initializer).to include("scope: GoogleOauth.scope_string")` | PASS |
| C9 | /login and org home render locale pt-BR | `bin/rspec spec/requests/sessions_spec.rb -e "login and organization home use locale pt-BR"` exit 0 | `spec/requests/sessions_spec.rb:32` - `expect(response.body).to include('lang="pt-BR"')` ; `spec/requests/sessions_spec.rb:39` - `expect(response.body).to include('lang="pt-BR"')` | PASS |
| C10 | PostgreSQL, no Active Storage, no Kamal | `bin/rspec spec/config/application_spec.rb -e "uses PostgreSQL, skips Active Storage, skips Kamal"` exit 0 | `spec/config/application_spec.rb:5` - `expect(ActiveRecord::Base.connection.adapter_name).to eq("PostgreSQL")` ; `spec/config/application_spec.rb:6` - `expect(defined?(ActiveStorage::Engine)).to be_nil` ; `spec/config/application_spec.rb:10` - `expect(gemfile).not_to match(/^\s*gem ["']kamal["']/)` | PASS |
| C11 | POST /auth/google_oauth2 with CSRF is 302 | `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "POST /auth/google_oauth2 responds 302"` exit 0 | `spec/requests/omniauth_callbacks_spec.rb:60` - `expect(response).to have_http_status(:found)` | PASS |
| C12 | Account rejects duplicate Google uid | `bin/rspec spec/models/account_spec.rb -e "rejects a second Account for the same Google uid"` exit 0 | `spec/models/account_spec.rb:18` - `expect(duplicate).not_to be_valid` | PASS |
| C13 | Uninvited verified callback: no Account, 302 /denied | `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "uninvited callback persists no Account and redirects to /denied"` exit 0 | `spec/requests/omniauth_callbacks_spec.rb:68` - `end.not_to change(Account, :count)` ; `spec/requests/omniauth_callbacks_spec.rb:71` - `expect(response).to redirect_to("/denied")` | PASS |
| C14 | GET /denied is 200 with não foi convidado | `bin/rspec spec/requests/denied_spec.rb -e "GET /denied responds 200 with nao foi convidado"` exit 0 | `spec/requests/denied_spec.rb:7` - `expect(response).to have_http_status(:ok)` ; `spec/requests/denied_spec.rb:8` - `expect(response.body).to include("não foi convidado")` | PASS |
| C15 | Second uninvited callback still persists no Account | `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "second uninvited callback still persists no Account"` exit 0 | `spec/requests/omniauth_callbacks_spec.rb:81` - `expect(Account.find_by(email: "stranger@example.com")).to be_nil` | PASS |
| C16 | POST /coordinator_invites persists coordinator Invite, 302 home | `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites persists a coordinator Invite and redirects"` exit 0; `bin/rspec spec/models/invite_spec.rb -e "persists kind coordinator"` exit 0 | `spec/requests/coordinator_invites_spec.rb:14` - `expect(invite.kind).to eq("coordinator")` ; `spec/requests/coordinator_invites_spec.rb:16` - `expect(response).to have_http_status(:found)` ; `spec/models/invite_spec.rb:9` - `expect(invite.kind).to eq("coordinator")` | PASS |
| C17 | GET / lists standing and pending coordinator emails | `bin/rspec spec/requests/organizations_spec.rb -e "organization home lists standing and pending coordinator emails"` exit 0 | `spec/requests/organizations_spec.rb:12` - `expect(response.body).to include("coord@example.com")` ; `spec/requests/organizations_spec.rb:13` - `expect(response.body).to include("guest@example.com")` | PASS |
| C18 | GET / lists no pending-invite email when none exist | `bin/rspec spec/requests/organizations_spec.rb -e "organization home lists no pending invite when none exist"` exit 0 | `spec/requests/organizations_spec.rb:23` - `expect(response.body).not_to include("guest@example.com")` ; `spec/requests/organizations_spec.rb:24` - `expect(organization.invites).to be_empty` | PASS |
| C19 | Invite-matching callback grants Access, deletes Invite, 302 home | `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "callback matching Invite grants Access and deletes Invite"` exit 0; `bin/rspec spec/models/invite_spec.rb -e "accept creates coordinator Access and deletes the Invite"` exit 0 | `spec/requests/omniauth_callbacks_spec.rb:95` - `expect(Invite.find_by(email: "guest@example.com")).to be_nil` ; `spec/requests/omniauth_callbacks_spec.rb:99` - `expect(response).to redirect_to("/")` ; `spec/models/invite_spec.rb:21` - `expect(access.kind).to eq("coordinator")` | PASS |
| C20 | Invite rejects standing Access, pending duplicate, not-an-email with 422 | `bin/rspec spec/requests/coordinator_invites_spec.rb -e "rejected invite emails return 422"` exit 0; `bin/rspec spec/models/invite_spec.rb -e "rejects standing Access, pending duplicate, and invalid email"` exit 0 | `spec/requests/coordinator_invites_spec.rb:35` - `expect(response).to have_http_status(:unprocessable_content)` over the 3 emails ; `spec/models/invite_spec.rb:36` - `expect(invite).not_to be_persisted` over the same 3 | PASS |
| C21 | Unauthenticated POST /coordinator_invites is 302 /login, no Invite | `bin/rspec spec/requests/coordinator_invites_spec.rb -e "unauthenticated POST /coordinator_invites responds 302 to /login"` exit 0 | `spec/requests/coordinator_invites_spec.rb:42` - `end.not_to change(Invite, :count)` ; `spec/requests/coordinator_invites_spec.rb:45` - `expect(response).to redirect_to("/login")` | PASS |
| C22 | Concurrent invite creates persist exactly one pending Invite | `bin/rspec spec/models/invite_spec.rb -e "concurrent creates persist exactly one pending Invite"` exit 0 | `spec/models/invite_spec.rb:53` - `expect(Invite.where(organization: organization, email: "guest@example.com").count).to eq(1)` | PASS |
| C23 | Access rejects a second row for the same Account and Organization | `bin/rspec spec/models/access_spec.rb -e "rejects a second Access for the same Account and Organization"` exit 0 | `spec/models/access_spec.rb:9` - `expect(duplicate).not_to be_valid` | PASS |
| C24 | Access kind enum is coordinator and submitter; invite and bootstrap write coordinator | `bin/rspec spec/models/access_spec.rb -e "kind enum members are coordinator and submitter"` exit 0; `bin/rspec spec/tasks/coordinator_bootstrap_spec.rb -e "bootstrap persists Organization Account and coordinator Access"` exit 0 | `spec/models/access_spec.rb:13` - `expect(Access.kinds.keys).to contain_exactly("coordinator", "submitter")` ; `spec/models/access_spec.rb:19` - `expect(invite.kind).to eq("coordinator")` ; `spec/tasks/coordinator_bootstrap_spec.rb:31` - `expect(access.kind).to eq("coordinator")` | PASS |
| C25 | Confirmed DELETE of a non-last coordinator Access is 302 and deletes | `bin/rspec spec/requests/accesses_spec.rb -e "DELETE /accesses/:id of a non-last coordinator redirects"` exit 0 | `spec/requests/accesses_spec.rb:12` - `expect(Access.find_by(id: other_access.id)).to be_nil` ; `spec/requests/accesses_spec.rb:13` - `expect(response).to have_http_status(:found)` | PASS |
| C26 | Revoke control includes data-turbo-confirm | `bin/rspec spec/requests/organizations_spec.rb -e "revoke control includes data-turbo-confirm"` exit 0 | `spec/requests/organizations_spec.rb:35` - `expect(response.body).to include("data-turbo-confirm")` | PASS |
| C27 | DELETE last coordinator Access is 422 and leaves Accesses unchanged | `bin/rspec spec/requests/accesses_spec.rb -e "DELETE last coordinator Access returns 422"` exit 0; `bin/rspec spec/models/access_spec.rb -e "destroy is rejected when it is the last coordinator Access"` exit 0 | `spec/requests/accesses_spec.rb:26` - `expect(response).to have_http_status(:unprocessable_content)` ; `spec/models/access_spec.rb:28` - `expect(organization.accesses.coordinator.count).to eq(1)` | PASS |
| C28 | Concurrent destroy of last two keeps one Access; loser is 422 | `bin/rspec spec/models/access_spec.rb -e "concurrent destroy of last two persists exactly one"` exit 0; `bin/rspec spec/requests/accesses_spec.rb -e "concurrent DELETE of last two returns 422 to the loser"` exit 0 | `spec/models/access_spec.rb:48` - `expect(organization.accesses.coordinator.count).to eq(1)` ; `spec/requests/accesses_spec.rb:60` - `expect(statuses).to contain_exactly(302, 422)` | PASS |
| C29 | DELETE /coordinator_invites/:id on focused org deletes Invite, 302 | `bin/rspec spec/requests/coordinator_invites_spec.rb -e "DELETE /coordinator_invites/:id redirects"` exit 0 | `spec/requests/coordinator_invites_spec.rb:55` - `expect(Invite.find_by(id: invite.id)).to be_nil` ; `spec/requests/coordinator_invites_spec.rb:57` - `expect(response).to redirect_to("/")` | PASS |
| C30 | Zero-Access callback keeps Account, no focus, 302 /denied | `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "callback with zero Access redirects to /denied and keeps Account"` exit 0 | `spec/requests/omniauth_callbacks_spec.rb:109` - `expect(Account.find_by!(email: "former@example.com")).to eq(account)` ; `spec/requests/omniauth_callbacks_spec.rb:111` - `expect(response).to redirect_to("/denied")` ; `spec/requests/omniauth_callbacks_spec.rb:112` - `expect(session[:organization_id]).to be_nil` | PASS |
| C31 | DELETE invite of another organization is 404 and leaves Invite | `bin/rspec spec/requests/coordinator_invites_spec.rb -e "DELETE /coordinator_invites/:id of another organization returns 404"` exit 0 | `spec/requests/coordinator_invites_spec.rb:68` - `expect(response).to have_http_status(:not_found)` ; `spec/requests/coordinator_invites_spec.rb:69` - `expect(Invite.find(invite.id)).to eq(invite)` | PASS |
| C32 | DELETE Access of another organization is 404 and leaves Access | `bin/rspec spec/requests/accesses_spec.rb -e "DELETE /accesses/:id of another organization returns 404"` exit 0 | `spec/requests/accesses_spec.rb:76` - `expect(response).to have_http_status(:not_found)` ; `spec/requests/accesses_spec.rb:77` - `expect(Access.find(other_access.id)).to eq(other_access)` | PASS |
| C33 | GET / lists organization names when Account has multiple Accesses | `bin/rspec spec/requests/organizations_spec.rb -e "home lists organization names when Account has multiple Accesses"` exit 0 | `spec/requests/organizations_spec.rb:46` - `expect(response.body).to include("ONG Norte")` ; `spec/requests/organizations_spec.rb:47` - `expect(response.body).to include("ONG Sul")` | PASS |
| C34 | POST /focus to an Access org sets focus and 302 home | `bin/rspec spec/requests/focus_spec.rb -e "POST /focus to an Access organization redirects"` exit 0 | `spec/requests/focus_spec.rb:12` - `expect(session[:organization_id]).to eq(org_b.id)` ; `spec/requests/focus_spec.rb:13` - `expect(response).to have_http_status(:found)` ; `spec/requests/focus_spec.rb:16` - `expect(response.body).to include("ONG Sul")` | PASS |
| C35 | Focused home does not list another organization's Access or Invite | `bin/rspec spec/requests/organizations_spec.rb -e "focused home does not list another organization Access or Invite"` exit 0 | `spec/requests/organizations_spec.rb:61` - `expect(response.body).not_to include("only-b@example.com")` ; `spec/requests/organizations_spec.rb:62` - `expect(response.body).not_to include("invite-b@example.com")` | PASS |
| C36 | POST /focus without Access is 404 and leaves focus | `bin/rspec spec/requests/focus_spec.rb -e "POST /focus without Access returns 404"` exit 0 | `spec/requests/focus_spec.rb:26` - `expect(response).to have_http_status(:not_found)` ; `spec/requests/focus_spec.rb:27` - `expect(session[:organization_id]).to eq(org_a.id)` | PASS |
| C37 | Bootstrap with name and email persists Organization, Account, coordinator Access, exit 0 | `bin/rspec spec/tasks/coordinator_bootstrap_spec.rb -e "bootstrap persists Organization Account and coordinator Access"` exit 0 | `spec/tasks/coordinator_bootstrap_spec.rb:26` - `expect(status).to eq(0)` ; `spec/tasks/coordinator_bootstrap_spec.rb:31` - `expect(access.kind).to eq("coordinator")` | PASS |
| C38 | Bootstrap rejects missing and not-an-email COORDINATOR_EMAIL, persist nothing, non-zero | `bin/rspec spec/tasks/coordinator_bootstrap_spec.rb -e "bootstrap rejects missing and invalid COORDINATOR_EMAIL"` exit 0 | `spec/tasks/coordinator_bootstrap_spec.rb:41` - `expect(status).not_to eq(0)` over both env rows ; `spec/tasks/coordinator_bootstrap_spec.rb:42` - `end.not_to change(Organization, :count)` | PASS |
| C39 | Bootstrap with existing Account persists no second Account, non-zero | `bin/rspec spec/tasks/coordinator_bootstrap_spec.rb -e "bootstrap rejects an email that already has an Account"` exit 0 | `spec/tasks/coordinator_bootstrap_spec.rb:56` - `expect(status).not_to eq(0)` ; `spec/tasks/coordinator_bootstrap_spec.rb:57` - `end.not_to change(Account, :count)` | PASS |
| C40 | No public registration route persists an Account | `bin/rspec spec/requests/sessions_spec.rb -e "no public registration route persists an Account"` exit 0 | `spec/requests/sessions_spec.rb:45` - `end.not_to change(Account, :count)` ; `spec/requests/sessions_spec.rb:47` - `expect(response).to have_http_status(:not_found)` | PASS |

## Coverage

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| GET /login statuses (1) | plan Surface | 200 C2 | - |
| POST /auth/google_oauth2 statuses (1) | plan Surface | 302 C11 | - |
| GET /auth/google_oauth2/callback statuses (1) | plan Surface | 302 C3 C5 C6 C13 C19 C30 | - |
| callback outcomes (6) | plan AC 3,5,6,10,16,27 | Access home C3 · Invite accept C19 · uninvited /denied C13 · zero Access /denied C30 · unverified /login C5 · OmniAuth failure /login C6 | - |
| DELETE /session statuses (1) | plan Surface | 302 C7 | - |
| GET /denied statuses (1) | plan Surface | 200 C14 | - |
| GET / statuses (2) | plan Surface | 200 C17 · 302 C1 | - |
| POST /coordinator_invites statuses (2) | plan Surface | 302 C16 · 422 C20 | - |
| invite rejection reasons (3) | plan AC 17-19 | standing Access C20 · pending duplicate C20 · not-an-email C20 | - |
| DELETE /coordinator_invites/:id statuses (2) | plan Surface | 302 C29 · 404 C31 | - |
| DELETE /accesses/:id statuses (3) | plan Surface | 302 C25 · 422 C27 · 404 C32 | - |
| POST /focus statuses (2) | plan Surface | 302 C34 · 404 C36 | - |
| Google scopes (2) | Landing door 2 / `GoogleOauth.scopes` | openid C8 · email C8 | - |
| Account identity uniqueness (2) | Landing door 3 / Account validations | normalized email C4 · Google uid C12 | - |
| Access kind enum (2) | Landing door 4 / `Access.kinds` | coordinator C24 · submitter C24 | - |
| bootstrap COORDINATOR_EMAIL rejects (2) | plan AC 33 | missing C38 · not-an-email C38 | - |
| door 1 rails new (3) | Landing door 1 / C10 | PostgreSQL C10 · no Active Storage C10 · no Kamal C10 | - |
| last-coordinator destroy (2) | Landing door 6 | sequential last 422 C27 · concurrent last-two C28 | - |
| Relations uniqueness (3) | plan Relations | Account email C4 · Access account+org C23 · Invite org+email C22 | - |
| Relations entities (4) | plan Relations | Account C4 · Organization C37 · Access C23 · Invite C16 | - |
| startup config: OmniAuth Google (1) | Landing door 2 / `config/initializers/omniauth.rb` | same initializer as app C8 | - |
| locale default (1) | Landing door 1 / `config.i18n.default_locale` | pt-BR C9 | - |
| door 8 no public signup (1) | Landing door 8 | no registration route C40 | - |

Swept existing, re-read in code: unique indexes on `accounts.email`, `accounts.google_uid`, `accesses(account_id, organization_id)`, `invites(organization_id, email)`; `Access#destroy` locks coordinator rows; `Invite#accept!` creates coordinator Access then `destroy!`; Account is not deleted when Access is gone. Observability n/a as approved.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decides, reached across a boundary | `app/models/operator_authenticator.rb` + `app/controllers/omniauth_callbacks_controller.rb`; `app/models/invite.rb` + `app/controllers/coordinator_invites_controller.rb`; `app/models/access.rb` + `app/controllers/accesses_controller.rb`; `app/controllers/focus_controller.rb`; `lib/tasks/coordinator.rake` | boundary contract plus own-layer case per table row | yes |
| Decides, not reached across a boundary | `app/models/account.rb` uid uniqueness; `app/models/access.rb` pair uniqueness and kind enum; `app/models/google_oauth.rb` | own-layer case per member | yes |
| Entry point that decides nothing | `app/controllers/sessions_controller.rb`; `app/controllers/organizations_controller.rb` show | accepted / rejected / error at HTTP | yes |
| Instrumentation, pass-throughs | `OmniauthCallbacksController` status case; `NormalizedEmail` | none of its own | yes |

Callback 6 outcomes are asserted at `GET /auth/google_oauth2/callback`. Persistence tables have own-layer proofs: Invite accept C19, invite create/reject C16 C20, last-coordinator C27 C28, Account email C4. Focus and bootstrap decisions live at the controller/task, proven at that boundary.

## Faults injected

| Mutation | Location | Killed |
| --- | --- | --- |
| `email_verified?` always true | `app/models/operator_authenticator.rb:42` | yes |
| invite create always 302 even when invalid | `app/controllers/coordinator_invites_controller.rb:9` | yes |
| last-coordinator bound `<= 1` shifted to `<= 0` | `app/models/access.rb:12` | yes |
| missing-Access focus returns 302 instead of 404 | `app/controllers/focus_controller.rb:5` | yes |
| skip abort when Account already exists | `lib/tasks/coordinator.rake:11` | yes |

Scratch worktree `/tmp/caa-coord-access-verify-r1` discarded. Real tree porcelain matched the empty baseline after removal.

## Gate

`bin/rspec spec/requests/sessions_spec.rb spec/requests/omniauth_callbacks_spec.rb spec/requests/denied_spec.rb spec/requests/coordinator_invites_spec.rb spec/requests/organizations_spec.rb spec/requests/accesses_spec.rb spec/requests/focus_spec.rb spec/models/account_spec.rb spec/models/invite_spec.rb spec/models/access_spec.rb spec/config/omniauth_spec.rb spec/config/application_spec.rb spec/tasks/coordinator_bootstrap_spec.rb` - 46 passed, 0 failed
