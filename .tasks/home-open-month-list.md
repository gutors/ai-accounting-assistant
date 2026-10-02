# Home: open month as a limited list

> Build this with **tlc-implement**. Profile **`ui`**: screen `home` is binding through
> `.specs/features/visual-identity/design.md` (criterion 10).
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

The coordinator home form for a new month is `month_field_tag :year_month, nil`: a native
`type=month` control whose value is empty. Issue #77 states the cost: that control requires the
person to know the `YYYY-MM` pattern. The issue gives no conversion figure. Already-opened months
are links; that list is not the problem. Success and error toasts on `POST /months` already exist
from #76 (`redirect_success` / `toast_now`).

When this ships, a coordinator on screen `home` (`GET /`) picks the month from a native select of
the 25 calendar months from `Date.current`’s month minus 12 through plus 12, with the previous
calendar month selected, and `Abrir mês` still posts `year_month` to `POST /months`. Opened months
stay `year_month` links. Invites are untouched.

10 criteria in 3 slices · 0 one-way doors · 3 open, of which 0 block

## Criteria

### Limited picker on home

1. Given `Date.current` is `2026-10-01` and a signed-in coordinator of the focused organization
   with no Month, when `GET /` runs, then the status is `200`, the body includes `Nenhum mês aberto`,
   the `Abrir mês` form posts to `/months`, there is one `select#year_month` with `name="year_month"`,
   there is no `input[type=month]` named `year_month`, that select has exactly 25 options whose
   `value`s in document order are `2025-10` through `2027-10` inclusive (one calendar month each),
   the selected option’s `value` is `2026-09` and its text is `setembro de 2026`, the first option’s
   text is `outubro de 2025`, the last option’s text is `outubro de 2027`, the field label is `Mês`,
   and the submit is `Abrir mês`.
2. Given `Date.current` is `2026-01-15` and a signed-in coordinator of the focused organization,
   when `GET /` runs, then `select#year_month` option `value`s in document order start at `2025-01`
   and end at `2027-01`, and the selected `value` is `2025-12`.
3. Given `Date.current` is `2026-10-01` and Month `2026-05` exists on the focused organization, when
   `GET /` runs, then `li[data-row="month"]` contains `a[href="/months/2026-05"]` whose text includes
   `2026-05`, and `select#year_month` still has an option whose `value` is `2026-05`.

### Opening a month

4. Given `Date.current` is `2026-10-01` and a signed-in coordinator of the focused organization with
   no Month `2026-09`, when `POST /months` runs with `year_month` `2026-09`, then one Month
   `2026-09` exists, the response is `302` to `/months/2026-09`, and the following `GET` has
   `[data-toast-kind="success"]` text `Pronto.`
5. Given Month `2026-05` already exists, when `POST /months` runs with `year_month` `2026-05`, then
   `organization.months.where(year_month: "2026-05").count` stays `1`, the response is `302` to
   `/months/2026-05`, and the following `GET` has `[data-toast-kind="success"]` text `Pronto.`
6. Given `Date.current` is `2026-10-01`, when `POST /months` runs with `year_month` `2024-01`, then
   one Month `2024-01` exists and the response is `302` to `/months/2024-01`.
7. Given `Date.current` is `2026-10-01`, when `POST /months` runs with `year_month` `""`, then no
   Month is persisted, the status is `422`, `[data-notice="error"]` is `Informe um mês válido`,
   `[data-toast-kind="error"]` is `Informe um mês válido`, and `select#year_month` still matches the
   25 values and selected `2026-09` in criterion 1.
8. When `POST /months` runs with `year_month` `2026-13`, then no Month is persisted and the status
   is `422`.
9. Given a signed-in submitter of the focused organization, when `GET /` runs, then the body has no
   `select#year_month` and does not include `Abrir mês`.

### Binding home wireframe

10. `.specs/features/visual-identity/design.md` section `home` — `GET /` (coordinator) no longer
    shows `Mês  [____]  [ Abrir mês ]`; it shows a `select` of months from today − 12 through today
    + 12 with the previous calendar month selected, and it still lists opened months as `year_month`
    links with `Aberto` / `Fechado`.

## Out of scope

