# lote-identify-progress proofs

**HEAD**: e17b34a
**Tree**: clean
**Result**: 15 pass, 2 fail; mutations 0 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `browser - ten files, second wave gated in flight, save captures/lote-b-faixa-fila.running.png at 716×798` | - | - | **not judged** (screens.md) |
| C2 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "ten files paint ten ticks in the three states"` | count unknown | - | pass |
| C3 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "sentence names every wave bounds and the total"` | count unknown | - | pass |
| C4 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "four files show one wave over four ticks"` | count unknown | - | pass |
| C5 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "one file keeps the proof square sentence and no rule"` | count unknown | - | pass |
| C6 | `browser - ten files, second wave gated in flight, save captures/lote-b-faixa-fila.running.png at 716×798` | - | - | **not judged** (screens.md) |
| C7 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "five XMLs split Identificando from Na fila"` | count unknown | - | pass |
| C8 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "unreadable XML fills one margem tick"` | count unknown | - | pass |
| C9 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "last wave leaves no rule and the count on Incluir pro` | count unknown | - | pass |
| C10 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "Retirar repaints the rule with one tick fewer"` | count unknown | - | pass |
| C11 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "second picker paints seven ticks and queues the new f` | count unknown | - | pass |
| C12 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "thirty files keep every tick eight pixels at 390"` | count unknown | - | pass |
| C13 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "each Situacao matches its tick"` | count unknown | - | pass |
| C14 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "selecting a queued row leaves the book empty"` | count unknown | - | pass |
| C15 | `bin/rspec spec/system/document_lote_progress_spec.rb -e "Incluir prontos while a wave is in flight repaints th` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |
