# Document edit page Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 5b94f0e..36a0e13 (`5b94f0e..HEAD`)
**Round**: 2 - scoped (proofs re-run in full at `36a0e13`; step 1 and faults on the interface/template surfaces the fix touched, plus C20–C25)
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Opened as files or images in the repo (not URLs). `evidence-pane.webp` was viewed as the approved **Prova à esquerda** raster. Round-2 Sources, Landing, and `.impeccable/surfaces/app-views-supporting-documents.md` mark that raster **not authority for the SEFAZ band**; HTML prototype + FIRST VIEWPORT + C14 win there. That is a user-visible renegotiation of round-1 C14, not a silent checklist edit of the C14 claim.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| `.impeccable/mocks/document-edit.html` | yes - file | none | none — C20 actions row, C21 `XML` + `Limpar` close round-1 gaps |
| `.impeccable/mocks/decision/evidence-pane.webp` | yes - image | none vs **marked** authority (panes: photo left, 28rem book right). Raster still pixels-places the SEFAZ notice on the same visual row as Tipo; that is out of authority, same class as abbreviated `Chave` / `Observação` / `Nenhum XML` | none for pane composition (C10). Abbreviated copy already assigned to HTML + C19 |
| `.impeccable/surfaces/app-views-supporting-documents.md` | yes - file | none (FIRST VIEWPORT: SEFAZ band after h1 then split; thesis proof left / 28rem book) | — |
| `DESIGN.md` | yes - file | none (28rem, 768px two-column, file field `Nenhum arquivo` + chip + `Limpar`, no cards/shadows/extra icons, raw chave digits) | — C21 `Limpar`; C24/C25 390px |
| Conversation 2026-10-08 (checklist Sources) | yes - transcribed in the checklist | none | — |
| Checklist Landing SEFAZ band / actions row | yes | none vs C14 / C20 | — |

Visual unproven as enumerated: `01` spacing, colour, type weight. Named per screen and property — not a blanket.

Screen `01` enumeration (selector-reachable) vs checks: Voltar before h1 C10; h1 C1/C10; SEFAZ band full-width after h1 before split C14; split proof then book, `max-w-[28rem]`, `md:grid-cols-[minmax(0,1fr)_28rem]` C10; photo img/filename/`PHOTO_LOCKED` C12; empty photo C13; XML label/`Nenhum arquivo`/`Incluir XML`/`Limpar` C11+C21; locked XML C13; labels Tipo/Valor/Data/Favorecido/Observação C10; chave label C11; `#kind` disabled C10; Salvar then Excluir in one `[data-edit=actions]` in book C20; Excluir DELETE+confirm / absent with month C16; no `#photo` C12/C13; no list `<details>` C6. No extra icons on this template.

## Checks

Proofs run at `36a0e13` in **one** invocation: 31 examples, 0 failures (JSON `/tmp/document-edit-proofs-r2.json`). Each named example appears in that output as passed.

