# Lote identify waves checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: none - no plan.md; Intent below

8 checks in 1 slice · 0 one-way doors · 0 open

## Intent

A coordinator who drops more than four supporting-document files into the lote waits on one `POST /supporting_documents/identify_batch` until every file is identified. Rows stay on `Identificando o arquivo…` for the whole request (about 14 seconds for nine files), then all flip at once. `IDENTIFY_THREADS` only overlaps workers inside that request; the page does not update per wave.

When this ships, one picker action still uses `identify_batch`, but the lote sends at most four files per POST, one POST at a time. Rows of a finished wave become Pronto, Digitar, or Erro while later rows stay on `Identificando o arquivo…`. Nothing persists until Incluir.

## Out of scope

- Streaming items inside one POST
- Changing `IDENTIFY_THREADS`, Puma, or the identify_batch JSON contract
- A progress counter (`Identificando 3 de 9…`)
- Submitter `POST /identify`
- Coupling the JS wave size to the `IDENTIFY_THREADS` env (wave size is 4)

## Checks

### S1 - Waves of 4

**C1** - Coordinator attaches five authorized XMLs `a.xml` … `e.xml` in one picker change: the page sends two `POST /supporting_documents/identify_batch` (first with 4 files, second with 1) and does not send `POST /supporting_documents/identify` (AC 1)
Proof: `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "five XMLs send identify_batch waves of 4 then 1"`

**C2** - Coordinator attaches four authorized XMLs in one change: the page sends one `POST /supporting_documents/identify_batch` with 4 files (AC 2)
Proof: `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "four XMLs send one identify_batch of 4"`

**C3** - While the first identify_batch of those five XMLs has not returned, all five rows show `Identificando o arquivo…` and the page does not show `#wait` unhidden (AC 3)
Proof: `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "five XMLs first wave in flight shows Identificando on all rows"`

**C4** - When that first POST returns, the first four rows show `Pronto` and the fifth still shows `Identificando o arquivo…` (AC 4)
Proof: `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "five XMLs first wave paints four Pronto and fifth Identificando"`

**C5** - When the second POST returns, the fifth row shows `Pronto` (AC 5)
Proof: `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "five XMLs second wave paints fifth Pronto"`

**C6** - While an identify_batch POST is in flight, when the coordinator attaches more files, those new rows show `Identificando o arquivo…` and the page keeps only one identify_batch POST in flight (AC 6)
Proof: `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "second picker while identifying joins later waves with one POST in flight"`

**C7** - First wave is unreadable XML `nota.xml` (`<nfe/>`) and three authorized XMLs, fifth authorized XML waits: after the first POST the page shows `Erro`, `O XML da nota fiscal não pôde ser lido`, three `Pronto`, and the fifth still `Identificando o arquivo…`, and still sends the second POST (AC 7)
Proof: `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "unreadable XML in first wave still sends the second POST"`

**C8** - When the first four of those five XMLs are `Pronto` and the fifth is still identifying, coordinator uses `Incluir prontos`: the system persists those four SupportingDocuments through `POST /supporting_documents/batch` and the fifth row remains in the lote (AC 8)
Proof: `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "Incluir prontos four XMLs while fifth is identifying"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| Wave size bound (2) | 5 files 4 then 1 C1 · 4 files one POST of 4 C2 | - |
| First-wave in-flight paint (1) | 5 Identificando C3 | - |
| Wave paint (2) | first 4 Pronto C4 · fifth Pronto C5 | - |
| In-flight identify_batch cap (1) | one POST C6 | - |
| Mixed error in wave 1 (1) | Erro plus second POST C7 | - |
| Incluir prontos during later wave (1) | four persist, fifth remains C8 | - |

- Gesture proofs that attach the picker: C1–C8
- No other check claims more than the single case its proof exercises

## Swept

- validation: existing - picker MAX 30 from lote-identify-batch
- failure modes: C7
- idempotency: n/a - identify is preview; another picker action is another POST
- authorization: existing - identify_batch coordinator/session from lote-identify-batch
- concurrency: C6
- data lifecycle: C8
- dependency failure: existing - unreadable XML is Erro from lote-identify-batch; C7 reuses it across waves
- state transitions: C3, C4, C5
- observability: n/a - no logging requirement in this slice

## Handoff

- **Settled mid-build:** none
- **Dispatched:** Verifier at `07984a9` returned
- **Boundary:** C1-C8 closed at `07984a9`
- **Abandoned:** none
- **Walked:** Coordinator `/login` Ambiente local `gutors@gmail.com` then `/supporting_documents`. Playwright attached five authorized XMLs `a.xml`…`e.xml` from `tmp/walk-waves/` (IDE tab cannot set `<input type=file>`). Two `POST /supporting_documents/identify_batch` returned 200; the lote showed `Situação`, `Incluir prontos (5)`, and Pronto on Padaria Central / Farmácia São José / Mercado Bom Preço / Atacado Verde / Café do Ponto. Sem mês still held the earlier documents — identify did not persist. XML identify finished too fast to photograph the fifth row still on `Identificando o arquivo…`; that wait is C3–C4.
