# Project state

Decisions that constrain later features live in `docs/adr/` (start from ADR-0001). Do not append `AD-NNN` rows here.

Live feature work is `.specs/features/<name>/` (`plan.md`, `checks.md`, `## Handoff`). Confirmed lessons load via `lessons.py`.

## Decisions

Pointer only - each row names the ADR that holds the question, the options and the consequence. The
decision text is never written here.

| ID | Decision | Rationale | Status | Date |
| --- | --- | --- | --- | --- |
| AD-0011 | The lote progress capture keeps two proof-square facts out of scope | user chose to record the two facts the capture draws (XML access key in the proof frame, `Definido pelo XML.` under Tipo) as differences instead of building them | active | 2026-11-17 |
| AD-0012 | Home-desk capture differences (fonts, Excluir, one-org chips, collapsed Pessoas) | superseded by AD-0013 — chips, row Excluir, and collapsed Pessoas are replaced; two-pane desk and one-org quiet remain | superseded by AD-0013 | 2026-11-18 |
| AD-0013 | Home-desk-select: header org list, selected month on the right, people pin | user locked Cadastro na mesa in `.specs/features/home-desk-select/plan.md` | active | 2026-11-18 |
| AD-0014 | Setup-desk capture differences (fonts, scene switcher) | user locked Pendências na lista in `.specs/features/setup-desk/plan.md`; product self-hosts IBM Plex and omits the prototype scene switcher | active | 2026-11-19 |
| AD-0015 | The month statement action is one icon in the row | user chose option 3 (one icon, no band) from `.impeccable/mocks/statement-files.html`; one control per row, `✓` only with a spreadsheet staged, no band on either state; the departed sketch facts are `docs/adr/0015-month-statement-row.md` | active | 2026-11-19 |
