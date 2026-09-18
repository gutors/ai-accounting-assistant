# SEFAZ certificate and identified consulta

Sources:

- `.tasks/sefaz-certificate-and-consulta.md` - this cut: criteria 1–69, doors, sweep, surface
- https://github.com/gutors/ai-accounting-assistant/issues/38 - A1 e-CNPJ one slot; identified consulta; extração da foto delegated to #51
- https://github.com/gutors/ai-accounting-assistant/issues/27#issuecomment-5650004568 - one optional A1 `.pfx`/`.p12` + passphrase; coordinator install/replace/remove; submitter does not see the slot; expired/removed skips new consulta; does not block close-for-send
- https://github.com/gutors/ai-accounting-assistant/issues/14#issuecomment-5611316484 - XML is truth; typed is fallback; payee is emitente; identified later overwrites correctable fields only on confirm; recibo→nota fires the pipeline
- https://github.com/gutors/ai-accounting-assistant/issues/13#issuecomment-5587570133 - identified `NFeDistribuicaoDFe consChNFe`; public chave HTML form is out
- https://github.com/gutors/ai-accounting-assistant/issues/9#issuecomment-5545690456 - matching keys in authorized XML: chave, emitente xNome, dhEmi, ICMSTot/vNF
- https://github.com/gutors/ai-accounting-assistant/issues/51 - photo extraction out of this cut
- `CONTEXT.md` - SEFAZ certificate, SEFAZ consulta, Chave de acesso, Supporting document, Observation, Nota fiscal, Recibo
- `AGENTS.md` - A1 ciphertext in Postgres; wrapping key in process environment; identified consulta mTLS on the server
- [ADR-0001](../docs/adr/0001-rails-8-hotwire.md) - Rails 8 + Hotwire; certificate is not a working file
- `.specs/features/supporting-document-insert/plan.md` - typed path this task supersedes for XML; AC 19 typed-wins is inverted by C24
- `.tasks/submitter-access.md` - submitter `/setup` 404; submitter insert; own no-month PATCH
- user delegated - setup copy (`Certificado SEFAZ`, `Nenhum certificado`, `Válido até`, `Expirado em`, `Remover`, Turbo confirm `Remover o certificado SEFAZ?`); PKCS#12 at most `1048576` bytes; real consulta uses SEFAZ produção; A1 optional

No design source for the screens. Profile stays `standard`.

## Out of scope

- Chave from barcode/QR on the photo, NFC-e consumer consulta of the QR URL, and reading amount/date/payee from the photo — #51
- Matching the titular CNPJ to an organization tax id — #27 this version has no organization tax id
- A3 tokens, e-CPF as this certificate, accountant login, NF-e issuance, public chave HTML form (captcha) — #27 / #14
- Open Finance, Drive writes, wrapping-key rotation, storing the PKCS#12 in Active Storage or the object store
- Re-parsing XML blobs already stored by #32 — C31; origin stays typed until a new upload or consulta
- Changing close-for-send, matches, or suggestions beyond reading the already-stored three fields — #34 / #37
- Destroy rules for SupportingDocument — existing #35

## Landing

