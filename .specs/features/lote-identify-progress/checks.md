# Lote identify progress checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/lote-identify-progress/plan.md`

15 checks in 2 slices · 1 one-way door · 0 open

## Checks

### S1 - The rule measures the lote, the sentence names the wave

**C1** - With ten files and the second wave in flight, the section matches `.specs/features/lote-identify-progress/captures/lote-b-faixa-fila.png`: the heading carries ten ticks with ticks 5–8 hollow, the sentence `Identificando os documentos 5 a 8 de 10` sits under them, and the heading's own border is gone (AC 1)
Proof: browser - ten files, second wave gated in flight, save `captures/lote-b-faixa-fila.running.png` at 716×798

**C2** - The ticks take the three states drawn in `.specs/features/lote-identify-progress/captures/ruler-states.png`: with ten files and the second wave in flight, ticks 1–4 have background `rgb(46, 107, 78)`, ticks 5–8 have background `rgb(243, 245, 241)` with a `2px` inset `rgb(46, 107, 78)` outline, ticks 9–10 have background `rgb(199, 213, 202)` (AC 1)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "ten files paint ten ticks in the three states"`

**C3** - The sentence names each wave's 1-based bounds and the lote total: ten files give `Identificando os documentos 1 a 4 de 10`, then `5 a 8 de 10`, then `9 a 10 de 10`; five files give `Identificando os documentos 1 a 4 de 5`, then `Identificando o documento 5 de 5`, never `os documentos 5 a 5` (AC 2)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "sentence names every wave bounds and the total"`

**C4** - Four files, one wave, show `Identificando os documentos 1 a 4 de 4` and four ticks (AC 3)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "four files show one wave over four ticks"`

**C5** - One file shows no rule and no sentence, and its proof square keeps `Identificando o arquivo…` (AC 4)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "one file keeps the proof square sentence and no rule"`

**C6** - With ten files and the second wave in flight, the lote sheet matches `.specs/features/lote-identify-progress/captures/lote-b-faixa-fila.png` in the rows it draws: the first three rows say `Pronto` with their date, payee, kind and amount, and no row carries a second sentence under its file name (AC 5)
Proof: browser - ten files, second wave gated in flight, save `captures/lote-b-faixa-fila.running.png` at 716×798

**C7** - Every row of a five-file lote carries its Situação word: four `Identificando` while the first wave is in flight and one `Na fila`; once that wave returns the first four say `Pronto` and the fifth still says `Na fila`; a row in `Erro` shows its error sentence and no reading sentence (AC 5)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "five XMLs split Identificando from Na fila"`

**C8** - An unreadable XML `nota.xml` as the first of four fills one tick `margem` — the error state of `.specs/features/lote-identify-progress/captures/ruler-states.png` — leaves three `caixa` ticks, and its row shows `Erro` with `O XML da nota fiscal não pôde ser lido` (AC 6)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "unreadable XML fills one margem tick"`

**C9** - When the last wave lands, the rule and the sentence are gone and `Incluir prontos (5)` carries the count (AC 7)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "last wave leaves no rule and the count on Incluir prontos"`

**C10** - `Retirar` on a five-file lote while the first wave is in flight leaves four ticks, and the sentence names the same four documents `1 a 4 de 4` (AC 8)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "Retirar repaints the rule with one tick fewer"`

**C11** - Attaching two more files while the first wave of five is in flight paints seven ticks, keeps ticks 1–4 hollow, and shows `f.xml` and `g.xml` as `Na fila` (AC 9)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "second picker paints seven ticks and queues the new files"`

**C12** - At 390px wide with thirty files, the rule's width does not exceed its container, the page has no horizontal scroll, and every tick measures at least 8px (AC 10)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "thirty files keep every tick eight pixels at 390"`

### S2 - The lote sheet and the rule agree

**C13** - Each row's Situação matches its tick: `Pronto` and `Digitar` filled `caixa`, `Erro` filled `margem`, `Identificando` hollow, `Na fila` pale `rule` (AC 11)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "each Situacao matches its tick"`

