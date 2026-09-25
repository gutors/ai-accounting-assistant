# Administration list

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/administration-list.md` marks screen `administration` binding.

Sources:

- `.tasks/administration-list.md` - criteria 1–38, the state diagram, the sweep, and the boundary. Stage 1 of 2. Unresolved 1 stays open
- `.design/administration-list.md` - **binding for the interface**: screen `administration` (rest, invalid registration, registration confirmation, the row after a write, the name field, and the name confirmation). Opened as a file in the repo. The email-correction, removal, and home-invite drawings in that file are the next stage
- https://github.com/gutors/ai-accounting-assistant/issues/63 - the registry, the welcome subject, and the name correction. This cut does not close the issue
- `.design/administration-intake.md` - the form, the notices, confirm-before-write, and the session pending / result. Its confirmation `h1` `Confirmar cadastro` and the button `Cadastrar outra organização` do not survive
- `docs/adr/0006-administration-intake.md` - `administrator?` is one normalized env email. `index_organizations_on_lower_name` is the collision rule
- `DESIGN.md` - the 28rem left-aligned column, quiet caixa (`text-caixa underline underline-offset-2`), caixa primary, ink-border secondary, and the notice partial
- `app/views/shared/_notice.html.erb` - error notice is `[data-notice="error"]`
- `app/models/month.rb` - `replace_month_folder` is called with `name: year_month`. A rename does not call the writer
- `app/controllers/application_controller.rb` - the home orders coordinator emails with `order("accounts.email")`

## Out of scope

- `.tasks/administration-access.md` - `Corrigir` on a coordinator email, `Remover`, and invite mail. This stage does not add those controls
- Changing `Account.email`, moving an Access, or deleting an Organization
- The buyer form
- Changing `coordinator:bootstrap` or `db/seeds.rb`
- A second administrator
- A submitter list on `/administration`
- Accountant, package archive, and certificate screens
- The header, the months list, the people lists, and the invite forms
- Choosing the mailbox or adding a provider gem
- Closing issue #63. Unresolved 1 stays open. Tests use the `:test` delivery
- Deleting `POST /administration/another`. The button is absent. The route stays
- Rewriting a month folder on rename

## Landing

Touches `AdministrationController`, the administration views, `Organization.name_taken?`, and `CoordinatorWelcomeMailer`'s subject. Reuses `Organization.register_coordinator`, `index_organizations_on_lower_name`, the notice partial, `session[:administration_pending]`, `session[:administration_result]`, and `MailerEnvironment`.

None — this stage renames through the existing unique index and changes the subject on the existing mailer. The name draft is a session hash, the same kind of store as `session[:administration_pending]`.

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
- `spec/requests/administration_spec.rb` already proves the intake routes at HTTP. This cut extends that file for the list, the row result, and the name posts
- `spec/models/organization_spec.rb` already proves `register_coordinator` and the unique index. `name_taken?(except:)` is a new branch on that predicate
- `spec/mailers/coordinator_welcome_mailer_spec.rb` already proves the two welcome bodies. The subject change is the same two examples

Cost: a model example for `coordinator_emails` and for `name_taken?` excluding the organization being corrected; the mailer examples gain the new subject; request examples for every status and screen claim below.

## Checks

Name-correction posts, which the task left unnamed: `POST /administration/name` starts `Corrigir nome` (`organization_id`). `POST /administration/name/continue` is `Continuar` (`name`). `POST /administration/name/cancel` is `Cancelar`. `POST /administration/name/confirm` confirms the name (`organization_id`). `Corrigir` on that confirmation is `GET /administration`.

### S1 - Registry · 7 files · 43 KB · ~11k

**C1** - Given the allowlisted Account is signed in, no Organization exists, and `session[:administration_pending]` and `session[:administration_result]` are absent, when `GET /administration` runs, then the status is `200`, the `h1` is `Administração`, the body includes `Cadastre a organização e o coordenador que vai fechá-la.`, labels `Nome da organização` and `E-mail do coordenador` with empty fields, a submit `Continuar`, no heading `Organizações`, no `Cadastrar outra organização`, and the column is a `div` whose class includes `max-w-[28rem]` and does not include `mx-auto`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "GET /administration renders the empty registration form"`

