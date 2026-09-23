# Administration intake

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/administration-intake.md` marks screen `administration` binding.

Sources:

- `.tasks/administration-intake.md` - criteria 1–41, doors, sweep, surface, holding answers for Unresolved 2 and 3
- `.design/administration-intake.md` - **binding for the interface**: screen `administration` (empty, invalid, confirmation, success, mail failure, and the header states drawn on it). Opened as a file in the repo.
- https://github.com/gutors/ai-accounting-assistant/issues/62 - the sale opens `/administration`; construction does not answer #63
- https://github.com/gutors/ai-accounting-assistant/issues/63 - mailbox account, welcome subject, and resend with no result stay open. Holding answers below are the task's "until answered" column, not a resolution
- `DESIGN.md` - short form at 28rem, caixa primary, ink-border secondary, margem notice, sheet field on a 1px rule
- `lib/tasks/coordinator.rake` - today's write; this cut does not edit it
- `app/models/operator_authenticator.rb` - zero Access and no Invite is `:denied` and creates no Account, except the allowlisted email
- `app/controllers/application_controller.rb` - `sign_in` stores `organization.id` today; this cut stores `organization&.id`. Invalid HTML re-renders use `422`
- `app/views/shared/_notice.html.erb` - error notice is `[data-notice="error"]`
- `config/environments/production.rb` - commented SMTP example is port `587` and `authentication: :plain`

## Out of scope

- List, correction, and removal of a registration - the review trigger. A saved typo stays (C28)
- A buyer-facing form - the product does not record a purchase
- Renaming an Organization
- Editing `coordinator:bootstrap` or `db/seeds.rb` - a duplicate `ORGANIZATION_NAME` exits non-zero because of the unique index (C31); an existing Account still aborts as today
- Mail for later Invites - Invite delivery stays out of band
- Choosing an SMTP vendor or naming the mailbox account - Unresolved 1 / #63. No vendor and no mailbox name in the repo
- Accountant, package archive, and SEFAZ certificate - they stay on `/setup`
- An `administrators` table or a flag on Account
- A new term in `CONTEXT.md`
- `GET /` for a signed-in Account with no focused organization - `require_focused_organization` still redirects to `/login`
- Settling Unresolved 1–3. C42 and C43 implement the holding answers only

## Landing

Touches `OperatorAuthenticator`, the Google callback, `sign_in`, `Organization`, the header, Action Mailer configuration, and a new administration screen. Reuses `NormalizedEmail`, `Account.create!`, `Access` kind `coordinator`, the notice partial, `head :not_found`, and `coordinator:bootstrap` unchanged.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Who opens the screen | `administrator?` is true only when `NormalizedEmail.normalize(ENV["ADMINISTRATOR_EMAIL"]) == current_account.email`. Blank or unset env is false | An `administrators` table - a second person who must open the screen without a deploy is not the seller today |
| Sign-in without Access | A verified email equal to `ADMINISTRATOR_EMAIL`, with zero Access and zero Invites, creates the Account when it is missing, returns `:signed_in` with no organization, and does not create an Organization. `sign_in` stores `session[:organization_id] = organization&.id`. The callback redirects to `/administration` when the result has no organization. Pending Invites for that email still accept first | Requiring a bootstrapped Access before the form - the seller is not a coordinator of the customer organization, and today's callback sends zero Access to `/denied` |
| Organization name | Unique index `index_organizations_on_lower_name` on `lower((name)::text)`. The stored name stays the stripped text the person typed. `ONG Norte` occupies `ong norte` and `  ONG NORTE  `. A taken name on `POST /administration` is `422` with notice `Já existe uma organização com esse nome.` and does not store pending. A confirm that loses the insert rolls the transaction back, sends no mail, and responds `422` with that notice | A case-sensitive index on `organizations.name` - `ONG Norte` and `ong norte` would be two organizations. Leaving the name non-unique would let two overlapping confirms insert two rows |

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
- `spec/models/operator_authenticator_spec.rb` and `spec/requests/omniauth_callbacks_spec.rb` already split authenticator outcomes that way. This cut adds the allowlisted zero-Access branch to that table
- `spec/models/extra_exception_kind_spec.rb` proves a `lower((name)::text)` unique index at the model, including a concurrent create. Organization name uses the same expression without the organization prefix
- `spec/requests/layout_spec.rb` proves header branches at the request, which is the layer `coordinator_on_focus?` already uses
- `spec/config/omniauth_spec.rb` proves a boot setting by the value the process assembled and by the file that applies it. Mailer host and SMTP follow that, because development and production are not the booted test process

Cost: model specs for the authenticator outcomes, `register_coordinator`, and the SMTP/host table; a mailer spec for the two welcome sentences; request specs for every status and screen claim below.

## Checks

### S1 - Allowlisted door · 7 files · 19 KB · ~5k

**C1** - Given `ADMINISTRATOR_EMAIL` is `seller@example.com`, and a verified Google auth for `seller@example.com` has no Account, no Access, and no Invite, when the callback runs, then one Account exists with email `seller@example.com` and `google_uid` equal to that auth uid, no Organization and no Access exist for it, `session[:account_id]` is that Account, `session[:organization_id]` is nil, and the response is `302` to `/administration`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "allowlisted callback with no Account redirects to /administration"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "allowlisted email with no Account signs in with no organization"`

