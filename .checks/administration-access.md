# Administration access

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/administration-access.md` marks screens `administration` and `home` binding.

Sources:

- `.tasks/administration-access.md` - criteria 1–52, the state diagram, the sweep, the two doors, and the boundary. Stage 2 of 2. Unresolved 1–3 stay open
- `.design/administration-list.md` - **binding for the interface**: screen `administration` (email correction, removal) and screen `home` (invites). Opened as a file in the repo
- https://github.com/gutors/ai-accounting-assistant/issues/63 - the email write, the removal guard, the invite words. This cut cites `#63` and leaves it open
- `.tasks/administration-list.md` - stage 1, already the list, the registration result, the welcome subject, and `Corrigir nome`
- `app/models/access.rb` - `destroy` returns false for the last coordinator. C13 inserts the new Access first. C28 must not use that refusal as a veto
- `app/mailers/coordinator_welcome_mailer.rb` - the subject and the two bodies are stage 1. This stage chooses the recipient
- `app/controllers/administration_controller.rb` - `Organization.find` on mail raises if the row is gone; C39 replaces that
- `app/views/organizations/show.html.erb` - `Revogar` uses `turbo_confirm`. Pending invites render `Cancelar` and no resend
- `DESIGN.md` - quiet caixa, quiet margem, and the notice partial `data-notice="error"`
- `docs/adr/0006-administration-intake.md` - `administrator?` is one normalized env email

## Out of scope

- Rebuilding the list, the registration flow, the welcome subject, or `Corrigir nome` - those are `.tasks/administration-list.md`. This stage keeps them working (C19, C20, C25)
- The buyer form
- Changing `coordinator:bootstrap` or `db/seeds.rb`
- A second administrator - `administrator?` stays the one normalized `ADMINISTRATOR_EMAIL`
- A submitter list on `/administration`
- Accountant, package archive, and certificate screens - they stay on `/setup`. Their columns do not block removal (C28)
- The header, the months list, the people lists, and the invite form fields - the home changes on the pending-invite row and on a failed invite send
- Choosing the mailbox, or adding a provider gem - delivery stays `MailerEnvironment` and `MAIL_FROM`
- Closing issue #63 - the code pull request cites `#63` and leaves it open. A real welcome is Unresolved 1
- Rewriting a month folder
- Rate-limiting mail, and a success sentence for an invite
- Settling Unresolved 2 or 3

## Landing

Touches `AdministrationController`, the administration row, `Organization` (email move and removal), `CoordinatorWelcomeMailer`'s recipient, invite create/resend, and the pending-invite row on the home. Reuses `session[:administration_result]`, the notice partial, `MailerEnvironment`, `Invite.create_pending`, `Access#destroy`'s last-coordinator refusal (unchanged), and `focused_organization`.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Email move | For a different normalized email: in one transaction, insert the coordinator Access for that Account (create the Account when missing), delete a pending Invite for that email on that organization, then destroy the old Access. Do not update `accounts.email`. Deliver the welcome after commit | Rewriting `Account.email`. That column is the Google identity `OperatorAuthenticator` looks up; the old address would stop being that Account |
| Removal | No archive column. Delete Accesses (including the last coordinator) and Invites, then the Organization, only when `bank_accounts`, `months`, `supporting_documents`, `justifications`, and `extra_exception_kinds` are all empty. Account rows stay. Accountant, package archive, and certificate columns are on `organizations` and go with the row | An `archived_at` flag. A removed organization would stay readable, which the issue refuses |

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
- `spec/requests/administration_spec.rb` already proves the list and name posts at HTTP. This cut extends that file for email correction, removal, and the two mail-result notices
- `spec/models/organization_spec.rb` already proves `register_coordinator`. The email move and the removal guard are new branches on that model
- `spec/mailers/coordinator_welcome_mailer_spec.rb` already proves the two welcome bodies. This cut passes the recipient Account instead of `accesses.coordinator.first`
- `spec/models/invite_spec.rb` and the invite request specs already prove create/cancel. This cut adds delivery after persist and a resend post
- closest analogue: stage 1 name correction, same session-draft then confirm, proven at HTTP with the unique-index collision at the model

