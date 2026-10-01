# Home: open month as a limited list

Profile: `ui`. Raised from the repo floor `standard` because `.tasks/home-open-month-list.md` marks screen `home` binding through `.specs/features/visual-identity/design.md` (criterion 10).

Sources:

- `.tasks/home-open-month-list.md` - criteria 1–10, the sweep, the boundary, Unresolved 1–3 (stay `month_title`, UI-only window, `Date.current`)
- https://github.com/gutors/ai-accounting-assistant/issues/77 - **binding for this slice**: replace `month_field_tag :year_month, nil` with a select of today − 12 through today + 12, initial previous calendar month, opened months stay links, toast via the existing helper, invites out
- https://github.com/gutors/ai-accounting-assistant/issues/75 - parent: abrir mês is that window and default; toast first (now #76 closed)
- https://github.com/gutors/ai-accounting-assistant/issues/76 - toast helper already on `POST /months` success (`Pronto.`) and on create `422` (`toast_now`)
- `.specs/features/visual-identity/design.md` - **binding for the interface**: screen `home`. Opened as a file in the repo. Section `home` — `GET /` (coordinator) today still draws `Mês  [____]  [ Abrir mês ]`; C10 replaces that line with the select. Opened-month ledger (`li[data-row="month"]`, `year_month` links, `Aberto` / `Fechado`) and empty `Nenhum mês aberto` stay
- `app/views/organizations/show.html.erb` - today’s `month_field_tag` and month list
- `app/helpers/application_helper.rb` `month_title` and `config/locales/pt-BR.yml` `date.formats.month_title` (`%B de %Y`) — Unresolved 1 default for option text
- `Month.open` / `Month::INVALID` — existing accept/reject of `year_month`

## Out of scope

- Invite forms, pending-invite rows, tipo, and email status — #78
- Changing opened-month row labels from `year_month` (`2026-05`) to `month_title`
- Closing, reopening, restore, statements, matches, exceptions
- Submitter home copy (`Início`) beyond omitting this control (C9)
- Time zone / `config.time_zone` — Unresolved 3 uses `Date.current` as the app already does
- Restricting `Month.open` to the picker window — Unresolved 2; C6 keeps today’s accept of any valid `YYYY-MM`
- Settling Unresolved 1–3

## Landing

Touches coordinator home (`organizations/show`) so `Abrir mês` posts `year_month` from a native `select` instead of `input[type=month]`. Reuses `select_tag` / `options_for_select` (same pattern as bank `compe` and document `kind`), `month_title`, `Month.open`, `redirect_success` / `toast_now`, and the opened-month ledger. No schema change.

None — a native `select` is already in the repo; the ±12 window is not persisted; `Month.open` and `POST /months` stay the existing contract aside from the home control that fills `year_month`.

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
- `Month.open` / `YEAR_MONTH` / `INVALID` already decide persist vs `:base` at the model (`spec/models/month_spec.rb`) and at HTTP (`spec/requests/months_spec.rb`). This cut does not add a branch there. C4–C8 are boundary proofs of that existing table plus the home re-render
- Picker window is Date arithmetic (`Date.current` month − 12 through + 12, previous calendar month selected) consumed by the home ERB. No enumerated dispatch. Closest analogue: `month_title` in `ApplicationHelper`, proven by request HTML. This repo has no view specs. C1 enumerates all 25 `value`s at HTTP; C2 is the January sample of the same formula
- `MonthsController#create` stays pass-through: persist → `redirect_success`; else `load_home` + `toast_now` + `422`
- Who may call `POST /months` is existing (`require_coordinator_organization`); C9 is GET-only omit of the control. Submitter POST `404` is already in `spec/requests/months_spec.rb`

Cost: request examples for C1–C9; file-read example for C10. No new model spec, no system spec (a request spec reaches `select` options). Without the C1 enumeration, a 24-option window could still pass C2.

## Checks

Criteria 1–10 map to C1–C10. Unresolved 1–3 stay `month_title`, UI-only window, and `Date.current`.