**C2** - Given the allowlisted Account `seller@example.com` is signed in, and three organizations exist — `AMA` with coordinator `ana@exemplo.org`, `ONG Norte` with coordinators `zoe@exemplo.org` and `ana@exemplo.org` plus a submitter `submitter@exemplo.org`, and `ONG Sul` with coordinator `sul@exemplo.org` — when `GET /administration` runs, then the status is `200`, the form from C1 is still there, a heading `Organizações` follows the form, and the names appear in stored-name order `AMA`, `ONG Norte`, `ONG Sul`. The heading's class includes `border-b` and `border-rule`. The `ONG Norte` row shows `Corrigir nome` (class includes `text-caixa`, `underline`, and `underline-offset-2`), then `ana@exemplo.org`, then `zoe@exemplo.org`. The body does not include `submitter@exemplo.org`, a control whose text is `Corrigir`, or `Remover`. The row is an element whose class includes `flex-wrap`, `border-b`, and `border-rule`, inside the `max-w-[28rem]` column. `Organization#coordinator_emails` returns those coordinator emails in `accounts.email` order and omits the submitter
Proof: `bin/rspec spec/requests/administration_spec.rb -e "GET /administration lists organizations in stored-name order"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "coordinator_emails are ordered by accounts.email and omit submitters"`

**C3** - Given no signed-in Account, when the request is `GET /administration`, `POST /administration`, `POST /administration/confirm`, `POST /administration/mail`, `POST /administration/another`, `POST /administration/name`, `POST /administration/name/continue`, `POST /administration/name/cancel`, or `POST /administration/name/confirm`, then the response is `302` to `/login`, and `Organization.count`, `Account.count`, `Access.count`, `Invite.count`, and `ActionMailer::Base.deliveries` are unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "signed-out administration routes redirect to /login"`

**C4** - Given a signed-in Account whose email is not the normalized `ADMINISTRATOR_EMAIL`, including when that env is unset or blank, when the request is any route in C3, then the status is `404`, the body is empty, and the counts and deliveries in C3 are unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "non-administrator and blank allowlist administration routes respond 404"`

### S2 - Registration · 7 files · 37 KB · ~9k

**C5** - Given `ONG Norte` already exists and the allowlisted Account is signed in, when `POST /administration` submits name `   ` and email `coordenador@exemplo.org`, then the status is `422`, the only notice is `Informe o nome da organização.` in `[data-notice="error"]` under the `h1`, the typed values stay in the fields, `ONG Norte` is still listed, no Organization, Account, or Access is written, and `session[:administration_pending]` is not set
Proof: `bin/rspec spec/requests/administration_spec.rb -e "blank organization name re-renders 422 and writes nothing"`

**C6** - Given the same list, when `POST /administration` submits name `ONG Sul` and email `nao-e-email`, then the status is `422`, the only notice is `Informe um e-mail válido.`, the typed values stay, the list stays, nothing is written, and `session[:administration_pending]` is not set
Proof: `bin/rspec spec/requests/administration_spec.rb -e "invalid coordinator email re-renders 422 and writes nothing"`

**C7** - Given the same list, when `POST /administration` submits a blank name and email `nao-e-email`, then the status is `422`, the notices are `Informe o nome da organização.` and then `Informe um e-mail válido.`, the list stays, and nothing is written
Proof: `bin/rspec spec/requests/administration_spec.rb -e "blank name and invalid email re-render both notices"`

**C8** - Given an Organization named `ONG Norte` exists, when `POST /administration` submits name `  ong norte  ` and email `coordenador@exemplo.org`, then the status is `422`, the notice is `Já existe uma organização com esse nome.`, the fields keep those values, the list stays, nothing is written, and `session[:administration_pending]` is not set
Proof: `bin/rspec spec/requests/administration_spec.rb -e "taken organization name re-renders 422 and stores no pending"`

