# NF-e photo OCR (printed chave and fields)

Sources:

- `.tasks/nfe-photo-ocr.md` - this cut: criteria 1–9, Tesseract door, sweep, surface
- https://github.com/gutors/ai-accounting-assistant/issues/56 - printed 44-digit chave after QR/CODE-128 miss; amount, date, emitente after identified and public miss; origin `photo`; C12/C13-shaped Real proofs; no cloud OCR
- `.checks/nfe-photo-extraction.md` Landing door 5 - printed-digit and `PhotoFields::Real` miss, superseded here
- `CONTEXT.md` - Supporting document, Chave de acesso, Nota fiscal, Recibo
- `AGENTS.md` / `.cursor/rules/rails.mdc` - no cloud vendor; integer cents; Real proven at its own layer from fixtures
- `app/models/photo_symbols.rb` / `app/models/photo_fields.rb` - production `build` is already Real; test `reset!` is Fake

No design source for the screens. Profile stays `standard` (AGENTS.md tlc-spec-lean floor; this cut has no binding screen).

## Out of scope

- Reading a recibo photo — #14 this version; #51 C7 / C31
- Sending photo bytes to a third-party OCR or vision API — #51 Decided 2; issue #56
- Replacing C4 / C26 Fake submit specs with Real — issue #56 asks C12/C13-shaped Real proofs
- Typed chave, identified consulta, public NFC-e GET, lock, confirm — already #38 / #51
- PDF or WebP Real decode — `PhotoSymbols::Real#load_image` already returns no image for those
- HEIC and types outside JPEG, PNG, WebP, PDF — existing `PHOTO_TYPE`
- Re-running extraction when PATCH replaces the photo — #51 Unresolved 1 (no)
- Backfilling existing photos — #51 C40
- Real DANFE photos or other financial data in the repo — `AGENTS.md`

## Landing

Touches `PhotoSymbols::Real` (printed digits after QR then CODE-128 miss) and `PhotoFields::Real` (amount, date, emitente). Reuses the existing `current` / `Fake` / `Real` ports and the #51 submit pipeline. Submit specs stay Fake.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Production Real for printed digits and fields is Tesseract in the app container and CI | `PhotoSymbols::Real` (after QR then CODE-128 miss) and `PhotoFields::Real` run Tesseract on PNG/JPEG bytes inside the Rails process host. Runtime `Dockerfile` stage (the final image inherits `base`, not only `build`) and the CI `test` job install `tesseract-ocr` and `tesseract-ocr-por`. Photo bytes are not sent to a third-party OCR or vision API. This supersedes #51 Landing door 5. | Cloud Vision / Textract — `AGENTS.md` does not pick a cloud vendor inside a feature; photos are working files with financial data; #51 Decided 2. Pure-Ruby OCR with no native lib — cannot read DANFE emitente/amount/date for C4–C5. Leave Real as miss — that is the production hole #56 names. Ship Tesseract only in CI and not in the runtime image — proofs would pass and production would still `Miss`. |
| Tesseract is the `tesseract` CLI via Open3 on a PNG/JPEG tempfile | `PhotoOcr` runs `tesseract <file> stdout -l por+eng --psm 6`. Missing binary (`ENOENT`) or non-zero exit is empty text, which Real maps to chave nil / `Miss`. Language `por+eng` so the `tesseract-ocr-por` package is the one that feeds C4. | `rtesseract` gem — extra dependency wrapping the same CLI. FFI / `tesseract-ocr` gem — needs libtesseract headers in the slim image beyond the runtime packages already named. `eng` only — ASCII fixtures would pass without `tesseract-ocr-por`, and production DANFE copy is Portuguese. |

- Nothing else in this change is hard to reverse. How the spec rasterizes the proof PNG/JPEG, and CLI vs FFI vs wrapper gem, are placement. Door 1 reaches past this feature: a later read of a working-file image that needs OCR copies Tesseract in the container plus in-process ports with fakes, not a cloud vision vendor.

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions):

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at the model layer **and** one request spec at HTTP | one asserted case per enumerated member at the model; status / who may call at the boundary | follow |
| Decides, not reached across a boundary | one at the model layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` lines 49–51 name the level and the sampling rule (one asserted case per enumerated member; HTTP also a request spec)
- `spec/models/photo_symbols_spec.rb` C12 / C13 — Real decoder proven at its own layer from generated PNGs, not from HTTP; this cut copies that shape
- `spec/config/application_spec.rb` — production wiring asserted by reading Dockerfile / workflow / Gemfile, not HTTP
- SupportingDocumentsController stays pass-through; this cut does not add HTTP claims

Cost: model specs for Real printed-digit and field-reading PNG/JPEG, miss, partial, and Tesseract failure; file assertions for the two host-package assemblies.

## Checks

### S1 - Printed 44-digit chave after QR and CODE-128 miss · 4 files · 24 KB · ~6k

**C1** - Given a PNG with no QR and no CODE-128 whose pixels render the printed digits `43260511222333000181550010000000011123456781`, when `PhotoSymbols::Real#scan` is given those bytes, then it returns `chave` that value and `qr_url` `nil`
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real printed-digit PNG returns chave 43260511222333000181550010000000011123456781"`

