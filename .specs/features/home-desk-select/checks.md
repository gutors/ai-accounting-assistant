# Home desk select checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/home-desk-select/plan.md`

39 checks in 5 slices · 0 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`. Capture proofs are at 903×970.

## Checks

### S1 - The month desk matches the capture

**C1** - A coordinator focused on an organization that is not their only one, with an open never-sent in-work month that still has missing documents and one account without a statement, GETs `/` and sees `.specs/features/home-desk-select/captures/month-desk.png` (AC 1)
Proof: browser - reach that coordinator home, save `captures/month-desk.running.png` at 903×970

**C2** - Coordinator GET `/`: the Meses list does not include `Excluir` and does not include a link to `/months/:year_month` (AC 2)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "Meses list omits Excluir and omits month-page links"`

**C3** - Coordinator GET `/`: the left column pin includes the title `Coordenadores e submitters` and stays in the first viewport while the Meses list scrolls (AC 3)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "people pin sits outside the Meses scroll"`
Proof: `bin/rspec spec/system/home_desk_select_spec.rb -e "people pin stays in the viewport while Meses scrolls"`

**C4** - Pin with 3 standing coordinators, 2 standing submitters, and 1 invite whose last delivery failed: `3 coordenadores · 2 submitters` and `1 falhou envio` in `margem`, and does not include `convite` (AC 4)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "people pin says 3 coordenadores 2 submitters and 1 falhou envio without convite"`

**C5** - Pin with 1 standing coordinator, 1 standing submitter, and no failed invite: `1 coordenador · 1 submitter` and does not include `falhou envio` (AC 5)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "people pin says 1 coordenador 1 submitter without falhou envio"`

### S2 - Organization is a header list

**C6** - Account with exactly one organization, coordinator GET `/`: header includes that organization name and does not render a control with `aria-haspopup="listbox"`; the left column has no `nav[aria-label="Organizações"]` and no `role="group"` `aria-label="Organização"` (AC 6)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "one-organization home omits org listbox and names the org in the header"`

**C7** - Account with two organizations, coordinator GET `/`: header includes a button whose accessible name is `Organização: <focused name>. Abrir lista`, `aria-haspopup="listbox"`, `aria-expanded="false"` (AC 7)
Proof: `bin/rspec spec/requests/focus_spec.rb -e "two-organization header switcher names the focused org"`

**C8** - Using that header button shows `.specs/features/home-desk-select/captures/org-list.png` (AC 8)
Proof: browser - open the header list, save `captures/org-list.running.png` at 903×970

**C9** - Open list: focused organization is `aria-current="true"`; using the unfocused organization’s option POSTs `/focus` with that `organization_id` and the next GET `/` is that organization’s month desk, not `desk=people` (AC 9)
Proof: `bin/rspec spec/requests/focus_spec.rb -e "header list marks the focused organization aria-current"`
Proof: `bin/rspec spec/requests/focus_spec.rb -e "POST /focus names the organization in the toast"`

**C10** - Open list: Escape, or a control outside the switcher, closes the list and the button is `aria-expanded="false"` (AC 10)
Proof: `bin/rspec spec/system/home_desk_select_spec.rb -e "org list closes on Escape and outside click"`

### S3 - A month row fills the right desk

**C11** - Using a Meses row for `2026-10` issues `GET /?year_month=2026-10` (AC 11)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "Meses row for 2026-10 is GET year_month 2026-10"`

**C12** - GET `/?year_month=2026-10` for a closed month shows `.specs/features/home-desk-select/captures/closed-month.png` (AC 12)
Proof: browser - select the closed month, save `captures/closed-month.running.png` at 903×970

**C13** - GET `/?year_month=2026-11` for the open never-sent in-work month: right column `<h1>` is that month’s `month_title`, the body includes `2026-11`, Continuar links to `/months/2026-11`, and Excluir is a secondary danger button whose confirm is `Excluir este fechamento?` (AC 13)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "selected never-sent 2026-11 right h1 Continuar and Excluir"`

