# Home-open-month-list Verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: d66e199ca79f5b3376e5b1fde0ab638dce3e3ff0..3ff9d29b548651359efc6a6c3a1d0a033132e
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

Opened #77 via `gh issue view 77` (GitHub). Opened `.specs/features/visual-identity/design.md` as a file; coordinator `home` wireframe at the `### home — GET / (coordinator)` section. `.tasks/home-open-month-list.md` used as criteria source, not a second checklist.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| https://github.com/gutors/ai-accounting-assistant/issues/77 | yes - `gh issue view 77` | none — replace `month_field_tag` with select of today − 12 through + 12, previous calendar month initial, opened months stay links, toast via existing helper, invites out. Example `2026-09 → 2026-08` is the previous-month rule, not a fixed pair | — |
| `.specs/features/visual-identity/design.md` screen `home` | yes - file in the repo | none — line is `Mês  [ select today − 12 through today + 12, previous calendar month selected ]  [ Abrir mês ]`; ledger `year_month` + `Aberto` / `Fechado`; empty `Nenhum mês aberto`; submitter `home` has no picker | Pessoas, invites, org switcher — out of scope (#78 / this cut). `Aberto` / `Fechado` on the live ledger are C10 (design text) + existing markup, not a new HTML assertion in C3. Spacing, colour, type weight enumerated unproven |
| `.tasks/home-open-month-list.md` | yes - criteria 1–10 | none — C1–C10 match criteria 1–10 | Unresolved 1–3 left as `month_title`, UI-only window, `Date.current` |

Screens (ui) vs design: one bound screen (`home`). Arrangement the design decides that a selector reaches — ledger then `Mês` + `select` + `Abrir mês` posting to `/months`; submitter omit — has checks (C1, C3, C9, C10). Visual unproven is enumerated per state (spacing, colour, type weight), not a blanket fidelity clause.

## Checks

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | GET `/` 200; empty `Nenhum mês aberto`; one `select#year_month` named `year_month`; no month input; 25 values `2025-10`–`2027-10`; selected `2026-09` / `setembro de 2026`; first/last labels; label `Mês`; submit `Abrir mês` to `/months` | `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker lists 25 months from 2025-10 to 2027-10"` — ran, passed | `spec/requests/organizations_spec.rb:108` `have_http_status(:ok)` · `:109` include `Nenhum mês aberto` · `:112` month input nil · `:113` `css("select#year_month").size` `eq(1)` · `:115` name `year_month` · `:117-119` values `eq` `(0..24).map` from `Date.new(2025, 10, 1)` · `:121-124` selected/first/last · `:125` label `Mês` · `:126-129` submit `Abrir mês`, `action` `/months`, select in form | PASS |
| C2 | January window `2025-01`–`2027-01`, selected `2025-12` | `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker in January starts 2025-01 ends 2027-01"` — ran, passed | `spec/requests/organizations_spec.rb:142-144` `values.first` `eq("2025-01")` · `values.last` `eq("2027-01")` · selected `eq("2025-12")` | PASS |
| C3 | Ledger link `/months/2026-05` text includes `2026-05`; picker still has `2026-05` | `bin/rspec spec/requests/organizations_spec.rb -e "GET / lists opened 2026-05 and keeps it in the picker"` — ran, passed | `spec/requests/organizations_spec.rb:157-161` `a[href="/months/2026-05"]` · `link.text` include `2026-05` · `values` include `"2026-05"` | PASS |
| C4 | POST `2026-09` persists, 302 to `/months/2026-09`, toast success `Pronto.` | `bin/rspec spec/requests/months_spec.rb -e "POST /months 2026-09 persists Month and redirects"` — ran, passed | `spec/requests/months_spec.rb:48-53` count `eq(1)` · `:found` · `redirect_to("/months/2026-09")` · `data-toast-kind` `eq("success")` · text include `Pronto.` | PASS |
| C5 | Second POST `2026-05` count stays 1, 302, toast `Pronto.` | `bin/rspec spec/requests/months_spec.rb -e "POST /months 2026-05 a second time does not duplicate"` — ran, passed | `spec/requests/months_spec.rb:63-68` count `eq(1)` · `:found` · `redirect_to("/months/2026-05")` · toast success `Pronto.` | PASS |
| C6 | POST `2024-01` persists, 302 to `/months/2024-01` | `bin/rspec spec/requests/months_spec.rb -e "POST /months 2024-01 outside the picker window persists"` — ran, passed | `spec/requests/months_spec.rb:79-81` count `eq(1)` · `:found` · `redirect_to("/months/2024-01")` | PASS |
| C7 | Empty POST: no row, 422, notice and error toast `Informe um mês válido`, picker still C1 window and selected `2026-09` | `bin/rspec spec/requests/months_spec.rb -e "POST /months empty year_month re-renders the 25-month picker"` — ran, passed | `spec/requests/months_spec.rb:91` `not_to change(Month, :count)` · `:94` `:unprocessable_content` · `:95` `eq("Informe um mês válido")` · `:96-97` toast error that string · `:100-103` 25 values and selected `2026-09`. `[data-notice="error"]` is not named at `:95` (`error_notice_text`); house helper locates `p[role="alert"][data-notice="error"]` | PASS |
| C8 | POST `2026-13`: no Month, 422 | `bin/rspec spec/requests/months_spec.rb -e "POST /months 2026-13 returns 422"` — ran, passed | `spec/requests/months_spec.rb:167-171` `not_to change(Month, :count)` · `:unprocessable_content` | PASS |
| C9 | Submitter GET `/`: no `select#year_month`, no `Abrir mês` | `bin/rspec spec/requests/organizations_spec.rb -e "submitter home has no year_month picker"` — ran, passed | `spec/requests/organizations_spec.rb:170-171` `select#year_month` `be_nil` · body `not_to include("Abrir mês")` | PASS |
| C10 | Design `home` drops `Mês  [____]  [ Abrir mês ]`; select window + previous month; ledger `year_month` / `Aberto` / `Fechado` | `bin/rspec spec/docs/home_open_month_list_spec.rb -e "visual-identity home wireframe uses a month select"` — ran, passed | `spec/docs/home_open_month_list_spec.rb:8-15` `not_to include("Mês  [____]  [ Abrir mês ]")` · include `select`, `today − 12`, `today + 12`, `previous calendar month selected`, `year_month`, `Aberto`, `Fechado` | PASS |

Named examples exist in the feature diff (`spec/requests/organizations_spec.rb`, `spec/requests/months_spec.rb`, `spec/docs/home_open_month_list_spec.rb`) and each appeared individually in documentation output as passed at HEAD `3ff9d29`.

## Coverage (recomputed)

| Set (size) | Member -> proof | Unproven |
|---|---|---|
| picker `value`s at `2026-10-01` (25) | C1 `eq` of `(0..24)` from `2025-10-01` | - |
| `Date.current` samples (2) | October `2026-10-01` C1 · January `2026-01-15` C2 | - |
| option labels at `2026-10-01` (3 named) | first / selected / last C1 | remaining 22 `month_title` strings — same I18n format |
| opened month on home (2) | ledger link C3 · still an option C3 | - |
| `POST /months` outcomes (5) | new C4 · second POST C5 · outside window C6 · empty `422` C7 · `2026-13` C8 | - |
| who sees the picker (2) | coordinator C1 · submitter omit C9 | - |
| designed screens this cut binds (1) | `home` C1, C3, C7, C9, C10 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `setup`, `month`, `documents` |
| `home` visual (3 × 5 states) | — | spacing, colour, type weight |

Authority for the 25-month window is the task / #77 / design (`today − 12` through `today + 12`), not the helper. C1 asserts that set at HTTP. No extra enumerated set in Landing. Status/route claims C1, C4–C8 are asserted in request specs (`:ok`, `:found` / `redirect_to`, `:unprocessable_content`).

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | `app/models/month.rb` `Month.open` (existing; this cut adds no branch) | own layer + HTTP | yes — existing `spec/models/month_spec.rb`; C4–C8 at HTTP. C6 is the UI-only-window member |
| Decides, not reached across a boundary | none added | own layer | n/a |
| Entry point that decides nothing | `MonthsController#create` pass-through | request spec | yes — C4–C8 |
| Instrumentation / pass-through | `openable_month_options` / `previous_calendar_year_month` (Date arithmetic, no dispatch table) | consumer HTTP | yes — C1 enumerates 25 values; C2 samples January. Repo has no helper/view specs; matches analogue `month_title` |

Swept **existing**: `Month.open` `rescue ActiveRecord::RecordNotUnique` `app/models/month.rb:35-36`; unique index `db/schema.rb:156`; `Month::INVALID` `app/models/month.rb:10`; `before_action :require_coordinator_organization` `app/controllers/months_controller.rb:2`. Cited constraints are present. n/a / not-in-scope rows left as policy.

## Faults injected

Scratch: `git worktree add /tmp/home-open-month-list-verify-wt HEAD`. Real-tree porcelain before and after: empty. Worktree removed.

| Mutation | Location | Killed |
|---|---|---|
| picker range `(0..24)` → `(0..23)` | `application_helper.rb` `openable_month_options` | yes — C1, values end at `2027-09` not `2027-10` |
| previous month → current month (`prev_month` dropped) | `application_helper.rb` `previous_calendar_year_month` | yes — C2 selected `2026-01` not `2025-12` |
| `select#year_month` on submitter branch | `organizations/show.html.erb` | yes — C9 `select#year_month` not nil |
| wireframe line back to `Mês  [____]  [ Abrir mês ]` | `design.md` coordinator `home` | yes — C10 `not_to include` that string |
| drop option `2026-05` from picker | `application_helper.rb` `openable_month_options` | yes — C3 `values` exclude `2026-05` |

Cap 5. C4–C8 persist/422 live in existing `Month.open` / `MonthsController#create` (not new code). C7’s 25-value assertions share the C1 picker surface already killed.

## Gate

`bin/rspec spec/requests/organizations_spec.rb spec/requests/months_spec.rb spec/docs/home_open_month_list_spec.rb` with the ten `-e` names, `--format documentation --out` — 10 examples, 0 failures (Finished in 0.32212 seconds).
