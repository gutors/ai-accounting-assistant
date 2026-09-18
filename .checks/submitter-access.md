# Submitter access

Sources:

- `.tasks/submitter-access.md` - this cut: criteria 1–58, doors, sweep, surface
- https://github.com/gutors/ai-accounting-assistant/issues/35 - submitter invite, isolation, justification
- https://github.com/gutors/ai-accounting-assistant/issues/24 - Access kinds, focus isolation, author withdraws while no month
- https://github.com/gutors/ai-accounting-assistant/issues/3 - who inserts does not see the statement
- https://github.com/gutors/ai-accounting-assistant/issues/29 / `.specs/features/coordinator-access/` - Google OIDC, Invite unique, last-coordinator guard, focus
- https://github.com/gutors/ai-accounting-assistant/issues/32 / `.specs/features/supporting-document-insert/` - insert/edit path reused; destroy was out of that cut
- `CONTEXT.md` - Account, Access, Invite, Submitter, Justification
- user delegated in the task - coordinator sees justifications on `/supporting_documents`; submitter may PATCH spent amount while every member has no month

No design source for the screens.

## Out of scope

- Turning a justification into a suggestion, or any payment association the submitter does not choose - #37
- Promoting submitter Access to coordinator Access on the same organization (or the reverse) in one gesture
- Replacing the last coordinator, creating organizations in the UI, magic-link email proof, outbound invite SMTP - #29 / #24
- Locking typed fields because XML is attached, identified SEFAZ consulta, reading the photo - #38
- Destroying a SupportingDocument that belongs to a Month - leave-match (#33) returns it to no month
- Accountant login, Drive writes, public signup
- Coordinator-declared justifications

## Landing

Touches Invite, OperatorAuthenticator, Access, `focused_organization`, SupportingDocumentsController, and a new Justification row. Reuses `Invite.create_pending` / `accept!`, Google OIDC, `POST /focus`, `DELETE /accesses/:id`, and the insert/edit path from #32.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Focus is any Access; coordinator-only HTML is 404 for submitter | Session `organization_id` may be an organization the Account holds Access on, of either kind. HTML that lists or mutates months, statements, payments, matches, document exceptions, close-for-send, setup, accountant, package archive, Invites, or Accesses requires coordinator Access on the focused organization and otherwise responds `404` with no Payment / Bank statement body. | Keep `focused_organization` coordinator-only — a signed-in submitter would `302` `/login` on `/` despite `account_id`. Expand focus without the 404 — one missed guard on `MonthsController#show` leaks payments |
| Invite.kind is the Access that accept persists | `Invite.create_pending` takes the kind; `accept!` creates `Access` with `invite.kind` and deletes the Invite. Unique pending Invite per Organization per email still covers both kinds. Standing Access of either kind blocks a new Invite on that organization. | A second `SubmitterInvite` table — glossary is one Invite. Accept always coordinator — a submitter invite would grant the close ritual |
| Justification is its own row, document at most one | `Justification` belongs to `Organization` and to `Account` (the declarer). `SupportingDocument` belongs to at most one `Justification`. Spent amount is integer cents. | Spent amount on `SupportingDocument` — cannot express more than one document toward one amount. `Justification` belongs to `Access` — revoke would cascade or strand the grouping while documents must remain on Account |
| Destroy SupportingDocument only while it has no month | `DELETE` succeeds only when `month_id` is nil, and only for the inserting Account (submitter) or a coordinator of that organization. Blobs go with the row. | Destroy while a Match exists — would dissolve the Match as a side effect. Submitter destroy after month assignment — #24 limits the author to documents that still have no month |

- Nothing else in this change is hard to reverse

Unresolved 1–2 stay open. Build uses the task recommendations without pinning them as checks: headings in pt-BR using the glossary word Submitter; empty justifications `Nenhuma justificativa`; justifications `created_at` desc; document DELETE uses Turbo confirm; sign-in focus prefers a coordinator organization if any exist, else a submitter organization.

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions):

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at the model layer **and** one request spec at HTTP | one asserted case per enumerated member at the model; status / who may call at the boundary | follow |
| Decides, not reached across a boundary | one at the model layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` lines 49–51 name the level and the sampling rule (one asserted case per enumerated member; HTTP also a request spec)
- `spec/models/invite_spec.rb` + `spec/requests/coordinator_invites_spec.rb` — Invite create/accept is the closest analogue
- `spec/models/access_spec.rb` + `spec/requests/accesses_spec.rb` — last-coordinator destroy at both layers
- OperatorAuthenticator has no model spec today; the table still requires one because it dispatches over sign-in outcomes

Cost: model specs for Invite kind/accept, OperatorAuthenticator outcomes, Justification declare/patch, SupportingDocument withdraw; request specs for every status/route claim below.

## Checks

### S1 - Submitter is invited and signs in · 22 files · 42 KB · ~11k

**C1** - When a coordinator of the focused organization submits a well-formed email that has neither standing Access nor a pending Invite on that organization as a submitter, then the system persists one pending Invite of kind `submitter` for that email and responds `302` to `/`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "POST /submitter_invites persists a submitter Invite and redirects"`
Proof: `bin/rspec spec/models/invite_spec.rb -e "create_pending kind submitter persists submitter"`

