# Documents list mask and actions

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/documents-list-mask-and-actions.md` marks screen `documents` binding through `.specs/features/visual-identity/design.md` and `DESIGN.md` (criterion 11).

Sources:

- `.tasks/documents-list-mask-and-actions.md` - criteria 1–25, the state diagram, the sweep, the three doors, the boundary. Unresolved 2 and 3 stay as transcribed (`422` copy in 14, 16, 20). Nothing under Unresolved is settled while building
- https://github.com/gutors/ai-accounting-assistant/issues/103 - GitHub child of #75 for this recorte
- Conversation 2026-10-08 - **binding for this slice**: Valor centavos-first; insert Valor `0,00` hint; insert Tipo unselected; Sem mês Tipo and Ações; filename under Favorecido; Excluir leaves the edit panel; attached files locked; empty slot still Incluir; mask on justificativa Valor gasto; Editar Tipo locked
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screen `documents`. Opened as a file in the repo. Section `documents` today still draws Sem mês as date | payee (kind as meta) | amount with Editar then Excluir inside the fold. C11 amends that wire. Insert-first, two columns from 768px, optional labels, Recibo hide, Justificativas, and `Editar` copy come from the opened section
- `DESIGN.md` - **binding for the design system**: ledger — status and each action in their own columns; file field empty copy `Nenhum arquivo`; disabled 50% opacity / no pointer; quiet `Excluir` margem underline. Opened as a file in the repo
- `app/views/supporting_documents/index.html.erb` - today’s three-track `.ledger-doc`, kind under payee, Excluir inside Editar, empty file fields on edit, enabled `select#kind_{id}`, insert kind default `nota_fiscal`, empty insert Valor
- `SupportingDocumentsController#update` - posts photo/xml into `apply` when present; posts `kind` when the select is submitted
- `SupportingDocument#apply` / `#submit` / `persist_document` - `attach` if a file is passed; `kind` may change on persist
- Open defaults in Unresolved 2–3; Unresolved 1 already closed (`0,00` hint)

## Out of scope

- Month page pool `Documentos sem casamento`, Devolver, casamento — not this screen
- Changing `BrlCents` or `amount_cents` storage — mask posts a comma string the parser already accepts (C4)
- Removing a blob while keeping the document — person deletes the document and inserts again
- Replacing an attached file — refused (C14, C16, C18)
- Changing Tipo on a persisted document — refused (C19–C21); person deletes and inserts again
- Treating insert `0,00` as a stored amount — C22; the person must type a non-zero value
- Máscara on any field outside this screen’s document Valor and justification Valor gasto
- New delete authorization — `month_id` nil and coordinator-or-owner stay (C9, C10, existing `mutate_document` / `withdraw`)
- Settling Unresolved 2–3 beyond the task’s transcribed `:base` strings

## Landing

