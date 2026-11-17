# The lote progress capture keeps two proof-square facts out of scope

The prototype behind `lote-identify-progress` (`.impeccable/mocks/identify-progress.html?v=b&c=faixa&s=1&queue=fila`)
draws two facts of the proof square and the book that the product does not have, and neither
belongs to the rule that measures the lote:

- for an XML, the proof square shows the access key as monospace lines inside the frame;
- under `Tipo`, a green note reads `Definido pelo XML.`

The product shows an empty proof frame for an XML (the frame holds a photo, a PDF or nothing) and
carries origin notes only under `Valor`, `Data` and `Favorecido` (`XML autorizado`, `Lido da foto`,
`Digitado`).

## Status

accepted

## Considered options

- **Build the two facts as part of this feature.** Rejected: they are proof-square and book
  decisions of the single-file include screen, not of the lote's measure. Changing them here would
  put a second, unreviewed design change inside a slice about the rule and the sentence, and the
  single-file screen is settled by `documents-insert-refine`.
- **Drop the two facts from the capture and retake it.** Rejected: the capture is the binding
  source the user approved; a capture is changed by the user, not by the builder, and the two facts
  do not affect the tick rule, the sentence or the row words this feature is judged on.
- **Record them as differences of the source and leave the screens as they are.** Chosen: the
  measure, the sentence, the two row words and the absent sub-line — what this feature is — are
  reproduced exactly; the two proof-square facts are named here so the screens judge does not fail
  a picture for a difference the user accepted.

## Consequences

- `plan.md` `## Differences from the source` carries one row per fact, citing this ADR.
- The screens sub-agent's inventory marks the proof frame of an XML and the note under `Tipo` as
  accepted differences, not as findings.
- A later feature that touches the single-file include screen decides both facts on their own
  terms; this ADR does not settle them.