Cost: a model example for the email-move write (new Account, existing Account, same email, Invite delete, rollback) and for removal (empty close data, each of the five close-data members, last coordinator does not veto); mailer examples for the welcome recipient and the two invite bodies; request examples for every status and screen claim below.

## Checks

Email-correction posts, which the task left unnamed: `POST /administration/email` starts `Corrigir` (`organization_id`, `email`). `POST /administration/email/continue` is `Continuar` (`email`). `POST /administration/email/cancel` is `Cancelar`. `POST /administration/email/confirm` confirms (`organization_id`). `Corrigir` on that confirmation is `GET /administration`. Removal is `DELETE /administration` (`organization_id`). Invite resend is `POST /coordinator_invites/:id/mail` and `POST /submitter_invites/:id/mail`.

### S1 - Email controls · 4 files · 52 KB · ~13k

**C1** - Given the list from `.tasks/administration-list.md` is showing `ONG Norte` with coordinators `ana@exemplo.org` and `zoe@exemplo.org` and a submitter `submitter@exemplo.org`, when `GET /administration` runs, then each email has `Corrigir` (`text-caixa underline underline-offset-2`) and the organization has `Remover` (`text-margem underline underline-offset-2`). `Corrigir nome` is still there. The body does not include `submitter@exemplo.org`. Those actions sit in a `flex-wrap` group inside the `max-w-[28rem]` column. Emails stay ordered by `accounts.email` ascending
Proof: `bin/rspec spec/requests/administration_spec.rb -e "GET /administration shows Corrigir on each coordinator email and Remover"`

**C2** - Given no signed-in Account, when the request starts or confirms an email correction or removes an organization, then the response is `302` to `/login`, and `Organization.count`, `Account.count`, `Access.count`, `Invite.count`, and `ActionMailer::Base.deliveries` are unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "signed-out administration routes redirect to /login"`

**C3** - Given a signed-in Account whose email is not the normalized `ADMINISTRATOR_EMAIL`, when the request is any route in C2, then the status is `404`, the body is empty, and the counts and deliveries in C2 are unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "non-administrator and blank allowlist administration routes respond 404"`

### S2 - Email correction · 8 files · 84 KB · ~21k

**C4** - Given `ONG Norte` has coordinators `ana@exemplo.org` and `zoe@exemplo.org`, when `Corrigir` is used on `zoe@exemplo.org`, then that address is in one field, the name and `ana@exemplo.org` with its `Corrigir` stay, `Continuar` is `bg-caixa`, `Cancelar` is `text-caixa underline underline-offset-2`, nothing is written, and no message is delivered
Proof: `bin/rspec spec/requests/administration_spec.rb -e "Corrigir opens the coordinator email"`

**C5** - Given that field is open with a typed value `novo@exemplo.org`, when `Cancelar` is used, then the row is at rest with `zoe@exemplo.org`, Access and Account rows are unchanged, and no message is delivered
Proof: `bin/rspec spec/requests/administration_spec.rb -e "Cancelar on the email field restores the row"`

**C6** - Given the email field is open, when `Continuar` submits `nao-e-email`, then the status is `422`, the notice under the `h1` is `Informe um e-mail válido.`, the field keeps `nao-e-email`, the row does not become a confirmation, and Access rows are unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "invalid email correction re-renders 422"`

**C7** - Given `ana@exemplo.org` already has coordinator Access on `ONG Norte`, when `Continuar` on `zoe@exemplo.org` submits `Ana@Exemplo.ORG`, then the status is `422`, the notice is `Esse e-mail já tem acesso a esta organização.`, the field keeps that value, and Access rows are unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "taken coordinator email correction re-renders 422"`

**C8** - Given `submitter@exemplo.org` has submitter Access on `ONG Norte`, when `Continuar` on the coordinator email submits that address, then the status is `422`, the notice is `Esse e-mail já tem acesso a esta organização.`, and Access rows are unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "taken submitter email correction re-renders 422"`

**C9** - Given the coordinator being corrected is `coordenador@exemplo.org`, when `Continuar` submits ` Coordenador@Exemplo.ORG `, then the status is `200`, the row shows the stored name and `coordenador@exemplo.org`, the access notice is absent, and nothing is written. Until Unresolved 2 is answered, the access being corrected does not count as a collision with itself
Proof: `bin/rspec spec/requests/administration_spec.rb -e "the same coordinator email asks for confirmation"`

**C10** - Given that confirmation, when `Confirmar` runs and delivery succeeds, then `Access.count` for that organization is unchanged, that Account's `email` is still `coordenador@exemplo.org`, one `text/plain` welcome is delivered to `coordenador@exemplo.org` with subject `Fechamento Mensal - Cadastro da Organização ONG Norte` and body `A organização ONG Norte está pronta. Entre com o Google usando coordenador@exemplo.org, pelo botão Entrar com Google.`, and the row shows `E-mail enviado para coordenador@exemplo.org.` The existing Access stays because `(account_id, organization_id)` is unique, so a second Access is not inserted. Until Unresolved 2 is answered, this is the write
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirming the same coordinator email sends the welcome and writes no Access"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "replace_coordinator keeps the Access when the email is unchanged"`

**C11** - Given `Continuar` on `zoe@exemplo.org` submitted ` Novo@Exemplo.ORG ` and `ana@exemplo.org` is the other coordinator, when the confirmation is shown, then the status is `200`, it shows the stored name `ONG Norte` and `novo@exemplo.org`, `Confirmar` and `Corrigir`, it does not show `ana@exemplo.org`, and nothing is written
Proof: `bin/rspec spec/requests/administration_spec.rb -e "a new coordinator email asks for confirmation"`

**C12** - Given that confirmation, when `Corrigir` is used, then the field shows `novo@exemplo.org`, nothing is written, and no message is delivered
Proof: `bin/rspec spec/requests/administration_spec.rb -e "Corrigir on the email confirmation returns the typed email"`

**C13** - Given `ONG Norte` has exactly one coordinator, `coordenador@exemplo.org`, that email's Account has no other Access, `novo@exemplo.org` has no Account, and a pending Invite for `novo@exemplo.org` exists on `ONG Norte` and another on `ONG Sul`, when the email confirmation for ` Novo@Exemplo.ORG ` is confirmed and delivery succeeds, then a new Account `novo@exemplo.org` exists, the old Account's `email` is still `coordenador@exemplo.org`, `ONG Norte` has exactly one coordinator Access and it belongs to `novo@exemplo.org`, the `ONG Norte` Invite for `novo@exemplo.org` is gone, the `ONG Sul` Invite remains, and one `text/plain` message is delivered to `novo@exemplo.org` with subject `Fechamento Mensal - Cadastro da Organização ONG Norte` and body `A organização ONG Norte está pronta. Entre com o Google usando novo@exemplo.org, pelo botão Entrar com Google.` No message contains `Você foi convidado`. The row shows `E-mail enviado para novo@exemplo.org.` The new Access is inserted before the old one is destroyed, in one transaction, which is why `Access#destroy` does not refuse this sole coordinator. Mail runs after that transaction commits
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirming a new coordinator email moves Access and sends the welcome"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "replace_coordinator inserts the new Access then destroys the old and deletes the matching Invite"`

**C14** - Given `sul@exemplo.org` already has an Account that coordinates `ONG Sul`, and `ONG Norte` has exactly one coordinator `coordenador@exemplo.org`, when the move to `sul@exemplo.org` delivers, then `Account.count` is unchanged, the old Account's `email` is still `coordenador@exemplo.org`, `ONG Norte`'s coordinator Access belongs to that Account, and the delivered body is `A organização ONG Norte foi adicionada à sua conta. Entre com o Google usando sul@exemplo.org, pelo botão Entrar com Google.`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "moving Access onto an existing coordinator Account keeps Account.count"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "replace_coordinator reuses an existing Account"`

**C15** - Given `ana@exemplo.org` was created before `zoe@exemplo.org` on `ONG Norte`, when `zoe@exemplo.org` is moved to `novo@exemplo.org` and delivery succeeds, then `ana@exemplo.org` still has coordinator Access, `zoe@exemplo.org` does not, and the delivered message's `to` is `novo@exemplo.org`, not `ana@exemplo.org`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "the welcome after an email move addresses the new email"`
Proof: `bin/rspec spec/mailers/coordinator_welcome_mailer_spec.rb -e "welcome mail addresses the given Account"`

**C16** - Given the move in C13, when `deliver_now` raises, then the new Access and the new Account remain, the old Access is gone, the old Account's `email` is unchanged, the `ONG Norte` Invite for the new email is gone, and the following `GET` shows `[data-notice="error"]` `A correção foi gravada, mas o e-mail não saiu.` and primary `Reenviar e-mail` on that row, and does not include `E-mail enviado para`. The correction remains because delivery runs after the transaction commits and the delivery error is rescued
Proof: `bin/rspec spec/requests/administration_spec.rb -e "email confirm keeps the move when deliver_now raises"`

**C17** - Given that correction failure, and `ana@exemplo.org` is the other coordinator, when `POST /administration/mail` runs and delivery succeeds, then one more welcome is delivered to `novo@exemplo.org` and not to `ana@exemplo.org`, with subject `Fechamento Mensal - Cadastro da Organização ONG Norte`, and the following `GET` shows `E-mail enviado para novo@exemplo.org.` and no `Reenviar e-mail`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "correction resend delivers to the new email"`

**C18** - Given that correction failure, when `POST /administration/mail` runs and `deliver_now` raises, then Access rows are unchanged and the following `GET` still shows `A correção foi gravada, mas o e-mail não saiu.`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "correction resend keeps the correction notice when deliver_now raises"`

**C19** - Given a row is showing `O cadastro foi gravado, mas o e-mail não saiu.` from a registration, when `POST /administration/mail` runs and delivery succeeds, then the row shows `E-mail enviado para` that coordinator and does not show `A correção foi gravada, mas o e-mail não saiu.`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "resend delivers another welcome message"`

**C20** - Given that registration failure, when `POST /administration/mail` runs and `deliver_now` raises, then the row still shows `O cadastro foi gravado, mas o e-mail não saiu.` and does not show `A correção foi gravada, mas o e-mail não saiu.`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "resend keeps mail_sent false when deliver_now raises"`

**C21** - Given the signed-in Account is the administrator and the new email is that administrator's email, when the email confirmation delivers, then `session[:organization_id]` is that Organization id
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm of the signed-in email on a correction focuses the organization"`

**C22** - Given the new email is not the signed-in administrator, when the email confirmation delivers, then `session[:organization_id]` is unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm of another email on a correction leaves the focused organization"`

**C23** - When an email confirmation is submitted for an organization id that does not exist, then the response is `404`, no Access is written, and no message is delivered
Proof: `bin/rspec spec/requests/administration_spec.rb -e "email confirmation for a missing organization responds 404"`

**C24** - If the email move raises before its transaction commits, then `Access.count` is unchanged, the old Access remains, no new Access exists, a pending Invite for the new email on that organization remains, and no message is delivered. The new Access, the Invite delete, and the old Access destroy share one transaction, and mail runs only after commit
Proof: `bin/rspec spec/models/organization_spec.rb -e "replace_coordinator rolls back when the write raises before commit"`

### S3 - One unwritten flow · 2 files · 53 KB · ~13k

**C25** - Given the name confirmation `Nenhum e-mail será enviado.` is unwritten, when `Corrigir` starts on a coordinator email, then the stored name is unchanged, the email field is open with that address, and `Nenhum e-mail será enviado.` is absent
Proof: `bin/rspec spec/requests/administration_spec.rb -e "Corrigir on an email discards an unwritten name confirmation"`

