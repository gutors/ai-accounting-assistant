# Administration access Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: d2ecf9d..b9956c4
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

Round 1 (`d2ecf9d..88d2a8b`) failed step 1: confirmation labels and two-block stacking were uncovered, rest `Corrigir` was not proven interleaved after each email, and the email-field `Continuar`/`Cancelar` group was not proven as one `flex-wrap` ordered pair. This round re-opened those three screens, re-proved **C1, C4, C11**, and re-ran proofs at `b9956c4`. The three arrangement gaps are closed. C2, C3, C5–C10, C12–C52 carried from `88d2a8b` except citations in `spec/requests/administration_spec.rb`, which this round’s assertion inserts moved.

## Binding sources

Step 1 this round: screens `administration` rest-with-coordinators, email field, and email confirmation. Home screens carried from `88d2a8b` (interface untouched in `88d2a8b..b9956c4`).

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.design/administration-list.md` screens `administration` (rest, email field, email confirmation) and `home` | yes - file in the repo. Rest drawing stacks name, `Corrigir nome`, each email then `Corrigir`, then `Remover`. Email field has no ASCII; name-field analogue and “Continuar and Cancelar behave as they do for the name” put `Continuar` then `Cancelar`. Email-correction confirmation drawing stacks `Nome da organização` then the stored name, `E-mail do coordenador` then the new email, then `Confirmar` then `Corrigir`. | none vs C1, C4, C11 (renegotiated this round) or vs C2–C3, C5–C10, C12–C52 / Landing carried from `88d2a8b` | **none of the three round-1 arrangement gaps.** C11 now claims and asserts the labels and label-then-value siblings plus `Confirmar` then `Corrigir`. C1 now claims and asserts `ana@exemplo.org`, `Corrigir`, `zoe@exemplo.org`, `Corrigir`, `Remover` in document order. C4 now claims and asserts `Continuar` then `Cancelar` as the only submit/button descendants of Continuar’s `flex-wrap` parent. Visual unproven remains enumerated per screen (spacing, colour, type weight) — not a blanket. Home pending-invite / invite-failed / submitter uncovered: none, carried from `88d2a8b`. |

## Checks

C1, C4, C11 re-proved at `b9956c4`. Named examples written individually by rspec `--out` (`GET /administration shows Corrigir on each coordinator email and Remover`, `Corrigir opens the coordinator email`, `a new coordinator email asks for confirmation`) — 3 examples, 0 failures. Full `spec/requests/administration_spec.rb` at `b9956c4`: 78 examples, 0 failures. Other proof files at `b9956c4`: 102 examples, 0 failures; every named proof below appeared as `passed`. C1 and C27 share one example.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | rest: `Corrigir` immediately after each coordinator email, `Remover`, no submitter, `flex-wrap` in `max-w-[28rem]`, order name / `Corrigir nome` / `ana` / `Corrigir` / `zoe` / `Corrigir` / `Remover`, emails ascending | `bin/rspec spec/requests/administration_spec.rb -e "GET /administration shows Corrigir on each coordinator email and Remover"` exit 0 at `b9956c4` | `administration_spec.rb:38–42` column `max-w-[28rem]`; `:1047–1050` row inside that column, row `flex-wrap`; `:1051–1059` `p, button` eq `ONG Norte`, `Corrigir nome`, `ana@exemplo.org`, `Corrigir`, `zoe@exemplo.org`, `Corrigir`, `Remover`; `:1064–1069` two `Corrigir` with `text-caixa underline underline-offset-2`; `:1073–1080` `Remover` `text-margem underline underline-offset-2`; `:1081` body omits `submitter@exemplo.org` | PASS |
| C2 | signed out: 302 `/login`, counts and deliveries unchanged | same file, example re-run in the 78; carried assertions from `88d2a8b` | `administration_spec.rb:75–82` — routes include the five new email/removal paths; `have_http_status(:found)` `redirect_to("/login")`; `not_to change` Organization/Account/Access/Invite/deliveries | PASS |
| C3 | non-administrator / blank allowlist: 404, empty body, counts unchanged | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:85–97` — `seller@example.com`, `nil`, `""` each over `administration_routes`; `have_http_status(:not_found)`; `response.body).to eq("")` | PASS |
| C4 | email field: address in one field, name and other email+`Corrigir` stay, `Continuar` `bg-caixa`, `Cancelar` quiet caixa, `Continuar` then `Cancelar` in one `flex-wrap` group, nothing written or mailed | `… -e "Corrigir opens the coordinator email"` exit 0 at `b9956c4` | `administration_spec.rb:1095–1116` — `not_to change` Access/Account/deliveries; field value `zoe@exemplo.org`; Continuar `bg-caixa`; parent `flex-wrap`; group submit/button eq `["Continuar", "Cancelar"]`; Cancelar `text-caixa underline underline-offset-2`; one remaining `Corrigir`; `ana@exemplo.org` present | PASS |
| C5 | Cancelar restores `zoe@exemplo.org`, Access/Account unchanged, no mail | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1129–1136` — `not_to change` Access/Account; deliveries empty; row includes `zoe@exemplo.org` | PASS |
| C6 | invalid email: 422, notice `Informe um e-mail válido.`, field keeps `nao-e-email`, not a confirmation | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1148–1155` — `:unprocessable_content`; notices `eq(["Informe um e-mail válido."])`; field value `nao-e-email`; no confirm form | PASS |
| C7 | taken coordinator email: 422, `Esse e-mail já tem acesso a esta organização.`, field keeps `Ana@Exemplo.ORG` | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1168–1173` — 422; that notice; Access count unchanged | PASS |
| C8 | taken submitter email: 422, same notice, Access unchanged | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1189–1190` — 422; notice `Esse e-mail já tem acesso a esta organização.` | PASS |
| C9 | same address (padded case): 200, stored name and `coordenador@exemplo.org`, no access notice, nothing written | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1201–1208` — `not_to change` Access/Account; error notice absent | PASS |
| C10 | same-email confirm: Access count unchanged, Account email unchanged, welcome to that address, row `E-mail enviado para coordenador@exemplo.org.` | request re-run in the 78; model re-run at `b9956c4`; carried from `88d2a8b` | `administration_spec.rb:1220–1229` — `not_to change { norte.accesses.count }`; email still `coordenador@exemplo.org`; mime/subject/body. `organization_spec.rb:425–436` (unchanged file) — same Access record, email unchanged | PASS |
| C11 | new-email confirmation: 200, label `Nome da organização` then `ONG Norte`, then `E-mail do coordenador` then `novo@exemplo.org`, then `Confirmar` then `Corrigir`, not `ana@exemplo.org`, nothing written | `… -e "a new coordinator email asks for confirmation"` exit 0 at `b9956c4` | `administration_spec.rb:1246–1260` — `not_to change` Access/Account; `:ok`; `html.index` label then name then email-label then new email; `name_label.next_element` `ONG Norte`; `email_label.next_element` `novo@exemplo.org`; not `ana@exemplo.org`; buttons `eq(["Confirmar", "Corrigir"])` | PASS |
| C12 | Corrigir on confirmation returns `novo@exemplo.org`, nothing written or mailed | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1272–1277` — GET `/administration`; `not_to change` Access/Account; field `novo@exemplo.org` | PASS |
| C13 | move: new Account, old email unchanged, one coordinator Access on the new email, Norte invite gone, Sul invite stays, welcome to `novo@exemplo.org`, no `Você foi convidado`, sent sentence | request re-run in the 78; model re-run at `b9956c4`; carried from `88d2a8b` | `administration_spec.rb:1294–1310`; `organization_spec.rb:447–456` — Account created; old email unchanged; one coordinator; Norte invite nil; Sul present; mailer empty at the model (mail after commit). Order insert-then-destroy is inferred from end state, not sequenced | PASS |
| C14 | existing Account: `Account.count` unchanged, old email unchanged, Access belongs to that Account, “adicionada à sua conta” body | request + model re-run at `b9956c4`; carried from `88d2a8b` | `administration_spec.rb:1314` example; `organization_spec.rb:467–472` | PASS |
| C15 | welcome `to` is the new email, not `ana@exemplo.org` | request + mailer re-run at `b9956c4`; carried from `88d2a8b` | `administration_spec.rb:1347–1349`; `coordinator_welcome_mailer_spec.rb:53–55` — `to eq(["novo@exemplo.org"])` | PASS |
| C16 | `deliver_now` raises: move remains, error notice on that row, primary `Reenviar e-mail` posts `/administration/mail`, no `E-mail enviado para` | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1366–1377` — new Account present; new Access; old Access gone; old email unchanged; Norte invite gone; `[data-notice=error]` correction copy; resend `bg-caixa` action `/administration/mail` | PASS |
| C17 | correction resend delivers to `novo@exemplo.org`, not ana; following GET sent sentence, no `Reenviar e-mail` | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1397–1400` | PASS |
| C18 | correction resend raise: Access rows unchanged, correction notice remains | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1405` example | PASS |
| C19 | registration resend success: `E-mail enviado para` that coordinator, not the correction failure copy | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:442–444` | PASS |
| C20 | registration resend raise: cadastro failure copy, not correction copy | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:448–462`. Given is a successful confirm then a failed resend, not an already-failed registration row; the **then** copy is asserted | PASS |
| C21 | confirm of signed-in email sets `session[:organization_id]` to that Organization | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1425` example | PASS |
| C22 | confirm of another email leaves `session[:organization_id]` | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1438` example | PASS |
| C23 | missing organization confirm: 404, no Access, no mail | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1456–1465` — `:not_found` | PASS |
| C24 | write raises before commit: Access count 1, old Access remains, no new Account, Invite remains, no mail | model re-run at `b9956c4`; carried from `88d2a8b` | `organization_spec.rb:481–491` — stubs `Access.create!`; Access count 1; old Access found; new Account nil; Invite present; deliveries empty. Proves Account+create rollback; does not fail a later Invite-delete or destroy | PASS |
| C25 | email Corrigir discards unwritten name confirmation | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1470` example | PASS |
| C26 | Corrigir nome or valid registration discards unwritten email confirmation, no welcome | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1485` and `:1503` examples | PASS |
| C27 | `Remover` `data-turbo-confirm` `Remover a organização ONG Norte?` | same example as C1 exit 0 at `b9956c4` | `administration_spec.rb:1078–1080` — `data-turbo-confirm`; DELETE `/administration` | PASS |
| C28 | empty close data: 302 `/administration`, Organization/Accesses/Invite gone, Accounts remain, GET omits `ONG Norte` | request re-run in the 78; model re-run at `b9956c4`; carried from `88d2a8b` | `administration_spec.rb:1520` example; `organization_spec.rb:502–508` | PASS |
| C29 | after removing focused org: 200, session id kept, header `Fechamento mensal` | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1547` example | PASS |
| C30 | removing another org leaves focused `ONG Sul` | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1580–1581` | PASS |
| C31 | last-coordinator `DELETE /accesses/:id` still 422; `Access#destroy` still false | both examples passed at `b9956c4`; carried from `88d2a8b` | `accesses_spec.rb:17–26`; `access_spec.rb:32–38`. Those files are unchanged on `88d2a8b..b9956c4` | PASS |
| C32 | BankAccount blocks: 422, row notice, counts unchanged | request + model re-run at `b9956c4`; carried from `88d2a8b` | `administration_spec.rb:1589–1595` — 422; notice on that row; `organization_spec.rb:516–520` | PASS |
| C33 | Month blocks: 422, same notice, nothing deleted | request + model re-run at `b9956c4`; carried from `88d2a8b` | `administration_spec.rb:1599` example; `organization_spec.rb:528–530` | PASS |
| C34 | SupportingDocument blocks | request + model re-run at `b9956c4`; carried from `88d2a8b` | `administration_spec.rb:1614` example; `organization_spec.rb:546–548` | PASS |
| C35 | Justification blocks | request + model re-run at `b9956c4`; carried from `88d2a8b` | `administration_spec.rb:1636` example; `organization_spec.rb:557–559` | PASS |
| C36 | ExtraExceptionKind blocks | request + model re-run at `b9956c4`; carried from `88d2a8b` | `administration_spec.rb:1651` example; `organization_spec.rb:567–569` | PASS |
| C37 | missing id: 404, other Organization remains | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1672` — `:not_found` | PASS |
| C38 | after removing the result org: 200, form shown, no mail sentence or cadastro failure for `ONG Norte` | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1677` example | PASS |
| C39 | resend for missing result org: 302 `/administration`, no mail, no writes | re-run in the 78; carried from `88d2a8b` | `administration_spec.rb:1704` — `:found` | PASS |
| C40 | coordinator invite: 302 `/`, pending Invite, text/plain from `venda@example.com`, subject/body, no success sentence, no error notice, `Reenviar e-mail` before `Cancelar` with quiet classes | request + mailer passed at `b9956c4`; carried from `88d2a8b` | `coordinator_invites_spec.rb:44–68`; `invite_mailer_spec.rb:17–23` | PASS |
| C41 | submitter invite body and subject | request + mailer passed at `b9956c4`; carried from `88d2a8b` | `submitter_invites_spec.rb:22–36`; `invite_mailer_spec.rb:32–36` | PASS |
| C42 | create + `deliver_now` raises: Invite remains; notice after `h1` `Meses` and before months content | passed at `b9956c4`; carried from `88d2a8b` | `coordinator_invites_spec.rb:139–145` | PASS |
| C43 | GET `/` does not deliver for an already pending Invite | passed at `b9956c4`; carried from `88d2a8b` | `organizations_spec.rb:211` — `not_to change` deliveries | PASS |
| C44 | resend on another Invite clears the failure notice, both Invites remain, no success sentence | passed at `b9956c4`; carried from `88d2a8b` | `coordinator_invites_spec.rb:160–165` | PASS |
| C45 | resend raise: Invite remains, failure notice | passed at `b9956c4`; carried from `88d2a8b` | `coordinator_invites_spec.rb:175–178` | PASS |
| C46 | Cancelar after failure: Invite gone, no mail, notice remains | passed at `b9956c4`; carried from `88d2a8b` | `coordinator_invites_spec.rb:191–194` | PASS |
| C47 | Cancelar without stored notice: Invite gone, no mail, notice absent | passed at `b9956c4`; carried from `88d2a8b` | `coordinator_invites_spec.rb:204–207` | PASS |
| C48 | standing Access, pending Invite, `nao-e-email` on both controllers: 422, no Invite, no mail | both examples passed at `b9956c4`; carried from `88d2a8b` | `coordinator_invites_spec.rb:78–88`; `submitter_invites_spec.rb:48–59` | PASS |
| C49 | resend of another organization’s Invite: 404, Invite remains, no mail | passed at `b9956c4`; carried from `88d2a8b` | `coordinator_invites_spec.rb:218–220` | PASS |
| C50 | signed out create/resend: 302 `/login`, no Invite, no mail | three examples passed at `b9956c4`; carried from `88d2a8b` | `coordinator_invites_spec.rb:93–98`, `:226–231`; `submitter_invites_spec.rb:64–69` | PASS |
| C51 | submitter home: `h1` `Início`, no `Reenviar e-mail`, no invite-failure notice | passed at `b9956c4`; carried from `88d2a8b` | `organizations_spec.rb:220–222` | PASS |
| C52 | later successful create clears the failure notice; both Invites remain | passed at `b9956c4`; carried from `88d2a8b` | `coordinator_invites_spec.rb:244–246` | PASS |

