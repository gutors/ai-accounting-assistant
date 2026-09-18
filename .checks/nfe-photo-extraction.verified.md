# NF-e photo extraction Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: `fc0d56b7c0e8577ec5e8554df6f93aa4a9bc2392`..`fc8a9057ce74b7fd34934b92764ce655fabd038d`
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

HEAD `fc8a905`. Commits on the range: `0c2e787` docs(nfe): freeze photo-extraction checks; `fc8a905` feat(nfe): fill nota fields from the photo before typed entry. Flow is tlc-implement (`.checks/nfe-photo-extraction.md` present; no `.specs/features/nfe-photo-extraction/checks.md`). No `plan.md`.

## Binding sources

Step 1 (`ui` screens) input is empty. Checklist: "No design source for the screens. Profile stays `standard`." No source is marked binding. `screens.md` skipped.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| (none marked binding) | n/a — step 1 empty | n/a | n/a |

## Checks

Proofs run at `fc8a905` in one invocation: `bin/rspec spec/requests/supporting_documents_spec.rb spec/models/supporting_document_spec.rb spec/models/photo_symbols_spec.rb --format documentation --format json --out /tmp/nfe-photo-rspec.json` — 286 examples, 0 failures, 0 pending. All 88 named C1–C47 proofs exist (`rg -n` on those files) and passed in that JSON (`status=passed` each). Examples live in the feature diff (`fc0d56b..HEAD`), not in untouched pre-feature tests.

