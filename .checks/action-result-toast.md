# Action result toast

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/action-result-toast.md` marks the layout toast plus screens `home`, `documents`, and `setup` binding through `.specs/features/visual-identity/design.md`.

Sources:

- `.tasks/action-result-toast.md` - criteria 1–26, the state diagram, the sweep, the two doors, and the boundary. Unresolved 1–3 stay open (`Pronto.`, `Fechar`, `5000` ms)
- https://github.com/gutors/ai-accounting-assistant/issues/76 - **binding for this slice**: toast at the top, ~5s, dismissible, listed action results, field validation stays, `422` `:base`/notice also toasts, replace `session[:invite_mail_failed]`, per-invite status is the invites child, extend visual-identity design
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent: toast first; later children set the same `flash` keys; toast only for action result
- `.specs/features/visual-identity/design.md` - **binding for the interface**: layout toast plus screens `home`, `documents`, `setup`. Opened as a file in the repo. The file already has Notice (`[data-notice="error"]` under the title, `margem` rule), tokens `caixa`/`margem`, Motion (`<details>` as the only state change), and `prefers-reduced-motion` (no transitions or keyframes). It has no Toast component yet — C7 adds it. Toast arrangement and copy in C2–C6 are the values the task transcribed; colour tokens come from the opened file, not hex from a mock
- `.design/administration-list.md` - **binding for screen `home` invites** on the mail-failure paragraph C12 amends. Opened as a file in the repo. Section `Screen home invites` today still draws the stuck notice under `Meses`
- `app/views/shared/_notice.html.erb` - existing error notice: `role="alert"` `data-notice="error"` `border-l-[3px] border-margem pl-3 text-margem`
- `app/views/layouts/application.html.erb` - `header` then `main`; no toast node today
- `app/javascript/controllers/` - Stimulus is eager-loaded; `hello_controller.js` is unused. Browser timeout and dismiss are Stimulus events
- `DESIGN.md` / tokens in `app/assets/tailwind/application.css` - `bg-caixa`, `text-margem`, `border-margem`

## Out of scope

- Persisted email status on each pending invite row — #78
- Home month-field defaults and the limited month list — #77
- Document insert form layout — #79
- Setup copy, counters, bank accounts, extra exception kinds — #80–#84
- Keeping typed fields on document and A1 `422` — #85
- Administration notices, welcome mail, and `session[:administration_result]` — seller screens keep `[data-notice="error"]`; they do not use this toast
- Login, denied, OIDC, `DELETE /session`
- Month close-for-send, restore, reopen, matches, document exceptions, bank statements, justifications, accesses `Revogar`, extra-kind and bank-account mutations — later children set the same `flash` keys
- Inventing field notices on home invite or accountant `422` where the page has none today (C25, C26)
- Per-action success sentences beyond `Pronto.` unless Unresolved 1 is overridden
- Settling Unresolved 1–3

## Landing

Touches the application layout, a Stimulus toast controller, invite create/mail/cancel, `ApplicationController#load_home` / `deliver_invite` callers, home `organizations/show`, month open, focus, document insert, accountant, package archive, and certificate install/remove. Reuses Rails `flash` / `flash.now`, `_notice.html.erb` for `:base` on the page, and existing `302`/`422` paths. No new table.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| One-shot channel | Rails `flash[:toast]` is the message string; `flash[:toast_kind]` is `success` or `error`. Redirects use `flash`; `422` re-renders use `flash.now`. The application layout is the only renderer. Later #75 children set these keys; they do not invent a second banner | Keep `session[:invite_mail_failed]`: it sticks across Cancel and unrelated GETs, which #76 replaces. A new session boolean per action would repeat that stickiness |
| Action-result UI | Layout `[data-toast]` immediately after `header` and before `main`; success `caixa` fill; error `margem` rule like `[data-notice="error"]` but not that notice; timeout `5000` ms; dismiss `Fechar`. Stimulus removes the node (browser timer). Design.md Motion lists this timeout as a result of the action that set the toast | Reuse `[data-notice="error"]` under each `h1`: that is the field and `:base` notice #76 keeps, and it has no success colour. A page-local banner under `Meses` is what this slice removes |

- Nothing else in this change is hard to reverse

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
- Layout chrome (`absent` / `success` / `error`) is a view decision with no model table. Closest analogue: `spec/requests/layout_spec.rb` and `[data-notice="error"]` examples in `spec/requests/supporting_documents_spec.rb` — request specs assert HTML. This repo has no view specs
- Invite SMTP rescue already lives in `ApplicationController#deliver_invite` (true/false). Callers today write `session[:invite_mail_failed]`; they will write `flash` instead. The HTTP outcomes are already in `spec/requests/coordinator_invites_spec.rb`. No new model branch
- Stimulus timeout and `Fechar` are browser APIs. Closest analogue: `spec/system/screens_spec.rb` (Cuprite). No JS unit runner. C4–C6 are system (and stylesheet) proofs because a request spec cannot elapse `5000` ms in the browser
- `:base` vs field-only `422` is a two-member controller table proven at HTTP by C23–C26. Same shape as today’s `@document_error` / `@certificate_error` request examples

