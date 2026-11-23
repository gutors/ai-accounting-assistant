# LESSONS - auto-maintained by scripts/lessons.py

> Machine-owned. Do NOT hand-edit. Changes are overwritten on the next `lessons.py` write.
> Canonical state lives in `.specs/lessons.json`. Edit lessons only via the script.
> promote_threshold=2 distinct features · window_days=45 · quarantine_threshold=2

## Confirmed (load these at Plan/Checks)

Corroborated across multiple features. Safe to apply as guidance.

_none_

## Candidates (under observation - do NOT load as guidance yet)

Seen once or not yet corroborated. Tracked, not trusted.

### L-015 - A size cap of N needs a proof at N that is accepted as well as N+1 that is rejected
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `validation` · harmful: 0
- features: lote-identify-batch
- evidence: C5 identify_batch 31-file 422 (validation)
- last seen: 2026-11-17T03:17:04Z

### L-016 - Assert a forbidden element is absent inside each row that could carry it, never through a selector no element matches
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `system specs, Stimulus` · harmful: 0
- features: lote-identify-progress
- evidence: verification.md finding 1 - document_lote_controller.js:347 (system specs, Stimulus)
- last seen: 2026-11-18T02:04:34Z

### L-017 - Write a check's concrete value from the state the gesture produces, not from the state before it
- signal: `spec_precision_gap` · recurrence: 1 feature(s) · scope: `checks` · harmful: 0
- features: lote-identify-progress
- evidence: verification.md finding 2 - checks.md C10 (checks)
- last seen: 2026-11-18T02:04:35Z

### L-018 - A Miss-for-kind fixture must still yield a complete triple so only the kind guard can produce Miss
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `parser specs` · harmful: 0
- features: recibo-pdf-fields
- evidence: C5 app-receipt PDF (parser specs)
- last seen: 2026-11-18T15:01:31Z

### L-019 - When a criterion names empty or unusable input, prove both paths, not only the empty stub
- signal: `spec_precision_gap` · recurrence: 1 feature(s) · scope: `parser specs` · harmful: 0
- features: recibo-pdf-fields
- evidence: C6 AC 6 unusable pdftotext (parser specs)
- last seen: 2026-11-18T15:01:31Z

### L-020 - When the default is the first incomplete key in list order, prove a later key as that default, not only the first key in the list.
- signal: `spec_precision_gap` · recurrence: 1 feature(s) · scope: `setup` · harmful: 0
- features: setup-desk
- evidence: C19 (setup)
- last seen: 2026-11-19T15:08:52Z

### L-021 - When a row has both a complete stamp and an incomplete stamp, prove the incomplete stamp, not only the complete one.
- signal: `spec_precision_gap` · recurrence: 1 feature(s) · scope: `setup` · harmful: 0
- features: setup-desk
- evidence: C33 (setup)
- last seen: 2026-11-19T15:08:52Z

### L-022 - When fallback is a conjunction of two validations, prove mixed cases (valid with invalid, invalid with valid), not only both-invalid together.
- signal: `surviving_mutant` · recurrence: 1 feature(s) · harmful: 0
- features: month-overview-lists
- evidence: C22
- last seen: 2026-11-19T19:37:09Z

### L-023 - Assert selected inputs are cleared in the DOM when changing a form mode, including after cancellation.
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `system` · harmful: 0
- features: matches-workspace
- evidence: C15 clear selected documents (system)
- last seen: 2026-11-23T23:31:46Z

### L-024 - Assert every named field in expanded details using distinct members and values.
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `system` · harmful: 0
- features: matches-workspace
- evidence: C20 document payee in details (system)
- last seen: 2026-11-23T23:31:46Z

### L-025 - Use distinct payment and document data when verifying every completed summary column.
- signal: `spec_precision_gap` · recurrence: 1 feature(s) · scope: `system` · harmful: 0
- features: matches-workspace
- evidence: C19 (system)
- last seen: 2026-11-23T23:31:46Z

### L-026 - Exercise every completed list when checking account filters and closed-month read-only behavior.
- signal: `spec_precision_gap` · recurrence: 1 feature(s) · scope: `system` · harmful: 0
- features: matches-workspace
- evidence: C24 C25 (system)
- last seen: 2026-11-23T23:31:46Z

### L-027 - Populate wide tables before asserting responsive horizontal scrolling.
- signal: `spec_precision_gap` · recurrence: 1 feature(s) · scope: `system` · harmful: 0
- features: matches-workspace
- evidence: C27 (system)
- last seen: 2026-11-23T23:31:46Z

### L-028 - Assert specified user-facing error copy literally rather than via the production constant.
- signal: `spec_precision_gap` · recurrence: 1 feature(s) · scope: `system` · harmful: 0
- features: matches-workspace
- evidence: C11 (system)
- last seen: 2026-11-23T23:31:46Z

## Quarantined (failed when applied - ignore)

A confirmed lesson that recurred alongside failure. Kept for the maintainer to review.

_none_
