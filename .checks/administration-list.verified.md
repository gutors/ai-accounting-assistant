# Administration list Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 332d5b7..afaa369
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

Committed range is unchanged. Proofs ran on the working tree: `afaa369` plus the uncommitted fix in `app/views/administration/show.html.erb`, `app/views/administration/_organization.html.erb`, `spec/requests/administration_spec.rb`, and `.checks/administration-list.md`. Other dirty paths are not this fix.

Round 1 (`afaa369`) failed on screen coverage. The user renegotiated C2, C26, and C30 and added C39. Those four were re-read. Everything else is carried from `afaa369`.

## Binding sources

Re-opened this round: `.design/administration-list.md` for rest-with-organizations, invalid registration, the name field, and the name confirmation, and the section-heading rule in `DESIGN.md` ("Section headings take a 1px ruling underline"). Other sources are carried from `afaa369`.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.tasks/administration-list.md` | carried from `afaa369` | none | — |
| `.design/administration-list.md` | yes — file in the repo, this round, for the four screens the fix touched | none — C2, C26, C30, and C39 match the drawing and the notice order | none on those screens. `Corrigir` on an email and `Remover` stay the next stage |
| issue #63 | carried from `afaa369` | none | email correction, removal, and home invites — next stage |
| `.design/administration-intake.md` | carried from `afaa369` | none | — |
| `docs/adr/0006-administration-intake.md` | carried from `afaa369` | none | — |
| `DESIGN.md` | yes — the section-heading rule, this round | none — the `Organizações` heading is `border-b border-rule` | — |
| `app/views/shared/_notice.html.erb` | carried from `afaa369` | none | — |
| `app/models/month.rb` | carried from `afaa369` | none | — |
| `app/controllers/application_controller.rb` | carried from `afaa369` | none | — |

Per screen, this round, what the design decides that a selector reaches:

- **administration, rest, with organizations.** Form first, heading `Organizações` with a ruling line under it, stored-name order, `Corrigir nome` then coordinator emails, no submitter, no `Corrigir`, no `Remover`, row rule, `flex-wrap` inside the column. C2 requires `border-b` and `border-rule` on the heading (`app/views/administration/show.html.erb:30`) and on the row (`app/views/administration/_organization.html.erb:1`). `Corrigir` and `Remover` in the drawing are the next stage.
- **administration, invalid registration.** Carried placement under the `h1` is C5. The design adds one notice per failed check, in the order blank name, invalid email, taken name. C39 is the pair the code can produce together: `Informe um e-mail válido.` then `Já existe uma organização com esse nome.` Notice colour and the field border stay inside the per-screen exemption.
- **administration, name field.** The prose says `Corrigir nome` opens the stored name in one field and the email lines stay. The drawing is that label, the name in the field, `[ Continuar ]   Cancelar` on one line, then the email as text. C26 requires the label `Nome da organização` on that field, `Continuar` then `Cancelar` in one `flex-wrap` group, `Continuar` submitting the form that contains the field, and the email after that group. The drawing's `Corrigir` and `Remover` are the next stage. The drawing's first line repeats the stored name; the prose puts that name in the field, and C26 asserts the field value.
- **administration, name confirmation.** Label `Nome da organização`, then the new name, then `Nenhum e-mail será enviado.`, then `Confirmar` then `Corrigir`. The coordinator email is not in the drawing. C30 requires that order, the sentence not being an error notice, the email absent, and the `flex-wrap` button group.

The other screens are carried from `afaa369`. The per-screen exemption is spacing, colour, and type weight. That is not a blanket.

## Checks

Proofs re-ran as one invocation on the working tree: `bin/rspec spec/requests/administration_spec.rb spec/models/organization_spec.rb spec/mailers/coordinator_welcome_mailer_spec.rb --format documentation`. Exit 0. `83 examples, 0 failures`. Every example name below appeared in that output. An earlier invocation of the same command reported two `Account.create!` failures in `plant_coordinator` for the C14 and C15 examples; they did not reproduce, and this invocation is the proof.

C2, C26, C30, and C39 were re-read. The other verdicts are carried from `afaa369`. Citations in `spec/requests/administration_spec.rb` below the inserted example were refreshed; model and mailer lines did not move.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | empty `GET /administration` is the form in a 28rem column, no list | batch exit 0 | `spec/requests/administration_spec.rb:42-61` — `expect(page.at_css("h1").text.strip).to eq("Administração")`, labels `eq([ "Nome da organização", "E-mail do coordenador" ])`, `expect(column["class"]).not_to include("mx-auto")`, headings `eq([ "Administração" ])` | PASS — carried from `afaa369` |
| C2 | three organizations in stored-name order; heading and row use `border-b` and `border-rule`; `ONG Norte` emails omit the submitter | batch exit 0 | `spec/requests/administration_spec.rb:628-636` — heading class `include("border-b")` and `include("border-rule")`, ids `eq([ ama.id, norte.id, sul.id ])`, row class `include("flex-wrap")`, `include("border-b")`, `include("border-rule")`. `639-641` — `html.index("Corrigir nome") < html.index("ana@exemplo.org")` then `zoe@exemplo.org`. `647-649` — `not_to include("Corrigir")` and `"Remover"`. `spec/models/organization_spec.rb:331` — `expect(organization.coordinator_emails).to eq([ "ana@exemplo.org", "zoe@exemplo.org" ])` | PASS |
| C3 | nine signed-out routes are `302` to `/login` and write nothing | batch exit 0 | `spec/requests/administration_spec.rb:11-22` lists the nine paths. `74-77` — `expect(response).to have_http_status(:found)`, `redirect_to("/login")`, `not_to change` the five counts | PASS — carried from `afaa369` |
| C4 | other email, unset env, and blank env are `404` with an empty body | batch exit 0 | `spec/requests/administration_spec.rb:84-91` — `[ "seller@example.com", nil, "" ]` over `administration_routes`, `have_http_status(:not_found)`, `expect(response.body).to eq("")` | PASS — carried from `afaa369` |
| C5 | blank name is `422`, one notice under the `h1`, nothing written | batch exit 0 | `spec/requests/administration_spec.rb:126-133` — `have_http_status(:unprocessable_content)`, notices `eq([ "Informe o nome da organização." ])`, `index("Administração") < index("Informe o nome da organização.")`, `session[:administration_pending]).to be_nil` | PASS — carried from `afaa369` |
| C6 | invalid email is `422` and the only notice | batch exit 0 | `spec/requests/administration_spec.rb:144-150` — notices `eq([ "Informe um e-mail válido." ])`, field values kept, pending `be_nil` | PASS — carried from `afaa369` |
| C7 | blank name then invalid email, in that order | batch exit 0 | `spec/requests/administration_spec.rb:165-171` — `expect(name_at).to be < email_at`, notices `eq([ "Informe o nome da organização.", "Informe um e-mail válido." ])` | PASS — carried from `afaa369` |
| C8 | `  ong norte  ` is `422` with the taken-name notice and no pending | batch exit 0 | `spec/requests/administration_spec.rb:554-561` — notices `eq([ "Já existe uma organização com esse nome." ])`, `h2` `eq("Organizações")`, pending `be_nil` | PASS — carried from `afaa369` |
| C9 | valid post renders confirmation on `Administração`, list at rest, pending stored | batch exit 0 | `spec/requests/administration_spec.rb:185-207` — `h1` `eq("Administração")`, body `not_to include("Confirmar cadastro")`, buttons `eq([ "Confirmar", "Corrigir" ])`, confirm action `eq("/administration/confirm")`, `border-ink`, pending `eq("name" => "ONG Norte", "email" => "coordenador@exemplo.org")`. Labels: `spec/requests/administration_spec.rb:219-223` — ruled text includes `"Nome da organização"` and the next block includes `"E-mail do coordenador"` | PASS — carried from `afaa369` |
| C10 | `GET` with pending fills the form and is not the confirmation | batch exit 0 | `spec/requests/administration_spec.rb:233-239` — name value `eq("ONG Norte")`, `at_css('form[action="/administration/confirm"]')).to be_nil`, row includes `"Corrigir nome"` | PASS — carried from `afaa369` |
| C11 | `Corrigir` returns the filled form and writes nothing | batch exit 0 | `spec/requests/administration_spec.rb:250-255` — `not_to change` counts, name value `eq("ONG Norte")`, email value `eq("coordenador@exemplo.org")` | PASS — carried from `afaa369` |
| C12 | confirm redirects, then the sent sentence sits on the row | batch exit 0 | `spec/requests/administration_spec.rb:267-294` — `redirect_to("/administration")`, result `eq("organization_id" => organization.id, "mail_sent" => true)`, subject `eq("Fechamento Mensal - Cadastro da Organização ONG Norte")`, sentence `p` `not_to be_nil` and `sentence["data-notice"]).to be_nil`, body `not_to include("Cadastrar outra organização")` | PASS — carried from `afaa369` |
| C13 | confirm reuses an Account | batch exit 0 | `spec/requests/administration_spec.rb:304-313` — `not_to change(Account, :count)`, coordinator access `eq(1)`, `Invite.count).to eq(0)`, row includes `"E-mail enviado para coordenador@exemplo.org."`. Model: `spec/models/organization_spec.rb:378-380` — `change(Account, :count).by(0)` | PASS — carried from `afaa369` |
| C14 | own email focuses the new organization | batch exit 0 | `spec/requests/administration_spec.rb:328-331` — `session[:organization_id]).to eq(created.id)`, header text `include("ONG Norte")` | PASS — carried from `afaa369` |
| C15 | another email leaves focus | batch exit 0 | `spec/requests/administration_spec.rb:345` — `expect(session[:organization_id]).to eq(previous.id)` | PASS — carried from `afaa369` |
| C16 | confirm without pending keeps the result | batch exit 0 | `spec/requests/administration_spec.rb:357-362` — `not_to change` counts and deliveries, `redirect_to("/administration")`, `session[:administration_result]).to eq(result)` | PASS — carried from `afaa369` |
| C17 | `deliver_now` raises, notice and `Reenviar e-mail` on `ONG Norte` only | batch exit 0 | `spec/requests/administration_spec.rb:378-397` — result `"mail_sent" => false`, notice text `eq("O cadastro foi gravado, mas o e-mail não saiu.")`, resend classes include `"bg-caixa"`, `"font-semibold"`, `"text-white"`, form action `eq("/administration/mail")`, `ONG Sul` `not_to include("Reenviar e-mail")` | PASS — carried from `afaa369` |
| C18 | resend delivers another welcome and clears the button | batch exit 0 | `spec/requests/administration_spec.rb:424-434` — `not_to change(Organization, :count)`, deliveries `eq(1)`, `mail_sent`).to be(true)`, row `not_to include("Reenviar e-mail")` | PASS — carried from `afaa369` |
| C19 | a raising resend records `mail_sent` false and shows the notice | batch exit 0 | `spec/requests/administration_spec.rb:444-451` — `not_to change(Organization, :count)`, `mail_sent`).to be(false)`, row includes the failure sentence. The example confirms successfully first, then raises on `POST /administration/mail`. `mail` does not branch on the previous flag; it sets `mail_sent` from `deliver_welcome` | PASS — carried from `afaa369` |
| C20 | resend with no result redirects and writes nothing | batch exit 0 | `spec/requests/administration_spec.rb:458-463` — `not_to change` counts and deliveries, `have_http_status(:found)`, `redirect_to("/administration")` | PASS — carried from `afaa369` |
| C21 | two confirms of the same lower name leave one organization; the loser is `422` | batch exit 0 | `spec/requests/administration_spec.rb:974-980` — count `eq(1)`, loser status `422`, body includes the taken-name notice, loser result `be_nil`, deliveries `eq(1)`. Model: `spec/models/organization_spec.rb:403` — `raise_error(ActiveRecord::RecordNotUnique)` for `"ong norte"` | PASS — carried from `afaa369`; citation refreshed |
| C22 | a later registration replaces the failure notice | batch exit 0 | `spec/requests/administration_spec.rb:665-667` — `ONG Norte` notice `be_nil` and `not_to include("Reenviar e-mail")`, `ONG Sul` includes `"E-mail enviado para sul@exemplo.org."` | PASS — carried from `afaa369`; citation refreshed |
| C23 | the sent sentence survives refresh | batch exit 0 | `spec/requests/administration_spec.rb:680` — row includes `"E-mail enviado para coordenador@exemplo.org."` | PASS — carried from `afaa369`; citation refreshed |
| C24 | first-organization welcome subject and body | batch exit 0 | `spec/mailers/coordinator_welcome_mailer_spec.rb:18-24` — body `eq("A organização ONG Norte está pronta. ...")`, `from` `eq([ "venda@example.com" ])`, subject `eq("Fechamento Mensal - Cadastro da Organização ONG Norte")`, deliveries `eq(1)` | PASS — carried from `afaa369` |
| C25 | second-organization welcome subject and body | batch exit 0 | `spec/mailers/coordinator_welcome_mailer_spec.rb:37-41` — body `eq("A organização ONG Norte foi adicionada à sua conta. ...")`, subject `eq("Fechamento Mensal - Cadastro da Organização ONG Norte")`, `from` `eq([ "venda@example.com" ])` | PASS — carried from `afaa369` |
| C26 | `Corrigir nome` shows the label on the stored name; `Continuar` then `Cancelar` share a `flex-wrap` group and `Continuar` submits that form | batch exit 0 | `spec/requests/administration_spec.rb:695-714` — input value `eq("ONG Norte")`, label text `eq("Nome da organização")` and `label["for"]` equals the field id, `form#name_correction_form` contains that field, submit `"Continuar"` includes `"bg-caixa"` and `submit["form"]` `eq("name_correction_form")`, parent class `include("flex-wrap")`, group controls `eq([ "Continuar", "Cancelar" ])`, `Cancelar` includes `"text-caixa"`, `"underline"`, `"underline-offset-2"`, `index("Cancelar") < index("coordenador@exemplo.org")` | PASS |
| C27 | `Cancelar` restores `ONG Norte` and sends nothing | batch exit 0 | `spec/requests/administration_spec.rb:731-741` — `not_to change` the name, deliveries `be_empty`, row includes `"Corrigir nome"`, name input `be_nil`, `organization.name).to eq("ONG Norte")` | PASS — carried from `afaa369`; citation refreshed |
| C28 | blank name correction is `422` and stays a field | batch exit 0 | `spec/requests/administration_spec.rb:751-759` — `have_http_status(:unprocessable_content)`, notices `eq([ "Informe o nome da organização." ])`, input value `eq("   ")`, row `not_to include("Nenhum e-mail será enviado.")`, name `eq("ONG Norte")` | PASS — carried from `afaa369`; citation refreshed |
| C29 | `ong sul` is `422`; `name_taken?(except:)` ignores the row being corrected | batch exit 0 | `spec/requests/administration_spec.rb:771-777` — notices `eq([ "Já existe uma organização com esse nome." ])`, input `eq("ong sul")`, stored name `eq("ONG Norte")`. `spec/models/organization_spec.rb:338-339` — `name_taken?("ong sul", except: norte)).to be(true)` and `name_taken?("ong norte", except: norte)).to be(false)` | PASS — carried from `afaa369`; citation refreshed |
| C30 | own lower name asks for confirmation, with the label, without the coordinator email, and writes nothing | batch exit 0 | `spec/requests/administration_spec.rb:790-806` — `have_http_status(:ok)`, error notices `be_empty`, `index("Nome da organização") < index("ong norte") < index("Nenhum e-mail será enviado.")`, row `not_to include("coordenador@exemplo.org")`, sentence `data-notice` `be_nil`, buttons `eq([ "Confirmar", "Corrigir" ])`, confirm action `eq("/administration/name/confirm")`, `border-ink`, `ONG Sul` includes `"Corrigir nome"` | PASS |
| C31 | confirm stores `ong norte`, does not call the writer, drops the sentence | batch exit 0 | `spec/requests/administration_spec.rb:820-830` — `expect(PackageArchiveWriter).not_to receive(:current)`, name `eq("ong norte")`, `month_folder_id).to eq("folder-norte")`, body `not_to include("Nenhum e-mail será enviado.")` | PASS — carried from `afaa369`; citation refreshed |
| C32 | renaming the failed row keeps that notice and `Reenviar e-mail` | batch exit 0 | `spec/requests/administration_spec.rb:845-854` — deliveries unchanged, name `eq("ONG Norte Nova")`, notice includes the failure sentence, row includes `"Reenviar e-mail"` | PASS — carried from `afaa369`; citation refreshed |
| C33 | renaming the other row leaves the failure where it was | batch exit 0 | `spec/requests/administration_spec.rb:870-882` — deliveries unchanged, `ONG Norte` keeps the notice and `"Reenviar e-mail"`, `ONG Sul Nova` `not_to include("E-mail enviado para")` and `not_to include("O cadastro foi gravado")` | PASS — carried from `afaa369`; citation refreshed |
| C34 | two renames to `ONG Iguais` leave one rename; the loser is `422` | batch exit 0 | `spec/requests/administration_spec.rb:1014-1018` — `names.count("ONG Iguais")).to eq(1)`, the other name is `"ONG Norte"` or `"ONG Sul"`, loser body includes the taken-name notice, deliveries `be_empty`. Model: `spec/models/organization_spec.rb:346-351` — `raise_error(ActiveRecord::RecordNotUnique)`, reloaded name `eq("ONG Norte")` | PASS — carried from `afaa369`; citation refreshed |
| C35 | `Corrigir` on the name confirmation returns `ONG Norte Nova` | batch exit 0 | `spec/requests/administration_spec.rb:894-899` — `not_to change` the name, deliveries `be_empty`, input value `eq("ONG Norte Nova")` | PASS — carried from `afaa369`; citation refreshed |
| C36 | name confirmation for a missing id is `404` | batch exit 0 | `spec/requests/administration_spec.rb:910-912` — `have_http_status(:not_found)`, `Organization.pluck(:name)).to eq([ "ONG Norte" ])`, deliveries `be_empty` | PASS — carried from `afaa369`; citation refreshed |
| C37 | `Corrigir nome` discards an unwritten registration | batch exit 0 | `spec/requests/administration_spec.rb:924-928` — `Organization.find_by(name: "ONG Nova")).to be_nil`, form name and email `eq("")`, name field value `eq("ONG Norte")` | PASS — carried from `afaa369`; citation refreshed |
| C38 | a valid registration discards an open name field | batch exit 0 | `spec/requests/administration_spec.rb:944-948` — stored name `eq("ONG Norte")`, confirm form `not_to be_nil`, name input `be_nil` | PASS — carried from `afaa369`; citation refreshed |
| C39 | taken name with invalid email is `422`, email notice then taken-name notice, nothing written | batch exit 0 | `spec/requests/administration_spec.rb:585-597` — `not_to change` the three counts, `have_http_status(:unprocessable_content)`, notices `eq([ "Informe um e-mail válido.", "Já existe uma organização com esse nome." ])`, field values kept, row includes `"ONG Norte"`, pending `be_nil` | PASS |

