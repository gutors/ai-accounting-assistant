# The lote names the wave it is reading, and marks only that wave

While a wave of at most four files is in flight, the section shows the wave as a 1-based
range with the lote total (`Identificando os documentos 5 a 8 de 10`), and the section
heading's rule becomes one tick per document. Rows inside the wave say `Identificando`;
rows the browser has not sent yet say `Na fila`. No row repeats the reading sentence under
its file name. A single file shows neither the ticks nor the sentence, and its proof square
keeps `Identificando o arquivo…`.

This supersedes the paint that `lote-identify-waves` shipped: C3 asserted that all five rows
of a five-file lote show `Identificando o arquivo…` while the first wave is in flight, and C4
asserted that the fifth row still showed it after the first wave returned.

## Status

accepted

## Considered options

- **A counter under the heading (`4 de 10 documentos identificados`).** Rejected: "4 de 10" reads equally as
  four already identified and four being read now, and the two point in opposite directions. The
  count of finished documents also sits at `0` through the whole first wave while the system is
  visibly working.
- **A second rule under the heading rule.** Rejected: two horizontal rules a few pixels apart read as
  a table border, not a measure. The heading's own rule becomes the measure instead.
- **A lighter tint of `caixa` for the ticks in flight.** Rejected after measuring: a 75% tint reads as
  finished at capture scale, so the wave looked done before it was. Fill versus hollow versus pale
  carries three states without a tint that lies.
- **`item.wave` or a `queued` status on each item (chosen against).** Rejected: the wave is already the
  slice `pumpIdentify` hands to `identifyBatch`. A per-item flag has to be cleared in `failIdentify`,
  `includeReady` and `removeSelected`, and a stale flag would paint a hollow tick over a finished row.
  `this.wave` is one array set in one place and cleared in one place.
- **`Aguardando a próxima leva` under the file name of queued rows.** Rejected: the Situação column
  already says `Na fila`, and the sheet is a ledger where a second sentence per row breaks the
  one-line rhythm.

## Consequences

- The Situação column carries three readings where it carried one: `Identificando` (in the wave),
  `Na fila` (not sent), and the existing `Pronto` / `Digitar` / `Erro`.
- A document that finishes in `Erro` fills its tick in `margem`, so the rule keeps the One Red Rule
  of `DESIGN.md`: red marks what blocks the close and what failed.
- The rule is `aria-hidden`; the sentence lives in a `role="status"` region so a screen reader hears
  each new wave once. With no wave in flight, neither is rendered.
- At the 30-file limit the ticks stay 21.9px on a laptop and 9.7px at 390px, so a full lote still
  reads as separate ticks rather than a single line.
- `spec/support/lote_system_helpers.rb` and the assertions in `document_lote_spec.rb` and
  `document_lote_identify_batch_spec.rb` that expect `Identificando o arquivo…` on lote rows change
  with the copy they prove.
