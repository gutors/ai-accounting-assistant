# Month statement row screens

**Verifier**: independent sub-agent (author != verifier)
**Round**: 1
**HEAD**: de99997

| Screen | Compared with | Verdict | Finding |
| --- | --- | --- | --- |
| `captures/statement-row.running.png` | `captures/statement-row.png` | diverges | 2 rows differ: the nav omits `Administração`, and the Pagamentos head draws sort glyphs the capture does not |
| `captures/statement-row-390.running.png` | `captures/statement-row-390.png` | diverges | 3 rows differ: the nav, the content box's right gutter, and the payment first line's type step |

No `differs` row is a regression of anything AD-0015 or the plan decided. Its four departures - one
control per row, the `✓` gated on a spreadsheet, no quiet link, no visible `Incluir` / `Substituir`
words - all read `same` below, and so do the five bank-row states, the action icons, both sheets'
column tracks, the payment row pitch and the truncation. `Administração` and the sort glyphs are
incumbent page chrome the sketch draws unconditionally or omits altogether; neither comes from this
feature and neither is covered by AD-0015, so both are reported rather than accepted.

**Two known open questions, recorded and not counted.** The running month is confirmed and every
payment in it lacks a document, so all four Pagamentos rows read `Documento faltante` and all four
carry the red margin, where the capture mixes `Casado` and `Tarifa bancária`. That costs the judge two
readings at 1280px: the Documento column is empty on every row, so its truncation (`Atacado de
Confecçõe…`) is never drawn, and the margin's "a missing row only" rule cannot be seen. It costs
nothing else the criterion asks for - the 43px pitch, the two-line maximum, the `14px`/`13px` step,
the four status variants' cells and the 176px Documento track are all drawn and measured. **The
picture carries AC 12 adequately.** AC 15's "no horizontal scroll" is not carried, for the gutter
reason below.

### `captures/statement-row.running.png`

| Element | Result | Picture draws |
| --- | --- | --- |
| render: 1280 wide, not resized - `06/05/2026` 87×15 in both, `Documento faltante` 78×10 in both, `MARCIO` 58×10 in both | same | note: picture is 1297px tall against the capture's 993; the length difference is the breadcrumb, the two page actions, the chips and the two folds |
| header: mark plus `Fechamento Mensal · Centro Social da Rua` | same | note: picture names the seeded organization `Caminhada`, joined by `-` |
| nav, right: `Início`, `Documentos`, `Configuração`, `Administração`, `Sair` | differs | four links; no `Administração` |
| `Sair` underlined, last in the nav | same | |
| hairline under the header | same | |
| quiet `Voltar para Início` above the title | same | note: capture draws none; incumbent month chrome |
| page title `<h1>` `maio de 2026`, slug `2026-05` in soft ink under it | same | |
| summary sentence `Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.` | same | note: the picture's month is confirmed, so it draws the other summary state, `4 pagamentos com documento faltante.` in margem plus `Falta o extrato de 4 contas ativas.` - the same fixture fact as the payment statuses |
| `Casar pagamentos` secondary and `Fechar para envio` primary at the title's right | same | note: capture draws none; incumbent month chrome |
| section heading `Contas bancárias` with a rule under it | same | |
| bank sheet head: `Banco`, `Nome`, `Agência/conta`, `Situação`, `Documentos`, empty action head, vertical rules between cells, ink rule under the head | same | |
| bank sheet column tracks | same | 169 / 199 / 160 / 104 / 279 / 176 px in both |
| bank sheet block geometry: 1088px wide, ~10px cell padding | same | note: the capture left-aligns the block at x=32 and leaves 160px of page to its right; the picture centres it at x=104 with 89px right |
| row state 1, nothing chosen: bank, name, coordinates, `Falta` in margem, `A planilha é obrigatória` in soft ink, no file line, one `+` | same | note: picture draws it on `conta salário` `2806/55110-8`, fourth row |
| row state 2, PDF alone: `Pdf extrato-maio-2026.pdf` above `A planilha é obrigatória`, `+` and `×`, no `✓` | same | note: picture draws it on `poupança`, fifth row; the staged line is soft ink where the capture draws it in body ink (shade) |
| row state 3, PDF and spreadsheet: `Pdf` above `Planilha`, `✓` and `×` | same | note: picture draws it on `conta corrente`, second row; both staged lines soft ink (shade) |
| row state 4, refused: `Só PDF, .csv ou .xlsx` in margem above `A planilha é obrigatória`, one `+`, nothing staged | same | note: picture draws it on `aplicação` `2806/40022-1`, first row; both pictures print the refusal as a plain margem sentence in the cell, with no second bar |
| row state 5, Presente: `Presente` in body ink, `Pdf` above `Planilha`, pencil | same | note: picture draws it on `conta corrente BB` `2806/33117-0`, third row; the capture repeats `2806/24942-4` twice and the picture does not (fixture data) |
| action cell: 16px stroke glyphs, `caixa` for `+`, `✓` and pencil, `margem` for `×`, side by side with a small gap, vertically centred | same | |
| one control per row; no band, no chip, no second form surface, no visible `Incluir extrato` / `Substituir extrato` | same | AD-0015 |
| legend paragraph `Estados: 1 sem nada escolhido, …` under the sheet | same | note: the sketch's own state annotation, not page copy; picture draws none |
| bank row heights | same | note: the one-line state is 41px in both; a two-line state is 52px in the capture and 49px in the picture, a hair tighter |
| `Pagamentos` heading with a rule under it | same | note: picture draws it as an open disclosure summary `▾ Pagamentos`; incumbent month chrome |
| payment sheet head: `Data`, `Histórico`, `Valor`, `Status`, `Documento`, vertical rules between cells, ink rule under the head | same | |
| payment head labels carry sort glyphs | differs | `Data ↑` and `Valor ↕`; the capture draws both labels bare |
| payment column tracks | same | 151 / 472 / 128 / 160 / 176 px in both |
| payment rows: four rows, two lines each, history over the account meta, both `…` with the full text in `title`, never wrapped | same | note: capture pitch 41/43/43/43px, picture a flat 43px; every picture row is `Documento faltante` (open question), so no row is long enough to truncate at this width |
| type step: history, status and document at `14px`/`18px`, account meta at `13px`/`18px` | same | |
| amount right-aligned in its track, tabular digits, same step as the history | same | |
| status word left-aligned in the Status track | same | note: picture draws `Documento faltante` in margem; the capture draws the same words in body ink (shade) |
| Documento cell: matched payee names, truncated with `…` | same | note: the picture's four cells are empty because every payment lacks a document; the column and its 176px track are drawn |
| no third line, no match observation in the row | same | |
| red left margin, 3px, 12px inset on the first cell | same | note: picture draws it on all four rows where the capture draws it on one (open question) |
| `Documentos sem casamento` and `Recebimentos` folds under Pagamentos | same | note: capture ends at the last payment row and draws neither; incumbent month chrome |

