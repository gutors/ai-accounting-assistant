# Meaningful action toasts

> Build this with **tlc-implement**. Profile **`ui`**: the binding interface source is
> `.specs/features/visual-identity/design.md` (Toast) and `DESIGN.md` (Notice, Do's and Don'ts).
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

A coordinator or submitter finishes an action and the toast says `Pronto.` — or says nothing at
all. Sixteen routes inherit `Pronto.` from `ApplicationController#redirect_success`, whose message
is a hardcoded literal, and eighteen more redirect on success with no toast: close, reopen and
restore a month, import a statement, confirm and undo a match, mark and unmark a document
exception, return a document to having no month, edit and delete a document, confirm a chave on
SEFAZ, declare and edit a justification, revoke an access, and the three extra-exception-kind
mutations. On every screen that matters there are several rows of the same kind — four bank
accounts, twelve pending invites, a list of payments each with an amount — so `Pronto.` does not
say which one changed, and half the actions do not confirm anything at all. The person has to
re-read the page and infer what just happened, which is exactly what a toast exists to prevent.

When this ships, every state-changing action answers with one short sentence that names the object
it changed and the value the person just chose: `Conta bancária desativada: Conta Principal.`,
`Certificado A1 de 11.222.333/0001-81 instalado, válido até 18/09/2027.`,
`Casamento confirmado: R$ 220,00 com Padaria Central.` The copy lives in one module,
`app/models/action_toast.rb`, one function per action, so the wording is reviewed in one place
instead of at fourteen call sites. `Pronto.` stops existing. Error copy, toast chrome (position,
colour, `Fechar`, the `5000` ms timeout) and the `[data-notice="error"]` under the title are
unchanged.

34 routes · 4 slices · 1 one-way door · 0 open

## Criteria

One observable outcome per line. Every success message is asserted twice: once at its own layer in
`spec/models/action_toast_spec.rb` with the literal string, and once at the HTTP boundary in the
request spec that already covers the route.

### S1 - Início e Pessoas

1. When `POST /focus` with the id of `ONG Sul` succeeds, then the response is `302` to `/` and the
   following `GET /` has `[data-toast-kind="success"]` text exactly `Agora em ONG Sul.`
2. When `POST /coordinator_invites` persists `guest@example.com` and delivery succeeds, then the
   following `GET /` has `[data-toast-kind="success"]` text exactly
   `Convite enviado para guest@example.com.`
3. When `POST /submitter_invites` persists `guest@example.com` and delivery succeeds, then the
   following `GET /` has `[data-toast-kind="success"]` text exactly
   `Convite enviado para guest@example.com.`
4. When `POST /coordinator_invites/:id/mail` delivers, then the following `GET /` has
   `[data-toast-kind="success"]` text exactly `Convite reenviado para guest@example.com.`
5. When `POST /submitter_invites/:id/mail` delivers, then the following `GET /` has
   `[data-toast-kind="success"]` text exactly `Convite reenviado para guest@example.com.`
6. When `DELETE /coordinator_invites/:id` deletes the pending `guest@example.com`, then the
   response is `302` to `/` and the following `GET /` has `[data-toast-kind="success"]` text
   exactly `Convite para guest@example.com cancelado.`
7. When `DELETE /submitter_invites/:id` deletes the pending `guest@example.com`, then the following
   `GET /` has `[data-toast-kind="success"]` text exactly
   `Convite para guest@example.com cancelado.`
8. Given a peer coordinator `ana@ong.org`, when the principal coordinator `DELETE`s that Access,
   then the response is `302` to `/` and the following `GET /` has `[data-toast-kind="success"]`
   text exactly `Acesso de ana@ong.org revogado.`
9. When `POST /months` with `year_month` `2026-05` persists the Month, then the response is `302`
   to `/months/2026-05` and the following `GET` has `[data-toast-kind="success"]` text exactly
   `Fechamento de maio de 2026 aberto.`

### S2 - Configuração

10. When `PATCH /accountant` persists a valid accountant with presentation name `Ana Contábil`,
    then the response is `302` to `/setup` and the following `GET` has
    `[data-toast-kind="success"]` text exactly `Contador salvo: Ana Contábil.`
11. When `PATCH /package_archive` persists a Drive folder URL, then the response is `302` to
    `/setup` and the following `GET` has `[data-toast-kind="success"]` text exactly
    `Pasta do pacote salva.`
