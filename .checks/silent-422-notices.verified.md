# Silent 422 notices Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: 715244f..fa9a6df
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

No binding screen source. Checklist Sources names GitHub issue #71 and existing notice markup; it states there is no design source. Step 1 is this line.

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | `POST /months` empty `year_month` → 422 and home HTML `p[data-notice=error]` text **Informe um mês válido** | batched `bin/rspec` (8 examples) exit 0; both named examples ran | `spec/requests/months_spec.rb:100-101` - `have_http_status(:unprocessable_content)` · `error_notice_text(response.body)).to eq("Informe um mês válido")` (`error_notice_text` via `spec/support/page_helpers.rb:7-12` `p[role="alert"][data-notice="error"]`); `spec/models/month_spec.rb:28-29` - `not_to be_persisted` · `errors[:base]).to include("Informe um mês válido")` | PASS |
| C2 | `POST /months` `year_month=2026-05` → 302 to `/months/2026-05` and 1 `Month` | same batch; example ran | `spec/requests/months_spec.rb:30-32` - `have_http_status(:found)` · `redirect_to("/months/2026-05")` · `months.where(year_month: "2026-05").count).to eq(1)` | PASS |
| C3 | `PATCH /accountant` `presentation_name=Ana` `tax_id=11222333000181` (no razão social) → 422 and `/setup` notice **Informe a razão social** | same batch; both named examples ran | `spec/requests/accountants_spec.rb:119-120` - `:unprocessable_content` · `error_notice_text(...).to eq("Informe a razão social")`; `spec/models/organization_spec.rb:103-104` - `update_accountant(...)).to be(false)` · `errors[:base]).to include("Informe a razão social")` | PASS |
| C4 | `PATCH /accountant` `presentation_name=Ana` → 302 to `/setup` and persists that name | same batch; example ran | `spec/requests/accountants_spec.rb:10-12` - `:found` · `redirect_to("/setup")` · `accountant_presentation_name).to eq("Ana Contábil")` (named proof uses trimmed `Ana Contábil`, not literal `Ana`) | PASS |
| C5 | `POST /supporting_documents` `kind=nota_fiscal` neither photo nor XML → 422 and notice **Envie a foto e/ou o XML** | same batch; example ran | `spec/requests/supporting_documents_spec.rb:286-287` - `:unprocessable_content` · `error_notice_text(...).to eq("Envie a foto e/ou o XML")` | PASS |
| C6 | `POST /sefaz_certificate` valid A1 + passphrase, `SEFAZ_WRAP_KEY` absent → 422 and notice **O certificado não pôde ser guardado** | same batch; example ran | `spec/requests/sefaz_certificates_spec.rb:247-248` - `:unprocessable_content` · `error_notice_text(...).to eq("O certificado não pôde ser guardado")` | PASS |

All eight named proofs exist in the tree, appear in `715244f..HEAD` (C2/C4 examples pre-existed; C1/C3 examples and C5/C6 `error_notice_text` assertions are in the range), and ran at `fa9a6df`.

## Coverage (recomputed)

| Set (size) | Authority | Member -> proof | Unproven |
| --- | --- | --- | --- |
| Punch-list HTTP cases (6) | checklist / issue #71 criteria 1–6 | empty month C1 request · valid month C2 · CNPJ no razão social C3 request · name-only accountant C4 · nota_fiscal no files C5 · wrap key absent C6 | - |
| New `:base` copy (2) | Landing | `Informe um mês válido` C1 · `Informe a razão social` C3 | - |
| Notice selector (4 refusals) | checklist | C1 · C3 · C5 · C6 each via `error_notice_text` → `p[role="alert"][data-notice="error"]` | - |

No other enumeration in Landing, Test policy evidence, or claims lacked a Coverage row. Accountant refusals the issue did not name new copy for are Out of scope, not uncovered members of the new-copy set.

Status/route/shape claims (C1–C6) each have a request-spec assertion at HTTP.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `app/models/month.rb` (`Month.open` invalid path); `app/models/organization.rb` (`accountant_shape` CNPJ without legal name) | own layer + HTTP; one asserted case per named member | yes — empty month model `month_spec.rb:25` + HTTP C1; CNPJ/legal-name model `organization_spec.rb:99` + HTTP C3 |
| Decides, not reached across a boundary | none in this change | own layer | n/a |
| Entry point that decides nothing | `MonthsController#create`, `AccountantsController#update` (pass-through once `:base` is set) | request spec: accepted / this punch-list rejected | yes — C2/C4 accepted; C1/C3 rejected + notice. Controllers add no extra branch |
| Instrumentation / pass-through | `app/views/organizations/show.html.erb` `@month_error` notice; `app/views/setup/show.html.erb` `@accountant_error` notice; `shared/notice` | consumer proofs | yes — C1/C3 (and existing C5/C6 document/certificate notices) |
| Existing boundary notice (C5–C6) | `SupportingDocumentsController` / `SefazCertificatesController` (unchanged assign of `:base`) | HTTP `error_notice_text` | yes — C5/C6 |

`.cursor/rules/rails.mdc` 49–51 matches these rows. No unmet row.

## Swept existing

- Idempotency citation `POST /months 2026-05 a second time does not duplicate` is in `spec/requests/months_spec.rb:35`.
- Authorization: unauthenticated/submitter examples remain on `POST /months`, `PATCH /accountant`, `POST /supporting_documents`, `POST /sefaz_certificate`.
- `Month.open` still gates format with `valid_year_month?` before persist (`app/models/month.rb:23-27`), so uniqueness cannot take the new `:base` copy.

Not-in-scope swept rows are policy; not re-judged against code.

## Faults injected

Scratch: `/tmp/silent-422-verify-scratch` at HEAD. Real-tree porcelain before and after: `?? .checks/supporting-document-insert-deepen.verified.md` (unchanged). Cap five; C6 wrap-key string not mutated.

| Mutation | Location | Killed |
|---|---|---|
| `Month::INVALID` `Informe um mês válido` → `Informe um mês inválido` | `app/models/month.rb` | yes — C1 request + C1 model |
| `MonthsController#create` success redirect `/months/#{year_month}` → `/setup` | `app/controllers/months_controller.rb` | yes — C2 |
| `ACCOUNTANT_LEGAL_NAME` `Informe a razão social` → `Informe o CNPJ` | `app/models/organization.rb` | yes — C3 request + C3 model |
| `AccountantsController#update` success redirect `/setup` → `/` | `app/controllers/accountants_controller.rb` | yes — C4 |
| `SupportingDocument::NF_FILES` `Envie a foto e/ou o XML` → `Envie o XML` | `app/models/supporting_document.rb` | yes — C5 |

## Gate

`bin/rspec spec/requests/months_spec.rb spec/models/month_spec.rb spec/requests/accountants_spec.rb spec/models/organization_spec.rb spec/requests/supporting_documents_spec.rb spec/requests/sefaz_certificates_spec.rb` with the eight `-e` names from the checklist — 8 passed, 0 failed (at `fa9a6df`).