**C2** - When `/` renders for that coordinator, then it includes that pending email
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "POST /submitter_invites persists a submitter Invite and redirects"`

**C3** - When Google OIDC succeeds with `email_verified` true and that normalized email matches a pending submitter Invite and has no Account, then the system persists one Account, one submitter Access on that organization, deletes that Invite, sets the session to that Account and focus to that organization, and responds `302` to `/`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "callback matching submitter Invite grants submitter Access"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "pending submitter Invite with no Account signs in"`

**C4** - When that submitter then opens `/`, then the response is `200` and includes that organization’s name
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "callback matching submitter Invite grants submitter Access"`

**C5** - When Google OIDC succeeds a second time for that submitter email, then the system persists no second Account and no second Access on that organization and sets the session to the existing Account
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "second submitter callback reuses Account and Access"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "existing submitter Access with no pending Invite signs in"`

**C6** - Given an Account that already has coordinator Access on organization A and a pending submitter Invite on organization B, when Google OIDC succeeds for that verified email, then the system persists submitter Access on B, deletes that Invite, and persists no second Account, and responds `302` to `/`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "callback accepts submitter Invite on B for coordinator of A"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "coordinator of A accepts pending submitter Invite on B"`

**C7** - Given an Account that has submitter Access and no pending Invite, when Google OIDC succeeds for that verified email, then the system sets the session to that Account, sets focus to an organization of that Access, and responds `302` to `/`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "submitter callback with standing Access and no Invite signs in"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "existing submitter Access with no pending Invite signs in"`

**C8** - If a coordinator submits that email and it already has standing Access of either kind on that organization, then the system persists no Invite and responds `422`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "rejected submitter invite emails return 422"`
Proof: `bin/rspec spec/models/invite_spec.rb -e "rejects standing Access of either kind, pending duplicate, and invalid email"`

**C9** - If a coordinator submits that email and it already has a pending Invite on that organization, then the system persists no additional Invite and responds `422`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "rejected submitter invite emails return 422"`
Proof: `bin/rspec spec/models/invite_spec.rb -e "rejects standing Access of either kind, pending duplicate, and invalid email"`

**C10** - If a coordinator submits a string that is not an email as a submitter invite, then the system persists no Invite and responds `422`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "rejected submitter invite emails return 422"`
Proof: `bin/rspec spec/models/invite_spec.rb -e "rejects standing Access of either kind, pending duplicate, and invalid email"`

**C11** - If an unauthenticated request submits a submitter Invite, then the system persists no Invite and responds `302` to `/login`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "unauthenticated POST /submitter_invites responds 302 to /login"`

**C12** - When two concurrent submitter Invite submissions use the same email and organization, then the system persists exactly one pending Invite
Proof: `bin/rspec spec/models/invite_spec.rb -e "concurrent submitter creates persist exactly one pending Invite"`

**C13** - Always, accepting a submitter Invite persists Access kind `submitter` and does not persist coordinator Access on that organization for that Account
Proof: `bin/rspec spec/models/invite_spec.rb -e "accept submitter creates submitter Access and deletes the Invite"`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "callback matching submitter Invite grants submitter Access"`

**C14** - When `/` renders for a coordinator and the organization has a standing submitter Access, then the page includes that submitter’s email
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "organization home lists standing submitter email"`

