# Quick selection verification

**Verdict**: PASS
**Mutations**: 3 - probed C1, C2
**Proofs**: `proofs.md` at 1653d81
**Verifier**: independent sub-agent (author != verifier)

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| Removing the only available payment leaves no way to select it again. | Independent system example removed the sole payment and failed to find “Adicionar pagamento”; `_workspace.html.erb` renders the toggle only when `selectable_payments.size > 1`, while the list is hidden on connect. | Make the available payment list accessible after removal even when it contains one payment, and prove reselection. | `1653d81` |
| C1 does not prove that selected payments appear above the list. | Mutation `render selected payments` replaces the selected payment rows with an empty array; C1 still passes. | Assert the added and removed payment rows in the selected area, including retention on close. | `1653d81` |
| C4 does not establish that the changed selection is submitted. | The named example confirms the unchanged initial proposal and only checks inclusion of its original members. | Change both selections before confirmation and assert the exact persisted payment and document IDs. | `1653d81` |
| C5 does not prove both lists' width or keyboard-accessible removal and desktop operation. | The named example checks only document widths at 390px and keyboard toggles one document checkbox; it does not exercise payment width, removal by keyboard, or desktop width. | Exercise both lists and keyboard removal at phone and desktop widths. | `1653d81` |
