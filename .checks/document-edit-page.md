# Document edit page

Profile: `ui`. Raised from the repo floor `standard` because this work names a binding screen (supporting-document edit, composition **Prova à esquerda**).

Sources:

- Conversation 2026-10-08 - decided work: `GET /supporting_documents/:id/edit` as a page (same pattern as `GET /administration/:id/edit`); list `Editar` becomes a quiet caixa link; inline `<details>` edit is removed; PATCH/DELETE/SEFAZ semantics stay; after success still `/supporting_documents`; prefer re-render **edit** on failed update from this page
- `.impeccable/mocks/document-edit.html` - **binding for the interface**: screen `01` edit documento. Opened as a file in the repo. Structure, copy, and order: Voltar → h1 `Editar documento` → SEFAZ margem notice + `Usar dados da SEFAZ` → split with proof left / book right from 768px; labels `Tipo`, `Valor`, `Data`, `Favorecido`, `Chave de acesso (opcional)`, `Observação (opcional)`; `Salvar documento` then `Excluir`; XML empty copy `Nenhum arquivo` + chip `Incluir XML`
- `.impeccable/mocks/decision/evidence-pane.webp` - **binding for the interface**: screen `01` approved raster of **Prova à esquerda**. Opened as an image in the repo. Arrangement: photo in a ruled sheet on the left; book column on the right; SEFAZ notice + primary before the split. Where this raster abbreviates labels (`Chave`, `Observação`, `Nenhum XML`, truncated lock), the HTML prototype and `PHOTO_LOCKED` win for copy (task + existing insert labels)
- `.impeccable/surfaces/app-views-supporting-documents.md` - direction contract: evidence pane, no card, no extra icons, typed NF fields, photo locked, XML picker only if none attached
- `DESIGN.md` - **binding for the design system**: paper / sheet / caixa / margem / rule / ink; 28rem short form; 768px two-column; file field empty `Nenhum arquivo`; no cards, no shadows, no extra icons. Opened as a file in the repo
- `app/views/supporting_documents/index.html.erb` - today’s inline `<details>Editar</details>`, field names, Stimulus `document-kind` / `money-mask`, `shared/file_field`, list `Excluir`, list SEFAZ button
- `SupportingDocumentsController#update` / `#destroy` / `#sefaz_confirm` / `mutate_document` - incumbent write/auth. This cut does not re-spec those tables
- `GLOSSARY.md` - Supporting document, Chave de acesso, SEFAZ consulta, Recibo, Observação

## Out of scope

- Changing `apply` / `submit` / `withdraw` / `confirm_identified_sefaz` decision tables — already shipped
- Replacing an attached photo or XML — existing `PHOTO_LOCKED` / `XML_LOCKED`
- Changing Tipo on a persisted row — existing `KIND_LOCKED`
- Insert form on `GET /supporting_documents` — stays
- List `Excluir` in Ações — stays
- Justificativa `Editar` disclosure — stays
- Month page unmatched pool
- Echo of posted (unsaved) PATCH values on `422` — re-render shows the persisted document plus notice/toast
- Browser-stack for spacing, colour, type weight
- Writing these test-policy rows into `.cursor/rules/rails.mdc` — see Test policy; needs an explicit yes

## Landing

Touches `SupportingDocumentsController#edit` and `#update` `422` template, `config/routes.rb`, `app/views/supporting_documents/edit.html.erb`, the Sem mês row on the index (link instead of disclosure), and request/system examples that pointed at the inline fold. Reuses `mutate_document`, `form_with` PATCH, `shared/file_field`, `document-kind`, `money-mask`, `PHOTO_LOCKED`, list `Excluir` / Turbo confirm, `render_document_error` notice+toast.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Edit is a page, not a list disclosure | `GET /supporting_documents/:id/edit` → `#edit`; list `Editar` is `a` href that path, quiet caixa, in Ações. No `<details>` and no PATCH form on the list row | Keep the inline `<details>` — the locked composition refuses it. A modal — DESIGN.md forbids a modal for this |
| Failed `PATCH #update` re-renders `:edit` | `422`, `@document` is the mutate target, `@document_error` + error toast as today, template `supporting_documents/edit`. `#destroy` and `#sefaz_confirm` `422` still render `:index` | Always render `:index` (today) — the person would leave the page they were correcting. A `return_to` param — only this UI posts PATCH after the fold is gone |
| Photo proof is not a file field | Attached photo: `image_tag` of the blob inside the ruled sheet, filename, `SupportingDocument::PHOTO_LOCKED`. No `#photo` input. Missing photo: copy `Nenhuma foto`, no lock sentence, no `#photo` input. XML still uses `shared/file_field` (`Incluir XML` / `Nenhum arquivo`) only when the document is `nota_fiscal` and XML is not attached; attached XML shows the locked field (filename, disabled, no Limpar) | Keep the list’s photo picker on the edit page — the composition is the proof pane. `Nenhum XML` as a link (approved raster) — DESIGN.md file field + the HTML prototype |

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

