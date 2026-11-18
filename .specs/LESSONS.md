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

## Quarantined (failed when applied - ignore)

A confirmed lesson that recurred alongside failure. Kept for the maintainer to review.

_none_
