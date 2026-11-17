# Meaningful action toasts

Sources:

- `.tasks/meaningful-action-toasts.md` — **binding**: criteria 1–48, the copy table, `Decided`
- `.specs/features/visual-identity/design.md` § Toast, § Motion, "Copy is the interface" — **binding for the interface**: screens `home`, `setup`, `month`, `documents`. Position after
  `header` before `main`, success fill `caixa`, `Fechar`, `5000` ms, one sentence, "no numbers
  without their noun". Unchanged by this change; the copy rules land there.
- `DESIGN.md` § Notice, § Do's and Don'ts — the red rule marks what blocks the close or went
  wrong, so a success sentence never uses `margem`
- `GLOSSARY.md` — the nouns (`Conta bancária`, `Extrato`, `Casamento`, `Tipo extra`, `Exceção`,
  `Documento de suporte`, `Justificativa`, `Fechamento`)
- `.tasks/action-result-toast.md` — the toast chrome criteria of #76 still hold; its Unresolved 1
  (`Pronto.`) is superseded here
- `spec/support/page_helpers.rb` — `toast_node` is the existing anchor; no new helper needed

## Out of scope

- `/administration` result panel — it has its own `_mail_result.html.erb` and
  `session[:administration_result]`, not the toast
- Login, `denied`, `DELETE /session`, the OIDC callback — no toast today, none after
- Existing error copy, `[data-notice="error"]`, and the invite mail-failure sentence
  `O convite foi gravado, mas o e-mail não saiu.`
- Toast chrome (position, `caixa`/`margem`, `Fechar`, `5000` ms, `role`, Stimulus dismiss)
- Field-only `422` responses — they keep showing no toast
- Migrating copy to I18n

## Landing

Adds `app/models/action_toast.rb`, one function per action returning a `String`, plus two private
helpers (truncation at 40, BRL through `format_reais`, month title through `month_title`). Twelve
controllers stop calling `redirect_to … status: :found` on success and call `redirect_success` with
the message. Reuses `format_reais` and `month_title` from `app/helpers/application_helper.rb` — the
module is a PORO at the same layer as `BrlCents` and `BrazilianTaxId`, which are the existing
precedent for a pure-computation class that is not a record, and it includes `ApplicationHelper`
rather than duplicating the two formatters.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Action-result copy lives in one module | `app/models/action_toast.rb`; `ActionToast.<action>(record)` → `String`; a controller picks the function and never builds a sentence | A literal per call site (34 of them) — no single review point, which is how `Pronto.` survived 14 callers; a constant per model — the same formatting rules duplicated 34 times |
| `redirect_success` requires its message | `def redirect_success(path, message)` — positional, required | `message: "Pronto."` as a default — keeps the exact affordance being removed (criterion 48) |
| A marked-exception sentence keeps the kind as a label, not as a subject | `Exceção marcada: Tarifa bancária, R$ 45,00.` — the kind is punctuation-delimited data, so an extra kind the coordinator invents (`Estorno`, `Frete`) never produces a gender disagreement | `Tarifa bancária marcada` / `Honorário do contador marcado` — the participle has to agree, and an extra exception kind is free text with no gender to look up; a gender table is wrong for the first kind that does not match its pattern. Settled by the user this session as "neutral" |

Nothing else here is hard to reverse: one sentence is one line in one function, and the truncation
bound is a constant.

## Test policy

`.cursor/rules/rails.mdc` already declares both halves this change needs, so nothing is proposed:
"Decision (branch table, guard, state transition): prove at its own layer (model/job spec), one
asserted case per enumerated member" and "Code reached over HTTP: also a request spec at the
boundary". `ActionToast` decides (one branch per action kind, plurality, truncation) and is reached
across the boundary, so it owes both. The request-spec half already exists for every route below.

## Checks

### S1 - Início e Pessoas · 13 files · 125 KB · ~31k

**C1** - `POST /focus` to `ONG Sul`, then `GET /`: one `[data-toast][data-toast-kind="success"]`
whose text is `Agora em ONG Sul.`
Proof: `bin/rspec spec/requests/focus_spec.rb -e "POST /focus names the organization in the toast"`