**C26** - Given an email confirmation for `novo@exemplo.org` is unwritten, when `Corrigir nome` starts or `POST /administration` submits a valid registration, then Access rows are unchanged, the email confirmation is gone, and no welcome is delivered
Proof: `bin/rspec spec/requests/administration_spec.rb -e "Corrigir nome discards an unwritten email confirmation"`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "a valid registration discards an unwritten email confirmation"`

### S4 - Removal · 5 files · 79 KB · ~20k

**C27** - Given the row `ONG Norte`, the `Remover` control carries `data-turbo-confirm` `Remover a organização ONG Norte?`, the same `turbo_confirm` mechanism as `Revogar`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "GET /administration shows Corrigir on each coordinator email and Remover"`

**C28** - Given `ONG Norte` has one coordinator Access, one submitter Access, one pending Invite, `accountant_presentation_name` set, `package_archive_folder_id` set, and `sefaz_pkcs12_ciphertext` set, and it has no BankAccount, Month, SupportingDocument, Justification, or ExtraExceptionKind, when removal is confirmed, then the response is `302` to `/administration`, that Organization is gone, its Accesses and Invite are gone, both Accounts remain, and the following `GET` does not include `ONG Norte`. The last-coordinator refusal does not veto this delete
Proof: `bin/rspec spec/requests/administration_spec.rb -e "removing an organization with no close data deletes it"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "remove deletes Accesses and Invites including the last coordinator"`

**C29** - Given that removed organization was `session[:organization_id]` and the administrator's only Access, when the following `GET /administration` runs, then the status is `200`, `session[:organization_id]` is still that id, and the header text is `Fechamento mensal`, because `focused_organization` resolves only an organization the Account still has an Access to
Proof: `bin/rspec spec/requests/administration_spec.rb -e "GET /administration after removing the focused organization keeps the session id"`

**C30** - Given the administrator is focused on `ONG Sul` and removes `ONG Norte`, which they do not coordinate, then `session[:organization_id]` stays `ONG Sul` and the header still shows `ONG Sul`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "removing another organization leaves the focused organization"`

**C31** - Given another organization still has exactly one coordinator, when `DELETE /accesses/:id` runs for that Access, then the response is `422` and the Access remains, because `Access#destroy` adds `:last_coordinator` and returns false. Removal in C28 does not go through that refusal
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "DELETE last coordinator Access returns 422"`
Proof: `bin/rspec spec/models/access_spec.rb -e "destroy is rejected when it is the last coordinator Access"`

**C32** - Given `ONG Norte` has a BankAccount and no Month, SupportingDocument, Justification, or ExtraExceptionKind, when removal is confirmed, then the status is `422`, `[data-notice="error"]` on that row is `Esta organização já tem dados de fechamento e não pode ser removida.`, and Organization, Access, Invite, and BankAccount counts for it are unchanged. The check runs before any delete
Proof: `bin/rspec spec/requests/administration_spec.rb -e "removing an organization with a BankAccount re-renders 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "remove refuses when a BankAccount exists"`

**C33** - Given `ONG Norte` has a Month and none of the other four close-data rows, when removal is confirmed, then the status is `422`, the same notice is on that row, and nothing is deleted
Proof: `bin/rspec spec/requests/administration_spec.rb -e "removing an organization with a Month re-renders 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "remove refuses when a Month exists"`

**C34** - Given `ONG Norte` has a SupportingDocument and none of the other four, when removal is confirmed, then the status is `422`, the same notice is on that row, and nothing is deleted
Proof: `bin/rspec spec/requests/administration_spec.rb -e "removing an organization with a SupportingDocument re-renders 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "remove refuses when a SupportingDocument exists"`

**C35** - Given `ONG Norte` has a Justification and none of the other four, when removal is confirmed, then the status is `422`, the same notice is on that row, and nothing is deleted
Proof: `bin/rspec spec/requests/administration_spec.rb -e "removing an organization with a Justification re-renders 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "remove refuses when a Justification exists"`

