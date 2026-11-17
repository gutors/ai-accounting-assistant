# Lote identify batch verification

**Verdict**: FAIL
**Mutations**: 3 - probed C5, C11, C8
**Proofs**: `proofs.md` at 6ddfe6f
**Verifier**: independent sub-agent (author != verifier)

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| C5 allows the 30-file cap to reject a full lote and no test fails | mutation `overflow bound > 30 -> >= 30` not killed; C5 only POSTs 31 files | POST 30 files and assert `200` with `items` length `30` (AC 5 is more than 30, Landing is 1..30) | |
