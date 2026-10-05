# Document insert form

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/document-insert-form.md` marks screen `documents` binding through `.specs/features/visual-identity/design.md` (criterion 13).

Sources:

- `.tasks/document-insert-form.md` - criteria 1–13, the chrome state diagram, the sweep, the one door, and the boundary. Unresolved 1 stays settled as transcribed (Editar shares hide and labels; date default is insert only)
- https://github.com/gutors/ai-accounting-assistant/issues/79 - **binding for this slice**: one screen, Stimulus for kind; `date_field` value today (`Date.current`), not empty; labels `Chave de acesso (opcional)` and `Observação (opcional)`; NF chave rule unchanged; Tipo Recibo hides chave and XML (photo only); toasts via #76; OCR out; 422 keep-values is #85
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent: this child is the documents inclusion form; 422 keep-values after documents and A1
- https://github.com/gutors/ai-accounting-assistant/issues/76 - toast helper already on create `redirect_success` / `toast_now`
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screen `documents`. Opened as a file in the repo. Section `documents` — `GET /supporting_documents` today still draws `Chave de acesso` / `Observação` without `(opcional)`, empty `date`, and Foto|XML always; C13 records Data defaulted to today, the two optional labels, and Tipo Recibo hiding chave and XML (photo only). Ledger rows, `Editar`, Justificativas, two columns from 768px, and insert-first come from the opened section
- `app/views/supporting_documents/index.html.erb` - today’s empty date, labels without `(opcional)`, chave and XML always in the form
- `SupportingDocument` - `RECIBO_XML`, `CHAVE_DIGITS`, Recibo zeros chave
- `app/javascript/controllers/` - Stimulus is eager-loaded; `toast_controller.js` is the browser-event analogue. Kind chrome is a `change` handler

## Out of scope

- Photo OCR, barcode/QR chave capture, and field extraction — #79
- Echoing typed values or keeping `input type=file` on `422` — #85
- Changing NF chave validation (optional; 44 digits if filled without a photo chave) — C10, C12
- Toast chrome, timeout, `Pronto.`, and `flash[:toast]` keys — #76, already on create
- Success toast on `PATCH` / `DELETE` / `sefaz_confirm` — those actions still `redirect_to` without `redirect_success`
- List rows, Editar layout beyond kind chrome and the two labels, Excluir, Usar dados da SEFAZ, justificativas
- Default kind other than `nota_fiscal`
- Client-only validation; making Data `required` in HTML
- Setting `config.time_zone` — Unresolved uses `Date.current` as the app already does
- Settling Unresolved 1 beyond the task’s transcribed answer

## Landing

Touches the documents index ERB and one Stimulus controller so insert Data is `Date.current`, the two labels carry `(opcional)`, and Recibo hides chave and XML (disabled, not posted) while photo stays. Reuses `date_field_tag`, `select_tag` kind, `SupportingDocument.insert` / `CHAVE_DIGITS` / `RECIBO_XML`, and create `redirect_success` / `toast_now`. No schema change.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Recibo hides by not showing and not submitting | When kind is Recibo, that form’s chave and xml controls are not visible and are `disabled` (omitted from the payload). Initial state comes from the selected kind in the HTML; Stimulus updates on `change`. Photo stays | CSS-only hide that still posts XML and 422s `Recibo não tem XML`, which is the UI the model already rejects. A full page reload per kind — #79 names Stimulus |

- Nothing else in this change is hard to reverse

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions). These rows are the bar for this build. They already live in that file, so this cut does not edit it.

These rows are the bar I build under — approving the checklist is enough for that. Writing them into `.cursor/rules/rails.mdc` needs an explicit yes, and it lands as its own commit before the build. Without one I build under them and leave the file alone.

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at its own layer **and** one request spec at HTTP | one asserted case per enumerated member at its own layer; status and who may call at the boundary | follow |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` names the level and the sampling rule: a decision is proven at its own layer, one asserted case per enumerated member; HTTP also gets a request spec; system specs only when a request spec cannot settle the claim
- `SupportingDocument#submit` already decides Recibo XML, Recibo chave `nil`, and typed chave 44 digits at the model (`spec/models/supporting_document_spec.rb`) and at HTTP. This cut does not add a branch there. C9–C12 are boundary proofs of that existing table plus the create toast already on the controller
- Insert/Editar chrome for kind is a view decision (selected kind in HTML) plus a two-member Stimulus table (`nota_fiscal` / `recibo`). Closest analogue: `spec/requests/supporting_documents_spec.rb` for GET HTML and `spec/system/toast_spec.rb` for Stimulus `change`/timer. This repo has no view specs and no JS unit runner. C1–C6 are request proofs of the HTML initial state; C7–C8 are system proofs because a request spec cannot fire `select` `change`
- `SupportingDocumentsController#create` stays pass-through: persist → `redirect_success`; else notice + `toast_now` + `422`

