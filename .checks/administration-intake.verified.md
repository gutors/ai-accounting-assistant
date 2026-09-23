# Administration intake Verification

**Verdict**: FAIL
**Profile**: ui
**Diff range**: `5e8e030..a9e201b`, plus the uncommitted working tree: `.checks/administration-intake.md`, `spec/requests/administration_spec.rb`, `spec/models/organization_spec.rb`, `spec/models/operator_authenticator_spec.rb`
**Round**: 3 - scoped
**Verifier**: independent sub-agent (author != verifier)

Scoped to the fix diff and to every round-2 verdict that was not PASS. Proofs re-ran once against this working tree. Carried rows say so. This is round 3 of 3; the two gaps below were outside the round-2 fix and are still uncovered.

The handoff says the user asked to keep the success sentence outside the ruled block and inside the 28rem column (C16), and to put the mail-failure notice immediately before that record inside the same column (C21, C47). The uncommitted diff does that: C16, C21, and C47 now say so, and `spec/requests/administration_spec.rb` asserts those positions. That match is not the proof. The proofs are the examples below.

## Binding sources

Step 1 re-judged success, mail failure, and confirmation (C46's claim text is the one round 2 already passed; its lines moved). Other screen rows are carried from the round-2 report.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.design/administration-intake.md` screen `administration` | yes — file in the repo, this round | none on the renegotiated success and mail-failure placement. The drawing puts the sentence above the ruled record, and the notice under the title and above that record, inside the 28rem column | invalid `422` still does not assert the column; submitter header still does not assert `text-ink` or `flex-wrap`. Carried from round 2; this diff does not touch them |
| `.tasks/administration-intake.md` | yes — criteria 1–41. Not a second design. Carried: not binding | none. Tightened C16 and C21 add the design's placement on top of criteria 16 and 21 | — |
| issue #62 | yes — `gh issue view 62`, this round. Carried: not binding | none. The sale opens `/administration`; construction does not answer #63 | — |
| issue #63 | yes — `gh issue view 63`, this round. Carried: not binding | none. Mailbox, subject, and resend-with-no-result stay open. C42 and C43 are the holding answers only | — |
| `DESIGN.md` | yes — short form at 28rem, caixa, margem, wrap below 640px. Carried: not a second composition | none | spacing, colour, and type weight stay in the checklist's per-screen exemption |
| `lib/tasks/coordinator.rake` | yes — lines 11–14, no `rescue`. Carried: not binding | none | — |
| `app/models/operator_authenticator.rb` | yes — allowlisted branch at lines 27–31. Carried: not binding | none | — |
| `app/controllers/application_controller.rb` | yes — `sign_in` at line 130 stores `organization&.id`. Carried: not binding | none | — |
| `app/views/shared/_notice.html.erb` | yes — `[data-notice="error"]` with `border-l-[3px] border-margem`. Carried: not binding | none | the 3px border stays in the enumerated spacing exemption |
| `config/environments/production.rb` | yes — `raise_delivery_errors = true` at line 53, `MailerEnvironment.apply!` at line 56. Carried: not binding | none | — |

Screen enumeration:

- **empty** — carried from round 2. `h1` `Administração`, sentence, labels then empty inputs, `Continuar`, no error notice, column class, no `svg` in `main`. C10.
- **invalid** — carried from round 2. Notices after `h1` and before the sentence, name then email, typed values stay, taken-name copy. C11, C12, C13, C29. The design says the form column stays 28rem and left-aligned. The `422` examples still do not assert `max-w-[28rem]`. `AdministrationController#create` renders `:show` (`app/controllers/administration_controller.rb:13`), and C10 asserts that wrapper on the empty GET, so a missing class on the shared wrapper fails C10. Nothing asserts the column on the `422` body.
- **confirmation** — carried from round 2. C46's claim is unchanged. `h1` `Confirmar cadastro`, labels and values, ruling line, `Confirmar` then `Corrigir`, column class. C14, C46. Citations refreshed: `spec/requests/administration_spec.rb:195-203`.
- **success** — re-judged. The sentence is a `p` inside `div.max-w-[28rem]` without `mx-auto`, that `p`'s next element is `.border-b.border-rule`, and that ruled element does not contain the sentence. The email row follows. C16. The round-2 gap (sentence not proven outside the ruled block; record not proven inside the column) is covered.
- **mail failure** — re-judged. The notice is inside `div.max-w-[28rem]` without `mx-auto`, and its next element is `.border-b.border-rule`. The email row follows. C21, C47. The round-2 gap (notice not proven before the record; record not proven inside the column) is covered.
- **header, no focus** — carried from round 2. `Fechamento mensal`, one `Sair` (`text-caixa`, `DELETE /session`), nav labels absent. C34.
- **header, administrator coordinator** — carried from round 2. `Início`, `Documentos`, `Configuração`, `Administração` (`text-ink`) after `Configuração`, one `Sair`, `flex-wrap`. C35.
- **header, administrator submitter** — carried from round 2. Prose, not a separate drawing: ink link, after `Documentos` when `Configuração` is absent. C37 (`spec/requests/layout_spec.rb:92-98`) asserts order, absence of `Configuração`, and `Sair`. It does not assert `text-ink` or `flex-wrap`. `layout_spec.rb` is not in this diff. The same `link_to` and `nav` serve the coordinator header (`app/views/layouts/_header.html.erb:13` and `:20`), so C35 locks those classes on that render. The submitter render still has no assertion.
- **header, coordinator who is not the administrator** — carried from round 2. No `Administração`. C36. `flex-wrap` is not asserted on this render. The 640px breakpoint stays in the checklist's enumerated exemption.

No blanket visual exemption. Spacing, colour, and type weight are named per screen.

## Checks

Proof batch (one invocation, working tree): `bin/rspec spec/requests/omniauth_callbacks_spec.rb spec/models/operator_authenticator_spec.rb spec/requests/administration_spec.rb spec/models/organization_spec.rb spec/tasks/coordinator_bootstrap_spec.rb spec/mailers/coordinator_welcome_mailer_spec.rb spec/requests/layout_spec.rb spec/config/mailer_environment_spec.rb --format documentation` — exit 0, 109 examples, 0 failures. Every example name below appears in that output.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | allowlisted callback creates the Account and redirects to `/administration` | both named examples in the batch, exit 0 | `spec/requests/omniauth_callbacks_spec.rb:200-203` — `expect(session[:account_id]).to eq(account.id)` and `expect(response).to redirect_to("/administration")`; `spec/models/operator_authenticator_spec.rb:72-74` — `expect(result.status).to eq(:signed_in)` and `expect(result.organization).to be_nil` | PASS — carried from round 2; lines re-read, unchanged |
| C2 | allowlisted coordinator stays on `ONG Norte` and redirects home | both named examples, exit 0 | `spec/requests/omniauth_callbacks_spec.rb:219-221` — `expect(session[:organization_id]).to eq(organization.id)` and `expect(response).to redirect_to("/")`; `spec/models/operator_authenticator_spec.rb:96` — `expect(result.organization).to eq(organization)` | PASS — carried from round 2 |
| C3 | pending Invite is accepted and the callback redirects home | both named examples, exit 0 | `spec/requests/omniauth_callbacks_spec.rb:234-237` — access kind `"coordinator"`, Invite `be_nil`, `redirect_to("/")` | PASS — carried from round 2 |
| C4 | other email persists nothing and the denied page names the refusal | named example, exit 0 | `spec/requests/omniauth_callbacks_spec.rb:248-251` — `redirect_to("/denied")` then `expect(response.body).to include("Você não foi convidado a usar este sistema.")` | PASS — carried from round 2 |
| C49 | other email is `:denied` and persists no Account | named example, exit 0 | `spec/models/operator_authenticator_spec.rb:121-122` — `expect(result.status).to eq(:denied)` and `expect(Account.find_by(email: "other@example.com")).to be_nil` | PASS — carried from round 2; lines re-read, unchanged |
| C5 | unverified allowlisted auth persists nothing and redirects to `/login` | both named examples, exit 0 | `spec/requests/omniauth_callbacks_spec.rb:261-263` — `redirect_to("/login")` and Account `be_nil`; model `:unverified` at `spec/models/operator_authenticator_spec.rb:131` | PASS — carried from round 2 |
| C6 | unset and blank allowlist deny and redirect to `/denied` | both named examples, exit 0 | `spec/requests/omniauth_callbacks_spec.rb:267-275` — `[ nil, "" ]` each `redirect_to("/denied")`; model `:denied` at `spec/models/operator_authenticator_spec.rb:141` | PASS — carried from round 2 |
| C7 | coordinator callback redirects home and the body names `ONG Norte` | named example, exit 0 | `spec/requests/omniauth_callbacks_spec.rb:13-20` — `redirect_to("/")`, body includes `ONG Norte`, excludes the refusal sentence | PASS — carried from round 2 |
| C44 | mixed-case allowlist is the same door as C1 | both named examples, exit 0 | `spec/requests/omniauth_callbacks_spec.rb:290-292` — `session[:organization_id]` nil and `redirect_to("/administration")` | PASS — carried from round 2 |
| C45 | existing zero-Access Account is reused and sent to `/administration` | both named examples, exit 0 | `spec/requests/omniauth_callbacks_spec.rb:298-309` — `not_to change(Account, :count)`, `google_uid` `uid-seller`, `redirect_to("/administration")` | PASS — carried from round 2 |
| C8 | signed-out administration routes redirect to `/login` | named example, exit 0 | `spec/requests/administration_spec.rb:64-65` — each route `have_http_status(:found)` and `redirect_to("/login")` | PASS — carried from round 2; citation refreshed |
| C9 | non-administrator and blank allowlist return an empty `404` | named example, exit 0 | `spec/requests/administration_spec.rb:80-81` — `[ "seller@example.com", nil, "" ]` over the five routes, `have_http_status(:not_found)` and `expect(response.body).to eq("")` | PASS — carried from round 2; citation refreshed |
| C10 | empty form copy, column class, and field classes | named example, exit 0 | `spec/requests/administration_spec.rb:37-50` — `max-w-[28rem]` without `mx-auto`, labels in order, following inputs empty with `w-full border border-rule bg-sheet`, `Continuar` `bg-caixa` | PASS — carried from round 2; citation refreshed |
| C11 | blank name is `422` and writes nothing | named example, exit 0 | `spec/requests/administration_spec.rb:115-120` — `:unprocessable_content`, notices `eq([ "Informe o nome da organização." ])`, pending `be_nil` | PASS — carried from round 2; citation refreshed |
| C12 | invalid email is `422` and writes nothing | named example, exit 0 | `spec/requests/administration_spec.rb:130-135` — notices `eq([ "Informe um e-mail válido." ])`, field value `nao-e-email` | PASS — carried from round 2; citation refreshed |
| C13 | both notices, name then email, between `h1` and the sentence | named example, exit 0 | `spec/requests/administration_spec.rb:149-155` — `name_at < email_at`, `Administração` before the name notice, email notice before the sentence | PASS — carried from round 2; citation refreshed |
| C14 | confirmation copy, button order, and pending hash | named example, exit 0 | `spec/requests/administration_spec.rb:167-186` — `h1` `Confirmar cadastro`, buttons `eq([ "Confirmar", "Corrigir" ])`, pending `{ "name" => "ONG Norte", "email" => "coordenador@exemplo.org" }` | PASS — carried from round 2; citation refreshed |
| C46 | confirmation column and record labels | named example, exit 0 | `spec/requests/administration_spec.rb:195-203` — column `max-w-[28rem]` without `mx-auto`; ruled text includes `Nome da organização` and `ONG Norte`; next element includes `E-mail do coordenador` and `coordenador@exemplo.org` | PASS — carried from round 2; citation refreshed |
| C15 | pending GET fills the form | named example, exit 0 | `spec/requests/administration_spec.rb:212-215` — `h1` `Administração`, input values `ONG Norte` and `coordenador@exemplo.org` | PASS — carried from round 2; citation refreshed |
| C16 | success sentence is a `p` inside the 28rem column, outside the ruled record, and the rows are written | named example, exit 0 | `spec/requests/administration_spec.rb:243-255` — `administration_column`, sentence `p` inside it, `sentence.next_element` includes `border-b` and `border-rule`, that element `not_to include("E-mail enviado para")` and includes `Nome da organização` and `ONG Norte`, next element includes the email label and `coordenador@exemplo.org`. Rows at `:227-235` — redirect, coordinator Access, `mail_sent` true | PASS — re-judged. The round-2 order-only assertion is replaced |
| C17 | confirm reuses an Account | both named examples, exit 0 | `spec/requests/administration_spec.rb:271` — `not_to change(Account, :count)`; model `change(Account, :count).by(0)` at `spec/models/organization_spec.rb:347` | PASS — carried from round 2; request citation refreshed |
| C18 | own email focuses the new organization | named example, exit 0 | `spec/requests/administration_spec.rb:293-294` — `session[:organization_id]` equals the new id and not `ONG Sul` | PASS — carried from round 2; citation refreshed |
| C19 | another email leaves focus | named example, exit 0 | `spec/requests/administration_spec.rb:308` — `expect(session[:organization_id]).to eq(previous.id)` | PASS — carried from round 2; citation refreshed |
| C20 | confirm without pending writes nothing and keeps the result | named example, exit 0 | `spec/requests/administration_spec.rb:319-325` — counts unchanged, `redirect_to("/administration")`, result `eq(result)` | PASS — carried from round 2; citation refreshed |
| C21 | mail failure keeps the rows, and the notice sits in the 28rem column immediately before the ruled record | named example, exit 0 | `spec/requests/administration_spec.rb:337-354` — `mail_sent` false, notice text inside `administration_column`, `h1` index before the notice, `notice.next_element` includes `border-b` and `border-rule`. Buttons `eq([ "Reenviar e-mail", "Cadastrar outra organização" ])` at `:357-367` | PASS — re-judged. Round 2 did not prove notice-before-record or the column |
| C47 | mail-failure record is the notice's next element, inside the 28rem column | named example, exit 0 | `spec/requests/administration_spec.rb:378-387` — notice from `administration_column`, `notice.next_element` includes `border-b` and `border-rule` and `Nome da organização` and `ONG Norte`; next element includes the email label and `coordenador@exemplo.org` | PASS — re-judged. Round 2 proved the labels only |
| C22 | resend delivers another welcome and sets `mail_sent` | named example, exit 0 | `spec/requests/administration_spec.rb:399-406` — `Organization` count unchanged, `deliveries.size` 1, `mail_sent` true, body includes `E-mail enviado para coordenador@exemplo.org.` | PASS — carried from round 2; citation refreshed |
| C23 | resend keeps `mail_sent` false when delivery raises | named example, exit 0 | `spec/requests/administration_spec.rb:416-422` — `mail_sent` false and body includes the failure notice | PASS — carried from round 2; citation refreshed |
| C24 | another registration clears the result and shows the empty form | named example, exit 0 | `spec/requests/administration_spec.rb:444-449` — result `be_nil`, organization still found, `expect_empty_form` | PASS — carried from round 2; citation refreshed |
| C25 | sign-out drops pending and result | both named examples, exit 0 | `spec/requests/administration_spec.rb:462-465` — `redirect_to("/login")`, both keys nil; confirmed row remains at `:485` | PASS — carried from round 2; citation refreshed |
| C43 | resend without a result redirects and delivers nothing | named example, exit 0 | `spec/requests/administration_spec.rb:429-434` — counts and deliveries unchanged, `redirect_to("/administration")` | PASS — carried from round 2; citation refreshed |
| C26 | raise before commit rolls the write back and sends no mail | named example, exit 0 | `spec/models/organization_spec.rb:355-360` — `raise_error(ActiveRecord::RecordInvalid)`, org nil, account and access counts 0, deliveries empty | PASS — carried from round 2; lines re-read, unchanged |
| C27 | `ONG Norte` and `ong norte` raise `RecordNotUnique` | named example, exit 0 | `spec/models/organization_spec.rb:368-375` — both names `raise_error(ActiveRecord::RecordNotUnique)`, counts unchanged, no `outro%@exemplo.org` account | PASS — carried from round 2; lines re-read, unchanged |
| C28 | success and mail-failure have no name or email inputs | named example, exit 0 | `spec/requests/administration_spec.rb:499-511` — both screens `input[name="name"]` and `input[name="email"]` `be_nil`; stored name and email unchanged | PASS — carried from round 2; citation refreshed |
| C29 | `ong norte` with spaces is `422` and stores no pending | named example, exit 0 | `spec/requests/administration_spec.rb:522-528` — notice `Já existe uma organização com esse nome.`, typed value `  ong norte  `, pending `be_nil` | PASS — carried from round 2; citation refreshed |
| C48 | `  ONG NORTE  ` is `422` and `register_coordinator` raises | both named examples, exit 0 | `spec/requests/administration_spec.rb:539-545` — same notice and typed value `  ONG NORTE  `; `spec/models/organization_spec.rb:384-390` — `raise_error(ActiveRecord::RecordNotUnique)`, counts unchanged, no account `outro@exemplo.org` | PASS — carried from round 2; request citation refreshed, model lines unchanged |
| C30 | one organization survives two overlapping confirms | named example, exit 0 | `spec/requests/administration_spec.rb:569-576` — lower-name count `eq(1)`, loser status 422, body includes the taken-name notice, loser result nil, one account and one access, one delivery | PASS — carried from round 2; citation refreshed |
| C31 | bootstrap of `ong norte` persists nothing and exits non-zero | named example, exit 0 | `spec/tasks/coordinator_bootstrap_spec.rb:66-68` — rake source includes the abort string and `Organization.create!`, does not include `rescue`; `:85-88` status not 0 and counts unchanged. Source opened at `lib/tasks/coordinator.rake:11-14` | PASS — carried from round 2 |
| C32 | first-organization welcome body and from | named example, exit 0 | `spec/mailers/coordinator_welcome_mailer_spec.rb:18-22` — `text/plain`, body equals the `está pronta` sentence, from `venda@example.com` | PASS — carried from round 2 |
| C33 | second-organization welcome body and from | named example, exit 0 | `spec/mailers/coordinator_welcome_mailer_spec.rb:36-40` — body equals the `foi adicionada` sentence, from `venda@example.com` | PASS — carried from round 2 |
| C42 | subject `Cadastro da organização ONG Norte` on both sentences | both named examples, exit 0 | `spec/mailers/coordinator_welcome_mailer_spec.rb:23` and `:40` — `expect(message.subject).to eq("Cadastro da organização ONG Norte")` | PASS — carried from round 2 |
| C34 | header without focus shows the product name and one `Sair` | named example, exit 0 | `spec/requests/administration_spec.rb:97-106` — `Fechamento mensal`, one `Sair` with `text-caixa`, form action `/session`, method `delete`, nav labels absent | PASS — carried from round 2; citation refreshed |
| C35 | administrator coordinator link after `Configuração` | named example, exit 0 | `spec/requests/layout_spec.rb:49-59` — links end with `Administração` `/administration`, class includes `text-ink`, a `flex-wrap` ancestor, one `Sair` | PASS — carried from round 2; file not in the fix diff |
| C36 | non-administrator coordinator has no `Administração` link | named example, exit 0 | `spec/requests/layout_spec.rb:71-75` — `/`, `/supporting_documents`, `/setup` present, `a[href="/administration"]` nil, `Sair` present | PASS — carried from round 2; file not in the fix diff |
| C37 | administrator submitter link after `Documentos` | named example, exit 0 | `spec/requests/layout_spec.rb:92-98` — links `eq` Início, Documentos, Administração; no `Configuração`; `Sair` present. No `text-ink` and no `flex-wrap` | PASS for the check as written. The ink link and wrap are uncovered — see Binding sources |
| C38 | delivery errors raised in development and production; test delivery is `:test` | named example, exit 0 | `spec/config/mailer_environment_spec.rb:16-19` — both env files include `raise_delivery_errors = true`; booted `delivery_method` `:test` and host `example.com`. Assemblies opened this round: `config/environments/development.rb:33`, `config/environments/production.rb:53` | PASS — carried from round 2; assemblies re-opened |
| C39 | production SMTP follows `SMTP_ADDRESS`, blank port `587`, blank address applies nothing | named example, exit 0 | `spec/config/mailer_environment_spec.rb:33-52` — settings hash with port `2525` and `authentication: :plain`, blank port `587`, blank address `smtp_settings` nil. `config/environments/production.rb:56` calls `MailerEnvironment.apply!`. Settings built at `config/mailer_environment.rb:8-14`, opened this round | PASS — carried from round 2; assembly re-opened |
| C40 | development and production host is `MAILER_HOST` | named example, exit 0 | `spec/config/mailer_environment_spec.rb:59-63` — both env files include `MailerEnvironment.apply!`; host `fechamento.example`. Assemblies opened this round: `config/environments/development.rb:39`, `config/environments/production.rb:56` | PASS — carried from round 2; assemblies re-opened |
| C41 | README names the env vars | named example, exit 0 | `spec/config/mailer_environment_spec.rb:69-71` — README includes each of the seven names. Seen at `README.md:38` | PASS — carried from round 2 |

## Coverage

Designed screens recomputed from `.design/administration-intake.md` this round. Other rows carried from round 2: the fix added no member to those sets. Header variants still list the submitter gap, carried from round 2, because `layout_spec.rb` is not in the diff.

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| OperatorAuthenticator outcomes this cut adds (7) | no Account C1 · coordinator Access C2 · pending Invite C3 · other email C4 C49 · unverified C5 · blank env C6 · existing Account zero Access C45 | — carried from round 2 |
| allowlist env spelling (2) | `seller@example.com` C1 · `Seller@Example.com` C44 | — carried from round 2 |
| `ADMINISTRATOR_EMAIL` blank forms (2) | unset and `""` both asserted in C6 | — carried from round 2 |
| administration routes when signed out (5) | the five routes in C8 | — carried from round 2 |
| administration routes when not the administrator (2 callers × 5 routes) | other email and blank env, each over the five routes, C9 | — carried from round 2 |
| `POST /administration` rejection notices (4) | blank name C11 · invalid email C12 · both C13 · taken name C29 | — carried from round 2. The 28rem column on these `422` bodies is a screen gap, not a member of this set |
| confirm outcomes (7) | C16 · C17 · C18 · C19 · C20 · C21 · C30 | — re-checked. C16 and C21 still name those outcomes; the new assertions add placement, not a new outcome |
| `register_coordinator` (4) | C16 · C17 · C26 · C27 | — carried from round 2 |
| duplicate name spellings (3) | `ONG Norte` and `ong norte` C27 · `  ONG NORTE  ` C48 | — carried from round 2 |
| resend outcomes (3) | C22 · C23 · C43 | — carried from round 2 |
| sign-out session keys (2) | pending C25 · result C25 | — carried from round 2 |
| welcome sentences (2) | C32 · C33 | — carried from round 2 |
| header variants (4) | C34 · C35 · C36 · C37 | submitter `text-ink` and `flex-wrap` — carried from round 2 |
| SMTP settings (3) | port `2525` · blank port `587` · blank address C39 | — carried from round 2 |
| mail host assemblies (3) | `development.rb:39` · `production.rb:56` · booted test host C38 | — assemblies re-opened this round |
| `raise_delivery_errors` assemblies (2) | `development.rb:33` · `production.rb:53` | — assemblies re-opened this round |
| designed screens (7 drawings) | empty C10 · invalid C11 C12 C13 C29 · confirmation C14 C46 · success C16 · mail failure C21 C47 · header no focus C34 · header administrator C35 | invalid column class on the `422` body. Submitter and non-admin headers are prose, not extra drawings; submitter `text-ink` and `flex-wrap` stay uncovered. Success column containment and mail-failure notice-before-record are now proven |

Startup assemblies were opened this round, not inferred from the green spec.

## Test policy rows

Round 2 met every row. The unmet set is empty, so those verdicts carry. The rows that classify `organization.rb` and the administration requests were re-checked against the new examples: they still assert the same members. The new C16, C21, and C47 text adds placement inside examples that already existed.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `operator_authenticator.rb`, `organization.rb` `register_coordinator`, `administration_controller.rb`, `coordinator_welcome_mailer.rb`, `administrator?` | model or mailer, and a request spec | met — re-checked for `organization.rb` and the administration requests. Authenticator members at `spec/models/operator_authenticator_spec.rb` and `spec/requests/omniauth_callbacks_spec.rb` (carried). `register_coordinator` members at `spec/models/organization_spec.rb` and confirm at `spec/requests/administration_spec.rb`. Welcome sentences at the mailer (carried) |
| Decides, not reached across a boundary | unique index `index_organizations_on_lower_name` | model | met — carried from round 2. C27 and C48 still assert `RecordNotUnique` for each spelling. Schema re-read: `db/schema.rb:175` index `lower((name)::text)` |
| Entry point that decides nothing | administration routes, `coordinator:bootstrap` | request, or the rake boundary for the task | met — carried from round 2. C8 and C9 still cover who may call; C31 still runs `coordinator:bootstrap` |
| Instrumentation / pass-through | `sign_in` storing `organization&.id` | consumer | met — carried from round 2. C1 and C45 still assert `session[:organization_id]` nil at the callback. `sign_in` re-read at `app/controllers/application_controller.rb:130` |

## Swept

Carried from round 2. The fix does not touch these constraints.

- validation, failure modes, idempotency, authorization, concurrency, data lifecycle, and state transitions cite checks that exist and whose assertions are in the table above.
- external-dependency failure: C21 and C23. `OmniauthCallbacksController#failure` still `redirect_to login_path` (`app/controllers/omniauth_callbacks_controller.rb:19-20`, re-read this round). The example `OmniAuth failure redirects to /login with no session` ran in the batch.
- observability: n/a in the checklist. Nothing in this diff adds a log the source required.
- Rows marked out of scope in the checklist are the approved boundary. Not re-opened.

## Faults injected

Scratch worktree `/Users/gutors/Developer/ai-accounting-assistant-verify-r3` at `a9e201b`, with the three uncommitted specs copied in. The committed tree does not contain the tightened assertions. Real-tree `git status --porcelain` before `git worktree add` matched the dispatch baseline. After `git worktree remove --force`, porcelain matched that baseline and `app/views/administration/show.html.erb` had no diff. The scratch is gone.

| Mutation | Location | Killed |
|---|---|---|
| success sentence moved inside `.border-b.border-rule`, before `Nome da organização` | scratch `app/views/administration/show.html.erb` | yes — `confirm creates the organization and shows the sent mail` failed `expect(ruled["class"]).to include("border-b")` (`expected "font-medium" to include "border-b"`) |
| mail-failure notice rendered after the buttons | scratch `app/views/administration/show.html.erb` | yes — `confirm keeps the rows when deliver_now raises` failed `expect(ruled["class"]).to include("border-b")` (`undefined method '[]' for nil`) |
| result branch closed out of `div.max-w-[28rem]` | scratch `app/views/administration/show.html.erb` | yes — `confirm creates the organization and shows the sent mail` failed `expect(sentence).not_to be_nil` |

## Gate

No spec-lean validator. This is tlc-implement. The proof batch above: 109 examples, 0 failures. All 49 checks have a located assertion and passed. The three round-2 mutants are killed.

The work is not done. Two arrangements the design decides are still uncovered, carried from round 2, and this diff does not cover them:

1. Invalid `422` does not assert the 28rem column.
2. The submitter header does not assert `text-ink` or `flex-wrap`.
