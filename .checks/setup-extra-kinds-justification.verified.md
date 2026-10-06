# Setup extra kinds with justification Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: 9fd4f9c..03d7e9f
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

Proofs re-run in full at `03d7e9f`. Round-1 SHA `c888200`. Re-judged: C6, step-1 arrangement for `setup`, Coverage designed-screens row, Test policy extras-view row, faults on the fix surface. Other check verdicts carried from `c888200` with citations on `setup_spec.rb` refreshed (that file moved).

Opened `.specs/features/visual-identity/design.md` as a file; section `### setup — GET /setup` (lines 226–266). No contradiction between that drawing and C1–C15 copy. Visual exemption is enumerated (`spacing, colour, type weight on extras`), not a blanket clause.

## Binding sources

verified at `03d7e9f` (fix touched `setup/show.html.erb`)

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| design.md section `setup` | yes - repo file `.specs/features/visual-identity/design.md` lines 226–266 | none | none — round-1 arrangement members are now isolated: extras last among `div.space-y-12 > section > h2` (C1); h2 then `ul` with no intro `p` (C1); column heading `Justificativa` as `li[data-row="extras-column-headings"]` above the rows and outside the form (C6); form after that list (C6) |

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | 200; h2 then Tarifa+copy then Honorário+copy; no `Nenhum tipo extra`; extra count 0 | `./bin/rspec spec/requests/setup_spec.rb spec/requests/extra_exception_kinds_spec.rb spec/models/extra_exception_kind_spec.rb spec/docs/setup_extra_kinds_justification_spec.rb` at `03d7e9f` — example ran, exit 0 | `spec/requests/setup_spec.rb:415` `have_http_status(:ok)`; `:417` last setup h2 `eq("Tipos extras de exceção")`; `:418–419` `h2 + ul` present / `h2 + p` nil; `:426–436` heading &lt; tarifa &lt; tarifa_copy &lt; honorario &lt; honorario_copy; `not_to include("Nenhum tipo extra")`; count `eq(0)`. Citations refreshed at `03d7e9f` | PASS |
| C2 | Tarifa and Honorário are not `li[data-row="extra-exception-kind"]` | same invocation — example ran | `spec/requests/setup_spec.rb:450–453` extra-row texts omit those names while the extras section still includes them. Citations refreshed at `03d7e9f`; claim carried from `c888200` | PASS |
| C3 | fixed rows omit Desativar / Reativar / Excluir | same invocation — example ran | `spec/requests/setup_spec.rb:466–469` `not_to include` those three strings on each located fixed row. Citations refreshed at `03d7e9f`; claim carried from `c888200` | PASS |
| C4 | extras section order Tarifa then Honorário then Alfa then Zeta | same invocation — example ran | `spec/requests/setup_spec.rb:486–488` successive `index` inequalities. Citations refreshed at `03d7e9f`; claim carried from `c888200` | PASS |
| C5 | POST Tarifa + justification → count 0, 422, exactly one Tarifa on GET /setup | same invocation — both examples ran | request `spec/requests/extra_exception_kinds_spec.rb:83–87` `:unprocessable_content`, count `0`, `scan("Tarifa bancária").size eq(1)`; model `spec/models/extra_exception_kind_spec.rb:69–70` not persisted, count `0`. Carried from `c888200` | PASS |
| C6 | form Nome / `#extra_exception_kind_name` / justification input labeled Justificativa / submit Adicionar tipo extra; section column heading Justificativa | same invocation — example ran | form `spec/requests/setup_spec.rb:499–504`. Column heading isolated at `:505–509`: `li[data-row="extras-column-headings"]` text `eq("Justificativa")`, `heading.ancestors("form")` empty, first `li` in `h2 + ul` is that heading. Form after the list `:510` `form.previous_element` `eq(list)`. Re-judged at `03d7e9f` | PASS |
| C7 | POST Doação + justification persists, 302 `/setup`, row shows both | same invocation — both examples ran | request `spec/requests/extra_exception_kinds_spec.rb:10–20` `:found`, `redirect_to("/setup")`, name and justification; model `spec/models/extra_exception_kind_spec.rb:13–16` persisted equalities. Carried from `c888200` | PASS |
| C8 | POST trims name and justification | same invocation — both examples ran | request `spec/requests/extra_exception_kinds_spec.rb:30–31`; model `spec/models/extra_exception_kind_spec.rb:26–27` `eq("Doação")` / `eq("Doação pontual sem nota.")`. Carried from `c888200` | PASS |
| C9 | POST blank / missing / whitespace justification → none persisted, 422 | same invocation — all six examples ran | request `spec/requests/extra_exception_kinds_spec.rb:116–117`, `:126–127`, `:136–137` `:unprocessable_content` and count `0`; model `spec/models/extra_exception_kind_spec.rb:92–93`, `:99–100`, `:106–107` not persisted, count `0`. Carried from `c888200` | PASS |
| C10 | POST blank name + justification → none persisted, 422 | same invocation — both examples ran | request `spec/requests/extra_exception_kinds_spec.rb:106–107`; model `spec/models/extra_exception_kind_spec.rb:85–86`. Carried from `c888200` | PASS |
| C11 | extra row shows justification and has no name/justification fields | same invocation — example ran | `spec/requests/setup_spec.rb:524–526` include justification; `at_css` name and justification fields `be_nil`. Citations refreshed at `03d7e9f`; claim carried from `c888200` | PASS |
| C12 | PATCH justification=Outro texto leaves `Doação pontual sem nota.` | same invocation — example ran | `spec/requests/extra_exception_kinds_spec.rb:170` `eq("Doação pontual sem nota.")`. Carried from `c888200` | PASS |
| C13 | deactivated extra row still includes justification | same invocation — example ran | `spec/requests/setup_spec.rb:540` `include("Doação pontual sem nota.")`. Citations refreshed at `03d7e9f`; claim carried from `c888200` | PASS |
| C14 | POST duplicate Doação with other justification → count 1, original justification, 422 | same invocation — both examples ran | request `spec/requests/extra_exception_kinds_spec.rb:58–60`; model `spec/models/extra_exception_kind_spec.rb:50–52`. Carried from `c888200` | PASS |
| C15 | design.md setup extras lists fixed pair + strings, extra name+justification, form Nome / Justificativa / Adicionar tipo extra, no `Nenhum tipo extra` | same invocation — example ran | `spec/docs/setup_extra_kinds_justification_spec.rb:9–16` index order, includes, `not_to include("Nenhum tipo extra")`. Carried from `c888200` | PASS |

