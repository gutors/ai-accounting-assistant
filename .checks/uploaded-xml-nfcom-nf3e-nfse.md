# Uploaded XML for NFCom, NF3e, and national NFS-e

Profile: `standard`. Screens on insert/edit reuse existing copy and arrangement; no binding design source. Not raised to `ui`.

Sources:

- `.tasks/uploaded-xml-nfcom-nf3e-nfse.md` - criteria 1–16, three doors, sweep, surface, Unresolved 1–3 (municipal refuse vs recibo; `vServ` vs `vLiq`; `dhEmi` vs `dCompet`). Nothing under Unresolved is settled while building
- Conversation 2026-10-17 - accept NFS-e, NF3e (66), NFCom (62); skip new consulta because the XML already has the three fields
- Conversation landing before the plan - uploaded XML only; photo of those types without XML does not gain fiscal identification in this version; municipal NFS-e without `infNFSe` is refused with a clear sentence
- `app/models/authorized_nfe.rb` - current `infNFe` + `ICMSTot/vNF` + `NFe` prefix
- `GLOSSARY.md` **Nota fiscal** / **Chave de acesso** / **SEFAZ consulta** - criterion 16 amends them
- ADR-0009 - empty insert XML still `nota_fiscal`; this task does not reopen infer

## Out of scope

- New identified consulta, public consulta, or portal download for NFCom, NF3e, or NFS-e
- Photo / DANFCom / DANF3e / DANFSE identification, OCR, or chave-from-photo for models 62 and 66 or NFS-e
- Parsing municipal NFS-e layouts (Ginfes, ISSNet, ABRASF `InfNfse`, and other pre-national schemas) - C14 refuses them
- CT-e, CT-e OS, MDF-e, BP-e, NFAg, NFGas, and CF-e SAT XML - C13 copy
- New `kind` enum members; these documents stay `nota_fiscal`
- Changing match, close-for-send package names, or origin copy `XML autorizado`
- Signature validation of the XML
- Open Finance, NF-e issuance, accountant login

## Landing

Touches `AuthorizedNfe.parse` (accepted inf roots and Id prefixes), `SupportingDocument#submit` identify/insert XML refusal copy, `GLOSSARY.md`. Reuses identify/create/edit HTTP, `fields_origin` `uploaded_xml`, lock `LOCKED_FIELDS`, origin stamp `XML autorizado`, Turbo Stream 422 notice+toast, focused Access. No schema change. `SefazConsulta` / `PublicNfceConsulta` stay off the uploaded-XML success path.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| These DFe stay `kind` `nota_fiscal` | Enum unchanged. XML extension still classifies as `nota_fiscal` (ADR-0009). | New kind members per model — would split the list, infer, submitter justify, and match for no operator distinction in monthly close. |
| Upload XML only; no new consulta | Identify/create parse the bytes. `SefazConsulta` / `PublicNfceConsulta` are not invoked when that parse succeeds (C10). NFCom/NF3e SVRS and NFS-e national portals are not dependencies. | Identified consulta for modelo 62/66 — different webservice and certificate use than `chNFe` distDFe already in `SefazConsulta::Real`. |
| Typed/photo chave stay 44 digits | `CHAVE_DIGITS` and `PhotoSymbols` 44-digit guard unchanged. Uploaded XML stores Id digits after the model prefix (`NFe`, `NFCom`, `NF3e`, `NFS`). | Widen typed chave to 50 — would send NFS-e keys into NF-e distDFe. |
| `AuthorizedNfe.parse` stays Parsed or nil; uploaded XML maps nil through a refusal classifier | `parse` returns the four-field object or `nil` (existing `SefazConsulta` callers stay nil-on-miss). When uploaded XML parse is nil, `AuthorizedNfe.unsupported?` is true for well-formed XML with none of `infNFe` / `infNFCom` / `infNF3e` / `infNFSe` and a recognized other-DFe root (`infCte`, `infCteOS`, `infMDFe`, `infBPe`, `infNFAg`, `infNFGas`, `CFe`/`infCFe`, `CompNfse`/`InfNfse`); then `SupportingDocument::XML_UNSUPPORTED` (`Este XML não é NF-e, NFC-e, NFS-e nacional, NFCom ou NF3e`). Otherwise `XML_UNREADABLE`. | Change `parse` to a result union — would rewrite identified-XML callers that treat a truthy return as a fill. Treat every well-formed non-accepted XML as unsupported — would change `<nfe/>` without `infNFe` from unreadable to unsupported. |

