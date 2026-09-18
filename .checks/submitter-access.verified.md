# Submitter access Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: 9486aa2..4cae67b (`origin/main..HEAD` on `submitter-access`)
**Round**: 2 - full
**Verifier**: independent sub-agent (author != verifier)

Flow confirmed from the tree: `.checks/submitter-access.md` present; no `.specs/features/submitter-access/checks.md`. No binding design source.

Round 1 at `7aa65f5` FAILed Coverage / Test policy: Landing door 1 kinds statements, document exceptions, accountant, and package archive had no submitter `404` proof. `4cae67b` added those proofs (plus bank-account create and reopen) and expanded the Coverage row. This round re-ran every check at `HEAD`; nothing was carried from round 1.

## Binding sources

Profile `standard` — step 1 (`ui`) did not run. Checklist: “No design source for the screens.” No source marked binding.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| (none marked binding) | n/a | n/a | n/a |

## Proof run

One invocation at `HEAD` `4cae67b`:

```
bin/rspec --format documentation
  spec/requests/submitter_invites_spec.rb
  spec/models/invite_spec.rb
  spec/requests/omniauth_callbacks_spec.rb
  spec/models/operator_authenticator_spec.rb
  spec/requests/organizations_spec.rb
  spec/requests/accesses_spec.rb
  spec/models/access_spec.rb
  spec/requests/focus_spec.rb
  spec/requests/supporting_documents_spec.rb
  spec/requests/months_spec.rb
  spec/requests/setup_spec.rb
  spec/requests/close_spec.rb
  spec/requests/matches_spec.rb
  spec/models/supporting_document_spec.rb
  spec/requests/justifications_spec.rb
  spec/models/justification_spec.rb
  spec/requests/bank_statements_spec.rb
  spec/requests/document_exceptions_spec.rb
  spec/requests/accountants_spec.rb
  spec/requests/package_archives_spec.rb
  spec/requests/bank_accounts_spec.rb
  spec/requests/reopen_spec.rb
```

