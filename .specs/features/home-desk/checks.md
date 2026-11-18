# Home desk checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/home-desk/plan.md`

24 checks in 5 slices · 1 one-way door · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.

## Checks

### S1 - The desk matches the capture · door 1

**C1** - A coordinator focused on ONG Norte, who also has ONG Sul, with open month `2026-10` that still has missing documents and one account without a statement, GETs `/` and sees `.specs/features/home-desk/captures/coordinator-home.png` (`.specs/features/home-desk/captures/coordinator-home.html`) (AC 1)
Proof: browser - reach that coordinator home, save `captures/coordinator-home.running.png` at 960×970

**C2** - Coordinator GET `/`: the header link `Início` has `aria-current="page"` and is the only principal nav link with `aria-current` (AC 2)
Proof: `bin/rspec spec/requests/layout_spec.rb -e "GET / Inicio is the only principal nav link with aria-current page"`

**C3** - Coordinator GET `/supporting_documents`: `Documentos` has `aria-current="page"` and `Início` does not (AC 3)
Proof: `bin/rspec spec/requests/layout_spec.rb -e "GET /supporting_documents Documentos has aria-current page and Inicio does not"`

**C4** - Coordinator GET `/setup`: `Configuração` has `aria-current="page"` (AC 4)
Proof: `bin/rspec spec/requests/layout_spec.rb -e "GET /setup Configuracao has aria-current page"`

**C5** - Coordinator GET `/`: `main` is a two-column grid whose first column is `26rem` (door 1)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "coordinator home main is a two-column grid with first column 26rem"`

### S2 - Organization is quiet

**C6** - Account with exactly one organization, coordinator GET `/`: no `nav[aria-label="Organizações"]`, no heading `Organizações`, and the organization name appears in the header (AC 5)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "one-organization home omits Organizacoes nav and names the org in the header"`

**C7** - Account with two organizations, coordinator GET `/`: the left column includes `role="group"` `aria-label="Organização"` with one button per organization, the focused one `aria-current="true"` (AC 6)
Proof: `bin/rspec spec/requests/focus_spec.rb -e "focused organization button carries aria-current"`

**C8** - Submitting the unfocused organization’s button POSTs `/focus` with that `organization_id` and the next GET `/` is that organization’s desk (AC 7)
Proof: `bin/rspec spec/requests/focus_spec.rb -e "POST /focus names the organization in the toast"`

### S3 - Left column opens and lists months

**C9** - Coordinator GET `/`: Abrir mês is `<label for="year_month">Abrir mês</label>`, `select#year_month` and submit `Abrir mês` on one row, above the Meses list, posting `year_month` to `/months` (AC 8)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "Abrir mes is label select and submit on one row above Meses posting to /months"`

**C10** - The picker lists 25 months, selects the previous calendar month, and the window stays 12 months back through 12 months forward (AC 9)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker lists 25 months from 2025-10 to 2027-10"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker in January starts 2025-01 ends 2027-01"`

**C11** - POST `/months` that succeeds redirects to `/months/:year_month` with the opened-month success toast (AC 10)
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months names the opened month in the toast"`

**C12** - Coordinator GET `/` with no months: Meses includes `Nenhum mês aberto` and the right column does not include Continuar (AC 11)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "empty home lists Nenhum mes aberto and omits Continuar"`

**C13** - Open `2026-10` and closed `2026-09`: the open row includes `em trabalho` and `Aberto`, the closed row includes the stamp `Fechado`, order is `year_month` desc, and each month title links to `/months/:year_month` (AC 12)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "open month row says em trabalho and Aberto, closed row stamps Fechado, year_month desc"`

**C14** - A never-sent month row includes `Excluir` (AC 13)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "never-sent open month row includes Excluir with turbo confirm"`

### S4 - Right column summarizes the in-work month

**C15** - In-work month `2026-10`: the right column `<h1>` is `outubro de 2026`, the body includes `2026-10`, and Continuar is a link to `/months/2026-10` (AC 14)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "in-work month 2026-10 right h1 is outubro de 2026 with Continuar to /months/2026-10"`

**C16** - That month has accounts confirmed and 3 payments missing a document: the right column includes exactly one missing-document sentence `3 pagamentos com documento faltante.` in `margem`, and does not include `Falta o extrato` in that sentence (AC 15)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "in-work summary says 3 pagamentos com documento faltante in margem without Falta o extrato"`

**C17** - Accounts confirmed and 1 payment missing a document: the sentence is `1 pagamento com documento faltante.` (AC 16)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "in-work summary says 1 pagamento com documento faltante"`

**C18** - Accounts confirmed and 0 payments missing a document: the sentence is `Nenhum documento faltante.` and that sentence is not in `margem` (AC 17)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "in-work summary says Nenhum documento faltante without margem"`

**C19** - In-work month is not accounts-confirmed: the right column does not include `documento faltante` (AC 18)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "unconfirmed in-work month omits documento faltante"`