### S1 - Limited picker on home · 4 files · 20 KB · ~5k

**C1** - Given `Date.current` is `2026-10-01` and a signed-in coordinator of the focused organization with no Month, when `GET /` runs, then the status is `200`, the body includes `Nenhum mês aberto`, the `Abrir mês` form posts to `/months`, there is one `select#year_month` with `name="year_month"`, there is no `input[type=month]` named `year_month`, that select has exactly 25 options whose `value`s in document order are `2025-10` through `2027-10` inclusive (one calendar month each), the selected option’s `value` is `2026-09` and its text is `setembro de 2026`, the first option’s text is `outubro de 2025`, the last option’s text is `outubro de 2027`, the field label is `Mês`, and the submit is `Abrir mês`.
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker lists 25 months from 2025-10 to 2027-10"`

**C2** - Given `Date.current` is `2026-01-15` and a signed-in coordinator of the focused organization, when `GET /` runs, then `select#year_month` option `value`s in document order start at `2025-01` and end at `2027-01`, and the selected `value` is `2025-12`.
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "GET / picker in January starts 2025-01 ends 2027-01"`

**C3** - Given `Date.current` is `2026-10-01` and Month `2026-05` exists on the focused organization, when `GET /` runs, then `li[data-row="month"]` contains `a[href="/months/2026-05"]` whose text includes `2026-05`, and `select#year_month` still has an option whose `value` is `2026-05`.
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "GET / lists opened 2026-05 and keeps it in the picker"`

### S2 - Opening a month · 2 files · 65 KB · ~16k

**C4** - Given `Date.current` is `2026-10-01` and a signed-in coordinator of the focused organization with no Month `2026-09`, when `POST /months` runs with `year_month` `2026-09`, then one Month `2026-09` exists, the response is `302` to `/months/2026-09`, and the following `GET` has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months 2026-09 persists Month and redirects"`

**C5** - Given Month `2026-05` already exists, when `POST /months` runs with `year_month` `2026-05`, then `organization.months.where(year_month: "2026-05").count` stays `1`, the response is `302` to `/months/2026-05`, and the following `GET` has `[data-toast-kind="success"]` text `Pronto.`
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months 2026-05 a second time does not duplicate"`

**C6** - Given `Date.current` is `2026-10-01`, when `POST /months` runs with `year_month` `2024-01`, then one Month `2024-01` exists and the response is `302` to `/months/2024-01`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months 2024-01 outside the picker window persists"`

**C7** - Given `Date.current` is `2026-10-01`, when `POST /months` runs with `year_month` `""`, then no Month is persisted, the status is `422`, `[data-notice="error"]` is `Informe um mês válido`, `[data-toast-kind="error"]` is `Informe um mês válido`, and `select#year_month` still matches the 25 values and selected `2026-09` in criterion 1.
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months empty year_month re-renders the 25-month picker"`

**C8** - When `POST /months` runs with `year_month` `2026-13`, then no Month is persisted and the status is `422`.
Proof: `bin/rspec spec/requests/months_spec.rb -e "POST /months 2026-13 returns 422"`

**C9** - Given a signed-in submitter of the focused organization, when `GET /` runs, then the body has no `select#year_month` and does not include `Abrir mês`.
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home has no year_month picker"`

### S3 - Binding home wireframe · 2 files · 20 KB · ~5k

**C10** - `.specs/features/visual-identity/design.md` section `home` — `GET /` (coordinator) no longer shows `Mês  [____]  [ Abrir mês ]`; it shows a `select` of months from today − 12 through today + 12 with the previous calendar month selected, and it still lists opened months as `year_month` links with `Aberto` / `Fechado`.
Proof: `bin/rspec spec/docs/home_open_month_list_spec.rb -e "visual-identity home wireframe uses a month select"`

## Screens (ui)

Design opened: `.specs/features/visual-identity/design.md` (file in the repo). Until C10 lands, the picker arrangement values are the task transcription; ledger, empty state, and submitter home come from the opened `home` section.