Exit 0. `363 examples, 0 failures`. All 73 unique named examples from C1–C58 appear in that documentation output as having run. The six Coverage-row examples for remaining coordinator-only HTML also appear. Every named proof file is in `9486aa2..HEAD`.

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | persist one pending `submitter` Invite; `302` `/` | batched; names present | `spec/requests/submitter_invites_spec.rb:10` `change(Invite, :count).by(1)`; `:14` `invite.kind).to eq("submitter")`; `:16–17` `:found` `redirect_to("/")`. `spec/models/invite_spec.rb:16–17` `be_persisted` / `kind).to eq("submitter")` | PASS |
| C2 | `/` includes that pending email | batched; name present | `spec/requests/submitter_invites_spec.rb:19` `include("guest@example.com")` after `follow_redirect!` | PASS |
| C3 | OIDC: one Account, submitter Access, Invite gone, session+focus, `302` `/` | batched; names present | `spec/requests/omniauth_callbacks_spec.rb:108–118` Account+submitter count, `kind).to eq("submitter")`, Invite `be_nil`, `session` ids, `:found` `redirect_to("/")`. `spec/models/operator_authenticator_spec.rb:22–26` `:signed_in`, submitter kind | PASS |
| C4 | then `/` is `200` with organization name | batched; name present | `spec/requests/omniauth_callbacks_spec.rb:120–121` `:ok` `include("ONG Norte")` | PASS |
| C5 | second callback: no second Account/Access; session is existing Account | batched; names present | `spec/requests/omniauth_callbacks_spec.rb:130–132` Account count `1`, Access count `1`, `session[:account_id]`. `spec/models/operator_authenticator_spec.rb:34–38` `:signed_in`, counts `1` | PASS |
| C6 | coordinator of A accepts submitter Invite on B; no second Account; `302` `/` | batched; names present | `spec/requests/omniauth_callbacks_spec.rb:142–148` `not_to change(Account, :count)`, B Access `submitter`, Invite `be_nil`, `redirect_to("/")`. `spec/models/operator_authenticator_spec.rb:48–52` same at the model | PASS |
| C7 | standing submitter, no Invite: session+focus, `302` `/` | batched; names present | `spec/requests/omniauth_callbacks_spec.rb:156–159` session ids, `:found` `redirect_to("/")`. `spec/models/operator_authenticator_spec.rb:34–36` `:signed_in` + organization | PASS |
| C8 | standing Access of either kind: no Invite, `422` | batched; names present | `spec/requests/submitter_invites_spec.rb:32–40` `standing-coord@` / `standing-sub@` `not_to change` `:unprocessable_content`. `spec/models/invite_spec.rb:54–60` those emails `not_to be_persisted` | PASS |
| C9 | pending Invite: no additional, `422` | batched; names present | `spec/requests/submitter_invites_spec.rb:34` `pending@example.com` in the same table. `spec/models/invite_spec.rb:56` `pending@example.com` `not_to be_persisted` | PASS |
| C10 | not-an-email: no Invite, `422` | batched; names present | `spec/requests/submitter_invites_spec.rb:35` `"not-an-email"`. `spec/models/invite_spec.rb:57` same | PASS |
| C11 | unauthenticated POST: no Invite, `302` `/login` | batched; name present | `spec/requests/submitter_invites_spec.rb:47–50` `not_to change` `:found` `redirect_to("/login")` | PASS |
| C12 | concurrent submitter creates: exactly one pending Invite | batched; name present | `spec/models/invite_spec.rb:96` `Invite.where(...).count).to eq(1)` | PASS |
| C13 | accept persist `submitter`, not coordinator | batched; names present | `spec/models/invite_spec.rb:41–42` `kind).to eq("submitter")` and coordinator relation `be_empty`. `spec/requests/omniauth_callbacks_spec.rb:112–113` same | PASS |
| C14 | coordinator `/` lists standing submitter email | batched; name present | `spec/requests/organizations_spec.rb:24` `include("sub@example.com")` | PASS |
| C15 | DELETE submitter Access: gone, Account remains, `302` `/` | batched; name present | `spec/requests/accesses_spec.rb:88–91` Access `be_nil`, Account still found, `:found` `redirect_to("/")` | PASS |
| C16 | revoked zero Access: Account stays, no focus, `302` `/denied` | batched; names present | `spec/requests/omniauth_callbacks_spec.rb:168–173` `not_to change(Account, :count)`, `redirect_to("/denied")`, `session[:organization_id]` `be_nil`. `spec/models/operator_authenticator_spec.rb:61–63` `:denied`, `organization` `be_nil` | PASS |
| C17 | last submitter revoke leaves coordinator Accesses | batched; names present | `spec/requests/accesses_spec.rb:102` coordinator `pluck(:account_id)).to eq([ account.id ])`. `spec/models/access_spec.rb:29` `coordinator.count).to eq(1)` | PASS |
| C18 | DELETE pending submitter Invite: gone, `302` `/` | batched; name present | `spec/requests/submitter_invites_spec.rb:60–62` `find_by` `be_nil`, `:found` `redirect_to("/")` | PASS |
| C19 | submitter `/` lists those organizations’ names | batched; name present | `spec/requests/organizations_spec.rb:138–139` `include("ONG Norte")` / `include("ONG Sul")`. Does not assert a control node; names are the claimed values | PASS |
| C20 | submitter POST `/focus` to Access org: focus, `302` `/`, name | batched; name present | `spec/requests/focus_spec.rb:38–42` `session[:organization_id]`, `:found` `redirect_to("/")`, `include("ONG Sul")` | PASS |
| C21 | GET `/supporting_documents` omits org-B-only payee | batched; name present | `spec/requests/supporting_documents_spec.rb:505` `not_to include("Only Org B")` | PASS |
| C22 | focus without Access: `404`, focus unchanged | batched; name present | `spec/requests/focus_spec.rb:52–53` `:not_found`, `session[:organization_id]).to eq(org_a.id)` | PASS |
| C23 | mixed Access, focus B: GET `/months/2026-05` `404` | batched; name present | `spec/requests/months_spec.rb:260` `:not_found` | PASS |
| C24 | mixed Access, focus A: GET `/months/2026-05` `200` | batched; name present | `spec/requests/months_spec.rb:272` `:ok` | PASS |
| C25 | submitter GET month: `404`, body omits `PIX Isolado` | batched; name present | `spec/requests/months_spec.rb:284–285` `:not_found` `not_to include("PIX Isolado")` | PASS |
| C26 | submitter GET `/setup`: `404`, omits bank-account name | batched; name present | `spec/requests/setup_spec.rb:163–164` `:not_found` `not_to include("Conta Principal")` | PASS |
| C27 | submitter `/` omits close-ritual chrome | batched; name present | `spec/requests/organizations_spec.rb:148–151` `not_to include` `Abrir mês` / `Fechar para envio` / `Configuração` / `Convidar coordenador` | PASS |
| C28 | submitter documents: `200`, `Documentos de suporte`, omits `Doc Alheio` | batched; name present | `spec/requests/supporting_documents_spec.rb:517–519` `:ok`, `include("Documentos de suporte")`, `not_to include("Doc Alheio")` | PASS |
| C29 | no own documents: includes `Nenhum documento` | batched; name present | `spec/requests/supporting_documents_spec.rb:529` `include("Nenhum documento")` | PASS |
| C30 | submitter POST `/months`: no Month, `404` | batched; name present | `spec/requests/months_spec.rb:292–296` `not_to change(Month, :count)` `:not_found` | PASS |
| C31 | submitter POST close: month not closed, `404` | batched; name present | `spec/requests/close_spec.rb:516–517` `closed?).to eq(false)` `:not_found` | PASS |
| C32 | submitter POST match: no Match, `404` | batched; name present | `spec/requests/matches_spec.rb:374–380` `not_to change(Match, :count)` `:not_found` | PASS |
| C33 | submitter POST coordinator or submitter Invite: no Invite, `404` | batched; name present | `spec/requests/submitter_invites_spec.rb:70–77` both `/coordinator_invites` and `/submitter_invites` `not_to change` `:not_found` | PASS |
| C34 | submitter DELETE Access: remains, `404` | batched; name present | `spec/requests/accesses_spec.rb:113–114` `:not_found` `Access.find` still the row | PASS |
| C35 | matched own document: omits `Casado em` | batched; name present | `spec/requests/supporting_documents_spec.rb:545` `not_to include("Casado em")` | PASS |
| C36 | coordinator documents include submitter payee | batched; name present | `spec/requests/supporting_documents_spec.rb:557` `include("Padaria Central")` | PASS |
| C37 | submitter POST recibo jpg: one no-month own doc, `302`, list has date/amount/payee/Recibo | batched; name present | `spec/requests/supporting_documents_spec.rb:567–577` `:found` `redirect_to("/supporting_documents")`, org/account/`month_id` nil, count `1`, list match `11/05/2026` `R$ 155,00` `Recibo` `Padaria Central`. `recibo_params` defaults are `kind=recibo`, `155,00`, `2026-05-11`, `Padaria Central`, jpg, no XML | PASS |
| C38 | PATCH payee own no-month: persist, `302`, `Mercado Silva`, not `Padaria Central` | batched; name present | `spec/requests/supporting_documents_spec.rb:589–593` `:found` `redirect_to("/supporting_documents")`, include/omit payees | PASS |
| C39 | PATCH other Account: no change, `404` | batched; name present | `spec/requests/supporting_documents_spec.rb:606–607` `:not_found` `payee).to eq("Padaria Central")` | PASS |
| C40 | PATCH own month document: no change, `422` | batched; name present | `spec/requests/supporting_documents_spec.rb:622–623` `:unprocessable_content` `payee).to eq("Padaria Central")` | PASS |
| C41 | DELETE own no-month: row+blobs gone, `302`, page omits payee | batched; names present | `spec/requests/supporting_documents_spec.rb:636–641` `:found`, row `be_nil`, blob `be_nil`, `not_to include("Padaria Central")`. `spec/models/supporting_document_spec.rb:355–357` `withdraw` true, row+blob `be_nil` | PASS |
| C42 | DELETE own month document: row remains, `422` | batched; names present | `spec/requests/supporting_documents_spec.rb:656–657` `:unprocessable_content` `be_persisted`. `spec/models/supporting_document_spec.rb:379–380` `withdraw` false, `be_persisted` | PASS |
| C43 | DELETE other Account no-month: row remains, `404` | batched; name present | `spec/requests/supporting_documents_spec.rb:670–671` `:not_found` `be_persisted` | PASS |
| C44 | coordinator DELETE submitter no-month: gone, `302` | batched; name present | `spec/requests/supporting_documents_spec.rb:684–686` `:found` `redirect_to("/supporting_documents")` row `be_nil` | PASS |
| C45 | POST `200,00` + two docs: one Justification `20000`, both members, `302`, page `R$ 200,00` | batched; names present | `spec/requests/justifications_spec.rb:27–34` `:found`, `amount_cents).to eq(20000)`, both `justification`, `include("R$ 200,00")`. `spec/models/justification_spec.rb:35–39` `20000` Integer, both members | PASS |
| C46 | POST `155,00` + one doc persists `15500` | batched; names present | `spec/requests/justifications_spec.rb:45` `amount_cents).to eq(15500)`. `spec/models/justification_spec.rb:52` same | PASS |
| C47 | no document ids: no Justification, `422` | batched; names present | `spec/requests/justifications_spec.rb:51–55` `not_to change` `:unprocessable_content`. `spec/models/justification_spec.rb:63–64` `not_to be_persisted` count `0` | PASS |
| C48 | other Account document: no Justification, doc ungrouped, `422` | batched; names present | `spec/requests/justifications_spec.rb:68–75` `not_to change`, `justification_id).to be_nil`, `:unprocessable_content`. `spec/models/justification_spec.rb:86–87` same | PASS |
| C49 | month document: no Justification, `422` | batched; names present | `spec/requests/justifications_spec.rb:85–91` `not_to change` `:unprocessable_content`. `spec/models/justification_spec.rb:103–104` `not_to be_persisted` count `0` | PASS |
| C50 | already justified: no additional, still original, `422` | batched; names present | `spec/requests/justifications_spec.rb:102–109` `not_to change`, `justification).to eq(original)`, `:unprocessable_content`. `spec/models/justification_spec.rb:123–125` count `1`, original | PASS |
| C51 | spent `0` or non-BRL: no Justification, `422` | batched; names present | `spec/requests/justifications_spec.rb:116–123` `["0", "not-an-amount"]` `not_to change` `:unprocessable_content`. `spec/models/justification_spec.rb:131–138` both `not_to be_persisted`, count `0` | PASS |
| C52 | submitter documents omit other Account `R$ 80,00` | batched; name present | `spec/requests/justifications_spec.rb:139` `not_to include("R$ 80,00")` | PASS |
| C53 | concurrent declare same document: exactly one Justification | batched; name present | `spec/models/justification_spec.rb:200–201` `Justification.where(...).count).to eq(1)` and document has a justification | PASS |
| C54 | DELETE last member no-month document destroys Justification | batched; names present | `spec/requests/justifications_spec.rb:152` `Justification.count).to eq(0)`. `spec/models/supporting_document_spec.rb:370` `Justification.find_by` `be_nil` | PASS |
| C55 | coordinator documents include `R$ 200,00` and both payees | batched; name present | `spec/requests/justifications_spec.rb:168–170` `include("R$ 200,00")` / `Padaria Central` / `Mercado Silva` | PASS |
| C56 | PATCH spent `180,00` while members have no month: `18000`, `302`, page `R$ 180,00` not `R$ 200,00` | batched; names present | `spec/requests/justifications_spec.rb:183–188` `:found`, `18000`, include/omit amounts. `spec/models/justification_spec.rb:154–155` `replace_amount` true, `18000` | PASS |
| C57 | PATCH with a month member: no change, `422` | batched; names present | `spec/requests/justifications_spec.rb:204–205` `:unprocessable_content` `amount_cents).to eq(20000)`. `spec/models/justification_spec.rb:170–171` `replace_amount` false, `20000` | PASS |
| C58 | PATCH other Account Justification: no change, `404` | batched; name present | `spec/requests/justifications_spec.rb:222–223` `:not_found` `amount_cents).to eq(8000)` | PASS |

Accounted: **58 / 58**. No check lacks `file:line`. Claims that name a status/route have a request-spec assertion at that boundary. No level gap on those claims.

## Coverage (recomputed)

Members taken from enums, Landing, and decision tables in the code — not copied from the author’s table.

| Set (authority) | Member -> proof | Unproven |
| --- | --- | --- |
| `Invite.kind` / `Access.kind` (code enums, 2) | `coordinator` existing `spec/models/invite_spec.rb:29` `kind).to eq("coordinator")` · `submitter` C13 | - |
| standing Access kinds that block Invite (`Access.kinds`, 2) | `coordinator` C8 `standing-coord@` · `submitter` C8 `standing-sub@` | - |
| rejected submitter invite inputs (claim, 3) | standing C8 · pending C9 · invalid email C10 | - |
| OperatorAuthenticator outcomes this cut adds (claim + `call` branches, 5) | new submitter Invite C3 · second callback C5 · coordinator+pending submitter C6 · standing submitter C7 · revoked zero Access C16 | - |
| mixed Access focus (claim, 2) | focus B months `404` C23 · focus A months `200` C24 | - |
| coordinator-only HTML in Landing door 1 (lists or mutates months, statements, payments, matches, document exceptions, close-for-send, setup, accountant, package archive, Invites, Accesses — 11 kinds) | months GET/POST C25/C30 · payments body C25 `PIX Isolado` · statements POST `spec/requests/bank_statements_spec.rb:351` `:not_found` `not_to change(BankStatement, :count)` · matches POST C32 · document exceptions POST `spec/requests/document_exceptions_spec.rb:163–164` `:not_found` `document_exception_kind).to be_nil` · close-for-send C31 · setup GET C26 · accountant PATCH `spec/requests/accountants_spec.rb:164–165` `:not_found` name `be_nil` · package archive PATCH `spec/requests/package_archives_spec.rb:90–91` `:not_found` URL `be_nil` · Invites C33 · Accesses C34. Extra verbs on the same `before_action` also proven: POST bank accounts, POST reopen | - |
| Invite kinds a submitter must not POST (2) | `coordinator` C33 `/coordinator_invites` · `submitter` C33 `/submitter_invites` | - |
| document owner on submitter mutate (2) | own PATCH C38 / DELETE C41 · other PATCH C39 / DELETE C43 | - |
| document month on submitter mutate (2) | no month PATCH C38 / DELETE C41 · has month PATCH C40 / DELETE C42 | - |
| destroy actors for no-month document (2) | inserting submitter C41 · coordinator C44 | - |
| Justification declare rejects (`eligible?` + parse, 5) | no ids C47 · other Account C48 · has month C49 · already justified C50 · invalid amount C51 | - |
| invalid spent amount members (2) | `0` C51 · non-BRL C51 | - |
| Justification visibility (3) | own submitter C45 · other submitter C52 · coordinator C55 | - |
| Justification amount PATCH (claim 3; code also rejects invalid amount) | members no month C56 · month member C57 · other Account C58 | `replace_amount` invalid amount (`justification.rb:48–50`) has no PATCH proof — not named in a claim; recorded, not a FAIL |
| startup config assemblies | no new process setting; OmniAuth initializer unchanged in this range (`config/routes.rb` only) | - |

