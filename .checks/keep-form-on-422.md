# Keep form on 422 (document and A1)

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/keep-form-on-422.md` marks screens `documents` and `setup` binding through `.specs/features/visual-identity/design.md` (criterion 11).

Sources:

- `.tasks/keep-form-on-422.md` - criteria 1–11, the state diagram, the sweep, the one door, Unresolved 1 transcribed as `Limpar`. Nothing under Unresolved is settled while building
- https://github.com/gutors/ai-accounting-assistant/issues/85 - **binding for this slice**: keep document insert and A1 install on `422`; echo document tipo, valor, data, favorecido, chave, observação; do not echo A1 senha; files only if `422` does not replace the form node; `Limpar` next to Foto / XML / Arquivo do A1 without submit; no failed-upload stash; proofs NF without file, recibo with XML, invalid chave, A1 wrong passphrase; out: blob stash, edit of a saved document, client-only validation
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent: `422` must not wipe what was filled; `input type=file` does not round-trip in HTML; no failed upload or `.pfx` in session
- https://github.com/gutors/ai-accounting-assistant/issues/79 - insert chrome already shipped; echoing on `422` was deferred here
- https://github.com/gutors/ai-accounting-assistant/issues/82 - A1 fold and HTML `422` passphrase empty already shipped; Stream / keep file deferred here
- https://github.com/gutors/ai-accounting-assistant/issues/76 - `:base` `422` still has the error toast; Stream must keep that extra (5, 6)
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screens `documents` and `setup`. Opened as a file in the repo. Sections today still draw Foto / XML / Arquivo without `Limpar` and do not mention HTML `422` echo. C11 amends those two sections. Insert field ids, Recibo hide, A1 fold, and empty passphrase on HTML `422` come from the opened sections plus #79 / #82
- `app/views/supporting_documents/index.html.erb` - today’s `nil` insert values; no `Limpar`
- `app/views/setup/show.html.erb` - today’s empty passphrase on every render; no `Limpar`
- Open default in Unresolved 1 - control text `Limpar` (not `Remover`)

## Out of scope

- Stash of a pending blob or `.pfx` in session, object store, or container disk — #85 / #75
- Editing a document already saved (`PATCH /supporting_documents/:id` `422`) — #85
- Client-only validation — #85
- Restoring `input type=file` by setting a value from the server — browser limitation; #75
- Echoing the A1 passphrase in HTML — #75 / #82 criterion 6; this task keeps that (4, 6, 10)
- Changing insert or A1 decision tables or `:base` copy — existing #51 / #38 / #79 / #82
- Justificativa `422`, other setup `422`s, bank-statement uploads — not on #85
- Toast chrome, timeout, `Pronto.` — #76 already on these `422`s
- Recibo chrome (hide chave/XML) and Data default on GET — #79, already shipped
- A1 fold heading / empty line / details `open` on HTML `422` — #82, already shipped
- Settling Unresolved 1 beyond the task’s transcribed `Limpar`

## Landing

Touches `SupportingDocumentsController#create`, `SefazCertificatesController#create`, the documents insert ERB, the setup A1 form, layout notice/toast targets those streams can update, and one Stimulus controller that clears `input type=file`. Reuses existing `:base` strings, `toast_now`, `render :index` / `setup/show` HTML `422`, `document-kind`, and `#76` error toast. No schema change.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| First Turbo Stream `422` in this app, only on these two POSTs | `POST /supporting_documents` and `POST /sefaz_certificate`, when `Accept` includes `text/vnd.turbo-stream.html`, respond `422` `text/vnd.turbo-stream.html` whose streams `replace` `[data-notice=error]` and `update` `#toast-host` only. They do not replace `form[action="/supporting_documents"]` or `form[action="/sefaz_certificate"]`. Without that Accept, `422` is still the full page HTML with echoed document params (1–3) and empty A1 passphrase (4). | Full-page HTML only — Turbo Drive replaces the form node, so files cannot survive, which #85 forbids. Site-wide morph / `turbo-refresh` — a new default for every form, which #75 did not ask. Stashing the upload in session or the object store — #75 / #85, A1 is a secret, container disk is ephemeral |

`Limpar` is Stimulus clearing `input type=file` (browser API), the same class of controller as `document-kind`. It is not a new transport.

