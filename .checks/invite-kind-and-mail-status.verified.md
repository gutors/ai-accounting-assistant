# Invite kind and mail status Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: d66e199ca79f5b3376e5b1fde0ab638dce3e3ff0..0cfb8017ac667d1b84e25f0c698f34465f5b33f6
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Opened as files in the repo except #78, which was opened with `gh issue view 78` (WebFetch from this agent was blocked).

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.tasks/invite-kind-and-mail-status.md` | yes - repo file | none vs C1–C14 (Unresolved 1 stays NOT NULL default `sent`) | — |
| https://github.com/gutors/ai-accounting-assistant/issues/78 | yes - `gh issue view 78` | none: pending row Coordenador/Submitter; persist `sent`/`failed`; copy `enviado` / `falhou envio do e-mail`; resend updates status; no Meses notice; toast is #76; out: new invite flow | — |
| `.specs/features/visual-identity/design.md` screen `home` | yes - repo file | none: coordinator `Convites pendentes` is a band on `home` (not its own screen); ASCII line is email, `Coordenador\|Submitter`, `enviado\|falhou envio do e-mail`, `Reenviar e-mail` then `Cancelar`; Pessoas two-column then full-width invites | HTTP proofs do not assert sibling order of the `Convites pendentes` `h2` after `Pessoas` (C3 asserts non-nesting). Design ASCII order is in the C13 home excerpt |
| `.design/administration-list.md` `Screen home invites` | yes - repo file | none: per-invite kind and last-delivery on the row; `Invite resend` no longer says the failure notice sits under `Meses` | ASCII wraps actions onto a second line; C1/C14 still treat them as the same `li` (selector-reachable composition matches) |

Screens table vs design (selector-reachable): coordinator `Convites pendentes` copy (email, kind, last-delivery, `Reenviar e-mail` before `Cancelar`), mixed one list, each pending item one `li`, section not nested in the Pessoas grid, error toast from #76, no mail-failure `[data-notice="error"]` under `Meses`. Submitter `home` has no pending list (existing `organizations_spec` “submitter home says Inicio”). Visual unproven is enumerated (`home` coordinator `Convites pendentes` — spacing, colour, type weight) — not a blanket fidelity waiver.

## Checks

Proofs run at `0cfb801` in one `bin/rspec` invocation over the six spec files with fifteen `-e` names (C9 has two proofs). First attempt used a single `|` string and matched **0 examples with exit 0**; re-run with one `-e` per name. **15 examples, 0 failures**. JSON list from `--format json --out /tmp/invite-c1-c14.json`. Each named example exists under `spec/` (rg) and appears as `passed`. Spec files are in `d66e199..HEAD`.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | POST coordinator invite `pessoa@exemplo.org` succeeds; GET `/` item has `Coordenador`, `enviado`, not `Submitter`; `Reenviar e-mail` before `Cancelar` | `coordinator_invites_spec.rb` `-e "POST /coordinator_invites pending row shows Coordenador and enviado"` passed | `spec/requests/coordinator_invites_spec.rb:74–77` `include("Coordenador")`, `include("enviado")`, `not_to include("Submitter")`, `inner_html.index("Reenviar e-mail") < index("Cancelar")` | PASS |
| C2 | POST submitter invite `docs@exemplo.org` succeeds; item has `Submitter`, `enviado`, not `Coordenador` | `submitter_invites_spec.rb` `-e "POST /submitter_invites pending row shows Submitter and enviado"` passed | `spec/requests/submitter_invites_spec.rb:53–55` `include("Submitter")`, `include("enviado")`, `not_to include("Coordenador")` | PASS |
| C3 | `ana@exemplo.org` before `zoe@exemplo.org`; kinds exclusive; both `li` under `Convites pendentes`; not nested in Pessoas | `organizations_spec.rb` `-e "home pending invites show kind in email order under Convites pendentes"` passed | `spec/requests/organizations_spec.rb:16` email index order; `:17–20` kind exclusivity; `:23–28` `li` under invites `h2` parent; Pessoas section `h2`/`li` do not contain Convites/emails | PASS |
| C4 | create + `deliver_now` raise: Invite remains, `last_delivery` `failed`, `302` `/`, GET `200` error toast copy, no that text on `[data-notice="error"]`, row `falhou envio do e-mail` not `enviado`; rescue after persist | `coordinator_invites_spec.rb` `-e "POST /coordinator_invites keeps the Invite when deliver_now raises"` passed | `coordinator_invites_spec.rb:150–156` invite present, `last_delivery == "failed"`, `:found`, redirect `/`, follow `ok`; `:158–159` toast error copy; `:163` notice-with-mail nil; `:165–166` row copy. Delivery-after-commit is persist + interceptor raise (no separate `deliver_now` spy) | PASS |
| C5 | later successful invite leaves failed row failed; success toast `Pronto.`; no mail-failure `[data-notice="error"]` | `-e "a later invite send leaves the failed row failed"` passed | `coordinator_invites_spec.rb:217` both Invites; `:219–220` success `Pronto.`; `:224` notice-with-mail nil; `:227–230` pessoa failed copy, nova `enviado` without failed copy | PASS |
| C6 | resend of `failed` row then GET includes `enviado` not `falhou envio do e-mail` | `-e "resend overwrites failed last delivery with enviado"` passed | `coordinator_invites_spec.rb:243–244` `include("enviado")`, `not_to include("falhou envio do e-mail")` | PASS |
| C7 | resend + raise: Invite remains; GET row `falhou envio do e-mail` not `enviado` | `-e "invite resend keeps the Invite when deliver_now raises"` passed | `coordinator_invites_spec.rb:254` `Invite.find` still that record; `:264–265` failed copy, not `enviado` | PASS |
| C8 | second GET after C4: no `[data-toast]`, no mail-failure sentence, row still failed copy | `-e "second GET after invite mail failure has no toast"` passed | `coordinator_invites_spec.rb:179–182` `toast_node` nil; body excludes sentence; item includes `falhou envio do e-mail` | PASS |
| C9 | stored last delivery only `sent`/`failed`; home item exactly one of the two copies | `invite_spec.rb` `-e "last_delivery is sent or failed"` and `organizations_spec.rb` `-e "home pending invite shows exactly one last-delivery copy"` both passed | `spec/models/invite_spec.rb:61` keys `sent`,`failed`; `:65` `create_pending` `sent`; `:68` `failed`; `:71` `unsent` not valid. `organizations_spec.rb:43–46` sent item has `enviado` not failed copy; failed item has failed copy not `enviado` | PASS |
| C10 | Cancelar: Invite gone, no delivery, GET does not include that email | `-e "Cancelar without a failure notice delivers nothing"` passed | `coordinator_invites_spec.rb:292–296` invite nil, deliveries empty, body excludes email | PASS |
| C11 | leftover `session[:invite_mail_failed]`, empty flash: `200`, no toast, no mail-failure as `[data-notice="error"]` or under `Meses` | `layout_spec.rb` `-e "GET / with empty flash has no toast"` passed | `spec/requests/layout_spec.rb:108–109` `ok`, `toast_node` nil; `:111` body excludes sentence; `:115` notice-with-mail nil; `:117–118` `h1` `Meses`, first section under that parent excludes sentence | PASS |
| C12 | resend other-org Invite: `404`, no mail, `last_delivery` unchanged | `-e "resend of another organization Invite returns 404"` passed | `coordinator_invites_spec.rb:307–310` `not_found`; invite unchanged `failed`; deliveries empty | PASS |
| C13 | design.md coordinator `home` Convites line names kind, last delivery, `Reenviar e-mail` immediately before `Cancelar` | `invite_kind_and_mail_status_spec.rb` `-e "visual-identity design.md home Convites pendentes names kind and last delivery"` passed | `spec/docs/invite_kind_and_mail_status_spec.rb:8–13` includes heading, both kinds, both copies; `match(/Reenviar e-mail\s+Cancelar/)` | PASS |
| C14 | administration-list `Screen home invites` per-invite copy; `Invite resend` does not say the failure notice sits under `Meses` | `-e "administration-list home invites names per-invite copy not Meses notice"` passed | `spec/docs/invite_kind_and_mail_status_spec.rb:21–28` section includes kinds, copies, actions; `| Invite resend |` present and `not_to include("The failure notice sits under \`Meses\`")` | PASS |

## Coverage (recomputed)

Members taken from the Invite enums, the task state diagram, issue #78, and the two `home` variants in design.md — not from the author’s table as authority.

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| Invite kind on the pending row (2) | `coordinator` → `Coordenador` C1, C3 · `submitter` → `Submitter` C2, C3 | — |
| last_delivery stored values (2) | `sent` C9 `create_pending` / enum keys · `failed` C4, C9 | create-success SMTP write of `sent` is not distinct from the column default in C1 (C6 kills a skipped success write on a `failed` row) |
| last_delivery transitions (5) | create success display `enviado` C1 · create raise → `failed` C4 · resend `failed`→`enviado` C6 · resend raise → failed copy C7 · Cancelar destroys C10 | — |
| mixed pending list (2 emails, email order) | `ana@exemplo.org` before `zoe@exemplo.org` C3 | — |
| leftover session channel (2 absences) | no `[data-toast]` C11 · no mail-failure notice / under `Meses` C11 | — |
| resend target organization (2) | focused org C6 · other org `404` C12 | — |
| designed screens (2 home variants) | coordinator `Convites pendentes` C1–C3, C13 · submitter `Início` existing `organizations_spec.rb:238` “submitter home says Inicio” | that existing example asserts `Início` and no `Meses`, not the string `Convites pendentes` |
| visual (enumerated) | — | spacing, colour, type weight on coordinator `Convites pendentes` |

Claims naming a status code, route or response shape (C1–C2 follow_redirect HTML; C4 `302`/`200`; C10–C12 HTTP; C11 `200`) assert at the request boundary. C13–C14 are document proofs.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `Invite` `last_delivery` enum; `ApplicationController#deliver_invite` sent/failed write; invite mail/create/resend HTTP | own layer C9 enum members; HTTP C1/C4/C6/C7/C12 | yes — two stored members at the model; SMTP outcomes at request (failed persist C4; success overwrite C6). No isolated `deliver_invite` spec; analogue is existing invite request specs |
| Decides, not reached across a boundary | kind/last-delivery copy maps in `organizations/show.html.erb` | HTTP C1–C4, C6–C9 (repo has no view specs) | yes — checklist evidence: request HTML |
| Entry point that decides nothing | — | — | no new pass-through entry in this cut (`create`/`mail` still call `redirect_after_invite_mail`) |
| Instrumentation / pass-through | — | none of its own | n/a |