Touches the documents index (Valor mask, Sem mês columns, Editar file/kind lock), `SupportingDocument#submit`/`#apply` (refuse attached replace and kind change), the shared file-field partial (attached filename, no Limpar when locked), Stimulus money-mask and document-kind (empty Tipo hides NF chrome), and the visual-identity `documents` wire. Reuses `BrlCents.parse`, `format_reais` without `R$`, `mutate_document`, `withdraw`, `render_document_error` / toast, and existing file-field / Turbo confirm. No schema change.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Centavos-first mask is a Stimulus controller on the existing `text` Valor fields | Digits only; display `0,01` / `0,10` / `1,00` (thousands `.` as in `format_reais` without `R$`); posted value is that comma string; `inputmode` `numeric`; eager-loaded like other controllers. Prefill parses the comma string as reais-and-centavos, not as a digit tape (C2, C3) | `type=number` cannot step `100` → `1,00`. Leaving `BrlCents.parse("100")` as R$ 100,00, which is the bug. A shared Ruby formatter in the browser via a new gem — the repo has no money-mask dependency and Rails 8 already uses Stimulus for kind/file |
| Replace of an attached blob is refused in `apply`/`submit` on a persisted row | If `photo` is already attached, an incoming photo is not attached and `:base` is criterion 14’s string. Same for XML and criterion 16. Empty slot still attaches. HTTP `update` surfaces that `:base` as today’s `422` | Controller omitting the param and returning `302` — silent no-op. Controller-only refuse — `apply` remains the domain write and still replaces if called (close_spec / summary already call `apply` without files) |
| Kind is immutable after persist | `apply`/`submit` on a persisted row ignores a new `kind` and adds criterion 20’s `:base` when the posted value differs. Insert still chooses kind. Empty-slot photo attach does not convert NF to Recibo (C15) | Keep PATCH kind conversions (consulta, XML purge) — that is a different document, which the person does by delete and insert |
| Insert Tipo starts unselected | `select#kind` selected value empty; `nota_fiscal` and `recibo` remain options; chave/XML chrome only when selected kind is `nota_fiscal` (C23, C24). Blank POST uses existing `BAD_KIND` (C25) | Keep default `nota_fiscal` (document-insert-form C4) — the person must pick the kind that matches the document |
| Insert Valor `0,00` is a hint, not a persistable amount | GET `#amount` (and new `#justification_amount`) value `0,00`; first typed digit moves the mask (`1` → `0,01`); POST `0,00` is existing `MISSING_FIELDS` (C1, C3, C22) | Empty field until the first digit — the person would not see the `0,00` format |

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
- `SupportingDocument#submit` gains three persisted-row guards (photo attached, XML attached, posted kind differs). Closest analogue: existing Recibo XML / MISSING_FIELDS / BAD_KIND cases in `spec/models/supporting_document_spec.rb` plus matching request examples. C18 and C21 are the own-layer table; C14, C16, C20 are the HTTP contract
- Empty-slot attach and insert still go through existing `persist_document` attach (C15, C4)
- View HTML (columns, `inputmode`, disabled files, unselected kind, `0,00` value) is a request-spec claim. Typing the mask and Tipo `change` are browser APIs; this repo has no JS unit runner. Closest analogue: `spec/system/document_kind_spec.rb`. C1–C3 typing/prefill-after-connect and C24 after Tipo change are system proofs
- `SupportingDocumentsController#update` stays pass-through: `apply` → `302` or `render_document_error` `422`

Cost: request examples for C4–C17, C19, C20, C22, C23, C25; model examples for C18, C21; system examples for C1–C3, C24 change; file-read example for C11. Without the model proofs, a `422` path that never called `apply`’s new guards would still look green at HTTP. Without the system proofs, the mask and empty-kind chrome would be unproven.

## Checks

Criteria 1–25 map to C1–C25. Unresolved 2 and 3 stay: the `:base` strings in C14, C16, and C20.

### S1 - Centavos-first Valor mask · 5 files · 132 KB · ~33k

**C1** - Given a signed-in coordinator of the focused organization on `GET /supporting_documents`, then insert `#amount` value is `0,00`. When the person then types `1`, then `0`, then `0` into that field, then its value is `0,01`, then `0,10`, then `1,00`.
Proof: `bin/rspec spec/system/money_mask_spec.rb -e "insert amount types 1 0 0 as 0,01 0,10 1,00"`

**C2** - Given a persisted recibo on that organization with `amount_cents` `15500` and id `{id}`, when `GET /supporting_documents` runs, then `#amount_{id}` value is `155,00` after the page is interactive, with no extra digits typed.
Proof: `bin/rspec spec/system/money_mask_spec.rb -e "Editar amount prefills 155,00 after interactive"`

**C3** - Given a signed-in submitter of the focused organization on `GET /supporting_documents`, then `#justification_amount` value is `0,00`. When the person then types `1`, then `0`, then `0` into that field, then its value is `0,01`, then `0,10`, then `1,00`. Given that submitter has a justification with `amount_cents` `30000` and id `{id}` whose documents all have `month_id` nil, when that GET runs, then `#justification_amount_{id}` value is `300,00` after the page is interactive.
Proof: `bin/rspec spec/system/money_mask_spec.rb -e "justification amount types 1 0 0 as 0,01 0,10 1,00"`
Proof: `bin/rspec spec/system/money_mask_spec.rb -e "justification amount prefills 300,00 after interactive"`

