# home-desk proofs

**HEAD**: 11ba80e
**Tree**: clean
**Result**: 32 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `browser - reach that coordinator home, save captures/coordinator-home.running.png at 960×970` | - | - | pass |
| C2 | `bin/rspec spec/requests/layout_spec.rb -e "GET / Inicio is the only principal nav link with aria-current page"` | count unknown | - | pass |
| C3 | `bin/rspec spec/requests/layout_spec.rb -e "GET /supporting_documents Documentos has aria-current page and Inic` | count unknown | - | pass |
| C4 | `bin/rspec spec/requests/layout_spec.rb -e "GET /setup Configuracao has aria-current page"` | count unknown | - | pass |
| C5 | `bin/rspec spec/requests/organizations_spec.rb -e "coordinator home main is a two-column grid with first column` | count unknown | - | pass |
| C6 | `bin/rspec spec/requests/organizations_spec.rb -e "one-organization home omits Organizacoes nav and names the o` | count unknown | - | pass |
| C7 | `bin/rspec spec/requests/focus_spec.rb -e "focused organization button carries aria-current"` | count unknown | - | pass |
| C8 | `bin/rspec spec/requests/focus_spec.rb -e "POST /focus names the organization in the toast"` | count unknown | - | pass |
| C9 | `bin/rspec spec/requests/organizations_spec.rb -e "Abrir mes is label select and submit on one row above Meses ` | count unknown | - | pass |
| C10 | `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker lists 25 months from 2025-10 to 2027-10"` | count unknown | - | pass |
| C10 | `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker in January starts 2025-01 ends 2027-01"` | count unknown | - | pass |
| C11 | `bin/rspec spec/requests/months_spec.rb -e "POST /months names the opened month in the toast"` | count unknown | - | pass |
| C12 | `bin/rspec spec/requests/organizations_spec.rb -e "empty home lists Nenhum mes aberto and omits Continuar"` | count unknown | - | pass |
| C13 | `bin/rspec spec/requests/organizations_spec.rb -e "open month row says em trabalho and Aberto, closed row stamp` | count unknown | - | pass |
| C14 | `bin/rspec spec/requests/organizations_spec.rb -e "never-sent open month row includes Excluir with turbo confir` | count unknown | - | pass |
| C15 | `bin/rspec spec/requests/organizations_spec.rb -e "in-work month 2026-10 right h1 is outubro de 2026 with Conti` | count unknown | - | pass |
| C16 | `bin/rspec spec/requests/organizations_spec.rb -e "in-work summary says 3 pagamentos com documento faltante in ` | count unknown | - | pass |
| C17 | `bin/rspec spec/requests/organizations_spec.rb -e "in-work summary says 1 pagamento com documento faltante"` | count unknown | - | pass |
| C18 | `bin/rspec spec/requests/organizations_spec.rb -e "in-work summary says Nenhum documento faltante without marge` | count unknown | - | pass |
| C19 | `bin/rspec spec/requests/organizations_spec.rb -e "unconfirmed in-work month omits documento faltante"` | count unknown | - | pass |
| C20 | `bin/rspec spec/requests/organizations_spec.rb -e "in-work Contas bancarias Extrato is Presente and Falta in ma` | count unknown | - | pass |
| C21 | `bin/rspec spec/requests/organizations_spec.rb -e "all-closed home omits Continuar and Contas bancarias"` | count unknown | - | pass |
| C22 | `bin/rspec spec/requests/organizations_spec.rb -e "in-work skips a newer closed month"` | count unknown | - | pass |
| C22 | `bin/rspec spec/requests/organizations_spec.rb -e "in-work is the newest of two open months"` | count unknown | - | pass |
| C23 | `bin/rspec spec/requests/organizations_spec.rb -e "Pessoas is a closed details below the desk"` | count unknown | - | pass |
| C23 | `bin/rspec spec/requests/organizations_spec.rb -e "home pending invites show kind in email order under Convites` | count unknown | - | pass |
| C23 | `bin/rspec spec/requests/organizations_spec.rb -e "principal coordinator is first and sees Revogar on peer coor` | count unknown | - | pass |
| C24 | `bin/rspec spec/requests/organizations_spec.rb -e "submitter home says Inicio and points to Documentos"` | count unknown | - | pass |
| C24 | `bin/rspec spec/requests/organizations_spec.rb -e "submitter home omits close-ritual chrome"` | count unknown | - | pass |
| C24 | `bin/rspec spec/requests/organizations_spec.rb -e "submitter two-organization home shows Organizacao chips"` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| missing-document filter stripped | `app/controllers/application_controller.rb:91` | yes |
| in-work is newest closed month | `app/controllers/application_controller.rb:81` | yes |
| em trabalho on every open month | `app/views/organizations/show.html.erb:27` | yes |