## Test policy rows

The instrumentation row classifies the two views the fix touched, so it was re-judged. The other rows were met at `afaa369` and do not classify a touched file. Carried from `afaa369`.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/organization.rb`; `app/mailers/coordinator_welcome_mailer.rb`; `app/controllers/administration_controller.rb` | model or mailer example, and a request spec | carried from `afaa369` — yes |
| Decides, not reached across a boundary | no new file is only in this row | one example per member at its own layer | carried from `afaa369` — no file in this row |
| Entry point that decides nothing | no new post is only in this row | one request spec | carried from `afaa369` — no file in this row |
| Instrumentation / pass-through | `app/views/administration/show.html.erb`, `_organization.html.erb`, `_mail_result.html.erb`, `_record.html.erb` | the request examples that render them | yes — the views decide nothing. C2 renders the heading and the rest row, C26 renders the name field, C30 renders the name confirmation |

## Coverage

Notice combinations and designed screen states were recomputed from `registration_notices` (`app/controllers/administration_controller.rb:211-216`) and from `.design/administration-list.md`. The other rows are carried from `afaa369`.

`registration_notices` appends a blank-name notice, then an invalid-email notice, then a taken-name notice only when the stripped name is present. A blank name cannot also be taken, so the producible rejection combinations are five.

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| administration routes when signed out (9) | carried from `afaa369` — C3 | — |
| administration routes when not the administrator (3 env values × 9 routes) | carried from `afaa369` — C4 | — |
| `POST /administration` rejection notices (5) | blank name C5 · invalid email C6 · blank name then invalid email C7 · taken name C8 · taken name then invalid email, email notice first, C39 | — |
| confirm outcomes (8) | carried from `afaa369` — C12 · C13 · C14 · C15 · C16 · C17 · C21 · C22 | — |
| resend outcomes (3) | carried from `afaa369` — C18 · C19 · C20 | — |
| welcome sentences (2) | carried from `afaa369` — C24 · C25 | — |
| `coordinator_emails` (2) | carried from `afaa369` — C2 | — |
| `name_taken?` except (2) | carried from `afaa369` — C29 | — |
| name-correction outcomes (11) | carried from `afaa369` — C26 · C27 · C28 · C29 · C30 · C31 · C32 · C33 · C34 · C35 · C36 | — |
| unwritten-flow discards (2) | carried from `afaa369` — C37 · C38 | — |
| designed screen states this stage builds (8) | rest empty C1 · rest list C2 · invalid C5 · registration confirmation C9 · row sent C12 · row failed C17 · name field C26 · name confirmation C30 | — |
| drawings in `.design/administration-list.md` this stage does not build (3) | — | email correction, removal, and screen `home` invites — next stage, named in Out of scope |

The eight states are the ones Screen `administration` draws for this stage: rest with the section omitted, rest with the list, invalid registration, registration confirmation, the sent row, the failed row, the name field, and the name confirmation. Swept validation now includes C39; `registration_notices` does append both of those notices. The other Swept rows are carried from `afaa369`.

## Faults injected

Scratch worktree `/tmp/aa-admin-list-verify-r2` at `afaa369`, with the uncommitted view and request-spec fix copied in. The worktree was removed. Real-tree `git status --porcelain` matched the baseline taken before the scratch.

| Mutation | Location | Killed |
|---|---|---|
| removed `border-b` from the `Organizações` heading | `app/views/administration/show.html.erb` | yes — `GET /administration lists organizations in stored-name order` exit 1, expected the class to include `"border-b"` |
| removed `border-b` from the organization row | `app/views/administration/_organization.html.erb` | yes — the same example exit 1, expected the row class to include `"border-b"` |
| removed `flex-wrap` from the name-field button group | `app/views/administration/_organization.html.erb` | yes — `Corrigir nome opens the stored name` exit 1, expected the group class to include `"flex-wrap"`. The label and `form` assertions had already passed |
| rendered the coordinator email on the name confirmation | `app/views/administration/_organization.html.erb` | yes — `a lower-case spelling of the same name asks for confirmation` exit 1, expected the row not to include `"coordenador@exemplo.org"`. The label-then-name assertions had already passed |
| appended the taken-name notice before the invalid-email notice | `app/controllers/administration_controller.rb` `registration_notices` | yes — `taken name and invalid email re-render both notices` exit 1, got the taken-name notice first |

## Gate

`bin/rspec spec/requests/administration_spec.rb spec/models/organization_spec.rb spec/mailers/coordinator_welcome_mailer_spec.rb` — 83 examples, 0 failures. No spec-lean validator on this report.
