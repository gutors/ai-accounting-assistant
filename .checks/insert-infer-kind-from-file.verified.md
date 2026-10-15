# Insert infer kind from file Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: `13010f1`..`e404eac` (`13010f1..HEAD`)
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

HEAD `e404eac`. Range commits: `c53af03` chore: extract insert-infer-kind-from-file checks; `3f66022` feat: infer blank insert kind from the uploaded file; `e404eac` test: isolate QR URL as a blank-kind NF signal. Checklist `.checks/insert-infer-kind-from-file.md` present. No `plan.md`.

Scope: proofs re-run in full at `e404eac`. Other sections: fix diff `e404eac` (isolated qr_url-without-chave examples) plus round-1 non-PASS (surviving `qr_url.present?` mutant; Test policy qr_url member; Coverage qr_url arm). PASS check citations carried from `3f66022` with line numbers refreshed where those two spec files grew.

## Binding sources

carried from `3f66022`. Step 1 (`ui` screens) input is empty. Checklist: "No design source. Not raised to `ui`." No source is marked binding. Designed-screen enumeration skipped. Fix did not touch the interface.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| (none marked binding) | n/a — step 1 empty | n/a | n/a |

## Checks

Proofs run at `e404eac` in one invocation:

`bin/rspec spec/requests/supporting_documents_spec.rb spec/models/supporting_document_spec.rb` with twenty-five `-e` names (RSpec `-e` is substring include) `--format json`.

JSON summary: **25 examples, 0 failures, 0 pending**. Each named C1–C12 proof exists (`rg -n` on those two spec files) and `status=passed`. Examples are in `13010f1..HEAD`.