**C20** - In-work month with two active accounts, one with a statement and one without: Contas bancárias is a ruled sheet with heads `Banco`, `Nome`, `Extrato`; the row with a statement includes `Presente`; the row without includes `Falta` in `margem` (AC 19)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "in-work Contas bancarias Extrato is Presente and Falta in margem"`

**C21** - No in-work open month: the right column does not include Continuar and does not include Contas bancárias (AC 20)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "all-closed home omits Continuar and Contas bancarias"`

**C22** - In-work is the newest open month: closed `2026-10` plus open `2026-09` puts `setembro de 2026` on the right with Continuar to `/months/2026-09`; open `2026-10` plus open `2026-08` puts `outubro de 2026` on the right
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "in-work skips a newer closed month"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "in-work is the newest of two open months"`

### S5 - People stay, collapsed; submitter is not this desk

**C23** - Coordinator GET `/`: Pessoas and Convites pendentes sit inside a closed `<details>` whose summary is `Pessoas`, below the two panes, and invite / revoke / list behaviour remains (AC 21)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "Pessoas is a closed details below the desk"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "home pending invites show kind in email order under Convites pendentes"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "principal coordinator is first and sees Revogar on peer coordinator and submitter rows"`

**C24** - Submitter GET `/`: `<h1>` is `Início`, the Documentos sentence is present, Abrir mês, Continuar, Contas bancárias, and Convidar coordenador are absent, and org chips render only when the account has more than one organization (AC 22)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home says Inicio and points to Documentos"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home omits close-ritual chrome"`
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter two-organization home shows Organizacao chips"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| door 1: two-pane `main` (1) | first column `26rem` C5 | - |
| header `aria-current="page"` (3) | `Início` C2 · `Documentos` C3 · `Configuração` C4 | - |
| org chips (2) | one org omitted C6 · two orgs group C7, C8 | - |
| source controls: `coordinator-home` (8) | Início current C2 · org chips C7, C8 · Abrir mês C9 · live month row C13 · closed stamp C13 · Continuar C15 · missing-document sentence C16 · Contas Extrato C20 | - |
| product additions vs capture (2) | Excluir C14 · Pessoas details C23 | - |
| picker window (2) | Oct 2025–2027 C10 · Jan 2025–2027 C10 | - |
| missing-document sentence (4) | 3 C16 · 1 C17 · 0 C18 · unconfirmed omitted C19 | - |
| Extrato column (2) | `Presente` C20 · `Falta` C20 | - |
| in-work month (4) | `2026-10` C15 · none C21 · newest of two open C22 · newer closed skipped C22 | - |
| month row state (2) | open `em trabalho`/`Aberto` C13 · closed `Fechado` C13 | - |
| GET `/` (1) | 200 C6 | - |
| POST `/months` (1) | 302 success C11 | - |
| POST `/focus` (1) | 302 with Access C8 | - |
| submitter home (2) | one org no chips C24 · two orgs chips C24 | - |

- C1 is the capture comparison; C2–C24 are request specs (or existing ones this feature keeps). No check claims more than the cases its proofs exercise.
- GET `/`, POST `/months`, and POST `/focus` keep method, params, status, and who may call. Unauthenticated GET `/` 302, POST `/months` 422 / submitter 404 / unauthenticated 302, and POST `/focus` 404 stay on the existing examples named in Swept.

## Swept

- validation: existing - `POST /months` empty and `2026-13` still 422 with `Informe um mês válido`; C10 keeps the 25-month picker window
- failure modes: existing - `POST /months` 422 re-renders `organizations/show` after `load_home`, so the desk still shows the picker
- idempotency: existing - `POST /months 2026-05 a second time does not duplicate`
- authorization: existing - submitter `POST /months` 404; C24 omits Abrir mês, Continuar, Contas bancárias, and Convidar coordenador; `POST /focus` without Access stays 404
- concurrency: n/a - this change is a read of existing Month/Access rows; `POST /focus` still last-write-wins on the session
- data lifecycle: n/a - nothing to migrate; Months, Accesses, and Invites are unchanged
- dependency failure: n/a - no new external call
- state transitions: C13, C21, C22 (open vs closed vs in-work); C16–C19 (missing-document copy by count and accounts-confirmed)
- observability: n/a - no logging or metrics criterion

## Handoff

- **Settled mid-build:** none
- **Dispatched:**
- **Boundary:**
- **Abandoned:** none
- **Walked:** Ambiente local `desk-walk@example.com` on `GET /` at 960×970: ONG Norte current with ONG Sul chip, Abrir mês on one row, open `2026-10` `em trabalho` plus three closed stamps, right pane `outubro de 2026` / `2026-10` / Continuar / `3 pagamentos com documento faltante.` / Contas Extrato Presente then Falta. Saved `captures/coordinator-home.running.png` at 960×970. `GET /supporting_documents` marks Documentos current; `GET /setup` marks Configuração current; Continuar opens `/months/2026-10` (three missing payments, one Falta extrato). Pessoas stays a closed details below the desk. One-org quiet chips and submitter home are request specs.