Cost: request examples for C1–C3, C8–C26; system examples for C4–C6; stylesheet example for no toast `transition`/`@keyframes`; file-read examples for C7 and C12. No new model spec. Without the system proofs, dismiss and timeout would be unproven.

## Checks

Criteria 1–26 map to C1–C26. Unresolved 1–3 stay `Pronto.`, `Fechar`, and `5000` ms.

### S1 - Toast chrome · 8 files · 33 KB · ~8k

**C1** - Given a signed-in coordinator on the focused organization and no toast in `flash`, when `GET /` runs, then the status is `200`, the body has no `[data-toast]`, and it does not include `O convite foi gravado, mas o e-mail não saiu.`
Proof: `bin/rspec spec/requests/layout_spec.rb -e "GET / with empty flash has no toast"`

**C2** - When a success toast is present, then the layout renders one `[data-toast][data-toast-kind="success"]` immediately after `header` and before `main`, with `role="status"`, the message text, a `button` whose text is `Fechar`, classes that include `bg-caixa` and `text-white`, and `data-toast-timeout-ms="5000"`. It does not use `[data-notice]`.
Proof: `bin/rspec spec/requests/layout_spec.rb -e "success toast sits after header before main"`

**C3** - When an error toast is present, then the layout renders one `[data-toast][data-toast-kind="error"]` in that same place, with `role="alert"`, the message text, a `button` `Fechar`, classes that include `text-margem` and `border-l-[3px]` and `border-margem`, and `data-toast-timeout-ms="5000"`.
Proof: `bin/rspec spec/requests/layout_spec.rb -e "error toast sits after header before main"`

**C4** - When `Fechar` on a visible toast is activated, then that `[data-toast]` node is gone before `5000` ms elapse.
Proof: `bin/rspec spec/system/toast_spec.rb -e "Fechar removes the toast before timeout"`

**C5** - While a toast is visible and `5000` ms elapse without `Fechar`, that `[data-toast]` node is gone.
Proof: `bin/rspec spec/system/toast_spec.rb -e "toast is gone after 5000 ms"`

**C6** - Always, this task ships no CSS `transition` or `@keyframes` for the toast. `prefers-reduced-motion` does not change the `5000` ms timeout.
Proof: `bin/rspec spec/requests/stylesheet_spec.rb -e "served stylesheet ships no toast transition or keyframes"`
Proof: `bin/rspec spec/system/toast_spec.rb -e "toast timeout stays 5000 ms under prefers-reduced-motion"`

**C7** - `.specs/features/visual-identity/design.md` contains a Toast component: position immediately after `header` and before `main`, success colour `caixa`, error colour `margem`, timeout `5000` ms, dismiss `Fechar`; and the Motion bullet no longer claims that `<details>` opening is the only state change — it names the toast timeout as the other user-triggered result (the action that produced the toast).
Proof: `bin/rspec spec/docs/action_result_toast_spec.rb -e "visual-identity design.md names Toast and Motion timeout"`

### S2 - Invite mail is one-shot, not stuck under Meses · 6 files · 46 KB · ~11k

**C8** - Given `POST /coordinator_invites` persists the Invite and `deliver_now` raises, then the Invite remains, `session[:invite_mail_failed]` is not `true`, the response is `302` to `/`, and the following `GET /` is `200` with `[data-toast-kind="error"]` text `O convite foi gravado, mas o e-mail não saiu.` and with no `[data-notice="error"]` that text. Delivery still runs after the Invite commit; the error is still rescued.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites keeps the Invite when deliver_now raises"`

**C9** - Given that following `GET /` showed the error toast, when a second `GET /` runs with no action in between, then the body has no `[data-toast]` and does not include `O convite foi gravado, mas o e-mail não saiu.`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "second GET after invite mail failure has no toast"`

**C10** - Given a pending Invite, when `POST .../mail` (`Reenviar e-mail`) runs and `deliver_now` raises, then the Invite remains and the following `GET /` matches the toast and notice absences in C8.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "invite resend keeps the Invite when deliver_now raises"`

