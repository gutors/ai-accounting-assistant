# Silent 422 notices

Sources:

- https://github.com/gutors/ai-accounting-assistant/issues/71 - punch list: silent 422 on month, document, accountant, and SEFAZ certificate; criteria 1–6; new copy only criteria 1 and 3
- `app/views/shared/_notice.html.erb` - error alert is `p[role=alert][data-notice=error]`
- `spec/requests/supporting_documents_spec.rb`, `spec/requests/sefaz_certificates_spec.rb` - documents and wrap-key refusals already re-render with `errors[:base]` through that partial (Unresolved: keep criteria 5–6 as proofs that the alert is in the HTML, not console-only)

No design source for the screens. Profile stays `standard`.

## Out of scope

- Accepting an invalid month, a CNPJ without razão social, a certificate that is not a current e-CNPJ A1, or installing A1 without a wrap key (issue out of scope; ADR-0004)
- 422s from the package archive, invites, and the rest of setup (not on the punch list)
- New copy for other accountant refusals (blank presentation name, invalid tax id, CPF with razão social, invalid destination) — only criterion 3 names a string
- Changing insert, close, or certificate decision tables except the two `:base` messages below

## Landing

Touches `Month.open` and `Organization#accountant_shape` so those refusals put Portuguese copy on `errors[:base]`, then `MonthsController#create` / `AccountantsController#update` pass that string into the existing notice partial on home and `/setup`. Documents and SEFAZ already do this. Reuses `shared/notice`, `error_notice_text`, and existing 302 paths.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Invalid month open copy lives on `Month` `:base` | `Month.open` with a value that fails `YEAR_MONTH` does not persist, adds `errors[:base]` `Informe um mês válido`, and `POST /months` re-renders home with that notice. Format still uses `valid_year_month?` so a uniqueness miss cannot steal this copy | Rendering Rails’ attribute format message — it never reached the page; uniqueness also sits on `year_month` |
| CNPJ without razão social copy lives on `Organization` `:base` | `update_accountant` with presentation name and CNPJ `11222333000181` and blank legal name adds `errors[:base]` `Informe a razão social` and does not persist. `PATCH /accountant` re-renders `/setup` with that notice | `errors.full_messages` / attribute `:blank` — English attribute names and copy the issue did not name |

- Nothing else in this change is hard to reverse

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions):

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at the model layer **and** one request spec at HTTP | one asserted case per enumerated member at the model; status / who may call / notice at the boundary | follow |
| Decides, not reached across a boundary | one at the model layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` lines 49–51: decision at its own layer; HTTP also a request spec
- `Month.close_for_send` already puts Portuguese copy on `:base` and `spec/requests/close_spec.rb` asserts `error_notice_text` — month open follows that shape
- `SupportingDocumentsController` / `SefazCertificatesController` already assign `errors[:base]` and the views render `shared/notice`; C5–C6 are boundary proofs of that existing path
- `MonthsController#create` and `AccountantsController#update` stay pass-through once `:base` is set on the model

Cost: two model examples (empty month; CNPJ without razão social copy) and four request examples (C1–C4). C5–C6 tighten existing request examples to `error_notice_text`. No new guidelines file.

## Checks

### S1 - Open month notice · 5 files · 92 KB · ~23k

**C1** - `POST /months` with empty `year_month` responds 422 and the home HTML includes `p[data-notice=error]` whose text is **Informe um mês válido**
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months empty year_month returns 422 Informe um mes valido"`
Proof: `bin/rspec spec/models/month_spec.rb -e "open empty year_month adds Informe um mes valido and does not persist"`

**C2** - `POST /months` with `year_month=2026-05` responds 302 to `/months/2026-05` and leaves 1 `Month` with that `year_month`
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months 2026-05 persists Month and redirects"`

### S2 - Accountant notice · 5 files · 58 KB · ~15k

**C3** - `PATCH /accountant` with `presentation_name=Ana` and `tax_id=11222333000181` (no razão social) responds 422 and `/setup` includes `p[data-notice=error]` whose text is **Informe a razão social**
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant CNPJ without razao social returns 422 Informe a razao social"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "rejects CNPJ without razao social adds Informe a razao social"`

**C4** - `PATCH /accountant` with `presentation_name=Ana` responds 302 to `/setup` and persists that name
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant persists presentation name and redirects"`

### S3 - Documents and wrap key already on the notice · 2 files · 102 KB · ~25k

**C5** - `POST /supporting_documents` `kind=nota_fiscal` with neither photo nor XML responds 422 and `p[data-notice=error]` is **Envie a foto e/ou o XML**
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal without files returns 422 Envie a foto e/ou o XML"`

**C6** - `POST /sefaz_certificate` with a valid A1 and passphrase while `SEFAZ_WRAP_KEY` is absent responds 422 and the notice is **O certificado não pôde ser guardado**
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST A1 with blank wrap key returns 422"`

## Swept

- validation: C1, C3
- failure modes: C1, C3, C5, C6
- idempotency: existing `POST /months 2026-05 a second time does not duplicate` — not this punch list
- authorization: existing coordinator/submitter/unauthenticated examples on these routes
- concurrency: not in scope — no new write race
- data lifecycle: C2, C4 persist; C1, C3, C5, C6 persist nothing
- dependency failure: C6 wrap key
- state transitions: C2 open month; C4 accountant name
- observability: not in scope — no log requirement

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| Punch-list HTTP cases (6) | empty month C1 · valid month C2 · CNPJ no razão social C3 · name-only accountant C4 · nota_fiscal no files C5 · wrap key absent C6 | - |
| New `:base` copy (2) | `Informe um mês válido` C1 · `Informe a razão social` C3 | - |
| Notice selector (4 refusals) | C1 · C3 · C5 · C6 each assert `p[data-notice=error]` text | - |

- Claims naming a status code, route or response shape: C1, C2, C3, C4, C5, C6 - each has a request-spec proof
- No other check claims more than the single case its proof exercises

## Handoff

S1 23k + S2 15k + S3 25k = 63k, all on home / setup / existing document and certificate request specs. One batch; no mid-feature handoff.

These rows are the bar this build uses. Writing them into `.cursor/rules/rails.mdc` needs an explicit yes; without one the file stays as it is.
