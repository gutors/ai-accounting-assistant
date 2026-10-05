# Document insert form Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 37fe43bdbf7b3e2fc2526faed7af79d74c419339..b1aa7e9c4a16ed0507648f4d2c29fbc54054808c
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

Proofs: 13/13 named examples exist, ran, and passed at `b1aa7e9c4a16ed0507648f4d2c29fbc54054808c`. Faults: 3/3 mutants killed in a scratch worktree (cap five; surfaces the fix created or refreshed). Round 1 composition FAIL is closed: C4 now asserts insert-first, `md:grid-cols-2`, label order, chave/observation `md:col-span-2`, and `Incluir documento` on GET HTML.

## Binding sources

Issue #79 and design `### documents` opened this round (`gh issue view 79`; `.specs/features/visual-identity/design.md` lines 309–343). Step 1 scoped to screen `documents` insert because the fix touched the interface proofs. Copy/hide claims: carried from `08f86d82` (no contradiction then; checks unchanged). Arrangement: re-judged against the new C4/C13 assertions.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| https://github.com/gutors/ai-accounting-assistant/issues/79 | yes - `gh issue view 79` this round | none | - |
| `.specs/features/visual-identity/design.md` screen `documents` insert | yes - file in the repo, section `### documents` | none | none on the insert arrangement the Screens table assigns to C4/C13. C4 GET now asserts first `section`, `md:grid-cols-2` (768px `md`), label `for` order `kind amount date payee chave observation photo xml`, chave and observation parent `md:col-span-2`, submit `Incluir documento`. C13 `include`s `two columns from 768px` and `the insert form is the first section` in the markdown section. Ledger rows, Justificativas, Excluir, Usar dados da SEFAZ stay in approved Out of scope |

Visual unproven remains enumerated (spacing, colour, type weight). Not a blanket exemption.

## Checks

Proofs run in one invocation at `b1aa7e9c4a16ed0507648f4d2c29fbc54054808c`:

`/opt/homebrew/bin/ruby bin/rspec spec/requests/supporting_documents_spec.rb spec/system/document_kind_spec.rb spec/docs/document_insert_form_spec.rb -E "<13 names>" --format documentation` → **13 examples, 0 failures**. Each name appeared in the documentation output. `rg` located each `it` before the run.

