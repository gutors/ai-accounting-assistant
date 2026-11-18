# documents-sem-mes-list proofs

**HEAD**: e062849
**Tree**: clean
**Result**: 17 pass, 0 fail; mutations 0 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents excludes matched do` | count unknown | - | pass |
| C2 | `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents includes unmatched ` | count unknown | - | pass |
| C3 | `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents includes unmatched ` | count unknown | - | pass |
| C4 | `bin/rspec spec/models/supporting_document_filter_list_spec.rb -e "filter_list filters by payee substring case-` | count unknown | - | pass |
| C5 | `bin/rspec spec/models/supporting_document_filter_list_spec.rb -e "filter_list filters by valid kind and ignore` | count unknown | - | pass |
| C6 | `bin/rspec spec/models/supporting_document_filter_list_spec.rb -e "filter_list filters by date_from and date_to` | count unknown | - | pass |
| C7 | `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents filters Sem mes by ` | count unknown | - | pass |
| C8 | `bin/rspec spec/models/supporting_document_filter_list_spec.rb -e "filter_list orders by date and amount ascend` | count unknown | - | pass |
| C9 | `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents defaults to date de` | count unknown | - | pass |
| C10 | `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents sorts by date ascen` | count unknown | - | pass |
| C11 | `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents sorts by amount des` | count unknown | - | pass |
| C12 | `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents renders SVG icon ac` | count unknown | - | pass |
| C13 | `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents omits Excluir icon ` | count unknown | - | pass |
| C14 | `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "submitter justification checkboxes remain ava` | count unknown | - | pass |
| C15 | `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET /supporting_documents responds 30` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |
