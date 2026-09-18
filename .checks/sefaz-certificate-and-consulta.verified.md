# SEFAZ certificate and identified consulta Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: `f7bff4c07d873824bfade371da73c4b26a450eb9`..`f89a86ed2d27d5a6b73f1d328c8ec5732618f999`
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

HEAD at start was `f89a86ed2d27d5a6b73f1d328c8ec5732618f999`. Round 1 was FAIL at `287da46`. Fix `287da46..f89a86e` is extra proofs only (two spec files; no product-code change). Step 1 (ui screens) input is empty — no source marked binding; screens.md skipped.

Proofs re-ran in full at `f89a86e`. Citations in files the fix did not touch are carried from `287da46`. Citations in `spec/models/supporting_document_spec.rb` and `spec/requests/supporting_documents_spec.rb` refreshed (line numbers moved). Coverage rows for confirm and wrap-key skip recomputed. Test policy re-judged for the unmet confirm row and rows whose proofs live in the touched spec files.

## Binding sources

carried from `287da46`

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| (none marked binding) | n/a — step 1 empty | n/a | n/a |

## Checks

Proofs run at `f89a86e` in one invocation: `unset BUNDLE_PATH && bin/rspec spec/requests/setup_spec.rb spec/requests/sefaz_certificates_spec.rb spec/models/organization_spec.rb spec/requests/supporting_documents_spec.rb spec/models/supporting_document_spec.rb spec/requests/close_spec.rb spec/models/sefaz_consulta_spec.rb spec/config/application_spec.rb --format json` — 312 examples, 0 failures. All 119 named C1–C69 proofs exist (`rg -n`) and passed in that JSON.