## Coverage (recomputed)

Authority for the designed-screens row is `.design/administration-list.md` (re-opened this round for rest, email field, email confirmation). Other set rows: authority unchanged this round; recomputed members still match proofs. Carried join body from `88d2a8b` except the designed-screens Unproven column.

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| new administration routes when signed out (5) | `POST /administration/email` C2 · `…/continue` C2 · `…/cancel` C2 · `…/confirm` C2 · `DELETE /administration` C2 (`administration_routes` includes all five) | - |
| new administration routes when not the administrator (2 callers × 5) | other email C3 · blank env C3 (`nil` and `""`), each over those routes | - |
| email-correction Continuar rejections (3) | invalid C6 · taken coordinator C7 · taken submitter C8 | - |
| email-correction Continuar allowed (2) | same address C9 · new address C11 | - |
| email-move writes (5) | same email C10 · new Account + Invite delete C13 · existing Account C14 · recipient C15 · rollback C24 | insert-then-destroy is end state only |
| correction mail outcomes (5) | confirm delivers C13 · raise C16 · resend C17 · resend raise C18 · missing id C23 | - |
| registration mail notices (2) | resend success omits correction copy C19 · resend raise keeps cadastro copy C20 | - |
| close-data members that block removal (5) | BankAccount C32 · Month C33 · SupportingDocument C34 · Justification C35 · ExtraExceptionKind C36 | - |
| removal allowed (1) | no close data, last coordinator included, accountant/archive/cert present C28 | - |
| invite kinds (2) | coordinator C40 · submitter C41 | - |
| invite create rejections (3 × 2) | coordinator C48 · submitter C48 | - |
| invite mail failure and retry (6) | create raise C42 · GET does not send C43 · resend other clears C44 · resend raise C45 · Cancelar keeps C46 · later create clears C52 | - |
| invite authorization (3) | signed out C50 · wrong organization C49 · submitter home C51 | - |
| designed screen states this stage builds (design) | rest C1 · email field C4 · email invalid C6 · email confirmation C11 · correction failed C16 · removal blocked C32 · home pending C40 · home invite failed C42 · home submitter C51 | **none** — confirmation labels and label-then-value blocks C11; rest `Corrigir` after each email C1; email-field `Continuar` then `Cancelar` in one `flex-wrap` group C4 |