| GET documents and setup plus the layout toast host always expose the Stream CSS targets | The layout always renders `#toast-host`. When there is no flash it is empty and has no `[data-toast]` (#76). Documents and setup always render `[data-notice=error]` (`hidden` when the message is blank). Stream `422` uses `action="replace"` `targets="[data-notice=error]"` and `action="update"` `target="toast-host"` so a later `422` still has a toast slot after dismiss or a Pronto flash. `request.accept` including `text/vnd.turbo-stream.html` selects this path. | Replacing `[data-toast-kind=error]` — that node is the flash toast, so dismiss or Pronto removes the Stream target. `turbo_stream.append` — a second `422` would duplicate nodes. Putting `data-toast` on an empty host — `GET /` with empty flash must still have no `[data-toast]` (#76). Site-wide morph / `turbo-refresh` — already rejected |

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
- `SupportingDocument.insert` and `Organization#install_sefaz_certificate` already decide the four `:base` strings. This cut does not add a domain branch. C1–C4, C10 are boundary proofs of echo / empty passphrase / no stash on those existing refusals
- Controller `422` transport is a two-member dispatch (`text/vnd.turbo-stream.html` vs HTML). That is the HTTP contract; C1–C4 prove HTML, C5–C6 prove Stream. Closest analogue: existing `422` examples in `spec/requests/supporting_documents_spec.rb` and `spec/requests/sefaz_certificates_spec.rb`
- Stimulus `Limpar` and the live form node after Stream `422` are browser APIs. This repo has no JS unit runner. Closest analogue: `spec/system/document_kind_spec.rb`. C7, C8 (click), C9 (click) are system proofs because a request spec cannot keep a chosen file or fire the clear without a POST
- GET `Limpar` presence is HTML a request spec can read (C8, C9)

Cost: request examples for C1–C6, C8 presence, C9 presence, C10; system examples for C7, C8 click, C9 click; file-read example for C11. No new model spec. Without the system proofs, a Stream `422` that still replaced the form would look green at HTTP.

## Checks

Criteria 1–11 map to C1–C11. Unresolved 1 stays: label `Limpar`.

### S1 - HTML 422 echoes document params · 3 files · 116 KB · ~29k

**C1** - Given a signed-in coordinator of the focused organization, when `POST /supporting_documents` is `kind=nota_fiscal`, amount `155,00`, date `2026-05-11`, payee `Padaria Central`, observation `pago em dinheiro`, and neither photo nor XML, then no SupportingDocument is persisted, the status is `422`, `[data-notice="error"]` and `[data-toast-kind="error"]` are `Envie a foto e/ou o XML`, insert `#kind` selected is `nota_fiscal`, `#amount` value is `155,00`, `#date` value is `2026-05-11`, `#payee` value is `Padaria Central`, `#observation` value is `pago em dinheiro`, and `#photo` / `#xml` are `input type=file` with no server-filled value.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal without files echoes insert fields on 422"`

**C2** - When `POST /supporting_documents` is `kind=recibo`, those same amount / date / payee / observation values, a photo, and an XML file, then no SupportingDocument is persisted, no new `ActiveStorage::Blob` is created, the status is `422`, `[data-notice="error"]` and `[data-toast-kind="error"]` are `Recibo não tem XML`, insert `#kind` selected is `recibo`, the four text values match criterion 1, and `#xml` is `input type=file` with no server-filled value.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo with XML echoes insert fields on 422 and creates no blob"`

**C3** - When `POST /supporting_documents` is `kind=nota_fiscal`, a `.jpg` photo, amount `155,00`, date `2026-05-11`, payee `Padaria Central`, and chave `123`, then no SupportingDocument is persisted, the status is `422`, `[data-notice="error"]` and `[data-toast-kind="error"]` are `Informe a chave de acesso com 44 dígitos`, and insert `#chave` value is `123` with the same four text values as criterion 1.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal chave 123 echoes chave and insert fields on 422"`

### S2 - HTML 422 does not echo the A1 passphrase · 2 files · 24 KB · ~6k

**C4** - Given no certificate, when `POST /sefaz_certificate` is a valid `.pfx` and passphrase `errada`, then no certificate is persisted, the status is `422`, `[data-notice="error"]` and `[data-toast-kind="error"]` are `Não foi possível abrir o certificado com essa senha`, the Arquivo/Senha `<details>` has the `open` attribute, `#certificate` is `input type=file` with no server-filled value, `#passphrase` value is `""`, and the body does not include `errada`.
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST pfx with passphrase errada returns 422 with install details open"`

### S3 - Turbo Stream 422 does not replace the form node · 4 files · 118 KB · ~30k

**C5** - When `POST /supporting_documents` repeats criterion 1 with `Accept` including `text/vnd.turbo-stream.html`, then the status is `422`, the response media type includes `text/vnd.turbo-stream.html`, the streams put `Envie a foto e/ou o XML` on `[data-notice=error]` and `#toast-host`, and the response body does not include a `form` whose `action` is `/supporting_documents`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal without files turbo stream 422 updates notice and toast only"`

**C6** - When `POST /sefaz_certificate` repeats criterion 4 with that same `Accept`, then the status is `422`, the media type includes `text/vnd.turbo-stream.html`, the streams put `Não foi possível abrir o certificado com essa senha` on `[data-notice=error]` and `#toast-host`, the body does not include `errada`, and the body does not include a `form` whose `action` is `/sefaz_certificate`.
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST pfx with passphrase errada turbo stream 422 updates notice and toast only"`

**C7** - Given the insert form in the browser with Tipo Recibo, a chosen XML file whose filename is `nota.xml`, and the typed fields from criterion 2, when Incluir documento runs, then the status the person sees is the `Recibo não tem XML` notice (and error toast), `#kind` stays `recibo`, those typed fields stay filled, and `#xml` still has `nota.xml`.
Proof: `bin/rspec spec/system/keep_form_on_422_spec.rb -e "insert Recibo XML 422 keeps the chosen xml file"`

### S4 - Limpar clears a file without submit · 4 files · 30 KB · ~8k

**C8** - When `GET /supporting_documents` runs as in criterion 1’s actor, then the insert form has a `button type=button` whose text is `Limpar` next to `#photo` and another next to `#xml`. After a file is chosen on `#photo`, activating that button leaves `#photo` with no file and does not `POST /supporting_documents`.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET insert has Limpar next to photo and xml"`
Proof: `bin/rspec spec/system/keep_form_on_422_spec.rb -e "Limpar clears insert photo without submit"`

**C9** - When `GET /setup` runs as that coordinator, then `form[action="/sefaz_certificate"]` has a `button type=button` whose text is `Limpar` next to `#certificate`. After a file is chosen on `#certificate`, activating that button leaves `#certificate` with no file and does not `POST /sefaz_certificate`.
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET setup A1 form has Limpar next to certificate"`
Proof: `bin/rspec spec/system/keep_form_on_422_spec.rb -e "Limpar clears A1 certificate without submit"`

### S5 - No failed-upload stash and binding wireframes · 3 files · 25 KB · ~6k

**C10** - Always, after the `422`s in criteria 1–4, `ActiveStorage::Blob.count` is unchanged, the organization’s A1 columns are unchanged, and `session` values do not include passphrase `errada` or the PKCS12 bytes.
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal without files echoes insert fields on 422"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST recibo with XML echoes insert fields on 422 and creates no blob"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "POST nota_fiscal chave 123 echoes chave and insert fields on 422"`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST pfx with passphrase errada returns 422 with install details open"`

**C11** - `.specs/features/visual-identity/design.md` sections `documents` and `setup` — insert Foto and XML each have `Limpar` beside the file control; setup Arquivo has `Limpar` beside the file control; HTML `422` fallback echoes the document fields in criteria 1–3; A1 senha is not written into the HTML on `422`.
Proof: `bin/rspec spec/docs/keep_form_on_422_spec.rb -e "visual-identity documents and setup keep form on 422"`

## Screens (ui)

Design opened: `.specs/features/visual-identity/design.md` (file in the repo). Until C11 lands, `Limpar` beside Foto / XML / Arquivo, HTML `422` echo of document fields, and A1 senha absent from HTML are the task transcription; insert field order, Recibo hide, A1 fold, and empty passphrase control come from the opened `documents` and `setup` sections.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `documents` insert, HTML `422` NF no file | `[data-notice="error"]` and `[data-toast-kind="error"]` `Envie a foto e/ou o XML`; `#kind` `nota_fiscal`; `#amount` `155,00`; `#date` `2026-05-11`; `#payee` `Padaria Central`; `#observation` `pago em dinheiro`; `#photo` and `#xml` `type=file` empty C1 | notice under the title; insert remains the first `section`; Foto then XML; file inputs not filled by the server C1 | spacing, colour, type weight |
| `documents` insert, HTML `422` Recibo+XML | notice and error toast `Recibo não tem XML`; `#kind` `recibo`; four text values as C1; `#xml` `type=file` empty C2 | same insert grid; XML control empty in the HTML fallback C2 | spacing, colour, type weight |
| `documents` insert, HTML `422` chave `123` | notice and error toast `Informe a chave de acesso com 44 dígitos`; `#chave` `123`; four text values as C1 C3 | chave full width in the insert form C3 | spacing, colour, type weight |
| `documents` insert, Stream `422` | streams put the notice string on `[data-notice=error]` and `#toast-host`; no `form[action="/supporting_documents"]` in the Stream body C5 | Stream updates notice and toast host only; the form node stays C5, C7 | spacing, colour, type weight |
| `documents` insert, browser Recibo+XML `422` | notice and error toast `Recibo não tem XML`; `#kind` `recibo`; typed fields stay; `#xml` still `nota.xml` C7 | form node not replaced C7 | spacing, colour, type weight |
| `documents` insert, `Limpar` | `button type=button` text `Limpar` next to `#photo` and next to `#xml` C8 | each `Limpar` sits beside that file control, not as a submit C8, C11 | spacing, colour, type weight |
| `setup` certificate, HTML `422` wrong passphrase | notice and error toast `Não foi possível abrir o certificado com essa senha`; details `open`; `#certificate` `type=file` empty; `#passphrase` `""`; body has no `errada` C4 | Arquivo/Senha inside open `<details>`; Senha not written into HTML C4 | spacing, colour, type weight |
| `setup` certificate, Stream `422` | streams put that string on `[data-notice=error]` and `#toast-host`; no `errada`; no `form[action="/sefaz_certificate"]` in the Stream body C6 | Stream does not replace the install form C6 | spacing, colour, type weight |
| `setup` certificate, `Limpar` | `button type=button` text `Limpar` next to `#certificate` inside `form[action="/sefaz_certificate"]` C9 | `Limpar` beside Arquivo; `Remover` stays the certificate delete C9, C11 | spacing, colour, type weight |

## Swept

- validation: existing — the four `:base` strings in C1–C4; this cut does not add a rule
- failure modes: C1, C2, C3, C4, C5, C6, C7 — `422` keeps typed document fields; A1 passphrase stays out of HTML; Stream does not replace the form; HTML file inputs stay empty
- idempotency and retry: C1, C5 — a second `422` with different params echoes that later payload (HTML) or leaves the live form (Stream); two valid inserts still persist two rows (existing)
- authorization: existing — `require_focused_organization` on documents; `require_coordinator_organization` on A1; submitter still uses the same insert template
- concurrency and ordering: n/a — each `422` is one form in one tab; two overlapping POSTs still do not share a form node; #38 still leaves one A1 slot
- data lifecycle: C2, C10 — no new Blob on refused insert; no failed `.pfx` in session or A1 columns; no backfill
- external-dependency failure: n/a — these `422`s are local validation / PKCS12 open; wrap-key `422` copy stays #71 / #82
- state transitions: C5, C7, C8, C9 and the task States — Stream keeps the filled form; `Limpar` returns that file control to empty without a submit
- observability: C4, C6, C10 — passphrase `errada` is absent from HTML and from `session` values; the source names no log, metric, or trace (`filter_parameters` already covers passphrase)

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| HTML `POST /supporting_documents` `422` echoes named by this cut (3) | NF without file C1 · recibo+XML C2 · chave `123` C3 | - |
| HTML `POST /sefaz_certificate` passphrase `422` (1) | wrong passphrase C4 | existing e-CPF / expired / wrap-key stay in `sefaz_certificates_spec` |
| Turbo Stream `422` POSTs (2) | documents C5 · sefaz C6 | - |
| browser keep-file after Stream `422` (1) | Recibo + `nota.xml` C7 | - |
| `Limpar` file controls (3) | insert `#photo` C8 · insert `#xml` C8 · A1 `#certificate` C9 | - |
| no failed-upload stash (3) | Blob count C10 · A1 columns C10 · session has no `errada` / PKCS12 C10 | - |
| `422` transport (2) | HTML C1–C4 · Turbo Stream C5–C6 | - |
| designed screens this cut binds (2) | `documents` C1, C8, C11 · `setup` C4, C9, C11 | - |
| visual-identity screens this cut does not bind (4) | — | `login`, `denied`, `home`, `month` — out of scope |
| `documents` / `setup` visual (3 properties × 9 states) | — | spacing, colour, type weight on the nine Screens rows |

- Claims naming a status code, route or response shape: C1, C2, C3, C4, C5, C6 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~29k (`index.html.erb` + `supporting_documents_controller.rb` + the 101 KB request spec) + S2 ~6k (`setup/show` + `sefaz_certificates_spec`) + S3 ~30k (same request specs plus a system spec; 101 KB spec not paid twice on a unique-file floor) + S4 ~8k (Stimulus + GET examples + system clicks) + S5 ~6k (`design.md` + docs spec + C10 assertions on the same POST examples) = ~79k if the large spec is counted once (~42k unique-file floor / 4 on ~167 KB of named files). All five slices stay under 150k and share the two forms. No split. One batch.

- Where the boundary fell: C1–C11 closed on this branch after the implementation commit.
- What the user settled mid-build: none.
- What was abandoned: `turbo_stream.action(:replace, targets: …)` — TagBuilder `#action` expects a DOM id as the second argument (`wrong number of arguments`). `#action_all` emits `targets=`. C7 re-enables `#xml` in the browser proof because Recibo chrome (#79) disables that control so a Turbo submit would omit the file and never hit `Recibo não tem XML`.