C1–C22 and C66–C67, C69: evidence carried from `287da46` (untouched files). C23–C65 and C68: citations verified at `f89a86e`.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | `/setup` 200, `Certificado SEFAZ`, `Nenhum certificado` | named example passed | carried `setup_spec.rb:45-47` | PASS |
| C2 | persist pfx titular `11222333000181` notAfter `2027-09-18`, 302 `/setup`, copy, no passphrase | named examples passed | carried `sefaz_certificates_spec.rb:20-30` · `organization_spec.rb:184-186` | PASS |
| C3 | `.p12` 302 and `11.222.333/0001-81` | named examples passed | carried `sefaz_certificates_spec.rb:41-44` · `organization_spec.rb:194-195` | PASS |
| C4 | `GET /sefaz_certificate` 404 without PKCS#12 bytes | named example passed | carried `sefaz_certificates_spec.rb:61-62` | PASS |
| C5 | wrong passphrase, no persist, 422 copy, still `Nenhum certificado` | named examples passed | carried `sefaz_certificates_spec.rb:73-76` · `organization_spec.rb:201-203` | PASS |
| C6 | e-CPF `39053344705` refused 422 `O certificado deve ser e-CNPJ A1 vigente` | named examples passed | carried `sefaz_certificates_spec.rb:87-89` · `organization_spec.rb:212-214` | PASS |
| C7 | notAfter `2026-05-10` on `2026-05-11` refused same copy | named examples passed | carried `sefaz_certificates_spec.rb:101-103` · `organization_spec.rb:226-227` | PASS |
| C8 | `.txt` refused same copy | named examples passed | carried `sefaz_certificates_spec.rb:115-117` · `organization_spec.rb:237-238` | PASS |
| C9 | PKCS#12 `> 1048576` 422, no persist | named examples passed | carried `sefaz_certificates_spec.rb:128-129` · `organization_spec.rb:247-248` | PASS |
| C10 | unauthenticated POST 302 `/login`, no persist | named example passed | carried `sefaz_certificates_spec.rb:138-141` | PASS |
| C11 | submitter POST 404, no persist | named example passed | carried `sefaz_certificates_spec.rb:154-155` | PASS |
| C12 | submitter `GET /setup` 404 omits titular / `Válido até` | named example passed | carried `setup_spec.rb:178-180` | PASS |
| C13 | second A1 titular `12345678000101` replaces first | named examples passed | carried `sefaz_certificates_spec.rb:172-173` · `organization_spec.rb:259-260` | PASS |
| C14 | `Remover` Turbo confirm `Remover o certificado SEFAZ?` | named example passed | carried `setup_spec.rb:190-191` | PASS |
| C15 | DELETE nulls slot, 302, `Nenhum certificado` | named examples passed | carried `sefaz_certificates_spec.rb:185-190` · `organization_spec.rb:271-274` | PASS |
| C16 | unauthenticated DELETE leaves cert, 302 `/login` | named example passed | carried `sefaz_certificates_spec.rb:203-205` | PASS |
| C17 | submitter DELETE leaves cert, 404 | named example passed | carried `sefaz_certificates_spec.rb:221-222` | PASS |
| C18 | setup omits org B titular | named example passed | carried `setup_spec.rb:206` | PASS |
| C19 | concurrent installs one consistent PKCS#12+passphrase | named example passed | carried `organization_spec.rb:314-316`. Model-only (no request spec) | PASS |
| C20 | blank wrap key 422 `O certificado não pôde ser guardado` | named examples passed | carried `sefaz_certificates_spec.rb:235-237` · `organization_spec.rb:283-284` | PASS |
| C21 | expired `Expirado em 11/05/2026`, no `Válido até` | named example passed | carried `setup_spec.rb:223-224` | PASS |
| C22 | install while month closed still persists 302 | named examples passed | carried `sefaz_certificates_spec.rb:250-252` · `organization_spec.rb:292-293` | PASS |
| C23 | uploaded XML fills 15500 / 2026-05-11 / Padaria Central / chave, 302, page copy, not dest | named examples passed | `supporting_documents_spec.rb:747-760` `:found` + 15500 / date / payee / chave + page copy / omit dest · `supporting_document_spec.rb:406-409` | PASS |
| C24 | typed `100,00` ignored, persist 15500 | named examples passed | `supporting_documents_spec.rb:209` · `supporting_document_spec.rb:123` | PASS |
| C25 | PATCH amount 422 lock copy, amount stays 15500 | named examples passed | `supporting_documents_spec.rb:770-772` · `supporting_document_spec.rb:424-425` | PASS |
| C26 | PATCH payee 422 same copy | named examples passed | `supporting_documents_spec.rb:782-784` · `supporting_document_spec.rb:432-433` | PASS |
| C27 | PATCH date 422 same copy | named examples passed | `supporting_documents_spec.rb:794-796` · `supporting_document_spec.rb:440-441` | PASS |
| C28 | PATCH observation 302, page includes `pago em dinheiro` | named examples passed | `supporting_documents_spec.rb:806-809` · `supporting_document_spec.rb:449` | PASS |
| C29 | malformed XML none persisted, 422 `O XML da nota fiscal não pôde ser lido` | named examples passed | `supporting_documents_spec.rb:817-819` · `supporting_document_spec.rb:455-457` | PASS |
| C30 | XML without `ICMSTot/vNF` same 422 | named examples passed | `supporting_documents_spec.rb:827-829` · `supporting_document_spec.rb:463-465` | PASS |
| C31 | pre-task XML blob payee PATCH 302, amount stays 15500 | named examples passed | `supporting_documents_spec.rb:841-843` · `supporting_document_spec.rb:474-476` | PASS |
| C32 | recibo typed then PATCH payee 302 | named examples passed | `supporting_documents_spec.rb:853-854` · `supporting_document_spec.rb:483` | PASS |
| C33 | recibo+xml 422 `Recibo não tem XML` | named examples passed | `supporting_documents_spec.rb:138-140` · `supporting_document_spec.rb:85-86` (model does not assert the copy; request does) | PASS |
| C34 | typed nota photo then PATCH payee 302, 15500 | named examples passed | `supporting_documents_spec.rb:864-866` · `supporting_document_spec.rb:490-491` | PASS |
| C35 | `dhEmi` `2026-05-11T23:30:00-03:00` → `document_on` `2026-05-11` | named example passed | `supporting_document_spec.rb:504` | PASS |
| C36 | chave+consulta XML fills fields, attaches xml, 302, page copy | named examples passed | `supporting_documents_spec.rb:878-889` · `supporting_document_spec.rb:512-516`. Does **not** PATCH-lock; lock for this origin is C64/C53/C55 | PASS |
| C37 | submitter same insert, GET 200 `R$ 155,00`, omits cert copy | named example passed | `supporting_documents_spec.rb:903-910`. Asserts 15500 + xml + 200 + omissions; does not assert `document_on` / `payee` | PASS |
| C38 | resumo persist three fields, photo, no xml, amount PATCH 422 | named examples passed | `supporting_documents_spec.rb:927-932` · `supporting_document_spec.rb:524-529` | PASS |
| C39 | resumo without files none, 422 `Envie a foto e/ou o XML` | named examples passed | `supporting_documents_spec.rb:945-947` · `supporting_document_spec.rb:537-538` | PASS |
| C40 | consulta XML without files attaches xml, 302, 15500 | named examples passed | `supporting_documents_spec.rb:957-959` · `supporting_document_spec.rb:546-548`. Date/payee not asserted | PASS |
| C41 | no cert stays typed, PATCH payee 302 | named examples passed | `supporting_documents_spec.rb:969-970` · `supporting_document_spec.rb:555-556` | PASS |
| C42 | expired cert stays typed | named examples passed | `supporting_documents_spec.rb:986-987` · `supporting_document_spec.rb:570` | PASS |
| C43 | removed cert stays typed | named examples passed | `supporting_documents_spec.rb:1000-1001` · `supporting_document_spec.rb:581` | PASS |
| C44 | consulta Error stays typed | named examples passed | `supporting_documents_spec.rb:1012-1013` · `supporting_document_spec.rb:590`. Injects `Error`, not `Timeout::Error` | PASS |
| C45 | Error without typed fields 422 `Informe valor, data e favorecido` | named examples passed | `supporting_documents_spec.rb:1023-1025` · `supporting_document_spec.rb:598-599` | PASS |
| C46 | NotFound **and** WindowExpired stay typed | named examples passed | `supporting_documents_spec.rb:1031-1038` loop both results · `supporting_document_spec.rb:604-610` | PASS |
| C47 | dotted chave stores 44 digits + XML | named examples passed | `supporting_documents_spec.rb:1053-1054` · `supporting_document_spec.rb:627-628` | PASS |
| C48 | not 44 digits 422 chave copy | named examples passed | `supporting_documents_spec.rb:1062-1064` · `supporting_document_spec.rb:634-635` | PASS |
| C49 | duplicate chave persists two | named examples passed | `supporting_documents_spec.rb:1075` · `supporting_document_spec.rb:644` | PASS |
| C50 | recibo+chave stores no chave, no xml, PATCH payee 302 | named examples passed | `supporting_documents_spec.rb:1085-1090` · `supporting_document_spec.rb:653-656` | PASS |
| C51 | uploaded XML wins over consulta `vNF` 100.00 | named examples passed | `supporting_documents_spec.rb:1102` · `supporting_document_spec.rb:664` | PASS |
| C52 | kind recibo purges xml/chave, unlocks payee | named examples passed | `supporting_documents_spec.rb:1113-1119` · `supporting_document_spec.rb:672-676` | PASS |
| C53 | recibo→nota consulta 10000 / Mercado Silva / 2026-05-12, then amount 422 | named examples passed | `supporting_documents_spec.rb:1132-1137` · `supporting_document_spec.rb:685-690` | PASS |
| C54 | PATCH chave keeps 15500, page `Usar dados da SEFAZ` | named examples passed | `supporting_documents_spec.rb:1149-1152` · `supporting_document_spec.rb:699-700` | PASS |
| C55 | confirm persists 10000, 302, page `R$ 100,00` not `R$ 155,00`, locks | named examples passed | `supporting_documents_spec.rb:1181-1186` Xml path · `supporting_document_spec.rb:721-723`. Extra (not named by C55): resumo confirm `supporting_document_spec.rb:734-739` · `supporting_documents_spec.rb:1199-1208` | PASS |
| C56 | confirm Error 422, 15500 editable | named examples passed | `supporting_documents_spec.rb:1268-1271` · `supporting_document_spec.rb:785-788` | PASS |
| C57 | no cert stores chave, omits `Usar dados da SEFAZ`, 15500 | named examples passed | `supporting_documents_spec.rb:1281-1284` · `supporting_document_spec.rb:795-797` | PASS |
| C58 | confirm already identified 302 unchanged | named examples passed | `supporting_documents_spec.rb:1297-1299` · `supporting_document_spec.rb:808-811` | PASS |
| C59 | closed month PATCH chave 422 `Mês fechado` | named examples passed | `supporting_documents_spec.rb:1313-1314` · `supporting_document_spec.rb:823-824` | PASS |
| C60 | submitter own no-month PATCH chave 302 | named example passed | `supporting_documents_spec.rb:1327-1328` | PASS |
| C61 | submitter other Account 404 | named example passed | `supporting_documents_spec.rb:1341-1342` | PASS |
| C62 | submitter month document 422 `Documento já pertence a um mês` | named example passed | `supporting_documents_spec.rb:1357-1359` | PASS |
| C63 | later A1 install does not retro-consult | named examples passed | `supporting_documents_spec.rb:1371-1373` · `supporting_document_spec.rb:833-834` | PASS |
| C64 | DELETE cert leaves identified lock | named examples passed | `supporting_documents_spec.rb:1386-1387` · `supporting_document_spec.rb:844` | PASS |
| C65 | expired cert leaves identified lock | named examples passed | `supporting_documents_spec.rb:1403-1404` · `supporting_document_spec.rb:858` | PASS |
| C66 | close with no certificate 302 closed | named example passed | carried `close_spec.rb:541-543` | PASS |
| C67 | close with expired certificate 302 closed | named example passed | carried `close_spec.rb:557-558` | PASS |
| C68 | `vNF` `155.00` is Integer 15500 | named example passed | `supporting_document_spec.rb:415-417` | PASS |
| C69 | blank wrap key: `/setup` 200 `Nenhum certificado`; close 302 | named examples passed | carried `setup_spec.rb:235-236` · `close_spec.rb:569-570` | PASS |