- `.cursor/rules/rails.mdc` names the level and the sampling rule
- `#edit` is an entry point that decides nothing beyond `mutate_document` (already the PATCH/DELETE guard). Closest analogue: `AdministrationController#edit` `404` when missing + request examples in `spec/requests/administration_access_spec.rb`
- `#update` `422` template choice is a two-member dispatch (`:edit` vs `:index`). Own-layer table is not new domain branches. C17 is the HTTP contract for the `:edit` member; destroy/sefaz keep existing index `422` examples
- View HTML (order, containment, copy, disabled, href) is a request-spec claim. Mask prefill after connect is a system proof (`spec/system/money_mask_spec.rb`). Horizontal scroll at 390 on the new page is `spec/system/screens_spec.rb`
- `mutate_document` and `apply` guards stay proven where they already are

Cost: request examples for C1–C17, C19; system examples for C18 and the 390px edit visit. No new model spec. Without the `422` template proof, a green PHOTO_LOCKED example could still render the list.

## Screens (ui)

Opened: `.impeccable/mocks/document-edit.html` (file), `.impeccable/mocks/decision/evidence-pane.webp` (image), `DESIGN.md` (file), `.impeccable/surfaces/app-views-supporting-documents.md` (file).

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `01` edit documento | `Voltar para documentos`; h1 `Editar documento`; pending SEFAZ `A SEFAZ devolveu dados desta chave.` + `Usar dados da SEFAZ`; labels `Tipo`, `Valor`, `Data`, `Favorecido`, `Chave de acesso (opcional)`, `Observação (opcional)`; `Salvar documento`; `Excluir` when allowed; `PHOTO_LOCKED` when photo attached; XML `Nenhum arquivo` / `Incluir XML` when NF and no XML | Header (layout) then main: Voltar, then h1, then SEFAZ notice (when pending) **before** the split. Split: proof **first** (photo sheet, filename, lock), XML under the sheet, book **second** `max-w-[28rem]`. From 768px two columns `minmax(0,1fr)` + `28rem`. Tipo `disabled`. No list `<details>`. No extra icons. No `#photo` file input | `01` spacing, colour, type weight |

## Checks

### S1 - GET edit route and auth · 4 files · 130 KB · ~33k

**C1** - Given a signed-in coordinator of the focused organization and a supporting document id `{id}` on that organization, when `GET /supporting_documents/{id}/edit` runs, then the status is `200` and `h1` text is `Editar documento`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit coordinator 200 Editar documento"`

**C2** - When `GET /supporting_documents/{id}/edit` runs with no session, then the status is `302` to `/login`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET edit responds 302 to /login"`

**C3** - Given a signed-in submitter of the focused organization and a supporting document belonging to another Account on that organization, when `GET /supporting_documents/{id}/edit` runs, then the status is `404`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter GET edit on another Account document returns 404"`

**C4** - Given that submitter and a supporting document they own on that organization, when `GET /supporting_documents/{id}/edit` runs, then the status is `200`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter GET edit on own document returns 200"`

