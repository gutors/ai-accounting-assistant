# Documents list mask and actions Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: `4e6a4d3..f121f06462f6f20742c65ee0cd94447ddf76ec5a`
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Opened as files in the repo (not URL-only). Conversation 2026-10-08 is transcribed in `.tasks/documents-list-mask-and-actions.md` Sources.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.specs/features/visual-identity/design.md` screen `documents` | yes - file in the repo, `### documents` | none versus C1–C25 / Landing (empty insert Tipo vs wire `Tipo [v]` is the conversation amendment; Recibo-hide and five-column Sem mês match the opened section) | insert-first and two columns from 768px are not a *named* proof of this checklist; they remain asserted in `spec/requests/supporting_documents_spec.rb:189–192` and visual-identity C44. Optional labels, `Usar dados da SEFAZ`, Justificativas `h2` are prior `documents` work, not this cut’s criteria |
| `DESIGN.md` ledger / file-field | yes - file in the repo, Ledger row, File field, Buttons Quiet | none | disabled 50% opacity is colour (enumerated unproven). Quiet margem underline on `Excluir` is the system token (`text-margem underline` in the view); C9 asserts placement and confirm, not those classes |
| Conversation 2026-10-08 / `.tasks/documents-list-mask-and-actions.md` (this slice) | yes - task file | none. Task criterion 3 writes only the final `1,00`; C3 enumerates `0,01` / `0,10` / `1,00`, which matches the conversation’s centavos-first tape and C1 | Unresolved 2–3 copy stays the transcribed `:base` strings |

Visual unproven is enumerated per screen (spacing, colour, type weight) — not a blanket fidelity clause.

## Checks

