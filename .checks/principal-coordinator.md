# Principal coordinator

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/principal-coordinator.md` marks screens `administration`, `administration/:id/edit`, and `home` binding.

Sources:

- `.tasks/principal-coordinator.md` - criteria 1–32, the state diagram, the sweep, the two doors, and the boundary. Unresolved 1–2 stay open
- `.design/administration-list.md` - **binding for the interface**: screens `administration` (list column, Status, `Editar`), `administration/:id/edit` (`Corrigir` only on the principal email, other coordinators as text, `Remover`), and `home` people (principal first, `Revogar` rules). Opened as a file in the repo. Screen `home` invites and the add form on `administration/new` are unchanged
- https://github.com/gutors/ai-accounting-assistant/issues/66 - principal identity, home revoke rules, list column, edit-only principal, submitter promotion, skip mail when the Account exists. Item 4 (delete Accounts with no Access) is out of this task
- `CONTEXT.md` - term `Principal coordinator`
- `.tasks/administration-access.md` - the move that does not rewrite `Account.email`, the close-data removal guard, last-coordinator `destroy`, welcome on a new Account
- `docs/adr/0007-administration-access.md` - Account rows stay on remove
- `app/models/invite.rb` - `accept!` creates Access and destroys the Invite; it does not write `principal_coordinator_account_id` (C27)
- `app/models/access.rb` - uniqueness on `(account_id, organization_id)` is why a submitter is `update!` `kind`, not a second Access
- `app/controllers/accesses_controller.rb` - other-organization DELETE is already `404`; forbidden coordinator revoke uses that status
- `DESIGN.md` - quiet caixa, quiet margem, notice partial `data-notice="error"`
- Conversation, recorded in the task - non-principal cannot revoke self (C2, C7). Removal keeps Account rows (C29)

## Out of scope

- Rebuilding registration, name correction, invite mail copy, or the welcome subject - those stay as `.tasks/administration-list.md` and `.tasks/administration-access.md` left them (C23, C24)
- Sending no welcome on `register_coordinator` when the Account already exists - #66 item 5 is the principal-email correction, not the sale
- A badge or the words `coordenador principal` on `home` or `/administration` - order and `Email coordenador` are the signal (C1, C13)
- Restricting who may invite a coordinator - any coordinator still can (C1, C2)
- Deleting Account rows on `Remover` - #66 asked to drop Accounts with no Access left. This task keeps ADR-0007: Account rows stay (C29)
- A submitter list on `/administration` (C13, C15)
- Rewriting `Account.email` - still the Google identity
- Changing `Access#destroy` `:last_coordinator` (C11)
- Changing `coordinator:bootstrap` abort when the email already has an Account (C28)
- A second administrator
- Closing issue #63 - a real mailbox is Unresolved 1
- Rate-limiting mail
- Settling Unresolved 2 - overlapping principal-email confirms. Do not add a lock

## Landing

Touches `organizations.principal_coordinator_account_id`, `Organization#listed_coordinator_account`, `Organization#replace_coordinator` (promote submitter, skip welcome when the Account existed), `AccessesController#destroy` (who may revoke a coordinator), the administration list and edit views, home coordinator order and `Revogar`, `register_coordinator`, `coordinator:bootstrap`, and `DevelopmentCoordinatorSeed`. Reuses `Access#destroy` `:last_coordinator`, ADR-0007 removal, `session[:administration_pending]` email confirm, `CoordinatorWelcomeMailer`, and `head :not_found`.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Principal pointer | `organizations.principal_coordinator_account_id` `bigint NOT NULL`, FK to `accounts(id)`, `ON DELETE RESTRICT`. One principal per organization by being a single column. `Invite#accept!` creates a coordinator Access and does not write this column. `register_coordinator`, bootstrap, and the development seed set it to the Account they create | A `principal` boolean on `accesses`. Two coordinator rows could both be true unless a partial unique index existed, and the sale identity would still be inferred from Access rather than from the organization the seller edits. Treating the newly accepted invite as principal, which would let a later invite steal `Email coordenador` |
| Email write | For a different normalized email: in one transaction, grant coordinator Access to that Account (create the Account when missing; if that Account already has submitter Access on this organization, `update!` `kind` to `coordinator`), delete a pending Invite for that email on that organization, point `principal_coordinator_account_id` at that Account, then destroy the old principal Access. Do not update `accounts.email`. Deliver the welcome after commit only when this transaction created the Account | Always sending the welcome. #66 says an email that already exists in the system is not mailed. Leaving the old principal as a peer. The issue is a correction of the sale email, which is the existing move |
| Concurrent sale | `Organization.register_coordinator` looks up the Account by email, creates it, and on `RecordNotUnique` finds it again before inserting the Organization | Letting two concurrent confirms raise on `accounts.email`. The existing concurrent-confirm example needs one organization to remain |
| Removal | Unchanged from ADR-0007: after the close-data guard, delete Accesses (including the last coordinator) and Invites, then the Organization. Account rows stay | Deleting Accounts with no Access left. #66 asked for that; this task keeps ADR-0007 |