**C15** - When a coordinator of the focused organization confirms revoke of a submitter Access, then the system deletes that Access and responds `302` to `/`, and that Account remains
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "DELETE submitter Access redirects and keeps Account"`

**C16** - While that revoked Account has no remaining Access, when Google OIDC succeeds for that email, then the system leaves the Account in place, sets no organization focus, and responds `302` to `/denied`
Proof: `bin/rspec spec/requests/omniauth_callbacks_spec.rb -e "revoked submitter callback keeps Account and redirects to /denied"`
Proof: `bin/rspec spec/models/operator_authenticator_spec.rb -e "Account with zero Access is denied"`

**C17** - When a coordinator revokes the only submitter Access and at least one coordinator Access remains, then those coordinator Accesses are unchanged
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "DELETE last submitter Access leaves coordinator Accesses"`
Proof: `bin/rspec spec/models/access_spec.rb -e "destroy last submitter Access is allowed"`

**C18** - When a coordinator DELETEs a pending submitter Invite on the focused organization, then that Invite is gone and the response is `302` to `/`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "DELETE /submitter_invites/:id redirects"`

### S2 - Focus follows any Access · 8 files · 32 KB · ~8k

**C19** - When an Account holds submitter Access on more than one organization, then `/` includes a control that lists those organizations’ names
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home lists organization names when Account has multiple Accesses"`

**C20** - When that submitter selects the other organization, then the system sets focus to that organization and responds `302` to `/`, and that page includes that organization’s name
Proof: `bin/rspec spec/requests/focus_spec.rb -e "submitter POST /focus to an Access organization redirects"`

**C21** - While focus is organization A, `GET /supporting_documents` does not include payee text that exists only on organization B’s supporting documents
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter documents page does not include another organization payee"`

**C22** - If the submitter requests to focus an organization they have no Access on, then the system responds `404` and leaves focus unchanged
Proof: `bin/rspec spec/requests/focus_spec.rb -e "submitter POST /focus without Access returns 404"`

**C23** - Given an Account that is coordinator of A and submitter of B, while focus is B, `GET /months/2026-05` responds `404`
Proof: `bin/rspec spec/requests/months_spec.rb -e "submitter focus GET /months/2026-05 responds 404"`

**C24** - Given that same Account, while focus is A, `GET /months/2026-05` responds `200`
Proof: `bin/rspec spec/requests/months_spec.rb -e "coordinator focus GET /months/2026-05 responds 200 for mixed Access"`

### S3 - Submitter cut hides the close ritual and others’ documents · 14 files · 40 KB · ~10k

**C25** - While a submitter is focused on an organization whose month `2026-05` has a Payment whose history is `PIX Isolado`, `GET /months/2026-05` responds `404` and the body does not include `PIX Isolado`
Proof: `bin/rspec spec/requests/months_spec.rb -e "submitter GET /months/2026-05 responds 404 and omits PIX Isolado"`

**C26** - While that submitter is focused, `GET /setup` responds `404` and the body does not include a bank-account name that exists only on that organization’s setup
Proof: `bin/rspec spec/requests/setup_spec.rb -e "submitter GET /setup responds 404 and omits bank-account name"`

**C27** - When that submitter opens `/`, then the page does not include `Abrir mês`, `Fechar para envio`, `Configuração`, or `Convidar coordenador`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home omits close-ritual chrome"`

**C28** - When a submitter opens `/supporting_documents` and another Account has a no-month document whose payee is `Doc Alheio` on that organization, then the page responds `200`, includes `Documentos de suporte`, and does not include `Doc Alheio`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter GET /supporting_documents omits another Account payee"`

**C29** - When that submitter’s organization has no SupportingDocument belonging to that Account, then `/supporting_documents` includes `Nenhum documento`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter GET /supporting_documents with no own documents includes Nenhum documento"`

**C30** - If a submitter POSTs `/months`, then the system persists no Month and responds `404`
Proof: `bin/rspec spec/requests/months_spec.rb -e "submitter POST /months persists no Month and responds 404"`

**C31** - If a submitter POSTs `/months/2026-05/close`, then the month remains not closed and the response is `404`
Proof: `bin/rspec spec/requests/close_spec.rb -e "submitter POST close leaves month open and responds 404"`

**C32** - If a submitter POSTs `/months/2026-05/matches`, then the system persists no Match and responds `404`
Proof: `bin/rspec spec/requests/matches_spec.rb -e "submitter POST match persists no Match and responds 404"`

**C33** - If a submitter POSTs a coordinator or submitter Invite, then the system persists no Invite and responds `404`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "submitter POST invites persist no Invite and respond 404"`

**C34** - If a submitter DELETEs an Access, then that Access remains and the response is `404`
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "submitter DELETE /accesses/:id returns 404"`

**C35** - While a submitter’s own document is in a Match, `/supporting_documents` does not include `Casado em`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter GET /supporting_documents matched document omits Casado em"`