**C5** - Given a signed-in coordinator of the focused organization, when `GET /supporting_documents/{missing}/edit` runs, then the status is `404`. Given a document that belongs only to another organization, when that coordinator `GET`s its edit path, then the status is `404`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit missing id returns 404"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit other organization document returns 404"`

### S2 - List Editar is a page link · 3 files · 136 KB · ~34k

**C6** - Given a recibo on the focused organization with id `{id}`, when `GET /supporting_documents` runs, then that row’s Ações cell contains `a` whose text is `Editar` and href is `/supporting_documents/{id}/edit`, that row has no `<details>` whose summary is `Editar`, and that row has no `form` posting `PATCH /supporting_documents/{id}`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Editar is a link to edit not a details fold"`

**C7** - Given that document has `month_id` nil and the session is a coordinator on focus, when that GET runs, then the row still has `Excluir` posting `DELETE /supporting_documents/{id}` with `data-turbo-confirm` `Excluir este documento?` in Ações.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET Excluir sits in Acoes not inside Editar"`

**C8** - Given that document has `month_id` set, when `GET /supporting_documents` runs, then that row has the Editar link of C6 and has no `Excluir` control.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET month-assigned row has Editar and no Excluir"`

**C9** - Given a `nota_fiscal` with `sefaz_confirm_pending` true, when `GET /supporting_documents` runs, then that row’s text does not include `Usar dados da SEFAZ`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET list row has no Usar dados da SEFAZ"`

### S3 - Edit page composition · 3 files · 128 KB · ~32k

**C10** - Given C1’s GET, then `main` contains `a` `Voltar para documentos` href `/supporting_documents` **before** `h1` `Editar documento`. The PATCH form `#document-edit` has labels for `kind`, `amount`, `date`, `payee`, `observation` whose text is `Tipo`, `Valor`, `Data`, `Favorecido`, `Observação (opcional)`. `#kind` is `disabled`. The form has `input[type=submit][value="Salvar documento"]`. The book column containing that form has class `max-w-[28rem]`. The split `[data-edit=split]` has class including `md:grid-cols-[minmax(0,1fr)_28rem]`. Its first child is `[data-edit=proof]`; its second is `[data-edit=book]`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit page order Voltar h1 split proof then book"`

**C11** - Given a typed `nota_fiscal` with chave and no XML, when `GET /supporting_documents/{id}/edit` runs, then `label[for=chave]` text is `Chave de acesso (opcional)`, `#chave` is not disabled, and `[data-file-field=xml]` shows `Nenhum arquivo` and `Incluir XML` with `#xml` not disabled. Given a recibo GET edit, then `#chave` and `#xml` are not visible.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit nota_fiscal shows chave and empty XML"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit recibo hides chave and xml"`

**C12** - Given a recibo whose photo filename is `foto-antiga.jpg`, when `GET /supporting_documents/{id}/edit` runs, then `[data-edit=proof]` contains an `img` whose `src` includes the blob path, contains `foto-antiga.jpg`, contains `A foto não pode ser alterada. Exclua o documento e inclua novamente.`, and the page has no `input#photo`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit attached photo shows img filename and PHOTO_LOCKED"`

**C13** - Given an xml-only `nota_fiscal` (no photo) whose XML filename is `autorizada.xml`, when `GET /supporting_documents/{id}/edit` runs, then `[data-edit=proof]` contains `Nenhuma foto`, does not contain `A foto não pode ser alterada`, has no `input#photo`, and `[data-file-field=xml]` shows `autorizada.xml` with `#xml` disabled and no `Limpar`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit xml-only empty photo and locked XML"`

**C14** - Given a typed `nota_fiscal` with `sefaz_confirm_pending` true, when `GET /supporting_documents/{id}/edit` runs, then a margem notice after `h1` and before `[data-edit=split]` contains `A SEFAZ devolveu dados desta chave.` and a control `Usar dados da SEFAZ` posting `POST /supporting_documents/{id}/sefaz_confirm`. Given a recibo with `sefaz_confirm_pending` false, that GET has neither that sentence nor that control.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit pending SEFAZ notice and button before split"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit without pending SEFAZ has no Usar dados"`

**C15** - Given a typed recibo, when `GET /supporting_documents/{id}/edit` runs, then `#amount`, `#date`, and `#payee` are present and not disabled. Given a `nota_fiscal` whose fields come from uploaded XML (`fields_locked?`), that GET has no `#amount`, `#date`, or `#payee`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit typed shows amount date payee"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit locked XML hides amount date payee"`