- Nothing else in this change is hard to reverse

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at the model or mailer layer **and** one request spec at HTTP | one asserted case per enumerated member at its own layer; status and who may call at the boundary | follow |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` names the level and the sampling rule: a decision is proven at its own layer, one asserted case per enumerated member; HTTP also gets a request spec
- `AccessesController#destroy` gains a revoke guard (principal may revoke a peer coordinator; nobody may revoke their own coordinator Access; a non-principal may not revoke any coordinator). Closest analogue: other-organization DELETE already `404` in `spec/requests/accesses_spec.rb`
- `Organization#listed_coordinator_account` becomes the principal Account, not `accounts.email` first. `listed_coordinator_signed_in?` follows that Account's `google_uid`. Proven on the model; the list requests assert the column and Status
- Home coordinator order is principal first, then remaining emails `accounts.email` ascending. Proven on the model and on `GET /`
- `Organization#replace_coordinator` (or the method that lands the email write) dispatches over invalid/taken-coordinator/promote-submitter/existing-Account/new-Account/same-email/rollback. HTTP confirm/continue cover the contract
- `Invite#accept!` still does not write the FK. `register_coordinator`, bootstrap, and the seed do
- Backfill then `NOT NULL` is the migration. No migration spec exists in this repo; this cut adds one that runs the migration against planted rows
- closest analogue: administration-access email move, proven at the model and at HTTP

Cost: model examples for listed principal, home order, the email-write members including promote and skip-mail, register/bootstrap/seed FK writes, invite-accept leaving the pointer, last-coordinator destroy unchanged, removal keeping Accounts; a migration example for backfill then not-null; request examples for every status and screen claim below.

These rows are the bar I build under — approving the checklist is enough for that. Writing them into `.cursor/rules/rails.mdc` needs an explicit yes, and it lands as its own commit before the build. Without one I build under them and leave the file alone. They already live there, so silence leaves the file alone.

## Checks

Email-correction posts stay as administration-access named them: `POST /administration/email` starts `Corrigir` (`organization_id`, `email`). `POST /administration/email/continue` is `Continuar` (`email`). `POST /administration/email/confirm` confirms (`organization_id`). Removal is `DELETE /administration` (`organization_id`).

### S1 - Home · 7 files · 28 KB · ~7k

`app/controllers/accesses_controller.rb` 419, `app/controllers/application_controller.rb` 5367, `app/views/organizations/show.html.erb` 6085, `app/models/access.rb` 516, `spec/requests/accesses_spec.rb` 5121, `spec/requests/organizations_spec.rb` 8067, `spec/models/access_spec.rb` 2370. 27945 bytes / 4 ≈ 7k.

**C1** - Given `ONG Norte` has principal coordinator `zoe@exemplo.org`, coordinator `ana@exemplo.org`, and submitter `submitter@exemplo.org`, when `zoe@exemplo.org` is signed in on that organization and `GET /` runs, then under `Coordenadores` the emails appear in order `zoe@exemplo.org` then `ana@exemplo.org`. The `zoe@exemplo.org` row has no `Revogar`. The `ana@exemplo.org` row has `Revogar` with `data-turbo-confirm` `Revogar o acesso deste coordenador?`. The submitter row has `Revogar` with `data-turbo-confirm` `Revogar o acesso deste submitter?`. The body includes `Convidar coordenador` and `Convidar submitter`. The body does not include `coordenador principal`. Coordinator Accesses for home are the principal first, then remaining coordinators by `accounts.email` ascending
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "principal coordinator is first and sees Revogar on peer coordinator and submitter rows"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "home coordinator Accesses list the principal first then accounts.email"`

**C2** - Given the same people, when `ana@exemplo.org` is signed in as coordinator on `ONG Norte` and `GET /` runs, then the coordinator emails are still `zoe@exemplo.org` then `ana@exemplo.org`. No coordinator row has `Revogar`. The submitter row still has `Revogar` with `data-turbo-confirm` `Revogar o acesso deste submitter?`. `Convidar coordenador` and `Convidar submitter` are present
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "peer coordinator does not see Revogar on coordinator rows and still revokes submitters"`

