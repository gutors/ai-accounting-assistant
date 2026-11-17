# Lote identify batch checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/lote-identify-batch/plan.md`

22 checks in 3 slices · 1 one-way door · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.

## Checks

### S1 - One POST identifies the picker set · door 1

**C1** - Coordinator `POST /supporting_documents/identify_batch` with authorized XML `proc-nfe-padaria.xml` (`vNF` `155.00`, emit `Padaria Central`, `dhEmi` `2026-05-11`) then `proc-nfe-farmacia.xml` (`vNF` `89.40`, emit `Farmácia São José`) responds `200` with `items` length `2` in that order, `items[0].ok` true, `payee` `Padaria Central`, `amount` `155,00`, `kind` `nota_fiscal`, `locked` true, `origin` `XML autorizado`, `arquivo` `XML`, `items[1].payee` `Farmácia São José`, `amount` `89,40`, and persists `0` SupportingDocument rows (AC 1, door 1)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch two authorized XMLs fills items without persisting"`

**C2** - That POST with only JPEG `empty.jpg` (photo extract misses) responds `200`, `items[0].ok` true, `kind` `recibo`, `locked` false, `origin` `Digitado`, `arquivo` `Foto`, and empty amount, date, and payee (AC 2, door 1)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch empty.jpg is recibo typed empty"`

**C3** - That POST with authorized XML `proc-nfe-padaria.xml` then unreadable XML `nota.xml` (`<nfe/>`) responds `200`, `items[0].ok` true with `payee` `Padaria Central`, `items[1].ok` false with `error` `O XML da nota fiscal não pôde ser lido`, and persists `0` SupportingDocument rows (AC 3, door 1)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch mixed XML keeps Padaria and unreadable error"`

**C4** - `POST /supporting_documents/identify_batch` with `files[]` missing or empty responds `422` with `{ "error": "Envie os arquivos" }` and persists nothing (AC 4, door 1)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch missing or empty files is 422 Envie os arquivos"`

**C5** - `POST /supporting_documents/identify_batch` with 31 files responds `422` with `{ "error": "No máximo 30 arquivos neste lote" }` and persists nothing (AC 5, door 1)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch 31 files is 422 No maximo 30"`

**C22** - `POST /supporting_documents/identify_batch` with 30 JPEG files responds `200` with `items` length `30` and persists nothing (Landing 1..30, AC 5 bound)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch 30 files is 200 with 30 items"`

**C6** - Unauthenticated `POST /supporting_documents/identify_batch` responds `302` to `/login` and persists nothing (AC 6)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "unauthenticated POST identify_batch responds 302 to /login"`

**C7** - Submitter of the focused organization `POST /supporting_documents/identify_batch` responds `404` and persists nothing (AC 7)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "submitter POST identify_batch persists none and 404"`

**C18** - Coordinator `POST /supporting_documents/identify_batch` with JPEG `danfe.jpg` whose photo fields read amount `155,00`, date `2026-05-11`, payee `Padaria Central` responds `200`, `items[0].ok` true, `origin` `Lido da foto`, `locked` false (door 1)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch photo fields origin Lido da foto"`

**C19** - Coordinator `POST /supporting_documents/identify_batch` with JPEG `nfce.jpg` whose symbols scan returns an NFC-e QR URL whose public consulta returns the book triple responds `200`, `items[0].ok` true, `origin` `Consulta NFC-e` (door 1)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch NFC-e QR origin Consulta NFC-e"`

**C21** - `POST /supporting_documents/identify_batch` with a session and no focused organization responds `302` to `/login` and persists nothing (Surface 302)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch without focus responds 302 to /login"`

### S2 - Bounded parallel identify

**C8** - `identify_batch` of two JPEGs with `IDENTIFY_THREADS` `2`, when `PhotoSymbols.current.scan` blocks until both calls have started, has both scans in flight at the same moment and both items `ok` true (AC 8)
Proof: `bin/rspec spec/models/supporting_document_identify_batch_spec.rb -e "identify_batch two JPEGs overlap when IDENTIFY_THREADS is 2"`

**C9** - `identify_batch` of those two JPEGs with `IDENTIFY_THREADS` `1` starts the second `scan` only after the first `scan` returns (AC 9)
Proof: `bin/rspec spec/models/supporting_document_identify_batch_spec.rb -e "identify_batch two JPEGs are serial when IDENTIFY_THREADS is 1"`

**C10** - `IDENTIFY_THREADS` clamps to `1`..`8`: `0` → `1`, `9` → `8`, unset → `4` (AC 10)
Proof: `bin/rspec spec/models/supporting_document_identify_batch_spec.rb -e "IDENTIFY_THREADS 0 clamps to 1"`
Proof: `bin/rspec spec/models/supporting_document_identify_batch_spec.rb -e "IDENTIFY_THREADS 9 clamps to 8"`
Proof: `bin/rspec spec/models/supporting_document_identify_batch_spec.rb -e "IDENTIFY_THREADS unset uses 4"`