**C2** - `POST /coordinator_invites` for `guest@example.com` that delivers, then `GET /`: text
`Convite enviado para guest@example.com.`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites names the invited email in the toast"`

**C3** - `POST /submitter_invites` for `guest@example.com` that delivers, then `GET /`: text
`Convite enviado para guest@example.com.`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "POST /submitter_invites names the invited email in the toast"`

**C4** - `POST /coordinator_invites/:id/mail` that delivers: text
`Convite reenviado para guest@example.com.`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "resend names the resent email in the toast"`

**C5** - `POST /submitter_invites/:id/mail` that delivers: text
`Convite reenviado para guest@example.com.`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "resend names the resent email in the toast"`

**C6** - `DELETE /coordinator_invites/:id`: `302` to `/`, and the following `GET /` has text
`Convite para guest@example.com cancelado.`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "Cancelar names the cancelled email and drops the mail failure"`

**C7** - `DELETE /submitter_invites/:id`: text `Convite para guest@example.com cancelado.`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "DELETE names the cancelled email in the toast"`

**C8** - principal coordinator `DELETE`s the Access of `ana@ong.org`: `302` to `/` and text
`Acesso de ana@ong.org revogado.`
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "principal DELETE names the revoked coordinator email"`

**C9** - `POST /months` for `2026-05`: `302` to `/months/2026-05` and text
`Fechamento de maio de 2026 aberto.`
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months names the opened month in the toast"`

### S2 - Configuração · 13 files · 115 KB · ~29k

**C10** - `PATCH /accountant` persisting `Ana Contábil`: `302` to `/setup` and text
`Contador salvo: Ana Contábil.`
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant names the saved accountant in the toast"`

**C11** - `PATCH /package_archive` persisting a folders URL: `302` to `/setup` and text
`Pasta do pacote salva.`
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive toasts the saved package folder"`

**C12** - `POST /sefaz_certificate` installing the A1 whose titular is `11.222.333/0001-81` and
whose `not_after` is `2027-09-18`: `302` to `/setup` and text
`Certificado A1 de 11.222.333/0001-81 instalado, válido até 18/09/2027.`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST /sefaz_certificate names the titular and validity in the toast"`

**C13** - `DELETE /sefaz_certificate` after that install: `302` to `/setup` and text
`Certificado A1 de 11.222.333/0001-81 removido.`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "DELETE /sefaz_certificate names the removed titular in the toast"`

**C14** - `POST /bank_accounts` persisting `Conta Principal`: `302` to `/setup` and text
`Conta bancária criada: Conta Principal.`
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST /bank_accounts names the created account in the toast"`

**C15** - `PATCH /bank_accounts/:id` renaming to `Nova Conta` with no `active` param: text
`Conta bancária salva: Nova Conta.`
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "PATCH section form names the saved account in the toast"`

**C16** - `PATCH /bank_accounts/:id` with only `active` `false`: text
`Conta bancária desativada: Conta Principal.`
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "PATCH active false names the deactivated account in the toast"`

**C17** - `PATCH /bank_accounts/:id` with only `active` `true` on an inactive account: text
`Conta bancária reativada: Conta Principal.`
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "PATCH active true names the reactivated account in the toast"`

**C18** - `POST /extra_exception_kinds` persisting `Doação`: `302` to `/setup` and text
`Tipo extra criado: Doação.`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST /extra_exception_kinds names the created kind in the toast"`

**C19** - `PATCH /extra_exception_kinds/:id` with `active` `false`: text
`Tipo extra desativado: Doação.`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "PATCH inactive names the deactivated kind in the toast"`

**C20** - `PATCH /extra_exception_kinds/:id` with `active` `true`: text
`Tipo extra ativado: Doação.`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "PATCH active names the activated kind in the toast"`