**C2** - Given `ADMINISTRATOR_EMAIL` is `seller@example.com` and that email already has an Account with a coordinator Access to Organization `ONG Norte`, when a verified callback for `seller@example.com` runs, then `Account.count` is unchanged, `session[:organization_id]` is `ONG Norte`, and the response is `302` to `/`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "allowlisted coordinator callback keeps the organization and redirects home"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "allowlisted email with coordinator Access signs in to that organization"`

**C3** - Given `ADMINISTRATOR_EMAIL` is `seller@example.com` and a pending coordinator Invite exists for that email and no Account does, when a verified callback runs, then the Invite is accepted (one Account, one coordinator Access, the Invite row is gone) and the response is `302` to `/`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "allowlisted callback with a pending Invite accepts the Invite and redirects home"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "allowlisted email with a pending Invite accepts the Invite"`

**C4** - Given `ADMINISTRATOR_EMAIL` is `seller@example.com` and a verified Google auth is `other@example.com` with no Invite and no Access, when the callback runs, then no Account is persisted for `other@example.com` and the response is `302` to `/denied`, and the denied page body includes `Você não foi convidado a usar este sistema.`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "uninvited callback persists no Account and the denied page names the refusal"`

**C5** - Given `ADMINISTRATOR_EMAIL` is `seller@example.com` and the Google auth for that email is not verified (`email_verified` is not `true` and not `"true"`), when the callback runs, then no Account is persisted and the response is `302` to `/login`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "unverified allowlisted callback persists no Account and redirects to /login"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "unverified allowlisted email is unverified"`

**C6** - Given `ADMINISTRATOR_EMAIL` is unset or blank, when a verified Google auth with no Invite and no Access runs, then no Account is persisted and the response is `302` to `/denied`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "blank administrator email persists no Account and redirects to /denied"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "blank administrator email denies a verified email with no Access"`

**C7** - Given a coordinator Access exists for `coordenador@exemplo.org` on Organization `ONG Norte`, when a verified callback for that email runs, then the response is `302` to `/` and the home body includes `ONG Norte` and does not include `Você não foi convidado a usar este sistema.`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "verified coordinator callback redirects to organization home"`

**C44** - Given `ADMINISTRATOR_EMAIL` is `Seller@Example.com`, and a verified Google auth for `seller@example.com` has no Account, no Access, and no Invite, when the callback runs, then the outcome is the same as C1: one Account `seller@example.com`, no Organization, no Access, `session[:organization_id]` nil, `302` to `/administration`. The door compares `NormalizedEmail.normalize` of the env to the auth email
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "mixed-case administrator email is the same door"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "mixed-case administrator email signs in with no organization"`

**C45** - Given `ADMINISTRATOR_EMAIL` is `seller@example.com` and an Account already exists for that email with zero Access and zero Invites and a blank `google_uid`, when a verified callback runs, then `Account.count` is unchanged, `google_uid` becomes that auth uid, no Organization and no Access are created, `session[:account_id]` is that Account, `session[:organization_id]` is nil, and the response is `302` to `/administration`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "allowlisted Account with zero Access signs in without a second Account"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "allowlisted Account with zero Access signs in with no organization"`

### S2 - Screen administration · 6 files · 37 KB · ~9k

**C8** - Given no signed-in Account, when the request is `GET /administration`, `POST /administration`, `POST /administration/confirm`, `POST /administration/mail`, or `POST /administration/another`, then the response is `302` to `/login`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "signed-out administration routes redirect to /login"`

**C9** - Given a signed-in Account whose email is not the normalized `ADMINISTRATOR_EMAIL`, including when that env is unset or blank, when the request is any route in C8, then the status is `404` and the body is empty
Proof: `bin/rspec spec/requests/administration_spec.rb -e "non-administrator and blank allowlist administration routes respond 404"`

**C10** - Given the allowlisted Account is signed in, and `session[:administration_pending]` and `session[:administration_result]` are absent, when `GET /administration` runs, then the status is `200`, the `h1` is `Administração`, the body includes `Cadastre a organização e o coordenador que vai fechá-la.`, labels `Nome da organização` and `E-mail do coordenador` in that order with empty fields, a submit button `Continuar`, and no `[data-notice="error"]`. The column is a `div` whose class includes `max-w-[28rem]` and does not include `mx-auto`. Each label's field is the following `input`, and those inputs include classes `w-full`, `border`, `border-rule`, and `bg-sheet`. `Continuar` includes class `bg-caixa`. `main` contains no `svg`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "GET /administration renders the empty registration form"`

**C11** - Given the allowlisted Account is signed in, when `POST /administration` submits name `   ` and email `coordenador@exemplo.org`, then the status is `422`, the only `[data-notice="error"]` is `Informe o nome da organização.`, the typed values stay in the fields, no Organization, Account, or Access is written, and `session[:administration_pending]` is not set to that submission
Proof: `bin/rspec spec/requests/administration_spec.rb -e "blank organization name re-renders 422 and writes nothing"`

**C12** - Given the allowlisted Account is signed in, when `POST /administration` submits name `ONG Norte` and email `nao-e-email`, then the status is `422`, the only `[data-notice="error"]` is `Informe um e-mail válido.`, the typed values stay in the fields, no Organization, Account, or Access is written, and `session[:administration_pending]` is not set to that submission
Proof: `bin/rspec spec/requests/administration_spec.rb -e "invalid coordinator email re-renders 422 and writes nothing"`

**C13** - Given the allowlisted Account is signed in, when `POST /administration` submits a blank name and email `nao-e-email`, then the status is `422`, the body contains `Informe o nome da organização.` and then `Informe um e-mail válido.`, no Organization, Account, or Access is written, and `session[:administration_pending]` is not set to that submission. Both notices are `[data-notice="error"]`, and they sit after the `h1` and before `Cadastre a organização e o coordenador que vai fechá-la.`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "blank name and invalid email re-render both notices"`

**C14** - Given the allowlisted Account is signed in, when `POST /administration` submits name `  ONG Norte  ` and email ` Coordenador@Exemplo.ORG `, then the status is `200`, the `h1` is `Confirmar cadastro`, the body shows `ONG Norte` and `coordenador@exemplo.org`, and it does not include `Cadastre a organização e o coordenador que vai fechá-la.`. The name value sits in an element whose class includes `border-b` and `border-rule`, and the email value follows that element. The buttons are `Confirmar` and `Corrigir` in that order inside one element whose class includes `flex-wrap`. `Confirmar` is a submit whose class includes `bg-caixa` and whose form posts to `/administration/confirm`. `Corrigir` is an `a` to `/administration` whose class includes `border` and `border-ink`. No Organization, Account, or Access is written, and `session[:administration_pending]` is `{ "name" => "ONG Norte", "email" => "coordenador@exemplo.org" }`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "valid POST stores pending and renders confirmation"`

