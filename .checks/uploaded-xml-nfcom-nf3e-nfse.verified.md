# Uploaded XML for NFCom, NF3e, and national NFS-e Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: `cb96568e3b06c1ddec433f4a1b0539b823b01221`..`651514d6bc2b4098415fd5821829a2f688db3c7b` (`origin/main`..`uploaded-xml-nfcom-nf3e-nfse`)
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

Designed-screens skipped: profile `standard`, no source marked binding.

## Binding sources

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| (none marked binding) | n/a | n/a | n/a |

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | identify NFCom fills book, no persist, 200, Tipo disabled, 256,80 / 2026-06-15 / EMPRESA TELECOM, chave, origin `XML autorizado` disabled | `POST identify authorized NFCom XML fills book without persisting` + `parse NFCom 25680 EMPRESA TELECOM 2026-06-15 chave` — both ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3726-3737` — `count == 0`; `:ok`; kind `nota_fiscal` disabled; `#amount` `256,80`; `#date` `2026-06-15`; `#payee` `EMPRESA TELECOM EXEMPLO S.A.`; chave include; origin `XML autorizado` and disabled on amount/date/payee. `spec/models/authorized_nfe_spec.rb:7-10` — `amount_cents == 25680`; payee; `Date.new(2026, 6, 15)`; chave | PASS |
| C2 | create NFCom persists `nota_fiscal` 25680 / 2026-06-15 / EMPRESA TELECOM / chave / `uploaded_xml` / XML blob / no photo / 302 to list | `POST create NFCom XML without kind persists 25680 uploaded_xml` + `insert NFCom XML persists 25680 uploaded_xml blob` — both ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3746-3756` — `:found`; redirect `/supporting_documents`; kind `nota_fiscal`; `25680`; date; payee; chave; `uploaded_xml`; xml attached; photo not. `spec/models/supporting_document_spec.rb:1808-1816` — same persist fields and blobs | PASS |
| C3 | identify NF3e fills 189,40 / 2026-05-20 / Companhia Energetica / chave / origin `XML autorizado`, no persist, 200 | `POST identify authorized NF3e XML fills book without persisting` + `parse NF3e 18940 Companhia Energetica 2026-05-20 chave` — both ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3764-3771` — count 0; `:ok`; `189,40`; `2026-05-20`; payee; chave include; `origin_copy(doc, "amount") == "XML autorizado"`. `spec/models/authorized_nfe_spec.rb:16-19` — `18940`; payee; date; chave | PASS |
| C4 | create NF3e persists 18940 / 2026-05-20 / Companhia Energetica / chave / `uploaded_xml` / 302 | `POST create NF3e XML without kind persists 18940 uploaded_xml` + `insert NF3e XML persists 18940 uploaded_xml blob` — both ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3779-3786` — `:found`; redirect list; cents/date/payee/chave/`uploaded_xml`. `spec/models/supporting_document_spec.rb:1822-1826` — same persist fields | PASS |
| C5 | identify national NFS-e fills 610,00 / 2026-05-06 / Contabilidade Exemplo / 50-digit chave / origin `XML autorizado`, no persist, 200 | `POST identify authorized national NFSe XML fills book without persisting` + `parse national NFSe 61000 Contabilidade Exemplo 2026-05-06 chave` — both ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3794-3801` — count 0; `:ok`; `610,00`; date; payee; 50-digit chave include; amount origin `XML autorizado`. `spec/models/authorized_nfe_spec.rb:25-28` — `61000`; payee; date; 50-digit chave | PASS |
| C6 | create NFS-e persists 61000 / 2026-05-06 / Contabilidade Exemplo / 50-digit chave / `uploaded_xml` / 302 | `POST create national NFSe XML without kind persists 61000 uploaded_xml` + `insert national NFSe XML persists 61000 uploaded_xml blob` — both ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3809-3816` — `:found`; redirect list; persist fields. `spec/models/supporting_document_spec.rb:1833-1836` — same | PASS |
| C7 | submitter identify then create NFCom: `account_id` is submitter; GET list 200 includes EMPRESA TELECOM, not other org | `submitter identify then create NFCom is own account and scoped list` — ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3833-3837` — `doc.account_id == submitter.id`; GET `:ok`; body includes EMPRESA TELECOM; `not_to include("Outra ONG")` | PASS |
| C8 | edit NFCom: Valor/Data/Favorecido disabled, origin `XML autorizado`; PATCH payee 422 LOCKED_FIELDS copy; payee unchanged | GET edit + PATCH + `apply payee on NFCom uploaded XML keeps EMPRESA TELECOM` — all ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3851-3852` — disabled + origin `XML autorizado` on amount/date/payee. `:3865-3867` — `:unprocessable_content`; notice `eq` `Valor, data e favorecido vêm da nota e não podem ser alterados`; payee still EMPRESA TELECOM. `spec/models/supporting_document_spec.rb:1843-1844` — `errors[:base]` includes `LOCKED_FIELDS`; reload payee | PASS |
| C9 | identify NF-e still 200, 155,00 / 2026-05-11 / Padaria Central / origin `XML autorizado`, no persist | `POST identify authorized XML fills book without persisting` + `parse NFe 15500 Padaria Central 2026-05-11 chave` — both ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3384-3399` — count 0; `:ok`; `155,00`; `2026-05-11`; Padaria Central; origin `XML autorizado` disabled (HTTP example pre-exists this cut; still asserts at HEAD). `spec/models/authorized_nfe_spec.rb:34-37` — `15500`; payee; date; chave (in this diff) | PASS |
| C10 | identify and insert of NFCom/NF3e/NFS-e do not call `SefazConsulta` or `PublicNfceConsulta` | `identify and insert of NFCom NF3e NFSe XML do not call SefazConsulta or PublicNfceConsulta` — ran, exit 0 | `spec/models/supporting_document_spec.rb:1857-1865` — three uploads × identify then insert: `not_to have_received(:lookup)` and `not_to have_received(:fetch)` | PASS |
| C11 | identify malformed `<nfe><` : no persist, 422, notice+toast unreadable copy | request + parse + insert — all ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3479-3484` — count 0; `:unprocessable_content`; notice and toast include `O XML da nota fiscal não pôde ser lido`. `spec/models/authorized_nfe_spec.rb:43-44` — `parse` nil; `unsupported? == false`. `spec/models/supporting_document_spec.rb:488-490` — not persisted; `XML_UNREADABLE`; count 0 | PASS |
| C12 | identify `infNFe` without `ICMSTot/vNF`: no persist, 422, same unreadable copy | request + parse + named insert — all ran, exit 0 | Settling: `spec/requests/supporting_documents_spec.rb:3886-3891` — count 0; `:unprocessable_content`; notice+toast unreadable copy (fixture has `infNFe`, no `vNF`). `spec/models/authorized_nfe_spec.rb:60-61` — parse nil; `unsupported? == false`. Named insert example `spec/models/supporting_document_spec.rb:496-498` asserts `XML_UNREADABLE` / count 0 on `xml_with_vnf` (`<nfe><vNF>…`) — not the C12 `infNFe` fixture; does not weaken the identify+parse proofs | PASS |
| C13 | identify CT-e `infCte`: no persist, 422, unsupported copy; other-DFe roots unsupported | request + `unsupported other DFe roots` + insert CTe — all ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3899-3904` — count 0; `:unprocessable_content`; notice+toast include `Este XML não é NF-e, NFC-e, NFS-e nacional, NFCom ou NF3e`. `spec/models/authorized_nfe_spec.rb:65-75` — `%w[infCte infCteOS infMDFe infBPe infNFAg infNFGas CFe infCFe]` plus `cte_xml` / `municipal_nfse_xml`: parse nil, `unsupported? == true`. `spec/models/supporting_document_spec.rb:1875-1877` — not persisted; `XML_UNSUPPORTED`; count 0 | PASS |
| C14 | identify municipal NFS-e `CompNfse`/`InfNfse`: no persist, 422, same unsupported copy | request + insert municipal — both ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3912-3917` — count 0; `:unprocessable_content`; notice+toast unsupported copy. `spec/models/supporting_document_spec.rb:1883-1885` — not persisted; `XML_UNSUPPORTED`; count 0. Roots also in C13 table via `municipal_nfse_xml` | PASS |
| C15 | create CT-e: no persist, 422, unsupported `[data-notice=error]` | `POST create CTe XML 422 unsupported copy` — ran, exit 0 | `spec/requests/supporting_documents_spec.rb:3925-3927` — count 0; `:unprocessable_content`; `error_notice_text` `eq` unsupported copy | PASS |
| C16 | GLOSSARY Nota fiscal / Chave de acesso / SEFAZ consulta name uploaded XML models | glossary example — ran, exit 0 | `spec/docs/glossary_spec.rb:27-44` — Nota includes NF-e, NFC-e, `NFCom (modelo 62)`, `NF3e (modelo 66)`, `national NFS-e`, `authorized XML`; Chave includes uploaded XML, `` `Id` ``, 44, 50, national NFS-e, typed chave, `photo decode remain 44`; SEFAZ includes NF-e/NFC-e and `not_to include` NFCom / NF3e / NFS-e | PASS |

## Coverage (recomputed)

Authority: `AuthorizedNfe::ACCEPTED_INF` (4), `OTHER_DFE` grouped as Landing (8), `ID_PREFIXES` (4), identify/create HTTP members in checks, C10 3×2 ports, refused identify (4), glossary entries (3).

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| accepted uploaded XML models (4) | `infNFe` C9 · `infNFCom` C1/C2 · `infNF3e` C3/C4 · `infNFSe` C5/C6 | NFC-e shares `infNFe`; no separate fixture (declared) |
| identify HTTP for accepted (4) | NFCom C1 · NF3e C3 · NFS-e C5 · NF-e C9 | - |
| create HTTP for new models (3) | NFCom C2 · NF3e C4 · NFS-e C6 | - |
| no-consulta ports (6) | identify×3 and insert×3 × not lookup / not fetch in C10 | - |
| refused XML at identify (4) | malformed C11 · incomplete `infNFe` C12 · CT-e C13 · municipal NFS-e C14 | - |
| other-DFe unsupported roots (8) | eight names in `unsupported other DFe roots` plus municipal `CompNfse`/`InfNfse` | - |
| create unsupported (1) | CT-e C15 | municipal create is the same `submit` map as C14 insert |
| glossary entries this cut amends (3) | Nota fiscal · Chave de acesso · SEFAZ consulta in C16 | - |
| Id prefixes on success (4) | `NFe` C9 · `NFCom` C1 · `NF3e` C3 · `NFS` C5 | - |

Landing leftover well-formed XML with no accepted inf and no other-DFe (`<nfe/>`) stays unreadable: asserted by existing `insert XML without ICMSTot vNF` on `xml_with_vnf`.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/authorized_nfe.rb` (`parse` / `unsupported?`); `SupportingDocument#submit` XML nil-map | model one case per member **and** request spec status / who | yes — ACCEPTED_INF + OTHER_DFE + unreadable vs unsupported at model; identify/create HTTP on C1–C9, C11–C15; submitter who-may on C7 |
| Decides, not reached across a boundary | private `accepted_amount` / `strip_id_prefix` / `calendar_date` | own layer, one case per member | yes — exercised through parse success/failure examples, not a second table |
| Entry point that decides nothing | `SupportingDocumentsController#identify` / `#create` / `#update` | request spec: accepted, each rejected, each error path named here | yes — C1–C9, C11–C15 HTTP; C8 PATCH |
| Instrumentation / pass-through | controller after the submit map | none of its own | yes — covered by consumer request specs |