**C39** - Given an Organization named `ONG Norte` exists, when `POST /administration` submits name `  ong norte  ` and email `nao-e-email`, then the status is `422`, the notices are `Informe um e-mail válido.` and then `Já existe uma organização com esse nome.`, the fields keep those values, the list stays, nothing is written, and `session[:administration_pending]` is not set
Proof: `bin/rspec spec/requests/administration_spec.rb -e "taken name and invalid email re-render both notices"`

**C9** - Given `ONG Sul` is already listed, when `POST /administration` submits name `  ONG Norte  ` and email ` Coordenador@Exemplo.ORG `, then the status is `200`, the `h1` is `Administração`, the body does not include `Confirmar cadastro` or `Cadastre a organização e o coordenador que vai fechá-la.`, it shows `ONG Norte` and `coordenador@exemplo.org` with `Confirmar` (class includes `bg-caixa`) and `Corrigir` (class includes `border-ink`), `ONG Sul` stays at rest with `Corrigir nome`, nothing is written, no message is delivered, and `session[:administration_pending]` is `{ "name" => "ONG Norte", "email" => "coordenador@exemplo.org" }`. The label `Nome da organização` and the value sit in an element whose class includes `border-b` and `border-rule`, and the email label follows. `Confirmar` posts to `/administration/confirm`. `Corrigir` is an `a` to `/administration`. Those two controls sit in an element whose class includes `flex-wrap`, in that order
Proof: `bin/rspec spec/requests/administration_spec.rb -e "valid POST stores pending and renders confirmation"`

**C10** - Given that pending and no result, when `GET /administration` runs, then the status is `200`, the `h1` is `Administração`, the fields show `ONG Norte` and `coordenador@exemplo.org`, the lead sentence is present, the list stays at rest, and the page is not the confirmation in C9
Proof: `bin/rspec spec/requests/administration_spec.rb -e "GET /administration with pending fills the form"`

**C11** - Given the confirmation in C9, when `Corrigir` is followed, then the form shows `ONG Norte` and `coordenador@exemplo.org`, the list stays at rest, and nothing is written
Proof: `bin/rspec spec/requests/administration_spec.rb -e "Corrigir on the registration confirmation returns the filled form"`

**C12** - Given pending `{ "name" => "ONG Norte", "email" => "coordenador@exemplo.org" }` and that email has no Account, when `POST /administration/confirm` runs and delivery succeeds, then the response is `302` to `/administration`. The following `GET` is `200` with an empty form, the lead sentence, and on the `ONG Norte` row the text `E-mail enviado para coordenador@exemplo.org.` which is not `[data-notice="error"]`. That row has no `Reenviar e-mail`. The body has no `Cadastrar outra organização`. One Organization `ONG Norte`, one Account `coordenador@exemplo.org`, one coordinator Access, and no Invite exist. `session[:administration_pending]` is absent. `session[:administration_result]` is `{ "organization_id" => that id, "mail_sent" => true }`. One message is delivered to `coordenador@exemplo.org` with the subject and body in C24
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm creates the organization and shows the sent mail"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "register_coordinator creates Organization Account and coordinator Access"`

**C13** - Given pending for a new organization and an Account that already exists for that email, when confirm runs and delivery succeeds, then `Account.count` is unchanged, a new Organization and one coordinator Access exist, no Invite exists, and the following `GET` shows `E-mail enviado para` that email on that row
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm reuses an existing Account"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "register_coordinator reuses an existing Account"`

**C14** - Given the signed-in Account email equals the pending coordinator email, when confirm succeeds, then `session[:organization_id]` is the new Organization id and the following `GET /administration` header shows that organization name
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm of the signed-in email focuses the new organization"`

**C15** - Given the signed-in Account email does not equal the pending coordinator email, when confirm succeeds, then `session[:organization_id]` is unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm of another email leaves the focused organization"`