**C3** - Given that home as `zoe@exemplo.org`, when `DELETE /accesses/:id` runs for `ana@exemplo.org`'s coordinator Access, then the status is `302` to `/`, that Access is gone, `zoe@exemplo.org` still has coordinator Access, and `principal_coordinator_account_id` is still that Account
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "principal DELETE of a peer coordinator Access redirects"`

**C4** - Given that home as `zoe@exemplo.org`, when `DELETE /accesses/:id` runs for `zoe@exemplo.org`'s coordinator Access, then the status is `404`, the body is empty, that Access remains, and `principal_coordinator_account_id` is unchanged
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "principal DELETE of own coordinator Access returns 404"`

**C5** - Given that home as `ana@exemplo.org`, when `DELETE /accesses/:id` runs for `zoe@exemplo.org`'s coordinator Access, then the status is `404`, the body is empty, and that Access remains
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "peer DELETE of the principal coordinator Access returns 404"`

**C6** - Given `ONG Norte` also has coordinator `bia@exemplo.org` who is not principal, when `ana@exemplo.org` sends `DELETE /accesses/:id` for `bia@exemplo.org`'s coordinator Access, then the status is `404` and that Access remains
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "peer DELETE of another peer coordinator Access returns 404"`

**C7** - Given that home as `ana@exemplo.org`, when `DELETE /accesses/:id` runs for `ana@exemplo.org`'s coordinator Access, then the status is `404`, the body is empty, and that Access remains. `zoe@exemplo.org` remains principal
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "peer DELETE of own coordinator Access returns 404"`

**C8** - Given that home as `ana@exemplo.org`, when `DELETE /accesses/:id` runs for the submitter Access, then the status is `302` to `/` and that Access is gone
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "peer DELETE of a submitter Access redirects"`

**C9** - Given a submitter is signed in on `ONG Norte`, when `GET /` runs, then the `h1` is `Início` and the body does not include `Revogar` or `Convidar coordenador`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home omits Revogar and Convidar coordenador"`

**C10** - Given no signed-in Account, when `DELETE /accesses/:id` runs, then the response is `302` to `/login` and Access rows are unchanged
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "unauthenticated DELETE /accesses/:id redirects to /login"`

**C11** - Always, `Access#destroy` of the last coordinator Access returns false, adds `:last_coordinator`, and leaves the row
Proof: `bin/rspec spec/models/access_spec.rb -e "destroy is rejected when it is the last coordinator Access"`

**C12** - Given two coordinator Accesses on one organization, when each signed-in Account concurrently sends `DELETE /accesses/:id` for its own Access, then both Accesses remain and both statuses are `404`. Neither request calls `Access#destroy`
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "concurrent self-DELETE of two coordinators returns 404 and leaves both Accesses"`

### S2 - Administration list and edit · 8 files · 61 KB · ~15k

`app/controllers/administration_controller.rb` 12691, `app/views/administration/show.html.erb` 1234, `app/views/administration/edit.html.erb` 441, `app/views/administration/_organization_row.html.erb` 772, `app/views/administration/_organization.html.erb` 4608, `app/views/administration/_mail_result.html.erb` 554, `spec/requests/administration_access_spec.rb` 34570, `app/models/organization.rb` 7552. 62422 bytes / 4 ≈ 16k.

**C13** - Given the allowlisted Account is signed in, `ONG Norte`'s principal is `zoe@exemplo.org` with no `google_uid`, `ana@exemplo.org` is a coordinator with `google_uid` set, and a submitter exists, when `GET /administration` runs, then the status is `200`, the `h1` is `Administração`, `Adicionar organização` is a link to `/administration/new` whose class includes `bg-caixa`, the table headers are `Nome`, `Email coordenador`, `Status`, `Editar` in that order, that row's `Email coordenador` cell is `zoe@exemplo.org` and not `ana@exemplo.org`, Status is `Pendente`, `Editar` is a link to `/administration/:id/edit` whose class includes `text-caixa`, `underline`, and `underline-offset-2`, and that row's cells do not include `ana@exemplo.org`, the submitter email, `Corrigir`, or `Remover`. `Organization#listed_coordinator_account` is the principal Account
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "GET /administration lists the principal coordinator email Status and Editar"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "listed_coordinator_account is the principal coordinator"`

**C14** - Given that principal Account has `google_uid` set, when `GET /administration` runs, then Status on that row is `Ativa`. `Organization#listed_coordinator_signed_in?` is true only when that principal Account has `google_uid`
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "GET /administration Status is Ativa when the principal has google_uid"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "listed_coordinator_signed_in? follows the principal google_uid"`

**C15** - Given `GET /administration/:id/edit` for that `ONG Norte`, then the status is `200`, the page includes `zoe@exemplo.org` with `Corrigir` (`text-caixa underline underline-offset-2`), includes `ana@exemplo.org` as text with no `Corrigir` control for that address, includes `Corrigir nome` and `Remover` (`text-margem underline underline-offset-2`) with `data-turbo-confirm` `Remover a organização ONG Norte?`, and does not include the submitter email. There is exactly one `Corrigir` control, and it is the one on `zoe@exemplo.org`
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "GET /administration/:id/edit shows Corrigir only on the principal email"`