Citations in `spec/requests/supporting_documents_spec.rb` and `spec/docs/document_insert_form_spec.rb` refreshed (fix touched those files). C7/C8 citations carried from `08f86d82` (`spec/system/document_kind_spec.rb` not in the fix diff).

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | GET 200; insert `label[for=date]` `Data`; `input#date[type=date]` value `2026-10-05` | named example ran, exit 0 | `spec/requests/supporting_documents_spec.rb:148` `have_http_status(:ok)`; `:150` `eq("Data")`; `:152` `eq("2026-10-05")` | PASS |
| C2 | Editar `input#date_{id}` value `2026-05-11` | named example ran, exit 0 | `spec/requests/supporting_documents_spec.rb:164` `eq("2026-05-11")` | PASS |
| C3 | insert and Editar labels exactly `Chave de acesso (opcional)` and `Observação (opcional)` | named example ran, exit 0 | `spec/requests/supporting_documents_spec.rb:176-180` four `eq(...)` on those strings | PASS |
| C4 | insert `select#kind` selected `nota_fiscal`; `#chave` and `#xml` present, not disabled, not hidden; Screens arrangement on this GET | named example ran, exit 0 | `:189-191` form is in `page.css("section").first`; `:192` `include("md:grid-cols-2")`; `:193` submit `Incluir documento`; `:194-196` label `for` `%w[kind amount date payee chave observation photo xml]`; `:197-198` chave and observation parent `md:col-span-2`; `:199` `eq("nota_fiscal")`; `:204-207` disabled nil and `html_visible?` true | PASS |
| C5 | Editar recibo selected `recibo`; chave/xml disabled and not visible; photo visible and not disabled | named example ran, exit 0 | `spec/requests/supporting_documents_spec.rb:217` `eq("recibo")`; `:221-226` disabled present, chave/xml not visible, photo visible not disabled | PASS |
| C6 | Editar NF selected `nota_fiscal`; chave/xml visible not disabled | named example ran, exit 0 | `spec/requests/supporting_documents_spec.rb:244` `eq("nota_fiscal")`; `:247-250` visible true, disabled nil | PASS |
| C7 | insert Tipo Recibo: chave/xml not visible and disabled; photo visible not disabled | named example ran, exit 0 | carried from `08f86d82`: `spec/system/document_kind_spec.rb:33-39` `not_to be_visible`, `be_disabled`, photo visible not disabled | PASS |
| C8 | insert Tipo back to NF: chave/xml visible not disabled | named example ran, exit 0 | carried from `08f86d82`: `spec/system/document_kind_spec.rb:51-54` `be_visible`, `not_to be_disabled` | PASS |
| C9 | POST recibo photo no XML → 302 `/supporting_documents`, chave nil, no XML blob, GET toast success `Pronto.` | named example ran, exit 0 | `spec/requests/supporting_documents_spec.rb:258-266` `:found`, `redirect_to("/supporting_documents")`, `chave` nil, `xml` not attached, `data-toast-kind` success, text includes `Pronto.` | PASS |
| C10 | POST NF chave `123` → none persisted, 422, notice and error toast `Informe a chave de acesso com 44 dígitos` | named example ran, exit 0 | `spec/requests/supporting_documents_spec.rb:274-279` count 0, `:unprocessable_content`, notice and toast that string | PASS |
| C11 | POST recibo + XML → none persisted, 422, notice and error toast `Recibo não tem XML` | named example ran, exit 0 | `spec/requests/supporting_documents_spec.rb:287-292` count 0, `:unprocessable_content`, notice and toast that string | PASS |
| C12 | POST NF 44-digit chave, consulta does not deliver → one row with that chave | named example ran, exit 0 | `spec/requests/supporting_documents_spec.rb:300-301` count 1, `chave` `eq("43260511222333000181550010000000011123456781")` at the assertion line | PASS |
| C13 | design.md `documents` records today date, optional labels, Recibo hide (photo only), plus arrangement phrases | named example ran, exit 0 | `spec/docs/document_insert_form_spec.rb:8-15` `include` / `match` on the markdown section, including `two columns from 768px` and `the insert form is the first section` — **no GET** | PASS (file claim) |

## Coverage (recomputed)

Designed-screens / insert-arrangement row recomputed this round. Other set rows: members unchanged in the fix; carried from `08f86d82` except as noted.

| Set (size) | Members from authority | Proof | Gap |
|---|---|---|---|
| date field sources (2) | insert `Date.current`; Editar `document_on` | C1, C2 | none — carried from `08f86d82` |
| optional labels (2×2) | insert/Editar chave and observation | C3 | none — carried from `08f86d82` |
| kind chrome states named in Checks (5) | insert NF GET; Editar recibo GET; Editar NF GET; insert Recibo change; insert NF change | C4–C8 | Landing also says Stimulus `change` on “that form”; Editar `change` has no proof — carried from `08f86d82` |
| POST outcomes this cut names (4) | recibo no XML; NF chave 123; recibo+XML; NF 44-digit no consulta | C9–C12 at HTTP | none for this named set |
| designed screens this cut binds (1) + insert arrangement | `documents` from the design heading; insert-first, two columns from 768px, paired field order, chave/observation full width, `Incluir documento` | C1, C3, C4, C7, C13. Arrangement members now asserted on GET in C4 (`section`.first, `md:grid-cols-2`, label order, `md:col-span-2`, submit value); C13 records the same phrases in `design.md` | none for those insert-arrangement members |
| visual-identity screens not bound (5) | `login`, `denied`, `home`, `setup`, `month` | — | out of scope as declared |
| `documents` visual (3×7) | spacing, colour, type weight | — | unproven as enumerated |

