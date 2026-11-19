# Month overview lists verification

**Verdict**: PASS
**Mutations**: 3 - probed C7, C22, C8
**Proofs**: `proofs.md` at f2a6f02
**Verifier**: independent sub-agent (author != verifier)

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| C22 fallback is not held: valid `*_sort` with invalid `*_dir` (or the reverse) can skip date-ascending and the named proof stays green | mutation `invalid sort/dir fallback AND to OR` not killed by `month_overview_lists_spec.rb` "invalid sort and dir params fall back to date ascending" (both params invalid together). Check C22 names three families; the proof only sends `payments_sort=history` and `payments_dir=sideways`. Unnamed GET `payments_sort=amount` `payments_dir=sideways` is date-ascending on current `&&` code | assert at least one valid column with an invalid dir, and one invalid column with a valid dir, on a list C22 names | b4e2af9 |