**C2** - When that same layout is a JPEG, then `PhotoSymbols::Real#scan` returns `chave` `43260511222333000181550010000000011123456781` and `qr_url` `nil`
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real printed-digit JPEG returns chave 43260511222333000181550010000000011123456781"`

**C3** - If a PNG has no QR, no CODE-128, and no 44-digit sequence, then `PhotoSymbols::Real#scan` returns `chave` `nil`
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real printed-digit PNG without 44 digits returns chave nil"`

### S2 - Amount, date, and emitente from the photo · 6 files · 28 KB · ~7k

**C4** - Given a PNG with no QR and no CODE-128 whose pixels render emitente `Padaria Central`, destinatário `ONG Destinataria`, amount `R$ 155,00`, and date `11/05/2026`, when `PhotoFields::Real#read` is given those bytes, then it returns `amount_cents` `15500`, `document_on` `2026-05-11`, and `payee` `Padaria Central`
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real PNG returns 15500 2026-05-11 Padaria Central"`

**C5** - When that same layout is a JPEG, then `PhotoFields::Real#read` returns those same three values
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real JPEG returns 15500 2026-05-11 Padaria Central"`

**C6** - Always, `amount_cents` from that read is Integer `15500`, never a `Float`
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real amount_cents 15500 is Integer"`

**C7** - If a PNG has none of those amount, date, and emitente strings, then `PhotoFields::Real#read` returns `Miss`
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real PNG without amount date emitente returns Miss"`

**C8** - If a PNG has `R$ 155,00` and neither a date nor an emitente name, then `PhotoFields::Real#read` does not return a complete triple (`Miss`, or `Fields` with `document_on` `nil` or `payee` `nil`)
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real PNG with only amount is not a complete triple"`

**C9** - If the Tesseract host binary is missing or the OCR subprocess errors, then `PhotoSymbols::Real#scan` returns `chave` `nil` and `PhotoFields::Real#read` returns `Miss`
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real scan misses when tesseract binary is missing"`
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real read misses when tesseract binary is missing"`
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real scan misses when tesseract subprocess errors"`
Proof: `bin/rspec spec/models/photo_fields_spec.rb -e "Real read misses when tesseract subprocess errors"`

**C10** - Always, the production Dockerfile runtime image (the `base` stage the final `FROM base` inherits, not only `build`) installs `tesseract-ocr` and `tesseract-ocr-por`
Proof: `bin/rspec spec/config/application_spec.rb -e "production runtime image installs tesseract-ocr and tesseract-ocr-por"`

**C11** - Always, the CI `test` job installs `tesseract-ocr` and `tesseract-ocr-por` before `bin/rspec`
Proof: `bin/rspec spec/config/application_spec.rb -e "CI test job installs tesseract-ocr and tesseract-ocr-por before rspec"`

## Swept

- validation: C3, C8 - a photo with no 44-digit sequence is a chave miss, not `422` at the port; a photo that lacks date or emitente is not a complete triple
- failure modes: C7, C9 - blank/unreadable field image is `Miss`; missing or failing Tesseract is `Miss`, not a raised error into submit
- idempotency and retry: n/a - the ports do not persist; a second scan of the same bytes is another read with no write
- authorization: existing - `POST /supporting_documents` still requires focused Access (#51 C42); the ports are not an inbound API
- concurrency and ordering: n/a - no one-slot resource; two scans do not share writable state
- data lifecycle: n/a - nothing stored by this task; existing photos are not re-read (#51 C40)
- external-dependency failure: C9 - Tesseract missing or subprocess error is `Miss`, then the #51 pipeline (typed or `422`)
- state transitions: n/a - `fields_origin` `photo`, lock, and confirm stay #51; this cut only makes production Real able to reach that origin
- observability: existing - `filter_parameters` already covers certificate/passphrase; photo bytes are not a log field; no new operator metric

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| printed-chave image type (2) | PNG C1 · JPEG C2 | - |
| printed-chave miss (1) | no 44-digit sequence C3 | - |
| field-reading image type (2) | PNG C4 · JPEG C5 | - |
| amount type (1) | Integer `15500` C6 | - |
| field-reading miss / partial (2) | none of the three C7 · amount only C8 | - |
| Tesseract failure (2 modes × 2 ports) | missing symbols C9 · missing fields C9 · subprocess symbols C9 · subprocess fields C9 | - |
| Tesseract host packages (2 assemblies) | Dockerfile `base` / runtime C10 · CI `test` job C11 | - |
| startup config assemblies | each port’s `current`/`Fake`/`Real` lives in one module; test `reset!` and production `build` share it (same as `SefazConsulta`) | - |

- Claims naming a status code, route or response shape: none - C1–C11 are model / file assertions
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~6k + S2 ~7k = ~13k tokens floor. Both slices stay under 150k and share `PhotoOcr` / the host binary, so no split. One agent, one batch.