**C16** - Given `session[:administration_pending]` is absent and a registration result is already stored, when `POST /administration/confirm` runs, then no Organization, Account, or Access is written, no message is delivered, the result is unchanged, and the response is `302` to `/administration`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm without pending writes nothing and keeps the result"`

**C17** - Given a pending registration for `ONG Norte` and `ONG Sul` already listed, when `POST /administration/confirm` runs and `deliver_now` raises, then the Organization, Account, and coordinator Access remain, no Invite exists, `session[:administration_pending]` is absent, `session[:administration_result]["mail_sent"]` is false, and the following `GET` shows `[data-notice="error"]` `O cadastro foi gravado, mas o e-mail não saiu.` on the `ONG Norte` row only, with primary `Reenviar e-mail` whose class includes `bg-caixa`, `font-semibold`, and `text-white` and whose form posts to `/administration/mail`. The body does not include `E-mail enviado para` or `Cadastrar outra organização`. `ONG Sul` has no `Reenviar e-mail`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm keeps the rows when deliver_now raises"`

**C18** - Given that failed result, when `POST /administration/mail` runs and delivery succeeds, then `Organization.count` is unchanged, one more welcome is delivered to that coordinator, the result records that mail was sent, and the following `GET` shows `E-mail enviado para` that email and no `Reenviar e-mail`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "resend delivers another welcome message"`

**C19** - Given a failed result, when `POST /administration/mail` runs and `deliver_now` raises, then `Organization.count` is unchanged, the result still records that mail was not sent, and the following `GET` shows `O cadastro foi gravado, mas o e-mail não saiu.` on that row
Proof: `bin/rspec spec/requests/administration_spec.rb -e "resend keeps mail_sent false when deliver_now raises"`

**C20** - Given no registration result is stored, when `POST /administration/mail` runs, then the response is `302` to `/administration`, no message is delivered, and no Organization, Account, or Access is written
Proof: `bin/rspec spec/requests/administration_spec.rb -e "resend without a result redirects and delivers nothing"`

**C21** - Given no Organization named `ONG Norte` yet, when two overlapping `POST /administration/confirm` requests still hold pending names `ONG Norte` and `ong norte` for `coordenador@exemplo.org`, then exactly one Organization exists for that name. The request that loses the insert writes no Account and no Access, sends no mail, leaves no registration result, and responds `422` with `Já existe uma organização com esse nome.`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "concurrent confirms of the same name leave one organization"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "register_coordinator rejects a name that differs only by case"`

**C22** - Given `ONG Norte` is showing the failure notice from C17, when a later confirm of `ONG Sul` / `sul@exemplo.org` delivers, then the `ONG Norte` row has neither that notice nor `Reenviar e-mail`, and the `ONG Sul` row shows `E-mail enviado para sul@exemplo.org.`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "a later registration replaces the failure notice"`

**C23** - Given the success sentence from C12 is on the row, when `GET /administration` runs again, then that sentence is still on that row
Proof: `bin/rspec spec/requests/administration_spec.rb -e "the sent sentence stays on the row after refresh"`

### S3 - Welcome mail · 2 files · 3 KB · ~1k

**C24** - When the Account has exactly one coordinator Access, `CoordinatorWelcomeMailer` delivers one `text/plain` message whose body is `A organização ONG Norte está pronta. Entre com o Google usando coordenador@exemplo.org, pelo botão Entrar com Google.`, whose subject is `Fechamento Mensal - Cadastro da Organização ONG Norte`, and whose from address is `venda@example.com` when `MAIL_FROM` is `venda@example.com`
Proof: `bin/rspec spec/mailers/coordinator_welcome_mailer_spec.rb -e "welcome mail for the first organization"`

**C25** - When that Account already has two or more coordinator Accesses, the `text/plain` body is `A organização ONG Norte foi adicionada à sua conta. Entre com o Google usando coordenador@exemplo.org, pelo botão Entrar com Google.`, the subject is `Fechamento Mensal - Cadastro da Organização ONG Norte`, and the from address is `MAIL_FROM` at send time
Proof: `bin/rspec spec/mailers/coordinator_welcome_mailer_spec.rb -e "welcome mail when the account already coordinates another organization"`

### S4 - Name correction · 6 files · 43 KB · ~11k

**C26** - Given `ONG Norte` has coordinator `coordenador@exemplo.org`, when `Corrigir nome` is used, then that row shows the label `Nome da organização` on the stored name in one field, `Continuar` (class includes `bg-caixa`), and `Cancelar` (class includes `text-caixa`, `underline`, and `underline-offset-2`). `Continuar` then `Cancelar` sit in that order in an element whose class includes `flex-wrap`, and `Continuar` submits the form that contains the name field. The email follows that group as text, nothing is written, and no message is delivered
Proof: `bin/rspec spec/requests/administration_spec.rb -e "Corrigir nome opens the stored name"`

**C27** - Given that field is open and the typed value is `ONG Norte Nova`, when `Cancelar` is used, then the row is at rest with `ONG Norte`, the name is unchanged, and no message is delivered
Proof: `bin/rspec spec/requests/administration_spec.rb -e "Cancelar on the name field restores the row"`

**C28** - Given the name field is open, when `Continuar` submits `   `, then the status is `422`, the notice under the `h1` is `Informe o nome da organização.`, the field keeps what was typed, the row does not become a confirmation, and the stored name stays `ONG Norte`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "blank name correction re-renders 422"`

