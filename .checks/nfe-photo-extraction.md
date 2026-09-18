# NF-e photo extraction

Sources:

- `.tasks/nfe-photo-extraction.md` - this cut: criteria 1–47, doors, sweep, surface
- https://github.com/gutors/ai-accounting-assistant/issues/51 - chave from barcode/QR on the photo; NFC-e public consulta of the QR URL; reading amount, date, and payee from the photo
- https://github.com/gutors/ai-accounting-assistant/issues/14#issuecomment-5611316484 - extraction order; typed fallback; public origin correctable, no XML, no captcha; recibo this version typed only; recibo→nota fires the pipeline; identified later only on confirm; payee is emitente
- user delegated - printed-digit chave after barcode/QR miss and before typed
- https://github.com/gutors/ai-accounting-assistant/issues/13#issuecomment-5587570133 - public chave+captcha HTML is out; identified `consChNFe` stays #38
- https://github.com/gutors/ai-accounting-assistant/issues/9#issuecomment-5545690456 - CODE-128 is modelo 55 chave; NFC-e QR is the consult URL
- `.tasks/sefaz-certificate-and-consulta.md` / `.checks/sefaz-certificate-and-consulta.md` - identified port, origins, lock, confirm `Usar dados da SEFAZ`, no unique chave
- `CONTEXT.md` - Supporting document, Chave de acesso, SEFAZ consulta, Nota fiscal, Recibo; image PDF counts as a photo
- `AGENTS.md` / `.cursor/rules/rails.mdc` - identified mTLS on the server; working files are the blob interface; do not pick a cloud vendor inside a feature
- [ADR-0004](../docs/adr/0004-sefaz-certificate-in-postgres.md) - blank wrap key skips identified and does not stop the rest of the app (C15)

No design source for the screens. Profile stays `standard`.

## Out of scope

- Typed chave and identified consulta (A1, mTLS, lock, confirm control) — already #38; this cut feeds that pipeline a photo-obtained chave
- Public chave HTML form with captcha — #14 / #13
- Reading a recibo photo, or running SEFAZ on a recibo — #14 this version
- Sending photo bytes to a third-party OCR or vision API — Decided 2
- Re-parsing XML blobs already stored by #32 — #38 criterion 31
- Changing close-for-send, matches, or suggestions beyond reading the already-stored three fields — #34 / #37
- HEIC and other types outside JPEG, PNG, WebP, PDF — existing `PHOTO_TYPE`
- NF-e issuance, organization CNPJ as a setup field, accountant login — AGENTS.md
- Persisting the QR URL after extract
- Client-side barcode decode in Stimulus
- Re-running extraction when PATCH replaces the photo — Unresolved 1 (no)

## Landing

