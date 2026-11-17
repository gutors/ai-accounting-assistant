# lote-identify-batch proofs

**HEAD**: f6e2492
**Tree**: clean
**Result**: 26 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch two authorized XML` | count unknown | - | pass |
| C2 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch empty.jpg is recib` | count unknown | - | pass |
| C3 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch mixed XML keeps Pa` | count unknown | - | pass |
| C4 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch missing or empty f` | count unknown | - | pass |
| C5 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch 31 files is 422 No` | count unknown | - | pass |
| C22 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch 30 files is 200 wi` | count unknown | - | pass |
| C6 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "unauthenticated POST identify_batch re` | count unknown | - | pass |
| C7 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "submitter POST identify_batch persists` | count unknown | - | pass |
| C18 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch photo fields origi` | count unknown | - | pass |
| C19 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch NFC-e QR origin Co` | count unknown | - | pass |
| C21 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch without focus resp` | count unknown | - | pass |
| C8 | `bin/rspec spec/models/supporting_document_identify_batch_spec.rb -e "identify_batch two JPEGs overlap when IDE` | count unknown | - | pass |
| C9 | `bin/rspec spec/models/supporting_document_identify_batch_spec.rb -e "identify_batch two JPEGs are serial when ` | count unknown | - | pass |
| C10 | `bin/rspec spec/models/supporting_document_identify_batch_spec.rb -e "IDENTIFY_THREADS 0 clamps to 1"` | count unknown | - | pass |
| C10 | `bin/rspec spec/models/supporting_document_identify_batch_spec.rb -e "IDENTIFY_THREADS 9 clamps to 8"` | count unknown | - | pass |
| C10 | `bin/rspec spec/models/supporting_document_identify_batch_spec.rb -e "IDENTIFY_THREADS unset uses 4"` | count unknown | - | pass |
| C11 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch keeps files order ` | count unknown | - | pass |
| C20 | `bin/rspec spec/config/application_spec.rb -e "database max_connections adds IDENTIFY_THREADS"` | count unknown | - | pass |
| C12 | `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "coordinator identify two XMLs fills lote withou` | count unknown | - | pass |
| C13 | `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "lote identify_batch in flight shows Identifican` | count unknown | - | pass |
| C14 | `bin/rspec spec/system/document_lote_spec.rb -e "one XML is simple include chrome"` | count unknown | - | pass |
| C15 | `bin/rspec spec/system/document_lote_spec.rb -e "coordinator photo miss lote row is Digitar Recibo"` | count unknown | - | pass |
| C16 | `bin/rspec spec/system/document_lote_spec.rb -e "coordinator unreadable XML is Erro and leaves other lote rows"` | count unknown | - | pass |
| C17 | `bin/rspec spec/system/document_lote_spec.rb -e "Incluir prontos two XMLs empties lote into Sem mes"` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| overflow bound > 30 -> >= 30 | `app/controllers/supporting_documents_controller.rb:19` | yes |
| items order files[] -> reversed | `app/models/supporting_document/batch_identify.rb:21` | yes |
| pool size threads -> 1 | `app/models/supporting_document/batch_identify.rb:14` | yes |