**C16** - When `POST /administration/email` names `ana@exemplo.org` on `ONG Norte`, then the status is `404`, Access rows are unchanged, and the response is not the email field for that address
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "POST /administration/email for a non-principal coordinator returns 404"`

**C17** - Given no signed-in Account, when `POST /administration/email`, `POST /administration/email/confirm`, or `DELETE /administration` runs, then the response is `302` to `/login`, and `Organization.count`, `Account.count`, `Access.count`, `Invite.count`, and `ActionMailer::Base.deliveries` are unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "signed-out administration routes redirect to /login"`

**C18** - Given a signed-in Account whose email is not the normalized `ADMINISTRATOR_EMAIL`, when the request is any route in C17, then the status is `404`, the body is empty, and those counts and deliveries are unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "non-administrator and blank allowlist administration routes respond 404"`

### S3 - Principal email write · 10 files · 58 KB · ~15k

`app/models/organization.rb` 7552, `app/models/invite.rb` 1170, `app/controllers/administration_controller.rb` 12691, `spec/models/organization_spec.rb` 24828, `spec/models/invite_spec.rb` 3856, `spec/mailers/coordinator_welcome_mailer_spec.rb` 2511, `lib/tasks/coordinator.rake` 725, `app/models/development_coordinator_seed.rb` 418, `spec/tasks/coordinator_bootstrap_spec.rb` 2919, `spec/models/development_coordinator_seed_spec.rb` 1765. 58435 bytes / 4 ≈ 15k. The confirm request examples live in `spec/requests/administration_access_spec.rb`, already counted in S2.

**C19** - Given the principal email field is open on `ONG Norte`, when `Continuar` submits `nao-e-email`, then the status is `422`, the notice under the `h1` is `Informe um e-mail válido.`, the field keeps `nao-e-email`, and Access rows are unchanged
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "invalid principal email correction re-renders 422"`

**C20** - Given `ana@exemplo.org` already has coordinator Access on `ONG Norte` and is not principal, when `Continuar` on the principal email submits `Ana@Exemplo.ORG`, then the status is `422`, the notice is `Esse e-mail já tem acesso a esta organização.`, the field keeps that value, and Access rows are unchanged
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "taken peer coordinator email correction re-renders 422"`

**C21** - Given `ONG Norte` principal `coordenador@exemplo.org` and submitter `submitter@exemplo.org`, when `Continuar` on the principal email submits ` Submitter@Exemplo.ORG `, then the status is not `422` with `Esse e-mail já tem acesso a esta organização.` When that confirmation is confirmed, then that Account's Access `kind` is `coordinator`, `principal_coordinator_account_id` is that Account, the old principal Access is gone, `Account.count` is unchanged, a pending Invite for `submitter@exemplo.org` on `ONG Norte` is gone, `ActionMailer::Base.deliveries` is empty, and the following `GET /administration` shows `submitter@exemplo.org` as `Email coordenador` with no `E-mail enviado para` and no `A correção foi gravada, mas o e-mail não saiu.` The kind change exists before the old principal Access is destroyed, in one transaction, which is why `Access#destroy` does not refuse a sole remaining coordinator
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "Continuar on a same-org submitter email is not a collision"`
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "confirming a same-org submitter promotes Access and sends no welcome"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "replace_coordinator promotes submitter Access then destroys the old principal"`