**C36** - When a coordinator of that organization opens `/supporting_documents`, then the page includes the payee of a document the submitter inserted
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "coordinator GET /supporting_documents includes submitter payee"`

### S4 - Submitter inserts, edits, and withdraws own no-month documents · 6 files · 21 KB · ~5k

**C37** - When a submitter POSTs `kind=recibo`, amount `155,00`, date `2026-05-11`, payee `Padaria Central`, a `.jpg` photo, and no XML, then the system persists one SupportingDocument for the focused organization belonging to that Account and to no Month, responds `302` to `/supporting_documents`, and that page includes `11/05/2026`, `R$ 155,00`, `Padaria Central`, and `Recibo`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter POST recibo jpg persists Padaria Central Recibo and redirects"`

**C38** - When that submitter PATCHes payee `Mercado Silva` on that no-month document, then the system persists that payee, responds `302` to `/supporting_documents`, and that page includes `Mercado Silva` and does not include `Padaria Central`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter PATCH payee on own no-month document redirects"`

**C39** - If that submitter PATCHes payee on a SupportingDocument of the focused organization that belongs to another Account, then the system persists no change and responds `404`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter PATCH payee on another Account document returns 404"`

**C40** - If that submitter PATCHes payee on their own SupportingDocument that belongs to a Month, then the system persists no change and responds `422`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter PATCH payee on own month document returns 422"`

**C41** - When that submitter DELETEs their own SupportingDocument that belongs to no Month, then the system deletes that row and its blobs and responds `302` to `/supporting_documents`, and that page does not include that payee
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter DELETE own no-month document redirects and purges blobs"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "withdraw no-month document deletes the row and blobs"`

**C42** - If that submitter DELETEs their own SupportingDocument that belongs to a Month, then the row remains and the response is `422`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter DELETE own month document returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "withdraw month document is rejected"`

**C43** - If that submitter DELETEs a no-month SupportingDocument of another Account, then the row remains and the response is `404`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter DELETE another Account no-month document returns 404"`

**C44** - When a coordinator DELETEs a no-month SupportingDocument the submitter inserted, then the system deletes that row and responds `302` to `/supporting_documents`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "coordinator DELETE submitter no-month document redirects"`

### S5 - Submitter declares a justification · 8 files · 16 KB · ~4k

**C45** - When a submitter POSTs spent amount `200,00` and the ids of two of their no-month SupportingDocuments (amounts `15500` and `4500` cents), then the system persists one Justification for that Account and organization with `amount_cents` `20000`, both documents belong to that Justification, the system responds `302` to `/supporting_documents`, and that page includes `R$ 200,00`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "POST justification of 200,00 with two documents redirects"`
Proof: `bin/rspec spec/models/justification_spec.rb -e "declare two no-month documents persists amount_cents 20000"`

**C46** - When a submitter POSTs spent amount `155,00` and the id of one of their no-month SupportingDocuments of `15500` cents, then the system persists `amount_cents` `15500`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "POST justification of 155,00 with one document persists 15500"`
Proof: `bin/rspec spec/models/justification_spec.rb -e "declare one document persists amount_cents 15500"`

**C47** - If a submitter POSTs a spent amount with no supporting-document ids, then the system persists no Justification and responds `422`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "POST justification without document ids returns 422"`
Proof: `bin/rspec spec/models/justification_spec.rb -e "declare without documents is rejected"`

**C48** - If a submitter POSTs a document id that belongs to another Account, then the system persists no Justification, that document belongs to no Justification, and the response is `422`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "POST justification with another Account document returns 422"`
Proof: `bin/rspec spec/models/justification_spec.rb -e "declare another Account document is rejected"`

**C49** - If a submitter POSTs a document id that belongs to a Month, then the system persists no Justification and responds `422`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "POST justification with month document returns 422"`
Proof: `bin/rspec spec/models/justification_spec.rb -e "declare month document is rejected"`

**C50** - If a submitter POSTs a document id that already belongs to a Justification, then the system persists no additional Justification, that document still belongs to the original Justification, and the response is `422`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "POST justification with already justified document returns 422"`
Proof: `bin/rspec spec/models/justification_spec.rb -e "declare already justified document is rejected"`

**C51** - If a submitter POSTs spent amount `0` or a string that is not a BRL amount, then the system persists no Justification and responds `422`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "POST justification with invalid spent amount returns 422"`
Proof: `bin/rspec spec/models/justification_spec.rb -e "declare invalid spent amount is rejected"`