**C11** - Given the error toast from C8 would have been the stuck notice, when `DELETE` `Cancelar` deletes that Invite, then the Invite is gone, no message is delivered, and the following `GET /` has `[data-toast-kind="success"]` text `Pronto.` and does not include `O convite foi gravado, mas o e-mail não saiu.`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "Cancelar shows Pronto toast and does not keep the mail failure"`

**C12** - `.design/administration-list.md` section `Screen home invites` no longer says a failed send is a notice under the `Meses` title that `Cancelar` does not clear; it says that failure is the error toast in C8–C10 and that per-invite mail status is #78.
Proof: `bin/rspec spec/docs/action_result_toast_spec.rb -e "administration-list home invites names the error toast"`

### S3 - Listed successes · 16 files · 196 KB · ~49k

**C13** - Given `POST /coordinator_invites` persists the Invite and delivery succeeds, when the following `GET /` runs, then the body has `[data-toast-kind="success"]` text `Pronto.`, has no `[data-notice="error"]` for that send, and includes the pending email with `Reenviar e-mail` then `Cancelar`.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites delivers the coordinator invite"`

**C14** - Given `POST /submitter_invites` persists a submitter Invite and delivery succeeds, when the following `GET /` runs, then the body has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "POST /submitter_invites delivers the submitter invite"`

**C15** - Given a pending Invite, when `POST .../mail` delivers, then the following `GET /` has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "resend on another Invite delivers Pronto toast"`

**C16** - When `POST /months` with `year_month` `2026-05` persists the Month, then the response is `302` to `/months/2026-05` and the following `GET` has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months 2026-05 persists Month and redirects"`

**C17** - Given the Account has coordinator Access to `ONG Norte` (focused) and `ONG Sul`, when `POST /focus` with `ONG Sul`’s id runs, then the response is `302` to `/`, the following `GET /` has `[data-toast-kind="success"]` text `Pronto.`, and the `ONG Sul` switcher control has `aria-current="true"`.
Proof: `bin/rspec spec/requests/focus_spec.rb -e "POST /focus to an Access organization redirects"`

**C18** - When `POST /supporting_documents` inserts a recibo with photo and the other required fields, then the response is `302` to `/supporting_documents` and the following `GET` has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo jpg persists Padaria Central Recibo and redirects"`

**C19** - When `PATCH /accountant` persists a valid accountant, then the response is `302` to `/setup` and the following `GET` has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant persists presentation name and redirects"`

**C20** - When `PATCH /package_archive` persists a Drive folder URL, then the response is `302` to `/setup` and the following `GET` has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive persists folders URL and folder id"`

**C21** - When `POST /sefaz_certificate` installs a valid e-CNPJ A1, then the response is `302` to `/setup` and the following `GET` has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST /sefaz_certificate persists pfx and redirects"`

**C22** - Given a certificate is installed, when `DELETE /sefaz_certificate` runs, then the response is `302` to `/setup` and the following `GET` has `[data-toast-kind="success"]` text `Pronto.` and includes `Nenhum certificado`.
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "DELETE /sefaz_certificate clears the slot and redirects"`

### S4 - Action 422 keeps the notice and adds a toast; field 422 does not · 4 files · 120 KB · ~30k

**C23** - When `POST /supporting_documents` is a recibo without photo, then the status is `422`, `[data-notice="error"]` is `Envie a foto do recibo`, and `[data-toast-kind="error"]` is `Envie a foto do recibo`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "document error renders as a data-notice error alert"`

**C24** - When `POST /sefaz_certificate` is rejected as not a vigente e-CNPJ A1, then the status is `422`, `[data-notice="error"]` is `O certificado deve ser e-CNPJ A1 vigente`, and `[data-toast-kind="error"]` is that same string.
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "certificate error renders as a data-notice error alert"`

**C25** - When `POST /coordinator_invites` submits `nao-e-email`, then the status is `422`, no Invite is written, the body has no `[data-toast]`, and there is no new field notice this task adds.
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "rejected invite emails return 422"`

**C26** - When `PATCH /accountant` without presentation name returns `422`, then no toast is present (`[data-toast]` absent). Existing field behaviour is unchanged.
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant without presentation name returns 422"`

## Screens (ui)

