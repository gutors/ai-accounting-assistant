# Lote identify progress verification

**Verdict**: FAIL
**Mutations**: 3 - probed C2, C3, C7
**Proofs**: `proofs.md` at bc4af95
**Verifier**: independent sub-agent (author != verifier)

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| The `Identificando o arquivo…` sentence under the file name can come back on every reading row and no test fails (AC 5: "no row SHALL show a second sentence under its file name") | mutation `${error}` -> `${error}` + identifying sub-line at `document_lote_controller.js:347` not killed by C7; `document_lote_progress_spec.rb:114` selects `[data-lote-row]`, an attribute no row carries, so it is vacuous, and `:115`/`:123` look only inside `[data-lote-status]` | in C7, assert each wave and queued row (`[data-lote-id]` for `a.xml`…`e.xml`) has no content `Identificando o arquivo…`, and drop the `[data-lote-row]` selector | |
| C10's stated value contradicts its proof: the check says the sentence names `1 a 4 de 4`, the test asserts `1 a 3 de 4` | `checks.md` C10 vs `document_lote_progress_spec.rb:173`; removing `a.xml` leaves `b`,`c`,`d` in the wave at positions 1–3, so AC 8 ("same documents by their new 1-based bounds") gives `1 a 3 de 4` - the test is right, the check text is not | correct C10 to `Identificando os documentos 1 a 3 de 4` (ticks 1–3 hollow, tick 4 pale) | |

Probed and holding (no finding): own examples at `HEAD`, throwaway and deleted - (a) `Retirar` of `a`,`b`,`c` from a five-file lote mid-wave shrinks the wave to one: `Identificando o documento 1 de 2`, ticks hollow/pale, then `o documento 2 de 2` on the next wave; (b) 28 files then 4 more mid-wave hits the 30-file ceiling: 30 rows, 30 ticks, `1 a 4 de 30`, ticks 5–30 pale; (c) nine files, third wave singular `o documento 9 de 9` with ticks 1–8 filled. Mutations on the queued-tick state (C2) and the singular rule (C3) were killed. The rule-to-paint decision table is proven only in system specs; acceptable here since the rule lives in a Stimulus controller with no JS unit runner in the repo. Capture `lote-b-faixa-fila.png`: no check or criterion contradicts what it draws beyond the two AD-0011 departures; pixel judgement of C1/C6 is the screens sub-agent's.