`differs` rows, with the reading:

- **nav**: `Administração` is absent. The sketch lists it for every account; the app shows it only to
  the administrator (`docs/adr/0007`, `.design/administration-intake.md`). This feature does not touch
  the nav, so the link must not be added to make the picture match the sketch - confirm which account
  the picture was taken with instead.
- **sort glyphs**: the picture draws the incumbent sortable ledger head; the sketch draws plain labels.
  The head's tracks and rules are identical, so nothing in the sheet moves. Reported because the sketch
  omits them and AD-0015 does not cover them, not because this feature added them.

### `captures/statement-row-390.running.png`

| Element | Result | Picture draws |
| --- | --- | --- |
| render: 390 wide, not resized - `maio de 2026` 118px wide in both, `obrigatória` 62px in both, the status words and the history line match | same | note: picture is 2153px tall against the capture's 1833; the nav, the chips and two folds account for the extra |
| header: mark and brand | same | note: picture names `Caminhada`, capture `Centro Social da Rua` |
| nav links | differs | capture wraps them under the brand - `Início`/`Documentos`, then `Configuração`, then `Administração`/`Sair` at x=185 on three lines; picture draws `Início`, `Documentos`, `Configuração`, `Sair` on one row at y=49 and omits `Administração` |
| page title `<h1>` and slug `2026-05` | same | |
| summary sentence | same | note: picture draws the confirmed-state missing-document summary, as at 1280 |
| `Casar pagamentos`, `Fechar para envio`, `Voltar para Início` | same | note: capture draws none; incumbent month chrome |
| `Contas bancárias` heading with a rule under it | same | |
| content box: section rules, row rules and fold rules run the gutter to gutter | differs | rules run x=20..384, a 20px left gutter and a 6px right one; the capture draws x=20..369, 20px on both sides |
| bank rows stacked: bank, name, coordinates, then `Falta` or `Presente`, then the document lines, then the icons; one row per account with a rule between | same | |
| bank row inner gutters: text at x=20-21, icons on a row under the documents | same | note: rows run 195-200px in the capture and 179-213px in the picture; the 179px one is the empty state, which stacks the fewest lines |
| the five bank-row states, one per account | same | same five states in both, on different accounts and in a different order (fixture data) |
| action icons per state: one `+`; `+` and `×`; `✓` and `×`; one `+`; pencil | same | |
| legend paragraph `Estados: …` | same | note: the sketch's annotation; picture draws none |
| account chips `Todas` … `poupança` above Pagamentos | same | note: capture draws none; incumbent month chrome |
| `Pagamentos` disclosure heading with a rule under it | same | |
| payment row first line: date left, amount right | same | |
| payment row second line: truncated history left, status right | same | |
| Documento cell and the account meta line hidden | same | |
| history truncated with `…` (`MAR…`, `Confecc…`, `Cobra…`, `ROSE…`) | same | |
| type step of the payment row | differs | the first line is a step smaller: `06/05/2026` 76×12 where the capture draws 87×15, and `R$ 1.200,00` 77×13 against 88×15 |
| status word in margem, right-aligned | same | note: `Documento faltante` 125×10 against the capture's 125×11, so the second line matches |
| red left margin on each payment row | same | note: picture draws it on all four rows (open question) |
| `Documentos sem casamento` and `Recebimentos` folds | same | note: capture ends at the last payment row |

`differs` rows, with the reading:

- **nav**: the same missing `Administração` as at 1280, and the wrap follows from it - four links fit on
  one row where the capture's five need three.
- **content box**: the picture's content spans x=20..384, so its right gutter is 6px where the capture
  draws 20px on both sides (its content spans x=20..369). The header rule is full-bleed in both, so the
  window really is 390px, and the `h1` and every cell but the payment first line match at the capture's
  size - so this is not a resized picture. Either the page's right padding is ~6px or the ~370px content
  box overflows a 20px-gutter layout; nothing is visibly clipped, but the second reading is a horizontal
  overflow, and this is the measurement AC 15's "390px wide with no horizontal scroll" would be checked
  against. The picture cannot carry that clause as drawn.
- **type step**: only the first line is smaller; the history, the status, the `h1` and the file lines
  match to the pixel, so this is the page's own step at this width and not a resized picture.