Every controller that gained `before_action :require_coordinator_organization` in this range now has a submitter `404` example: `MonthsController`, `SetupController`, `MatchesController`, `SubmitterInvitesController` / `CoordinatorInvitesController`, `AccessesController`, `BankStatementsController`, `DocumentExceptionsController`, `AccountantsController`, `PackageArchivesController`, `BankAccountsController`.

## Test policy rows

Bar is the checklist table (rails.mdc lines 49–51), not a weaker house pattern.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/invite.rb` | model + HTTP | yes — C1/C8–C10/C12/C13 |
| Decides, and is reached across a boundary | `app/models/operator_authenticator.rb` | model + HTTP | yes — C3/C5–C7/C16 model + `omniauth_callbacks_spec` |
| Decides, and is reached across a boundary | `app/models/justification.rb` | model + HTTP; one case per member | yes — declare/replace C45–C51, C53, C56–C57 |
| Decides, and is reached across a boundary | `app/models/supporting_document.rb` `#withdraw` | model + HTTP | yes — C41/C42/C54 |
| Decides, and is reached across a boundary | `app/models/access.rb` last-submitter destroy | model + HTTP | yes — C15/C17 |
| Decides, and is reached across a boundary | coordinator-only controllers that dispatch `require_coordinator_organization` | HTTP status / who may call | yes — C25/C26/C30–C34 plus statements, document exception, accountant, package archive, bank accounts, reopen |
| Decides, not reached across a boundary | none added whose only home is a model | own layer | n/a |
| Entry point that decides nothing | `SubmitterInvitesController` create mapping | request spec accepted/rejected/unauth | yes — C1, C8–C11 |
| Instrumentation / pass-through | `ApplicationController#load_documents` scope | consumer | yes — C21, C28, C52 |