Design opened: `.specs/features/visual-identity/design.md` (file in the repo). Toast is added there by C7; until then the arrangement values are the task transcription plus Notice/tokens already in that file. Home-invites copy change is `.design/administration-list.md` opened as a file.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| layout toast, absent | no `[data-toast]`; no `O convite foi gravado, mas o e-mail não saiu.` C1 | `header` then `main`; no toast node between them C1 | spacing, colour, type weight |
| layout toast, success | one `[data-toast][data-toast-kind="success"]` `role="status"`; message; `button` `Fechar`; `data-toast-timeout-ms="5000"`; not `[data-notice]` C2 | that node immediately after `header` and before `main`; classes include `bg-caixa` and `text-white` C2 | spacing, colour, type weight |
| layout toast, error | one `[data-toast][data-toast-kind="error"]` `role="alert"`; message; `button` `Fechar`; `data-toast-timeout-ms="5000"` C3 | same place as success; classes include `text-margem`, `border-l-[3px]`, `border-margem` C3 | spacing, colour, type weight |
| home, no action | `h1` `Meses`; empty months `Nenhum mês aberto` stays; no stuck mail sentence C1 | no `[data-notice="error"]` under `Meses` for invite mail C1, C8 | spacing, colour, type weight |
| home, invite mail fail | `[data-toast-kind="error"]` `O convite foi gravado, mas o e-mail não saiu.` C8, C10 | toast in the layout slot, not `[data-notice="error"]` under `Meses` C8 | spacing, colour, type weight |
| home, listed success | `[data-toast-kind="success"]` `Pronto.`; pending email with `Reenviar e-mail` then `Cancelar` C13 | toast in the layout slot C2, C13 | spacing, colour, type weight |
| documents, `:base` 422 | `[data-notice="error"]` `Envie a foto do recibo` and `[data-toast-kind="error"]` that same string C23 | notice stays under the page title; toast is extra in the layout slot C23 | spacing, colour, type weight |
| documents, insert success | `[data-toast-kind="success"]` `Pronto.` after redirect C18 | toast in the layout slot C18 | spacing, colour, type weight |
| setup, certificate `:base` 422 | `[data-notice="error"]` `O certificado deve ser e-CNPJ A1 vigente` and `[data-toast-kind="error"]` that same string C24 | notice stays under the title; toast is extra in the layout slot C24 | spacing, colour, type weight |
| setup, listed success | `[data-toast-kind="success"]` `Pronto.` C19–C22; after remove, `Nenhum certificado` C22 | toast in the layout slot C19–C22 | spacing, colour, type weight |

## Swept

- validation: C25, C26 — field-only `422` does not toast; C23, C24 toast the existing `:base` string and keep the notice
- failure modes: C8, C10 — SMTP raise after Invite commit; C23, C24 — `:base` `422`
- idempotency and retry: C9 — flash is discarded after the GET that renders it; a second GET has no toast. Resend still delivers again (existing)
- authorization: existing — `require_account`, `require_coordinator_organization`, `require_focused_organization`; `404`/`302` paths do not set a toast
- concurrency and ordering: n/a — one session cookie; two overlapping POSTs leave whichever `flash` was written last; no shared toast store
- data lifecycle: C8, C9 — `session[:invite_mail_failed]` is not kept as the mail-failure channel; leftover true on an old session is not read (`load_home` does not paint that sentence). Rails `flash` dies with `reset_session` on sign-in (existing `sign_in`)
- external-dependency failure: C8, C10 — invite SMTP; certificate and document `:base` strings stay the product copy (C23, C24)
- state transitions: C4, C5, C8, C9, C11
- observability: n/a — the source names no log, metric, or trace; the person sees the toast

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| toast chrome states (3) | absent C1 · success C2 · error C3 | - |
| toast dismiss paths (2) | `Fechar` C4 · `5000` ms C5 | - |
| motion (2) | no toast `transition`/`@keyframes` C6 · timeout unchanged under `prefers-reduced-motion` C6 | - |
| invite mail-failure outcomes (4) | create SMTP raise C8 · second GET discards flash C9 · resend SMTP raise C10 · Cancelar success toast C11 | - |
| listed success actions (10) | coordinator invite C13 · submitter invite C14 · resend C15 · open month C16 · focus C17 · document insert C18 · accountant C19 · package archive C20 · A1 install C21 · A1 remove C22 | - |
| `422` toast vs field (4) | document `:base` C23 · certificate `:base` C24 · invite field-only C25 · accountant field-only C26 | - |
| `flash[:toast_kind]` (2) | `success` C2 · `error` C3 | - |
| designed screens this cut binds (3) | `home` C1, C8, C13 · `documents` C18, C23 · `setup` C19–C22, C24, C26 | - |
| visual-identity screens this cut does not bind (3) | — | `login`, `denied`, `month` — out of scope |
| layout toast visual (3 properties × 3 states) | — | spacing, colour, type weight on absent, success, and error |

- Claims naming a status code, route, or response shape: C1, C8, C11, C16–C26 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~8k + S2 ~11k + S3 ~49k + S4 ~30k = ~98k token floor if those spec files are counted in full each time they are named. Read once, `supporting_documents_spec.rb` and `months_spec.rb` are not paid twice; unique files sit under ~70k plus the opened design (~5k). All four slices stay under 150k and share the layout toast. No split. One batch.

Batch closed. Checks C1–C26 on this branch. No mid-build clarification. Abandoned: CDP `Emulation.setEmulatedMedia` for reduced-motion — Ferrum did not expose it; the C6 system example mocks `matchMedia` instead.
