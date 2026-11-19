# home-desk-select proofs

**HEAD**: 495c3c7
**Tree**: clean
**Result**: 59 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `browser - reach that coordinator home, save captures/month-desk.running.png at 903×970` | - | - | pass |
| C2 | `bin/rspec spec/requests/organizations_spec.rb -e "Meses list omits Excluir and omits month-page links"` | count unknown | - | pass |
| C3 | `bin/rspec spec/requests/organizations_spec.rb -e "people pin sits outside the Meses scroll"` | count unknown | - | pass |
| C3 | `bin/rspec spec/system/home_desk_select_spec.rb -e "people pin stays in the viewport while Meses scrolls"` | count unknown | - | pass |
| C4 | `bin/rspec spec/requests/organizations_spec.rb -e "people pin says 3 coordenadores 2 submitters and 1 falhou en` | count unknown | - | pass |
| C5 | `bin/rspec spec/requests/organizations_spec.rb -e "people pin says 1 coordenador 1 submitter without falhou env` | count unknown | - | pass |
| C6 | `bin/rspec spec/requests/organizations_spec.rb -e "one-organization home omits org listbox and names the org in` | count unknown | - | pass |
| C7 | `bin/rspec spec/requests/focus_spec.rb -e "two-organization header switcher names the focused org"` | count unknown | - | pass |
| C8 | `browser - open the header list, save captures/org-list.running.png at 903×970` | - | - | pass |
| C9 | `bin/rspec spec/requests/focus_spec.rb -e "header list marks the focused organization aria-current"` | count unknown | - | pass |
| C9 | `bin/rspec spec/requests/focus_spec.rb -e "POST /focus names the organization in the toast"` | count unknown | - | pass |
| C10 | `bin/rspec spec/system/home_desk_select_spec.rb -e "org list closes on Escape and outside click"` | count unknown | - | pass |
| C11 | `bin/rspec spec/requests/organizations_spec.rb -e "Meses row for 2026-10 is GET year_month 2026-10"` | count unknown | - | pass |
| C12 | `browser - select the closed month, save captures/closed-month.running.png at 903×970` | - | - | pass |
| C13 | `bin/rspec spec/requests/organizations_spec.rb -e "selected never-sent 2026-11 right h1 Continuar and Excluir"` | count unknown | - | pass |
| C14 | `bin/rspec spec/requests/organizations_spec.rb -e "selected never-sent Excluir is DELETE with turbo confirm"` | count unknown | - | pass |
| C14 | `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "DELETE never-sent empty month redirects home a` | count unknown | - | pass |
| C15 | `bin/rspec spec/requests/organizations_spec.rb -e "closed selected month omits Excluir"` | count unknown | - | pass |
| C15 | `bin/rspec spec/requests/organizations_spec.rb -e "reopened selected month omits Excluir"` | count unknown | - | pass |
| C16 | `bin/rspec spec/requests/organizations_spec.rb -e "closed selected month stamps Mes fechado and Continuar still` | count unknown | - | pass |
| C17 | `bin/rspec spec/requests/organizations_spec.rb -e "selected month says 2 pagamentos com documento faltante in m` | count unknown | - | pass |
| C18 | `bin/rspec spec/requests/organizations_spec.rb -e "selected month says Nenhum documento faltante without margem` | count unknown | - | pass |
| C19 | `bin/rspec spec/requests/organizations_spec.rb -e "unconfirmed selected month omits documento faltante"` | count unknown | - | pass |
| C20 | `bin/rspec spec/requests/organizations_spec.rb -e "selected Contas bancarias Extrato is Presente and Falta in m` | count unknown | - | pass |
| C21 | `bin/rspec spec/requests/organizations_spec.rb -e "absent year_month selects the in-work open month"` | count unknown | - | pass |
| C21 | `bin/rspec spec/requests/organizations_spec.rb -e "empty year_month selects the in-work open month"` | count unknown | - | pass |
| C21 | `bin/rspec spec/requests/organizations_spec.rb -e "unknown year_month selects the in-work open month"` | count unknown | - | pass |
| C22 | `bin/rspec spec/requests/organizations_spec.rb -e "empty home lists Nenhum mes aberto and Selecione um mes"` | count unknown | - | pass |
| C23 | `bin/rspec spec/requests/organizations_spec.rb -e "Meses row from people desk fills the month desk"` | count unknown | - | pass |
| C24 | `bin/rspec spec/requests/organizations_spec.rb -e "Abrir mes is label select and submit on one row above Meses ` | count unknown | - | pass |
| C24 | `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker lists 25 months from 2025-10 to 2027-10"` | count unknown | - | pass |
| C24 | `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker in January starts 2025-01 ends 2027-01"` | count unknown | - | pass |
| C24 | `bin/rspec spec/requests/months_spec.rb -e "POST /months names the opened month in the toast"` | count unknown | - | pass |
| C25 | `bin/rspec spec/requests/organizations_spec.rb -e "people pin is GET desk people"` | count unknown | - | pass |
| C26 | `browser - open the people book, save captures/people-desk.running.png at 903×970` | - | - | pass |
| C27 | `bin/rspec spec/requests/organizations_spec.rb -e "people desk pin is aria-current and no Meses row is"` | count unknown | - | pass |
| C28 | `bin/rspec spec/requests/organizations_spec.rb -e "people book heading invite form Coordenadores then Submitter` | count unknown | - | pass |
| C29 | `bin/rspec spec/requests/organizations_spec.rb -e "people book meta is 5 pessoas 2 convites 1 falhou envio"` | count unknown | - | pass |
| C30 | `bin/rspec spec/requests/organizations_spec.rb -e "people book lists standing then pending in insertion order"` | count unknown | - | pass |
| C31 | `bin/rspec spec/requests/organizations_spec.rb -e "pending invite rows say Convite enviado or falhou envio do e` | count unknown | - | pass |
| C32 | `bin/rspec spec/system/home_desk_select_spec.rb -e "Convidar Coordenador posts coordinator_invites and Submitte` | count unknown | - | pass |
| C32 | `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites names the invited email in t` | count unknown | - | pass |
| C33 | `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST /coordinator_invites persists a coordinator Invit` | count unknown | - | pass |
| C33 | `bin/rspec spec/requests/coordinator_invites_spec.rb -e "POST mail redirects to people desk"` | count unknown | - | pass |
| C33 | `bin/rspec spec/requests/coordinator_invites_spec.rb -e "DELETE /coordinator_invites/:id redirects"` | count unknown | - | pass |
| C33 | `bin/rspec spec/requests/submitter_invites_spec.rb -e "POST /submitter_invites persists a submitter Invite and ` | count unknown | - | pass |
| C33 | `bin/rspec spec/requests/accesses_spec.rb -e "DELETE /accesses/:id of a non-last coordinator redirects"` | count unknown | - | pass |
| C34 | `bin/rspec spec/requests/coordinator_invites_spec.rb -e "rejected invite emails return 422"` | count unknown | - | pass |
| C35 | `bin/rspec spec/requests/organizations_spec.rb -e "empty people book says Nenhum coordenador and Nenhum submitt` | count unknown | - | pass |
| C36 | `bin/rspec spec/requests/organizations_spec.rb -e "principal coordinator sees Revogar on peer and submitter row` | count unknown | - | pass |
| C36 | `bin/rspec spec/requests/organizations_spec.rb -e "people book omits Pessoas details and Convites pendentes"` | count unknown | - | pass |
| C37 | `bin/rspec spec/requests/organizations_spec.rb -e "submitter home says Inicio and points to Documentos"` | count unknown | - | pass |
| C37 | `bin/rspec spec/requests/organizations_spec.rb -e "submitter home omits close-ritual chrome"` | count unknown | - | pass |
| C37 | `bin/rspec spec/requests/organizations_spec.rb -e "submitter home ignores year_month and desk"` | count unknown | - | pass |
| C38 | `bin/rspec spec/requests/organizations_spec.rb -e "submitter two-organization home uses the header org listbox"` | count unknown | - | pass |
| C38 | `bin/rspec spec/requests/organizations_spec.rb -e "submitter one-organization home omits org listbox"` | count unknown | - | pass |
| C39 | `bin/rspec spec/requests/sessions_spec.rb -e "unauthenticated GET / responds 302 to /login"` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| selected month drops in-work fallback | `app/controllers/application_controller.rb:107` | yes |
| Excluir gated on closed instead of never_sent | `app/views/organizations/_month_desk.html.erb:11` | yes |
| standing coordinators listed newest first | `app/controllers/application_controller.rb:98` | yes |