**C21** - `DELETE /extra_exception_kinds/:id` of the unused `Doação`: text
`Tipo extra excluído: Doação.`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "DELETE names the deleted kind in the toast"`

**C22** - `PATCH /base_document_exceptions/bank_fee` with `active` `false`: `302` to `/setup` and
text `Exceção Tarifa bancária desativada.`
Proof: `bin/rspec spec/requests/base_document_exceptions_spec.rb -e "PATCH bank_fee inactive names the deactivated exception"`

**C23** - `PATCH /base_document_exceptions/bank_fee` with `active` `true` on the inactive offer:
text `Exceção Tarifa bancária reativada.`
Proof: `bin/rspec spec/requests/base_document_exceptions_spec.rb -e "PATCH bank_fee active names the reactivated exception"`

### S3 - Mês · 16 files · 135 KB · ~34k

**C24** - `POST /months/2026-05/close` of a ready month: `302` to `/months/2026-05` and text
`Maio de 2026 fechado. Pacote gravado na pasta do mês.`
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close names the closed month and the written package"`

**C25** - `POST /months/2026-05/reopen`: text `Maio de 2026 reaberto.`
Proof: `bin/rspec spec/requests/reopen_spec.rb -e "POST reopen names the reopened month"`

**C26** - `POST /months/2026-05/restore`: text
`Pasta de maio de 2026 restaurada no arquivo do pacote.`
Proof: `bin/rspec spec/requests/restore_spec.rb -e "POST restore names the restored month folder"`

**C27** - `POST /months/2026-05/bank_statements` importing the BB xlsx (18 inflows, 13 payments)
for `Conta Principal`: `302` to `/months/2026-05` and text
`Extrato de Conta Principal importado: 18 recebimentos e 13 pagamentos.`
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST BB xlsx names the account and the movement counts"`

**C28** - that import with 1 inflow and 1 payment: text
`Extrato de Conta Principal importado: 1 recebimento e 1 pagamento.`
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST one-row import uses the singular in the toast"`

**C29** - that import with 0 inflows and 0 payments: text
`Extrato de Conta Principal importado.`
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST zero-row import omits both movement clauses"`

**C30** - `POST /months/2026-05/matches` confirming one `R$ 220,00` payment with the document of
`Padaria Central`: `302` to `/months/2026-05` and text
`Casamento confirmado: R$ 220,00 com Padaria Central.`
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST 1:1 names the amount and the payee"`

**C31** - that route with two payments (`R$ 100,00`, `R$ 120,00`) and one document of
`Padaria Central`: text `Casamento confirmado: 2 pagamentos com Padaria Central.`
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST N:1 names the payment count and the payee"`

**C32** - `DELETE /months/2026-05/matches/:id` dissolving the `Padaria Central` match: text
`Casamento desfeito: Padaria Central.`
Proof: `bin/rspec spec/requests/matches_spec.rb -e "DELETE names the dissolved match payee"`

**C33** - `POST …/payments/:id/document_exception` with `kind` `bank_fee` on a `R$ 45,00` payment:
text `Exceção marcada: Tarifa bancária, R$ 45,00.`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST bank_fee names the marked kind and amount"`

**C34** - that route with `kind` `accountant_fee`: text
`Exceção marcada: Honorário do contador, R$ 45,00.`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST accountant_fee names the marked kind and amount"`

**C35** - that route with the extra kind `Doação`: text
`Exceção marcada: Doação, R$ 45,00.`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST extra kind names the marked kind and amount"`

**C36** - `DELETE …/payments/:id/document_exception` unmarking `bank_fee` on `R$ 45,00`: text
`Exceção removida de R$ 45,00.`
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "DELETE bank_fee names the removed exception and amount"`

**C37** - `POST /months/2026-05/supporting_documents/:id/return` of the `Padaria Central`
document: text `Documento de Padaria Central devolvido para Sem mês.`
Proof: `bin/rspec spec/requests/month_returns_spec.rb -e "POST return names the returned document"`

### S4 - Documentos e justificativas · 5 files · 160 KB · ~40k

**C38** - `POST /supporting_documents` inserting a recibo of `Padaria Silva` for `R$ 120,00`:
`302` to `/supporting_documents` and text
`Recibo de Padaria Silva, R$ 120,00, incluído.`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo names the payee amount and kind in the toast"`