- Invite forms, pending-invite rows, tipo, and email status — #78
- Changing opened-month row labels from `year_month` (`2026-05`) to `month_title`
- Closing, reopening, restore, statements, matches, exceptions
- Submitter home copy (`Início`) beyond omitting this control (9)
- Time zone / `config.time_zone` — Unresolved 3 uses `Date.current` as the app already does
- Restricting `Month.open` to the picker window — Unresolved 2; criterion 6 keeps today’s accept
  of any valid `YYYY-MM`

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `home` | empty state | 1 — `Nenhum mês aberto` and the select still render |
| screen `home` | loading state | n/a — Turbo full-page `GET /`; no pending chrome |
| screen `home` | error state | 7, 8 — `:base` notice plus error toast; picker still the window |
| screen `home` | unauthorised | 9 — submitter home has no picker; existing `POST /months` submitter `404` |
| screen `home` | density and ordering | 1, 2 — 25 months, oldest `value` first; 3 — opened rows keep `year_month` links |
| screen `home` | destructive action confirms | n/a — `Abrir mês` is not destructive; no confirm |
| HTML `POST /months` | response shape | 4, 5, 6 — `302` to `/months/{year_month}` |
| HTML `POST /months` | error shape and codes | 7, 8 — `422`, `Informe um mês válido` on empty; invalid `YYYY-MM` `422` |
| HTML `POST /months` | who may call it | existing — `require_coordinator_organization`; unauthenticated `302` `/login`; submitter `404` |
| HTML `POST /months` | versioning | n/a — existing HTML form; this cut does not publish an API |
| HTML `POST /months` | rate limit | n/a — coordinator-only, small operator set |
| document `.specs/features/visual-identity/design.md` | structure, tone, depth, next action | 10 |
| collection of picker months | grouping, naming, ordering, duplicates, exception | 1, 2 — one option per calendar month, `value` `YYYY-MM`, visible `month_title`, oldest first; 3 — already-opened months stay in the select |

## Swept

- validation: 7, 8 — empty and `2026-13` stay `Month::INVALID` / `422`; the picker does not add a
  second format
- failure modes: 7 — invalid open re-renders home with notice and error toast and keeps the picker
- idempotency and retry: 5 — a second `POST` of an already-open `year_month` does not insert a
  second row (`Month.open` returns the existing record)
- authorization: 9 and existing — submitter sees no picker; `POST /months` remains
  `require_coordinator_organization`
- concurrency and ordering: existing — `Month.open` `rescue ActiveRecord::RecordNotUnique` then
  `find_by!`; unique index on `(organization_id, year_month)`
- data lifecycle: n/a — no new column; existing Month rows stay; months outside the picker window
  are not deleted
- external-dependency failure: n/a — opening a month does not call Drive, SMTP, or SEFAZ
- state transitions: n/a — this cut does not change Month open/closed; `Month.open` is unchanged
  except as 4–8 already observe
- observability: n/a — the source names no log, metric, or trace; the person sees the select and
  the existing toast

## Impact

| Front | What changes |
|---|---|
| domain | no new glossary term — `CONTEXT.md` stays as it is |
| domain | existing term: Month `year_month` still means stored `YYYY-MM`; this cut only changes how home chooses it. Callers: `MonthsController#create`, `Month.open`, home list links, `/months/:year_month` |
| stored data | nothing to migrate — no schema change; existing months remain listed as links even when their `year_month` is outside the current picker window |

## Decided

None — a native `select` is the pattern already used for bank `compe` and document `kind`. The
±12 window is not persisted. `Month.open` and `POST /months` stay the existing contract aside from
the home control that fills `year_month`.

## Surface

| Route | In | Out | Status | Criteria |
|---|---|---|---|---|
| `GET /` | session, focus | `select#year_month` or submitter home | `200` | 1, 2, 3, 9 |
| `POST /months` | `year_month` | redirect to `/months/{year_month}` or home `422` | `302`, `422` | 4, 5, 6, 7, 8 |

## Sources

- https://github.com/gutors/ai-accounting-assistant/issues/77 — **binding for this slice**: replace
  `month_field_tag :year_month, nil` with a select (or accessible equivalent) of today − 12 through
  today + 12, initial previous calendar month, opened months stay links, toast via the existing
  helper, invites out
- https://github.com/gutors/ai-accounting-assistant/issues/75 — parent: abrir mês is that window and
  default; toast first (now #76 closed)
- https://github.com/gutors/ai-accounting-assistant/issues/76 — toast helper already on `POST /months`
  success (`Pronto.`) and on create `422` (`toast_now`)
- `.specs/features/visual-identity/design.md` — **binding for the interface** once criterion 10
  lands: screen `home`, opened-month ledger, empty `Nenhum mês aberto`
- `app/views/organizations/show.html.erb` — today’s `month_field_tag` and month list
- `app/helpers/application_helper.rb` `month_title` and `config/locales/pt-BR.yml`
  `date.formats.month_title` (`%B de %Y`) — Unresolved 1 default for option text
- `Month.open` / `Month::INVALID` — existing accept/reject of `year_month`
- Open defaults in Unresolved 1–3 — `month_title` labels, UI-only window, `Date.current`

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | open | Visible option text: `month_title` (`setembro de 2026`) or the stored `YYYY-MM`? #77 rejects typing the pattern; it does not name the label. | `month_title` via the existing helper (1, 2). `value` stays `YYYY-MM` |
| 2 | open | Must `POST /months` reject a valid `year_month` outside the picker window? #77 limits the control; `Month.open` today accepts any valid `YYYY-MM`. | UI-only window (6). Invalid format still `422` (7, 8) |
| 3 | open | Which clock is “hoje”? `config.time_zone` is unset (UTC). | `Date.current` (1, 2, 6, 7). This task does not set a zone |