**C15** - Given `session[:administration_pending]` is `{ "name" => "ONG Norte", "email" => "coordenador@exemplo.org" }` and `session[:administration_result]` is absent, when `GET /administration` runs, then the status is `200`, the `h1` is `Administração`, and the fields show `ONG Norte` and `coordenador@exemplo.org`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "GET /administration with pending fills the form"`

**C16** - Given pending `{ "name" => "ONG Norte", "email" => "coordenador@exemplo.org" }` and that email has no Account, when `POST /administration/confirm` runs and delivery succeeds, then the response is `302` to `/administration`, the following `GET` is `200` with `h1` `Administração`, body `E-mail enviado para coordenador@exemplo.org.`, the record `ONG Norte` and `coordenador@exemplo.org` with the name inside an element whose class includes `border-b` and `border-rule`, button `Cadastrar outra organização` whose class includes `border` and `border-ink` and whose form posts to `/administration/another`, and no `[data-notice="error"]`. The body does not include `Cadastre a organização e o coordenador que vai fechá-la.`. One Organization named `ONG Norte`, one Account `coordenador@exemplo.org`, one Access of kind `coordinator`, and no Invite exist. `session[:administration_pending]` is absent. `session[:administration_result]` is `{ "organization_id" => that id, "mail_sent" => true }`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm creates the organization and shows the sent mail"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "register_coordinator creates Organization Account and coordinator Access"`

**C17** - Given pending for a new organization and an Account that already exists for that email, when `POST /administration/confirm` runs and delivery succeeds, then `Account.count` is unchanged, a new Organization and one coordinator Access on it exist, no Invite exists, and the following `GET /administration` shows `E-mail enviado para` that email
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm reuses an existing Account"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "register_coordinator reuses an existing Account"`

**C18** - Given the signed-in Account email equals the pending coordinator email and `session[:organization_id]` is already another Organization, when confirm succeeds, then `session[:organization_id]` is the new Organization id
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm of the signed-in email focuses the new organization"`

**C19** - Given the signed-in Account email does not equal the pending coordinator email and `session[:organization_id]` is an Organization that Account already coordinates, when confirm succeeds, then `session[:organization_id]` is unchanged
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm of another email leaves the focused organization"`

**C20** - Given `session[:administration_pending]` is absent, when `POST /administration/confirm` runs, then no Organization, Account, or Access is written, an existing `session[:administration_result]` is unchanged, and the response is `302` to `/administration`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm without pending writes nothing and keeps the result"`

**C21** - Given a pending registration, when `POST /administration/confirm` runs and `deliver_now` raises, then the Organization, Account, and coordinator Access from that transaction remain, no Invite exists, `session[:administration_pending]` is absent, `session[:administration_result]["mail_sent"]` is false, and the following `GET` shows `[data-notice="error"]` `O cadastro foi gravado, mas o e-mail não saiu.` after the `h1`, buttons `Reenviar e-mail` and `Cadastrar outra organização` in that order inside one element whose class includes `flex-wrap`, `Reenviar e-mail` includes class `bg-caixa` and posts to `/administration/mail`, `Cadastrar outra organização` includes classes `border` and `border-ink` and posts to `/administration/another`, and the body does not include `E-mail enviado para`. The rows remain because delivery runs after the transaction commits and the delivery error is rescued
Proof: `bin/rspec spec/requests/administration_spec.rb -e "confirm keeps the rows when deliver_now raises"`

