# list-scroll-position proofs

**HEAD**: 053085a
**Tree**: clean
**Result**: 14 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bin/rspec spec/system/list_scroll_position_spec.rb -e "sorts Sem mês by Data and Valor in place"` | count unknown | - | pass |
| C2 | `bin/rspec spec/system/list_scroll_position_spec.rb -e "filters and clears Sem mês in place"` | count unknown | - | pass |
| C3 | `bin/rspec spec/system/list_scroll_position_spec.rb -e "sorts all three month lists in place"` | count unknown | - | pass |
| C4 | `bin/rspec spec/system/list_scroll_position_spec.rb -e "changes and clears the month account in place"` | count unknown | - | pass |
| C5 | `bin/rspec spec/system/list_scroll_position_spec.rb -e "returns keyboard focus after a list update"` | count unknown | - | pass |
| C6 | `bin/rspec spec/system/list_scroll_position_spec.rb -e "restores list results through history and reload"` | count unknown | - | pass |
| C7 | `bin/rspec spec/system/list_scroll_position_spec.rb -e "opens the full login page after session expiry"` | count unknown | - | pass |
| C8 | `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 responds 200 with pt-BR and 2026-05"` | count unknown | - | pass |
| C9 | `bin/rspec spec/requests/months_spec.rb -e "submitter focus GET /months/2026-05 responds 404"` | count unknown | - | pass |
| C10 | `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents excludes matched do` | count unknown | - | pass |
| C11 | `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET /supporting_documents responds 30` | count unknown | - | pass |
| C12 | `bin/rspec spec/requests/months_spec.rb -e "unauthenticated GET /months/2026-05 responds 302 to /login"` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| C2: reset the viewport to the top after replacing the list | `app/javascript/controllers/list_refresh_controller.js:34` | yes |
| C3: reopen Pagamentos after sorting another month list | `app/javascript/controllers/list_refresh_controller.js:24` | yes |
| C6: allow the promoted visit to override an intervening Back | `app/javascript/controllers/list_refresh_controller.js:44` | yes |