**C36** - Given `ONG Norte` has an ExtraExceptionKind and none of the other four, when removal is confirmed, then the status is `422`, the same notice is on that row, and nothing is deleted
Proof: `bin/rspec spec/requests/administration_spec.rb -e "removing an organization with an ExtraExceptionKind re-renders 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "remove refuses when an ExtraExceptionKind exists"`

**C37** - When removal is confirmed for an organization id that does not exist, then the response is `404` and every other Organization remains
Proof: `bin/rspec spec/requests/administration_spec.rb -e "removing a missing organization responds 404"`

**C38** - Given the registration result names `ONG Norte` and that organization is then removed, when `GET /administration` runs, then the status is `200`, the form is shown, and the body does not include a mail sentence or the failure notice for `ONG Norte`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "GET /administration after removing the result organization shows the empty form"`

**C39** - Given the registration result names an organization id that does not exist, when `POST /administration/mail` runs, then the response is `302` to `/administration`, no message is delivered, and no Organization, Account, or Access is written
Proof: `bin/rspec spec/requests/administration_spec.rb -e "resend for a missing result organization redirects and delivers nothing"`

### S5 - Invite mail · 8 files · 26 KB · ~7k

**C40** - Given a coordinator is signed in on `ONG Norte`, when `POST /coordinator_invites` submits ` Pessoa@Exemplo.ORG ` and delivery succeeds, then the response is `302` to `/`, one pending coordinator Invite exists for `pessoa@exemplo.org`, and one `text/plain` message is delivered to that address from `venda@example.com` when `MAIL_FROM` is `venda@example.com`, with subject `Fechamento Mensal - Convite para ONG Norte` and body `Você foi convidado a fechar o mês da organização ONG Norte. Entre com o Google usando pessoa@exemplo.org, pelo botão Entrar com Google.` The following `GET /` has no success sentence and no `[data-notice="error"]`. On that invite, `Reenviar e-mail` (`text-caixa underline underline-offset-2`) appears immediately before `Cancelar` (`text-margem underline underline-offset-2`)
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites delivers the coordinator invite"`
Proof: `bin/rspec spec/mailers/invite_mailer_spec.rb -e "coordinator invite mail"`

**C41** - Given the same home, when `POST /submitter_invites` submits `docs@exemplo.org` and delivery succeeds, then one pending submitter Invite exists and the delivered body is `Você foi convidado a enviar documentos da organização ONG Norte. Entre com o Google usando docs@exemplo.org, pelo botão Entrar com Google.` The subject is `Fechamento Mensal - Convite para ONG Norte`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "POST /submitter_invites delivers the submitter invite"`
Proof: `bin/rspec spec/mailers/invite_mailer_spec.rb -e "submitter invite mail"`

**C42** - Given `POST /coordinator_invites` persists the Invite and `deliver_now` raises, then the Invite remains, and the following `GET /` shows `[data-notice="error"]` `O convite foi gravado, mas o e-mail não saiu.` after the `h1` `Meses` and before the months content. The Invite remains because delivery runs after the Invite commit and the delivery error is rescued
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites keeps the Invite when deliver_now raises"`

**C43** - Given a pending Invite that this request did not just create, when `GET /` runs, then `ActionMailer::Base.deliveries` is unchanged
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "GET / does not deliver mail for an already pending Invite"`

**C44** - Given the notice from C42 is showing and another pending Invite exists, when `Reenviar e-mail` on that other Invite delivers, then one more message of that Invite's kind is delivered, both Invites remain, the following `GET` does not include `O convite foi gravado, mas o e-mail não saiu.`, and it includes no success sentence
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "resend on another Invite clears the failure notice"`

