Mode: Operate. Audience: Coordinator on a laptop during the monthly close. Prototype only.

## Direction contract

THESIS: The batch tells the coordinator where it is, once, without a second widget. It refuses a spinner, a progress ring, and a toast for work that lasts seconds.

OWN-WORLD: Ledger paper page, sheet only in fields and the proof frame, 1px rule, 4px controls, IBM Plex Sans, Plex Mono only on the chave, caixa for read and commit, margem only on error.

STORY: Coordinator drops 10 files. The section says how far the reading has got. The rows keep their own status. When the last wave lands, the sentence disappears and Incluir prontos carries the count.

FIRST VIEWPORT: Header. Documentos de suporte. Incluir documentos with the sentence under the heading (form A). Proof square and book. Toolbar. The ruled lote sheet with four Pronto and the rest identifying.

FORM: Sentence, local extension. Seed n/a.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

## Constraints

- The counter must name its axis. "4 de 10" alone is ambiguous: four already read, or four being read now. The prototype's second axis exists to settle that, not to decorate.
- Four placements (A under the title, B the rule measures, C on the title line, D in the Situação head) and four meanings (already identified, reading now, wave range, remaining).
- Rows keep "Identificando o arquivo…". An optional split puts "Na fila" on rows waiting for the next wave.
- The sentence is present only while a wave is in flight. After the last wave it is gone; the count lives on the Incluir prontos button.
- D cannot hold a full sentence: the Situação column is 7rem, 92px of usable text. It gets short forms only.
- B's in-flight tick is 75% caixa, the lightest tint that still clears 3:1 on paper.
- Static HTML. Waves of 4 simulated over 10 documents. Nothing persists.