C1–C19 citations refreshed where the spec moved; C20–C25 new this round.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | GET edit coordinator `200`, `h1` `Editar documento` | `:2926` passed | `spec/requests/supporting_documents_spec.rb:2932-2933` `have_http_status(:ok)` · `h1` `eq("Editar documento")` | PASS |
| C2 | no session → `302` `/login` | `:2936` passed | `2942-2943` `:found` · `redirect_to("/login")` | PASS |
| C3 | submitter other Account → `404` | `:2946` passed | `2956` `:not_found` | PASS |
| C4 | submitter own → `200` | `:2959` passed | `2968` `:ok` | PASS |
| C5 | missing id `404`; other org `404` | `:2971` and `:2979` passed | `2976` `:not_found` · `2990` `:not_found` | PASS |
| C6 | list `Editar` is `a` to edit; no details; no PATCH form | `:2677` passed | `2685-2690` text `Editar`, href edit path, no details summary Editar, no `_method` patch | PASS |
| C7 | Sem mês row keeps `Excluir` DELETE + confirm in Ações | `:2693` passed | `2703-2706` action, `_method` delete, `data-turbo-confirm` `Excluir este documento?`, in `[data-cell=actions]` | PASS |
| C8 | month-assigned: Editar link, no Excluir | `:2709` passed | `2718-2719` href edit · no Excluir | PASS |
| C9 | list row text has no `Usar dados da SEFAZ` | `:500` passed | `512` `not_to include("Usar dados da SEFAZ")` | PASS |
| C10 | Voltar before h1; labels; `#kind` disabled; Salvar; book `max-w-[28rem]`; split cols; proof then book | `:2993` passed | `3000-3021` href, order, label strings, disabled, submit value, class includes, `children[0/1]` data-edit | PASS |
| C11 | NF: chave label, enabled, XML empty copy/chip; recibo hides `#chave` `#xml` | `:302` and `:289` passed | `318-326` `Chave de acesso (opcional)`, not disabled, `Nenhum arquivo` / `Incluir XML` · `297-298` nodes `be_nil` | PASS |
| C12 | attached photo: img blob src, `foto-antiga.jpg`, `PHOTO_LOCKED`, no `#photo` | `:2722` passed | `2731-2735` src includes `rails/active_storage`, filename, `include(SupportingDocument::PHOTO_LOCKED)`, no `#photo` | PASS |
| C13 | xml-only: `Nenhuma foto`, no lock sentence, no `#photo`, locked XML, no `Limpar` | `:2738` passed | `2747-2753` those strings/disabled/no Limpar | PASS |
| C14 | pending: margem notice after h1 before split + POST `Usar dados da SEFAZ`; not pending: neither | `:3024` and `:3044` passed | `3036-3041` sentence, form action `.../sefaz_confirm`, indices vs `h1` and split · `3050-3051` absence | PASS (round-1 FAIL vs raster **closed**: raster is not authority for this band) |
| C15 | typed: amount/date/payee present not disabled; locked XML: those ids absent | `:3054` and `:3066` passed | `3061-3063` disabled nil · `3075-3077` `be_nil` | PASS |
| C16 | `month_id` nil: Excluir DELETE + confirm; set: no Excluir | `:3080` and `:3094` passed | `3088-3091` delete + confirm · `3102` none Excluir | PASS |
| C19 | `#chave` value raw 44 digits | `:3105` passed | `3113` `eq(chave)` with `chave = "35240612345678000190550010000012341000012340"` | PASS |
| C17 | PATCH new photo → `422`, h1 Editar documento, notice+toast PHOTO_LOCKED, filename unchanged | `:2756` passed | `2763-2769` `:unprocessable_content`, h1 `Editar documento`, `error_notice_text` / toast vs `PHOTO_LOCKED`, filename `foto-antiga.jpg`. Notice hook `[data-notice=error]` is behind `error_notice_text`, not on the assertion line | PASS |
| C18 | visit edit: `#amount` `155,00` after interactive; `inputmode` numeric | `money_mask_spec.rb:39` and `:3116` passed | `45` `find("#amount").value` `eq("155,00")` · `3122` `inputmode` `eq("numeric")` | PASS |
| C20 | book `[data-edit=actions]` contains Salvar before Excluir; Excluir inside that row | `:3125` passed | `3131-3138` book → actions, submit value, Excluir descendant, index Salvar < Excluir | PASS |
| C21 | empty XML: `label[for=xml]` `XML`; field contains `Limpar` | `:3141` passed | `3156-3158` `eq("XML")` · any button text `Limpar` | PASS |
| C22 | DELETE month document `422`, `h1` `Documentos de suporte` | `:3161` passed | `3171-3172` `:unprocessable_content` · `h1` `eq("Documentos de suporte")` | PASS |
| C23 | POST sefaz_confirm uploaded XML `422`, `h1` `Documentos de suporte` | `:3175` passed | `3186-3187` `:unprocessable_content` · `h1` `eq("Documentos de suporte")` | PASS |
| C24 | documents list at 390: `h1` Documentos de suporte, `scrollWidth` `<= 390` | `screens_spec.rb:169` passed | `175-176` `have_css("h1", text: "Documentos de suporte")` · `scroll_width` `be <= 390` | PASS |
| C25 | edit at 390: `h1` Editar documento, `scrollWidth` `<= 390` | `screens_spec.rb:180` passed | `187-188` `have_css("h1", text: "Editar documento")` · `scroll_width` `be <= 390` (visits list then clicks Editar; lands on edit) | PASS |

## Coverage (recomputed)