**C39** - that route inserting a nota fiscal of `Padaria Silva` for `R$ 120,00`: text
`Nota fiscal de Padaria Silva, R$ 120,00, incluída.`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota fiscal names the payee amount and kind in the toast"`

**C40** - `PATCH /supporting_documents/:id` saving `Padaria Silva`: text
`Documento de Padaria Silva atualizado.`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH names the updated document"`

**C41** - `DELETE /supporting_documents/:id` of `Padaria Silva`: text
`Documento de Padaria Silva excluído.`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "DELETE names the deleted document"`

**C42** - `POST /supporting_documents/:id/sefaz_confirm` confirming the chave of `Padaria Silva`:
text `Nota fiscal de Padaria Silva confirmada na SEFAZ.`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "sefaz_confirm names the confirmed document"`

**C43** - `POST /justifications` declaring `R$ 300,00`: text
`Justificativa de R$ 300,00 registrada.`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "POST names the declared amount"`

**C44** - `PATCH /justifications/:id` replacing the amount with `R$ 350,00`: text
`Justificativa alterada para R$ 350,00.`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "PATCH names the new amount"`

### Copy rules (own layer)

**C45a** - A 44-character payee renders as its first 39 characters plus `…`, total 40
Proof: `bin/rspec spec/models/action_toast_spec.rb -e "truncates a named value to forty characters"`

**C45b** - A payee of exactly 40 characters renders unchanged, with no `…`
Proof: `bin/rspec spec/models/action_toast_spec.rb -e "keeps a named value of exactly forty characters"`

**C46** - `12000` cents renders as `R$ 120,00` in every message that names money
Proof: `bin/rspec spec/models/action_toast_spec.rb -e "renders money through format_reais"`

**C47** - No function of the module returns a string containing `Pronto.` or an HTML entity
Proof: `bin/rspec spec/models/action_toast_spec.rb -e "never returns Pronto or HTML"`

**C48a** - `ApplicationController#redirect_success` takes exactly two arguments, so a caller cannot
omit the message and fall back to a generic success sentence
Proof: `bin/rspec spec/requests/layout_spec.rb -e "redirect_success requires its message"`

**C48b** - A blank message writes no toast: `GET /` with an empty flash has no `[data-toast]`
Proof: `bin/rspec spec/requests/layout_spec.rb -e "GET / with no toast has no data-toast"`

## Swept

- validation: C48 — `redirect_success` cannot be called without a message
- failure modes: existing — every `422` path keeps its `[data-notice]` and error toast; the proofs
  for C1–C44 sit beside those examples and do not touch them
- idempotency and retry: existing — `flash` is discarded after the GET that renders it; a repeated
  identical PATCH re-toasts the same sentence and changes nothing else
- authorization: existing — `require_account`, `require_coordinator_organization`,
  `require_focused_organization`, `require_administrator` are untouched; `404`/`302` paths set no
  toast and none of C1–C44 asserts one there
- concurrency and ordering: n/a — one session cookie; two overlapping POSTs leave whichever
  `flash` was written last and the toast is not a store
- data lifecycle: C8, C13, C32, C41 — the e-mail, the certificate CNPJ and validity, and the payee
  are read before the row disappears
- external-dependency failure: existing — SEFAZ, Drive and SMTP failures keep their `422` copy; a
  Drive failure on close still answers `Não foi possível gravar no arquivo do pacote`
- state transitions: C16, C17, C19, C20, C22, C23, C24, C25, C33–C36 — each sentence names the
  state entered