**C16** - Given a document with `month_id` nil and a coordinator session, when `GET /supporting_documents/{id}/edit` runs, then the page has `Excluir` posting `DELETE /supporting_documents/{id}` with `data-turbo-confirm` `Excluir este documento?`. Given `month_id` set, that GET has no `Excluir`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit Excluir when month_id nil"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit no Excluir when month_id set"`

**C19** - Given a `nota_fiscal` whose chave is `35240612345678000190550010000012341000012340`, when `GET /supporting_documents/{id}/edit` runs, then `#chave` value is that raw digit string (no spaces).
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit chave field keeps raw digits"`

### S4 - PATCH 422 stays on edit · 4 files · 131 KB · ~33k

**C17** - Given a recibo with an attached photo, when `PATCH /supporting_documents/{id}` includes a new photo, then the status is `422`, `h1` text is `Editar documento`, `[data-notice=error]` and `[data-toast-kind=error]` are `A foto não pode ser alterada. Exclua o documento e inclua novamente.`, and the photo filename is still the original.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH new photo on attached photo returns 422 and keeps filename"`

**C18** - Given a signed-in coordinator and a recibo with `amount_cents` `15500` and id `{id}`, when the person visits `/supporting_documents/{id}/edit`, then `#amount` value is `155,00` after the page is interactive, and that field has `inputmode` `numeric`.
Proof: `bin/rspec spec/system/money_mask_spec.rb -e "Editar amount prefills 155,00 after interactive"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET edit amount has inputmode numeric"`

## Swept

- validation: existing `apply` guards; not re-implemented. C17 surfaces PHOTO_LOCKED on the edit template
- failure modes: C17 (`422` stays on edit). Destroy/sefaz `422` stay on index (existing examples)
- idempotency: GET edit is read-only. Writes unchanged
- authorization: C1–C5 (`mutate_document` at GET). PATCH/DELETE already covered
- concurrency: not in scope — no new write
- data lifecycle: C12, C13 — photo not replaced in the UI; XML attach only when absent
- dependency failure: SEFAZ consulta unchanged; C14 only places the existing confirm control
- state transitions: C14 pending vs not; no new states
- observability: existing notice + toast on `422` (C17)

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| designed screens (1) | `01` edit documento C10–C16, C19 | - |
| GET edit who may call (4) | coordinator C1 · unauthenticated C2 · submitter other C3 · submitter own C4 | - |
| GET edit missing/foreign (2) | missing id C5 · other organization C5 | - |
| list Editar replacement (4) | link C6 · no details C6 · no PATCH form C6 · Excluir kept C7 · month no Excluir C8 · no list SEFAZ C9 | - |
| SEFAZ chrome (2) | pending on edit C14 · not pending C14 | - |
| photo pane (2) | attached C12 · missing C13 | - |
| XML field (3) | NF empty C11 · NF attached C13 · recibo hidden C11 | - |
| typed vs locked triple (2) | typed C15 · locked XML C15 | - |
| Excluir on edit (2) | `month_id` nil C16 · set C16 | - |
| `422` update template (2) | `#update` → `:edit` C17 · `#destroy`/`#sefaz_confirm` → `:index` (existing request examples, not this cut) | - |
| startup config | no new boot setting | - |

- Claims naming a status code, route or response shape: C1, C2, C3, C4, C5, C17 — each has a request-spec proof that crosses HTTP
- No other check claims more than the single case its proof exercises

## Handoff

One batch: S1–S4. Arithmetic: the shared `spec/requests/supporting_documents_spec.rb` (120 KB) dominates every slice; controller + index + routes + money_mask + screens ≈ 29 KB; new `edit.html.erb` is new. Floor S1 33k + S2 34k + S3 32k + S4 33k double-counts that spec; unique reading ≈ 160 KB · ~40k tokens. Under 150k. Surface stays supporting documents. This agent builds all four slices.

handoff: on; this is the only batch. Builder finishes, reports, stops. Orchestrator dispatches the Verifier.