## Coverage (recomputed)

Rows whose authority the fix touched: `confirm_identified_sefaz` and wrap-key skip on insert — verified at `f89a86e`. Other rows carried from `287da46` (product code unchanged).

| Set | Members from authority | Proof | Unproven |
|---|---|---|---|
| certificate slot states | absent / valid / expired | C1 · C2 · C21 | - carried |
| PKCS#12 extensions | `.pfx` `.p12` | C2 · C3 | - carried |
| install refuses | wrong passphrase · e-CPF · expired leaf · not PKCS#12 · oversized · blank wrap | C5–C9 · C20 | - carried |
| who may POST `/sefaz_certificate` | coordinator · unauthenticated · submitter | C2 · C10 · C11 | - carried |
| who may DELETE `/sefaz_certificate` | coordinator · unauthenticated · submitter | C15 · C16 · C17 | - carried |
| GET `/sefaz_certificate` | 404 | C4 | - carried |
| authorized XML keys | `ICMSTot/vNF` · `emit/xNome` · `ide/dhEmi` calendar · `@Id` without `NFe` | C23 · C35 | - carried |
| `fields_origin` / lock | `uploaded_xml` C25–C27 · `identified` full XML C64/C53/C55 · `identified` resumo C38 · typed C34 · pre-task nil C31 · recibo C32 | those | - carried |
| consulta insert outcomes | Xml C36/C40 · Resumo C38/C39 · Error C44/C45 · NotFound+WindowExpired C46 · skip no/expired/removed cert C41–C43 · **skip stored cert + blank wrap key** extra examples `insert chave with stored certificate and blank wrap key stays typed` (`supporting_document_spec.rb:772-775`) / `POST chave with stored certificate and blank wrap key stays typed` (`supporting_documents_spec.rb:1250-1254`) | those | Timeout still collapsed to Error (`consult_identified` rescue); insert proofs inject `Error` only — carried |
| SOAP `parse_response` cStat | 138+infNFe Xml · 138+resNFe Resumo · 137 NotFound · other Error | `sefaz_consulta_spec.rb:13,21,31,35` | `WindowExpired` is a port type (`sefaz_consulta.rb:10`) never returned by `parse_response` — carried |
| chave digits | 44 after strip · not 44 | C47 · C48 | - carried |
| kind pipeline | nota→recibo · recibo→nota | C52 · C53 | - carried |
| `confirm_identified_sefaz` | already identified C58 · Xml apply C55 · else/Error C56 · **Resumo apply** extra `confirm identified SEFAZ from resumo persists 10000 and locks` (`supporting_document_spec.rb:734-739`) / `… and redirects` (`supporting_documents_spec.rb:1199-1208`) · **blank chave** extra `… with blank chave keeps 15500 editable` (`:746-749`) / `… returns 422` (`:1218-1220`) · **Xml parse fail** extra `… when xml cannot be parsed keeps 15500 editable` (`:759-762`) / `… returns 422` (`:1234-1238`) | those | `month&.closed?` early return (`supporting_document.rb:272-274`) still has no confirm case (C59 is apply-chave, not confirm) |
| submitter chave PATCH | own no-month · other Account · has month | C60–C62 | - carried |
| lock vs certificate lifecycle | no retro C63 · remove keeps lock C64 · expired keeps lock C65 | C63–C65 | - carried |
| close-for-send A1 optional | no cert · expired · blank wrap + no cert | C66 · C67 · C69 | - carried |
| integer cents | `155.00` → Integer `15500` | C68 | - carried |
| startup wrap-key | one `WrapKey` module; install `organization.rb:71`; consulta `supporting_document.rb:352` now also hit by the blank-wrap insert examples | call sites + C20/C69 + new wrap-key skip examples | file `app/models/wrap_key.rb` exists; this verifier could not open it (repo hook). Test consulta assembly is Fake (`application_spec.rb:25-26`); app `SefazConsulta.build` is Real — carried |

