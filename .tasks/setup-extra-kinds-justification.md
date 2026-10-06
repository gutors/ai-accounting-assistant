# Setup: extra kinds with justification

> Build this with **tlc-implement**. Profile **`ui`**: screen `setup` is binding through
> `.specs/features/visual-identity/design.md` (criterion 15).
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

On `/setup`, the extra-exception section is only catalog names the organization added. The two
base document-exception kinds (`Tarifa bancária`, `Honorário do contador`) are absent from that
list, and an extra kind is a name with no sentence explaining why a payment needs no supporting
document. Issue #84 gives no conversion figure. The cost is that a coordinator cannot tell, on
setup, that those two marks already exist and are document-exempt, or record why a named extra is
exempt.

When this ships, screen `setup` (`GET /setup`) lists `Tarifa bancária` then `Honorário do
contador` at the top of that section with fixed justification copy, not as ExtraExceptionKind
rows. A new extra requires `justification`; the extra row shows name plus that text. Binding
design: `.specs/features/visual-identity/design.md` section `setup`. How the month page marks
tarifa, honorário, or extra stays #84 out of recorte.

15 criteria in 2 slices · 1 one-way door · 2 open, of which 0 block

## Criteria

### Fixed types at the top of the setup list

1. Given a signed-in coordinator of the focused organization with zero ExtraExceptionKind rows,
   when `GET /setup` runs, then the status is `200`, the body includes the heading `Tipos extras
   de exceção`, then `Tarifa bancária` with `Tarifa cobrada pelo banco; não há documento fiscal a
   anexar.`, then `Honorário do contador` with `Honorário do contador neste fechamento; isento de
   documento de suporte.`, it does not include `Nenhum tipo extra`, and ExtraExceptionKind count
   on that organization is `0`.
2. Always, `Tarifa bancária` and `Honorário do contador` on `/setup` are not
   `li[data-row="extra-exception-kind"]`.
3. While those two names are on `/setup`, their rows do not include `Desativar`, `Reativar`, or
   `Excluir`.
4. Given ExtraExceptionKind rows `Zeta` and `Alfa` on the focused organization, when `GET /setup`
   runs, then in the `Tipos extras de exceção` section the first occurrence of `Tarifa bancária`
   precedes `Honorário do contador`, which precedes `Alfa`, which precedes `Zeta`.
5. If a coordinator POSTs `/extra_exception_kinds` with `name` `Tarifa bancária` and a non-blank
   `justification`, then ExtraExceptionKind count stays `0`, the status is `422`, and `GET /setup`
   still includes exactly one `Tarifa bancária`.

### Extra kind justification

6. When `GET /setup` runs, then `form[action="/extra_exception_kinds"]` includes `#extra_exception_kind_name`
   whose label is `Nome`, an input `name="justification"` whose label is `Justificativa`, and
   submit `Adicionar tipo extra`. The `Tipos extras de exceção` section includes the column heading
   `Justificativa`.
7. When a coordinator POSTs `name` `Doação` and `justification` `Doação pontual sem nota.`, then
   the system persists one ExtraExceptionKind with those two values on the focused organization,
   responds `302` to `/setup`, and that extra-exception-kind row includes `Doação` and `Doação
   pontual sem nota.`
8. When a coordinator POSTs `name` `  Doação  ` and `justification` `  Doação pontual sem nota.  `,
   then the persisted name is `Doação` and the persisted justification is `Doação pontual sem
   nota.`
9. If a coordinator POSTs `name` `Doação` and `justification` blank, missing, or whitespace-only,
   then the system persists no ExtraExceptionKind and responds `422`.
10. If a coordinator POSTs `justification` `Doação pontual sem nota.` and blank `name`, then the
    system persists no ExtraExceptionKind and responds `422`.
11. When `/setup` lists extra exception kind `Doação`, then that `li[data-row="extra-exception-kind"]`
    includes its justification and does not include a control that submits a new `name` or
    `justification` for that kind.
12. If a coordinator PATCHes `justification=Outro texto` on extra exception kind `Doação`, then the
    persisted justification remains `Doação pontual sem nota.` (Unresolved 1).
13. When `/setup` lists deactivated extra exception kind `Doação`, then that row still includes
    `Doação pontual sem nota.`