**C22** - Given `sul@exemplo.org` already has an Account that coordinates `ONG Sul` and has no Access on `ONG Norte`, when the principal email confirmation to that address is confirmed, then `Account.count` is unchanged, `ONG Norte`'s `principal_coordinator_account_id` is that Account, that Account has coordinator Access there, the old principal Access is gone, and no message is delivered. The following `GET /administration` shows `sul@exemplo.org` as `Email coordenador` and no mail sentence
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "confirming onto an existing Account sends no welcome"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "replace_coordinator reuses an existing Account and does not mail"`

**C23** - Given the principal is `coordenador@exemplo.org`, that Account has no other Access, `novo@exemplo.org` has no Account, and a pending Invite for `novo@exemplo.org` exists on `ONG Norte`, when the principal email confirmation for ` Novo@Exemplo.ORG ` is confirmed and delivery succeeds, then a new Account `novo@exemplo.org` exists, it is principal, the old principal Access is gone, the `ONG Norte` Invite for that email is gone, one `text/plain` welcome is delivered to `novo@exemplo.org` with subject `Fechamento Mensal - Cadastro da Organização ONG Norte` and body `A organização ONG Norte está pronta. Entre com o Google usando novo@exemplo.org, pelo botão Entrar com Google.`, and the row shows `E-mail enviado para novo@exemplo.org.`
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "confirming a new principal email creates the Account and sends the welcome"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "replace_coordinator inserts the new Access then destroys the old and deletes the matching Invite"`

**C24** - Given that new-Account confirmation, when `deliver_now` raises, then the new Access and the new Account remain, the old principal Access is gone, the Invite for the new email on `ONG Norte` is gone, no `accounts.email` is rewritten, and the following `GET` shows `[data-notice="error"]` `A correção foi gravada, mas o e-mail não saiu.` and primary `Reenviar e-mail` on that row. Delivery runs after the transaction commits and the error is rescued
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "email confirm keeps the move when deliver_now raises"`

**C25** - Given `Continuar` on the principal submits ` Coordenador@Exemplo.ORG ` and that is already the principal Account email, when `Confirmar` runs, then Access rows are unchanged, no message is delivered, and the following `GET` shows `coordenador@exemplo.org` with no new mail sentence
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "confirming the current principal email writes nothing and sends nothing"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "replace_coordinator keeps the Access when the email is unchanged"`

**C26** - If the principal email write raises before its transaction commits, then `principal_coordinator_account_id` and Access rows are unchanged, a pending Invite for the new email on that organization remains, and no message is delivered. The new coordinator Access, the Invite delete, the old principal destroy, and the FK write share one transaction, and mail runs only after commit
Proof: `bin/rspec spec/models/organization_spec.rb -e "replace_coordinator rolls back when the write raises before commit"`

