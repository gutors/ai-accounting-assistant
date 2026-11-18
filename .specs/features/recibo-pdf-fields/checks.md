# Recibo PDF fields checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/recibo-pdf-fields/plan.md`

17 checks in 3 slices · 0 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.

## Checks

### S1 - Recibo PDF parser

**C1** - `ReciboFields::Real` reading a PDF whose text is `RECIBO DE PAGAMENTO`, `Eu Padaria Central, portador`, `a quantia de R$ 155,00`, `15 de junho de 2026` returns `Fields` with `amount_cents` `15500` (Integer, not Float), `document_on` `2026-06-15`, payee `Padaria Central` (AC 1)
Proof: `bin/rspec spec/models/recibo_fields_spec.rb -e "Real Padaria recibo PDF is 15500 2026-06-15 Padaria Central Integer"`

**C2** - That Real reading a PDF whose text is `RECIBO`, `Recebi de Centro Social da Rua`, `o valor de R$ 295,00`, date `27 / 06 / 2026`, payee block `Kali Confeitaria` returns `amount_cents` `29500`, `document_on` `2026-06-27`, payee `Kali Confeitaria`, and does not return `Centro Social da Rua` (AC 2)
Proof: `bin/rspec spec/models/recibo_fields_spec.rb -e "Real Kali recibo PDF is 29500 2026-06-27 Kali Confeitaria not payer"`

**C3** - If that PDF has only `R$ 155,00` and no date and no payee, Real returns `Miss` (AC 3)
Proof: `bin/rspec spec/models/recibo_fields_spec.rb -e "Real amount-only PDF returns Miss"`

**C4** - If the PDF text is a DANFE (`EMITENTE`, `VALOR TOTAL DA NOTA`) with no `RECIBO` title, Real returns `Miss` (AC 4)
Proof: `bin/rspec spec/models/recibo_fields_spec.rb -e "Real DANFE PDF without RECIBO title returns Miss"`

**C5** - If the PDF text is an app receipt (`Aqui está o recibo da sua entrega`, `Total`, `Preço da viagem`), Real returns `Miss` (AC 5)
Proof: `bin/rspec spec/models/recibo_fields_spec.rb -e "Real app receipt PDF returns Miss"`

**C6** - When `pdftotext` yields a usable Padaria triple, `PhotoOcr` does not run; when `pdftotext` is empty or unusable and raster OCR of a page yields that Padaria triple, Real returns those three values (AC 6)
Proof: `bin/rspec spec/models/recibo_fields_spec.rb -e "Real pdftotext Padaria triple does not call PhotoOcr"`
Proof: `bin/rspec spec/models/recibo_fields_spec.rb -e "Real empty pdftotext uses OCR Padaria triple"`
Proof: `bin/rspec spec/models/recibo_fields_spec.rb -e "Real unusable pdftotext uses OCR Padaria triple"`

### S2 - Identify fills the book

**C7** - Coordinator `POST /supporting_documents/identify` with that Padaria recibo PDF and no typed fields persists `0` SupportingDocument rows, responds `200`, Arquivo `Foto`, kind `recibo` disabled, Valor `155,00`, Data `2026-06-15`, Favorecido `Padaria Central`, origin under each `Lido da foto`, those three not disabled, chave hidden (AC 7)
Proof: `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST identify Padaria recibo PDF fills book Lido da foto"`

**C8** - Coordinator `POST /supporting_documents/identify_batch` with that PDF as the only file responds `200`, `items[0].ok` true, `kind` `recibo`, `amount` `155,00`, `date` `2026-06-15`, `payee` `Padaria Central`, `origin` `Lido da foto`, `locked` false, persist `0` rows (AC 8)
Proof: `bin/rspec spec/requests/supporting_documents_identify_batch_spec.rb -e "POST identify_batch Padaria recibo PDF origin Lido da foto"`

**C9** - Submitter `POST /supporting_documents/identify` with that PDF fills the same three values and origin `Lido da foto`, persist `0` (AC 9)
Proof: `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "submitter POST identify Padaria recibo PDF fills book Lido da foto"`

**C10** - Identify of JPEG named recibo.jpg whose `PhotoFields` stub would return payee `Mercado Silva` is kind `recibo`, empty amount/date/payee, origin `Digitado` (AC 10)
Proof: `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST identify JPEG recibo ignores PhotoFields and stays Digitado"`