Proofs: one `bin/rspec` invocation, 32 examples, 0 failures, at `f121f06`. Each named `it` exists (`rg -n`) and is in `4e6a4d3..HEAD`.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | insert `#amount` `0,00`; typing `1` `0` `0` → `0,01` `0,10` `1,00` | named example ran, exit 0 | `spec/system/money_mask_spec.rb:35` `eq("0,00")`; `:22–26` `eq("0,01")` then `0,10` then `1,00` | PASS |
| C2 | `#amount_{id}` `155,00` after interactive | named example ran, exit 0 | `spec/system/money_mask_spec.rb:45` `eq("155,00")` | PASS |
| C3 | insert `#justification_amount` `0,00` then same tape; `#justification_amount_{id}` `300,00` | both named examples ran, exit 0 | `:55` `eq("0,00")` plus `:22–26`; `:68` `eq("300,00")` | PASS |
| C4 | POST recibo amount `1,00` persists `amount_cents` `100` | named example ran, exit 0 | `spec/requests/supporting_documents_spec.rb:2611–2612` `count` `eq(1)`; `amount_cents` `eq(100)` | PASS |
| C5 | `inputmode` `numeric` on insert/edit document amounts and justification amounts | both named examples ran, exit 0 | `:2622–2623` `#amount` and `#amount_{id}` `eq("numeric")`; `:2636–2637` justification ids `eq("numeric")` | PASS |
| C6 | `.ledger-head.ledger-doc` five children `Data` `Favorecido` `Tipo` `Valor` `Ações` | named example ran, exit 0 | `:2646–2647` `eq([ "Data", "Favorecido", "Tipo", "Valor", "Ações" ])` | PASS |
| C7 | Tipo cell `Recibo`; Favorecido has payee and `foto.jpg`, not `Recibo` | named example ran, exit 0 | `:2665` kind `eq("Recibo")`; `:2667–2669` payee includes payee and `foto.jpg`, `not_to include("Recibo")` | PASS |
| C8 | PATCH form inside `<details>` summary `Editar`, not in Favorecido | named example ran, exit 0 | `:2680–2683` details not in payee, in actions; form ancestor is details. Helper `:458` summary `Editar` | PASS |
| C9 | `Excluir` DELETE + `Excluir este documento?` in Ações, not inside Editar | named example ran, exit 0 | `:2697–2702` action, `_method` delete, `data-turbo-confirm` `eq("Excluir este documento?")`; not inside details; inside actions | PASS |
| C10 | month-assigned row has Editar, no `Excluir` | named example ran, exit 0 | `:2709` `month_id`; `:2714–2715` details present; no Excluir button. Does not re-assert C8’s PATCH-in-details containment | PASS |
| C11 | design.md Sem mês is Data \| Favorecido \| Tipo \| Valor \| Ações; filenames under payee; Excluir not in Editar; kind not meta; Tipo locked | named example ran, exit 0 | `spec/docs/documents_list_mask_and_actions_spec.rb:8–13` `include` those phrases in the `documents` section | PASS |
| C12 | attached photo filename, `#photo_{id}` disabled, no Limpar | named example ran, exit 0 | `:2726–2728` include `foto-antiga.jpg`; `disabled` present; no Limpar | PASS |
| C13 | XML locked with filename; empty photo `Nenhum arquivo`, not disabled, Incluir foto + Limpar | named example ran, exit 0 | `:2740–2747` `autorizada.xml`, xml disabled, no Limpar; photo `Nenhum arquivo`, `Incluir foto`, disabled nil, Limpar | PASS |
| C14 | PATCH new photo 422, notice+toast criterion 14 string, filename kept | named example ran, exit 0 | `:2757` `:unprocessable_content`; `:2758/:2761` `PHOTO_LOCKED`; `:2762` `eq("foto-antiga.jpg")`. Constant `app/models/supporting_document.rb:11` is the checklist sentence | PASS |
| C15 | PATCH empty-slot photo 302, kind `nota_fiscal`, both filenames | named example ran, exit 0 | `:2772–2777` `:found`, redirect `/supporting_documents`, kind, `recibo-novo.jpg`, `autorizada.xml` | PASS |
| C16 | PATCH new XML 422, criterion 16 string, filename kept | named example ran, exit 0 | `:2787–2792` `:unprocessable_content`; `XML_LOCKED`; `:12` is the checklist sentence | PASS |
| C17 | insert `#photo` not disabled, `Nenhum arquivo`, has Limpar | named example ran, exit 0 | `:2802–2804` disabled nil; include `Nenhum arquivo`; Limpar present. XML hide is C24 | PASS |
| C18 | `apply` refuses attached photo/XML with those `:base` strings | both named examples ran, exit 0 | `:1588–1589` `PHOTO_LOCKED` + filename; `:1596–1597` `XML_LOCKED` + filename. `apply` delegates to `submit` (`supporting_document.rb:48–49`) | PASS |
| C19 | Editar kind disabled; insert kind enabled; Recibo hides chave/XML; NF shows them | named example ran, exit 0 | `:2823–2829` both `kind_{id}` disabled; insert `#kind` disabled nil; recibo chave/xml not visible; NF visible | PASS |
| C20 | PATCH kind flip 422 both directions, criterion 20 string, kind unchanged | both named examples ran, exit 0 | `:2839–2844` kind `nota_fiscal`, `:unprocessable_content`, `KIND_LOCKED`; `:2854–2859` kind `recibo`, same. Constant `:13` is the checklist sentence | PASS |
| C21 | `apply` refuses kind change both directions | both named examples ran, exit 0 | `:1604–1605` `KIND_LOCKED`, kind `nota_fiscal`; `:1612–1613` kind `recibo` | PASS |
| C22 | POST amount `0,00` no row, 422, `Informe valor, data e favorecido` | named example ran, exit 0 | `:2867–2872` `count` `eq(0)`; `:unprocessable_content`; notice and toast include the literal | PASS |
| C23 | insert `#kind` selected empty; options Nota fiscal / Recibo | named example ran, exit 0 | `:2881–2885` neither option selected; labels; `selected_option_value` `eq("")` | PASS |
| C24 | empty kind hides+disables chave/XML, photo visible; NF shows; Recibo hides | all three named examples ran, exit 0 | request `:2894–2899` hidden+disabled chave/xml, photo visible; system `:32–38` NF visible not disabled; `:49–55` Recibo hidden+disabled, photo not | PASS |
| C25 | POST empty kind no row, 422, `BAD_KIND` sentence | named example ran, exit 0 | `:2907–2912` `count` `eq(0)`; `:unprocessable_content`; `BAD_KIND`. Constant `:10` is `Informe se é nota fiscal ou recibo` | PASS |

