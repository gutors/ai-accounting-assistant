# match-quick-selection proofs

**HEAD**: 0d37a22
**Tree**: clean
**Result**: 7 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bin/rspec spec/system/matches_workspace_spec.rb -e "quick selection toggles payments and documents"` | count unknown | - | pass |
| C2 | `bin/rspec spec/system/matches_workspace_spec.rb -e "quick selection protects selected rows"` | count unknown | - | pass |
| C3 | `bin/rspec spec/system/matches_workspace_spec.rb -e "quick selection preserves exception behavior"` | count unknown | - | pass |
| C4 | `bin/rspec spec/system/matches_workspace_spec.rb -e "quick selection confirms selected members"` | count unknown | - | pass |
| C5 | `bin/rspec spec/system/matches_workspace_spec.rb -e "quick selection works at phone width"` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| remove selected item | `app/javascript/controllers/month_match_controller.js:18` | yes |
| render selected payments | `app/javascript/controllers/month_match_controller.js:92` | yes |
| hide selected documents | `app/javascript/controllers/month_match_controller.js:96` | yes |