**C11** - Identify of the app-receipt PDF is kind `recibo`, empty three fields, origin `Digitado` (AC 11)
Proof: `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST identify app receipt PDF is recibo typed empty"`

### S3 - Persist, fallback, lock

**C12** - Coordinator `POST /supporting_documents` with that Padaria PDF and no typed three persists one SupportingDocument kind `recibo`, `amount_cents` `15500`, `document_on` `2026-06-15`, `payee` `Padaria Central`, `fields_origin` `photo`, no chave, no XML, `302` to `/supporting_documents`, and that page includes `R$ 155,00`, `15/06/2026`, `Padaria Central` (AC 12)
Proof: `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST Padaria recibo PDF persists photo origin 15500"`

**C13** - GET edit of that document: Valor/Data/Favorecido not disabled, origin under each `Lido da foto`; later PATCH payee `Mercado Silva` responds `302` and persists that payee (AC 13)
Proof: `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "GET edit Padaria recibo PDF origins Lido da foto then PATCH payee"`

**C14** - That POST with typed payee `Mercado Silva` and a complete PDF triple persists `payee` `Padaria Central` and `fields_origin` `photo` (AC 14)
Proof: `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST Padaria recibo PDF wins over typed payee"`

**C15** - Incomplete PDF read plus typed `100,00` / `2026-05-11` / `Padaria Central` persists `amount_cents` `10000` and `fields_origin` `typed` (AC 15)
Proof: `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST incomplete recibo PDF uses typed amount 10000"`

**C16** - Coordinator POSTs `kind=recibo` with JPEG named recibo.jpg and typed `155,00` / `2026-05-11` / `Padaria Central` persists `payee` `Padaria Central` and `fields_origin` `typed` even if `PhotoFields` would return `Mercado Silva` (AC 16)
Proof: `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST recibo JPEG ignores PhotoFields stays typed Padaria"`

**C17** - Coordinator POSTs `kind=nota_fiscal` with a DANFE PDF whose `PhotoFields` read returns the Padaria triple persists kind `nota_fiscal` and does not run `ReciboFields` as the fill source (AC 17)
Proof: `bin/rspec spec/requests/supporting_documents_recibo_pdf_spec.rb -e "POST nota_fiscal DANFE PDF does not read ReciboFields"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| parser layouts (5) | Padaria C1 · Kali C2 · amount-only Miss C3 · DANFE Miss C4 · app Miss C5 | - |
| text vs OCR (3) | `pdftotext` usable C6 · empty `pdftotext` OCR C6 · unusable `pdftotext` OCR C6 | - |
| identify callers (2) | coordinator C7 · submitter C9 | - |
| identify_batch recibo origin (1) | `Lido da foto` C8 | - |
| stay typed (2) | JPEG C10 · app PDF C11 | - |
| persist origin (2) | `photo` C12 · `typed` incomplete C15 | - |
| photo wins typed (1) | C14 | - |
| edit unlocked (1) | C13 | - |
| JPEG recibo still typed (1) | C16 | - |
| ReciboFields not NF fill (1) | C17 | - |

## Swept

- validation: C3
- failure modes: C6
- idempotency: n/a - identify persists nothing; a second POST is another document (existing duplicate rule)
- authorization: existing - identify/insert session guards; submitter identify is C9
- concurrency: n/a - no new shared write; identify_batch pool is existing
- data lifecycle: C12, C13
- dependency failure: C6
- state transitions: C7, C10, C12, C13
- observability: n/a - no logging requirement in this slice

## Handoff

- **Settled mid-build:** none
- **Dispatched:** Verifier at `a4f83aa` returned; round closed at `dbd1b41`
- **Boundary:** C1-C17 closed at `dbd1b41`
- **Abandoned:** `SupportingDocument::ReciboPdf` and `spec/requests/supporting_documents_recibo_pdf_spec.rb` so `submit` and the existing request spec stay under file_tokens
- **Walked:** Development `ReciboFields::Real` on a Padaria text PDF returns `15500` / `2026-06-15` / `Padaria Central`. Identify book, lote JSON, persist and edit are C7–C13. No capture. IDE tab cannot set `<input type=file>`.