Round-1 unmet row on the four coordinator mutation controllers is met at `4cae67b`.

## Swept existing

- external-dependency failure: existing `#29` still in tree. `spec/requests/omniauth_callbacks_spec.rb:38` unverified email `redirect_to("/login")`; `:48` OmniAuth failure same. Those examples ran in the batched file invocation.
- Rows that cite C\* are the new checks above.
- n/a observability: nothing in the code to contradict.

## Faults injected

Scratch: `git worktree add /tmp/tlc-verify-submitter-access-r3 HEAD`. Real-tree porcelain before and after: ` M AGENTS.md` / ` M README.md` / `?? .checks/submitter-access.verified.md` (unchanged; not in the feature range). Scratch discarded with `git worktree remove --force`.

| Mutation | Location | Covering proof | Killed |
|---|---|---|---|
| `accept!` always creates `kind: :coordinator` | `app/models/invite.rb` `accept!` | `spec/models/invite_spec.rb -e "accept submitter creates submitter Access and deletes the Invite"` exit 1; `kind).to eq("submitter")` got `"coordinator"` | yes |
| zero-Access branch returns `:signed_in` instead of `:denied` | `app/models/operator_authenticator.rb` `call` | `spec/models/operator_authenticator_spec.rb -e "Account with zero Access is denied"` exit 1; `status).to eq(:denied)` got `:signed_in` | yes |
| removed `before_action :require_coordinator_organization` | `app/controllers/bank_statements_controller.rb` | `spec/requests/bank_statements_spec.rb -e "submitter POST bank_statements persists no statement and responds 404"` exit 1; `BankStatement.count` changed 0→1 | yes |
| `#withdraw` skips the `month_id.present?` guard | `app/models/supporting_document.rb` | `spec/models/supporting_document_spec.rb -e "withdraw month document is rejected"` exit 1; `withdraw).to eq(false)` got `true` | yes |
| `eligible?` always `true` | `app/models/justification.rb` | `spec/models/justification_spec.rb -e "declare another Account document is rejected"` exit 1; expected not persisted | yes |

Five distinct assertion surfaces. Cap reached. No surviving mutant. The statements `before_action` drop is the surface round 1 could not kill; the example added in `4cae67b` kills it.

## Gate

`bin/rspec --format documentation` (22 proof files) — 363 passed, 0 failed.

## Gaps (ranked)

None that fail the work. Notes only:

1. `Justification#replace_amount` rejects invalid spent amount in code with no PATCH check (not a named claim).
2. C19 asserts organization names, not that the listing is a control.