**C29** - Given `ONG Sul` exists and the name field is open on `ONG Norte`, when `Continuar` submits `ong sul`, then the status is `422`, the notice is `Já existe uma organização com esse nome.`, the field keeps `ong sul`, the stored name stays `ONG Norte`, and the row does not become a confirmation. `Organization.name_taken?` is false when the only match is the organization passed as `except`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "taken name correction re-renders 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "name_taken? ignores the organization being corrected"`

**C30** - Given the stored name is `ONG Norte`, when `Continuar` submits `ong norte`, then the status is `200`, the row is replaced by the label `Nome da organização`, then `ong norte`, then the sentence `Nenhum e-mail será enviado.` which is not `[data-notice="error"]`. The coordinator email is absent from that row. Other rows stay at rest, the collision notice is absent, and nothing is written. `Confirmar` (class includes `bg-caixa`, posts `/administration/name/confirm`) and `Corrigir` (class includes `border-ink`, links to `/administration`) sit in that order in an element whose class includes `flex-wrap`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "a lower-case spelling of the same name asks for confirmation"`

**C31** - Given `ONG Norte` has a closed Month with a `month_folder_id`, and `Continuar` submitted `  ong norte  ` so the confirmation shows `ong norte`, when that confirmation is confirmed, then the stored name is `ong norte`, no message is delivered, `PackageArchiveWriter` is not called, `month_folder_id` is unchanged, the row shows `ong norte`, and the body does not include `Nenhum e-mail será enviado.`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirming a name correction stores the stripped name and does not call the writer"`

**C32** - Given `ONG Norte` is showing `O cadastro foi gravado, mas o e-mail não saiu.` and `Reenviar e-mail`, when its name is confirmed as `ONG Norte Nova`, then no message is delivered, the row shows `ONG Norte Nova`, and that same notice and `Reenviar e-mail` are still on that row
Proof: `bin/rspec spec/requests/administration_spec.rb -e "renaming keeps the mail failure on that row"`

**C33** - Given the failure notice is on `ONG Norte`, when `ONG Sul`'s name is confirmed as `ONG Sul Nova`, then the notice and `Reenviar e-mail` stay on `ONG Norte`, `ONG Sul Nova` has no mail sentence, and no message is delivered
Proof: `bin/rspec spec/requests/administration_spec.rb -e "renaming another organization leaves the failure notice in place"`