14. If a coordinator POSTs `name` `Doação` and `justification` `Outro texto` while `Doação` already
    exists with `Doação pontual sem nota.`, then ExtraExceptionKind count stays `1`, the
    justification stays `Doação pontual sem nota.`, and the status is `422`.
15. `.specs/features/visual-identity/design.md` section `setup` lists `Tarifa bancária` and
    `Honorário do contador` with the two strings in criterion 1 at the top of `Tipos extras de
    exceção`, extra rows as name plus justification, the form as `Nome` / `Justificativa` /
    `Adicionar tipo extra`, and does not show `Nenhum tipo extra`.

## Out of scope

- How the month page marks tarifa, honorário, or extra — #84 Fora deste recorte
- Showing justification on `/months/:year_month`, on a payment row, or in the summary spreadsheet
- `Pronto.` toast on extra-kind create, deactivate, or delete — #76 listed other setup saves, not this resource; `ExtraExceptionKindsController` still `redirect_to "/setup"`
- Keeping typed extra-kind fields on `422` — #85 is document insert and A1
- Renaming an extra exception kind, deactivating the two base kinds, or persisting them as ExtraExceptionKind — `.tasks/extra-exception-kinds.md` / ADR-0003
- Accountant login, Drive writes, Open Finance, SEFAZ, NF-e issuance

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `setup` extras | empty extras | 1 - two fixed rows; no `Nenhum tipo extra` |
| screen `setup` extras | loading | n/a - Turbo full-page / redirect |
| screen `setup` extras | error state | 5, 9, 10, 14 - HTTP `422`; existing extra-kind `422` re-renders `/setup` with no new page-level notice |
| screen `setup` extras | unauthorised | existing - unauthenticated POST `302` `/login`; submitter POST/PATCH/DELETE `404` |
| screen `setup` extras | density and ordering | 2, 3, 4, 6, 11, 13 - fixed pair first; extras by name after; column `Justificativa` |
| screen `setup` extras | destructive action confirms | existing - unused `Excluir` submits immediately; fixed rows have no delete |
| HTML `GET /setup` | who may call it | existing - coordinator with focus |
| HTML `GET /setup` | error shape and codes | existing |
| HTML `GET /setup` | versioning | n/a - existing HTML surface |
| HTML `GET /setup` | rate limit | n/a - coordinator-only |
| HTML `POST /extra_exception_kinds` | who may call it | existing - coordinator create; 7 is the success shape with `justification` |
| HTML `POST /extra_exception_kinds` | error shape and codes | 5, 9, 10, 14 |
| HTML `POST /extra_exception_kinds` | versioning | n/a - existing HTML surface; body gains `justification` |
| HTML `POST /extra_exception_kinds` | rate limit | n/a - coordinator-only |
| HTML `PATCH /extra_exception_kinds/:id` | who may call it | existing - `active` only |
| HTML `PATCH /extra_exception_kinds/:id` | error shape and codes | 12 - `justification` on PATCH does not change the row |
| HTML `PATCH /extra_exception_kinds/:id` | versioning | n/a |
| HTML `PATCH /extra_exception_kinds/:id` | rate limit | n/a |
| collection extra exception kinds | grouping | existing - focused organization |
| collection extra exception kinds | naming | 7, 8 - trimmed name plus trimmed justification |
| collection extra exception kinds | ordering | 4 - fixed pair, then extras ascending name |
| collection extra exception kinds | duplicates | 14 - name still unique; a second justification does not create a second row |
| collection extra exception kinds | exception that does not fit | 1, 2, 5 - base kinds listed, not catalog rows |
| document `design.md` `setup` | structure / next | 15 |

## Swept

- validation: 8, 9, 10, 14
- failure modes: 5, 9, 10, 14
- idempotency and retry: 14 - a second include of the same name does not create a second row or replace justification
- authorization: existing - coordinator-only extra-kind routes; submitter `404`; unauthenticated `302` `/login`
- concurrency and ordering: existing - unique index on `(organization_id, lower(name))` still serializes two concurrent creates of the same name; justification is not a second identity
- data lifecycle: 7, 12, 13, Unresolved 1 - justification is stored on the catalog row; deactivate keeps it; unused DELETE still removes the row; existing rows need a NOT NULL backfill
- external-dependency failure: n/a - no new remote
- state transitions: n/a - ExtraExceptionKind active/deactivated/delete is unchanged; justification is not a lifecycle
- observability: n/a - no operator metric or log line is required

