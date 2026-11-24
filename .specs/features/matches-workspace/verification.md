# Matches workspace verification

**Verdict**: FAIL
**Mutations**: 3 - probed C2, C15, C20; 1 killed, 2 not killed
**Proofs**: `proofs.md` at 389e2b3
**Verifier**: independent sub-agent (author != verifier)

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| C15 does not establish that choosing an exception clears document selections | Mutation `C15 clear selected documents` sets every document checkbox checked instead of clearing it and the named proof still passes. | Assert the document checkboxes are unchecked after selection, including after cancellation. |d9cbf6d |
| C20 does not establish document payees in expanded details | Mutation `C20 document payee in details` removes the payee and its named proof still passes. The proof also does not assert the amounts or multiple members. | Assert each payment and document's required fields with distinct values and multiple members. |d9cbf6d |
| C19 does not establish the complete summary row | `spec/system/matches_workspace_spec.rb` criterion 19 asserts one matching text and one amount, with identical payment history and document payee and equal totals; it does not establish date, document summary, or both totals. | Assert each summary field using distinct payment and document values. |d9cbf6d |
| C24 and C25 omit important completed-list cases | Criterion 24 exercises a cross-account match but no exceptions; criterion 25 creates an exception but no confirmed match, so neither filtered exceptions nor closed-month match visibility and undo prohibition are proved. | Add filtered exceptions in both accounts and a confirmed match in the closed-month case. |d9cbf6d |
| C27 does not prove populated wide ledgers can be scrolled without clipping | Criterion 27 creates no confirmed match or marked exception, so neither ledger table is present; the page-width assertion alone cannot test either table's scroll behavior. | Populate both ledgers at both widths and assert their content can be reached by horizontal scrolling. |d9cbf6d |
| C11 does not hold the specified error text | Criterion 11 compares the displayed text with `Match::LESSER` rather than the literal required by the check, so changing the constant and UI together would pass. | Assert the specified `Informe a observação do casamento` text independently. |d9cbf6d |

Two independent request examples passed: ordering across three distinct dates and filtering marked exceptions across two accounts.

All six findings were addressed by `d9cbf6d`; the later mechanical proof run killed all three mutations. The FAIL verdict records the original review at `389e2b3`.