## Coverage (recomputed)

Authority for designed `setup` extras is the opened design, not the view. Designed-screens row re-judged at `03d7e9f`. Other set rows carried from `c888200` (fix did not change those authorities).

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| reserved names refused as extras (2) from `ExtraExceptionKind::BASE_NAMES` | `Tarifa bancária` C5 · `Honorário do contador` `spec/requests/extra_exception_kinds_spec.rb:90` and `spec/models/extra_exception_kind_spec.rb:73` (both send a justification) | - |
| POST justification absence (3) | blank C9 · missing C9 · whitespace-only C9 | - |
| list order tokens (4) | Tarifa then Honorário then Alfa then Zeta C4 | - |
| ExtraExceptionKind create outcomes this cut names (6) | persist C7 · trim C8 · blank/missing/whitespace C9 · blank name C10 · duplicate keeps original C14 · reserved C5 | - |
| PATCH fields that must not rewrite identity (2) | `name` `spec/requests/extra_exception_kinds_spec.rb:149` · `justification` C12 | - |
| extras list row kinds (2) | fixed chrome C2, C3 · catalog `li[data-row="extra-exception-kind"]` C7, C11, C13 | - |
| designed screens this cut binds (1) | `setup` C1–C4, C6, C11, C13, C15. C6 now isolates the column heading as its own `li` outside the form; C1 isolates last extras section and no intro under the h2 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `home`, `month`, `documents` — out of scope |
| `setup` extras visual (3 properties) | — | spacing, colour, type weight on extras |
| Landing / Unresolved 1 backfill (1) | — | `Isento de documento de suporte.` then NOT NULL — present in `db/migrate/20261005210000_add_justification_to_extra_exception_kinds.rb:5–9`, no named check. Carried from `c888200`. Unresolved 1 is open by checklist policy, not a missing C-row |

