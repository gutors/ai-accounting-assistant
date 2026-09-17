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

### L-003 - Skip-row proofs must fail when the skip list is emptied: assert a persisted statement (or in-month skip rows), not only that skip histories are absent.
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `import-specs` · harmful: 0
- features: bank-statement-upload
- evidence: verification.md F5 SKIP [] banco_do_brasil_spreadsheet.rb:6 / C21 bank_statement_spec.rb:60-62 (import-specs)
- last seen: 2026-09-17T00:19:39Z

### L-004 - A skip-row check that does not require persist is satisfied by any reject path that leaves movements empty.
- signal: `spec_precision_gap` · recurrence: 1 feature(s) · scope: `import-specs` · harmful: 0
- features: bank-statement-upload
- evidence: C21 spec/models/bank_statement_spec.rb:60-62 (import-specs)
- last seen: 2026-09-17T00:19:39Z

### L-005 - When a collection label also appears in the same page's form, assert it inside the collection HTML, not the whole body
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `request-specs` · harmful: 0
- features: supporting-document-insert
- evidence: verification.md Faults: list kind interpolation; C8 (request-specs)
- last seen: 2026-09-17T01:55:56Z

### L-006 - A page-include of a string the form always renders does not prove the list showed that string
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `request-specs` · harmful: 0
- features: supporting-document-insert
- evidence: C8 C15 verification.md (request-specs)
- last seen: 2026-09-17T01:55:56Z

### L-007 - When each collection row embeds a form whose options repeat the row labels, assert the display node, not a heading-sliced HTML fragment.
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `request-specs` · harmful: 0
- features: supporting-document-insert
- evidence: verification.md Faults: list kind interpolation; C8 index.html.erb:65 (request-specs)
- last seen: 2026-09-17T02:00:12Z

### L-008 - A substring in a heading-sliced fragment is not list copy when nested row forms still render that substring.
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `request-specs` · harmful: 0
- features: supporting-document-insert
- evidence: C8 C15 spec/requests/supporting_documents_spec.rb:92,150 (request-specs)
- last seen: 2026-09-17T02:00:12Z

### L-009 - A collection slice that still contains an edit form with the same option labels is not a unique assertion surface
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `request-specs` · harmful: 0
- features: supporting-document-insert
- evidence: verification.md round 2 Faults: PATCH options_for_select; C8 (request-specs)
- last seen: 2026-09-17T02:00:43Z

## Quarantined (failed when applied - ignore)

A confirmed lesson that recurred alongside failure. Kept for the maintainer to review.

_none_
