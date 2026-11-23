# Preserve list scroll position verification

**Verdict**: PASS
**Mutations**: 3 - C2, C3, and C6 killed after the proof fixes
**Proofs**: `proofs.md`, 14 passing rows. The independent review at `7a645ba` surfaced five proof gaps, closed by `ec5f226`.
**Verifier**: independent sub-agent (author != verifier)

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| C3 permits a closed Pagamentos or Documentos sem casamento fold to reopen after a sort. | The mutation that skips restoring Pagamentos survived. `spec/system/list_scroll_position_spec.rb:124` changes only the Recebimentos fold and checks only that fold at lines 134 and 144. | Close each default-open fold in turn, sort a different open list, and assert the closed fold stays closed. | `ec5f226` - C3 checks all three folds while sorting another list |
| C2 allows nonmatching rows to remain after applying a Sem mês filter. | `spec/system/list_scroll_position_spec.rb:100` counts only rows that contain Mercado 02. The assertion would also pass with Mercado 02 and all 27 nonmatching rows present. | Assert the complete set of visible document row IDs after applying the filter. | `ec5f226` - C2 checks all returned row IDs and verifies an actual scroll clamp |
| C4 can pass with incorrect Recebimentos rows for the selected bank account. | `spec/system/list_scroll_position_spec.rb:157-182` seeds and asserts only Pagamentos. The independent example proved both movement lists become empty for a bank account without a statement and return when Todas is selected. | Seed and assert both movement lists when selecting and clearing the bank account. Assert the shortened page actually exercises the new scroll limit. | `ec5f226` - C4 checks both movement lists and verifies an actual scroll clamp |
| C5 can pass without exercising keyboard-only activation. | At `spec/system/list_scroll_position_spec.rb:192-209`, the sort and clear links are unfocused before `send_keys(:enter)`. Cuprite 0.20.1's `node.rb:205-215` clicks an unfocused target before typing. The independent examples sent native Enter after focusing with `preventScroll`. | Focus each target before sending native Enter. Assert the equivalent control or Favorecido receives focus at the expected offset. | `ec5f226` - C5 focuses each control before sending native Enter |
| C6 can pass when Forward restores the sort indicator and URL with the wrong result order. | `spec/system/list_scroll_position_spec.rb:243-245` checks the indicator and query only. The fixture at lines 19–22 also yields the same order for date ascending and amount descending. | Use a fixture that gives the two sort states different orderings and assert the ordered row IDs after Back, Forward, and reload. | `ec5f226` - C6 checks distinct complete row orders after Back, Forward, and reload |

## Independent examples

- Selected and cleared a bank account without a statement using native Enter. Both movement lists, the active filter, the Casar pagamentos URL, and keyboard focus updated. Selecting clamped scroll from 544 px to the new 391 px maximum. Clearing preserved 391 px.
- Pressed Enter in Favorecido for a query with zero matches. The field regained focus, and scroll clamped from 461 px to the new 120 px maximum. Keyboard activation of Limpar restored all 25 rows, returned focus to Favorecido, and preserved 120 px.
