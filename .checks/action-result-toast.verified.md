# Action result toast Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: f78dfd0..4938e2c
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Opened as files in the repo except #76, which was opened with `gh issue view 76` (WebFetch from this agent was blocked).

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.tasks/action-result-toast.md` | yes - repo file | none vs C1–C26 (Unresolved 1–3 stay `Pronto.` / `Fechar` / `5000`) | — |
| https://github.com/gutors/ai-accounting-assistant/issues/76 | yes - `gh issue view 76` | none: top banner, ~5s, dismissible, listed action results, field validation stays, `422` `:base`/notice also toasts, replace stuck invite-mail notice, per-invite status is #78, extend visual-identity, profile ui | month-open `:base` `422` is implemented (`toast_now` in `MonthsController#create`) and not a checklist member; the task’s `422` set is the four rows C23–C26 |
| `.specs/features/visual-identity/design.md` | yes - repo file | none: Toast after `header` before `main`; success `caixa` + white; error `margem` rule not `[data-notice]`; `5000` / `Fechar`; Motion names toast timeout with `<details>`; reduced-motion keeps `5000` | login / denied / month screens unbound (checklist Unproven). Home ASCII still omits the layout toast (Toast component is the arrangement authority) |
| `.design/administration-list.md` | yes - repo file | none vs C12 on section `Screen home invites` (error toast, not notice under `Meses`; per-invite status #78) | Decisions table row `Invite resend` still says the failure notice sits under `Meses` — stale prose outside the section C12 names; not a different screen composition |

Screens table vs design (selector-reachable): layout absent / success / error, home (no action, mail fail, listed success), documents (`:base` `422` and insert success), setup (`:base` `422` and listed success) each have a check. Visual unproven is enumerated (spacing, colour, type weight) per screen — not a blanket fidelity waiver.

Arrangement: one `[data-toast]` between `header` and `main`; notice remains under the page `h1` on documents/setup; home mail failure is the layout toast, not `[data-notice="error"]` under `Meses`. C2/C3 assert the layout slot; C8/C23/C24 assert notice vs toast copy.

## Checks

Proofs run at `4938e2c` in one `bin/rspec` invocation (`--example-matches` alternation over the named examples). **29 examples, 0 failures** (27 named proofs plus substring extras: `submitter POST /focus…`, `submitter POST recibo jpg…`). JSON example list in `/tmp/toast-proofs.json`. Each named example exists under `spec/` (rg) and appears as `passed` in that run. Spec files are in `f78dfd0..HEAD`.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | GET `/` empty flash: `200`, no `[data-toast]`, no stuck mail sentence | `layout_spec.rb` `-e "GET / with empty flash has no toast"` passed | `spec/requests/layout_spec.rb:108` `have_http_status(:ok)`; `:109` `toast_node(…).to be_nil`; `:110` `not_to include("O convite foi gravado, mas o e-mail não saiu.")` | PASS |
| C2 | success toast after `header` before `main`; `role="status"`; `Fechar`; `bg-caixa` `text-white`; `5000`; not `[data-notice]` | `layout_spec.rb` `-e "success toast sits after header before main"` passed | `layout_spec.rb:121` size 1; `:123` kind success; `:124` role status; `:125` timeout `5000`; `:126` `Pronto.`; `:127` `Fechar`; `:128–129` `bg-caixa` `text-white`; `:130–131` no `data-notice`; `:132–133` `header.next_element` toast, `toast.next_element` `main` | PASS |
| C3 | error toast same place; `role="alert"`; `text-margem` `border-l-[3px]` `border-margem`; `5000`; `Fechar` | `layout_spec.rb` `-e "error toast sits after header before main"` passed | `layout_spec.rb:149` kind error; `:150` role alert; `:151` `5000`; `:153` `Fechar`; `:154–156` margem classes; `:157–158` same header/main neighbours | PASS |
| C4 | `Fechar` removes toast before `5000` ms | `toast_spec.rb` `-e "Fechar removes the toast before timeout"` passed | `spec/system/toast_spec.rb:34` `click_button "Fechar"`; `:35` `have_no_css("[data-toast]", wait: 1)` | PASS |
| C5 | toast gone after `5000` ms | `toast_spec.rb` `-e "toast is gone after 5000 ms"` passed | `spec/system/toast_spec.rb:40` `have_no_css("[data-toast]", wait: 6)` | PASS |
| C6 | no toast CSS `transition`/`@keyframes`; reduced-motion keeps `5000` | stylesheet + system examples both passed | `spec/requests/stylesheet_spec.rb:75` `not_to include("@keyframes")`; `:76–78` `[data-toast]` rules `not_to include("transition")`; `spec/system/toast_spec.rb:63–64` still present then gone under mocked `matchMedia` | PASS |
| C7 | design.md Toast + Motion timeout | `action_result_toast_spec.rb` `-e "visual-identity design.md names Toast and Motion timeout"` passed | `spec/docs/action_result_toast_spec.rb:7–15` `### Toast`, header/main, caixa/margem, `5000`, `Fechar`; not old “only state change”; `/toast timeout/i` | PASS |
| C8 | create SMTP raise: Invite kept, `session[:invite_mail_failed]` not true, `302` `/`, GET toast error copy, no that text on `[data-notice="error"]` | `coordinator_invites_spec.rb` `-e "POST /coordinator_invites keeps the Invite when deliver_now raises"` passed | `coordinator_invites_spec.rb:132–134` invite present, session not true, `:found`; `:135` redirect `/`; `:137–140` toast error + copy; `:144` notice-with-mail nil. Delivery-after-commit is the interceptor raise plus persisted Invite (no separate `deliver_now` spy) | PASS |
| C9 | second GET no toast / no mail sentence | `-e "second GET after invite mail failure has no toast"` passed | `coordinator_invites_spec.rb:157–158` `toast_node` nil; body excludes the sentence | PASS |
| C10 | resend SMTP raise matches C8 toast/notice | `-e "invite resend keeps the Invite when deliver_now raises"` passed | `coordinator_invites_spec.rb:190` invite remains; `:193–198` error toast copy; notice-with-mail nil | PASS |
| C11 | Cancelar: Invite gone, no mail, `Pronto.` success toast, no failure sentence | `-e "Cancelar shows Pronto toast and does not keep the mail failure"` passed | `coordinator_invites_spec.rb:210–211` invite nil, deliveries empty; `:213–215` success `Pronto.`; sentence absent | PASS |
| C12 | administration-list `Screen home invites` names error toast / #78 | `-e "administration-list home invites names the error toast"` passed | `spec/docs/action_result_toast_spec.rb:22–25` section includes `error toast` and `#78`; excludes old Meses-notice sentences | PASS |
| C13 | coordinator invite success `Pronto.`; no error notice; pending email `Reenviar e-mail` then `Cancelar` | `-e "POST /coordinator_invites delivers the coordinator invite"` passed | `coordinator_invites_spec.rb:47–48` success `Pronto.`; `:49` error notices empty; `:52` resend index `<` Cancelar | PASS |
| C14 | submitter invite success `Pronto.` | `-e "POST /submitter_invites delivers the submitter invite"` passed | `spec/requests/submitter_invites_spec.rb:38–39` kind success, `Pronto.` | PASS |
| C15 | resend success `Pronto.` | `-e "resend on another Invite delivers Pronto toast"` passed | `coordinator_invites_spec.rb:177–178` success `Pronto.` | PASS |
| C16 | POST `/months` `2026-05` `302` to `/months/2026-05` then `Pronto.` | `-e "POST /months 2026-05 persists Month and redirects"` passed | `spec/requests/months_spec.rb:30–31` `:found` redirect `/months/2026-05`; `:34–35` success `Pronto.` | PASS |
| C17 | POST `/focus` `302` `/`, `Pronto.`, ONG Sul `aria-current="true"` | `-e "POST /focus to an Access organization redirects"` passed | `spec/requests/focus_spec.rb:13–14` found, redirect `/`; `:16–17` `Pronto.`; `:20` `aria-current` true | PASS |
| C18 | POST recibo `302` `/supporting_documents` then `Pronto.` | `-e "POST recibo jpg persists Padaria Central Recibo and redirects"` passed | `spec/requests/supporting_documents_spec.rb:101–102` found, redirect; `:106–107` success `Pronto.` | PASS |
| C19 | PATCH accountant `302` `/setup` then `Pronto.` | `-e "PATCH /accountant persists presentation name and redirects"` passed | `spec/requests/accountants_spec.rb:10–11` found, redirect `/setup`; `:16–17` `Pronto.` | PASS |
| C20 | PATCH package archive `302` `/setup` then `Pronto.` | `-e "PATCH /package_archive persists folders URL and folder id"` passed | `spec/requests/package_archives_spec.rb:12–13` found, redirect `/setup`; `:20–21` `Pronto.` | PASS |
| C21 | POST certificate `302` `/setup` then `Pronto.` | `-e "POST /sefaz_certificate persists pfx and redirects"` passed | `spec/requests/sefaz_certificates_spec.rb:20–21` found, redirect `/setup`; `:31–32` `Pronto.` | PASS |
| C22 | DELETE certificate `302` `/setup`, `Pronto.`, `Nenhum certificado` | `-e "DELETE /sefaz_certificate clears the slot and redirects"` passed | `sefaz_certificates_spec.rb:202–203` found, redirect `/setup`; `:206` `Nenhum certificado`; `:208–209` `Pronto.` | PASS |
| C23 | document `:base` `422`: notice and error toast `Envie a foto do recibo` | `-e "document error renders as a data-notice error alert"` passed | `supporting_documents_spec.rb:204` `:unprocessable_content`; `:205` notice text; `:207–208` toast error includes same string | PASS |
| C24 | certificate `:base` `422`: notice and toast `O certificado deve ser e-CNPJ A1 vigente` | `-e "certificate error renders as a data-notice error alert"` passed | `sefaz_certificates_spec.rb:89` unprocessable; `:90` notice; `:92–93` toast error same string | PASS |
| C25 | invite `nao-e-email` `422`, no Invite, no `[data-toast]` | `-e "rejected invite emails return 422"` passed | `coordinator_invites_spec.rb:73` includes `nao-e-email`; `:78` no Invite change; `:79` unprocessable; `:81` `toast_node` nil. “No new field notice” is not a located assertion (precision on that clause only) | PASS |
| C26 | PATCH accountant without presentation name `422`, no `[data-toast]` | `-e "PATCH /accountant without presentation name returns 422"` passed | `accountants_spec.rb:97` unprocessable; `:102` `toast_node` nil. “Existing field behaviour unchanged” is not a located selector | PASS |

## Coverage (recomputed)

Members taken from the checklist / issue action list / design screens, not from the author’s table as authority.

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| toast chrome states (3) | absent C1 · success C2 · error C3 | — |
| toast dismiss paths (2) | `Fechar` C4 · `5000` ms C5 | — |
| motion (2) | stylesheet C6 · reduced-motion C6 | — |
| invite mail-failure outcomes (4) | create C8 · second GET C9 · resend C10 · Cancelar C11 | — |
| listed success actions (10) | C13–C22 | — |
| `422` toast vs field (4) | C23–C26 | — |
| `flash[:toast_kind]` (2) | success C2 · error C3 | — |
| designed screens this cut binds (3) | `home` C1, C8, C13 · `documents` C18, C23 · `setup` C19–C22, C24, C26 | — |
| visual-identity screens unbound (3) | — | `login`, `denied`, `month` — out of scope |
| layout toast visual (3×3) | — | spacing, colour, type weight |

No extra enumeration in Landing (`success`/`error` flash kinds) without a proof. Status/route claims C1, C8, C11, C16–C26 assert at the request (or system) boundary.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | invite/month/focus/document/accountant/archive/certificate controllers writing `flash` / `flash.now` | HTTP request examples C8–C26; chrome C1–C3 | yes — HTML/status at request layer; no new model table (author evidence: no view specs; analogue `layout_spec` / existing `@document_error` examples) |
| Decides, not reached across a boundary | layout toast ERB + Stimulus timeout/dismiss | own layer: request HTML C1–C3; system C4–C6 (request cannot elapse `5000` ms) | yes |
| Entry point that decides nothing | n/a this cut | — | n/a |
| Instrumentation / pass-through | `redirect_with_toast` / `toast_now` helpers | consumer proofs | yes — consumers C8–C26 |

`rails.mdc` system-spec rule: C4–C6 are the browser APIs a request spec cannot settle.

## Swept existing

- `require_account` `app/controllers/application_controller.rb:8`; `require_focused_organization` `:52`; `require_coordinator_organization` `:56`
- `load_home` `:74–81` does not read `session[:invite_mail_failed]`
- `sign_in` `:151` `reset_session`
- `deliver_invite` `:83–93` still `deliver_now` + `rescue` → boolean

Cited constraints are present.

## Faults injected

Scratch: `git worktree add /tmp/action-result-toast-verify-wt HEAD`. Real-tree porcelain before and after: `?? .tasks/action-result-toast.md`. Worktree removed.

| Mutation | Location | Killed |
|---|---|---|
| `data-toast-timeout-ms="5000"` → `"100"` | `app/views/shared/_toast.html.erb` | yes — C2 failed |
| `dismiss()` no longer `remove()` | `app/javascript/controllers/toast_controller.js` | yes — C4 failed |
| `connect()` skips `setTimeout` | `toast_controller.js` | yes — C5 failed |
| invite SMTP failure `redirect_to` without error flash | `ApplicationController#redirect_after_invite_mail` | yes — C8 failed |
| omit `toast_now` on document create `:base` | `SupportingDocumentsController#create` | yes — C23 failed |

Cap 5. Distinct surfaces: layout attr, dismiss, timeout, invite flash, `:base` toast.

## Gate

`bin/rspec` (files named in the checklist proofs, `--example-matches` union of C1–C26 example strings) — **29 passed, 0 failed** at `4938e2c`.
