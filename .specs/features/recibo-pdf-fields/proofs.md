# recibo-pdf-fields proofs

**HEAD**: b1501ab
**Tree**: clean
**Result**: 20 pass, 0 fail; mutations 0 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `bin/rspec spec/models/recibo_fields_spec.rb -e "Real Padaria recibo PDF is 15500 2026-06-15 Padaria Central In` | count unknown | - | pass |
| C2 | `bin/rspec spec/models/recibo_fields_spec.rb -e "Real Kali recibo PDF is 29500 2026-06-27 Kali Confeitaria not ` | count unknown | - | pass |
| C3 | `bin/rspec spec/models/recibo_fields_spec.rb -e "Real amount-only PDF returns Miss"` | count unknown | - | pass |
| C4 | `bin/rspec spec/models/recibo_fields_spec.rb -e "Real DANFE PDF without RECIBO title returns Miss"` | count unknown | - | pass |
| C5 | `bin/rspec spec/models/recibo_fields_spec.rb -e "Real app receipt PDF returns Miss"` | count unknown | - | pass |
| C6 | `bin/rspec spec/models/recibo_fields_spec.rb -e "Real pdftotext Padaria triple does not call PhotoOcr"` | count unknown | - | pass |
| C6 | `bin/rspec spec/models/recibo_fields_spec.rb -e "Real empty pdftotext uses OCR Padaria triple"` | count unknown | - | pass |
| C7 | `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST identify Padaria recibo PDF fills boo` | count unknown | - | pass |
| C8 | `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch Padaria recibo PDF` | count unknown | - | pass |
| C9 | `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "submitter POST identify Padaria recibo PDF` | count unknown | - | pass |
| C10 | `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST identify JPEG recibo ignores PhotoFie` | count unknown | - | pass |
| C11 | `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST identify app receipt PDF is recibo ty` | count unknown | - | pass |
| C12 | `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST Padaria recibo PDF persists photo ori` | count unknown | - | pass |
| C13 | `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "GET edit Padaria recibo PDF origins Lido d` | count unknown | - | pass |
| C14 | `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST Padaria recibo PDF wins over typed pa` | count unknown | - | pass |
| C15 | `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST incomplete recibo PDF uses typed amou` | count unknown | - | pass |
| C16 | `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST recibo JPEG ignores PhotoFields stays` | count unknown | - | pass |
| C17 | `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST nota_fiscal DANFE PDF does not read R` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |
