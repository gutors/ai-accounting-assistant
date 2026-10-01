# Invite kind and mail status

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/invite-kind-and-mail-status.md` marks screen `home` binding through `.specs/features/visual-identity/design.md` and `.design/administration-list.md` (`Screen home invites`).

Sources:

- `.tasks/invite-kind-and-mail-status.md` - criteria 1–14, the state diagram, the sweep, the one door, and the boundary. Unresolved 1 stays open (`sent` default for rows that never ran this task’s `deliver_now`)
- https://github.com/gutors/ai-accounting-assistant/issues/78 - **binding for this slice**: pending row shows Coordenador or Submitter; persist `sent` / `failed` on Invite; row text `enviado` / `falhou envio do e-mail`; resend updates status; remove notice under Meses; toast is the #76 child; out: new invite flow
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent: invites after toast; type Coordenador/Submitter; persisted email status enviado / falhou envio
- https://github.com/gutors/ai-accounting-assistant/issues/76 - closed; toast helper and mail-failure sentence this task must not put back under `Meses`
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screen `home`. Opened as a file in the repo. Coordinator `Convites pendentes` line today is email plus `Cancelar`; C13 amends that line. Tokens `caixa`/`margem` and the Pessoas two-column / full-width invites split are already in the opened file
- `.design/administration-list.md` - **binding** `Screen home invites`. Opened as a file in the repo. C14 amends the stale `Invite resend` Decisions row (still says the failure notice sits under `Meses`) and shows per-invite kind and last-delivery copy on the row
- `app/views/organizations/show.html.erb` - today’s pending row is email + `Reenviar e-mail` + `Cancelar`; `Invite.kind` is unused in the list
- `app/controllers/application_controller.rb` `#deliver_invite` / `#redirect_after_invite_mail` - SMTP rescue true/false; writes toast, not Invite
- `CONTEXT.md` - Invite, Coordinator, Submitter
- Open default in Unresolved 1 - existing pending rows show `enviado` until a delivery write runs

## Out of scope

- New invite create/resend/cancel flow, SMTP body, or `MAIL_FROM` — #78; existing controllers and `InviteMailer`
- Toast chrome, timeout, and `Pronto.` / mail-failure toast copy — #76, already shipped
- Home month list defaults — #77
- Administration welcome/invite mail — seller screens
- A third last-delivery value (`unsent` / null in the product copy) — #78 names only `sent` / `failed`
- Submitter home, standing Access lists, revoke — unchanged
- Magic-link proof of mailbox ownership
- Settling Unresolved 1 (default stays `sent`)

## Landing

Touches `Invite` (new NOT NULL `last_delivery`), `ApplicationController#deliver_invite` (writes that column after SMTP), coordinator home `organizations/show` (`Convites pendentes` row), and the two binding docs. Reuses existing `create` / `mail` / `destroy` controllers, `Invite.kind`, `Invite.order(:email)`, `#76` toast, and `require_coordinator_organization`. No new route.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Last delivery lives on the Invite | Each pending Invite stores the last `deliver_now` this app ran for that row as `sent` or `failed` (NOT NULL string column `last_delivery`, those two values only, existing rows and `create_pending` / `Invite.create!` default `sent`). Create and resend both write it before the redirect. Accept and Cancelar still destroy the row | Keep status only in `flash` / toast: a later `GET /` makes A look like B, which is the lie #78 names. A third `unsent` value: #78 copy is only `enviado` / `falhou envio do e-mail`. Revive `session[:invite_mail_failed]`: one boolean for every Invite |

- Nothing else in this change is hard to reverse (row layout, `data-row` hook)

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at its own layer **and** one request spec at HTTP | one asserted case per enumerated member at its own layer; status and who may call at the boundary | follow |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` names the level and the sampling rule: a decision is proven at its own layer, one asserted case per enumerated member; HTTP also gets a request spec; system specs only when a request spec cannot settle the claim
- `Invite#kind` already has a two-member enum proven in `spec/models/invite_spec.rb`. `last_delivery` is the same shape (`sent` / `failed`, `validate: true`) and lands there as C9
- Kind label and last-delivery copy are two two-row maps. Closest analogue: request HTML for home rows (`spec/requests/organizations_spec.rb` `data-row="month"`). This repo has no view specs. C1–C4, C6–C8 assert the copy at HTTP; C9 asserts the stored members at the model
- `ApplicationController#deliver_invite` stays the SMTP rescue. After this cut it also writes `last_delivery` (`sent` on success, `failed` on raise). That two-member table is reached over HTTP; C1/C4/C6/C7 are the boundary cases. Own-layer write is C9’s persisted values after those same outcomes (create success, create raise) plus the model enum
- Other-organization resend is an existing controller guard (`find_by` then `404`). C12 is the HTTP proof and that `last_delivery` is unchanged
- C13–C14 are file-read proofs of binding docs, same shape as `spec/docs/action_result_toast_spec.rb`