**C45** - Given a pending Invite, when `Reenviar e-mail` runs and `deliver_now` raises, then the Invite remains and the following `GET` shows `O convite foi gravado, mas o e-mail não saiu.`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "invite resend keeps the Invite when deliver_now raises"`

**C46** - Given the notice from C42 is showing, when `Cancelar` deletes that Invite, then the Invite is gone, no message is delivered, and the following `GET` still shows `O convite foi gravado, mas o e-mail não saiu.`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "Cancelar does not clear the invite failure notice"`

**C47** - Given no failure notice is stored, when `Cancelar` deletes a pending Invite, then the Invite is gone, no message is delivered, and the following `GET` does not include `O convite foi gravado, mas o e-mail não saiu.`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "Cancelar without a failure notice delivers nothing"`

**C48** - Given a coordinator is signed in, when `POST /coordinator_invites` or `POST /submitter_invites` submits an email that already has Access on that organization, an email that already has a pending Invite there, or `nao-e-email`, then the status is `422`, no new Invite is persisted, and no message is delivered
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "rejected invite emails return 422"`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "rejected submitter invite emails return 422"`

**C49** - When resend is requested for an Invite that is not on the focused organization, then the response is `404`, that Invite remains, and no message is delivered
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "resend of another organization Invite returns 404"`

**C50** - Given no signed-in Account, when `POST /coordinator_invites`, `POST /submitter_invites`, or an invite resend runs, then the response is `302` to `/login`, no Invite is written, and no message is delivered
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "unauthenticated POST /coordinator_invites responds 302 to /login"`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "unauthenticated POST /submitter_invites responds 302 to /login"`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "unauthenticated invite resend responds 302 to /login"`

**C51** - Given the signed-in Account is a submitter on the focused organization, when `GET /` runs, then the `h1` is `Início` and the body does not include `Reenviar e-mail` or `O convite foi gravado, mas o e-mail não saiu.`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home omits invite resend"`

