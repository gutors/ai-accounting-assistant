# lote-identify-waves proofs

**HEAD**: 07984a9
**Tree**: clean
**Result**: 10 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "five XMLs send identify_batch waves of 4 then 1` | count unknown | - | pass |
| C2 | `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "four XMLs send one identify_batch of 4"` | count unknown | - | pass |
| C3 | `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "five XMLs first wave in flight shows Identifica` | count unknown | - | pass |
| C4 | `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "five XMLs first wave paints four Pronto and fif` | count unknown | - | pass |
| C5 | `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "five XMLs second wave paints fifth Pronto"` | count unknown | - | pass |
| C6 | `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "second picker while identifying joins later wav` | count unknown | - | pass |
| C7 | `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "unreadable XML in first wave still sends the se` | count unknown | - | pass |
| C8 | `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "Incluir prontos four XMLs while fifth is identi` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| wave size 4 -> 5 | `app/javascript/controllers/document_lote_controller.js:4` | yes |
| in-flight guard identifyingInFlight -> disabled | `app/javascript/controllers/document_lote_controller.js:160` | yes |
| after wave finally pumpIdentify -> omitted | `app/javascript/controllers/document_lote_controller.js:196` | yes |