**C22** - Given `session[:administration_result]` has `mail_sent` false for an organization, when `POST /administration/mail` runs and delivery succeeds, then `Organization.count` is unchanged, one more welcome message is delivered, `mail_sent` is true, and the following `GET` includes `E-mail enviado para` that coordinator email
Proof: `bin/rspec spec/requests/administration_spec.rb -e "resend delivers another welcome message"`

**C23** - Given `session[:administration_result]` has an organization id, when `POST /administration/mail` runs and `deliver_now` raises, then `Organization.count` is unchanged, `mail_sent` is false, and the following `GET` shows `O cadastro foi gravado, mas o e-mail não saiu.`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "resend keeps mail_sent false when deliver_now raises"`

**C24** - Given a result is in the session and the Organization row exists, when `POST /administration/another` runs, then `session[:administration_result]` is absent, the following `GET` is the empty form in C10, and that Organization row remains
Proof: `bin/rspec spec/requests/administration_spec.rb -e "another registration clears the result and keeps the organization"`

**C25** - Given a session holds `administration_pending` or `administration_result`, when `DELETE /session` runs, then the response is `302` to `/login`, the next request has neither key, an unconfirmed pending left no Organization, and a confirmed Organization remains
Proof: `bin/rspec spec/requests/administration_spec.rb -e "sign out drops a pending registration and writes no organization"`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "sign out drops a confirmed result and keeps the organization"`

**C43** - Given `session[:administration_result]` is absent, when `POST /administration/mail` runs, then the response is `302` to `/administration`, no welcome message is delivered, and no Organization, Account, or Access is written. Holding answer for Unresolved 3; this check does not close #63
Proof: `bin/rspec spec/requests/administration_spec.rb -e "resend without a result redirects and delivers nothing"`

### S3 - Registration · 5 files · 22 KB · ~6k

**C26** - If `Organization.register_coordinator` raises before commit, then `Organization.count`, `Account.count`, and `Access.count` are unchanged from before the call, and no welcome message is delivered, because the Organization, the Account create-when-missing, and the coordinator Access share one transaction and the mail runs only after commit
Proof: `bin/rspec spec/models/organization_spec.rb -e "register_coordinator rolls back when it raises before commit"`

**C27** - Given an Organization named `ONG Norte` already exists, when `Organization.register_coordinator` is called with name `ONG Norte` or `ong norte` and a different valid email, then the call raises `ActiveRecord::RecordNotUnique`, `Organization.count`, `Account.count`, and `Access.count` are unchanged, and no welcome message is delivered, because the unique index on `lower((name)::text)` rejects the insert and the transaction rolls back
Proof: `bin/rspec spec/models/organization_spec.rb -e "register_coordinator rejects a name that differs only by case"`