`nfe_chave` at the assertion sites is `"43260511222333000181550010000000011123456781"` (`supporting_documents_spec.rb:19-21`, `supporting_document_spec.rb:28-30`). `nfce_chave` / `nfce_qr_url` / `other_chave` match the checklist literals (`spec/support/photo_extract_helpers.rb:2-12`). `BAD_KIND` is `"Informe se é nota fiscal ou recibo"` (`app/models/supporting_document.rb:10`). `:found` is HTTP 302; `:unprocessable_content` is HTTP 422.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | empty kind + JPEG whose symbols chave is that 44-digit value → persist `nota_fiscal` + that chave; 302 to `/supporting_documents`; GET `[data-cell=kind]` `Nota fiscal` | named examples passed at `e404eac` | carried from `3f66022`: `supporting_documents_spec.rb:2921-2929` `:found` + `redirect_to("/supporting_documents")` + `count == 1` + `kind == "nota_fiscal"` + `chave == nfe_chave` + `at_css('[data-cell="kind"]').text` `== "Nota fiscal"` · `supporting_document_spec.rb:1109-1111` `count == 1` + `kind == "nota_fiscal"` + `chave == nfe_chave` | PASS |
| C2 | empty kind + JPEG miss (`chave`/`qr_url` nil) → persist `recibo`, `chave` nil, no XML; 302; GET kind `Recibo` | named examples passed at `e404eac` | carried from `3f66022`: `supporting_documents_spec.rb:2940-2948` `:found` + `count == 1` + `kind == "recibo"` + `chave` nil + `xml` not attached + cell `"Recibo"` · `supporting_document_spec.rb:1118-1121` same persist shape | PASS |
| C3 | empty kind + authorized XML, no photo → `nota_fiscal`, that chave, `amount_cents` `15500`, `fields_origin` `uploaded_xml`, 302 | named examples passed at `e404eac` | carried from `3f66022`: `supporting_documents_spec.rb:2956-2962` `:found` + `count == 1` + those four fields · `supporting_document_spec.rb:1127-1130` same | PASS |
| C4 | empty kind + that XML + JPEG whose photo chave is `…21987654321` → persisted chave is XML `…11123456781`, kind `nota_fiscal`, 302 | named examples passed at `e404eac` | carried from `3f66022`: `supporting_documents_spec.rb:2973-2976` `:found` + `kind == "nota_fiscal"` + `chave == nfe_chave` · `supporting_document_spec.rb:1137-1138` same | PASS |
| C5 | empty kind + JPEG with NFC-e `qr_url` and 44-digit chave → `nota_fiscal` and that chave; extra proofs: same POST/insert with `chave` nil and that `qr_url` → `nota_fiscal` | named examples passed at `e404eac` | with chave: `supporting_documents_spec.rb:2988-2989` `kind == "nota_fiscal"` + `chave == nfce_chave` · `supporting_document_spec.rb:1145-1146` same. without chave (`e404eac`): `supporting_documents_spec.rb:2994` `chave: nil, qr_url: nfce_qr_url` + `:3000` `kind == "nota_fiscal"` · `supporting_document_spec.rb:1150` same stub + `:1153` `kind == "nota_fiscal"` | PASS |
| C6 | empty kind, typed triple, neither file → no row, 422, notice and error toast `Informe se é nota fiscal ou recibo` | named examples passed at `e404eac` | carried from `3f66022`, lines refreshed: `supporting_documents_spec.rb:3008-3013` `count == 0` + `:unprocessable_content` + `error_notice_text == BAD_KIND` + toast `"error"` includes `BAD_KIND`. Helper `error_notice_text` reads `p[role="alert"][data-notice="error"]` (`page_helpers.rb:7-12`) · `supporting_document_spec.rb:1159-1161` not persisted + `count == 0` + `errors[:base]` includes `BAD_KIND` | PASS |
| C7 | posted `recibo` + JPEG that would decode a chave → persist `recibo`, `chave` nil, no XML | named examples passed at `e404eac` | carried from `3f66022`, lines refreshed: `supporting_documents_spec.rb:3023-3025` `kind == "recibo"` + `chave` nil + xml not attached · `supporting_document_spec.rb:1168-1170` same | PASS |
| C8 | posted `nota_fiscal` + JPEG miss → persist `nota_fiscal` (not `recibo`) | named examples passed at `e404eac` | carried from `3f66022`, lines refreshed: `supporting_documents_spec.rb:3034` `kind == "nota_fiscal"` · `supporting_document_spec.rb:1177` same | PASS |
| C9 | posted `invoice` + JPEG + typed triple → no row, 422, same BAD_KIND notice/toast | named examples passed at `e404eac` | carried from `3f66022`, lines refreshed: `supporting_documents_spec.rb:3042-3047` `count == 0` + `:unprocessable_content` + notice/toast `BAD_KIND` · `supporting_document_spec.rb:1183-1185` not persisted + `BAD_KIND` | PASS |
| C10 | empty kind + JPEG chave, no cert, PhotoFields triple, no typed triple → persist those values, `fields_origin` `photo`, kind `nota_fiscal`; PATCH payee `Mercado Silva` is 302 | named examples passed at `e404eac` | carried from `3f66022`, lines refreshed: `supporting_documents_spec.rb:3058-3065` kind/amount/date/payee/`"photo"` + `patch` `:found` + payee `"Mercado Silva"` · `supporting_document_spec.rb:1194-1198` same persist + `apply(payee:)` | PASS |
| C11 | empty kind + JPEG miss + typed triple, PhotoFields would return `Mercado Silva` → payee `Padaria Central`, `fields_origin` `typed` | named examples passed at `e404eac` | carried from `3f66022`, lines refreshed: `supporting_documents_spec.rb:3078-3079` payee + `"typed"` · `supporting_document_spec.rb:1206-1207` same | PASS |
| C12 | empty kind + JPEG → `PhotoSymbols.current#scan` with those bytes; persist, not `BAD_KIND` | named example passed at `e404eac` | carried from `3f66022`, lines refreshed: `supporting_document_spec.rb:1212-1219` `receive(:scan).with(hash_including(bytes: "jpeg-bytes", filename: "recibo.jpg"))` + `be_persisted` + errors omit `BAD_KIND` | PASS |

## Coverage (recomputed)

Members taken from Landing door 1 and `SupportingDocument#submit` (`app/models/supporting_document.rb:105-177`), not from the author’s table. `e404eac` did not change classify code; qr_url arm recomputed because round 1 left it unproven and the fix added proofs.

| Set | Member | Proof that asserts it | Unproven |
|---|---|---|---|
| blank-kind classify | empty + XML → `nota_fiscal` | C3 | - |
| blank-kind classify | empty + photo, 44-digit `chave` → `nota_fiscal` | C1 | - |
| blank-kind classify | empty + photo, `qr_url` present (chave not required) → `nota_fiscal` | C5 without-chave: `chave: nil, qr_url: nfce_qr_url` then `kind == "nota_fiscal"` (`supporting_documents_spec.rb:2994,3000`; `supporting_document_spec.rb:1150,1153`) | - |
| blank-kind classify | empty + photo, `qr_url` with chave (checklist row) | C5 with-chave | - |
| blank-kind classify | empty + photo miss → `recibo` | C2 | - |
| blank-kind classify | empty, no file → `BAD_KIND` | C6 | - |
| posted kind kept | `recibo` kept despite photo chave | C7 | - |
| posted kind kept | `nota_fiscal` kept on photo miss | C8 | - |
| posted kind kept | garbage `invoice` → `BAD_KIND` (no infer) | C9 | - |
| XML vs photo chave when kind empty | XML chave wins | C4 | - |
| field path after infer | NF `PhotoFields` `photo` then correctable | C10 | - |
| field path after infer | recibo typed ignores PhotoFields payee | C11 | - |
| field path after infer | scan invoked on insert photo | C12 | - |
| startup config assemblies | none added this cut | n/a | n/a |