- Nothing else in this change is hard to reverse

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

These rows are the bar I build under — approving the checklist is enough for that. Writing them into `.cursor/rules/rails.mdc` needs an explicit yes, and it lands as its own commit before the build. Without one I build under them and leave the file alone.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at the model layer **and** one request spec at HTTP | one asserted case per enumerated member at the model; status / who may call at the boundary | follow |
| Decides, not reached across a boundary | one at the model layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc`: decision at its own layer, one asserted case per enumerated member; HTTP also a request spec
- `AuthorizedNfe.parse` / `unsupported?` is the decision table (accepted inf roots, prefixes, unreadable vs unsupported). Closest analogue: `spec/models/sefaz_consulta_spec.rb` enumerates `cStat` at the parser
- `SupportingDocument#submit` maps parse-nil to `XML_UNREADABLE` vs `XML_UNSUPPORTED` and skips consulta when parse succeeds — model plus HTTP
- `#identify` / `#create` / `#update` stay pass-through after that map
- C16 is a file-read of `GLOSSARY.md`. Closest analogue: `spec/docs/glossary_spec.rb`

Cost: request + model examples for C1–C9, C11–C15; model table for C10 and other-DFe unsupported roots; file-read for C16. Without the parser table, HTTP successes would not prove incomplete `infNFe` vs CT-e vs municipal.

## Checks

Criteria 1–16 map to C1–C16. Unresolved 1–3 stay transcribed.

### S1 - NFCom, NF3e, and national NFS-e XML · 6 files · 242 KB · ~61k

**C1** - Given the focused organization has no SEFAZ certificate, and authorized NFCom XML (`nfcomProc` / `infNFCom`) with `total/vNF` `256.80`, emitente `EMPRESA TELECOM EXEMPLO S.A.`, `dhEmi` `2026-06-15T21:53:53-03:00`, `Id` `NFCom27260611222333000181620010008920781028142810`, when a coordinator POSTs `POST /supporting_documents/identify` with that file, then no SupportingDocument is persisted, the status is `200`, Tipo is `Nota fiscal` disabled, Valor `256,80`, Data `2026-06-15`, Favorecido `EMPRESA TELECOM EXEMPLO S.A.`, chave `27260611222333000181620010008920781028142810`, origin under Valor, Data, and Favorecido is `XML autorizado`, and those three inputs are disabled
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify authorized NFCom XML fills book without persisting"`
Proof: `bin/rspec spec/models/authorized_nfe_spec.rb -e "parse NFCom 25680 EMPRESA TELECOM 2026-06-15 chave"`

**C2** - When that coordinator POSTs `POST /supporting_documents` with that same NFCom file and no `kind`, then one SupportingDocument persists `kind` `nota_fiscal`, `amount_cents` `25680`, `document_on` `2026-06-15`, `payee` `EMPRESA TELECOM EXEMPLO S.A.`, that chave, `fields_origin` `uploaded_xml`, the XML blob, no photo blob, and the status is `302` to `/supporting_documents`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST create NFCom XML without kind persists 25680 uploaded_xml"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NFCom XML persists 25680 uploaded_xml blob"`

**C3** - Given no SEFAZ certificate, and authorized NF3e XML (`infNF3e`) with `vNF` `189.40`, emitente `Companhia Energetica Exemplo`, `dhEmi` `2026-05-20T00:00:00-03:00`, `Id` `NF3e27260611222333000181660010000008920781028142`, when that coordinator POSTs identify with that file, then no row is persisted, the status is `200`, Valor `189,40`, Data `2026-05-20`, Favorecido `Companhia Energetica Exemplo`, chave `27260611222333000181660010000008920781028142`, origin `XML autorizado`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify authorized NF3e XML fills book without persisting"`
Proof: `bin/rspec spec/models/authorized_nfe_spec.rb -e "parse NF3e 18940 Companhia Energetica 2026-05-20 chave"`

**C4** - When that coordinator POSTs create with that NF3e file and no `kind`, then one row persists `amount_cents` `18940`, `document_on` `2026-05-20`, `payee` `Companhia Energetica Exemplo`, that chave, `fields_origin` `uploaded_xml`, and `302` to `/supporting_documents`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST create NF3e XML without kind persists 18940 uploaded_xml"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert NF3e XML persists 18940 uploaded_xml blob"`

**C5** - Given no SEFAZ certificate, and authorized national NFS-e XML (`infNFSe`) with `vServ` `610.00`, emitente `xNome` `Contabilidade Exemplo Ltda`, `dhEmi` `2026-05-06T10:00:00-03:00`, `Id` `NFS41260511222333000181000000000000000000000000000001`, when that coordinator POSTs identify with that file, then no row is persisted, the status is `200`, Valor `610,00`, Data `2026-05-06`, Favorecido `Contabilidade Exemplo Ltda`, chave `41260511222333000181000000000000000000000000000001`, origin `XML autorizado`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify authorized national NFSe XML fills book without persisting"`
Proof: `bin/rspec spec/models/authorized_nfe_spec.rb -e "parse national NFSe 61000 Contabilidade Exemplo 2026-05-06 chave"`

**C6** - When that coordinator POSTs create with that NFS-e file and no `kind`, then one row persists `amount_cents` `61000`, `document_on` `2026-05-06`, `payee` `Contabilidade Exemplo Ltda`, that 50-digit chave, `fields_origin` `uploaded_xml`, and `302` to `/supporting_documents`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST create national NFSe XML without kind persists 61000 uploaded_xml"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert national NFSe XML persists 61000 uploaded_xml blob"`

**C7** - Given a submitter of the focused organization and no certificate, when they POST identify then create as in C2 with that NFCom file, then the persisted `account_id` is the submitter, `GET /supporting_documents` is `200` and includes `EMPRESA TELECOM EXEMPLO S.A.`, and it does not include another organization's documents
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter identify then create NFCom is own account and scoped list"`

**C8** - Given the NFCom row from C2, when `GET /supporting_documents/:id/edit` runs, then Valor, Data, and Favorecido are not editable and each origin is `XML autorizado`. When that coordinator PATCHes `payee` `Mercado Silva`, then the status is `422`, `[data-notice="error"]` is `Valor, data e favorecido vêm da nota e não podem ser alterados`, and `payee` remains `EMPRESA TELECOM EXEMPLO S.A.`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit NFCom uploaded_xml origins XML autorizado locked"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH payee on NFCom uploaded XML 422 LOCKED_FIELDS"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply payee on NFCom uploaded XML keeps EMPRESA TELECOM"`

### S2 - NF-e XML still parses; no new consulta · 4 files · 237 KB · ~59k

**C9** - When that coordinator POSTs identify with authorized NF-e XML of `vNF` `155.00`, emitente `Padaria Central`, `dhEmi` `2026-05-11T10:00:00-03:00`, chave `43260511222333000181550010000000011123456781`, then the status is `200`, Valor `155,00`, Data `2026-05-11`, Favorecido `Padaria Central`, origin `XML autorizado`, and no SupportingDocument is persisted
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify authorized XML fills book without persisting"`
Proof: `bin/rspec spec/models/authorized_nfe_spec.rb -e "parse NFe 15500 Padaria Central 2026-05-11 chave"`

**C10** - Always, identify or create of NFCom, NF3e, or national NFS-e XML does not call `SefazConsulta` and does not call `PublicNfceConsulta` (no certificate, wrapping key, or NFC-e QR is required for those three successes)
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "identify and insert of NFCom NF3e NFSe XML do not call SefazConsulta or PublicNfceConsulta"`

### S3 - Refused XML · 5 files · 241 KB · ~60k

**C11** - If identify is posted XML that is not well-formed (`<nfe><`), then no SupportingDocument is persisted, the status is `422`, and `[data-notice="error"]` and the error toast are `O XML da nota fiscal não pôde ser lido`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify unreadable XML 422 keeps file input"`
Proof: `bin/rspec spec/models/authorized_nfe_spec.rb -e "parse malformed XML is nil and not unsupported"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert malformed XML persists none"`

**C12** - If identify is posted well-formed XML that has `infNFe` and no `total/ICMSTot/vNF`, then no row is persisted, the status is `422`, and that same unreadable copy is shown
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify infNFe without vNF 422 unreadable"`
Proof: `bin/rspec spec/models/authorized_nfe_spec.rb -e "parse infNFe without vNF is nil and not unsupported"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert XML without ICMSTot vNF persists none"`

**C13** - If identify is posted well-formed CT-e XML (`infCte` and no `infNFe`, `infNFCom`, `infNF3e`, or `infNFSe`), then no row is persisted, the status is `422`, and `[data-notice="error"]` and the error toast are `Este XML não é NF-e, NFC-e, NFS-e nacional, NFCom ou NF3e`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify CTe XML 422 unsupported copy"`
Proof: `bin/rspec spec/models/authorized_nfe_spec.rb -e "unsupported other DFe roots"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert CTe XML is XML_UNSUPPORTED persists none"`

**C14** - If identify is posted well-formed municipal NFS-e XML (`CompNfse` / `InfNfse` and no `infNFSe`), then no row is persisted, the status is `422`, and that same unsupported copy as C13 is shown
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST identify municipal NFSe XML 422 unsupported copy"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "insert municipal NFSe XML is XML_UNSUPPORTED persists none"`

**C15** - When create is posted the CT-e file of C13, then no row is persisted, the status is `422`, and `[data-notice="error"]` is that unsupported copy
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST create CTe XML 422 unsupported copy"`

### S4 - Glossary · 2 files · 16 KB · ~4k

**C16** - When this ships, `GLOSSARY.md` **Nota fiscal** names NF-e, NFC-e, NFCom (modelo 62), NF3e (modelo 66), and national NFS-e as authorized XML the supporting document may store, and **Chave de acesso** says the identifier on an uploaded XML is the digits from that document's `Id` (44 for NF-e / NFC-e / NFCom / NF3e, 50 for national NFS-e). Typed chave and photo decode remain 44 digits for identified SEFAZ consulta. **SEFAZ consulta** stays identified lookup of NF-e / NFC-e; it does not claim NFCom, NF3e, or NFS-e
Proof: `bin/rspec spec/docs/glossary_spec.rb -e "GLOSSARY Nota fiscal Chave de acesso SEFAZ consulta name uploaded XML models"`

## Swept

- validation: C1–C6, C11–C15 — required amount, date, payee, and Id digits; malformed and incomplete NF-e stay unreadable; other DFe stay unsupported
- failure modes: C11, C12, C13, C14, C15 — syntax vs missing NF-e `vNF` vs wrong model
- idempotency and retry: existing — a retried create POSTs a second SupportingDocument; no unique chave
- authorization: C7 — existing focused organization and submitter-own-row
- concurrency and ordering: n/a — two identify-then-create sequences persist two rows; no new uniqueness
- data lifecycle: n/a — `chave` remains a string; nothing to backfill; NFS-e 50-digit values are new writes only
- external-dependency failure: C10 — these three successes must not depend on SEFAZ or public NFC-e
- state transitions: C8 — `uploaded_xml` still locks the three fields (`LOCKED_FIELDS`)
- observability: existing — `:base` notice plus error toast on `422`; no new metric

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| accepted uploaded XML models (4) | NF-e C9 · NFCom C1/C2 · NF3e C3/C4 · national NFS-e C5/C6 | NFC-e shares `infNFe` with NF-e; no separate fixture |
| identify HTTP for accepted (4) | NFCom C1 · NF3e C3 · NFS-e C5 · NF-e C9 | - |
| create HTTP for new models (3) | NFCom C2 · NF3e C4 · NFS-e C6 | - |
| no-consulta ports (6) | identify×3 and insert×3 × not `SefazConsulta` / not `PublicNfceConsulta` in C10 table | - |
| refused XML at identify (4) | malformed C11 · incomplete `infNFe` C12 · CT-e C13 · municipal NFS-e C14 | - |
| other-DFe unsupported roots (8) | `infCte` C13 · `infCteOS` C13 · `infMDFe` C13 · `infBPe` C13 · `infNFAg` C13 · `infNFGas` C13 · `CFe`/`infCFe` C13 · `CompNfse`/`InfNfse` C13/C14 — table in `unsupported other DFe roots` | - |
| create unsupported (1) | CT-e C15 | municipal create is the same `submit` map as C14 insert |
| glossary entries this cut amends (3) | **Nota fiscal** C16 · **Chave de acesso** C16 · **SEFAZ consulta** C16 | - |
| Id prefixes on success (4) | `NFe` C9 · `NFCom` C1 · `NF3e` C3 · `NFS` C5 | - |

- Claims naming a status code, route or response shape: C1–C9, C11–C15 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises except C10 (6 operations) and C13 (8 other-DFe roots), enumerated above

## Handoff

S1–S4 unique files (`authorized_nfe.rb`, `supporting_document.rb`, helpers, request spec, two model specs, `GLOSSARY.md`, glossary spec) ≈ 258 KB · ~65k tokens. All stay on the documents XML parse surface. Under 150k, **one batch, no mid-feature handoff**.