No extra enumeration in Landing or Test policy evidence lacked a row. Status/route claims have request-spec proofs.

## Test policy rows

Re-judged the HTTP row that classifies `spec/requests/administration_spec.rb` (the file this round touched). Other rows carried from `88d2a8b`.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/organization.rb` (`replace_coordinator`, `remove`); `app/mailers/invite_mailer.rb`; `app/mailers/coordinator_welcome_mailer.rb` (recipient) | own layer + HTTP; one case per member | yes — carried from `88d2a8b`; C10/C13/C14/C24 and C28/C32–C36 at model and request; C40/C41 mailer+request; C15 mailer+request. Invite rejections: existing `invite_spec.rb:45` + C48 HTTP |
| Decides, not reached across a boundary | none added | own layer | n/a |
| Entry point that decides nothing | invite/resend actions once persist is delegated; `AdministrationController#mail` missing org | request: accepted, rejected, error | yes — C39, C49, C50, C2, C3, C23, C37 |
| Instrumentation / pass-through | `ApplicationController#deliver_invite`; administration/home ERB | consumer | yes — C16/C42/C40 views and mail failure. New C1/C4/C11 assertions remain HTTP screen proofs of that ERB, which the row classifies as consumer coverage |

`AdministrationController#email_notices` is a controller decision table proven only at HTTP (C6–C9), matching the checklist’s named analogue (stage 1 name correction). Not scored unmet. Carried from `88d2a8b`.