12. When `POST /sefaz_certificate` installs the valid e-CNPJ A1 whose titular is
    `11.222.333/0001-81` and whose `not_after` is `2027-09-18`, then the response is `302` to
    `/setup` and the following `GET` has `[data-toast-kind="success"]` text exactly
    `Certificado A1 de 11.222.333/0001-81 instalado, válido até 18/09/2027.`
13. Given that certificate is installed, when `DELETE /sefaz_certificate` runs, then the response
    is `302` to `/setup` and the following `GET` has `[data-toast-kind="success"]` text exactly
    `Certificado A1 de 11.222.333/0001-81 removido.`
14. When `POST /bank_accounts` persists `Conta Principal`, then the response is `302` to `/setup`
    and the following `GET` has `[data-toast-kind="success"]` text exactly
    `Conta bancária criada: Conta Principal.`
15. When `PATCH /bank_accounts/:id` saves the name `Nova Conta` without an `active` param, then the
    following `GET /setup` has `[data-toast-kind="success"]` text exactly
    `Conta bancária salva: Nova Conta.`
16. When `PATCH /bank_accounts/:id` with only `active` `false` on `Conta Principal`, then the
    following `GET /setup` has `[data-toast-kind="success"]` text exactly
    `Conta bancária desativada: Conta Principal.`
17. When `PATCH /bank_accounts/:id` with only `active` `true` on an inactive `Conta Principal`,
    then the following `GET /setup` has `[data-toast-kind="success"]` text exactly
    `Conta bancária reativada: Conta Principal.`
18. When `POST /extra_exception_kinds` persists `Doação`, then the response is `302` to `/setup`
    and the following `GET` has `[data-toast-kind="success"]` text exactly
    `Tipo extra criado: Doação.`
19. When `PATCH /extra_exception_kinds/:id` with `active` `false` on `Doação`, then the following
    `GET /setup` has `[data-toast-kind="success"]` text exactly
    `Tipo extra desativado: Doação.`
20. When `PATCH /extra_exception_kinds/:id` with `active` `true` on inactive `Doação`, then the
    following `GET /setup` has `[data-toast-kind="success"]` text exactly
    `Tipo extra ativado: Doação.`
21. When `DELETE /extra_exception_kinds/:id` removes the unused `Doação`, then the following
    `GET /setup` has `[data-toast-kind="success"]` text exactly
    `Tipo extra excluído: Doação.`
22. When `PATCH /base_document_exceptions/bank_fee` with `active` `false`, then the response is
    `302` to `/setup` and the following `GET` has `[data-toast-kind="success"]` text exactly
    `Exceção Tarifa bancária desativada.`
23. When `PATCH /base_document_exceptions/bank_fee` with `active` `true` on the inactive base
    offer, then the following `GET /setup` has `[data-toast-kind="success"]` text exactly
    `Exceção Tarifa bancária reativada.`

### S3 - Mês

24. When `POST /months/2026-05/close` closes a ready month, then the response is `302` to
    `/months/2026-05` and the following `GET` has `[data-toast-kind="success"]` text exactly
    `Maio de 2026 fechado. Pacote gravado na pasta do mês.`
25. When `POST /months/2026-05/reopen` reopens a closed month, then the following `GET` has
    `[data-toast-kind="success"]` text exactly `Maio de 2026 reaberto.`
26. When `POST /months/2026-05/restore` restores the month folder of a closed month, then the
    following `GET` has `[data-toast-kind="success"]` text exactly
    `Pasta de maio de 2026 restaurada no arquivo do pacote.`
27. When `POST /months/2026-05/bank_statements` imports the BB xlsx with 18 inflows and 13
    payments for `Conta Principal`, then the response is `302` to `/months/2026-05` and the
    following `GET` has `[data-toast-kind="success"]` text exactly
    `Extrato de Conta Principal importado: 18 recebimentos e 13 pagamentos.`
28. When that import has 1 inflow and 1 payment, then the toast text is exactly
    `Extrato de Conta Principal importado: 1 recebimento e 1 pagamento.`
29. When that import has 0 inflows and 0 payments, then the toast text is exactly
    `Extrato de Conta Principal importado.`
30. When `POST /months/2026-05/matches` confirms one payment of `R$ 220,00` with the document of
    `Padaria Central`, then the response is `302` to `/months/2026-05` and the following `GET` has
    `[data-toast-kind="success"]` text exactly
    `Casamento confirmado: R$ 220,00 com Padaria Central.`
31. When that match has two payments of `R$ 100,00` and `R$ 120,00` with one document of
    `Padaria Central`, then the toast text is exactly
    `Casamento confirmado: 2 pagamentos com Padaria Central.`
