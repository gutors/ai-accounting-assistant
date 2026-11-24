# matches-workspace proofs

**HEAD**: 1e5968f
**Tree**: clean
**Result**: 36 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 01"` | count unknown | - | pass |
| C2 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 02"` | count unknown | - | pass |
| C2 | `bin/rspec spec/requests/matches_workspace_spec.rb -e "selects oldest pending payment even without a suggestion` | count unknown | - | pass |
| C3 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 03"` | count unknown | - | pass |
| C4 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 04"` | count unknown | - | pass |
| C5 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 05"` | count unknown | - | pass |
| C6 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 06"` | count unknown | - | pass |
| C7 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 07"` | count unknown | - | pass |
| C8 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 08"` | count unknown | - | pass |
| C9 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 09"` | count unknown | - | pass |
| C10 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 10"` | count unknown | - | pass |
| C11 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 11"` | count unknown | - | pass |
| C12 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 12"` | count unknown | - | pass |
| C13 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 13"` | count unknown | - | pass |
| C14 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 14"` | count unknown | - | pass |
| C15 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 15"` | count unknown | - | pass |
| C16 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 16"` | count unknown | - | pass |
| C17 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 17"` | count unknown | - | pass |
| C18 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 18"` | count unknown | - | pass |
| C18 | `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST deactivated extra_exception_kind_id returns 422"` | count unknown | - | pass |
| C18 | `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST extra_exception_kind_id of another organization r` | count unknown | - | pass |
| C18 | `bin/rspec spec/models/payment_spec.rb -e "rejects deactivated extra Doacao"` | count unknown | - | pass |
| C19 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 19"` | count unknown | - | pass |
| C20 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 20"` | count unknown | - | pass |
| C21 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 21"` | count unknown | - | pass |
| C22 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 22"` | count unknown | - | pass |
| C23 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 23"` | count unknown | - | pass |
| C24 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 24"` | count unknown | - | pass |
| C25 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 25"` | count unknown | - | pass |
| C26 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 26"` | count unknown | - | pass |
| C26 | `bin/rspec spec/requests/matches_workspace_spec.rb -e "rerenders the matches screen when exception selection is` | count unknown | - | pass |
| C26 | `bin/rspec spec/requests/matches_workspace_spec.rb -e "rerenders a closed month when exception marking is refus` | count unknown | - | pass |
| C27 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 27"` | count unknown | - | pass |
| C28 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 28"` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| C2 oldest payment ordering | `app/controllers/application_controller.rb:215` | yes |
| C15 clear selected documents | `app/javascript/controllers/month_match_controller.js:25` | yes |
| C20 document payee in details | `app/views/matches/_completed.html.erb:21` | yes |