Touches `SupportingDocument#submit` / `#apply` (chave from the photo, then identified, then public NFC-e, then field reading, then typed), three new server ports with the existing `current` / `Fake` / `Real` shape, `fields_origin` values `photo` and `nfc_e_public`, and recibo→nota reading the already-attached photo. Reuses identified consulta, lock, confirm `Usar dados da SEFAZ`, and the supporting-documents HTML surface. Controller stays pass-through.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Public and photo origins are persisted; lock is still derived | `fields_origin` values `photo` and `nfc_e_public`. `fields_locked?` stays true only for `uploaded_xml` and `identified`. PATCH of the three succeeds on `photo` and `nfc_e_public`. Nil origin remains typed-equivalent (#38-31). | Reuse `typed` for both — #38 door 2 already named photo and NFC-e-public as distinct correctable origins; confirm still needs them not to be `identified`. Lock whenever a chave exists — would lock typed and public rows #14 says any operator may correct. |
| Photo capture and public consulta are server ports; photo bytes stay in-process; public GET is allowlisted | Three ports with test fakes and no network in submit specs, same `current`/`Fake`/`Real` shape as `SefazConsulta`: (a) symbols from the photo (QR URL and/or 44-digit chave from QR, CODE-128, or printed digits), (b) amount/date/payee from the photo, (c) public consulta given a URL → the three fields, miss, or error. Production `build` is in-process Real. Photo bytes are not sent to a third-party OCR or vision API. Public HTTP GET runs only when the URL host is an NFC-e consumer portal published for the QR (NT 2015/002 and updates); `127.0.0.1` and `example.com` are not fetched. Real CODE-128 and QR decoders are proven from fixture PNGs (C12, C13). Consumer URLs are produção pages of authorized notes. | Browser zxing before POST — image PDF would not decode; submitter insert must match coordinator; rails.mdc keeps SEFAZ work on the server. Cloud Vision / Textract — AGENTS.md does not pick a cloud vendor inside a feature; photos are working files with financial data; #38 already fakes the external consult. Fetch any QR URL — a photo-supplied URL is attacker-controlled (SSRF). Public chave+captcha HTML — #14. Homologação consumer pages — coordinators consult authorized production notes. |
| Extraction order is #14, with all-three-or-miss at public and photo-reading | On nota fiscal without a readable uploaded XML: obtain chave from QR, else CODE-128, else printed digits, else typed; then identified if the A1 can run; then public consulta only if an NFC-e QR URL decoded and identified did not deliver; then field reading; then typed. A step that cannot yield all three of amount, date, and payee is a miss. Unreadable uploaded XML is `422` and does not fall through (C33). QR wins over CODE-128 when both decode (QR is the public URL). Photo-obtained 44-digit chave is a chave for identified (C1), not a separate path that skips #38. | Typed chave wins over a decoded chave — #14 obtains the chave from the photo first. Partial public/OCR fill mixed with typed — would split origin across columns. Using the QR payload `vNF` without HTML — #9 offline QR can carry `vNF` but not emitente name; #14 fills from the consumer page. |

- Nothing else in this change is hard to reverse. Route names, which gem decodes CODE-128, and the HTML selectors of one UF consumer page are placement. Door 1 reaches past this feature: suggestions keep reading the three columns; they must not treat `photo` or `nfc_e_public` as locked. Door 2 reaches past this feature: a later fetch of a user-supplied URL copies the consumer-portal allowlist, not “GET whatever the file contains”; a later read of a working-file image copies in-process ports with fakes, not a cloud vision vendor. Door 3 reaches past this feature: identified still runs before public; public still does not store XML.

Unresolved 1 stays open (none block): PATCH of a new photo stores the file and does not change amount, date, payee, or chave by itself.

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
- `spec/models/supporting_document_spec.rb` + `spec/requests/supporting_documents_spec.rb` — insert/apply/422 copy is the pipeline this cut extends
- `spec/models/sefaz_consulta_spec.rb` — Real decoder/parser proven at its own layer from fixtures, not from HTTP (C12, C13 copy that shape)
- SupportingDocumentsController stays pass-through once SupportingDocument decides; HTTP status / who may call still need request specs

Cost: model specs for photo-chave order, public and field-reading origins, kind pipeline, confirm from those origins; request specs for every status/route claim below; Real CODE-128 and QR at the symbols port.

## Checks

### S1 - Chave from the photo · 11 files · 124 KB · ~31k

**C1** - Given a `.jpg` photo whose barcode/QR decode returns chave `43260511222333000181550010000000011123456781`, the focused organization has a valid A1, and identified consulta for that chave returns authorized XML with `vNF` `155.00`, emitente `Padaria Central`, `dhEmi` `2026-05-11T10:00:00-03:00`, when a coordinator POSTs `kind=nota_fiscal`, that photo, and no typed chave, amount, date, payee, or XML, then the system persists `amount_cents` `15500`, `document_on` `2026-05-11`, `payee` `Padaria Central`, chave that value, attaches that XML, responds `302` to `/supporting_documents`, and that page includes `R$ 155,00`, `11/05/2026`, `Padaria Central`, and that chave
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST photo chave with consulta XML fills fields and redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert photo chave with consulta XML persists 15500 and attaches xml"`

**C2** - When a submitter POSTs that same insert, then the system persists the same fields and XML, `GET /supporting_documents` is `200` and includes `R$ 155,00`, and that page does not include `11.222.333/0001-81`, `Válido até`, or `passphrase-secreta`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter POST photo chave with consulta XML persists and omits certificate"`

**C3** - When that photo is a `.pdf` whose decode returns the same chave and identified consulta returns that XML, then the system persists those fields, that chave, and the XML, and responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST pdf photo chave with consulta XML redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert pdf photo chave with consulta XML persists chave and xml"`

**C4** - Given barcode/QR decode misses and chave-digit reading of the photo returns `43260511222333000181550010000000011123456781`, with a valid A1 and that identified XML, when a coordinator POSTs the photo and no typed chave, then the system persists that chave, `amount_cents` `15500`, and the XML
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST printed-digit chave with consulta XML persists chave"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert printed-digit chave with consulta XML persists 15500"`

**C5** - Given barcode/QR decode returns chave `43260511222333000181550010000000011123456781` and the POST also has typed chave `43260511222333000181550010000000021987654321`, with identified XML for the first chave, then the system persists chave `43260511222333000181550010000000011123456781` and `amount_cents` `15500`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST photo chave wins over typed chave"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert photo chave wins over typed chave"`

**C6** - Given barcode/QR decode returns a value that is not 44 digits after stripping non-digits, chave-digit reading misses, and the POST has typed chave `43260511222333000181550010000000011123456781` with a valid A1 and that identified XML, then the system persists that typed chave and the XML
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST non-44 photo decode falls through to typed chave"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert non-44 photo decode uses typed chave"`

**C7** - When a coordinator POSTs `kind=recibo` with a photo whose decode would return that chave, and typed `155,00` / `2026-05-11` / `Padaria Central`, then the system persists kind recibo, stores no chave, attaches no XML, and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo ignores photo chave and PATCH payee redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert recibo ignores photo chave"`

**C8** - When a coordinator POSTs authorized XML of `vNF` `155.00` chave `43260511222333000181550010000000011123456781` together with a photo whose decode returns chave `43260511222333000181550010000000021987654321`, then the system persists `amount_cents` `15500` and chave `43260511222333000181550010000000011123456781`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST uploaded XML chave wins over photo chave"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert uploaded XML chave wins over photo chave"`

**C9** - When the organization has no certificate and a coordinator POSTs a photo whose decode returns that chave, plus typed `155,00` / `2026-05-11` / `Padaria Central`, then the system persists that chave and `amount_cents` `15500`, and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST photo chave without certificate stays correctable"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert photo chave without certificate stays typed-correctable"`

**C10** - If identified consulta errors or times out and that POST has the photo-obtained chave and those typed fields, then the system persists the typed fields and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST photo chave when consulta errors stays typed"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert photo chave when consulta errors stays typed"`

**C11** - Given identified consulta returns only a resumo (`vNF` `155.00`, emitente `Padaria Central`, `dhEmi` `2026-05-11`) for the photo-obtained chave, when a coordinator POSTs the photo and no typed fields, then the system persists those three fields, the photo remains, XML is not attached, and a PATCH of amount responds `422` with `Valor, data e favorecido vêm da nota e não podem ser alterados`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST photo chave with resumo locks fields without xml"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert photo chave with resumo locks amount"`

**C12** - When the production CODE-128 decoder is given a PNG of a CODE-128 that encodes `43260511222333000181550010000000011123456781`, then it returns that chave
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real CODE-128 PNG returns chave 43260511222333000181550010000000011123456781"`

**C13** - When the production QR decoder is given a PNG of a QR whose payload is `https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=43260511222333000181650010000000011123456781|2|1|1`, then it returns chave `43260511222333000181650010000000011123456781` and that URL
Proof: `bin/rspec spec/models/photo_symbols_spec.rb -e "Real QR PNG returns NFC-e chave and sefaz.rs.gov.br URL"`

### S2 - Public NFC-e consulta · 8 files · 72 KB · ~18k

**C14** - Given the organization has no certificate, a photo whose QR decode returns URL `https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=43260511222333000181650010000000011123456781|2|1|1` and chave `43260511222333000181650010000000011123456781`, and public consulta of that URL returns `vNF` `155.00`, emitente `Padaria Central`, date `2026-05-11`, when a coordinator POSTs `kind=nota_fiscal`, that photo, and no typed amount, date, or payee, then the system persists `amount_cents` `15500`, `document_on` `2026-05-11`, `payee` `Padaria Central`, that chave, attaches no XML, responds `302` to `/supporting_documents`, that page includes `R$ 155,00`, `11/05/2026`, `Padaria Central`, and that chave, and a later PATCH of amount `200,00` responds `302` and persists `amount_cents` `20000`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST NFC-e QR public consulta fills fields and PATCH amount redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFC-e QR public consulta persists 15500 origin nfc_e_public"`

**C15** - While the wrapping-key process environment is blank, when that same public QR insert runs, then the system persists `amount_cents` `15500` and a later PATCH of amount `200,00` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST NFC-e QR public consulta with blank wrap key PATCH amount redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFC-e QR public consulta with blank wrap key stays correctable"`

**C16** - While the installed certificate is expired, when that same public QR insert runs, then the system persists `amount_cents` `15500` and a later PATCH of amount `200,00` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST NFC-e QR public consulta with expired certificate PATCH amount redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFC-e QR public consulta with expired certificate stays correctable"`

**C17** - If identified consulta errors or times out and that QR photo is posted with no typed fields, and public consulta returns those three values, then the system persists `amount_cents` `15500` and a later PATCH of amount `200,00` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST NFC-e QR public consulta when identified errors PATCH amount redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFC-e QR public consulta when identified errors stays correctable"`

**C18** - If identified consulta returns not found or window-expired and that QR photo is posted with no typed fields, and public consulta returns those three values, then the system persists `amount_cents` `15500` and a later PATCH of amount `200,00` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST NFC-e QR public consulta when identified not found PATCH amount redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFC-e QR public consulta when identified not found stays correctable"`

**C19** - Given identified consulta returns authorized XML of `vNF` `155.00` for that NFC-e chave and the photo also has that QR URL, when a coordinator POSTs the photo and no typed fields, then the system persists `amount_cents` `15500`, attaches XML, and a PATCH of amount responds `422` with `Valor, data e favorecido vêm da nota e não podem ser alterados`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST NFC-e QR identified XML wins over public consulta"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFC-e QR identified XML locks and skips public"`

**C20** - Given a photo whose decode returns only CODE-128 chave `43260511222333000181550010000000011123456781` (no QR URL), no certificate, typed `155,00` / `2026-05-11` / `Padaria Central`, and public consulta would return payee `Mercado Silva` for any URL, then the system persists `payee` `Padaria Central`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST CODE-128 without QR URL does not call public consulta"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert CODE-128 without QR URL keeps typed payee"`

**C21** - If the QR URL is `http://127.0.0.1/nfce`, field reading misses, and the POST has typed `155,00` / `2026-05-11` / `Padaria Central`, then the system persists `payee` `Padaria Central` and attaches no XML
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST QR 127.0.0.1 does not fetch and keeps typed payee"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert QR 127.0.0.1 keeps typed payee and no xml"`

**C22** - If the QR URL is `https://example.com/nfce`, field reading misses, and the POST has those typed fields, then the system persists `payee` `Padaria Central` and attaches no XML
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST QR example.com does not fetch and keeps typed payee"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert QR example.com keeps typed payee and no xml"`

**C23** - If public consulta errors or times out, field reading misses, and the POST has those typed fields, then the system persists `payee` `Padaria Central`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST NFC-e QR when public consulta errors keeps typed payee"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFC-e QR when public consulta errors keeps typed payee"`

**C24** - If public consulta returns only `vNF` `155.00` and not date or payee, field reading misses, and the POST has those typed fields, then the system persists `payee` `Padaria Central`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST NFC-e QR public partial three keeps typed payee"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFC-e QR public partial three keeps typed payee"`

**C25** - When public consulta returns emitente `Padaria Central` and destinatário `ONG Destinataria`, then the system persists `payee` `Padaria Central` and does not persist `ONG Destinataria`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST NFC-e QR public consulta payee is emitente not destinatario"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFC-e QR public consulta payee is emitente"`

### S3 - Reading amount, date, and payee from the photo · 7 files · 56 KB · ~14k

**C26** - Given barcode/QR and chave-digit reading miss, no certificate, and field reading of the photo returns `amount_cents` `15500`, `document_on` `2026-05-11`, payee `Padaria Central` (emitente; the photo also shows destinatário `ONG Destinataria`), when a coordinator POSTs `kind=nota_fiscal`, that photo, and no typed amount, date, or payee, then the system persists those three values, responds `302`, that page includes `R$ 155,00` and `Padaria Central` and does not include `ONG Destinataria`, and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST photo field reading fills emitente and PATCH payee redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert photo field reading persists 15500 origin photo"`

**C27** - If identified consulta errors or times out for a CODE-128 chave from the photo, there is no QR URL, and field reading returns those three values with no typed fields, then the system persists `amount_cents` `15500` and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST CODE-128 when identified errors uses field reading"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert CODE-128 when identified errors uses field reading"`

**C28** - If public consulta errors or times out for an NFC-e QR photo and field reading returns those three values with no typed fields, then the system persists `amount_cents` `15500` and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST NFC-e QR when public errors uses field reading"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFC-e QR when public errors uses field reading"`

**C29** - If field reading returns only `amount_cents` `15500` and the POST has typed `100,00` / `2026-05-11` / `Padaria Central`, then the system persists `amount_cents` `10000` and `payee` `Padaria Central`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST photo field reading partial three uses typed amount"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert photo field reading partial three uses typed"`

**C30** - If field reading misses and the POST has a nota fiscal photo and no typed amount, date, or payee, then the system persists no SupportingDocument and responds `422` with `Informe valor, data e favorecido`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota photo with all extracts missing returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert nota photo with all extracts missing persists none"`

**C31** - When a coordinator POSTs `kind=recibo` with a photo whose field reading would return payee `Mercado Silva`, and typed `155,00` / `2026-05-11` / `Padaria Central`, then the system persists `payee` `Padaria Central`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo ignores photo field reading"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert recibo ignores photo field reading"`

**C32** - Given field reading returns payee `Padaria Central` and the POST also has typed payee `Mercado Silva` (and typed amount `155,00`, date `2026-05-11`), with no chave path, then the system persists `payee` `Padaria Central`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST photo field reading wins over typed payee"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert photo field reading wins over typed payee"`

**C33** - If a coordinator POSTs a file that is not well-formed XML together with a photo whose field reading would return those three values, then the system persists no SupportingDocument and responds `422` with `O XML da nota fiscal não pôde ser lido`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST unreadable XML does not fall through to photo field reading"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert unreadable XML does not use photo field reading"`

### S4 - Relançamento, confirm, and fallbacks · 6 files · 64 KB · ~16k

**C34** - Given a SupportingDocument filled from photo field reading (`amount_cents` `15500`, payee `Padaria Central`) and a valid A1 whose consulta for chave `43260511222333000181550010000000011123456781` returns `vNF` `100.00`, when a coordinator PATCHes that chave, then `amount_cents` stays `15500`, the response is `302`, and `/supporting_documents` includes `Usar dados da SEFAZ`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH chave on photo-filled nota keeps 15500 and includes Usar dados da SEFAZ"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply chave on photo-filled nota keeps 15500 pending confirm"`

**C35** - When a coordinator confirms identified SEFAZ on that document, then the system persists `amount_cents` `10000`, a later PATCH of amount responds `422` with `Valor, data e favorecido vêm da nota e não podem ser alterados`, the response is `302` to `/supporting_documents`, and that page includes `R$ 100,00` and does not include `R$ 155,00`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "confirm identified SEFAZ on photo-filled nota persists 10000"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "confirm identified SEFAZ on photo-filled nota locks 10000"`

**C36** - Given a SupportingDocument filled from public NFC-e consulta (`amount_cents` `15500`) and that same valid A1, when a coordinator PATCHes that chave, then `amount_cents` stays `15500`, the response is `302`, and the page includes `Usar dados da SEFAZ`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH chave on public-filled nota keeps 15500 and includes Usar dados da SEFAZ"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply chave on public-filled nota keeps 15500 pending confirm"`

**C37** - When a coordinator confirms identified SEFAZ on that public-filled document, then the system persists `amount_cents` `10000` and a later PATCH of amount responds `422` with `Valor, data e favorecido vêm da nota e não podem ser alterados`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "confirm identified SEFAZ on public-filled nota persists 10000"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "confirm identified SEFAZ on public-filled nota locks 10000"`

**C38** - When a coordinator PATCHes `kind=nota_fiscal` on a recibo that already has a photo whose decode returns chave `43260511222333000181550010000000011123456781`, while the organization has a valid A1 and consulta returns full XML of `vNF` `100.00` emitente `Mercado Silva` `dhEmi` `2026-05-12`, then the system persists `amount_cents` `10000`, `payee` `Mercado Silva`, `document_on` `2026-05-12`, attaches that XML, and a later PATCH of amount responds `422`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH kind nota_fiscal on recibo reads existing photo chave"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply kind nota_fiscal on recibo reads existing photo chave"`

**C39** - When a coordinator PATCHes `kind=recibo` together with the existing photo on a photo-filled nota fiscal that has a chave, then the SupportingDocument is recibo, has no chave, keeps amount, date, and payee, and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH kind recibo on photo-filled nota drops chave and unlocks"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply kind recibo on photo-filled nota drops chave"`

**C40** - When a coordinator installs a valid A1 after a photo-filled nota fiscal already exists with a chave, then that document’s amount stays as stored and a PATCH of payee `Mercado Silva` still responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "install A1 after photo-filled chave does not retro-consult"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "install A1 after photo-filled chave leaves amount"`

**C41** - If a coordinator PATCHes chave while Month `2026-05` is closed and that photo-filled document belongs to it, then the chave is unchanged and the response is `422` with `Mês fechado`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH chave on closed-month photo-filled document returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply chave on closed-month photo-filled document is rejected"`

**C42** - If an unauthenticated request POSTs a nota fiscal photo whose decode would fill fields, then the system persists no SupportingDocument and responds `302` to `/login`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated POST nota photo responds 302 to /login"`

**C43** - If a submitter PATCHes chave on a photo-filled SupportingDocument of another Account, then the system persists no change and the response is `404`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter PATCH chave on another Account photo-filled document returns 404"`

**C44** - When two POSTs insert nota fiscal photos whose decode returns the same 44-digit chave, then the system persists two SupportingDocuments
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST duplicate photo chave persists two SupportingDocuments"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert duplicate photo chave persists two"`

**C45** - Always, amount from public consulta or field reading is integer cents (`15500` for `155.00`), never a `Float` domain amount
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "amount from public consulta 155.00 is Integer 15500"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "amount from photo field reading 155.00 is Integer 15500"`

**C46** - When a coordinator POSTs a nota fiscal photo, no typed three fields, barcode/QR miss, chave-digit miss, field reading miss, then the response is `422` with `Informe valor, data e favorecido` and the include form still has fields `amount`, `date`, `payee`, `chave`, and `photo`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota photo all extracts missing keeps include form fields"`

**C47** - If that confirm in 35 runs while identified consulta errors, then the system persists no change to amount, the three fields stay editable, and the response is `422` with `Não foi possível consultar a SEFAZ`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "confirm identified SEFAZ on photo-filled nota when consulta errors returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "confirm identified SEFAZ on photo-filled nota when consulta errors keeps 15500 editable"`

## Swept

- validation: C6, C24, C29, C30, C33 - non-44 photo decode is a miss not `422`; public or field reading that lacks all three is a miss; unreadable XML still `422` and does not fall through
- failure modes: C10, C15, C21, C23, C30, C47 - identified miss, blank wrap key, SSRF URL, public error, and field miss fall through or `422`; confirm does not lock on error
- idempotency and retry: C35, C44 - a second confirm is existing #38-58 behaviour on the locked row; a retried POST creates a second document (no unique chave)
- authorization: C2, C42, C43
- concurrency and ordering: n/a - no one-slot resource on the document; two in-flight inserts do not share writable state beyond creating two rows (C44)
- data lifecycle: C39, C40 - nota→recibo drops chave and unlocks as typed; a later A1 does not re-read stored photos
- external-dependency failure: C10, C17, C18, C23, C28 - identified error/timeout/not found/window-expired and public error/timeout fall through to the next step
- state transitions: C1, C11, C14, C19, C26, C34, C35, C38, C39
- observability: existing - `filter_parameters` already covers certificate/passphrase; no new operator metric; photo bytes are not a log field this task adds

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| chave source (4) | QR/CODE-128 C1 · printed digits C4 · typed after non-44 decode C6 · photo wins typed C5 | - |
| recibo ignores photo (2) | decode C7 · field reading C31 | - |
| uploaded XML vs photo chave (1) | XML chave wins C8 | - |
| identified from photo chave (4) | full XML C1 · resumo lock C11 · error/timeout with typed C10 · no certificate C9 | - |
| Real symbol decoders (2) | CODE-128 C12 · QR C13 | - |
| public NFC-e when identified cannot deliver (6) | no cert C14 · blank wrap C15 · expired A1 C16 · identified error C17 · not found/window-expired C18 · identified XML skips public C19 | - |
| public not used or miss (5) | CODE-128 no URL C20 · `127.0.0.1` C21 · `example.com` C22 · error/timeout C23 · partial three C24 | - |
| payee is emitente (2) | public C25 · photo C26 | - |
| field reading (6) | all three C26 · after identified error C27 · after public error C28 · partial uses typed C29 · all miss `422` C30 · wins typed C32 | - |
| unreadable XML vs photo (1) | no fall through C33 | - |
| confirm from correctable origins (5) | photo PATCH chave C34 · photo confirm C35 · public PATCH chave C36 · public confirm C37 · photo confirm errors C47 | - |
| kind pipeline (2) | recibo→nota reads photo C38 · nota→recibo drops chave C39 | - |
| later A1 / closed month (2) | no retro C40 · closed PATCH chave C41 | - |
| who may POST photo extract (2) | coordinator C1 · unauthenticated C42 | - |
| who may PATCH chave on photo-filled (2) | coordinator C34 · submitter other Account C43 | - |
| duplicate chave (1) | two rows C44 | - |
| integer cents (2) | public `155.00` C45 · photo `155.00` C45 | - |
| include form on `422` (1) | amount/date/payee/chave/photo C46 | - |
| `fields_origin` new members (2) | `nfc_e_public` C14 · `photo` C26 | - |
| startup config assemblies | each port’s `current`/`Fake`/`Real` lives in one module; test `reset!` and production `build` share it (same as `SefazConsulta`) | - |

- Claims naming a status code, route or response shape: C1–C11, C14–C44, C46, C47 - each has a request-spec proof that crosses the boundary except C12, C13, C45 (model-only Real decoders and Integer cents)
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~31k + S2 ~18k + S3 ~14k + S4 ~16k = ~79k tokens floor. All four slices stay under 150k. Surface changes at S2 (outbound public GET) but the running total never reaches the budget, so no split.
