# Supporting-document insert deepen Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: b17a52adf24ff9f00031e4ece2e80400208f3fcb..715244f10458f774705144c98628b8bdbf34dfea
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

carried from `0497b30`. No source marked binding. Step 1 empty (fix did not touch the interface).

## Checks

Proofs re-run in full at HEAD (`715244f`): one `bin/rspec spec/models/supporting_document_spec.rb spec/models/organization_spec.rb` with the fifteen checklist `-e` names. Exit 0, **15 examples, 0 failures**. Each `-e` name exists once in those spec files (`rg`). Specs sit in the feature diff. Citations for `supporting_document_spec.rb` refreshed at `715244f`; `organization_spec.rb` carried from `0497b30`.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | recibo insert persists Integer `15500`, origin `typed`, photo, no XML, `chave` nil | `-e "insert recibo jpg persists 15500 typed photo no xml chave nil"` ran, exit 0 | `spec/models/supporting_document_spec.rb:62-68` — `eq("recibo")`, `be_a(Integer)`, `eq(15500)`, `eq("typed")`, `photo` attached, `xml` not attached, `chave` nil | PASS |
| C2 | XML insert `15500` / `uploaded_xml` / blob; apply `200,00` keeps `15500` and locked copy | `-e "insert authorized XML persists 15500 uploaded_xml blob and apply 200,00 keeps 15500"` ran, exit 0 | `spec/models/supporting_document_spec.rb:450-458` — `eq(15500)`, `eq(Date.new(2026, 5, 11))`, `eq("Padaria Central")`, chave, `eq("uploaded_xml")`, xml attached, `include("Valor, data e favorecido vêm da nota e não podem ser alterados")`, reload `eq(15500)` | PASS |
| C3 | photo chave + consulta XML → `15500`, `identified`, XML, not pending | `-e "insert photo chave with consulta XML persists 15500 identified xml not pending"` ran, exit 0 | `spec/models/supporting_document_spec.rb:986-990` — `eq(15500)`, chave, `eq("identified")`, xml attached, `sefaz_confirm_pending` `eq(false)` | PASS |
| C4 | apply chave on typed nota keeps `15500`, pending, not `identified` | `-e "apply chave on typed nota keeps 15500 pending not identified"` ran, exit 0 | `spec/models/supporting_document_spec.rb:764-766` — `eq(15500)`, `sefaz_confirm_pending` `eq(true)`, `fields_origin` `not_to eq("identified")` | PASS |
| C5 | photo fields → `15500` origin `photo`; apply payee `Mercado Silva` | `-e "insert photo field reading persists 15500 origin photo"` ran, exit 0 | `spec/models/supporting_document_spec.rb:1301-1306` — triple + `eq("photo")` then `eq("Mercado Silva")` | PASS |
| C6 | NFC-e public → `15500` / `nfc_e_public` / no XML; apply `200,00` → `20000` | `-e "insert NFC-e QR public consulta persists 15500 origin nfc_e_public"` ran, exit 0 | `spec/models/supporting_document_spec.rb:1158-1164` — triple, `eq("nfc_e_public")`, xml not attached, then `eq(20000)` | PASS |
| C7 | Real symbols+fields: `PhotoOcr.text` at most once | `-e "insert Real photo OCR text is invoked at most once"` ran, exit 0 | `spec/models/supporting_document_spec.rb:996` — `expect(PhotoOcr).to receive(:text).once.and_call_original`. Covers `insert` only (`apply` shares `submit`). | PASS |
| C8 | Real QR + identified XML: `PhotoOcr.text` not invoked | `-e "insert Real QR identified XML does not invoke PhotoOcr text"` ran, exit 0 | `spec/models/supporting_document_spec.rb:1018` — `expect(PhotoOcr).not_to receive(:text)` | PASS |
| C9 | pkcs12 nil table; skip `lookup` on insert/apply/confirm; lookup gets PKCS12 + 44-digit chave | six `-e` names ran, exit 0 | Nil/PKCS12 carried from `0497b30`: `organization_spec.rb:201` `be_nil`; `:213` `be_nil`; `:222` `be_nil`; `:230` `be_a(OpenSSL::PKCS12)`. Skip: `supporting_document_spec.rb:1036-1040` persist `15500`, payee `Mercado Silva`, `not_to have_received(:lookup)`. Args: `:1049-1051` `pkcs12: an_instance_of(OpenSSL::PKCS12)`, `chave: a_string_matching(/\A\d{44}\z/)`. Unwrap-miss example uses `SEFAZ_WRAP_KEY` nil (`WrapKey.present?`), not blank ciphertext. | PASS |
| C10 | confirm → `10000` / `identified` / not pending; no symbols/fields/NFC-e | `-e "confirm identified SEFAZ persists 10000 identified without photo pipeline"` ran, exit 0 | `spec/models/supporting_document_spec.rb:797-805` — `not_to receive` scan/read/fetch; `eq(10000)`, `eq("identified")`, `sefaz_confirm_pending` `eq(false)` | PASS |

## Coverage (recomputed)