**C28** - After a successful confirm of `ONG Norte` / `coordenador@exemplo.org`, the success and mail-failure screens include no `input[name="name"]` and no `input[name="email"]`, and that Organization name and Account email stay `ONG Norte` and `coordenador@exemplo.org`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "saved registration screens have no name or email fields"`

**C29** - Given an Organization named `ONG Norte` exists and the allowlisted Account is signed in, when `POST /administration` submits name `  ong norte  ` and email `coordenador@exemplo.org`, then the status is `422`, the notice is `Já existe uma organização com esse nome.`, the fields keep those typed values, no Organization, Account, or Access is written, and `session[:administration_pending]` is not set
Proof: `bin/rspec spec/requests/administration_spec.rb -e "taken organization name re-renders 422 and stores no pending"`

**C30** - Given no Organization named `ONG Norte` yet, when two overlapping `POST /administration/confirm` requests still hold pending names `ONG Norte` and `ong norte` for `coordenador@exemplo.org`, then exactly one Organization exists for that name. The request that loses the insert writes no Account and no Access, sends no mail, leaves `session[:administration_result]` unset, and responds `422` with notice `Já existe uma organização com esse nome.` The unique index on `lower((name)::text)` is what keeps the second insert from committing
Proof: `bin/rspec spec/requests/administration_spec.rb -e "concurrent confirms of the same name leave one organization"`

**C31** - When `bin/rails coordinator:bootstrap` runs with `ORGANIZATION_NAME` `ong norte` while an Organization named `ONG Norte` exists, and a `COORDINATOR_EMAIL` that has no Account, then it persists nothing and exits non-zero. `lib/tasks/coordinator.rake` still contains `abort "an Account already exists for that email"` and `Organization.create!`, and it does not rescue that insert
Proof: `bin/rspec spec/tasks/coordinator_bootstrap_spec.rb -e "bootstrap with a case-different organization name persists nothing and exits non-zero"`

### S4 - Welcome mail · 3 files · 4 KB · ~1k

**C32** - When the Account has exactly one coordinator Access, `CoordinatorWelcomeMailer.welcome(organization)` delivers one `text/plain` message whose body is `A organização ONG Norte está pronta. Entre com o Google usando coordenador@exemplo.org, pelo botão Entrar com Google.` and whose from address is `ENV["MAIL_FROM"]` at send time
Proof: `bin/rspec spec/mailers/coordinator_welcome_mailer_spec.rb -e "welcome mail for the first organization"`

**C33** - When that Account already has two or more coordinator Accesses, the `text/plain` body is `A organização ONG Norte foi adicionada à sua conta. Entre com o Google usando coordenador@exemplo.org, pelo botão Entrar com Google.` and the from address is `ENV["MAIL_FROM"]` at send time
Proof: `bin/rspec spec/mailers/coordinator_welcome_mailer_spec.rb -e "welcome mail when the account already coordinates another organization"`

**C42** - The welcome subject is `Cadastro da organização ONG Norte` for both the one-Access sentence and the two-Access sentence. Holding answer for Unresolved 2; this check does not close #63
Proof: `bin/rspec spec/mailers/coordinator_welcome_mailer_spec.rb -e "welcome mail for the first organization"`
Proof: `bin/rspec spec/mailers/coordinator_welcome_mailer_spec.rb -e "welcome mail when the account already coordinates another organization"`

### S5 - Header · 2 files · 3 KB · ~1k

**C34** - Given an Account is signed in and `session[:organization_id]` is nil, when `GET /administration` renders, then the header shows `Fechamento mensal` and one `Sair` control that submits `DELETE /session`, and it does not show `Início`, `Documentos`, `Configuração`, or `Administração`. That `Sair` control includes class `text-caixa`
Proof: `bin/rspec spec/requests/administration_spec.rb -e "header without a focused organization shows the product name and Sair"`

**C35** - Given the signed-in Account is the allowlisted email and coordinator of the focused Organization, when `GET /` renders, then the header has one `a` `Administração` to `/administration` whose class includes `text-ink`, placed after the `Configuração` link, and one `Sair`. The header's link row is inside an element whose class includes `flex-wrap`
Proof: `bin/rspec spec/requests/layout_spec.rb -e "administrator coordinator header links Administracao after Configuracao"`

**C36** - Given the signed-in Account is a coordinator and is not the allowlisted email, when `GET /` renders, then the header has `Início`, `Documentos`, `Configuração`, and `Sair`, and no `Administração` link
Proof: `bin/rspec spec/requests/layout_spec.rb -e "coordinator who is not the administrator has no Administracao link"`

**C37** - Given the signed-in Account is the allowlisted email and a submitter on the focused Organization, when `GET /` renders, then the header has `Início`, `Documentos`, `Administração` to `/administration` after `Documentos`, and `Sair`, and no `Configuração` link
Proof: `bin/rspec spec/requests/layout_spec.rb -e "administrator submitter header links Administracao after Documentos"`

### S6 - Delivery configuration · 6 files · 16 KB · ~4k

**C38** - `config.action_mailer.raise_delivery_errors` is true in development and in production. In the booted test process, `delivery_method` is `:test` and `default_url_options` host is `example.com`
Proof: `bin/rspec spec/config/mailer_environment_spec.rb -e "mail delivery errors are raised outside test and test uses the test delivery"`

**C39** - In production, when `SMTP_ADDRESS` is present, `smtp_settings` uses `address` `SMTP_ADDRESS`, `port` the integer `SMTP_PORT` (or `587` when `SMTP_PORT` is blank), `user_name` `SMTP_USER_NAME`, `password` `SMTP_PASSWORD`, and `authentication` `:plain`. When `SMTP_ADDRESS` is blank, those settings are not applied. `config/environments/production.rb` calls `MailerEnvironment.apply!`
Proof: `bin/rspec spec/config/mailer_environment_spec.rb -e "production smtp settings follow SMTP_ADDRESS"`

**C40** - In development and production, `config.action_mailer.default_url_options` host equals `ENV["MAILER_HOST"]`. When `MAILER_HOST` is `fechamento.example`, the host is `fechamento.example`. `config/environments/development.rb` and `config/environments/production.rb` both call `MailerEnvironment.apply!`
Proof: `bin/rspec spec/config/mailer_environment_spec.rb -e "development and production mail host is MAILER_HOST"`

**C41** - The setup note in `README.md` includes the strings `ADMINISTRATOR_EMAIL`, `MAIL_FROM`, `MAILER_HOST`, `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USER_NAME`, and `SMTP_PASSWORD`
Proof: `bin/rspec spec/config/mailer_environment_spec.rb -e "README setup note names the mail and administrator env vars"`

## Screens (ui)

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| administration empty | `h1` `Administração`, sentence, labels, empty inputs, `Continuar` C10 | column `div.max-w-[28rem]` without `mx-auto`; label then input; inputs `w-full border border-rule bg-sheet`; `Continuar` `bg-caixa`; `main` has no `svg` C10 | spacing, colour, type weight |
| administration invalid | notices C11, C12, C13, C29; typed values stay | `[data-notice="error"]` after `h1` and before the sentence; name notice then email notice C13 | spacing, colour, type weight |
| administration confirmation | `h1` `Confirmar cadastro`, stripped name, normalized email, `Confirmar`, `Corrigir` C14 | name inside `.border-b.border-rule`, email follows; `flex-wrap` group with `Confirmar` (`bg-caixa`, posts `/administration/confirm`) then `Corrigir` (`a` to `/administration`, `border-ink`) C14 | spacing, colour, type weight |
| administration success | `E-mail enviado para …`, record, `Cadastrar outra organização` C16; no name/email inputs C28 | record under the sentence; name inside `.border-b.border-rule`; no `[data-notice="error"]`; button posts `/administration/another` with `border-ink` C16 | spacing, colour, type weight |
| administration mail failure | notice `O cadastro foi gravado, mas o e-mail não saiu.`, record, `Reenviar e-mail`, `Cadastrar outra organização` C21; no name/email inputs C28 | `[data-notice="error"]` after `h1`; `flex-wrap` group with `Reenviar e-mail` (`bg-caixa`, posts `/administration/mail`) then `Cadastrar outra organização` (`border-ink`, posts `/administration/another`) C21 | spacing, colour, type weight |
| header, no focused organization | `Fechamento mensal`, one `Sair`, none of `Início` `Documentos` `Configuração` `Administração` C34 | `Sair` submits `DELETE /session` and includes `text-caixa` C34 | spacing, colour, type weight; the 640px wrap breakpoint |
| header, administrator coordinator | `Administração` after `Configuração`, one `Sair` C35 | `a[href="/administration"]` includes `text-ink` and follows the `/setup` link; ancestor includes `flex-wrap` C35 | spacing, colour, type weight; the 640px wrap breakpoint |
| header, administrator submitter | `Início`, `Documentos`, `Administração`, `Sair`; no `Configuração` C37 | `Administração` follows the `/supporting_documents` link C37 | spacing, colour, type weight; the 640px wrap breakpoint |
| header, coordinator who is not the administrator | `Início`, `Documentos`, `Configuração`, `Sair`; no `Administração` C36 | no `a[href="/administration"]` C36 | spacing, colour, type weight |

## Swept

- validation: C11, C12, C13, C29
- failure modes: C21, C26, C27
- idempotency and retry: C20, C22, C43
- authorization: C1, C4, C6, C8, C9, C44, C45
- concurrency and ordering: C30
- data lifecycle: C24, C25, C28
- external-dependency failure: C21, C23 - SMTP. Google unverified and OmniAuth failure stay on `/login` (C5, existing `OmniauthCallbacksController#failure`)
- state transitions: C14, C16, C20, C21, C22, C24, C25, C29, C30
- observability: n/a - the source names no log, metric, or trace; the person sees the notice in C21

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| OperatorAuthenticator outcomes this cut adds (7) | no Account allowlisted C1 · coordinator Access allowlisted C2 · pending Invite allowlisted C3 · other email C4 · unverified allowlisted C5 · blank env C6 · existing Account zero Access allowlisted C45 | - |
| allowlist env spelling (2) | exact `seller@example.com` C1 · mixed-case `Seller@Example.com` C44 | - |
| `ADMINISTRATOR_EMAIL` blank forms (2) | unset C6 · `""` C6 | - |
| administration routes when signed out (5) | `GET /administration` C8 · `POST /administration` C8 · `POST /administration/confirm` C8 · `POST /administration/mail` C8 · `POST /administration/another` C8 | - |
| administration routes when not the administrator (2 callers × 5 routes) | other email C9 · blank env C9, each over the five routes in C8 | - |
| `POST /administration` rejection notices (4) | blank name C11 · invalid email C12 · both, name then email C13 · taken name C29 | - |
| confirm outcomes (7) | new Account C16 · existing Account C17 · own email focuses new org C18 · other email leaves focus C19 · no pending C20 · `deliver_now` raises C21 · lost unique name C30 | - |
| `register_coordinator` (4) | new Account C16 · existing Account C17 · raise before commit C26 · duplicate lower name C27 | - |
| duplicate name spellings (2) | `ONG Norte` C27 · `ong norte` C27 | - |
| resend outcomes (3) | delivery succeeds C22 · `deliver_now` raises C23 · no result C43 | - |
| sign-out session keys (2) | pending, no Organization C25 · result, Organization remains C25 | - |
| welcome sentences (2) | one coordinator Access C32 · two or more C33 | - |
| header variants (4) | no focus C34 · administrator coordinator C35 · coordinator not allowlisted C36 · administrator submitter C37 | - |
| SMTP settings (3) | address and port C39 · address and blank port `587` C39 · blank address, settings absent C39 | - |
| mail host assemblies (3) | `config/environments/development.rb` C40 · `config/environments/production.rb` C40 · booted test process C38 | - |
| `raise_delivery_errors` assemblies (2) | development C38 · production C38 | - |
| designed screens (9) | administration empty C10 · invalid C11 C12 C13 C29 · confirmation C14 · success C16 · mail failure C21 · header no focus C34 · header administrator coordinator C35 · header administrator submitter C37 · header coordinator C36 | - |

- Claims naming a status code, route, or response shape: C1–C9, C11–C16, C18–C25, C29, C30, C43, C44, C45 - each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~5k + S2 ~9k + S3 ~6k + S4 ~1k + S5 ~1k + S6 ~4k = ~26k token floor, plus the task and the design already read (~13k). All six slices stay under 150k. No split. One batch.

Batch closed. Checks C1–C45 are on `5e8e030..HEAD`. No mid-build clarification. Nothing abandoned.