Cost: request examples for C1–C6, C9–C12; system examples for C7–C8; file-read example for C13. No new model spec. Without the system proofs, Recibo hide on Tipo change would be unproven.

## Checks

Criteria 1–13 map to C1–C13. Unresolved 1 stays: Editar shares hide and labels; date default is insert only.

### S1 - Date default and optional labels · 2 files · 103 KB · ~26k

**C1** - Given `Date.current` is `2026-10-05` and a signed-in coordinator of the focused organization, when `GET /supporting_documents` runs, then the status is `200`, the insert form (`POST` `/supporting_documents`) has `label[for=date]` text `Data`, and `input#date[type=date]` has `value` `2026-10-05` (not empty).
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET insert date defaults to Date.current"`

**C2** - Given `Date.current` is `2026-10-05` and that organization has a recibo dated `2026-05-11` with id `{id}`, when `GET /supporting_documents` runs, then that row’s Editar form has `input#date_{id}[type=date]` with `value` `2026-05-11`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Editar date stays document_on"`

**C3** - When `GET /supporting_documents` runs as in criterion 1, then the insert form has `label[for=chave]` whose text is exactly `Chave de acesso (opcional)` and `label[for=observation]` whose text is exactly `Observação (opcional)`. That same GET, for the document in criterion 2, has Editar `label[for=chave_{id}]` and `label[for=observation_{id}]` with those same two strings.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET optional chave and observation labels on insert and Editar"`

### S2 - Recibo hides chave and XML · 4 files · 108 KB · ~27k

**C4** - When `GET /supporting_documents` runs as in criterion 1, then insert `select#kind` has selected `value` `nota_fiscal`, and insert `input#chave` and `input#xml` are present, not `disabled`, and not `hidden`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET insert kind nota_fiscal shows chave and xml"`

**C5** - Given a persisted recibo with id `{id}` on the focused organization, when `GET /supporting_documents` runs, then that Editar form’s `select#kind_{id}` has selected `value` `recibo`, that form’s chave and xml controls are `disabled` and not visible, and that form still has a photo file control that is visible and not `disabled`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Editar recibo hides chave and xml"`

**C6** - Given a persisted `nota_fiscal` with id `{id}` on the focused organization, when `GET /supporting_documents` runs, then that Editar form’s selected kind is `nota_fiscal`, and that form’s chave and xml controls are visible and not `disabled`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Editar nota_fiscal shows chave and xml"`

**C7** - Given the insert form on that GET with kind `nota_fiscal`, when Tipo is set to Recibo, then insert `input#chave` and `input#xml` are not visible and are `disabled`, and insert `input#photo` stays visible and not `disabled`.
Proof: `bin/rspec spec/system/document_kind_spec.rb -e "insert Recibo hides chave and xml"`

**C8** - Given the insert form after criterion 7, when Tipo is set to Nota fiscal, then insert `input#chave` and `input#xml` are visible and not `disabled`.
Proof: `bin/rspec spec/system/document_kind_spec.rb -e "insert Nota fiscal shows chave and xml again"`

### S3 - Persist, chave rule, toasts, binding wireframe · 3 files · 115 KB · ~29k

**C9** - When `POST /supporting_documents` inserts a recibo with photo and the other required fields and no XML, then the response is `302` to `/supporting_documents`, the row has `chave` `nil` and no XML blob, and the following `GET` has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo photo without XML persists chave nil and Pronto toast"`

**C10** - When `POST /supporting_documents` is `kind=nota_fiscal`, a photo, typed amount `155,00`, date `2026-05-11`, payee `Padaria Central`, and chave `123`, then no SupportingDocument is persisted, the status is `422`, `[data-notice="error"]` is `Informe a chave de acesso com 44 dígitos`, and `[data-toast-kind="error"]` is that same string.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal chave 123 returns 422 and error toast"`

**C11** - When `POST /supporting_documents` is `kind=recibo` with photo and an XML file, then no SupportingDocument is persisted, the status is `422`, `[data-notice="error"]` is `Recibo não tem XML`, and `[data-toast-kind="error"]` is that same string.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo with XML returns 422 and error toast"`

**C12** - When `POST /supporting_documents` is `kind=nota_fiscal`, a `.jpg` photo, typed `155,00` / `2026-05-11` / `Padaria Central`, and chave `43260511222333000181550010000000011123456781`, and identified consulta does not deliver, then one SupportingDocument persists with that chave.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal 44-digit chave persists when consulta does not deliver"`

**C13** - `.specs/features/visual-identity/design.md` section `documents` — `GET /supporting_documents` shows insert Data defaulted to today, labels `Chave de acesso (opcional)` and `Observação (opcional)`, and Tipo Recibo hiding chave and XML (photo only).
Proof: `bin/rspec spec/docs/document_insert_form_spec.rb -e "visual-identity documents insert defaults date and hides Recibo chave XML"`

## Screens (ui)

