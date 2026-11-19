# month-statement-row proofs

**HEAD**: e6ab476
**Tree**: clean
**Result**: 18 pass, 2 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bin/rspec spec/requests/month_statement_row_spec.rb -e "open month account rows carry one statement icon and n` | count unknown | - | pass |
| C2 | `bin/rspec spec/requests/month_statement_row_spec.rb -e "account without statement shows only the planilha hint` | count unknown | - | pass |
| C3 | `browser - reach the state, save captures/statement-row.running.png` | - | - | **not judged** (screens.md) |
| C4 | `bin/rspec spec/system/month_statement_row_spec.rb -e "picking a spreadsheet alone stages Planilha and offers t` | count unknown | - | pass |
| C5 | `bin/rspec spec/system/month_statement_row_spec.rb -e "picking a PDF alone withholds the send and keeps the hin` | count unknown | - | pass |
| C6 | `bin/rspec spec/system/month_statement_row_spec.rb -e "picking both files stages Pdf above Planilha with the se` | count unknown | - | pass |
| C7 | `bin/rspec spec/system/month_statement_row_spec.rb -e "two files of each kind stage the first of each"` | count unknown | - | pass |
| C8 | `bin/rspec spec/system/month_statement_row_spec.rb -e "nota txt and extrato ofx are refused and a staged xlsx c` | count unknown | - | pass |
| C9 | `bin/rspec spec/system/month_statement_row_spec.rb -e "sending the staged files persists the statement and toas` | count unknown | - | pass |
| C10 | `bin/rspec spec/system/month_statement_row_spec.rb -e "descartar clears the staged files without posting"` | count unknown | - | pass |
| C11 | `bin/rspec spec/requests/month_statement_row_spec.rb -e "closed month rows have no statement control"` | count unknown | - | pass |
| C17 | `bin/rspec spec/requests/month_statement_row_spec.rb -e "refused POST re-renders with Envie a planilha and no s` | count unknown | - | pass |
| C18 | `bin/rspec spec/requests/reopen_spec.rb -e "reopen shows the statement control and hides the send"` | count unknown | - | pass |
| C12 | `bin/rspec spec/system/month_statement_row_spec.rb -e "every Pagamentos row measures at most 48px across five s` | count unknown | - | pass |
| C13 | `bin/rspec spec/requests/month_statement_row_spec.rb -e "long history document and status cells truncate and ca` | count unknown | - | pass |
| C14 | `bin/rspec spec/requests/month_statement_row_spec.rb -e "Pagamentos omits the match observation that matches st` | count unknown | - | pass |
| C15 | `browser - reach the state at 390px, save captures/statement-row-390.running.png` | - | - | **not judged** (screens.md) |
| C15 | `bin/rspec spec/system/month_statement_row_spec.rb -e "390px pagamentos stacks two lines without horizontal scr` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| send hidden unless a spreadsheet is staged -> send always visible (C5) | `app/javascript/controllers/statement_row_controller.js:66` | yes |
| second PDF ignored -> second PDF replaces the first (C7) | `app/javascript/controllers/statement_row_controller.js:22` | yes |
| unknown extension refused -> unknown extension staged as a PDF (C8) | `app/javascript/controllers/statement_row_controller.js:114` | yes |
