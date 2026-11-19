# Home desk select verification

**Verdict**: PASS
**Mutations**: 3 - probed C21, C13, C30
**Proofs**: `proofs.md` at b459ac1
**Verifier**: independent sub-agent (author != verifier)

## Findings

None - dropped the in-work selected-month fallback, gated Excluir on `closed?` instead of `never_sent?`, and reversed standing-coordinator insertion order; all three were killed. Unnamed examples (another organization's `year_month`; `desk=people` with `year_month`) held at HEAD.