A first `-e` substring filter of joined names matched 0 examples (RSpec `-e` is literal include, not alternation) and exited 0 — discarded. The file-batch run above is the proof run.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | photo chave + identified XML → 15500 / 2026-05-11 / Padaria Central / chave, xml, 302 `/supporting_documents`, page copy | named examples passed | `supporting_documents_spec.rb:1550-1562` `:found` + `redirect_to("/supporting_documents")` + `amount_cents == 15500` + date + payee + chave + xml + `R$ 155,00` / `11/05/2026` / payee / chave · `supporting_document_spec.rb:913-917` same persist values | PASS |
| C2 | submitter same persist; GET 200 `R$ 155,00`; omits CNPJ / `Válido até` / `passphrase-secreta` | named example passed | `supporting_documents_spec.rb:1575-1582` 15500 + xml + `:ok` + `R$ 155,00` + three `not_to include`. Does not re-assert date/payee/chave | PASS |
| C3 | `.pdf` photo same chave + XML, 302 | named examples passed | `supporting_documents_spec.rb:1594-1596` `:found` + chave + xml · `supporting_document_spec.rb:926-928` chave + xml + 15500 | PASS |
| C4 | printed-digit chave after barcode/QR miss → chave + 15500 + xml | named examples passed | `supporting_documents_spec.rb:1607-1609` chave + 15500 + xml · `supporting_document_spec.rb:937-939` same. Fake `PhotoSymbols.set` returns a chave (same port as C1); Real printed-digit miss is Landing door 5 | PASS |
| C5 | photo chave `…781` wins typed `…321`; amount 15500 | named examples passed | `supporting_documents_spec.rb:1621-1622` chave `nfe_chave` + 15500 · `supporting_document_spec.rb:949-950` same | PASS |
| C6 | non-44 decode falls through to typed chave + XML | named examples passed | `supporting_documents_spec.rb:1633-1634` chave `nfe_chave` + xml · `supporting_document_spec.rb:959-960` same | PASS |
| C7 | recibo ignores photo chave; no chave/xml; PATCH payee 302 | named examples passed | `supporting_documents_spec.rb:1643-1648` `kind == "recibo"` + `chave` nil + xml not attached + `:found` + `Mercado Silva` · `supporting_document_spec.rb:970-973` same | PASS |
| C8 | uploaded XML chave wins photo chave; 15500 | named examples passed | `supporting_documents_spec.rb:1657-1658` 15500 + chave `nfe_chave` · `supporting_document_spec.rb:980-981` same | PASS |
| C9 | no certificate: persist chave + 15500; PATCH payee 302 | named examples passed | `supporting_documents_spec.rb:1667-1671` chave + 15500 + `:found` + `Mercado Silva` · `supporting_document_spec.rb:989-991` same | PASS |
| C10 | identified error: typed fields stay correctable; PATCH payee 302 | named examples passed | `supporting_documents_spec.rb:1683-1684` `:found` + `Mercado Silva` · `supporting_document_spec.rb:1001` payee. Amount/date not re-asserted | PASS |
| C11 | resumo locks three fields, photo remains, no xml; PATCH amount 422 lock copy | named examples passed | `supporting_documents_spec.rb:1696-1701` 15500 + photo + xml not + `:unprocessable_content` + lock copy · `supporting_document_spec.rb:1010-1015` 15500 + payee + photo + xml not + `LOCKED_FIELDS` | PASS |
| C12 | Real CODE-128 PNG → chave `…781` | named example passed | `photo_symbols_spec.rb:25-26` `result.chave == nfe_chave` + `qr_url` nil | PASS |
| C13 | Real QR PNG → NFC-e chave `…781` (modelo 65) + `sefaz.rs.gov.br` URL | named example passed | `photo_symbols_spec.rb:34-35` chave `nfce_chave` + `qr_url == nfce_qr_url` (helper `:16-18`) | PASS |
| C14 | public NFC-e fills 15500 / date / payee / chave, no xml, 302, page copy; PATCH amount 302 → 20000 | named examples passed | `supporting_documents_spec.rb:1711-1726` `:found` + redirect + 15500 + date + payee + chave + xml not + page copy + PATCH `:found` + 20000 · `supporting_document_spec.rb:1024-1027` 20000 after apply + `ORIGIN_NFC_E_PUBLIC` + xml not + chave | PASS |
| C15 | blank wrap key: 15500 then PATCH amount 302 | named examples passed | `supporting_documents_spec.rb:1741-1742` `:found` + 20000 · `supporting_document_spec.rb:1040` 20000 | PASS |
| C16 | expired A1: same correctable PATCH | named examples passed | `supporting_documents_spec.rb:1760-1761` `:found` + 20000 · `supporting_document_spec.rb:1056` 20000 | PASS |
| C17 | identified Error: public fill, PATCH amount 302 | named examples passed | `supporting_documents_spec.rb:1775-1776` `:found` + 20000 · `supporting_document_spec.rb:1068` 20000 | PASS |
| C18 | identified NotFound **and** WindowExpired: public fill, PATCH 302 | named examples passed | `supporting_documents_spec.rb:1784-1796` loop both results + `:found` + 20000 · `supporting_document_spec.rb:1075-1085` same loop | PASS |
| C19 | identified XML wins public; 15500 + xml; PATCH amount 422 lock copy | named examples passed | `supporting_documents_spec.rb:1810-1814` 15500 + xml + `:unprocessable_content` + lock copy · `supporting_document_spec.rb:1098-1100` 15500 + xml + `LOCKED_FIELDS` | PASS |
| C20 | CODE-128 no QR URL: typed payee `Padaria Central` (public would return `Mercado Silva`) | named examples passed | `supporting_documents_spec.rb:1824` payee `Padaria Central` · `supporting_document_spec.rb:1108` same | PASS |
| C21 | QR `http://127.0.0.1/nfce`: typed payee, no xml | named examples passed | `supporting_documents_spec.rb:1833-1834` payee + xml not · `supporting_document_spec.rb:1116-1117` same (model stubs tempting public fields; request does not) | PASS |
| C22 | QR `https://example.com/nfce`: typed payee, no xml | named examples passed | `supporting_documents_spec.rb:1843-1844` payee + xml not · `supporting_document_spec.rb:1125-1126` same | PASS |
| C23 | public Error: typed payee | named examples passed | `supporting_documents_spec.rb:1854` payee · `supporting_document_spec.rb:1134` payee | PASS |
| C24 | public partial three (amount only): typed payee | named examples passed | `supporting_documents_spec.rb:1867` payee · `supporting_document_spec.rb:1145` payee | PASS |
| C25 | public payee is emitente `Padaria Central`, not destinatário | named examples passed | `supporting_documents_spec.rb:1877-1878` `eq("Padaria Central")` + `not_to include("ONG Destinataria")` · `supporting_document_spec.rb:1153-1154` `eq` + `not_to eq`. Fake `Fields` has no destinatário member | PASS |
| C26 | field reading 15500 / date / emitente; 302; page `R$ 155,00` + Padaria, not dest; PATCH payee 302 | named examples passed | `supporting_documents_spec.rb:1887-1895` `:found` + page copy + omit dest + PATCH `:found` + `Mercado Silva` · `supporting_document_spec.rb:1162-1164` 15500 + payee + `ORIGIN_PHOTO` | PASS |
| C27 | CODE-128 + identified error → field reading 15500; PATCH payee 302 | named examples passed | `supporting_documents_spec.rb:1908-1910` `:found` + 15500 + `Mercado Silva` · `supporting_document_spec.rb:1175-1176` same | PASS |
| C28 | public error → field reading 15500; PATCH payee 302 | named examples passed | `supporting_documents_spec.rb:1922-1923` `:found` + 15500 · `supporting_document_spec.rb:1186-1187` 15500 + `Mercado Silva` | PASS |
| C29 | field-reading partial three uses typed amount `10000` + payee | named examples passed | `supporting_documents_spec.rb:1932-1933` 10000 + `Padaria Central` · `supporting_document_spec.rb:1206-1207` same | PASS |
| C30 | all extracts miss: none persisted, 422 `Informe valor, data e favorecido` | named examples passed | `supporting_documents_spec.rb:1941-1943` `:unprocessable_content` + copy + count 0 · `supporting_document_spec.rb:1213-1215` not persisted + `MISSING_FIELDS` + count 0 | PASS |
| C31 | recibo ignores field reading; payee stays `Padaria Central` | named examples passed | `supporting_documents_spec.rb:1952` payee · `supporting_document_spec.rb:1222` payee | PASS |
| C32 | field reading wins typed payee `Mercado Silva` | named examples passed | `supporting_documents_spec.rb:1961` `Padaria Central` · `supporting_document_spec.rb:1236` same | PASS |
| C33 | unreadable XML: none persisted, 422 `O XML da nota fiscal não pôde ser lido` | named examples passed | `supporting_documents_spec.rb:1972-1974` `:unprocessable_content` + copy + count 0 · `supporting_document_spec.rb:1250-1252` not persisted + `XML_UNREADABLE` + count 0 | PASS |
| C34 | PATCH chave on photo-filled keeps 15500, 302, `Usar dados da SEFAZ` | named examples passed | `supporting_documents_spec.rb:1987-1990` `:found` + 15500 + confirm copy · `supporting_document_spec.rb:1262-1263` 15500 + `sefaz_confirm_pending == true` | PASS |
| C35 | confirm photo-filled → 10000, PATCH amount 422 lock copy, 302, page `R$ 100,00` not `R$ 155,00` | named examples passed | `supporting_documents_spec.rb:2004-2011` `:found` + redirect + `R$ 100,00` + not `R$ 155,00` + `:unprocessable_content` + lock copy · `supporting_document_spec.rb:1274-1276` 10000 + `LOCKED_FIELDS` | PASS |
| C36 | PATCH chave on public-filled keeps 15500, 302, `Usar dados da SEFAZ` | named examples passed | `supporting_documents_spec.rb:2025-2028` `:found` + 15500 + confirm copy · `supporting_document_spec.rb:1287-1288` 15500 + pending | PASS |
| C37 | confirm public-filled → 10000; PATCH amount 422 lock copy | named examples passed | `supporting_documents_spec.rb:2043-2047` `:found` + 10000 + `:unprocessable_content` + lock copy · `supporting_document_spec.rb:1300-1302` 10000 + `LOCKED_FIELDS` | PASS |
| C38 | recibo→nota reads existing photo chave; 10000 / Mercado Silva / 2026-05-12 + xml; PATCH amount 422 | named examples passed | `supporting_documents_spec.rb:2061-2066` 10000 + payee + date + xml + `:unprocessable_content` · `supporting_document_spec.rb:1312-1317` same + `LOCKED_FIELDS` | PASS |
| C39 | nota→recibo drops chave, keeps amount, unlocks PATCH payee 302 | named examples passed | `supporting_documents_spec.rb:2079-2084` `recibo` + chave nil + 15500 + `:found` + `Mercado Silva` · `supporting_document_spec.rb:1326-1330` same. Date kept is not asserted | PASS |
| C40 | later A1 does not retro-consult; amount 15500; PATCH payee 302 | named examples passed | `supporting_documents_spec.rb:2098-2100` `:found` + 15500 + `Mercado Silva` · `supporting_document_spec.rb:1341-1342` same | PASS |
| C41 | closed month PATCH chave 422 `Mês fechado`; chave unchanged | named examples passed | `supporting_documents_spec.rb:2115-2117` `:unprocessable_content` + `Mês fechado` + chave nil · `supporting_document_spec.rb:1353-1354` `Month::CLOSED` + chave nil | PASS |
| C42 | unauthenticated POST 302 `/login`; none persisted | named example passed | `supporting_documents_spec.rb:2125-2127` `:found` + `redirect_to("/login")` + count 0 | PASS |
| C43 | submitter PATCH chave on another Account photo-filled → 404; no change | named example passed | `supporting_documents_spec.rb:2141-2142` `:not_found` + chave nil | PASS |
| C44 | duplicate photo chave persists two rows | named examples passed | `supporting_documents_spec.rb:2155` count 2 · `supporting_document_spec.rb:1365-1367` both persisted + count 2 | PASS |
| C45 | public and photo amounts are Integer 15500 | named examples passed | `supporting_document_spec.rb:1375-1376` `be_a(Integer)` + `eq(15500)` · `:1383-1384` same | PASS |
| C46 | 422 include form still has `amount` `date` `payee` `chave` `photo` | named example passed | `supporting_documents_spec.rb:2163-2169` `:unprocessable_content` + copy + `id="amount"` / `date` / `payee` / `chave` / `photo` | PASS |
| C47 | confirm errors: amount stays 15500, editable, 422 `Não foi possível consultar a SEFAZ` | named examples passed | `supporting_documents_spec.rb:2184-2188` `:unprocessable_content` + copy + 15500 + PATCH `:found` · `supporting_document_spec.rb:1394-1398` confirm false + 15500 + `Mercado Silva` | PASS |