## Coverage (recomputed)

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| mask fields (4) | insert `#amount` C1 · `#amount_{id}` C2 · `#justification_amount` C3 · `#justification_amount_{id}` C3 | - |
| `inputmode` numeric (4) | C5 both examples | - |
| Sem mês head cells (5) | C6 | - |
| Excluir placement (2) | C9 · C10 | - |
| attached-slot refuse (2) | photo C14+C18 · XML C16+C18 | - |
| empty-slot attach | photo on xml-only NF C15 | XML on a photo-only NF (Landing “empty slot still attaches” for XML) — no named proof |
| persisted kind refuse (2) | NF→recibo C20+C21 · recibo→NF C20+C21 | - |
| insert kind chrome (3) | empty C23+C24 · Nota fiscal C24 · Recibo C24 | C24 Recibo example selects Recibo from empty, not after Nota fiscal; same controller |
| insert POST outcomes (3) | C4 · C22 · C25 | - |
| designed screens this cut binds (1) | `documents` (design.md Screens) C1, C6, C11, C17, C23 | - |
| visual-identity screens not bound (5) | — | `login`, `denied`, `home`, `setup`, `month` |
| `documents` visual (3 × 7 states) | — | spacing, colour, type weight as the Screens table names |

HTTP claims C4, C14, C15, C16, C20, C22, C25 all assert status at the request spec.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `SupportingDocument#submit` / `#apply` photo lock, XML lock, kind lock | own layer C18, C21 · HTTP C14, C16, C20 | yes — both members each direction |
| Entry that decides nothing | `SupportingDocumentsController#update` (`apply` then 302/422) | request specs on those paths | yes — pass-through; contract is the `apply` errors |
| Instrumentation / browser API | `money_mask_controller.js`, `document_kind_controller.js` | system specs (repo has no JS unit runner) | yes — C1–C3, C24 |
| View HTML | `index.html.erb`, `_file_field.html.erb` | request specs | yes — C5–C13, C17, C19, C23, C24 GET |

Swept **existing** authorization: `require_focused_organization` (`supporting_documents_controller.rb:2`); `mutate_document` still 404 unless coordinator-or-owner (`:82–87`). Excluir still `month_id.nil?` (`index.html.erb:131`). Cited constraints are there.

## Faults injected

Scratch worktree `/tmp/tlc-verify-dlma` at HEAD. Real-tree porcelain before and after: `?? .impeccable/mocks/` only. Cap five; five distinct assertion surfaces.

| Mutation | Location | Killed |
|---|---|---|
| `formatCents` returns `` `${cents},00` `` (typing `1` → `1,00`) | scratch `app/javascript/controllers/money_mask_controller.js` | yes — C1 `expected "0,01" got "1,00"` (`money_mask_spec.rb:36` / helper `:22`) |
| photo-lock guard `&& false` | scratch `app/models/supporting_document.rb` | yes — C18 `expected [] to include PHOTO_LOCKED` (`:1588`) |
| kind-lock guard `&& false` | scratch `app/models/supporting_document.rb` | yes — C21 expected `KIND_LOCKED`, got `Envie a foto do recibo` (`:1604`) |
| insert Tipo defaults to `nota_fiscal`, no blank | scratch `app/views/supporting_documents/index.html.erb` | yes — C23 `selected` got `"selected"` (`:2881`) |
| Sem mês head drops `Tipo` | scratch `app/views/supporting_documents/index.html.erb` | yes — C6 expected five labels, got four (`:2647`) |

Worktree removed with `--force`.

## Gate

`bin/rspec spec/system/money_mask_spec.rb spec/system/document_kind_spec.rb spec/requests/supporting_documents_spec.rb spec/models/supporting_document_spec.rb spec/docs/documents_list_mask_and_actions_spec.rb` with every checklist `-e` selector — 32 passed, 0 failed.

## Ranked gaps (do not fail the round)

1. Empty-slot **XML** attach has no proof (Landing still says empty XML attaches).
2. C14, C16, C18, C20, C21, C25 expect `SupportingDocument::*LOCKED` / `BAD_KIND` rather than the Portuguese literal at the assertion line (values match `supporting_document.rb:10–13`).
3. This checklist’s Screens arrangement column names insert-first and `md:grid-cols-2` without a C-number; those remain asserted at `supporting_documents_spec.rb:189–192`.
