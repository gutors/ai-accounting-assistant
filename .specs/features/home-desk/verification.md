# Home desk verification

**Verdict**: FAIL
**Mutations**: 3 - probed C16, C22, C13
**Proofs**: `proofs.md` at 7b5a2b5
**Verifier**: independent sub-agent (author != verifier)

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| C16 still passes if every payment is counted as missing a document, and its `Falta o extrato` assertion is vacuous | mutation `missing-document filter stripped` not killed; `organizations_spec.rb:567-578` plants three unmatched payments on `plant_month`'s only account, which already has a statement, so `.count` equals `.missing_document.count` and `Falta o extrato` cannot appear | plant one excepted or matched payment plus a second active account without a statement; keep the sentence exactly `3 pagamentos com documento faltante.` and assert that sentence (not the Extrato cell) omits `Falta o extrato` | `cb6353f` |
| C13 still passes if every open month is marked `em trabalho` | mutation `em trabalho on every open month` not killed; `organizations_spec.rb:529-548` opens only `2026-10` beside closed `2026-09`, so `live = !month.closed?` matches in-work-only | with two open months, assert only the newest open row includes `em trabalho` | `cb6353f` |
| C8 proves `POST /focus`, not that the unfocused chip posts that `organization_id` or that the next desk is that organization's | `focus_spec.rb:10` posts `/focus` with `org_b.id` and then checks the toast and Sul `aria-current`; no example reads the ONG Sul form's `organization_id` or Sul's in-work pane (AC 7) | GET `/`, assert the unfocused chip form posts `/focus` with that `organization_id`, submit it, and expect that organization's desk | `cb6353f` |

Probed and holding (no finding): own examples at `HEAD`, throwaway and deleted — (a) two missing payments plus one `bank_fee` exception still render `2 pagamentos com documento faltante.`; (b) an inactive `Conta Inativa` is omitted from Contas bancárias while `Conta Principal` remains. Mutation `in-work is newest closed month` was killed by C22. Binding `coordinator-home` labels match the checks; Excluir, omitted one-org chips, and collapsed Pessoas are the confirmed differences.
