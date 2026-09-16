# LESSONS - auto-maintained by scripts/lessons.py

> Machine-owned. Do NOT hand-edit. Changes are overwritten on the next `lessons.py` write.
> Canonical state lives in `.specs/lessons.json`. Edit lessons only via the script.
> promote_threshold=2 distinct features · window_days=45 · quarantine_threshold=2

## Confirmed (load these at Plan/Checks)

Corroborated across multiple features. Safe to apply as guidance.

_none_

## Candidates (under observation - do NOT load as guidance yet)

Seen once or not yet corroborated. Tracked, not trusted.

### L-001 - Assert enumerated picker members by the check-defined names in the claimed order, not by mirroring the model's ordered collection.
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `request-specs` · harmful: 0
- features: organization-close-setup
- evidence: C28 spec/requests/setup_spec.rb:86-90 (request-specs)
- last seen: 2026-09-16T22:04:46Z

### L-002 - A catalog-order proof must fail when the collection is sorted by a different key than the check names.
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `request-specs` · harmful: 0
- features: organization-close-setup
- evidence: verification.md Faults injected Bank.ordered_catalog order(:compe) -> order(:presentation_name) (request-specs)
- last seen: 2026-09-16T22:04:46Z

## Quarantined (failed when applied - ignore)

A confirmed lesson that recurred alongside failure. Kept for the maintainer to review.

_none_