**C52** - Given the notice from C42 is showing, when a later `POST /coordinator_invites` for a new email delivers, then both Invites remain and the following `GET` does not include that notice
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "a later invite send clears the failure notice"`

## Screens (ui)

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| administration, rest with coordinators | `Corrigir nome`; each coordinator email with `Corrigir`; `Remover`; no submitter email C1 | column `div.max-w-[28rem]`; the row is `flex-wrap`; name, then `Corrigir nome` (`text-caixa underline underline-offset-2`), then `ana@exemplo.org`, then `Corrigir`, then `zoe@exemplo.org`, then `Corrigir`, then `Remover` (`text-margem underline underline-offset-2`) C1 | spacing, colour, type weight |
| administration, email field | stored name; other email with its `Corrigir`; the corrected address in one field; `Continuar`; `Cancelar` C4 | `Continuar` (`bg-caixa`) then `Cancelar` (`text-caixa underline underline-offset-2`) in a `flex-wrap` group; the other email stays as text plus `Corrigir` C4 | spacing, colour, type weight |
| administration, email invalid | notices C6, C7, C8; typed value stays; the row is not a confirmation | the only `[data-notice="error"]` sits under the `h1` C6 | spacing, colour, type weight |
| administration, email confirmation | stored name; new email; `Confirmar`; `Corrigir`; the other coordinator email absent C9, C11 | label `Nome da organização`, then the stored name, then `E-mail do coordenador`, then the new email; `Confirmar` then `Corrigir` C11 | spacing, colour, type weight |
| administration, correction failed | `[data-notice="error"]` `A correção foi gravada, mas o e-mail não saiu.` and primary `Reenviar e-mail` on that row; no `E-mail enviado para` C16 | the notice is inside the organization row; `Reenviar e-mail` is `bg-caixa` and posts `/administration/mail` C16 | spacing, colour, type weight |
| administration, removal blocked | `[data-notice="error"]` `Esta organização já tem dados de fechamento e não pode ser removida.` on that row C32 | the notice is inside the organization row, not under the `h1` C32 | spacing, colour, type weight |
| home, pending invite | `Reenviar e-mail`; `Cancelar`; no success sentence C40 | `Reenviar e-mail` (`text-caixa underline underline-offset-2`) immediately before `Cancelar` (`text-margem underline underline-offset-2`) on that invite row C40 | spacing, colour, type weight |
| home, invite send failed | `[data-notice="error"]` `O convite foi gravado, mas o e-mail não saiu.` C42 | after the `h1` `Meses` and before the months content C42 | spacing, colour, type weight |
| home, submitter | `h1` `Início`; no `Reenviar e-mail`; no invite-failure notice C51 | submitter home, not the `Meses` column C51 | spacing, colour, type weight |

## Swept

- validation: C6, C7, C8, C9, C48
- failure modes: C16, C18, C20, C24, C42, C45 - the write remains and the notice is the failure; a move that raises before commit leaves the old Access (C24)
- idempotency and retry: C17, C19, C39, C44 - resend delivers another message; mail for a missing organization writes nothing; a missing organization on removal is C37
- authorization: C2, C3, C49, C50
- concurrency and ordering: email-move overlap is Unresolved 3. Invite-create overlap stays the existing unique index on `invites` `(organization_id, email)`; C48 is the sequential rejection. Name-collision overlap is stage 1
- data lifecycle: C13 - `accounts.email` is not updated; C28 and C32 - removal deletes or deletes nothing
- external-dependency failure: C16, C42 - SMTP `deliver_now` raises, the write remains, the notice shows
- state transitions: States in `.tasks/administration-access.md`
- observability: n/a - no log, metric, or trace was decided. The notices in the failure-mode criteria are the signal

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| new administration routes when signed out (5) | `POST /administration/email` C2 · `POST /administration/email/continue` C2 · `POST /administration/email/cancel` C2 · `POST /administration/email/confirm` C2 · `DELETE /administration` C2 | - |
| new administration routes when not the administrator (2 callers × 5 routes) | other email C3 · blank env C3, each over the five routes in C2 | - |
| email-correction Continuar rejections (3) | invalid C6 · taken coordinator C7 · taken submitter C8 | - |
| email-correction Continuar allowed (2) | same address C9 · new address C11 | - |
| email-move writes (5) | same email, no second Access C10 · new Account plus Invite delete C13 · existing Account C14 · recipient is the new email C15 · rollback before commit C24 | - |
| correction mail outcomes (5) | confirm delivers C13 · `deliver_now` raises C16 · resend delivers to the new email C17 · resend raises C18 · missing organization id C23 | - |
| registration mail notices after this stage (2) | resend success does not show the correction notice C19 · resend raise keeps the registration notice C20 | - |
| close-data members that block removal (5) | BankAccount C32 · Month C33 · SupportingDocument C34 · Justification C35 · ExtraExceptionKind C36 | - |
| removal allowed (1) | no close data, last coordinator included C28 | - |
| invite kinds (2) | coordinator C40 · submitter C41 | - |
| invite create rejections (3 × 2 controllers) | standing Access, pending Invite, `nao-e-email` on coordinator C48 · the same three on submitter C48 | - |
| invite mail failure and retry (6) | create raises C42 · GET does not send C43 · resend other invite clears C44 · resend raises C45 · Cancelar keeps notice C46 · later create clears C52 | - |
| invite authorization (3) | signed out C50 · wrong organization C49 · submitter home C51 | - |
| designed screen states this stage builds (9) | rest with Corrigir/Remover C1 · email field C4 · email invalid C6 · email confirmation C11 · correction failed C16 · removal blocked C32 · home pending invite C40 · home invite failed C42 · home submitter C51 | - |

- Claims naming a status code, route, or response shape: C1–C12, C13 (request), C14 (request), C16–C23, C25–C30, C31 (request), C32–C42, C44–C52 - each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~13k + S2 ~21k + S3 ~13k + S4 ~20k + S5 ~7k = ~74k token floor, counting shared files again. Read once, the administration controller, the administration views, the request spec, the organization model, the invite controllers, the home, and the mailers are under 40k. The design was opened during extract (~5k). All five slices stay under 150k. S5 enters the home, a different surface, but still fits. No split. One batch.