**C34** - Given `ONG Norte` and `ONG Sul`, when two overlapping name confirms both submit `ONG Iguais`, then one Organization is named `ONG Iguais` and the other keeps its previous name. The loser responds `422` with `Já existe uma organização com esse nome.` and sends no mail
Proof: `bin/rspec spec/requests/administration_spec.rb -e "concurrent name confirms of the same name leave one rename"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "updating onto a taken lower name raises RecordNotUnique and keeps the previous name"`

**C35** - Given the name confirmation is showing `ONG Norte Nova` and `Nenhum e-mail será enviado.`, when `Corrigir` is used, then the field shows `ONG Norte Nova`, nothing is written, and no message is delivered
Proof: `bin/rspec spec/requests/administration_spec.rb -e "Corrigir on the name confirmation returns the typed name"`

**C36** - When a name confirmation is submitted for an organization id that does not exist, then the response is `404`, every Organization name is unchanged, and no message is delivered
Proof: `bin/rspec spec/requests/administration_spec.rb -e "name confirmation for a missing organization responds 404"`

### S5 - One unwritten flow · 2 files · 28 KB · ~7k

**C37** - Given a registration confirmation is unwritten for `ONG Nova` / `nova@exemplo.org`, when `Corrigir nome` starts on an existing organization, then no Organization named `ONG Nova` exists, the registration form is empty, and the name field is open
Proof: `bin/rspec spec/requests/administration_spec.rb -e "Corrigir nome discards an unwritten registration"`

**C38** - Given the name field is open on `ONG Norte` with typed `ONG Norte Nova` and nothing has been confirmed, when `POST /administration` submits a valid new registration, then the stored name is still `ONG Norte`, the registration confirmation is shown, and the name field is not open
Proof: `bin/rspec spec/requests/administration_spec.rb -e "a valid registration discards an open name field"`

## Screens (ui)

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| administration, rest, no organizations | `h1` `Administração`, lead sentence, labels, empty inputs, `Continuar`; no heading `Organizações`; no `Cadastrar outra organização` C1 | column `div.max-w-[28rem]` without `mx-auto` C1 | spacing, colour, type weight |
| administration, rest, with organizations | form from C1, heading `Organizações`, stored names, `Corrigir nome`, coordinator emails; no `Corrigir` control, no `Remover`, no submitter email C2 | heading follows the form and its class includes `border-b` and `border-rule`; names `AMA`, `ONG Norte`, `ONG Sul`; `ONG Norte` row is `flex-wrap` with `border-b` and `border-rule` inside the column, then `Corrigir nome` (`text-caixa underline underline-offset-2`), then `ana@exemplo.org`, then `zoe@exemplo.org` C2 | spacing, colour, type weight |
| administration, invalid registration | notices C5, C6, C7, C8, C39; typed values stay; the list stays | the only `[data-notice="error"]` sits under the `h1` C5; name notice then email notice C7; email notice then taken-name notice C39 | spacing, colour, type weight |
| administration, registration confirmation | `h1` `Administração`; no `Confirmar cadastro`; no lead sentence; stripped name; normalized email; `Confirmar`; `Corrigir`; listed rows stay at rest with `Corrigir nome` C9 | labels and values inside `.border-b.border-rule` then the email block; `flex-wrap` group with `Confirmar` (`bg-caixa`, posts `/administration/confirm`) then `Corrigir` (`a` to `/administration`, `border-ink`) C9 | spacing, colour, type weight |
| administration, row sent | empty form, lead sentence, `E-mail enviado para {email}.` on that row; no `Reenviar e-mail`; no `Cadastrar outra organização` C12 | the sentence is a `p` inside the organization's `flex-wrap` row and is not `[data-notice="error"]` C12 | spacing, colour, type weight |
| administration, row failed | notice `O cadastro foi gravado, mas o e-mail não saiu.` and `Reenviar e-mail` on that row only C17 | `[data-notice="error"]` inside the `ONG Norte` row; `Reenviar e-mail` includes `bg-caixa`, `font-semibold`, `text-white` and posts `/administration/mail`; `ONG Sul` has no `Reenviar e-mail` C17 | spacing, colour, type weight |
| administration, name field | label `Nome da organização`, stored name in one field, `Continuar`, `Cancelar`, email as text C26 | `flex-wrap` group with `Continuar` (`bg-caixa`, submits the form that contains the name field) then `Cancelar` (`text-caixa underline underline-offset-2`); the email follows that group and is not an input C26 | spacing, colour, type weight |
| administration, name confirmation | label `Nome da organização`, new name, `Nenhum e-mail será enviado.`, `Confirmar`, `Corrigir`; coordinator email absent; other rows at rest C30 | label, then the new name, then the sentence, which is not `[data-notice="error"]`; `flex-wrap` group with `Confirmar` (`bg-caixa`, posts `/administration/name/confirm`) then `Corrigir` (`border-ink`, links `/administration`) C30 | spacing, colour, type weight |