**C4** - When `POST /supporting_documents` inserts a recibo with photo, date `2026-05-11`, payee `Padaria Central`, and amount `1,00`, then one SupportingDocument persists with `amount_cents` `100`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo amount 1,00 persists 100 cents"`

**C5** - When `GET /supporting_documents` runs as in criterion 1, then insert `#amount` has `inputmode` `numeric`. That same GET, for every rendered `#amount_{id}` (when Valor is shown), also has `inputmode` `numeric`. A submitter GET as in criterion 3, `#justification_amount` and every rendered `#justification_amount_{id}` also have `inputmode` `numeric`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET coordinator amount fields have inputmode numeric"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET submitter justification amount fields have inputmode numeric"`

### S2 - Sem mês Tipo and Ações · 5 files · 148 KB · ~37k

**C6** - Given at least one supporting document on the focused organization, when `GET /supporting_documents` runs, then `.ledger-head.ledger-doc` has five children whose text in order is `Data`, `Favorecido`, `Tipo`, `Valor`, `Ações`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Sem mes head is Data Favorecido Tipo Valor Acoes"`

**C7** - Given a recibo `Padaria Central` with photo filename `foto.jpg` and `amount_cents` `15500`, when `GET /supporting_documents` runs, then that `li[data-row="document"]` has a Tipo cell whose text is exactly `Recibo`, a Favorecido cell that contains `Padaria Central` and `foto.jpg`, and that Favorecido cell’s text does not include `Recibo`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Sem mes row Tipo Recibo and filename under Favorecido"`

**C8** - When that GET runs, then that row’s `PATCH /supporting_documents/{id}` form sits inside a `<details>` whose `<summary>` text is `Editar`, and that `<details>` is not inside the Favorecido cell.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Editar details sit in Acoes not Favorecido"`

**C9** - Given that document has `month_id` nil and the session may delete it (coordinator on focus), when that GET runs, then the row has a `Excluir` control posting `DELETE /supporting_documents/{id}` with `data-turbo-confirm` `Excluir este documento?`, that control is not inside the Editar `<details>`, and that `<details>` contains no `Excluir` control.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Excluir sits in Acoes not inside Editar"`

**C10** - Given that document has `month_id` set, when `GET /supporting_documents` runs, then that row still has Editar as in criterion 8 and has no `Excluir` control.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET month-assigned row has Editar and no Excluir"`

**C11** - `.specs/features/visual-identity/design.md` section `documents` — Sem mês is date | payee (filenames, chave, observation, month status as meta under payee) | Tipo | amount | Ações (`Editar` disclosure; `Excluir` in Ações, not inside the edit panel). Kind is not a meta line under payee. Editar does not offer a control that changes Tipo.
Proof: `bin/rspec spec/docs/documents_list_mask_and_actions_spec.rb -e "visual-identity documents Sem mes is Data Favorecido Tipo Valor Acoes"`

### S3 - Attached file locked on Editar · 5 files · 181 KB · ~45k

**C12** - Given a recibo with photo filename `foto-antiga.jpg` and id `{id}`, when `GET /supporting_documents` runs, then the Editar photo file field shows `foto-antiga.jpg`, `#photo_{id}` is `disabled`, and that field has no `Limpar` control.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Editar attached photo shows filename and is disabled without Limpar"`

**C13** - Given a `nota_fiscal` with XML filename `autorizada.xml`, no photo, and id `{id}`, when `GET /supporting_documents` runs, then the Editar XML file field shows `autorizada.xml` and `#xml_{id}` is `disabled` with no `Limpar` on that field, and the Editar photo field shows `Nenhum arquivo`, `#photo_{id}` is not `disabled`, and that photo field has `Incluir foto` and `Limpar`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Editar xml-only locks XML and leaves photo empty"`