**C14** - Selecting a row that is still `Na fila` shows the book with `amount`, `date` and `payee` empty and no `Identificando o arquivo…` in the proof square (AC 12)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "selecting a queued row leaves the book empty"`

**C15** - `Incluir prontos (4)` while the second wave of a ten-file lote is in flight leaves six ticks, keeps the four in-flight rows hollow, and names `Identificando os documentos 1 a 4 de 6` (AC 13)
Proof: `bin/rspec spec/system/document_lote_progress_spec.rb -e "Incluir prontos while a wave is in flight repaints the rule"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| sentence bounds, AC 2 (6 examples) | `1 a 4 de 10` C3 · `5 a 8 de 10` C3 · `9 a 10 de 10` C3 · `1 a 4 de 5` C3 · `o documento 5 de 5` C3 · `1 a 4 de 4` C4 | - |
| tick state -> paint, AC 11 (5) | `pronto` C13 · `digitar` C13 · `error` C8, C13 · `identifying` in wave C2, C13 · `identifying` queued C2, C13 | - |
| lote size with the rule (4) | 10 C1, C2 · 5 C6, C7 · 4 C4 · 1 C5 | - |
| rule lifecycle (5) | painted at pick C1 · absent after the last wave C9 · one fewer after `Retirar` C10 · repainted after a second pick C11 · repainted after `Incluir prontos` C15 | - |
| door 1: wave is `this.wave`, never `item.wave` (3 stale-flag sites) | `failIdentify` C8 · `removeSelected` C10 · `includeReady` C15 | - |
| source `lote-b-faixa-fila.png` controls (4) | tick rule and sentence C1, C2 · row select C14 · `Retirar` C10 · `Incluir prontos` C15 | - |
| lote window widths (1) | 390px, 30 files C12 | - |
| Surface (0) | none - `identify_batch` unchanged | - |

## Swept

- validation: existing - the picker's 30-file ceiling from `lote-identify-batch`; C12 proves the rule holds at that ceiling
- failure modes: C8 - a wave that finishes in error still fills its tick and still starts the next wave
- idempotency: n/a - nothing is stored; every render repaints the rule from `items` and `this.wave`
- authorization: existing - the lote page is the coordinator's session from `coordinator-access`; the rule adds no request
- concurrency: C11, C15 - a picker change and an `Incluir prontos` arriving while a wave is in flight
- data lifecycle: n/a - the lote is in-memory until Incluir, so a reload has nothing to restore
- dependency failure: C8 - a wave whose POST fails paints `Erro` and keeps its tick
- state transitions: C13 - every Situação against its tick; C9 - the last wave retires the rule
- observability: n/a - no logging requirement in this slice

## Handoff

- **Settled mid-build:** "Critério 4 manda: com um arquivo só, volta a tela de inclusão simples, sem régua" - a lote that drops to one file shows no rule and no sentence; AC 13 is proven with a ten-file lote that keeps six. "Registrar como diferenças do capture (ADR-0011), sem construir" - the two proof-square facts the capture draws stay as they are (AD-0011).
- **Dispatched:** screens round 1 at `f8a79f5`; Verifier at `f8a79f5`
- **Boundary:** C1-C15 closed at `e17b34a`
- **Abandoned:** none
- **Walked:** Coordinator `/supporting_documents` with ten authorized XMLs `d1.xml`…`d10.xml` attached through the picker, waves gated so the second wave sat in flight; the section showed the ten-tick rule with ticks 5–8 hollow and `Identificando os documentos 5 a 8 de 10`, rows 1–4 `Pronto`, rows 5–8 `Identificando`, rows 9–10 `Na fila`, and `Incluir prontos (4)`. Saved as `captures/lote-b-faixa-fila.running.png` at 716×798, the section's own size at a 780px window. The 390px / 30-file state and the singular `Identificando o documento 5 de 5` are proven by C12 and C3.