| Screen | Copy and elements (selector) | Arrangement (selector) | Visual unproven |
| --- | --- | --- | --- |
| `home` coordinator, empty | `Nenhum mês aberto`; label `Mês`; one `select#year_month` `name="year_month"`; 25 options `2025-10`–`2027-10`; selected `2026-09` `setembro de 2026`; first text `outubro de 2025`; last text `outubro de 2027`; submit `Abrir mês`; no `input[type=month]` named `year_month` C1 | `Abrir mês` form posts to `/months`; select sits with the month list (empty copy, then the form); opened-month ledger absent C1 | spacing, colour, type weight |
| `home` coordinator, January | `select#year_month` values start `2025-01` end `2027-01`; selected `2025-12` C2 | same home form as C1 C2 | spacing, colour, type weight |
| `home` coordinator, opened months | `li[data-row="month"]` `a[href="/months/2026-05"]` text includes `2026-05`; select still has `value` `2026-05` C3 | ledger of `year_month` links then `Aberto` / `Fechado`; picker does not drop already-opened months C3, C10 | spacing, colour, type weight |
| `home` coordinator, empty `year_month` `422` | `[data-notice="error"]` `Informe um mês válido`; `[data-toast-kind="error"]` that same string; picker still the C1 window C7 | notice under `Meses`; toast in the layout slot; select remains the 25-month window with selected `2026-09` C7 | spacing, colour, type weight |
| `home` submitter | no `select#year_month`; no `Abrir mês` C9 | existing `Início` body; this cut does not add the picker C9 | spacing, colour, type weight |

## Swept

- validation: C7, C8 — empty and `2026-13` stay `Month::INVALID` / `422`; the picker does not add a second format
- failure modes: C7 — invalid open re-renders home with notice and error toast and keeps the picker
- idempotency and retry: C5 — a second `POST` of an already-open `year_month` does not insert a second row (`Month.open` returns the existing record)
- authorization: C9 and existing — submitter sees no picker; `POST /months` remains `require_coordinator_organization`
- concurrency and ordering: existing — `Month.open` `rescue ActiveRecord::RecordNotUnique` then `find_by!`; unique index on `(organization_id, year_month)`
- data lifecycle: n/a — no new column; existing Month rows stay; months outside the picker window are not deleted
- external-dependency failure: n/a — opening a month does not call Drive, SMTP, or SEFAZ
- state transitions: n/a — this cut does not change Month open/closed; `Month.open` is unchanged except as C4–C8 already observe
- observability: n/a — the source names no log, metric, or trace; the person sees the select and the existing toast

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| picker `value`s at `2026-10-01` (25) | C1, asserted in document order `2025-10` through `2027-10` | - |
| `Date.current` samples (2) | October `2026-10-01` C1 · January `2026-01-15` C2 | - |
| option labels at `2026-10-01` (3 named) | first `outubro de 2025` C1 · selected `setembro de 2026` C1 · last `outubro de 2027` C1 | remaining 22 `month_title` strings — same I18n format |
| opened month on home (2) | ledger link `2026-05` C3 · still an option C3 | - |
| `POST /months` outcomes (5) | new persist C4 · second POST C5 · outside window C6 · empty `422` C7 · `2026-13` `422` C8 | - |
| who sees the picker (2) | coordinator C1 · submitter omit C9 | - |
| designed screens this cut binds (1) | `home` C1, C3, C7, C9, C10 | - |
| visual-identity screens this cut does not bind (5) | — | `login`, `denied`, `setup`, `month`, `documents` — out of scope |
| `home` visual (3 properties × 5 states) | — | spacing, colour, type weight on empty, January, opened, `422`, submitter |

- Claims naming a status code, route or response shape: C1, C4, C5, C6, C7, C8 — each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~5k (home ERB, helper, `organizations_spec`) + S2 ~16k (`months_spec` paid in full because proofs live there) + S3 ~5k (design.md + docs spec) = ~26k token floor. Unique files ~104k bytes / 4. All three slices stay under 150k and share home HTML. No split. One batch.