persist `fields_origin` recomputed at `715244f`. Authority: checklist Coverage row (the cut names the set) joined to `SupportingDocument::ORIGIN_*` (`app/models/supporting_document.rb:20-24`: `typed`, `uploaded_xml`, `identified`, `photo`, `nfc_e_public`). Each member is asserted as a stored string literal in C1–C3, C5–C6, C10 (C4 asserts not `identified`).

Other Coverage rows carried from `0497b30` (fix did not change those authorities).

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| persist `fields_origin` this cut names (5) | `typed` C1 `eq("typed")` · `uploaded_xml` C2 `eq("uploaded_xml")` · `identified` C3/C10 `eq("identified")` · `photo` C5 `eq("photo")` · `nfc_e_public` C6 `eq("nfc_e_public")` | - |
| apply-chave pending vs identified (1) | pending and not `identified` C4 | - |
| OCR invocations on Real submit (2) | needed: at most once C7 · QR+identified: zero C8 | `#apply` not a separate Real OCR example (same `#submit`) |
| pkcs12 exposure nil (3 named) | no titular C9 · expired C9 · wrap missing C9 (`unwrap miss` example) | blank-ciphertext unwrap with wrap present (Landing also names “unwrap yields nothing”) |
| pkcs12 exposure PKCS12 (1) | valid A1 C9 | - |
| skip `lookup` when nil (3) | `insert` · `#apply` · `confirm_identified_sefaz` in one C9 example (no-titular org) | expired / wrap-miss skip not asserted on `SupportingDocument` |
| `lookup` args when PKCS12 (2) | `OpenSSL::PKCS12` · `chave: a_string_matching(/\A\d{44}\z/)` C9 | - |
| confirm does not re-run (3) | scan · read · fetch C10 | - |
| startup config assemblies | no new process setting | - |

No check names a status, route, or response shape. Round 1 note that 44-digit length was not asserted at `have_received` is closed at `715244f`.

## Test policy rows

carried from `0497b30`. Fix touched `spec/models/supporting_document_spec.rb` only; policy classifies app models, not spec files. No row was unmet in Round 1.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/supporting_document.rb` (`#submit` / `#insert` / `#apply` / `confirm_identified_sefaz`) | model C1–C6, C10 **and** existing HTTP | Model examples above. Boundary already in `spec/requests/supporting_documents_spec.rb`. This cut adds no HTTP claim. Met. |
| Decides, not reached across a boundary | `app/models/organization.rb` `#sefaz_pkcs12` | model C9 nil/PKCS12 table | Four organization examples. Met. |
| Entry point that decides nothing | none new | - | n/a |
| Instrumentation / pass-through | `SupportingDocumentsController` create/update/sefaz_confirm | none of its own | Forwards to insert/apply/confirm. Covered by consumer + existing request specs. Met. |

## Swept existing

carried from `0497b30` (fix did not touch those citations).

- validation: `MAX_BYTES` / `MISSING_FIELDS` / `CHAVE_DIGITS` still on `SupportingDocument` (`app/models/supporting_document.rb:2,9,18,174,286,490`)
- failure modes: `XML_UNREADABLE` still added on unreadable XML (`supporting_document.rb:136`); `consult_identified` still returns `SefazConsulta::Error` on timeout/PKCS12 (`:439-440`); `PhotoOcr.text` still `""` on miss (`photo_ocr.rb:25,32,37`)
- persist: `persist_document` still the attach path (`supporting_document.rb:405-426`)
- observability: `filter_parameters` still includes `:passphrase` and `:certificate` (`config/initializers/filter_parameter_logging.rb:7`)
- authorization: controller still `require_focused_organization` (`supporting_documents_controller.rb:2`)

## Faults injected

Scratch: `git worktree add /tmp/tlc-verify-sd-insert-deepen-r2 HEAD`. Never stash. One fault at a time, then `git checkout --`. Worktree removed. Real tree porcelain `?? .checks/supporting-document-insert-deepen.verified.md` (matches baseline).

Round 1 faults not on this fix’s surface (pending flag, eager OCR, `#sefaz_pkcs12` always nil, drop `return unless pkcs12`) carried as killed from `0497b30`. Re-injected origin surface plus new assertion surfaces from the spec fix:

| Mutation | Location | Killed |
|---|---|---|
| `ORIGIN_TYPED = "typed"` → `"photo"` (Round 1 survivor) | `app/models/supporting_document.rb:20` | **yes** — C1 `eq("typed")` at `:65` |
| `LOCKED_FIELDS` Portuguese → `"locked"` | `supporting_document.rb:17` | yes — C2 `include("Valor, data e favorecido vêm da nota e não podem ser alterados")` at `:457` |
| persist `self.kind = "nota_fiscal"` | `supporting_document.rb` persist | yes — C1 `eq("recibo")` at `:62` |
| `lookup` chave truncated to 43 digits | `supporting_document.rb:438` | yes — C9 `chave: a_string_matching(/\A\d{44}\z/)` at `:1051` |

## Gate

`bin/rspec spec/models/supporting_document_spec.rb spec/models/organization_spec.rb` with the fifteen checklist `-e` names — 15 passed, 0 failed.

Overall PASS: 10/10 checks located and green; Round 1 origin mutant killed; no unmet test-policy row.