## Swept

- validation: C5, C6, C7, C8, C39, C28, C29, C30
- failure modes: C17, C19
- idempotency and retry: C18, C20
- authorization: C3, C4
- concurrency and ordering: C21, C34 - unique index `index_organizations_on_lower_name`
- data lifecycle: C31 - rename does not rewrite the month folder
- external-dependency failure: C17 - SMTP `deliver_now` raises, the registration remains, the notice shows on that row
- state transitions: C9, C10, C11, C12, C17, C18, C19, C22, C23, C26, C27, C30, C31, C35, C37, C38
- observability: n/a - no log, metric, or trace was decided. The notice in C17 is the signal

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| administration routes when signed out (9) | `GET /administration` C3 · `POST /administration` C3 · `POST /administration/confirm` C3 · `POST /administration/mail` C3 · `POST /administration/another` C3 · `POST /administration/name` C3 · `POST /administration/name/continue` C3 · `POST /administration/name/cancel` C3 · `POST /administration/name/confirm` C3 | - |
| administration routes when not the administrator (2 callers × 9 routes) | other email C4 · blank env C4, each over the nine routes in C3 | - |
| `POST /administration` rejection notices (5) | blank name C5 · invalid email C6 · blank name then invalid email C7 · taken name C8 · taken name with invalid email C39 | - |
| confirm outcomes (8) | new Account C12 · existing Account C13 · own email focuses new org C14 · other email leaves focus C15 · no pending C16 · `deliver_now` raises C17 · lost unique name C21 · a later confirm replaces the failure C22 | - |
| resend outcomes (3) | delivery succeeds C18 · `deliver_now` raises C19 · no result C20 | - |
| welcome sentences (2) | one coordinator Access C24 · two or more C25 | - |
| `coordinator_emails` (2) | ascending `accounts.email` C2 · submitter omitted C2 | - |
| `name_taken?` except (2) | another organization C29 · the organization being corrected C29 | - |
| name-correction outcomes (11) | open field C26 · cancel C27 · blank C28 · taken C29 · own lower name C30 · confirm, no writer C31 · failure notice stays C32 · other row's notice stays C33 · lost unique name C34 · Corrigir C35 · missing id C36 | - |
| unwritten-flow discards (2) | registration confirmation discarded by `Corrigir nome` C37 · open name field discarded by a valid registration C38 | - |
| designed screen states this stage builds (8) | rest empty C1 · rest list C2 · invalid C5 · registration confirmation C9 · row sent C12 · row failed C17 · name field C26 · name confirmation C30 | - |
| drawings in `.design/administration-list.md` this stage does not build (3) | — | email correction, removal, and screen `home` invites — next stage, named in Out of scope |

- Claims naming a status code, route, or response shape: C1–C21, C26–C31, C34–C36, C39 - each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~11k + S2 ~9k + S3 ~1k + S4 ~11k + S5 ~7k = ~39k token floor, counting shared files again. Read once, the controller, the administration views, the request spec, the organization model, and the mailer are under 30k. The design was opened during extract (~5k). All five slices stay under 150k, and they share `AdministrationController`. No split. One batch.

Batch closed. Checks C1–C38 are in `914f965`. No mid-build clarification. Nothing abandoned.
