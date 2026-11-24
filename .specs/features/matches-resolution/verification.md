# Matching workspace resolution verification

**Verdict**: FAIL
**Mutations**: 3 - probed C5, C7, C6; 2 killed, 1 survived
**Proofs**: `proofs.md` at 6c295a4
**Verifier**: independent sub-agent (author != verifier)

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| C6 does not prove client-side whitespace validation | Removing `.trim()` in `month_match_controller.js` survives `opens the required observation on shortfall`: server-side rejection can produce the same alert and open field. | Assert the whitespace submission is stopped in the browser, and that the client opens the observation and focuses the alert. | `7e89208` (C6) |
| C2 does not prove account filtering for confirmed matches and exceptions | `selects and clears the matching account` creates only pending payments and checks their count and text; it does not populate or assert either history for selected and all accounts. | Populate both histories for two accounts and assert their contents after selecting and clearing the filter. | `7e89208` (C2) |
| C4 does not prove unselected candidates collapse | `adds payments and documents in their own list` asserts selected candidates remain visible after completion, but does not assert an unselected payment or document is hidden. | Include unselected candidates in both lists and assert they are hidden after each completion. | `7e89208` (C4) |
| C5 assertions omit required comparison labels and rendered colors | `shows signed and colored differences` checks amounts and `data-tone`, but not the less/more/pending labels or computed color treatments. | Assert the specified label and rendered tone for each comparison state, including both empty-side cases. | `7e89208` (C5) |

## Independent examples

- Summing 123456789012345678 and 17 cents formatted as `R$ 1.234.567.890.123.456,95`.
- A one-cent shortfall with a tab, space, and newline observation was prevented, disclosed, and alerted by the unmutated controller.

## Resolution

All findings were closed in `7e89208`. Re-running the verifier's three mutations at that commit killed all three. Both screen judgments and all 19 proof rows passed.
