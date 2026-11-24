# matches-resolution proofs

**HEAD**: 7e89208
**Tree**: clean
**Result**: 19 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bin/rspec spec/requests/month_matches_spec.rb -e "renders notices before the account selector"` | count unknown | - | pass |
| C1 | `bin/rspec spec/requests/month_matches_spec.rb -e "omits the workspace in an empty queue"` | count unknown | - | pass |
| C1 | `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches closed shows exceptions without mutation control` | count unknown | - | pass |
| C2 | `bin/rspec spec/system/month_matches_spec.rb -e "selects and clears the matching account"` | count unknown | - | pass |
| C2 | `bin/rspec spec/requests/matches_workspace_spec.rb -e "limits selectable unmatched documents to this organizati` | count unknown | - | pass |
| C3 | `bin/rspec spec/system/month_matches_spec.rb -e "shows full names below the value line"` | count unknown | - | pass |
| C4 | `bin/rspec spec/system/month_matches_spec.rb -e "adds payments and documents in their own list"` | count unknown | - | pass |
| C5 | `bin/rspec spec/system/month_matches_spec.rb -e "shows signed and colored differences"` | count unknown | - | pass |
| C6 | `bin/rspec spec/system/month_matches_spec.rb -e "opens the required observation on shortfall"` | count unknown | - | pass |
| C6 | `bin/rspec spec/requests/month_matches_spec.rb -e "POST matches lesser blank observation 422s matches with bord` | count unknown | - | pass |
| C7 | `bin/rspec spec/system/month_matches_spec.rb -e "chooses and cancels an outlined exception"` | count unknown | - | pass |
| C7 | `bin/rspec spec/system/matches_workspace_spec.rb -e "workspace criterion 03" -e "workspace criterion 17"` | count unknown | - | pass |
| C7 | `bin/rspec spec/system/month_matches_spec.rb -e "confirms a match and advances within the account"` | count unknown | - | pass |
| C8 | `bin/rspec spec/system/month_matches_spec.rb -e "workspace fits desktop and phone widths"` | count unknown | - | pass |
| C8 | `walk - open the balanced workspace and compare the desktop and phone layout against the interactive source` | - | - | pass (Walked) |
| C8 | `browser - open the balanced workspace at 1280 × 900, save captures/balanced-desktop.running.png` | - | - | pass |
| C8 | `browser - open the balanced workspace at 390 × 1080, save captures/balanced-phone.running.png` | - | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| C5 reverses signed difference | `app/javascript/controllers/month_match_controller.js:76` | yes |
| C7 retains exception documents | `app/javascript/controllers/month_match_controller.js:27` | yes |
| C6 accepts whitespace observation | `app/javascript/controllers/month_match_controller.js:97` | yes |