## Swept existing

| Row | Cited constraint present? |
|---|---|
| idempotency: retried create is a second row; no unique chave | yes — `db/schema.rb` `t.string "chave"` with no unique index; `spec/models/supporting_document_spec.rb:671-677` `insert duplicate chave persists two SupportingDocuments` `count == 2` |
| authorization: focused org / submitter-own-row | yes — C7 |
| state transitions: `LOCKED_FIELDS` still locks uploaded_xml | yes — `app/models/supporting_document.rb:21` and `:367`; C8 |
| observability: `:base` notice plus error toast on 422 | yes — C11/C13/C14 request specs assert notice and `toast-host` |
| external-dependency: C10 no SEFAZ / public NFC-e | yes — C10 |

## Faults injected

Scratch worktree `/tmp/tlc-verify-uploaded-xml-nfcom` at HEAD; real tree porcelain matched empty baseline after remove.

| Mutation | Location | Killed |
|---|---|---|
| NFCom amount xpath `vNF` → `vLiq` | `app/models/authorized_nfe.rb` `accepted_amount` | yes — `parse NFCom 25680…` NoMethodError on nil |
| `unsupported?` always `false` | `app/models/authorized_nfe.rb` | yes — `unsupported other DFe roots` expected true, got false (`infCte`) |
| `SefazConsulta.current.lookup` after successful parse | `app/models/supporting_document.rb` submit | yes — C10 `not_to have_received(:lookup)` received 1 time |
| skip `errors.add(:base, LOCKED_FIELDS)` | `app/models/supporting_document.rb` lock branch | yes — `apply payee on NFCom…` expected LOCKED_FIELDS in `errors[:base]` |
| drop `NFCom (modelo 62), ` from Nota fiscal | `GLOSSARY.md` | yes — C16 `include("NFCom (modelo 62)")` |

## Gate

`bin/rspec` batched `--example-matches` over the four proof files — **32 examples, 0 failures** (each named proof appeared in documentation output).