## Swept existing

Carried from `88d2a8b`. This round did not touch the cited files.

- `Access#destroy` last-coordinator refusal is still at `app/models/access.rb:9–17`. C28 uses `Access.where(organization_id:).delete_all`, not that method.
- `focused_organization` still resolves `current_account.organizations.find_by(id: session[:organization_id])` (`application_controller.rb:20–24`). C29 header `Fechamento mensal` matches.
- `POST /administration/mail` uses `Organization.find_by` (`administration_controller.rb:60`), not `find`.
- `Revogar` still sets `data-turbo-confirm` (`organizations/show.html.erb:54`).
- Notices still render `data-notice="error"` (`app/views/shared/_notice.html.erb:1`).
- `administrator?` is still one normalized `ADMINISTRATOR_EMAIL` (`application_controller.rb:32–35`).
- Invite `from` is still `ENV["MAIL_FROM"]` (`application_mailer.rb:2`).

## Faults injected

Worktree `/Users/gutors/Developer/ai-accounting-assistant-verify-aa-r2` at `b9956c4`. Never stash. Real-tree porcelain before and after: `M .design/administration-intake.md`, `M bin/dev`, `?? .checks/administration-access.verified.md`, `?? .tasks/administration-list.md`. Worktree removed.

These three are the new assertion surfaces this round (the old weak C1/C4/C11 assertions would have missed each mutant). Round-1 product-code surfaces were not re-injected: `88d2a8b..b9956c4` changed only the checklist and `spec/requests/administration_spec.rb`.