**C14** - Given the recibo in criterion 12, when `PATCH /supporting_documents/{id}` includes a new photo `foto-nova.jpg`, then no blob is replaced, the status is `422`, `[data-notice="error"]` and `[data-toast-kind="error"]` are `A foto não pode ser alterada. Exclua o documento e inclua novamente.`, and the photo filename is still `foto-antiga.jpg`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH new photo on attached photo returns 422 and keeps filename"`

**C15** - Given the xml-only `nota_fiscal` in criterion 13, when `PATCH /supporting_documents/{id}` includes photo `recibo-novo.jpg` and does not send a different `kind` (omit `kind`, or send `nota_fiscal`), then the status is `302` to `/supporting_documents`, `kind` is still `nota_fiscal`, photo filename is `recibo-novo.jpg`, and XML filename is still `autorizada.xml`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH empty-slot photo on xml-only nota_fiscal attaches and keeps xml"`

**C16** - Given a `nota_fiscal` that already has XML filename `autorizada.xml` and id `{id}`, when `PATCH /supporting_documents/{id}` includes a new XML file `outra.xml`, then no blob is replaced, the status is `422`, `[data-notice="error"]` and `[data-toast-kind="error"]` are `O XML não pode ser alterado. Exclua o documento e inclua novamente.`, and the XML filename is still `autorizada.xml`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH new XML on attached XML returns 422 and keeps filename"`

**C17** - When `GET /supporting_documents` runs as in criterion 1, then insert `#photo` is not `disabled`, its file field shows `Nenhum arquivo`, and it has `Limpar`. Insert XML follows criterion 24 (hidden until Tipo is Nota fiscal).
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET insert photo is empty with Limpar"`

**C18** - Always, `SupportingDocument#apply` (and `submit` on a persisted row) does not attach a new photo when `photo` is already attached, and does not attach a new XML when `xml` is already attached; the refused call adds the matching `:base` string from criterion 14 or 16. Insert of a new row still attaches (C4, existing create). Criterion 15 remains the empty-slot attach path.
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply refuses new photo when photo is already attached"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply refuses new XML when XML is already attached"`

### S4 - Tipo locked on Editar · 4 files · 192 KB · ~48k

**C19** - Given a persisted recibo with id `{id}` and a persisted `nota_fiscal` with id `{nf_id}`, when `GET /supporting_documents` runs, then neither Editar form has an enabled `select#kind_{id}` or `select#kind_{nf_id}` (the control is absent, or present and `disabled`). Insert `select#kind` stays enabled. Recibo Editar still hides chave and XML; Nota fiscal Editar still shows them (existing chrome, from persisted kind).
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Editar kind is disabled and insert kind stays enabled"`

**C20** - Given a persisted `nota_fiscal` with id `{id}`, when `PATCH /supporting_documents/{id}` is `kind=recibo`, then `kind` stays `nota_fiscal`, the status is `422`, `[data-notice="error"]` and `[data-toast-kind="error"]` are `O tipo não pode ser alterado. Exclua o documento e inclua novamente.` Given a persisted recibo with id `{id}`, when that PATCH is `kind=nota_fiscal`, then `kind` stays `recibo`, the status is `422`, and notice and toast are that same string.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH kind recibo on nota_fiscal returns 422 and keeps kind"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH kind nota_fiscal on recibo returns 422 and keeps kind"`

**C21** - Always, `SupportingDocument#apply` (and `submit` on a persisted row) does not change `kind`; if the posted `kind` differs from the persisted value, it adds the `:base` string from criterion 20 and does not persist the new kind. Insert of a new row still sets kind (C4, existing create). Omitting `kind` on PATCH still applies the other attrs (C15).
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply refuses kind change from nota_fiscal to recibo"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "apply refuses kind change from recibo to nota_fiscal"`

### S5 - Insert Valor hint and Tipo choice · 4 files · 122 KB · ~31k