**C52** - When another Account has a Justification of `R$ 80,00` on that organization, then the submitter’s `/supporting_documents` does not include `R$ 80,00`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "submitter GET /supporting_documents omits another Account justification"`

**C53** - When two concurrent POSTs include the same supporting-document id, then that document belongs to exactly one Justification
Proof: `bin/rspec spec/models/justification_spec.rb -e "concurrent declare with the same document persists exactly one Justification"`

**C54** - When a submitter DELETEs the last remaining no-month document of their Justification, then that Justification row is gone
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "DELETE last member document destroys the Justification"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "withdraw last member document destroys the Justification"`

**C55** - When a coordinator of that organization opens `/supporting_documents` and that organization has a Justification of `20000` cents whose member documents have payees `Padaria Central` and `Mercado Silva`, then the page includes `R$ 200,00`, `Padaria Central`, and `Mercado Silva`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "coordinator GET /supporting_documents includes justification and member payees"`

**C56** - When a submitter PATCHes spent amount `180,00` on their Justification whose member documents all have no Month, then the system persists `amount_cents` `18000`, responds `302` to `/supporting_documents`, and that page includes `R$ 180,00` and does not include `R$ 200,00`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "PATCH justification spent amount 180,00 redirects"`
Proof: `bin/rspec spec/models/justification_spec.rb -e "replace_amount while members have no month persists 18000"`

**C57** - If a submitter PATCHes spent amount on their Justification and any member SupportingDocument belongs to a Month, then the system persists no change and responds `422`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "PATCH justification with a month member returns 422"`
Proof: `bin/rspec spec/models/justification_spec.rb -e "replace_amount with a month member is rejected"`

**C58** - If a submitter PATCHes a Justification that belongs to another Account on that organization, then the system persists no change and responds `404`
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "PATCH another Account justification returns 404"`

## Swept

- validation: C8, C10, C47, C48, C49, C50, C51
- failure modes: C25, C26, C39, C40, C42, C43, C57
- idempotency and retry: C5, C9, C50
- authorization: C23, C25, C28, C33, C34, C39, C58
- concurrency and ordering: C12, C53
- data lifecycle: C15, C16, C41, C54
- external-dependency failure: existing - Google OIDC failure and unverified email still `302` `/login` from #29
- state transitions: C3, C13, C15, C18, C41, C45, C54, C56, C57
- observability: n/a - no operator metric or log line is required

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| Invite.kind -> Access.kind (2) | `coordinator` existing `invite_spec` accept coordinator · `submitter` C13 | - |
| standing Access kinds that block Invite (2) | `coordinator` C8 · `submitter` C8 (table-driven) | - |
| rejected submitter invite inputs (3) | standing C8 · pending C9 · invalid email C10 | - |
| OperatorAuthenticator outcomes this cut adds (5) | new submitter Invite C3 · second callback C5 · coordinator+pending submitter C6 · standing submitter C7 · revoked zero Access C16 | - |
| mixed Access focus (2) | focus B months `404` C23 · focus A months `200` C24 | - |
| coordinator-only HTML named in criteria (7) | GET months C25 · GET setup C26 · POST months C30 · POST close C31 · POST matches C32 · POST invites C33 · DELETE access C34 | - |
| Invite kinds a submitter must not POST (2) | `coordinator` C33 · `submitter` C33 (table-driven) | - |
| document owner on submitter mutate (2) | own PATCH C38 / DELETE C41 · other PATCH C39 / DELETE C43 | - |
| document month on submitter mutate (2) | no month PATCH C38 / DELETE C41 · has month PATCH C40 / DELETE C42 | - |
| destroy actors for no-month document (2) | inserting submitter C41 · coordinator C44 | - |
| Justification declare rejects (5) | no ids C47 · other Account C48 · has month C49 · already justified C50 · invalid amount C51 | - |
| invalid spent amount members (2) | `0` C51 · non-BRL string C51 (table-driven) | - |
| Justification visibility (3) | own submitter C45 · other submitter C52 · coordinator C55 | - |
| Justification amount PATCH (3) | members no month C56 · any member has month C57 · other Account C58 | - |
| startup config assemblies | no new process setting; OmniAuth initializer already shared | - |

- Claims naming a status code, route or response shape: C1, C3–C11, C15–C18, C20, C22–C34, C37–C51, C54, C56–C58 - each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~11k + S2 ~8k + S3 ~10k + S4 ~5k + S5 ~4k = ~38k tokens floor. All five slices stay under 150k. No split.