| Mutation | Location | Killed |
|---|---|---|
| dropped confirmation labels `Nome da organização` and `E-mail do coordenador`, left name and email values | `app/views/administration/_organization.html.erb` email `:confirm` | yes — C11 `administration_spec.rb:1251` expected `html.index("Nome da organização") < 61`, got `nil`. Old `include("ONG Norte")` / `include("novo@exemplo.org")` would not kill this |
| both `Corrigir` after both emails (two loops: all `<p>` then all buttons) | same file, rest branch | yes — C1 `administration_spec.rb:1051` expected interleaved `ana`, `Corrigir`, `zoe`, `Corrigir`; got `ana`, `zoe`, `Corrigir`, `Corrigir`. Old two-`Corrigir` count plus `ana` before `zoe` before `Remover` would not kill this |
| `Cancelar` moved outside Continuar’s `flex-wrap` group | same file, email `:field` | yes — C4 `administration_spec.rb:1107` expected `["Continuar", "Cancelar"]`, got `["Continuar"]`. Old “Continuar’s parent has `flex-wrap`” plus Cancelar present with classes would not kill this |

Three surfaces, three killed, none surviving.

## Gate

- `bin/rspec spec/requests/administration_spec.rb -e` C1, C4, C11 — 3 passed, 0 failed (`b9956c4`)
- `bin/rspec spec/requests/administration_spec.rb` — 78 passed, 0 failed
- `bin/rspec` over the eight other proof files named in the checklist — 102 passed, 0 failed; every named proof listed in Checks appeared as passed