**C22** - When `POST /supporting_documents` is `kind=recibo`, photo, date `2026-05-11`, payee `Padaria Central`, and amount `0,00`, then no SupportingDocument is persisted, the status is `422`, and `[data-notice="error"]` and `[data-toast-kind="error"]` are `Informe valor, data e favorecido`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo amount 0,00 returns 422 Informe valor, data e favorecido"`

**C23** - When `GET /supporting_documents` runs as in criterion 1, then insert `select#kind` has no option `nota_fiscal` or `recibo` selected (selected value is empty). The control still lists `Nota fiscal` (`value` `nota_fiscal`) and `Recibo` (`value` `recibo`).
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET insert kind has empty selection and both options"`

**C24** - When that GET runs, then insert `#chave` and `#xml` are not visible and are `disabled`, and insert `#photo` is visible and not `disabled`. When Tipo is set to Nota fiscal, then `#chave` and `#xml` are visible and not `disabled`. When Tipo is then set to Recibo, then `#chave` and `#xml` are not visible and are `disabled`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET insert empty kind hides chave and xml"`
Proof: `bin/rspec spec/system/document_kind_spec.rb -e "insert Nota fiscal shows chave and xml from empty kind"`
Proof: `bin/rspec spec/system/document_kind_spec.rb -e "insert Recibo hides chave and xml"`

**C25** - When `POST /supporting_documents` omits `kind` or sends `kind` empty, with amount `155,00`, date `2026-05-11`, payee `Padaria Central`, and a photo, then no SupportingDocument is persisted, the status is `422`, and `[data-notice="error"]` and `[data-toast-kind="error"]` are `Informe se é nota fiscal ou recibo` (`SupportingDocument::BAD_KIND`).
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST empty kind returns 422 Informe se e nota fiscal ou recibo"`

## Screens (ui)

Design opened: `.specs/features/visual-identity/design.md` (file in the repo) and `DESIGN.md` (file in the repo). Until C11 lands, Sem mês columns, Excluir in Ações, locked files, and unselected insert Tipo are the task transcription; insert-first, two columns from 768px, optional labels, Recibo hide, Justificativas, `Editar`, file-field `Nenhum arquivo` / disabled opacity, and quiet margem `Excluir` come from the opened sources.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `documents` insert | `#amount` `0,00` C1; `inputmode` `numeric` C5; `select#kind` selected empty, options `nota_fiscal` / `recibo` C23; `#photo` `Nenhum arquivo`, not disabled, has `Limpar` C17; `#chave` and `#xml` not visible and `disabled` C24 | insert is the first `section`; two columns from 768px; NF chrome hidden until Tipo is Nota fiscal C24 | spacing, colour, type weight |
| `documents` Sem mês list | head `Data` `Favorecido` `Tipo` `Valor` `Ações` C6; Tipo cell `Recibo`; Favorecido has payee and `foto.jpg` and not `Recibo` C7; `Excluir este documento?` C9 | five columns; filenames under payee; `Editar` `<details>` in Ações not Favorecido; `Excluir` in Ações not inside Editar C6–C9, C11 | spacing, colour, type weight |
| `documents` Editar | `#amount_{id}` `155,00` C2; attached photo filename, `#photo_{id}` disabled, no `Limpar` C12; empty photo `Nenhum arquivo` with `Incluir foto` and `Limpar` C13; kind select absent or `disabled` C19 | Editar panel in Ações; Recibo hides chave/XML; NF shows them; Excluir not in this panel C8, C9, C19 | spacing, colour, type weight |
| `documents` justificativas | `#justification_amount` `0,00`; `#justification_amount_{id}` `300,00`; both `inputmode` `numeric` C3, C5 | existing Justificativas section; mask on Valor gasto only C3 | spacing, colour, type weight |
| `documents` insert Tipo Nota fiscal | `#chave` and `#xml` visible and not `disabled` C24 | NF chrome restored C24 | spacing, colour, type weight |
| `documents` insert Tipo Recibo | `#chave` and `#xml` not visible and `disabled` C24 | photo only C24 | spacing, colour, type weight |
| `documents` insert/PATCH `:base` 422 | `[data-notice="error"]` and `[data-toast-kind="error"]` the same string C14, C16, C20, C22, C25 | notice under the title; toast in the layout slot | spacing, colour, type weight |