Touches Organization (one-slot A1 ciphertext), `/setup`, a new certificate HTML surface, SupportingDocument submit/apply (field origin, chave, authorized XML parse), identified consulta as a server port with a test fake, and close-for-send only as a reader of already-stored fields. Reuses `require_coordinator_organization`, `SupportingDocument#submit`, accountant 422-rerender of `setup/show`, and `filter_parameters` (`:passw`, `:certificate`).

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| One A1 slot on the organization, ciphertext in Postgres | Standing fields on `Organization` (one PKCS#12 + passphrase as ciphertext, titular CNPJ digits, notAfter date). Wrapping key from the process environment. Install/replace is upsert of that slot; remove nulls it. Never Active Storage, never Drive, never returned after install (`GET /sefaz_certificate` is `404`). Leaf titular 14-digit CNPJ accepted; 11-digit CPF refused; already-expired leaf refused. | `has_one :sefaz_certificate` row — #27 is one slot on the org, same as accountant fields. Active Storage / object store — AGENTS.md encrypts in Postgres; the file must not be downloadable; container disk is ephemeral. Rails credentials as the wrap key — AGENTS.md says process environment. Matching titular CNPJ to an organization tax id — #27 this version has none. |
| Field origin is persisted; lock is derived | `SupportingDocument` records where amount, date, and payee came from. PATCH of those three is refused when origin is uploaded authorized XML or identified consulta (resumo or full XML). Observation stays mutable. Recibo and typed/photo/NFC-e-public origins stay editable. Existing rows with an XML blob and no origin are typed (C31). | Boolean `locked` — cannot tell typed from identified for the later-confirm rule (#14). Lock whenever `xml` is attached — would lock #32 rows whose typed `15500` disagrees with `vNF`, and cannot lock resumo-only identified (C38). |
| Authorized XML paths are the matching keys | Amount from `infNFe/total/ICMSTot/vNF` as integer cents; payee from `infNFe/emit/xNome` (never destinatário); `document_on` from the calendar date in `infNFe/ide/dhEmi` as written (not converted through UTC); chave from `infNFe/@Id` without the `NFe` prefix when present. Uploaded XML that cannot yield the three is `422` even if the form was typed (C29, C30). Identified full XML occupies the same `xml` attachment as an upload; resumo does not. | First `vNF` anywhere in the file — item tags also carry values (#9 total is `ICMSTot/vNF`). Filling from destinatário — #14 favorecido is emitente. Keeping #32 typed-wins when XML is present — #14 XML is truth. |
| Identified consulta is a server port | Given chave + unwrapped A1, the port returns full XML, resumo fields, not found, window-expired, or error. Tests use a fake (no network). Real calls use SEFAZ produção, not homologação. mTLS stays on the server, including submitter insert. Insert applies consulta immediately. Consulta that would overwrite already-stored correctable fields waits for confirm (C54, C55). Browser, Stimulus, and views never see the PKCS#12 or passphrase. Missing A1, expired A1, removed A1, or blank wrap key skip identified consulta and do not stop the rest of the app (C41, C42, C43, C20, C69). | Public chave HTML form — #14 forbids captcha. Calling SEFAZ from the client — AGENTS.md / `.cursor/rules/rails.mdc`. Async job so the 302 page would not yet include `R$ 155,00` — #27 consulta runs on insert. Retro-consult on cert install — #27 new extractions only; C63. Homologação as the real target — coordinators consult authorized production notes. Requiring the wrap key at boot — A1 is optional; close and typed insert must work without it. |
| Leaf titular is 14 digits as written | The leaf CNPJ is the first 14-digit run on the certificate subject (then 11 digits, which are refused as e-CPF). `/setup` formats 14 digits as `AA.AAA.AAA/AAAA-AA` without módulo-11. Wrap key is `ENV["SEFAZ_WRAP_KEY"]` via `WrapKey`, derived with `ActiveSupport::KeyGenerator` (not a raw 32-byte key). | `BrazilianTaxId.cnpj?` as the install gate — C13’s titular `12345678000101` fails módulo-11, so that check would refuse a criterion named as a valid A1. `BrazilianTaxId.format` — returns nil for that titular. Rails credentials for the wrap key — already rejected in door 1. |

- Nothing else in this change is hard to reverse

Unresolved 1 stays open (none).

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
- `spec/models/organization_spec.rb` + `spec/requests/accountants_spec.rb` — standing fields on Organization plus coordinator HTML to `/setup` is the closest analogue for the certificate slot
- `spec/models/supporting_document_spec.rb` + `spec/requests/supporting_documents_spec.rb` — insert/apply/422 copy is the insert pipeline this cut extends
- `spec/models/invite_spec.rb` concurrent create — same `run_in_parallel` / `use_transactional_tests = false` shape as C19
- Identified consulta port is reached from insert/apply/confirm; the fake has no network. Real SOAP mapping is a decision table proven at its own layer from fixtures, not from HTTP
- SefazCertificatesController and the confirm action stay pass-through once Organization and SupportingDocument decide; HTTP status / who may call still need request specs

Cost: model specs for certificate install/replace/remove/unwrap, authorized XML keys, field-origin lock, consulta port outcomes, kind pipeline, confirm; request specs for every status/route claim below.

## Checks

### S1 - Certificate slot · 14 files · 49 KB · ~12k

**C1** - When a coordinator of the focused organization opens `/setup` while that organization has no SEFAZ certificate, then the response is `200` and includes the heading `Certificado SEFAZ` and the text `Nenhum certificado`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with no SEFAZ certificate includes Certificado SEFAZ and Nenhum certificado"`

**C2** - When a coordinator POSTs a PKCS#12 `.pfx` whose leaf titular is CNPJ `11222333000181`, notAfter `2027-09-18`, and passphrase `passphrase-secreta`, then the system persists that certificate on the focused organization, responds `302` to `/setup`, and that page includes `11.222.333/0001-81` and `Válido até 18/09/2027` and does not include `Nenhum certificado` or `passphrase-secreta`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST /sefaz_certificate persists pfx and redirects"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "install pfx persists titular 11222333000181 and notAfter 2027-09-18"`

**C3** - When a coordinator POSTs the same titular as a `.p12` with a correct passphrase, then the response is `302` to `/setup` and that page includes `11.222.333/0001-81`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST /sefaz_certificate accepts p12"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "install p12 persists titular 11222333000181"`

**C4** - If a request sends `GET /sefaz_certificate` after that install, then the response is `404` and the body does not include the PKCS#12 bytes
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "GET /sefaz_certificate after install responds 404 without PKCS12 bytes"`

**C5** - If a coordinator POSTs that `.pfx` with passphrase `errada`, then the system persists no certificate and responds `422` with `Não foi possível abrir o certificado com essa senha`, and `/setup` still includes `Nenhum certificado`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST pfx with passphrase errada returns 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "install with passphrase errada persists no certificate"`

**C6** - If a coordinator POSTs a PKCS#12 whose leaf titular is CPF `39053344705`, then the system persists no certificate and responds `422` with `O certificado deve ser e-CNPJ A1 vigente`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST e-CPF returns 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "install e-CPF 39053344705 persists no certificate"`

**C7** - If a coordinator POSTs a PKCS#12 whose leaf notAfter is `2026-05-10` while today is `2026-05-11`, then the system persists no certificate and responds `422` with `O certificado deve ser e-CNPJ A1 vigente`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST expired A1 returns 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "install notAfter 2026-05-10 on 2026-05-11 persists no certificate"`

**C8** - If a coordinator POSTs a `.txt` file as the certificate, then the system persists no certificate and responds `422` with `O certificado deve ser e-CNPJ A1 vigente`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST txt certificate returns 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "install txt persists no certificate"`

**C9** - If a coordinator POSTs a PKCS#12 larger than `1048576` bytes, then the system persists no certificate and responds `422`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST PKCS12 larger than 1048576 returns 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "install larger than 1048576 persists no certificate"`

**C10** - If an unauthenticated request POSTs a valid PKCS#12, then the system persists no certificate and responds `302` to `/login`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "unauthenticated POST /sefaz_certificate responds 302 to /login"`

**C11** - If a submitter POSTs a valid PKCS#12, then the system persists no certificate and responds `404`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "submitter POST /sefaz_certificate persists none and responds 404"`

**C12** - While a submitter is focused on an organization that has titular `11222333000181` installed, `GET /setup` responds `404` and the body does not include `11.222.333/0001-81` or `Válido até`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "submitter GET /setup responds 404 and omits titular CNPJ"`

**C13** - When a coordinator POSTs a second valid e-CNPJ A1 whose titular is `12345678000101` over the first, then `/setup` includes `12.345.678/0001-01` and does not include `11.222.333/0001-81`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST second A1 replaces titular on /setup"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "install second A1 replaces titular 12345678000101"`

**C14** - When `/setup` lists a certificate, then it includes `Remover` and that control uses Turbo confirm `Remover o certificado SEFAZ?`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with certificate includes Remover turbo confirm"`

**C15** - When a coordinator DELETEs the focused organization’s certificate, then the system persists no certificate, responds `302` to `/setup`, and that page includes `Nenhum certificado` and does not include `11.222.333/0001-81`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "DELETE /sefaz_certificate clears the slot and redirects"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "remove_sefaz_certificate nulls the slot"`

**C16** - If an unauthenticated request DELETEs the certificate, then the certificate remains and the response is `302` to `/login`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "unauthenticated DELETE /sefaz_certificate leaves certificate and responds 302 to /login"`

**C17** - If a submitter DELETEs the certificate, then the certificate remains and the response is `404`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "submitter DELETE /sefaz_certificate leaves certificate and responds 404"`

**C18** - While focus is organization A, `/setup` does not include a titular CNPJ that exists only on organization B’s certificate
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup does not include another organization titular CNPJ"`

**C19** - When two concurrent POSTs install different valid A1s on the same organization, then that organization has exactly one certificate and the stored passphrase opens the stored PKCS#12
Proof: `bin/rspec spec/models/organization_spec.rb -e "concurrent A1 installs leave one consistent pair"`

**C20** - If the wrapping-key process environment is blank, then a POST of a valid A1 persists no certificate and responds `422` with `O certificado não pôde ser guardado`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST A1 with blank wrap key returns 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "install with blank wrap key persists no certificate"`

**C21** - Given installed notAfter `2026-05-11`, while today is `2026-05-12`, `/setup` includes `Expirado em 11/05/2026` and does not include `Válido até`
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with expired certificate includes Expirado em 11/05/2026"`

**C22** - When Month `2026-05` is closed, a coordinator POST of a valid A1 still persists the certificate and responds `302` to `/setup`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST A1 while month closed still persists and redirects"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "install while a month is closed still persists"`

### S2 - Uploaded XML is truth · 8 files · 60 KB · ~15k

**C23** - When a coordinator POSTs `kind=nota_fiscal`, an authorized XML whose `infNFe/total/ICMSTot/vNF` is `155.00`, `infNFe/emit/xNome` is `Padaria Central`, `infNFe/ide/dhEmi` is `2026-05-11T10:00:00-03:00`, `infNFe/dest/xNome` is `ONG Destinataria`, `infNFe/@Id` is `NFe43260511222333000181550010000000011123456781`, and no typed amount, date, or payee, then the system persists `amount_cents` `15500`, `document_on` `2026-05-11`, `payee` `Padaria Central`, responds `302` to `/supporting_documents`, and that page includes `R$ 155,00`, `11/05/2026`, `Padaria Central`, and `43260511222333000181550010000000011123456781` and does not include `ONG Destinataria`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST authorized XML fills amount date payee chave and redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert authorized XML persists 15500 Padaria Central 2026-05-11 and chave"`

**C24** - When a coordinator POSTs that XML together with typed amount `100,00`, then the system persists `amount_cents` `15500`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST authorized XML with typed 100,00 persists 15500"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert authorized XML ignores typed 100,00 and keeps 15500"`

**C25** - If a coordinator PATCHes amount `200,00` on that document, then the system persists no change and responds `422` with `Valor, data e favorecido vêm da nota e não podem ser alterados`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH amount on uploaded XML returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply amount on uploaded XML is rejected"`

**C26** - If a coordinator PATCHes payee `Mercado Silva` on that document, then the system persists no change and responds `422` with `Valor, data e favorecido vêm da nota e não podem ser alterados`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH payee on uploaded XML returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply payee on uploaded XML is rejected"`

**C27** - If a coordinator PATCHes date `2026-06-01` on that document, then the system persists no change and responds `422` with `Valor, data e favorecido vêm da nota e não podem ser alterados`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH date on uploaded XML returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply date on uploaded XML is rejected"`

**C28** - When a coordinator PATCHes observation `pago em dinheiro` on that document, then the system persists that observation, responds `302` to `/supporting_documents`, and that page includes `pago em dinheiro`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH observation on uploaded XML redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply observation on uploaded XML persists"`

**C29** - If a coordinator POSTs `kind=nota_fiscal` with a file that is not well-formed XML, then the system persists no SupportingDocument and responds `422` with `O XML da nota fiscal não pôde ser lido`, even when typed amount, date, and payee are present
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST malformed XML returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert malformed XML persists none"`

**C30** - If a coordinator POSTs well-formed XML that has no `infNFe/total/ICMSTot/vNF`, then the system persists no SupportingDocument and responds `422` with `O XML da nota fiscal não pôde ser lido`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST XML without ICMSTot vNF returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert XML without ICMSTot vNF persists none"`

**C31** - Given a SupportingDocument that already has an XML blob containing `vNF` `100.00` and `amount_cents` `15500` from before this task (no field origin of uploaded XML), when a coordinator PATCHes payee `Mercado Silva`, then the system persists that payee, `amount_cents` stays `15500`, and the response is `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH payee on pre-task XML blob redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply payee on pre-task XML blob persists Mercado Silva"`

**C32** - When a coordinator POSTs `kind=recibo` with a photo, typed `155,00` / `2026-05-11` / `Padaria Central`, then the system persists those typed fields and a later PATCH of payee `Mercado Silva` responds `302` and persists that payee
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo then PATCH payee Mercado Silva redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert recibo then apply payee Mercado Silva persists"`

**C33** - If a coordinator POSTs `kind=recibo` with a photo and an XML file, then the system persists no SupportingDocument and responds `422` with `Recibo não tem XML`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo with xml returns 422 Recibo nao tem XML"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "rejects recibo with xml"`

**C34** - When a coordinator POSTs `kind=nota_fiscal` with a photo, typed `155,00` / `2026-05-11` / `Padaria Central`, and no XML and no chave, then the system persists `amount_cents` `15500` and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST typed nota_fiscal photo then PATCH payee redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert typed nota_fiscal photo then apply payee persists"`

**C35** - When `dhEmi` is `2026-05-11T23:30:00-03:00`, then `document_on` is `2026-05-11`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert XML dhEmi 2026-05-11T23:30:00-03:00 stores document_on 2026-05-11"`

### S3 - Identified consulta on insert · 6 files · 57 KB · ~14k

**C36** - Given the focused organization has a valid A1 and identified consulta for chave `43260511222333000181550010000000011123456781` returns authorized XML with `vNF` `155.00`, emitente `Padaria Central`, `dhEmi` `2026-05-11T10:00:00-03:00`, when a coordinator POSTs `kind=nota_fiscal`, a `.jpg` photo, that chave, and no typed amount, date, or payee, then the system persists `amount_cents` `15500`, `document_on` `2026-05-11`, `payee` `Padaria Central`, attaches that XML on the SupportingDocument, responds `302` to `/supporting_documents`, and that page includes `R$ 155,00`, `11/05/2026`, `Padaria Central`, and that chave
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST chave with consulta XML fills fields and redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert chave with consulta XML persists 15500 and attaches xml"`

**C37** - When a submitter POSTs that same insert, then the system persists the same fields and XML, `GET /supporting_documents` is `200` and includes `R$ 155,00`, and that page does not include `11.222.333/0001-81`, `Válido até`, or `passphrase-secreta`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter POST chave with consulta XML persists and omits certificate"`

**C38** - Given identified consulta returns only a resumo (`vNF` `155.00`, emitente `Padaria Central`, `dhEmi` `2026-05-11`) and not full XML, when a coordinator POSTs photo plus that chave and no typed fields, then the system persists those three fields, the photo remains, XML is not attached, and a PATCH of amount responds `422` with `Valor, data e favorecido vêm da nota e não podem ser alterados`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST chave with consulta resumo locks fields without xml"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert chave with resumo persists fields without xml and locks amount"`

**C39** - If identified consulta returns only a resumo and the POST has that chave and neither photo nor XML, then the system persists no SupportingDocument and responds `422` with `Envie a foto e/ou o XML`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST chave resumo without files returns 422 Envie a foto e/ou o XML"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert chave resumo without files persists none"`

**C40** - When identified consulta returns full XML and the POST has that chave and neither photo nor XML and no typed fields, then the system persists the XML attachment and those three fields and responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST chave consulta XML without files persists xml and redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert chave consulta XML without files attaches xml"`

**C41** - When the organization has no certificate and a coordinator POSTs photo, that chave, and typed `155,00` / `2026-05-11` / `Padaria Central`, then the system persists `amount_cents` `15500` and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST chave without certificate stays typed and PATCH payee redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert chave without certificate stays typed"`

**C42** - While the installed certificate is expired, when a coordinator POSTs photo, that chave, and those typed fields, then the system persists the typed fields and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST chave with expired certificate stays typed and PATCH payee redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert chave with expired certificate stays typed"`

**C43** - After the certificate is removed, when a coordinator POSTs photo, that chave, and those typed fields, then the system persists the typed fields and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST chave after certificate removed stays typed and PATCH payee redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert chave after certificate removed stays typed"`

**C44** - If identified consulta errors or times out and the POST has photo, that chave, and those typed fields, then the system persists the typed fields and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST chave when consulta errors stays typed and PATCH payee redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert chave when consulta errors stays typed"`

**C45** - If identified consulta errors or times out and the POST has photo, that chave, and no typed amount, date, or payee, then the system persists no SupportingDocument and responds `422` with `Informe valor, data e favorecido`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST chave when consulta errors without typed fields returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert chave when consulta errors without typed fields persists none"`

**C46** - If identified consulta returns not found or window-expired and the POST has photo, that chave, and those typed fields, then the system persists the typed fields and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST chave when consulta not found or window-expired stays typed"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert chave when consulta not found or window-expired stays typed"`

**C47** - When a coordinator POSTs chave `4326.0511.2223.3300.0181.5500.1000.0000.0111.2345.6781` with a valid A1 and consulta XML for the 44-digit form, then the system persists chave `43260511222333000181550010000000011123456781` and the XML fields
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST dotted chave persists 44 digits and XML fields"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert dotted chave stores 44 digits"`

**C48** - If a coordinator POSTs a chave that is not 44 digits after stripping non-digits, then the system persists no SupportingDocument and responds `422` with `Informe a chave de acesso com 44 dígitos`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST chave not 44 digits returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert chave not 44 digits persists none"`

**C49** - When two POSTs insert nota fiscal with the same 44-digit chave, then the system persists two SupportingDocuments
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST duplicate chave persists two SupportingDocuments"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert duplicate chave persists two SupportingDocuments"`

**C50** - When a coordinator POSTs `kind=recibo` with a photo, typed fields, and that chave, then the system persists kind recibo, attaches no XML, stores no chave, and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo with chave stores no chave and PATCH payee redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert recibo with chave stores no chave"`

**C51** - When a coordinator POSTs an uploaded XML of `vNF` `155.00` together with that chave while consulta would return `vNF` `100.00`, then the system persists `amount_cents` `15500`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST uploaded XML wins over consulta vNF 100.00"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert uploaded XML wins over consulta vNF 100.00"`

### S4 - Relançamento, isolation, close · 6 files · 64 KB · ~16k

**C52** - When a coordinator PATCHes `kind=recibo` together with the existing photo on a locked nota fiscal that has XML and chave, then the SupportingDocument is recibo, has no XML, has no chave, keeps amount, date, and payee, and a later PATCH of payee `Mercado Silva` responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH kind recibo on locked nota discards xml chave and unlocks"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply kind recibo on locked nota purges xml chave and unlocks"`

**C53** - When a coordinator PATCHes `kind=nota_fiscal` and that chave on a recibo while the organization has a valid A1 and consulta returns full XML of `vNF` `100.00` emitente `Mercado Silva` `dhEmi` `2026-05-12`, then the system persists `amount_cents` `10000`, `payee` `Mercado Silva`, `document_on` `2026-05-12`, attaches that XML, and a later PATCH of amount responds `422`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH kind nota_fiscal on recibo fires consulta and locks"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply kind nota_fiscal on recibo fires consulta and locks"`

**C54** - Given a typed nota fiscal of `amount_cents` `15500` payee `Padaria Central` and a valid A1 whose consulta for that chave returns `vNF` `100.00`, when a coordinator PATCHes that chave, then `amount_cents` stays `15500`, the response is `302`, and `/supporting_documents` includes `Usar dados da SEFAZ`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH chave on typed nota keeps 15500 and includes Usar dados da SEFAZ"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply chave on typed nota keeps 15500"`

**C55** - When a coordinator confirms identified SEFAZ on that document, then the system persists `amount_cents` `10000`, locks the three fields, responds `302` to `/supporting_documents`, and that page includes `R$ 100,00` and does not include `R$ 155,00`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "confirm identified SEFAZ persists 10000 and redirects"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "confirm identified SEFAZ persists 10000 and locks"`

**C56** - If that confirm runs while identified consulta errors, then the system persists no change to amount, the three fields stay editable, and the response is `422`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "confirm identified SEFAZ when consulta errors returns 422"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "confirm identified SEFAZ when consulta errors keeps 15500 editable"`

**C57** - When a coordinator PATCHes that chave on a typed nota fiscal and the organization has no certificate, then the system persists the chave, `amount_cents` stays `15500`, and the page does not include `Usar dados da SEFAZ`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH chave without certificate stores chave and omits Usar dados da SEFAZ"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply chave without certificate stores chave and keeps 15500"`

**C58** - When a coordinator confirms identified SEFAZ on a document already filled from identified consulta, then the response is `302` and amount, date, and payee stay the values already stored
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "confirm identified SEFAZ on already identified redirects unchanged"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "confirm identified SEFAZ on already identified changes nothing"`

**C59** - If a coordinator PATCHes chave while Month `2026-05` is closed and that document belongs to it, then the chave is unchanged and the response is `422` with `Mês fechado`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH chave on closed month returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply chave while month closed is rejected"`

**C60** - When a submitter PATCHes chave on their own no-month typed nota fiscal, then the system persists that chave and responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter PATCH chave on own no-month document redirects"`

**C61** - If a submitter PATCHes chave on a SupportingDocument of another Account, then the system persists no change and responds `404`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter PATCH chave on another Account document returns 404"`

**C62** - If a submitter PATCHes chave on their own SupportingDocument that belongs to a Month, then the system persists no change and responds `422` with `Documento já pertence a um mês`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter PATCH chave on month document returns 422"`

**C63** - When a coordinator installs a valid A1 after a typed nota fiscal already exists with a chave, then that document’s amount stays typed and a PATCH of payee `Mercado Silva` still responds `302`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "install A1 after typed chave does not retro-consult"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "install A1 after typed chave leaves amount typed"`

**C64** - When a coordinator DELETEs the certificate, a document already filled from identified consulta still responds `422` to a PATCH of amount
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "DELETE certificate leaves identified lock on amount PATCH"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "remove certificate leaves identified lock"`

**C65** - While the certificate is expired, a document already filled from identified consulta still responds `422` to a PATCH of amount
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "expired certificate leaves identified lock on amount PATCH"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "expired certificate leaves identified lock"`

**C66** - When the organization has no certificate and Month `2026-05` has no missing document, then `POST /months/2026-05/close` responds `302` and that month is closed
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with no certificate and no missing document redirects"`

**C67** - When the organization has an expired certificate and Month `2026-05` has no missing document, then `POST /months/2026-05/close` responds `302` and that month is closed
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with expired certificate and no missing document redirects"`

**C68** - Always, amount from `vNF` is integer cents (`15500` for `155.00`), never a `Float` domain amount
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "amount from vNF 155.00 is Integer 15500"`

**C69** - While the wrapping-key process environment is blank and the organization has no certificate, `GET /setup` responds `200` and includes `Nenhum certificado`, and when Month `2026-05` has no missing document, `POST /months/2026-05/close` responds `302` and that month is closed
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with blank wrap key and no certificate includes Nenhum certificado"`
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with blank wrap key and no certificate redirects"`

## Swept

- validation: C5, C6, C7, C8, C9, C23, C29, C30, C48
- failure modes: C20, C25, C39, C42, C44, C45, C56, C59, C69 - blank wrap key refuses install and skips identified consulta; setup and close-for-send still succeed
- idempotency and retry: C13, C58 - a second install overwrites the one slot; a second confirm does not change already-locked fields
- authorization: C10, C11, C12, C16, C17, C37, C61, C62
- concurrency and ordering: C19 - two installs leave one PKCS#12 that the stored passphrase opens (not a mix of A’s file and B’s passphrase)
- data lifecycle: C15, C31, C63, C64 - remove nulls the slot; existing XML rows are not backfilled; later install does not retro-consult; identified lock survives remove
- external-dependency failure: C44, C45, C46, C56 - consulta error, timeout, not found, and window-expired fall through to typed or `422` when the three fields are missing; confirm does not lock on error
- state transitions: C2, C13, C15, C21, C23, C36, C52, C53, C54, C55
- observability: existing - `filter_parameters` already includes `:passw` and `:certificate`; no new operator metric is required

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| certificate slot states (3) | absent C1 · valid C2 · expired C21 | - |
| PKCS#12 extensions accepted (2) | `.pfx` C2 · `.p12` C3 | - |
| install refuses (6) | wrong passphrase C5 · e-CPF C6 · expired leaf C7 · not PKCS#12 C8 · oversized C9 · blank wrap key C20 | - |
| who may POST `/sefaz_certificate` (3) | coordinator C2 · unauthenticated C10 · submitter C11 | - |
| who may DELETE `/sefaz_certificate` (3) | coordinator C15 · unauthenticated C16 · submitter C17 | - |
| GET `/sefaz_certificate` (1) | always `404` C4 | - |
| authorized XML keys (4) | `ICMSTot/vNF` C23 · `emit/xNome` C23 · `ide/dhEmi` calendar date C23 / C35 · `@Id` without `NFe` C23 | - |
| field origin lock (6) | uploaded XML C25–C27 · identified full XML C36 · identified resumo C38 · typed photo C34 · pre-task XML blob C31 · recibo C32 | - |
| consulta port outcomes (8) | full XML C36 / C40 · resumo C38 / C39 · error/timeout with typed C44 · error/timeout without typed C45 · not found/window-expired C46 · skip no cert C41 · skip expired C42 · skip removed C43 | - |
| chave digits (2) | 44 after strip C47 · not 44 C48 | - |
| kind pipeline (2) | nota→recibo C52 · recibo→nota C53 | - |
| confirm identified SEFAZ (3) | apply C55 · consulta error C56 · already identified C58 | - |
| submitter chave PATCH (3) | own no-month C60 · other Account C61 · has month C62 | - |
| lock vs certificate lifecycle (3) | later install no retro C63 · remove keeps lock C64 · expired keeps lock C65 | - |
| close-for-send with A1 optional (3) | no certificate C66 · expired C67 · blank wrap key C69 | - |
| integer cents from `vNF` (1) | `155.00` → `15500` Integer C68 | - |
| startup config assemblies | wrap-key reader is one module install and consulta both call; test and app share `ENV` | - |

- Claims naming a status code, route or response shape: C1–C22, C23–C34, C36–C67, C69 - each has a request-spec proof that crosses the boundary except C35 and C68 (model-only calendar date and Integer cents)
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~12k + S2 ~15k + S3 ~14k + S4 ~16k = ~57k tokens floor. All four slices stay under 150k. Surface changes at S2 (setup/certificate → supporting documents) but the running total never reaches the budget, so no split.