HTTP claims C1–C4, C6–C11 have request-spec proofs. C5 and C12 do not name an HTTP status in the original claim; C12 is model-only as the checklist states. The new C5 request example asserts kind at HTTP.

## Test policy rows

Re-judged the unmet row (qr_url member) plus the row classifying `supporting_document.rb` / insert HTTP. Other rows carried from `3f66022`.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/supporting_document.rb` `#submit` / `.insert` | model **and** request; one asserted case per enumerated member; status / who may call at the boundary | **yes** — qr_url-as-NF-signal now has model + request cases that fail when `qr_url.present?` is dropped (`insert empty kind photo QR without chave persists nota_fiscal`, `POST empty kind photo QR without chave infers nota_fiscal`). Other classify/posted-kind members still have model + request (C1–C4, C6–C11) |
| Decides, not reached across a boundary | C12 scan call-order | model only | yes — C12 model example (carried from `3f66022`) |
| Entry point that decides nothing | (no new decider at HTTP) | request spec | n/a — `create` is pass-through |
| Instrumentation / pass-through | `SupportingDocumentsController#create` (`supporting_documents_controller.rb:12-30`) | none of its own; consumer covers 302/422 | yes — C1–C4, C6–C11 request examples (carried from `3f66022`) |

## Swept (existing / n/a)

carried from `3f66022`. `e404eac` did not change product code.

| Row | Cited constraint in code? |
|---|---|
| validation: file type/size/`XML_UNREADABLE` stay existing | yes — `supporting_document.rb:123-140`, `186-190` (`OVERSIZE`, `PHOTO_TYPE`, `XML_TYPE`, `XML_UNREADABLE`) |
| idempotency: retried POST second row, no unique chave (#51 C44) | yes — `supporting_documents_spec.rb:2559-2569` `POST duplicate photo chave persists two SupportingDocuments` `count == 2` |
| authorization: focused organization; submitter insert unchanged | yes — `supporting_documents_controller.rb:2` `require_focused_organization`; create still `SupportingDocument.insert` pass-through |
| concurrency n/a | policy; nothing to disprove |
| data lifecycle n/a | no migration in the range |
| observability: no new OCR/photo-byte log; `filter_parameters` unchanged | yes — `config/initializers/filter_parameter_logging.rb:6-8` still `:passw, :passphrase, :email, …` |
| state: posted kind unchanged; infer only on blank insert | yes — `supporting_document.rb:105-116` garbage/persisted → `BAD_KIND` without infer; C7/C8 |

## Faults injected

Round-1 killed mutants (always-recibo, always-NF, XML→recibo, skip scan) carried from `3f66022` — classify code unchanged in `e404eac`. Re-injected the surviving mutant on the surface the fix added.

Scratch worktree `/tmp/tlc-verify-insert-infer-r2` at `HEAD`. Real-tree porcelain `?? .checks/insert-infer-kind-from-file.verified.md` before and after. Mutations only in scratch; discarded (`git worktree remove --force`). Scratch gone.

| Mutation | Location | Killed |
|---|---|---|
| infer photo always `recibo` (drop chave/QR → NF) | `supporting_document.rb` classify `if` | yes — carried from `3f66022` (C1) |
| infer photo always `nota_fiscal` (drop miss → recibo) | same `if` | yes — carried from `3f66022` (C2) |
| blank-kind XML sets `next_kind = "recibo"` instead of `"nota_fiscal"` | `elsif incoming_xml` | yes — carried from `3f66022` (C3) |
| skip `PhotoSymbols.current.scan` on infer (empty Symbols) | infer_from_photo scan | yes — carried from `3f66022` (C12) |
| drop `\|\| photo_symbols.qr_url.present?` (chave-only NF) | `supporting_document.rb:173` in scratch | **yes** — C5 without-chave request expected `"nota_fiscal"`, got `"recibo"` (`supporting_documents_spec.rb:3000`); C5 without-chave model same (`supporting_document_spec.rb:1153`). 2 examples, 2 failures |

## Gate

`bin/rspec` (25 named C1–C12 examples) — 25 passed, 0 failed, 0 pending at `e404eac`.