Checklist Coverage prose that C1–C22 all have request-spec proofs still overclaims C19 (model-only concurrent). Frozen checklist; carried.

## Test policy rows

verified at `f89a86e` for the previously unmet confirm row and for rows whose proofs sit in the touched spec files. Other rows carried from `287da46`.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `app/models/organization.rb` install/remove | model + request; one case per refuse/who | **yes** — carried (C2–C22 except C19 concurrent) |
| Decides, reached across a boundary | `app/models/supporting_document.rb` submit/apply | model + request per enumerated member | **yes** — re-judged; C23–C54, C57, C59, C63–C65 still have model + request. New wrap-key skip examples add model + request for stored-cert + blank wrap |
| Decides, reached across a boundary | `SupportingDocument#confirm_identified_sefaz` | model + request; one case per branch | **yes** — Round 1 FAIL resolved. Xml/error/already-identified C55/C56/C58; **Resumo success** extra examples both layers; blank chave and Xml parse-fail extra examples both layers. Closed-month confirm still unenumerated (not a named check) |
| Decides, not reached across HTTP | `SefazConsulta::Real.parse_response` | model, one case per cStat | **yes** — carried for 137 / 138 Xml / 138 Resumo / other. WindowExpired not a `parse_response` branch |
| Entry point, decides nothing | `SefazCertificatesController`, `sefaz_confirm` | request status / who | **yes** — C4, C10, C11, C16, C17, C55, C56, C58 plus new confirm 422s (`:unprocessable_content` + `Não foi possível consultar a SEFAZ` at `supporting_documents_spec.rb:1218-1219` and `:1234-1235`). Submitter/unauthenticated confirm still not a named check |
| Instrumentation | controller pass-through after model | none of its own | follow |