## Coverage (recomputed)

Members taken from `SupportingDocument` constants / `submit` order, `PublicNfceConsulta.allowed?`, `PhotoSymbols::Real#scan`, and Landing doors — not from the author's Unproven column.

| Set (authority) | Member -> proof | Unproven |
| --- | --- | --- |
| chave obtain order (Landing door 3) | symbols chave (QR or CODE-128 Fake) C1 · printed-digit Fake C4 · typed after non-44 C6 · photo wins typed C5 | QR-over-CODE-128 when **both** decode (Landing: "QR wins over CODE-128"; Real `:55-56` skips CODE-128 only if `qr_chave`; C12 and C13 are single-symbol PNGs) |
| recibo ignores photo (2) | decode C7 · field reading C31 | - |
| uploaded XML vs photo chave (1) | C8 | - |
| identified from photo chave (4) | full XML C1 · resumo lock C11 · error + typed C10 · no certificate C9 | Timeout vs `Error` not split (C10 injects `SefazConsulta::Error`) |
| Real symbol decoders (2) | CODE-128 C12 · QR C13 | - |
| public when identified cannot deliver (6) | no cert C14 · blank wrap C15 · expired A1 C16 · identified Error C17 · NotFound + WindowExpired C18 · identified XML skips C19 | - |
| public not used or miss | no QR URL C20 · `127.0.0.1` C21 · `example.com` C22 · Error C23 · partial three C24 | Landing/code `allowed?`: `userinfo` present; `tpAmb=2` (`public_nfce_consulta.rb:28-37`). Named in Landing door 4, absent from checks |
| payee is emitente (2) | public C25 · photo C26 | - |
| field reading (6) | all three C26 · after identified error C27 · after public error C28 · partial typed C29 · all miss 422 C30 · wins typed C32 | - |
| unreadable XML vs photo (1) | C33 | - |
| confirm from correctable origins (5) | photo PATCH C34 · photo confirm C35 · public PATCH C36 · public confirm C37 · confirm error C47 | - |
| kind pipeline (2) | recibo→nota C38 · nota→recibo C39 | - |
| later A1 / closed month (2) | C40 · C41 | - |
| who may POST photo extract | coordinator C1 · unauthenticated C42 · submitter C2 | - |
| who may PATCH chave on photo-filled (2) | coordinator C34 · submitter other Account C43 | - |
| duplicate chave (1) | C44 | - |
| integer cents (2) | public C45 · photo C45 | - |
| include form on 422 (1) | C46 | - |
| `fields_origin` from code (5) | new `nfc_e_public` C14 · new `photo` C26; lock only `uploaded_xml`/`identified` (`supporting_document.rb:331-332`) via C14/C26 PATCH success vs C11/C19 lock | pre-existing `typed` / `uploaded_xml` / `identified` are #38, not this cut |
| startup assemblies | each port `current`/`Fake`/`Real` in one module; `reset!` → Fake; `build` → Real — `photo_symbols.rb:10-24`, `photo_fields.rb:6-19`, `public_nfce_consulta.rb:9-23` (same shape as `sefaz_consulta.rb:16-30`). Test `reset!` in `spec/rails_helper.rb:86-88`. Test current is Fake: `spec/config/application_spec.rb:29-41` | production `build` is Real by reading those lines; the test assembly cannot fail if `build` were swapped to Fake |

