# month-overview-lists proofs

**HEAD**: 14d9971
**Tree**: clean
**Result**: 39 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "unconfirmed GET without spreadsheet enables In` | count unknown | - | pass |
| C2 | `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "POST account_confirmation without spreadsheet ` | count unknown | - | pass |
| C3 | `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "POST account_confirmation on closed month retu` | count unknown | - | pass |
| C4 | `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "POST account_confirmation reveals movements an` | count unknown | - | pass |
| C5 | `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "unauthenticated POST account_confirmation resp` | count unknown | - | pass |
| C6 | `bin/rspec spec/requests/months_account_confirmation_spec.rb -e "submitter POST account_confirmation responds 4` | count unknown | - | pass |
| C7 | `bin/rspec spec/models/investment_transfer_catalog_spec.rb -e "COMPE 001 debit Transferencia BB Rende Facil is ` | count unknown | - | pass |
| C7 | `bin/rspec spec/models/bank_statement_spec.rb -e "persist_import on COMPE 001 skips catalog debit and inserts o` | count unknown | - | pass |
| C8 | `bin/rspec spec/models/payment_spec.rb -e "for_month omits leftover COMPE 001 Rende Facil payment"` | count unknown | - | pass |
| C8 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "GET month and matches omit leftover catalog debit fro` | count unknown | - | pass |
| C9 | `bin/rspec spec/models/month_spec.rb -e "close does not refuse leftover catalog debit as missing document"` | count unknown | - | pass |
| C9 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "POST close with leftover catalog debit does not retur` | count unknown | - | pass |
| C10 | `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "custos section omits leftover COMPE 001 Rende Facil paym` | count unknown | - | pass |
| C11 | `bin/rspec spec/models/investment_transfer_catalog_spec.rb -e "COMPE 001 debit RENDE FACIL and rende facil matc` | count unknown | - | pass |
| C12 | `bin/rspec spec/models/investment_transfer_catalog_spec.rb -e "COMPE 033 debit Transferencia BB Rende Facil is ` | count unknown | - | pass |
| C12 | `bin/rspec spec/models/bank_statement_spec.rb -e "persist_import on COMPE 033 inserts Rende Facil debit as Paym` | count unknown | - | pass |
| C13 | `bin/rspec spec/models/investment_transfer_catalog_spec.rb -e "COMPE 001 credit containing Rende Facil is not a` | count unknown | - | pass |
| C13 | `bin/rspec spec/models/bank_statement_spec.rb -e "persist_import on COMPE 001 inserts Rende Facil credit as Inf` | count unknown | - | pass |
| C14 | `bin/rspec spec/requests/bank_statements_spec.rb -e "import toast counts 1 recebimento and 1 pagamento omitting` | count unknown | - | pass |
| C15 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "GET month defaults each list to date ascending with a` | count unknown | - | pass |
| C16 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "Pagamentos Valor sorts amount desc without reordering` | count unknown | - | pass |
| C17 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "Pagamentos Valor toggles amount dir from desc to asc"` | count unknown | - | pass |
| C18 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "Recebimentos Data sort keeps Pagamentos amount sort"` | count unknown | - | pass |
| C19 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "pool Favorecido sorts by payee"` | count unknown | - | pass |
| C20 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "pool Valor sorts by amount_cents"` | count unknown | - | pass |
| C21 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "sort header URLs keep bank_account_id"` | count unknown | - | pass |
| C22 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "invalid sort and dir params fall back to date ascendi` | count unknown | - | pass |
| C23 | `bin/rspec spec/requests/months_spec.rb -e "unauthenticated GET /months/2026-05 responds 302 to /login"` | count unknown | - | pass |
| C30 | `bin/rspec spec/requests/months_spec.rb -e "submitter GET /months/2026-05 responds 404 and omits PIX Isolado"` | count unknown | - | pass |
| C31 | `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-04 when never opened responds 404"` | count unknown | - | pass |
| C24 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "Pagamentos status includes Documento faltante without` | count unknown | - | pass |
| C25 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "Pagamentos status includes Documento faltante without` | count unknown | - | pass |
| C26 | `bin/rspec spec/requests/month_matches_spec.rb -e "GET matches still includes Sugestao de excecao"` | count unknown | - | pass |
| C27 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "pool heads are Data Favorecido Tipo Valor Foto withou` | count unknown | - | pass |
| C28 | `bin/rspec spec/requests/month_overview_lists_spec.rb -e "pool lists unmatched month document payee without Dev` | count unknown | - | pass |
| C29 | `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 with no unmatched documents includes Nenhum doc` | count unknown | - | pass |
| C32 | `bin/rspec spec/docs/visual_identity_month_overview_spec.rb -e "visual-identity month omits disabled Iniciar Su` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| catalog COMPE equality inverted | `app/models/investment_transfer_catalog.rb:8` | yes |
| invalid sort/dir fallback AND to OR | `app/models/month_list_sort.rb:5` | yes |
| without_catalog reject inverted to select | `app/models/payment.rb:15` | yes |