32. When `DELETE /months/2026-05/matches/:id` dissolves the match of `Padaria Central`, then the
    following `GET` has `[data-toast-kind="success"]` text exactly
    `Casamento desfeito: Padaria Central.`
33. When `POST /months/2026-05/payments/:id/document_exception` marks `bank_fee` on a payment of
    `R$ 45,00`, then the following `GET` has `[data-toast-kind="success"]` text exactly
    `Tarifa bancária marcada em R$ 45,00.`
34. When that action marks `accountant_fee`, then the toast text is exactly
    `Honorário do contador marcado em R$ 45,00.`
35. When that action marks the extra kind `Doação`, then the toast text is exactly
    `Doação marcada em R$ 45,00.`
36. When `DELETE /months/2026-05/payments/:id/document_exception` unmarks the `bank_fee` on a
    payment of `R$ 45,00`, then the following `GET` has `[data-toast-kind="success"]` text exactly
    `Exceção removida de R$ 45,00.`
37. When `POST /months/2026-05/supporting_documents/:id/return` returns the document of
    `Padaria Central` to having no month, then the following `GET` has
    `[data-toast-kind="success"]` text exactly
    `Documento de Padaria Central devolvido para Sem mês.`

### S4 - Documentos e justificativas

38. When `POST /supporting_documents` inserts a recibo of `Padaria Silva` for `R$ 120,00`, then the
    response is `302` to `/supporting_documents` and the following `GET` has
    `[data-toast-kind="success"]` text exactly
    `Recibo de Padaria Silva, R$ 120,00, incluído.`
39. When that insert is a nota fiscal of `Padaria Silva` for `R$ 120,00`, then the toast text is
    exactly `Nota fiscal de Padaria Silva, R$ 120,00, incluída.`
40. When `PATCH /supporting_documents/:id` saves the document of `Padaria Silva`, then the
    following `GET` has `[data-toast-kind="success"]` text exactly
    `Documento de Padaria Silva atualizado.`
41. When `DELETE /supporting_documents/:id` deletes the document of `Padaria Silva`, then the
    following `GET` has `[data-toast-kind="success"]` text exactly
    `Documento de Padaria Silva excluído.`
42. When `POST /supporting_documents/:id/sefaz_confirm` confirms the chave of `Padaria Silva`, then
    the following `GET` has `[data-toast-kind="success"]` text exactly
    `Nota fiscal de Padaria Silva confirmada na SEFAZ.`
43. When `POST /justifications` declares `R$ 300,00`, then the following `GET` has
    `[data-toast-kind="success"]` text exactly `Justificativa de R$ 300,00 registrada.`
44. When `PATCH /justifications/:id` replaces the amount with `R$ 350,00`, then the following
    `GET` has `[data-toast-kind="success"]` text exactly
    `Justificativa alterada para R$ 350,00.`

### Copy rules the module enforces

45. When a named value exceeds 40 characters, then it appears truncated to 40 characters with a
    trailing `…` — for example a payee of 60 `a`s renders as 39 `a`s plus `…`.
46. When the amount is `12000` cents, then every message that names money renders it through
    `format_reais` as `R$ 120,00`.
47. Always, the module renders no HTML entity and no string containing `Pronto.`
48. When `redirect_success` is called, then it requires a non-blank message argument, so no caller
    can fall back to a generic success sentence.

## Out of scope

- `/administration` — it has its own result panel (`_mail_result.html.erb` plus
  `session[:administration_result]`), not the toast; seller screens are unchanged.
- Login, `denied`, `DELETE /session`, the OIDC callback, `404`/`302` denial paths — they set no
  toast today and keep setting none.
- Existing error copy and `[data-notice="error"]`; the invite mail-failure message
  `O convite foi gravado, mas o e-mail não saiu.` stays verbatim.
- Toast chrome: position after `header`, `caixa`/`margem` colours, `Fechar`, `5000` ms timeout,
  `role`, Stimulus dismiss.
