# month-account-filter proofs

**HEAD**: 76dfc88
**Tree**: clean
**Result**: 9 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `browser - reach the state, save captures/option-a.running.png` | - | - | pass |
| C2 | `bin/rspec spec/system/month_account_filter_spec.rb -e "opens home"` | count unknown | - | pass |
| C3 | `bin/rspec spec/system/month_account_filter_spec.rb -e "shows the account selector"` | count unknown | - | pass |
| C4 | `bin/rspec spec/system/list_scroll_position_spec.rb -e "changes and clears the month account in place"` | count unknown | - | pass |
| C5 | `bin/rspec spec/system/month_account_filter_spec.rb -e "shows empty account messages"` | count unknown | - | pass |
| C6 | `bin/rspec spec/system/month_account_filter_spec.rb -e "keeps month totals"` | count unknown | - | pass |
| C7 | `bin/rspec spec/system/month_account_filter_spec.rb -e "fits a phone viewport"` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| C6 omit monthly missing documents | `app/controllers/application_controller.rb:272` | yes |
| C4 lose payment sort | `app/views/months/show.html.erb:118` | yes |
| C5 wrong empty receipt message | `app/views/months/show.html.erb:208` | yes |
