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

## Round 2

**Verifier**: independent sub-agent (author != verifier)
**Round**: 2
**HEAD**: 332d9a7 - pictures re-saved at 730ae6e, product code last changed at 0875ede

| Screen | Compared with | Verdict | Finding |
| --- | --- | --- | --- |
| `captures/statement-row.running.png` | `captures/statement-row.png` | matches | both reopened rows are now `same`: the nav carries `Administração`, and the sort glyphs are incumbent chrome whose tracks and rules match |
| `captures/statement-row-390.running.png` | `captures/statement-row-390.png` | diverges | 1 reopened row still `differs`: the nav's arrangement. The gutter and the payment first line's type step are now `same` |

Only the five rows that differed in round 1 were reopened. Rows that passed were re-read only where
these fixes reach them, and none broke: no `differs - regression` in either picture.

### `captures/statement-row.running.png` - reopened rows

| Element | Round 1 | Now | Picture draws |
| --- | --- | --- | --- |
| nav, right: `Início`, `Documentos`, `Configuração`, `Administração`, `Sair` | differs | same | five links at y=18..42, 39 / 89 / 93 / 102 / 28px wide against the capture's 39 / 89 / 93 / 103 / 28 (1px of antialiasing on the longest label), `Sair` last and underlined, hairline under the header at y=56 against the capture's y=55 |
| payment head labels carry sort glyphs | differs | same | note: `Data ↑` and `Valor ↕` are still drawn and the capture's labels are still bare, but the head's five tracks measure 151 / 472 / 128 / 160 / 176px and its rules sit at the same offsets in both, so nothing in the sheet moves. Incumbent sortable-ledger chrome the sketch omits; the plan does not change it and AD-0015 does not cover it - reported, not blocking |

The rows these two fixes sit next to, re-read and unchanged: the payment rows still run a flat 43px
each (799 / 842 / 885 / 928 in the capture, 856 / 899 / 942 / 985 in the picture), the amounts
89 / 74 / 65 / 74px wide by 15px, the history lines 370 / 302 / 383 / 375px and the status words
126 / 46 / 95px on the first three rows - every one of those widths identical to the capture - and
the `render` row still reads `06/05/2026` 87×15 in both. The fourth row's status is 126px in the
picture and 46px in the capture because the picture's fourth payment is `Documento faltante` where
the capture's is `Casado` - the mixed fixture, not a type or track difference.

### `captures/statement-row-390.running.png` - reopened rows

| Element | Round 1 | Now | Picture draws |
| --- | --- | --- | --- |
| nav links | differs | differs | five links now: `Início` `Documentos` `Configuração` (39 / 89 / 93px) on one row at y=57..72 running x=21..284, then `Administração` `Sair` (103 / 27px) at y=85..100 running x=20..170. The capture keeps them in a right-hand column from x=185-186 to x=331 over three rows - `Início` `Documentos`, `Configuração` alone, then `Administração` `Sair` - beside a three-line brand block. Same five labels, same order, same underlined `Sair`; different wrap, and the picture's links start at the left gutter the brand uses |
| content box: section rules, row rules and fold rules run the gutter to gutter | differs | same | every long rule runs x=20..369 at y=460, 673, 870, 1067, 1246, 1443, 1690, 1756, 1806, 1856, 1906, 1987 and 2108: a 20px gutter on both sides, as the capture draws. Round 1's 6px right gutter was the scrollbar |
| type step of the payment row | differs | same | `06/05/2026` 87px wide in both (14px tall against the capture's 15) and `R$ 1.200,00` 74×15 at x=295..368 in both - the capture's step, no smaller first line |

`differs` row, with the reading:

- **nav**: the link set, its order and the underlined last `Sair` now read `same`; what still differs is
  where the links sit and how they wrap. That follows from the brand block, not from the missing link:
  the picture draws the organization as a badge on the brand's one line (`Fechamento Mensal` +
  `Caminhada`, ending x=326), so the nav drops to the row below and spreads left to right, while the
  sketch draws the name inline over three wrapped lines and keeps the nav in a right-hand column. The
  header hairline sits at y=120 in the capture and y=116 in the picture, both full-bleed, and the five
  labels measure the same, so this is inherited header chrome this feature does not touch - not a
  regression of anything AD-0015 decided, and the nav must not be restyled to make the picture match.

Payment rows re-read under the new mixed-status fixture and unchanged: the red margin is 3px at
x=20..22 on rows 1 and 4 only (1707..1756 and 1857..1906), the two rows reading `Casado` and
`Tarifa bancária` carry none, the second line is truncated with `…` in all four rows, the status words
measure 129px wide and 10px tall against the capture's 129×11, and the Documento cell stays hidden at
this width.

### The two open questions from round 1

**Closed at 1280.** The mixed fixture draws both readings the round-1 picture could not: the Documento
column now carries `Atacado de Confecçõe…` in a 153px cell, the same 153px the capture truncates in,
so AC 13's `…` is drawn and measured; and the red margin runs on the two `Documento faltante` rows
only, so the "a missing row only" rule is visible. One residue, not a gap: the capture has two matched
rows carrying payees (`Atacado…`, `Roselena Borges da Si…` 151px) and the picture has one, because its
fourth payment is `Documento faltante` rather than `Casado` - the same fixture fact as the status
column, and one instance already proves the rule at the capture's width.

Nothing was open at 390 on truncation: the history truncates in all four rows of both pictures.

### AC 15's no-horizontal-scroll clause

**Carried.** The content box is x=20..369 inside a 390px window, 20px on both sides as the capture
draws, and the only ink outside it is the full-bleed header hairline at y=116 (x=0..389), which the
capture also draws full-bleed. The widest payment-row ink ends at x=368, the rules at 369, and no cell
is clipped or scrolled off the window.

### Verdict

`captures/statement-row.running.png` **matches**. `captures/statement-row-390.running.png` **diverges**
on the nav's arrangement alone - inherited header chrome, outside this feature and outside AD-0015.
Every row this feature owns now reads `same` in both pictures, and the gutter row that carried AC 15
reads `same`.