- Field-only `422` responses keep showing no toast.
- Migrating product copy to I18n — the repo keeps copy in constants and views.

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| toast `success` | empty state | existing — no `[data-toast]` until an action writes `flash`; 1–44 all assert the node exists after their action |
| toast `success` | error state | existing — error toast unchanged, out of scope above |
| toast `success` | unauthorised | existing — unsigned-in mutations stay `302` `/login` with no toast |
| toast `success` | density and ordering | existing — at most one toast; a later action replaces `flash` |
| toast `success` | destructive action confirms | existing — `data-turbo-confirm` on `Remover`, `Revogar`, `Excluir`, `Cancelar`, `Reabrir`, `Restaurar pasta` unchanged |
| screen `home` | empty state | existing — `Nenhum mês aberto` unchanged; 1–8 name the object instead |
| screen `setup` | empty state | existing — `Nenhuma conta bancária`, `Não há certificado A1 instalado` unchanged; 10–23 |
| screen `month` | empty state | existing — `Nenhum documento sem casamento`, `Nenhuma conta bancária ativa` unchanged; 24–37 |
| screen `documents` | empty state | existing — `Nenhum documento`, `Nenhuma justificativa` unchanged; 38–44 |
| document `.specs/features/visual-identity/design.md` § Toast | tone and depth | the copy rules of 45–48 land there |
| collection of toasts | grouping, naming, ordering, duplicates | existing — one toast per request; 1–44 each assert exactly one `[data-toast]` |

## Swept

- validation: 48 — `redirect_success` rejects a blank message
- failure modes: existing — every `422` path keeps its current `[data-notice]` and error toast;
  none of 1–44 changes a rejection branch
- idempotency and retry: existing — `flash` is discarded after the GET that renders it, so a second
  identical PATCH re-toasts the same sentence and nothing else
- authorization: existing — `require_account`, `require_coordinator_organization`,
  `require_focused_organization`, `require_administrator` unchanged; no toast on `404`/`302`
- concurrency and ordering: n/a — one session cookie; two overlapping POSTs leave whichever
  `flash` was written last, and the toast is not a store
- data lifecycle: 8, 32, 41 — the revoked e-mail and the dissolved match's payees are read before
  the row disappears, and the deleted document's own columns survive `destroy!`
- external-dependency failure: existing — SEFAZ, Drive and SMTP failures keep their `422` copy; a
  drive write failure on close still answers `Não foi possível gravar no arquivo do pacote`
- state transitions: 16, 17, 19, 20, 22, 23, 24, 25, 33–36 — each toast names the state just
  entered
- observability: n/a — the source names no log, metric or trace; the toast is the signal

## Impact

| Front | What changes |
|---|---|
| domain | no new glossary term — the sentences use `Conta bancária`, `Extrato`, `Casamento`, `Tipo extra`, `Exceção`, `Documento de suporte`, `Justificativa`, `Fechamento` as `GLOSSARY.md` defines them |
| domain | existing term: the success toast of an action. It was the literal `Pronto.` for 16 routes and absent for 18. Now it is one sentence per action naming the object and value, produced by `ActionToast`. Callers: the 12 controllers that mutate state, `ApplicationController#redirect_success` and `#redirect_after_invite_mail`, and 13 spec files asserting `Pronto.` |
| stored data | nothing to migrate — no column, no backfill |

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| Action-result copy lives in one module | `app/models/action_toast.rb`, `ActionToast.<action>(record)` returning a `String`; controllers choose the function, never build the sentence | A message literal at each of the 34 call sites — the wording then has no single review point and drifts, which is how `Pronto.` survived fourteen callers. A second set of model constants per action — those would sit on `BankAccount`, `Month`, `Match`… and duplicate the formatting rules 34 times |
| `redirect_success` requires its message | `def redirect_success(path, message)`; `message` is a positional required argument, so a new caller cannot compile without choosing copy | An optional `message: "Pronto."` default — that keeps the exact affordance being removed |

Nothing else in this change is hard to reverse: the sentence for any single action is one line in
one function, and the truncation bound is a constant.

## Sources

- The approved plan in this conversation, `Mensagens de toast com o valor da ação` — **binding for
  the copy table**: the per-action sentences of criteria 1–44, the writing rules, and the module
  shape in `Decided`
- `.tasks/action-result-toast.md` — Unresolved 1 (`Pronto.` on every listed success) is superseded
  by this task for the listed routes; the toast chrome criteria of that task still hold
- `.specs/features/visual-identity/design.md` § Toast, § Motion, and "Copy is the interface" —
  **binding for the interface**: position after `header` before `main`, `caixa` success,
  `margem` error, `Fechar`, `5000` ms, one sentence, "no numbers without their noun"
- `DESIGN.md` § Notice, § Do's and Don'ts — the red rule marks what blocks the close or went
  wrong, so a success sentence never uses `margem`
- `GLOSSARY.md` — the nouns each sentence uses, and the words to avoid
- `app/controllers/application_controller.rb:183-199` — `redirect_success`,
  `redirect_after_invite_mail`, `redirect_with_toast`
- `app/helpers/application_helper.rb:2-11` — `format_reais` and `month_title`, reused rather than
  reimplemented

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | None | | |