Authority for the screen set is the HTML prototype + DESIGN + surface FIRST VIEWPORT (SEFAZ band), not the implementation. Raster is authority for pane composition only.

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| designed screens (1) | `01` C10–C16, C19–C21, C24, C25 (C18 mask) | - |
| GET edit who may call (4) | coordinator C1 · unauthenticated C2 · submitter other C3 · submitter own C4 | - |
| GET edit missing/foreign (2) | missing C5 · other org C5 | - |
| list Editar replacement (6) | link/no details/no PATCH C6 · Excluir kept C7 · month no Excluir C8 · no list SEFAZ C9 | - |
| SEFAZ chrome (2) | pending C14 · not pending C14 | - |
| photo pane (2) | attached C12 · missing C13 | - |
| XML field (4) | NF empty C11 · NF attached C13 · recibo hidden C11 · empty label+Limpar C21 | - |
| typed vs locked triple (2) | typed C15 · locked XML C15 | - |
| Excluir on edit (3) | `month_id` nil C16 · set C16 · actions row C20 | - |
| `422` update template (3) | `#update` → `:edit` C17 · `#destroy` → `:index` C22 · `#sefaz_confirm` → `:index` C23 | - |
| 390px no horizontal scroll (2) | documents list C24 · edit page C25 | - |
| startup config | no new boot setting | - |

Claims naming status/route/shape C1–C5, C17, C22, C23: each asserts at HTTP.

## Test policy rows

Re-judged rows that were unmet in round 1 and rows classifying files the fix touched (`edit.html.erb`, `supporting_documents_controller.rb`, `screens_spec.rb`, request spec).

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `mutate_document` (incumbent) | own layer + HTTP who-may-call | GET reuses the same guard; C1–C5 HTTP. Own-layer stay in existing specs — follow as incumbent |
| Decides, not reached across a boundary | none new | own layer | n/a |
| Entry point that decides nothing | `SupportingDocumentsController#edit` | request spec: accepted, each rejected, each error | C1 accepted · C2 unauth · C3–C5 404 — met |
| Instrumentation / pass-through | n/a | consumer | n/a |
| `#update`/`#destroy`/`#sefaz_confirm` 422 template dispatch | `render_document_error` | HTTP per member | `:edit` C17 · `:index` destroy C22 · `:index` sefaz C23 — met (round-1 unmet `:index` closed) |
| View HTML | `edit.html.erb`, list row | request spec | C6–C16, C19–C21 met |
| Mask prefill | Stimulus after connect | system | C18 met |
| 390 no horizontal scroll | `screens_spec.rb` | system | C24 list · C25 edit — met |

## Swept existing

Re-read (not carried blindly):

- `SupportingDocument::PHOTO_LOCKED` is still `"A foto não pode ser alterada. Exclua o documento e inclua novamente."` (`app/models/supporting_document.rb:11`).
- `mutate_document` still scopes org + coordinator-or-owner (`supporting_documents_controller.rb:86-91`); `#edit` calls it.
- `#destroy` / `#sefaz_confirm` still call `render_document_error` with default `template: :index` (`:100`); `#update` passes `template: :edit` (`:38`, `:53`).
- Justificativa list `<details>Editar` remains (`index.html.erb:116`).

## Faults injected

Scratch worktree `/Users/gutors/Developer/ai-accounting-assistant-tlc-verify-r2` at `36a0e13`. Real-tree porcelain after `worktree remove --force` matches baseline (untracked `.impeccable/` + this report). Surfaces: SEFAZ band and actions (fix), plus new C20/C21/C22/C25. C23 shares the default `template: :index` surface with C22.

| Mutation | Location | Killed |
|---|---|---|
| SEFAZ notice moved inside `[data-edit=split]` | `edit.html.erb` | yes — C14 index vs `data-edit="split"` |
| `Excluir` moved out of `[data-edit=actions]` | `edit.html.erb` | yes — C20 `excluir` nil |
| XML `field_label` `XML` → `Arquivo` | `edit.html.erb` | yes — C21 expected `"XML"` got `"Arquivo"` |
| `render_document_error` default `template: :index` → `:edit` | `supporting_documents_controller.rb:100` | yes — C22 (destroy rendered `:edit` and raised `recibo?` on nil `@document`) |
| split `style="min-width: 50rem"` | `edit.html.erb` | yes — C25 `scroll_width` 820 ≰ 390. (A Tailwind-only `min-w-[50rem]` class was a no-op and did not count.) |

Cap 5. C24 list 390 not separately injected.

## Gate

`bin/rspec` 31 named examples, 0 failed, at `36a0e13`.

Overall **PASS**: 25/25 checks proven; round-1 C14 / actions / XML / `:index` 422 / 390 gaps closed; five mutants killed.