Design opened: `.specs/features/visual-identity/design.md` (file in the repo). Until C13 lands, the insert date, `(opcional)` labels, and Recibo hide are the task transcription; ledger rows, `Editar`, Justificativas, two columns from 768px, and insert-first come from the opened `documents` section.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `documents` insert, default NF | `label[for=date]` `Data`; `input#date[type=date]` `value` `2026-10-05` C1; `label[for=chave]` `Chave de acesso (opcional)`; `label[for=observation]` `Observação (opcional)` C3; `select#kind` selected `nota_fiscal`; `input#chave` and `input#xml` present, not `disabled`, not `hidden` C4 | insert is the first `section`; two columns from 768px: Tipo\|Valor, Data\|Favorecido, chave full width, observation full width, Foto\|XML, then `Incluir documento` C4, C13 | spacing, colour, type weight |
| `documents` Editar recibo | `input#date_{id}` `value` `2026-05-11` C2; labels `Chave de acesso (opcional)` and `Observação (opcional)` C3; `select#kind_{id}` selected `recibo`; chave and xml `disabled` and not visible; photo visible and not `disabled` C5 | Editar stays inside `<details>` under the ledger row; Recibo chrome is photo only (chave and XML gone) C5, C13 | spacing, colour, type weight |
| `documents` Editar nota_fiscal | selected kind `nota_fiscal`; chave and xml visible and not `disabled` C6 | same Editar panel; NF still shows chave and XML C6 | spacing, colour, type weight |
| `documents` insert, Tipo Recibo | `input#chave` and `input#xml` not visible and `disabled`; `input#photo` visible and not `disabled` C7 | photo only; chave and XML omitted from the payload C7 | spacing, colour, type weight |
| `documents` insert, Tipo back to NF | `input#chave` and `input#xml` visible and not `disabled` C8 | NF chrome restored C8 | spacing, colour, type weight |
| `documents` insert success | `[data-toast-kind="success"]` `Pronto.` C9 | toast in the layout slot (existing #76) C9 | spacing, colour, type weight |
| `documents` insert `:base` 422 | `[data-notice="error"]` and `[data-toast-kind="error"]` the same string C10, C11 | notice under the title; toast in the layout slot C10, C11 | spacing, colour, type weight |

## Swept

- validation: C10, C12 — typed chave still 44 digits when present without photo chave; blank chave on NF with photo still persists (existing). Observation stays optional. Date still fails insert if the posted value is not a calendar date (existing `Informe valor, data e favorecido`); C1 only defaults the GET control
- failure modes: C10, C11 — invalid chave and recibo+XML stay the same `422` strings and error toast
- idempotency and retry: existing — two valid recibo inserts still persist two rows; `GET` twice still shows `Date.current` (C1)
- authorization: existing — `require_focused_organization`; submitter still uses the same insert template; other-organization `404` on mutate
- concurrency and ordering: n/a — chrome is per request HTML plus one browser form; two overlapping POSTs still persist two rows (existing). Disabled Recibo fields are per form, not a shared lock
- data lifecycle: n/a — no new column; no backfill; Recibo still stores `chave` `nil` (C9)
- external-dependency failure: n/a — OCR/consulta out of this recorte; C12 does not require identified consulta to deliver
- state transitions: C4, C5, C6, C7, C8 — form chrome for kind; document persist states unchanged
- observability: n/a — the source names no log, metric, or trace; the person sees the form and the existing toast

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| date field sources (2) | insert `Date.current` C1 · Editar `document_on` C2 | - |
| optional labels (2 strings × 2 forms) | insert chave C3 · insert observation C3 · Editar chave C3 · Editar observation C3 | - |
| kind chrome states (5) | insert NF C4 · Editar recibo C5 · Editar NF C6 · insert Recibo on change C7 · insert NF on change C8 | - |
| `POST /supporting_documents` outcomes this cut names (4) | recibo photo no XML C9 · NF chave `123` `422` C10 · recibo+XML `422` C11 · NF 44-digit chave no consulta C12 | - |
| designed screens this cut binds (1) | `documents` C1, C3, C4, C7, C13 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `setup`, `month` — out of scope |
| `documents` visual (3 properties × 7 states) | — | spacing, colour, type weight on insert NF, Editar recibo, Editar NF, insert Recibo, insert NF again, success, `:base` 422 |

- Claims naming a status code, route or response shape: C1, C9, C10, C11, C12 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~26k (`index.html.erb` + `supporting_documents_spec.rb`) + S2 ~27k (same view/spec plus Stimulus controller and `document_kind_spec.rb`; spec file not paid twice on a unique-file floor) + S3 ~29k (`design.md` + docs spec + the same request spec) = ~82k if the 94 KB spec is counted in every slice, ~40k unique files / 4. All three slices stay under 150k and share the documents index. No split. One batch.

- Where the boundary fell: C1–C13 closed on this branch after the implementation commit.
- What the user settled mid-build: none.
- What was abandoned: none.
