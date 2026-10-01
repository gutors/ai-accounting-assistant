# Administration list

> Plan this with **tlc-plan**.
> Decisions below carry the literal shape — copy them, do not re-derive them.
> Issue [#63](https://github.com/gutors/ai-accounting-assistant/issues/63). Issue [#66](https://github.com/gutors/ai-accounting-assistant/issues/66) amends the listed coordinator, home `Revogar`, submitter promotion, and skip-welcome. Account rows on remove stay as ADR-0007.
> Continues `.design/administration-intake.md`. The drawings there for whole-page confirmation, success, and mail failure are superseded by the screen `administration` below. The door, the write, and the validation notices in that file still hold.

## Situation

The intake screen registers one organization and then stops on that result. The sale now needs the registry on the same page: every organization already saved, a correction for a wrong name or a wrong coordinator email, removal when the organization has no close data, and a real welcome. Pending invites, coordinator and submitter, send from the organization home.

Visitor mode is Operate. One administrator, at a laptop, on `/administration`. The organization home also changes on the coordinator list: who sits first, and who sees `Revogar`. Pending-invite send is unchanged.

The page stays the 28rem left-aligned column from the intake screen. It uses the livro-caixa rules in `DESIGN.md`: labels above fields, the validation notice under the title, a caixa primary button, quiet actions, no card, no icon besides the mark, no success color. Red is the validation notice, a failed send, and `Remover`.

## Screen `administration`

Header is unchanged. With no organization focused: the mark, `Fechamento mensal`, and `Sair`. With an organization focused: the organization name, the existing links, `Administração`, and `Sair`.

The list is the page. `Adicionar organização` is the primary button and opens screen `administration/new`. Each row is one line: stored name, the principal coordinator email (`organizations.principal_coordinator_account_id`, the address from the sale or from this screen's email correction — not `accounts.email` ascending), status, and quiet `Editar`. Status is `Ativa` when that principal Account has a `google_uid`, otherwise `Pendente`. Other coordinator emails and `Remover` live on screen `administration/:id/edit`. Submitter emails are not on this page. Zero organizations: the table is omitted; the page is the title, the add button, and `Nenhuma organização cadastrada.`

`Cadastrar outra organização` is absent. After a write, the list returns. There is no control that clears a mail sentence; the next write that sends mail replaces it. A mail sentence sits on that organization's row, under the four columns.

```
┌ header ────────────────────────────────────────────────────────┐
│                                                                │
│  Administração                    [ Adicionar organização ]    │
│                                                                │
│  Nome          Email coordenador       Status     Editar       │
│  ─────────────────────────────────────────────────────────     │
│  ONG Norte     coordenador@exemplo.org Pendente   Editar       │
│  ONG Sul       sul@exemplo.org         Ativa      Editar       │
└────────────────────────────────────────────────────────────────┘
```

### Invalid registration

`POST /administration` from screen `administration/new`. The add form stays, with the values typed. Each failed check adds one notice under the title, in this order: `Informe o nome da organização.` `Informe um e-mail válido.` `Já existe uma organização com esse nome.` The notice is margem text with a 3px margem left border. The field border stays the ruling line. Nothing is written, and the page does not become a confirmation.

### Registration confirmation

`Continuar` on a valid add form replaces that form with the confirmation. The title is `Adicionar organização`. The lead sentence goes with the form. The two values use the same labels as the form. `Confirmar` is primary. `Corrigir` is the secondary button and returns to the form with these values filled in. Nothing is written yet. The list is not on this screen.

```
│  Administração                                      (h1)       │
│                                                                │
│  Nome da organização                                           │
│  ONG Norte                                                     │
│  ─────────────────────────────────────────────                 │
│  E-mail do coordenador                                         │
│  coordenador@exemplo.org                                       │
│                                                                │
│  [ Confirmar ]   [ Corrigir ]                                  │
│                                                                │
│  Organizações                                                  │
│  …rows at rest…                                                │
```

### After the registration is written

The list returns. The new row carries the mail result. Success is body text, with no red: `E-mail enviado para {email}.` Failure is the notice on that row: `O cadastro foi gravado, mas o e-mail não saiu.` and primary `Reenviar e-mail`.

`Reenviar e-mail` appears only on the organization of the latest failed send. A later write that sends mail replaces that result. A name correction sends no mail and does not move it. Refresh keeps the result. `POST /administration/mail` with no `session[:administration_result]` answers `302` to `/administration`, sends nothing, and writes no row.

When the coordinator email just saved is the signed-in administrator, the session focuses that organization and the header follows. Any other email leaves focus as it was.

### Name correction

On screen `administration/:id/edit`, `Corrigir nome` opens the stored name in one field. The email lines stay. `Continuar` is primary. `Cancelar` is a quiet caixa action and restores the edit screen. Nothing is written.

A blank name or a name that collides on `lower(name)` with a different organization keeps the field, keeps what was typed, and shows the registration notice under the title. The organization being corrected does not count as a collision with itself. The row does not become a confirmation.

A valid `Continuar` replaces the whole row with the new name and the body sentence `Nenhum e-mail será enviado.` Other rows stay. `Confirmar` writes the name and sends no mail. `Corrigir` returns to the field with the typed name. After the write, the row shows the new name and no mail sentence.

A month folder already written in Drive is left as it was. Its Drive name is `{YYYY-MM}` (`Month#close_for_send` passes `name: year_month`). The spreadsheet in that folder still shows the previous organization name until the next close-for-send. A rename does not call the writer. The screen does not say so.

```
│  ONG Norte                                                     │
│  Nome da organização                                           │
│  [ ONG Norte                                   ]               │
│  [ Continuar ]   Cancelar                                      │
│  coordenador@exemplo.org                                       │
│  Corrigir                                                      │
│  Remover                                                       │
```

```
│  Nome da organização                                           │
│  ONG Norte                                                     │
│  Nenhum e-mail será enviado.                                   │
│  [ Confirmar ]   [ Corrigir ]                                  │
```

### Email correction

On screen `administration/:id/edit`, `Corrigir` exists only on the principal coordinator email. Other coordinator emails stay as text with no `Corrigir`. `Corrigir` opens that principal address in one field. The name and the other emails stay. `Continuar` and `Cancelar` behave as they do for the name.

An invalid email, or an email that already has coordinator access on that organization, keeps the field and shows the notice under the title. Invalid: `Informe um e-mail válido.` Already has coordinator access: `Esse e-mail já tem acesso a esta organização.` The principal access being corrected does not count. A submitter access on that organization for the typed email is not a collision: confirm promotes that Access to coordinator and makes it principal. The row does not become a confirmation when the notice is shown.

A valid `Continuar` replaces the whole row with the stored organization name and the new email. `Confirmar` writes. `Corrigir` returns to the field with the typed email.

The write does not change `Account.email`. Principal coordinator access for the old address moves to the typed email. The Account is created when it is missing. The new coordinator access exists before the old principal access is removed. A pending invite for the new email on that organization is deleted in the same write. When the typed email already has an Account, no message is sent. When this write created the Account, the only message is the welcome, to the new address, after the write, with the saved name and the saved email.

When mail was sent, success on that row: `E-mail enviado para {email}.` Failure on that row: `A correção foi gravada, mas o e-mail não saiu.` and primary `Reenviar e-mail`. The correction stays in either case. When mail was skipped because the Account already existed, the row shows the new principal email and no mail sentence. The same focus rule as registration applies when the new email is the signed-in administrator.

```
│  Nome da organização                                           │
│  ONG Norte                                                     │
│  ─────────────────────────────────────────────                 │
│  E-mail do coordenador                                         │
│  novo@exemplo.org                                              │
│                                                                │
│  [ Confirmar ]   [ Corrigir ]                                  │
```

### One unwritten flow

One confirmation, or one open field, at a time. Starting the registration form's `Continuar`, or `Corrigir nome`, or `Corrigir` on an email, discards the other unwritten field or confirmation. Nothing is written by the discard. The abandoned row returns to rest. An abandoned registration confirmation returns the empty form.

### Removal

`Remover` is only on screen `administration/:id/edit`. It asks `Remover a organização {name}?` with the same confirm as `Revogar`. The edit screen stays until the answer is yes.

Removal deletes every access, coordinator and submitter, and pending invites, then the organization. The last-coordinator lock does not block it. The Account stays. Accountant, package archive, and certificate do not block; they go with the organization. The organization is removed only when it has no bank account, month, supporting document, justification, or extra exception kind.

When close data blocks it, nothing is deleted. The row stays, and the notice on that row reads `Esta organização já tem dados de fechamento e não pode ser removida.`

## Screen `home` people

The months list and both invite forms stay as they are. The submitter home is unchanged. Any coordinator may still invite a coordinator or a submitter, and may still revoke a submitter.

Under `Coordenadores`, the principal coordinator is the first row. The remaining coordinator emails follow in `accounts.email` ascending order. There is no badge. Only the principal sees `Revogar` on other coordinator rows, with the existing confirm `Revogar o acesso deste coordenador?`. No coordinator row has `Revogar` for the signed-in person's own Access: not the principal, and not a peer. `DELETE /accesses/:id` of a coordinator Access the caller may not revoke — including their own — answers `404` and does not call `destroy`.

## Screen `home` invites

Each pending invite, coordinator or submitter, shows `Reenviar e-mail` immediately before `Cancelar`. `Reenviar e-mail` is a quiet caixa action. `Cancelar` stays a quiet margem action, deletes that invite, and sends nothing. An invite that was already pending is sent only when someone resends.

A failed send is the error toast in C8–C10 (`O convite foi gravado, mas o e-mail não saiu.`), not a notice under the `Meses` title. `Cancelar` does not keep that failure. Per-invite mail status is #78.

```
│  [error toast: O convite foi gravado, mas o e-mail não saiu.]  │
│  Meses                                              (h1)       │
│                                                                │
│  Convites pendentes                                            │
│  ─────────────────────────────────────────────                 │
│  pessoa@exemplo.org                                            │
│  Reenviar e-mail    Cancelar                                   │
```

## Mail words

Copied from #63. Text, same SMTP and `MAIL_FROM` as the welcome. The screen does not preview the message.

Welcome subject: `Fechamento Mensal - Cadastro da Organização {name}`, with the saved name. The body stays the two sentences already sent by `CoordinatorWelcomeMailer`: the first-organization sentence, or the sentence for an account that already coordinates another organization.

Invite subject: `Fechamento Mensal - Convite para {name}`. Coordinator: `Você foi convidado a fechar o mês da organização {name}. Entre com o Google usando {email}, pelo botão Entrar com Google.` Submitter: `Você foi convidado a enviar documentos da organização {name}. Entre com o Google usando {email}, pelo botão Entrar com Google.`

## Boundary

In: the list column as principal, `Corrigir` only on that email, submitter promotion, skip welcome when the Account exists, and the home coordinator list plus `Revogar` rules.

Out: the buyer form. Changing `coordinator:bootstrap` abort-on-existing-Account. A second administrator. A submitter list on `/administration`. Accountant, package archive, and certificate, which stay on `/setup`. The header, the months list, and the invite form fields. A badge on the principal row.

## Decisions

| Decision | Choice | Why this | Alternative, and what would make it win | Reversibility |
|---|---|---|---|---|
| What leads | The list is the page. `Adicionar organização` opens a short-form screen. `Editar` opens the name, every coordinator email, and `Remover`. | The user asked for this on 28 Sep 2026: the inline form and the per-row remove were in the way of reading the registry | The intake form first, when opening the page is more often a sale than a lookup | reversible |
| Registration confirmation | Replaces the form. The title stays `Administração`. The list stays at rest | The user confirmed the list remains. A second title would make the list look like another page | The intake `h1` `Confirmar cadastro`, when the confirmation is again the whole page | reversible |
| After the write | The form returns empty. The mail sentence lives on that organization's row. No `Cadastrar outra organização` | The form is already on the page, so the button only repeated it. The sentence has to survive beside the other rows | Keeping the result in place of the form, when one registration is again the whole visit | reversible |
| Corrections | `Corrigir nome` and `Corrigir` on the principal email are separate. Each opens one prefilled field, then `Continuar` replaces that row with a confirmation. Other coordinator emails have no `Corrigir` | A name change sends no mail and an email change does. #66 edits only the principal address | One edit that changes the name and an email together, when both should commit or fail as one write. `Corrigir` on every coordinator, when every peer is a sale identity | reversible |
| Name confirmation | Shows the new name and `Nenhum e-mail será enviado.` | The name write sends nothing, and the confirmation is the place that says so | A confirmation with no sentence, when the absence of a button is enough | reversible |
| One unwritten flow | Starting the form or either correction discards the other unwritten field or confirmation and writes nothing | Two confirmations on one page would leave the pending values ambiguous | Keeping both, when the seller routinely starts a sale while a correction is open | reversible |
| `Cancelar` on the field | Quiet caixa. Restores the row and writes nothing | Abandoning a field deletes nothing. Invite `Cancelar` stays margem because it deletes the invite | The same margem treatment for both, when the word should mean one thing everywhere | reversible |
| Resend on the registry | Primary `Reenviar e-mail`, only on the organization of the latest failed send | That is the recovery from the intake failure screen, now sitting on the row it belongs to | A quiet resend on every organization that ever failed, when the failure has to outlive the session result | reversible |
| `Remover` | Quiet margem. Confirm `Remover a organização {name}?`, the same mechanism as `Revogar`. A refusal is the notice on that row | The user confirmed the `Revogar` style. The sentence says "esta organização", which the row makes true | The notice under the title, when removal refusals should stack with validation notices | reversible |
| Invite resend | Quiet caixa `Reenviar e-mail` immediately before `Cancelar`, on every pending invite. The failure notice sits under `Meses`. A send that goes out clears it. No success sentence | Every pending invite has the action, including ones that never failed, so it cannot be a primary button on each row | Primary `Reenviar e-mail` on the invite that just failed, when pending invites that were never sent should stay silent | reversible |
| Welcome subject | `Fechamento Mensal - Cadastro da Organização {name}` | #63. The body sentences stay the ones `CoordinatorWelcomeMailer` already sends | Keeping `Cadastro da organização {name}`, when the mailbox should not gain the product prefix | reversible |
| Email write | Does not change `Account.email`. New coordinator access is created before the old principal access is removed. A pending invite for the new email on that organization is deleted in the same write. Welcome mail is sent only when this write created the Account | #63 plus #66. An address that already has an Account is already in the system | Rewriting `Account.email`, when the Google identity and the address are the same record. Always sending the welcome, when the operator already uses the product | costly |
| Removal guard | Deletes accesses and pending invites, then the organization, only when it has no bank account, month, supporting document, justification, or extra exception kind. The Account stays. The last-coordinator lock does not apply | #63 and ADR-0007. Close data is the reason the row cannot go. #66 item 4 is out of `.tasks/principal-coordinator.md` | A softer archive flag, when a removed organization must remain readable. Deleting orphan Accounts, when #66 item 4 is reopened | costly |
| Principal coordinator | `organizations.principal_coordinator_account_id` is the sale/edit email. Invited coordinators are not it. The list column and `Ativa`/`Pendente` follow that Account. Home lists it first | #66. Alphabetical first email is not the sale | `accounts.email` ascending as the listed coordinator, when the registry should not remember who was named at sale | costly |

## Sources

- Conversation, 24 Sep 2026 — form first; separate quiet corrections; the row becomes the confirmation; `Nenhum e-mail será enviado.` on a name confirmation; the list stays in the 28rem column
- Issue #63 — the registry, the mail words, the email write, the removal guard, and what stays out
- Issue #66 — principal coordinator, home revoke rules, submitter promotion, skip welcome when the Account exists
- `.design/administration-intake.md` — the form, the notices, the confirmation buttons, and the session result this screen keeps
- `DESIGN.md` — the 28rem short form, the notice, quiet actions, and the one red margin