- observability: n/a — no log, metric or trace is named; the toast is the signal

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| actions that toast today (17) | focus C1 · coordinator invite create C2 · submitter invite create C3 · coordinator resend C4 · submitter resend C5 · coordinator cancel C6 · submitter cancel C7 · accountant C10 · package archive C11 · certificate install C12 · certificate remove C13 · bank account create C14 · bank account save C15 · bank account deactivate C16 · base exception off C22 · month open C9 · document insert C38 | - |
| actions silent today (17 handled here) | access revoke C8 · bank account reactivate C17 · extra kind create C18 · extra kind deactivate C19 · extra kind activate C20 · extra kind delete C21 · base exception on C23 · month close C24 · month reopen C25 · month restore C26 · statement import C27 · match confirm 1:1 C30 · match confirm N:1 C31 · match dissolve C32 · exception mark C33–C35 · exception unmark C36 · document return C37 · document update C40 · document delete C41 · sefaz confirm C42 · justification create C43 · justification update C44 | - |
| mark kinds (3) | `bank_fee` C33 · `accountant_fee` C34 · extra kind C35 | - |
| base exception offers (2) | `bank_fee` off C22, on C23 | `accountant_fee` — same function and same map, `Organization::BASE_DOCUMENT_EXCEPTION_COLUMNS`; the criterion names only `bank_fee` |
| import count shapes (3) | 0/0 C29 · 1/1 C28 · 18/13 C27 | - |
| match shapes (2) | 1 payment C30 · N payments C31 | - |
| truncation edges (3) | 40 unchanged C45b · 44 → 40 C45a · 200 (favorecido max) C45a covers the bound only | - |
| designed screens (4) | `home` C1–C9 · `setup` C10–C23 · `month` C24–C37 · `documents` C38–C44 | - |

- Claims naming a status code, route or response shape: C1–C44 — every one of them is asserted in
  a request spec that crosses the boundary
- No other check claims more than the single case its proof exercises

## Screens (ui)

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `home` | `[data-toast-kind="success"]` `Agora em ONG Sul.` C1 · `Convite enviado para guest@example.com.` C2, C3 · `Convite reenviado …` C4, C5 · `Convite para guest@example.com cancelado.` C6, C7 · `Acesso de ana@ong.org revogado.` C8 · `Fechamento de maio de 2026 aberto.` C9 | toast stays inside `#toast-host`, which is `header`'s next element and precedes `main` (asserted today by `spec/requests/layout_spec.rb` "success toast sits after header before main"); this change adds no node and moves none | spacing, colour, type weight |
| `setup` | `Contador salvo: Ana Contábil.` C10 · `Pasta do pacote salva.` C11 · `Certificado A1 de … instalado, válido até 18/09/2027.` C12 · `… removido.` C13 · `Conta bancária criada/salva/desativada/reativada: …` C14–C17 · `Tipo extra criado/ativado/desativado/excluído: …` C18–C21 · `Exceção Tarifa bancária desativada/reativada.` C22, C23 | same host, same single `[data-toast]`; the Setup page's four sections and rows are unchanged | spacing, colour, type weight |
| `month` | `Maio de 2026 fechado. Pacote gravado na pasta do mês.` C24 · `Maio de 2026 reaberto.` C25 · `Pasta de maio de 2026 restaurada …` C26 · `Extrato de Conta Principal importado: 18 recebimentos e 13 pagamentos.` C27–C29 · `Casamento confirmado: …` C30, C31 · `Casamento desfeito: …` C32 · `<kind> marcada em R$ 45,00.` C33–C35 · `Exceção removida de R$ 45,00.` C36 · `Documento de Padaria Central devolvido para Sem mês.` C37 | same host; the ledger rows, the `Mês fechado` stamp and `Resolver` fold are untouched | spacing, colour, type weight |
| `documents` | `Recibo de Padaria Silva, R$ 120,00, incluído.` C38 · `Nota fiscal …, incluída.` C39 · `Documento de Padaria Silva atualizado.` C40 · `… excluído.` C41 · `Nota fiscal de Padaria Silva confirmada na SEFAZ.` C42 · `Justificativa de R$ 300,00 registrada.` C43 · `Justificativa alterada para R$ 350,00.` C44 | same host; the two ledgers and the insert form are untouched | spacing, colour, type weight |

## Handoff

One batch. S1 31k + S2 29k + S3 34k + S4 40k = 134k, under the 150k default, and the whole module
plus all its callers must land together anyway because `redirect_success` changes signature in the
same commit as its first caller. No boundary inside this feature.