**C11** - `POST /supporting_documents/identify_batch` with `files[]` named `b.jpg` then `a.jpg` responds `200` with `items[0].filename` `b.jpg` and `items[1].filename` `a.jpg` (AC 11, door 1)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch keeps files order b.jpg then a.jpg"`

**C20** - `config/database.yml` default `max_connections` is `RAILS_MAX_THREADS` plus clamped `IDENTIFY_THREADS` plus `3` (Assumption: Postgres pool)
Proof: `bin/rspec spec/config/application_spec.rb -e "database max_connections adds IDENTIFY_THREADS"`

### S3 - Lote chrome after one picker action

**C12** - Coordinator on `/supporting_documents` attaches those two authorized XMLs in one file picker change: the page sends one `POST /supporting_documents/identify_batch`, does not send `POST /supporting_documents/identify`, then shows `Situação`, both filenames, `Padaria Central`, `Farmácia São José`, `R$ 155,00`, `R$ 89,40`, `Pronto` twice, and `Nenhum documento`, with `SupportingDocument.count` `0` (AC 12)
Proof: `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "coordinator identify two XMLs fills lote without persisting"`

**C13** - While that identify_batch POST has not returned, each of those two rows shows `Identificando o arquivo…` and the page does not show `#wait` unhidden (AC 13)
Proof: `bin/rspec spec/system/document_lote_identify_batch_spec.rb -e "lote identify_batch in flight shows Identificando o arquivo on both rows"`

**C14** - Coordinator attaches one authorized XML only: after identify_batch returns the heading is `Incluir documento` and the page does not include `Situação` (AC 14)
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "one XML is simple include chrome"`

**C15** - Coordinator attaches files named `empty.jpg` and `other.jpg` in one change: after identify_batch returns those rows show `Digitar` and `Recibo` (AC 15)
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "coordinator photo miss lote row is Digitar Recibo"`

**C16** - Coordinator attaches `proc-nfe-padaria.xml` and unreadable `nota.xml` in one change: after identify_batch returns the page shows `Pronto`, `Erro`, and `O XML da nota fiscal não pôde ser lido` (AC 16)
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "coordinator unreadable XML is Erro and leaves other lote rows"`

**C17** - Coordinator then uses `Incluir prontos` on the two Pronto XML rows: the system persists those two SupportingDocuments through existing `POST /supporting_documents/batch` (AC 17)
Proof: `bin/rspec spec/system/document_lote_spec.rb -e "Incluir prontos two XMLs empties lote into Sem mes"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| `POST /supporting_documents/identify_batch` statuses (4) | `200` C1 · `422` C4, C5 · `302` C6, C21 · `404` C7 | - |
| 302 callers (2) | unauthenticated C6 · no focus C21 | - |
| 422 copy (2) | `Envie os arquivos` C4 · `No máximo 30 arquivos neste lote` C5 | - |
| identify_batch size bound (2) | 30 files `200` C22 · 31 files `422` C5 | - |
| origin stamps (4) | `XML autorizado` C1 · `Digitado` C2 · `Lido da foto` C18 · `Consulta NFC-e` C19 | - |
| arquivo (2) | `XML` C1 · `Foto` C2 | - |
| kind (2) | `nota_fiscal` C1 · `recibo` C2 | - |
| locked (2) | true C1 · false C2 | - |
| IDENTIFY_THREADS clamp (3) | `0`→`1` C10 · `9`→`8` C10 · unset→`4` C10 | - |
| overlap vs serial (2) | `IDENTIFY_THREADS` `2` C8 · `IDENTIFY_THREADS` `1` C9 | - |
| startup config: IDENTIFY_THREADS (2 assemblies) | model clamp C10 · `database.yml` pool C20 | - |
| Landing identify-batch HTTP contract (1) | door 1 C1–C7, C11, C18, C19 | - |

- Claims naming a status code, route or response shape: C1–C7, C11, C18, C19, C21 - each has a proof that crosses the boundary
- Gesture proofs that attach the picker: C12–C17
- No other check claims more than the single case its proof exercises

## Swept

- validation: C4, C5
- failure modes: C3
- idempotency: n/a - identify_batch persists nothing; a retry is another preview
- authorization: C6, C7, C21
- concurrency: C8, C9, C11
- data lifecycle: C1, C17
- dependency failure: C3
- state transitions: n/a - no persisted SupportingDocument state; lote row paint is C12–C16
- observability: n/a - no logging requirement in this slice

## Handoff

- **Settled mid-build:** none
- **Dispatched:** Verifier at `6ddfe6f` returned FAIL (C5 bound)
- **Boundary:** C1-C22 closed at `6ddfe6f` pending C22 commit
- **Abandoned:** none
- **Walked:** Coordinator `/login` Ambiente local `gutors@gmail.com` then `/supporting_documents` on the running app. IDE tab cannot set `<input type=file>`; picker attach is C12–C17. Running Puma `POST /supporting_documents/identify_batch` of `walk-padaria.xml` then `walk-farmacia.xml` returned `200` items Padaria `155,00` / Farmácia `89,40`, `XML autorizado`, no persist. In-flight `#wait` hidden is C13. Incluir prontos still `POST /supporting_documents/batch` is C17.