`.cursor/rules/rails.mdc:49-51` is the declared allocator.

## Faults injected

Scratch worktree `/tmp/tlc-verify-sefaz-f89a86e` at `f89a86e`. Real-tree porcelain baseline before/after: `M AGENTS.md`, `M README.md`, `?? .checks/sefaz-certificate-and-consulta.verified.md`, `?? .tasks/unmatched-docs-and-restore.md`. Discarded with `git worktree remove --force`. Never mutated the real tree. Round 1 faults on untouched product code carried (all killed). This round re-injected on surfaces the fix **created** (new assertions).

| Mutation | Location | Covering proof | Killed |
|---|---|---|---|
| Resumo persist `resumo.amount_cents` → existing `amount_cents` | `supporting_document.rb` confirm Resumo branch | `confirm identified SEFAZ from resumo persists 10000 and locks` | yes — expected 10000, got 15500 (`supporting_document_spec.rb:734`) |
| dropped `return fail_confirm unless parsed` | `supporting_document.rb:282` | `confirm identified SEFAZ when xml cannot be parsed keeps 15500 editable` | yes — `NoMethodError` on nil `parsed.amount_cents` |
| `return fail_confirm if chave.blank?` → `return true if chave.blank?` | `supporting_document.rb:277` | `confirm identified SEFAZ with blank chave keeps 15500 editable` | yes — expected false, got true (`:746`) |
| removed `return unless WrapKey.present?` | `supporting_document.rb:352` | `insert chave with stored certificate and blank wrap key stays typed` | **no** — equivalent: `unwrap_sefaz_pkcs12` still raises `WrapKey::Missing` (rescued to Error) or returns nil; lookup never runs; typed 15500 still holds |
| Resumo `fields_origin: ORIGIN_IDENTIFIED` → `ORIGIN_TYPED` | `supporting_document.rb` confirm Resumo persist | `confirm identified SEFAZ from resumo persists 10000 and locks` | yes — expected LOCKED_FIELDS, got `[]` (`:739`) |