Claims naming status/route/shape C1–C11, C14–C44, C46, C47 each have a request-spec proof. C12, C13, C45 are model-only as the checklist states.

`fields_locked?` members from code: `uploaded_xml`, `identified` only — PATCH of the three on `photo` / `nfc_e_public` is C26 / C14.

## Test policy rows

Judged against the artifact's own `## Test policy` (follows `.cursor/rules/rails.mdc` 49–51), not a weaker house taste.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/supporting_document.rb` (`submit`/`apply`/`confirm_identified_sefaz`: chave order, origins, complete-triple, lock) | model case per member **and** request spec for status / who may call | yes — C1–C11, C14–C44, C46, C47 have both layers where the check names HTTP; enumerated members above have a model assertion each |
| Decides, not reached across a boundary | `app/models/photo_symbols.rb` Real (QR then CODE-128) | own-layer one case per decoder | yes — C12, C13 from fixture PNGs (same shape as `sefaz_consulta_spec` Real) |
| Entry point that decides nothing | `SupportingDocumentsController` create/update/confirm (`supporting_documents_controller.rb:8-68` forwards to insert/apply/confirm) | request spec accepted / rejected / error | yes — covered by the request proofs on this cut; controller adds no photo-extract branch |
| Instrumentation / pass-through | `PhotoFields::Real#read` always `Miss` (`photo_fields.rb:42-44`); Fake is the test port | none of its own | yes — C26+ go through `PhotoFields.current` Fake; Landing door 5 |