**C14** - Using Excluir and confirming DELETEs `/months/:year_month` and keeps today’s success redirect and toast (AC 14)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "selected never-sent Excluir is DELETE with turbo confirm"`
Proof: `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "DELETE never-sent empty month redirects home and frees year_month"`

**C15** - Selected month closed, or open and not `never_sent?`: right column does not include `Excluir` (AC 15)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "closed selected month omits Excluir"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "reopened selected month omits Excluir"`

**C16** - Selected month closed: right column includes the stamp `Mês fechado` and Continuar still links to `/months/:year_month` (AC 16)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "closed selected month stamps Mes fechado and Continuar still links"`

**C17** - Selected month accounts confirmed and 2 payments missing a document: right column includes exactly one missing-document sentence `2 pagamentos com documento faltante.` in `margem` (AC 17)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "selected month says 2 pagamentos com documento faltante in margem"`

**C18** - Accounts confirmed and 0 payments missing a document: the sentence is `Nenhum documento faltante.` and does not use `margem` for that sentence (AC 18)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "selected month says Nenhum documento faltante without margem"`

**C19** - Selected month is not accounts-confirmed: the right column does not include `documento faltante` (AC 19)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "unconfirmed selected month omits documento faltante"`

**C20** - Selected month with two active accounts, one with a statement and one without: Contas bancárias is a ruled sheet with heads `Banco`, `Nome`, `Extrato`; the row with a statement includes `Presente`; the row without includes `Falta` in `margem` (AC 20)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "selected Contas bancarias Extrato is Presente and Falta in margem"`

**C21** - `year_month` absent, empty, or not a month of the focused organization: the selected month is the in-work open month when one exists (AC 21)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "absent year_month selects the in-work open month"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "empty year_month selects the in-work open month"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "unknown year_month selects the in-work open month"`

**C22** - No months: Meses includes `Nenhum mês aberto`, the right column includes `Selecione um mês na lista.`, and does not include Continuar or Excluir (AC 22)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "empty home lists Nenhum mes aberto and Selecione um mes"`

**C23** - GET `/?desk=people` showing the people book, using a Meses row: the right column is that month’s desk and the people pin is not `aria-current` (AC 23)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "Meses row from people desk fills the month desk"`

**C24** - Coordinator GET `/`: Abrir mês is `<label for="year_month">Abrir mês</label>`, a `select#year_month` and submit `Abrir mês` on one row, above the Meses list, posting `year_month` to `/months`; the 25-month picker window and a successful `POST /months` redirect and toast stay as today’s specs (AC 24)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "Abrir mes is label select and submit on one row above Meses posting to /months"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker lists 25 months from 2025-10 to 2027-10"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker in January starts 2025-01 ends 2027-01"`
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months names the opened month in the toast"`

### S4 - People sit on the desk

**C25** - Using the left pin `Coordenadores e submitters` issues `GET /?desk=people` (AC 25)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "people pin is GET desk people"`

**C26** - GET `/?desk=people` shows `.specs/features/home-desk-select/captures/people-desk.png` (AC 26)
Proof: browser - open the people book, save `captures/people-desk.running.png` at 903×970

**C27** - `desk=people`: the pin is `aria-current="true"` and no Meses row is `aria-current` (AC 27)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "people desk pin is aria-current and no Meses row is"`

**C28** - People book: right column `<h1>` is `Coordenadores e submitters`; the invite form sits directly under that heading, with email placeholder `E-mail`, a kind select whose options are `Coordenador` then `Submitter` (default `Coordenador`), and submit `Convidar`; below the form a heading `Coordenadores` then a heading `Submitters` (AC 28)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "people book heading invite form Coordenadores then Submitters"`

**C29** - 3 standing coordinators, 2 standing submitters, 1 pending coordinator invite, and 1 failed submitter invite: people-book meta is `5 pessoas · 2 convites · 1 falhou envio` (AC 29)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "people book meta is 5 pessoas 2 convites 1 falhou envio"`