## Impact

| Front | What changes |
|---|---|
| domain | existing term: `Extra exception kind` meant a unique name besides the two base kinds; it now also keeps a required justification sentence. Callers: `ExtraExceptionKind` / `create_for` (`app/models/extra_exception_kind.rb`), setup list (`app/views/setup/show.html.erb`), `GLOSSARY.md` Extra exception kind row |
| domain | existing term: `Document exception` base presentation names `Tarifa bancária` and `Honorário do contador` stay enum marks on Payment, not ExtraExceptionKind. `/setup` today must not list them (`spec/requests/setup_spec.rb` “does not list Tarifa bancaria…”). After this task they appear as fixed rows, still with ExtraExceptionKind count `0`. Callers of the old invariant: that example; `.tasks/extra-exception-kinds.md` criterion 14 |
| stored data | add required `justification` on `extra_exception_kinds`. Seed creates none. Any existing ExtraExceptionKind row must be non-null before the constraint (Unresolved 1). `create_for` today takes only `name`; every spec caller of `ExtraExceptionKind.create_for` must pass justification once the column is required |

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| 1. Extra justification is a required column on the catalog row | `ExtraExceptionKind` has `justification`, required, trimmed, not unique. Identity remains the case-insensitive name per organization (ADR-0003). The two base kinds are not ExtraExceptionKind rows; their justification strings live in code next to `BASE_NAMES`. | Optional justification — #84 required on a new extra. A justification column on Payment — ADR-0003 already rejected extra text on Payment; this sentence is catalog, not per mark. Persisting tarifa/honorário as ExtraExceptionKind so they can share the column — #84 not persisted as extra; ADR-0003 base names stay distinct from the catalog. |

- Nothing else here is one-way. Heading copy, list chrome, and form field ids are criteria or placement. Door 1 reaches past this feature: later extra-kind suggestion (#37) reads this column; it must not invent a second justification store.

## Surface

| Route | In | Out | Status | Criteria |
|---|---|---|---|---|
| `GET /setup` | session, focus | setup HTML, fixed pair plus extras with justification | `200`, `302`, `404` | 1, 2, 3, 4, 6, 11, 13 |
| `POST /extra_exception_kinds` | session, focus, `name`, `justification` | ExtraExceptionKind | `302`, `422`, `404` | 5, 7, 8, 9, 10, 14 |
| `PATCH /extra_exception_kinds/:id` | session, focus, `active` ( `justification` ignored ) | ExtraExceptionKind | `302`, `404` | 12 |

## Sources

- https://github.com/gutors/ai-accounting-assistant/issues/84 - this cut: fixed types at the top of the setup list with code-pinned justification; new extra requires Justificativa; list shows name + justification; column on `extra_exception_kinds`; month marking out of recorte
- https://github.com/gutors/ai-accounting-assistant/issues/75 - umbrella: extra justification required; fixed types at the top with non-editable justification
- `.tasks/extra-exception-kinds.md` - catalog, uniqueness, deactivate, unused delete, base names not extras; criterion 14 (do not list the base names) is superseded on the screen by this task, not in persistence
- [ADR-0003](../docs/adr/0003-extra-exception-kinds.md) - extras are catalog rows, not enum values
- `.specs/features/visual-identity/design.md` section `setup` - **binding for the interface**: screen `setup`; extras block is amended by criterion 15
- `GLOSSARY.md` - Extra exception kind, Document exception
- [ADR-0001](../docs/adr/0001-rails-8-hotwire.md) - Rails 8 + Hotwire; no new runtime

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | open | Write-once justification (PATCH does not change it, same as name), and existing ExtraExceptionKind rows backfilled with `Isento de documento de suporte.` so NOT NULL can apply? | Criterion 12 and the stored-data row assume yes. Override: allow PATCH of `justification`, or a different backfill string. |
| 2 | open | Keep heading `Tipos extras de exceção` with no intro sentence under it (the two fixed rows sit immediately below the h2)? | Criteria 1 and 15 assume yes. Override: rename the heading and/or add copy under it. |