Kinds in the Stimulus table (`nota_fiscal`, `recibo`) each have GET initial proofs; insert `change` covers both members. Model Recibo XML / 44-digit chave remain at `spec/models/supporting_document_spec.rb` — existing, not added in this range.

## Test policy rows

Re-judged: still relevant. C13 remains a `design.md` file-read (task criterion 13). HTTP insert arrangement now lives in C4’s GET proof. Rows classifying untouched product files: carried from `08f86d82`.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | existing `SupportingDocument` insert (unchanged table); HTTP create | own layer + request spec | yes — C9–C12 HTTP; model examples already exist |
| Decides, not reached across a boundary | Stimulus `document_kind_controller.js` (`nota_fiscal` / `recibo`) | own layer; system because a request spec cannot fire `change` | yes — C7, C8 |
| Entry point that decides nothing | `SupportingDocumentsController#create` persist → `redirect_success` / else 422 + `toast_now` | request spec accepted / rejected | yes — C9, C12 accepted; C10, C11 rejected |
| Instrumentation | create body is insert + branch on `errors.empty?` | none of its own beyond consumer | follow — treated as the HTTP proofs above |

C13 is not an unmet HTTP row: the checklist priced it as a file-read of the binding design section. Live arrangement is C4.

## Faults injected

Isolate: `git worktree add /tmp/dif-insert-verify-r2 HEAD`. Real-tree porcelain before: `?? .checks/document-insert-form.verified.md`. Surfaces the fix created (C4 arrangement assertions, C13 new includes) plus C12’s assertion now holding the 44-digit literal. Scratch discarded with `git worktree remove --force`. Real tree porcelain after: `?? .checks/document-insert-form.verified.md` (matches baseline). HEAD still `b1aa7e9c4a16ed0507648f4d2c29fbc54054808c`.

| Mutation | Location | Killed |
|---|---|---|
| insert form `md:grid-cols-2` → `md:grid-cols-1` | scratch `app/views/supporting_documents/index.html.erb` | yes — C4 `expected ... to include "md:grid-cols-2"` at `:192` |
| documents wireframe `two columns from 768px` → `1024px` | scratch `.specs/features/visual-identity/design.md` (Tipo\|Valor line in `### documents`) | yes — C13 `include("two columns from 768px")` at `:11` |
| `SupportingDocument.insert` forces chave to 44 zeros | scratch `app/models/supporting_document.rb` | yes — C12 `eq("43260511222333000181550010000000011123456781")` at `:301` |

C7/C8/C1/C3/C5 share surfaces the fix did not touch; not re-injected. C8 still shares Stimulus with C7.

## Swept existing

Carried from `08f86d82`; controller lines re-read this round (file not in the fix):

- `SupportingDocumentsController` `before_action :require_focused_organization` — present (`app/controllers/supporting_documents_controller.rb:2`).
- create still `redirect_success` / `toast_now` on 422 — present (`:23`, `:26`).
- Cited existing constraints are there. Out-of-scope sweep rows are policy, not code.

## Gate

`/opt/homebrew/bin/ruby bin/rspec spec/requests/supporting_documents_spec.rb spec/system/document_kind_spec.rb spec/docs/document_insert_form_spec.rb -E "<C1–C13 example names>" --format documentation` — 13 passed, 0 failed at `b1aa7e9c4a16ed0507648f4d2c29fbc54054808c`.

## Ranked gaps

1. **Level (note)** — C13’s check prose still names `GET /supporting_documents` and the proof still only reads `design.md`. Live arrangement is now C4, so this is not a composition FAIL.
2. **Coverage (note)** — Landing Stimulus `change` is proven only on insert (C7/C8), not Editar.