Cost: request examples for C1–C8 and C10–C12; model examples for C9; file-read examples for C13–C14. No system spec. Without the model enum cases, `sent`/`failed` would be proven only by the path that happens to render the row.

## Screens (ui)

Opened `.specs/features/visual-identity/design.md` (file in the repo) and `.design/administration-list.md` section `Screen home invites`. Coordinator `Convites pendentes` is a band on existing `home`, not a screen of its own. Submitter `home` has no pending list (task out of scope; existing `organizations_spec` “submitter home says Inicio”).

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `home` coordinator `Convites pendentes` | pending `li` text includes the email, `Coordenador` or `Submitter`, `enviado` or `falhou envio do e-mail`; `Reenviar e-mail` immediately before `Cancelar`; error toast copy stays #76 (`[data-toast-kind="error"]`); no `[data-notice="error"]` of the mail-failure sentence under `Meses` | `Convites pendentes` is an `h2` **full width after** the Pessoas two-column grid, not nested in it · one mixed list of both kinds · each pending item is one `li` whose email, kind label, and last-delivery copy sit on that row, then the two actions | `home` coordinator `Convites pendentes` — spacing, colour, type weight |

## Checks

Criteria 1–14 map to C1–C14. Unresolved 1 stays NOT NULL default `sent`.

### S1 - Kind on each pending row · 4 files · 35 KB · ~9k

`app/views/organizations/show.html.erb`, `spec/requests/coordinator_invites_spec.rb`, `spec/requests/submitter_invites_spec.rb`, `spec/requests/organizations_spec.rb`.

**C1** - Given `POST /coordinator_invites` persists Invite `pessoa@exemplo.org` and delivery succeeds, when the following `GET /` runs, then the pending item whose text includes `pessoa@exemplo.org` includes `Coordenador`, includes `enviado`, does not include `Submitter`, and still has `Reenviar e-mail` before `Cancelar`.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites pending row shows Coordenador and enviado"`

**C2** - Given `POST /submitter_invites` persists Invite `docs@exemplo.org` and delivery succeeds, when the following `GET /` runs, then the pending item whose text includes `docs@exemplo.org` includes `Submitter`, includes `enviado`, and does not include `Coordenador`.
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "POST /submitter_invites pending row shows Submitter and enviado"`

**C3** - Given pending Invites `ana@exemplo.org` (`coordinator`) and `zoe@exemplo.org` (`submitter`) on the focused organization, when `GET /` runs, then `ana@exemplo.org` appears before `zoe@exemplo.org`, the `ana@exemplo.org` item includes `Coordenador` and does not include `Submitter`, and the `zoe@exemplo.org` item includes `Submitter` and does not include `Coordenador`. Both items are `li` descendants of the section whose `h2` is `Convites pendentes`; that section is not nested in the Pessoas two-column grid.
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "home pending invites show kind in email order under Convites pendentes"`

### S2 - Last delivery is the row, not the session · 6 files · 43 KB · ~11k

`app/models/invite.rb`, `app/controllers/application_controller.rb`, `db/migrate/` (new `last_delivery` column), `spec/models/invite_spec.rb`, `spec/requests/coordinator_invites_spec.rb`, `spec/requests/layout_spec.rb`.

**C4** - Given `POST /coordinator_invites` persists the Invite and `deliver_now` raises, then that Invite remains, its last delivery is `failed`, the response is `302` to `/`, and the following `GET /` is `200` with `[data-toast-kind="error"]` text `O convite foi gravado, mas o e-mail não saiu.`, with no `[data-notice="error"]` that text, and with that pending item including `falhou envio do e-mail` and not `enviado`. Delivery still runs after the Invite commit; the error is still rescued.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites keeps the Invite when deliver_now raises"`

**C5** - Given that failed Invite `pessoa@exemplo.org` still pending, when `POST /coordinator_invites` for `nova@exemplo.org` delivers, then both Invites remain, the following `GET /` has `[data-toast-kind="success"]` text `Pronto.`, has no `[data-notice="error"]` text `O convite foi gravado, mas o e-mail não saiu.`, the `pessoa@exemplo.org` item includes `falhou envio do e-mail` and not `enviado`, and the `nova@exemplo.org` item includes `enviado` and not `falhou envio do e-mail`.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "a later invite send leaves the failed row failed"`

**C6** - Given a pending Invite whose last delivery is `failed`, when `POST .../mail` (`Reenviar e-mail`) delivers, then the following `GET /` has that item including `enviado` and not `falhou envio do e-mail`.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "resend overwrites failed last delivery with enviado"`