**C30** - Standing coordinators in insertion order (`accesses.created_at`, then `id`), then pending coordinator invites in insertion order; standing submitters in insertion order, then pending submitter invites in insertion order. The principal coordinator’s row includes `Principal` and does not include `Revogar` (AC 30)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "people book lists standing then pending in insertion order"`

**C31** - A pending invite row includes `Convite · enviado` when `last_delivery` is sent, and `Convite · falhou envio do e-mail` in `margem` when it failed; each pending row includes `Reenviar e-mail` and `Cancelar` (AC 31)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "pending invite rows say Convite enviado or falhou envio do e-mail"`

**C32** - Using `Convidar` with kind `Coordenador` POSTs `/coordinator_invites` with `email`; with kind `Submitter` POSTs `/submitter_invites` with `email`. Today’s validation, mail, and toast remain (AC 32)
Proof: `bin/rspec spec/system/home_desk_select_spec.rb -e "Convidar Coordenador posts coordinator_invites and Submitter posts submitter_invites"`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites names the invited email in the toast"`

**C33** - Invite create, mail, or destroy success, or access revoke success: redirect is `/?desk=people` and the next GET still shows the people book (AC 33)
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites persists a coordinator Invite and redirects"`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST mail redirects to people desk"`
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "DELETE /coordinator_invites/:id redirects"`
Proof: `bin/rspec spec/requests/submitter_invites_spec.rb -e "POST /submitter_invites persists a submitter Invite and redirects"`
Proof: `bin/rspec spec/requests/accesses_spec.rb -e "DELETE /accesses/:id of a non-last coordinator redirects"`

**C34** - Invite create unprocessable: `422` and still shows the people book, not the month desk (AC 34)
Proof: `bin/rspec spec/requests/coordinator_invites_spec.rb -e "rejected invite emails return 422"`

**C35** - No standing coordinators and no coordinator invites: Coordenadores includes `Nenhum coordenador`; no standing submitters and no submitter invites: Submitters includes `Nenhum submitter` (AC 35)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "empty people book says Nenhum coordenador and Nenhum submitter"`

**C36** - People book: revoke confirm copy stays `Revogar o acesso deste coordenador?` and `Revogar o acesso deste submitter?`; who may revoke stays as today’s access destroy specs. The page does not include a `<details>` whose summary is `Pessoas` and does not include a heading `Convites pendentes` (AC 36)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "principal coordinator sees Revogar on peer and submitter rows"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "people book omits Pessoas details and Convites pendentes"`

### S5 - Submitter is not this desk

**C37** - Submitter GET `/`: `<h1>` is `Início`, the Documentos sentence is present, Abrir mês, Continuar, Contas bancárias, `Coordenadores e submitters`, and `Convidar` are absent, and `year_month` and `desk` are ignored (AC 37)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home says Inicio and points to Documentos"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home omits close-ritual chrome"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home ignores year_month and desk"`

**C38** - Submitter with two organizations: the header uses the same organization listbox as C7–C10; with one, the header follows C6 (AC 38)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter two-organization home uses the header org listbox"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter one-organization home omits org listbox"`

**C39** - Unauthenticated GET `/` responds `302` to `/login`
Proof: `bin/rspec spec/requests/sessions_spec.rb -e "unauthenticated GET / responds 302 to /login"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| GET `/` statuses (2) | `200` C6 · `302` C39 | - |
| source controls: `month-desk` (9) | org button C7 · Abrir mês C24 · Meses row C11 · pin C25 · Continuar C13 · Excluir C13 · missing sentence C17 · Contas Extrato C20 · people counts C4 | - |
| source controls: `org-list` (2) | open list C8 · focused current C9 | - |
| source controls: `people-desk` (8) | pin current C27 · h1 C28 · invite form C28 · Coordenadores C28 · Submitters C28 · Principal C30 · Convite status C31 · Reenviar/Cancelar C31 | - |
| source controls: `closed-month` (3) | stamp C16 · Continuar C16 · no Excluir C15 | - |
| pin counts (2) | 3+2+fail C4 · 1+1 no fail C5 | - |
| org switcher (2) | one org C6 · two orgs C7 | - |
| year_month fallback (3) | absent C21 · empty C21 · unknown C21 | - |
| missing-document sentence (3) | 2 C17 · 0 C18 · unconfirmed omitted C19 | - |
| Extrato column (2) | `Presente` C20 · `Falta` C20 | - |
| Excluir on selected (3) | never-sent C13 · closed omitted C15 · not never_sent omitted C15 | - |
| picker window (2) | Oct 2025–2027 C24 · Jan 2025–2027 C24 | - |
| people empty (2) | Nenhum coordenador C35 · Nenhum submitter C35 | - |
| invite last_delivery (2) | sent C31 · failed C31 | - |
| invite kind POST (2) | Coordenador C32 · Submitter C32 | - |
| people write redirect (4) | create C33 · mail C33 · destroy C33 · revoke C33 | - |
| submitter home (2) | one org C38 · two orgs C38 | - |
| POST `/months` (1) | 302 success C24 | - |
| POST `/focus` (1) | 302 with Access C9 | - |
| DELETE `/months/:year_month` (1) | 302 success C14 | - |