Four of five new-surface mutants killed. The wrap-key `present?` guard is redundant with unwrap/Missing for this observable (same shape as Timeout collapsed to Error). The new tests still assert typed + no xml + payee PATCH 302.

## Swept existing

carried from `287da46`; re-read this round: `filter_parameters` includes `:passw` and `:certificate` (`config/initializers/filter_parameter_logging.rb:7`), plus `:passphrase`. Constraint is present.

## Gate

`unset BUNDLE_PATH && bin/rspec` of the eight spec files above at `f89a86e` — 312 passed, 0 failed.

## Ranked remaining gaps

Round 1 gaps 1, 2, 4 resolved by extra proofs. Carried:

1. `SefazConsulta::WindowExpired` is never produced by `Real.parse_response`; only Fake injects it (C46). Landing still names window-expired as a port return. Unchanged in product code.
2. Precision: C37 and C40 do not assert `document_on` / `payee` for “the same / those three fields”. Frozen checklist.
3. Checklist Coverage prose lists C19 among request-spec claims; C19 is model-only. Frozen checklist.
4. `WrapKey.present?` on `consult_identified` is not uniquely discriminated from unwrap/`WrapKey::Missing` (equivalent mutant). Observable skip is proven.
5. `confirm_identified_sefaz` `month&.closed?` branch has no confirm case (C59 is apply-chave). Not a Round 1 ranked gap; residual.