**C27** - When `Organization.register_coordinator` writes `ONG Norte` / `coordenador@exemplo.org`, then `principal_coordinator_account_id` is that Account. Given that organization then has a pending coordinator Invite for `ana@exemplo.org`, when `Invite#accept!` runs for that Invite, then a coordinator Access exists for `ana@exemplo.org`, the Invite is gone, and `principal_coordinator_account_id` is still the Account for `coordenador@exemplo.org`. The list column and the first `home` coordinator row stay `coordenador@exemplo.org`. `ana@exemplo.org` is a peer coordinator, not the principal
Proof: `bin/rspec spec/models/organization_spec.rb -e "register_coordinator sets principal_coordinator_account_id"`
Proof: `bin/rspec spec/models/invite_spec.rb -e "accept creates coordinator Access and does not write principal_coordinator_account_id"`
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "after invite accept the list column stays the principal email"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "after invite accept the first home coordinator row stays the principal"`

**C28** - When `coordinator:bootstrap` or `DevelopmentCoordinatorSeed.plant!` writes its Organization, Account, and coordinator Access, then `principal_coordinator_account_id` is that Account. The command still aborts when the email already has an Account
Proof: `bin/rspec spec/tasks/coordinator_bootstrap_spec.rb -e "bootstrap persists Organization Account and coordinator Access"`
Proof: `bin/rspec spec/tasks/coordinator_bootstrap_spec.rb -e "bootstrap rejects an email that already has an Account"`
Proof: `bin/rspec spec/models/development_coordinator_seed_spec.rb -e "plants ONG Exemplo and gutors@gmail.com with nil google_uid"`

### S4 - Removal · 5 files · 80 KB · ~20k

`app/models/organization.rb` 7552, `app/controllers/administration_controller.rb` 12691, `spec/requests/administration_access_spec.rb` 34570, `spec/models/organization_spec.rb` 24828, `db/schema.rb` 11162. 90803 bytes / 4 ≈ 23k. The migration file does not exist yet; its bytes are not in this floor.

**C29** - Given `ONG Norte` has a principal coordinator whose Account has no other Access, another coordinator who also coordinates `ONG Sul`, a submitter whose Account has no other Access, one pending Invite, `accountant_presentation_name` set, and no BankAccount, Month, SupportingDocument, Justification, or ExtraExceptionKind, when removal is confirmed, then the response is `302` to `/administration`, `ONG Norte` is gone, its Accesses and Invites are gone, both Accounts that only stood on `ONG Norte` remain, the extra coordinator Account remains with Access on `ONG Sul`, and the following `GET` does not include `ONG Norte`. The last-coordinator refusal does not veto this delete. Account rows stay, as ADR-0007
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "removing an organization keeps Account rows including a coordinator who still accesses another organization"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "remove deletes Accesses and Invites including the last coordinator"`

**C30** - Given `ONG Norte` has a BankAccount and none of the other four close-data rows, when removal is confirmed, then the status is `422`, `[data-notice="error"]` is `Esta organização já tem dados de fechamento e não pode ser removida.`, and Organization, Access, Invite, Account, and BankAccount counts for it are unchanged. The check runs before any delete
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "removing an organization with a BankAccount re-renders 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "remove refuses when a BankAccount exists"`

**C31** - When removal is confirmed for an organization id that does not exist, then the response is `404` and every other Organization and Account remains
Proof: `bin/rspec spec/requests/administration_access_spec.rb -e "removing a missing organization responds 404"`

**C32** - Given an existing organization whose coordinator Accesses were planted without a stored principal, when the migration runs, then `principal_coordinator_account_id` is the Account of the coordinator Access with the earliest `created_at`, ties broken by earliest `id`. After that, the column is not null
Proof: `bin/rspec spec/migrations/add_principal_coordinator_account_id_to_organizations_spec.rb -e "backfill sets principal to earliest coordinator Access then the column is not null"`

## Screens (ui)

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| administration, list | `h1` `Administração`; `Adicionar organização`; headers `Nome`, `Email coordenador`, `Status`, `Editar`; principal email; `Pendente` / `Ativa`; `Editar`; no peer email, no submitter, no `Corrigir`, no `Remover` C13, C14 | title and `Adicionar organização` (`bg-caixa`) on one row; four headers in that order; each data row is name, principal email, Status, `Editar` (`text-caixa underline underline-offset-2`); a mail sentence, when present, sits under those four columns C13, C23, C24 | spacing, colour, type weight |
| administration/:id/edit, rest | principal email with `Corrigir`; other coordinator email as text; `Corrigir nome`; `Remover`; no submitter email C15 | exactly one `Corrigir`, on the principal address (`text-caixa underline underline-offset-2`); `Remover` is `text-margem underline underline-offset-2` with `data-turbo-confirm` `Remover a organização ONG Norte?` C15 | spacing, colour, type weight |
| administration/:id/edit, email invalid | notices C19, C20; typed value stays; Access rows unchanged | the `[data-notice="error"]` sits under the `h1` C19 | spacing, colour, type weight |
| administration, after principal write | principal email on the list; no mail sentence when the Account existed C21, C22; `E-mail enviado para {email}.` when this write created the Account C23; `[data-notice="error"]` `A correção foi gravada, mas o e-mail não saiu.` and primary `Reenviar e-mail` when `deliver_now` raises C24 | the mail result is on that organization's row, under the four columns C23, C24 | spacing, colour, type weight |
| administration/:id/edit, removal blocked | `[data-notice="error"]` `Esta organização já tem dados de fechamento e não pode ser removida.` C30 | the notice is on the edit screen for that organization C30 | spacing, colour, type weight |
| home people, principal signed in | `Coordenadores` emails principal then peer; `Revogar` only on the peer coordinator and on the submitter; `Convidar coordenador`; `Convidar submitter`; no `coordenador principal` C1 | principal first; remaining coordinators by `accounts.email`; no `Revogar` on the signed-in person's own coordinator row; coordinator `Revogar` confirm `Revogar o acesso deste coordenador?`; submitter confirm `Revogar o acesso deste submitter?` C1 | spacing, colour, type weight |
| home people, peer signed in | same email order; no `Revogar` on coordinator rows; submitter `Revogar` stays; both invite legends C2 | peer cannot revoke coordinators, including self C2 | spacing, colour, type weight |
| home, submitter | `h1` `Início`; no `Revogar`; no `Convidar coordenador` C9 | submitter home, not the `Meses` column C9 | spacing, colour, type weight |