- C1, C8, C12, C26 are capture comparisons. No check claims more than the cases its proofs exercise.
- GET `/`, POST `/months`, POST `/focus`, DELETE `/months/:year_month`, and invite/access writes keep method, params, status, and who may call, except the people-write redirect target `/?desk=people`. Unauthenticated GET `/` 302 stays on the existing example named in Swept.

## Swept

- validation: existing - `POST /months` empty and `2026-13` still 422 with `Informe um mês válido`; C24 keeps the 25-month picker window; C32/C34 keep invite email validation
- failure modes: existing - `POST /months` 422 re-renders `organizations/show` after `load_home`; C34 invite 422 still shows the people book
- idempotency: existing - `POST /months 2026-05 a second time does not duplicate`
- authorization: existing - submitter `POST /months` 404; C37 omits Abrir mês, Continuar, Contas bancárias, `Coordenadores e submitters`, and `Convidar`; `POST /focus` without Access stays 404; who may revoke stays on today’s access destroy specs (C36)
- concurrency: n/a - this change is a read of existing Month/Access rows plus query-selected desk; `POST /focus` still last-write-wins on the session
- data lifecycle: n/a - nothing to migrate; Months, Accesses, and Invites are unchanged
- dependency failure: n/a - no new external call
- state transitions: C11, C21, C23 (selected month vs people desk); C13, C15, C16 (Excluir / closed stamp); C17–C19 (missing-document copy)
- observability: n/a - no logging or metrics criterion

## Handoff

- **Settled mid-build:** none
- **Dispatched:** Verifier at `b459ac1` (`2318ac0..b459ac1`); screens round 1 at `b459ac1`
- **Boundary:**
- **Abandoned:** none
- **Walked:** Ambiente local `gutors@gmail.com` on `GET /` at 903×970: header button ONG Exemplo (Instituto Água Viva in the list), Abrir mês on one row, Meses novembro de 2026 `em trabalho` Aberto plus outubro/agosto Fechado and setembro Aberto, pin `3 coordenadores · 2 submitters · 1 falhou envio`, right pane novembro de 2026 / `2026-11` / Continuar / Excluir / `2 pagamentos com documento faltante.` / Contas Extrato Presente then Falta. Saved `captures/month-desk.running.png`. Header list open: ONG Exemplo `aria-current` then Instituto Água Viva. Saved `captures/org-list.running.png`. `GET /?year_month=2026-10`: stamp `Mês fechado`, Continuar, no Excluir. Saved `captures/closed-month.running.png`. `GET /?desk=people`: h1 `Coordenadores e submitters`, invite form (E-mail, Coordenador/Submitter, Convidar), Coordenadores then Submitters in insertion order, Principal without Revogar, `Convite · enviado` and `Convite · falhou envio do e-mail` with Reenviar/Cancelar. Saved `captures/people-desk.running.png`. Meses row stays on `/?year_month=`; pin is `GET /?desk=people`; Excluir only on the selected never-sent right desk. One-org quiet and submitter home are request specs.