Swept “existing”: `Invite` still validates well-formed email, uniqueness, standing Access (`invite_spec.rb` “rejects standing Access…”); `CoordinatorInvitesController` still `before_action :require_coordinator_organization` (`application_controller.rb:56–63`).

## Faults injected

Scratch worktree `/tmp/tlc-verify-invite-kind` at `0cfb801`, then removed. Real-tree porcelain empty before and after.

| Mutation | Location | Killed |
|---|---|---|
| swap `Coordenador`/`Submitter` on the pending row | `app/views/organizations/show.html.erb` | yes — C1 failed (`Submitter` instead of `Coordenador`) |
| omit `update!(last_delivery: :failed)` on SMTP rescue | `ApplicationController#deliver_invite` | yes — C4 failed (`last_delivery` stayed `"sent"`) |
| omit `update!(last_delivery: :sent)` on SMTP success | `ApplicationController#deliver_invite` | yes — C6 failed (row still `falhou envio do e-mail`) |
| nest `Convites pendentes` inside the Pessoas two-column grid | `app/views/organizations/show.html.erb` | yes — C3 failed (Pessoas section `h2`s included `Convites pendentes`) |
| `Invite.find(params[:id])` instead of focused-org `find_by` on resend | `CoordinatorInvitesController#mail` | yes — C12 failed (`302` instead of `404`) |

## Gate

`bin/rspec` (six files, fifteen `-e` names) — 15 passed, 0 failed