## Swept

- validation: C19, C20. A same-org submitter is not a Continuar collision (C21)
- failure modes: C24, C26, C30 - a mail failure keeps the write; a write that raises before commit leaves the old principal; close data deletes nothing
- idempotency and retry: C25 - confirming the current principal email writes nothing and sends nothing. Resend of a new-Account failure stays the existing `/administration/mail` path (C24)
- authorization: C4, C5, C6, C7, C9, C10, C16, C17, C18
- concurrency and ordering: C12 - overlapping self-DELETE leaves both coordinator Accesses. Overlapping principal-email confirms are Unresolved 2
- data lifecycle: C29, C32 - removal still leaves Account rows (ADR-0007); existing organizations get a principal before the column is not null
- external-dependency failure: C24 - SMTP `deliver_now` raises only on the path that sends; C21 and C22 send nothing so a down mailbox does not fail them
- state transitions: States in `.tasks/principal-coordinator.md`
- observability: n/a - no log, metric, or trace was decided. The notices in C19, C20, C24, C30 are the signal

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| designed screens (3) | `administration` C13 · `administration/:id/edit` C15 · `home` people C1 | `home` invites — unchanged, named in Out of scope |
| coordinator DELETE callers (6) | principal→peer `302` C3 · principal→self `404` C4 · peer→principal `404` C5 · peer→peer `404` C6 · peer→self `404` C7 · peer→submitter `302` C8 | - |
| signed-out and non-admin administration writes (2 callers × 3 routes) | signed out C17 · non-administrator C18, each over `POST /administration/email`, `POST /administration/email/confirm`, `DELETE /administration` | - |
| list Status (2) | `Pendente` without `google_uid` C13 · `Ativa` with `google_uid` C14 | - |
| principal-email Continuar (3) | invalid C19 · peer coordinator C20 · same-org submitter allowed C21 | - |
| principal-email writes (6) | promote submitter, no mail C21 · existing Account, no mail C22 · new Account, welcome C23 · `deliver_now` raises C24 · same email, no write C25 · rollback before commit C26 | overlapping confirms — Unresolved 2 |
| principal pointer writers (4) | `register_coordinator` C27 · `Invite#accept!` does not write C27 · `coordinator:bootstrap` C28 · `DevelopmentCoordinatorSeed.plant!` C28 | - |
| last-coordinator destroy (1) | returns false, `:last_coordinator`, row remains C11 | - |
| concurrent self-DELETE (1) | both `404`, both Accesses remain, `destroy` not called C12 | - |
| removal (3) | no close data, Accounts remain C29 · BankAccount blocks C30 · missing id `404` C31 | Month, SupportingDocument, Justification, ExtraExceptionKind — already proven in `.checks/administration-access.md`; this cut names BankAccount as the close-data member |
| backfill (2) | earliest `created_at` then `id` C32 · column not null C32 | - |
| startup: `principal_coordinator_account_id` NOT NULL | one shared `db/schema.rb` assembly C32 | - |

- Claims naming a status code, route, or response shape: C1–C10, C12–C25, C27 (request), C29–C31 - each has a proof that crosses the boundary
- No other check claims more than the single case its proof exercises. C11 and C26 and C32 sit at their own layer because that is where the claim lives

## Handoff

S1 ~7k + S2 ~16k + S3 ~15k + S4 ~23k = ~61k token floor, counting shared files again. Read once, `AdministrationController`, the administration views, `administration_access_spec.rb`, `Organization`, home, and `AccessesController` are under 40k. The design was opened during extract (~5k). All four slices stay under 150k. S1 is the home/accesses surface; S2–S4 share administration. They still fit. No split. One batch.