## Swept

- validation: C14, C16, C18, C20, C21, C22, C25 — replace of an attached photo or XML is refused with those `:base` strings; a posted `kind` that differs from the persisted value is refused with criterion 20’s string; insert `0,00` is `MISSING_FIELDS`; blank insert kind is `BAD_KIND`; empty-slot attach still validates through existing submit (C15)
- failure modes: C14, C16, C20, C22, C25 — `422` notice and error toast; filename and kind unchanged on refused PATCH
- idempotency and retry: C14, C16, C20, C22, C25 — a second PATCH with a new file on an attached slot, or with a different kind, is still `422` (C18 and C21 are the mechanism); a second POST of `0,00` or blank kind is still `422` and still zero rows
- authorization: existing — `require_focused_organization` and `mutate_document`; C9/C10 do not widen who may delete
- concurrency and ordering: n/a — two overlapping PATCHes to an empty slot still race as today’s attach does; a replace or kind-change attempt is refused per request (C14, C20) and does not observe lock order between two browsers
- data lifecycle: C14, C16, C18, C20, C21 — refused replace does not purge the existing blob; refused kind change does not rewrite `kind`; no new column; no backfill
- external-dependency failure: n/a — no new SEFAZ, Drive, or mail call; PATCH that used to change kind to `nota_fiscal` and fire consulta no longer does (C20)
- state transitions: C12–C16, C18–C25 — file slot empty vs attached; kind no longer transitions on `apply`; insert Tipo unselected until chosen (C23, C24)
- observability: n/a — the source names no log, metric, or trace; the person sees the field, the list, and the existing toast

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| mask fields this cut names (4) | insert `#amount` C1 · Editar `#amount_{id}` C2 · insert `#justification_amount` C3 · Editar `#justification_amount_{id}` C3 | - |
| `inputmode` numeric fields (4) | insert `#amount` C5 · `#amount_{id}` C5 · `#justification_amount` C5 · `#justification_amount_{id}` C5 | - |
| Sem mês head cells (5) | `Data` C6 · `Favorecido` C6 · `Tipo` C6 · `Valor` C6 · `Ações` C6 | - |
| Excluir placement (2) | month_id nil in Ações not Editar C9 · month_id set absent C10 | - |
| attached-slot refuse (2) | photo C14, C18 · XML C16, C18 | - |
| empty-slot attach (1) | photo on xml-only NF C15 | - |
| persisted kind refuse (2) | `nota_fiscal`→`recibo` C20, C21 · `recibo`→`nota_fiscal` C20, C21 | - |
| insert kind chrome (3) | empty GET C23, C24 · Nota fiscal C24 · Recibo C24 | - |
| insert POST outcomes this cut names (3) | `1,00` → 100 cents C4 · `0,00` `422` C22 · empty kind `422` C25 | - |
| designed screens this cut binds (1) | `documents` C1, C6, C11, C17, C23 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `setup`, `month` — out of scope |
| `documents` visual (3 properties × 7 states) | — | spacing, colour, type weight on insert, Sem mês, Editar, justificativas, insert NF, insert Recibo, `:base` 422 |

- Claims naming a status code, route or response shape: C4, C14, C15, C16, C20, C22, C25 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~33k + S2 ~37k + S3 ~45k + S4 ~48k + S5 ~31k if the 107 KB request spec and 57 KB model spec are counted in every slice they touch. Unique files on this cut (`index.html.erb`, `supporting_document.rb`, both specs, `design.md`, `application.css`, `_file_field.html.erb`, `document_kind_controller.js`, new money-mask controller and system spec) ≈ 236 KB / 4 ≈ 59k. Running total stays under 150k and the surface stays the documents index plus `SupportingDocument#submit`. No split. One batch.

- Where the boundary fell: (builder fills after the last commit)
- What the user settled mid-build: none.
- What was abandoned: none.