Claims naming status/route/shape (C1, C5, C7, C9, C10, C12, C14) each have a request-spec assertion at that boundary except C12, which names only the persisted justification (request example asserts that value; it does not name a status). Carried from `c888200`.

## Test policy rows

extras-view row re-judged at `03d7e9f`. Other rows carried from `c888200`.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, reached across a boundary | `app/models/extra_exception_kind.rb` (`create_for`, trim, presence, reserved `BASE_NAMES`) | own layer + request spec; one case per member | yes for the create members in Coverage — C5, C7–C10, C14. Carried from `c888200` |
| Decides, not reached across a boundary | extras HTML in `app/views/setup/show.html.erb` | request spec on `GET /setup` (repo has no view specs) | form/order/fixed-row claims yes · column heading `Justificativa` yes (C6 `:505–509`) |
| Entry point that decides nothing | `ExtraExceptionKindsController#create` maps persisted? to 302/422 | request specs for accepted and each rejected input | yes — C7 accept; C5, C9, C10, C14 rejects. Carried from `c888200` |
| Instrumentation / pass-through | `ExtraExceptionKindsController#update` (`apply_active` only; ignores `justification`) | consumer/HTTP contract C12 | yes — C12. Carried from `c888200` |

## Swept existing

carried from `c888200` (fix did not touch these)

- authorization: `ExtraExceptionKindsController` `before_action :require_coordinator_organization` (`app/controllers/extra_exception_kinds_controller.rb:2`); `ApplicationController#require_coordinator_organization` (`app/controllers/application_controller.rb:56–62`) still 302 `/login` without focus and 404 unless coordinator. Existing examples in the same run: unauthenticated POST 302 `/login`; submitter POST/PATCH/DELETE 404; submitter `GET /setup` 404.
- concurrency: unique index `index_extra_exception_kinds_on_org_id_and_lower_name` still in `db/schema.rb:107`; model example `concurrent creates persist exactly one ExtraExceptionKind` ran in the same files.
- data lifecycle DELETE unused: `destroy_if_unused` unchanged; existing request/model delete examples ran.

## Faults injected

Scratch: `git worktree add /tmp/tlc-verify-extra-kinds-justification-r2 HEAD` (`03d7e9f`). Real-tree porcelain before and after: `?? .checks/setup-extra-kinds-justification.verified.md` (match). Scratch removed with `git worktree remove --force`. No stash. Restored mutated view with `git checkout --` in the scratch (no `reset --hard`).

Round-2 re-inject on the fix surface (heading isolation) and the new C1 arrangement assertions. Round-1 kills on C4 / C12 / C9 / C15 carried from `c888200`.

| Mutation | Location | Killed |
|---|---|---|
| emptied extras column heading `span` Justificativa (form label kept; `data-row` li kept) | `app/views/setup/show.html.erb` heading `li` | yes — C6 `spec/requests/setup_spec.rb:506` expected `"Justificativa"` got `""` |
| inserted intro `<p>` between extras h2 and `ul` | `app/views/setup/show.html.erb` | yes — C1 `spec/requests/setup_spec.rb:418` `h2 + ul` nil |
| `BASE_NAMES` order reversed | `app/models/extra_exception_kind.rb:2` | yes — C4. Carried from `c888200` |
| `update` writes `params[:justification]` | `app/controllers/extra_exception_kinds_controller.rb:26` | yes — C12. Carried from `c888200` |
| `create_for` substitutes a default when justification is blank | `app/models/extra_exception_kind.rb:18` | yes — C9. Carried from `c888200` |
| deleted Tarifa line from design extras ascii | `.specs/features/visual-identity/design.md` | yes — C15. Carried from `c888200` |

A third mutant (form before the list) was not run: it would fail the same C6 example already killed by the heading mutant.

## Gate

`./bin/rspec spec/requests/setup_spec.rb spec/requests/extra_exception_kinds_spec.rb spec/models/extra_exception_kind_spec.rb spec/docs/setup_extra_kinds_justification_spec.rb --format documentation` at `03d7e9f` — 87 passed, 0 failed (includes pre-existing examples in those files). Every named proof example appeared as passed in that output before fault injection.