`PublicNfceConsulta.allowed?` is a decision inside the port, reached from `Fake#fetch` / `Real#fetch` during submit. Named members `127.0.0.1` and `example.com` are asserted at the SupportingDocument model (C21/C22 stub a tempting `Fields` result). There is no `public_nfce_consulta_spec`. Extra `allowed?` members (`userinfo`, `tpAmb=2`) have no case — coverage note, not an unmet row for the members the checklist enumerated.

## Swept existing

- observability: `filter_parameters` includes `:passw`, `:passphrase`, `:certificate` (`config/initializers/filter_parameter_logging.rb:6-8`). Constraint is present.
- Other Swept rows are checks or explicit not-in-scope; nothing to re-read in code for those.

## Faults injected

Scratch worktree `/tmp/nfe-photo-fault-scratch` at `fc8a905`. Real-tree porcelain before and after: empty. Scratch discarded (`git worktree remove --force`). Real tree unchanged.

| Mutation | Location | Killed |
|---|---|---|
| `photo_chave \|\| typed_chave` → `typed_chave \|\| photo_chave` | `supporting_document.rb:168` | yes — C5 model: expected `…781`, got typed `…321` (`supporting_document_spec.rb:949`) |
| `fields_locked?` also true for `photo` and `nfc_e_public` | `supporting_document.rb:331-332` | yes — C14 model: expected amount 20000 after PATCH, got 15500 (`:1024`) |
| `PublicNfceConsulta.allowed?` always `true` | `public_nfce_consulta.rb:25-40` | yes — C21 model: expected `Padaria Central`, got stubbed `Mercado Silva` (`:1116`) |
| `complete_triple?` always `true` | `supporting_document.rb:498-500` | yes — C24 model: expected `Padaria Central`, got `nil` (`:1145`) |
| Real skips QR (`payload = nil`) | `photo_symbols.rb:48` | yes — C13: expected NFC-e chave, got `nil` (`photo_symbols_spec.rb:34`) |

Five surfaces, five killed. No survivor.

## Gate

`bin/rspec spec/requests/supporting_documents_spec.rb spec/models/supporting_document_spec.rb spec/models/photo_symbols_spec.rb` — 286 passed, 0 failed (HEAD `fc8a905`).