**C7** - Given a pending Invite whose last delivery is `sent`, when `POST .../mail` and `deliver_now` raises, then the Invite remains and the following `GET /` has that item including `falhou envio do e-mail` and not `enviado`.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "invite resend keeps the Invite when deliver_now raises"`

**C8** - Given the `GET /` after criterion 4, when a second `GET /` runs with no action in between, then the body has no `[data-toast]`, does not include `O convite foi gravado, mas o e-mail não saiu.`, and that pending item still includes `falhou envio do e-mail`.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "second GET after invite mail failure has no toast"`

**C9** - Always, a pending Invite stores last delivery as exactly `sent` or `failed`, and its home item includes exactly one of `enviado` or `falhou envio do e-mail`.
Proof: `bin/rspec spec/models/invite_spec.rb -e "last_delivery is sent or failed"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "home pending invite shows exactly one last-delivery copy"`

**C10** - When `DELETE` `Cancelar` deletes a pending Invite, then that Invite is gone, no message is delivered, and the following `GET /` does not include that email.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "Cancelar without a failure notice delivers nothing"`

**C11** - Given `session[:invite_mail_failed]` is `true` and `flash` has no toast, when `GET /` runs, then the status is `200`, the body has no `[data-toast]`, and it does not include `O convite foi gravado, mas o e-mail não saiu.` as `[data-notice="error"]` or under `Meses`.
Proof: `bin/rspec spec/requests/layout_spec.rb -e "GET / with empty flash has no toast"`

**C12** - If `POST` resend targets an Invite that belongs only to another organization, then the response is `404`, no message is delivered, and that Invite’s last delivery is unchanged.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "resend of another organization Invite returns 404"`

### S3 - Binding docs name the row · 3 files · 41 KB · ~10k

`.specs/features/visual-identity/design.md`, `.design/administration-list.md`, `spec/docs/invite_kind_and_mail_status_spec.rb`.

**C13** - `.specs/features/visual-identity/design.md` screen `home` (coordinator) `Convites pendentes` line includes email, `Coordenador` or `Submitter`, `enviado` or `falhou envio do e-mail`, and `Reenviar e-mail` immediately before `Cancelar`.
Proof: `bin/rspec spec/docs/invite_kind_and_mail_status_spec.rb -e "visual-identity design.md home Convites pendentes names kind and last delivery"`

**C14** - `.design/administration-list.md` section `Screen home invites` shows that per-invite copy on the row; the `Invite resend` Decisions row no longer says the failure notice sits under `Meses`.
Proof: `bin/rspec spec/docs/invite_kind_and_mail_status_spec.rb -e "administration-list home invites names per-invite copy not Meses notice"`

## Swept

- validation: existing — well-formed email, uniqueness, standing Access; C9 — last delivery is only `sent` or `failed`
- failure modes: C4, C7 — SMTP raise after persist; C12 — foreign Invite
- idempotency and retry: C6 — resend delivers again and overwrites last delivery; C8 — flash dies, row status remains
- authorization: existing `require_coordinator_organization`; C12 — other-organization resend `404`
- concurrency and ordering: n/a — one session writes one Invite row; two overlapping resends leave the last write; unique email is existing
- data lifecycle: C10 — Cancelar deletes the Invite and its last delivery; existing `accept!` also destroys the row
- external-dependency failure: C4, C7 — `deliver_now` still rescued; last delivery becomes `failed`
- state transitions: C4, C6, C7, C10
- observability: n/a — the source names no log, metric, or trace; the person reads the row

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| Invite kind on the pending row (2) | `coordinator` → `Coordenador` C1, C3 · `submitter` → `Submitter` C2, C3 | - |
| last_delivery stored values (2) | `sent` C1, C6, C9 · `failed` C4, C7, C9 | - |
| last_delivery transitions (5) | create success → `sent` C1 · create raise → `failed` C4 · resend success `failed`→`sent` C6 · resend raise `sent`→`failed` C7 · Cancelar destroys C10 | - |
| mixed pending list (2 emails, email order) | `ana@exemplo.org` before `zoe@exemplo.org` C3 | - |
| leftover session channel (2 absences) | no `[data-toast]` C11 · no mail-failure `[data-notice="error"]` or under `Meses` C11 | - |
| resend target organization (2) | focused org C6 · other org `404` C12 | - |
| designed screens (2 home variants) | `home` coordinator `Convites pendentes` C1–C3, C13 · `home` submitter (no pending list) existing `organizations_spec` “submitter home says Inicio” | - |

- Claims naming a status code, route or response shape: C1, C2, C4, C5, C6, C7, C8, C10, C11, C12 - each has a proof that crosses the HTTP boundary
- No other check claims more than the single case its proof exercises
- C13–C14 are document proofs, not HTTP

## Handoff

S1 = ~9k (home ERB + request specs). S2 = ~11k (Invite column, `deliver_invite`, request + model). S3 = ~10k (two binding docs). Running total S1–S3 ≈ 30k, under 150k, and S3 is a docs surface change rather than a mid-slice cut. One batch; no build handoff.
