# Month statement row screens

**Verifier**: independent sub-agent (author != verifier)
**Round**: 2
**HEAD**: 6e58b99 - product code last changed at 0875ede; 332d9a7, 730ae6e, d15d8b8 and 6e58b99 touch `.specs/` and `docs/` only

| Screen | Compared with | Verdict | Finding |
| --- | --- | --- | --- |
| `captures/statement-row.running.png` | `captures/statement-row.png` | matches | every row `same`; the payment head's sort glyphs are incumbent sortable-ledger chrome the sketch omits, with identical tracks and rules |
| `captures/statement-row-390.running.png` | `captures/statement-row-390.png` | matches | every row `same`; the nav's arrangement is an accepted difference under AD-0016 |

Both pictures are now 1280x993 and 390x1833 - the captures' own sizes, at scale 1 - so no `render` row
is `differs - resized`. Round 2 reopened the five rows that differed in round 1 and re-read the rest of
the inventory on the new files, because retaking the pictures changed the frame: the earlier pictures
were full-page (1297px and 2153px tall), these are viewport captures and end where the 993px and 1833px
windows end. No row that passed in round 1 broke: there is no `differs - regression` in either picture,
and no row reads `differs` at all.

### `captures/statement-row.running.png`

| Element | Result | Picture draws |
| --- | --- | --- |
| render: 1280x993, the capture's own size, not resized - `maio de 2026` 216x28 in both, `2026-05` 50x9 in both, `06/05/2026` 87x16 in both, `Documento faltante` 126x11 in both, the histories 370 / 302 / 384 / 375px wide in both | same | note: the earlier full-page picture was 1297px tall; the frame now ends at 993 like the capture's |
| header: mark 20x20 plus the brand | same | note: the picture draws `Fechamento Mensal` 146px wide (x=125..270) then the org-switcher badge `Caminhada` (108x32, x=295..402), because the seeded coordinator has two focusable organizations; the capture names `Centro Social da Rua` inline on one line (x=61..370). Fixture name and shared-header chrome, not this feature |
| nav, right: `Início`, `Documentos`, `Configuração`, `Administração`, `Sair` | same | five links at y=21..37, 39 / 89 / 93 / 102 / 28px wide against the capture's 39 / 89 / 93 / 103 / 28 - round 1's missing `Administração` is closed |
| `Sair` last in the nav, underlined | same | x=1156..1183 against 1220..1247, 15px tall with the underline against 15 |
| hairline under the header | same | full-bleed x=0..1279 at y=56 against y=55 |
| quiet `Voltar para Início` above the title | same | note: capture draws none; incumbent month chrome |
| page title `<h1>` `maio de 2026`, slug `2026-05` in soft ink under it | same | 216x28 at y=151..178 and 50x9 at y=193..201 against the capture's y=102..129 and y=144..152 |
| summary sentence | same | note: the picture's month is confirmed, so it draws the other summary state - `2 pagamentos com documento faltante.` in margem plus `Falta o extrato de 4 contas ativas.`, 528px wide against the capture's 589px `Insira os extratos…` sentence - the same fixture fact as the payment statuses |
| `Casar pagamentos` secondary and `Fechar para envio` primary at the title's right | same | note: capture draws none; incumbent month chrome. Both buttons sit at x=841..1183 |
| section heading `Contas bancárias` with a rule under it | same | 143x15 in both; rule x=96..1183 at y=327 against x=32..1119 at y=278 |
| bank sheet head: `Banco`, `Nome`, `Agência/conta`, `Situação`, `Documentos`, empty action head, vertical rules between cells, ink rule under the head | same | the five labels measure 36 / 35 / 86 / 51 / 73px wide in both; neither head carries sort glyphs |
| bank sheet column tracks | same | vertical rules at x=265 / 464 / 624 / 728 / 1007 against the capture's 201 / 400 / 560 / 664 / 943 - 169 / 199 / 160 / 104 / 279 / 176px in both, every offset 64px apart |
| bank sheet block geometry: 1088px wide, ~10px cell padding | same | note: 1088px in both; the capture left-aligns it at x=32..1119 and leaves 160px of page to its right, the picture centres it at x=96..1183 with 96px each side (the page container, both in round 1) |
| row state 1, nothing chosen: bank, name, coordinates, `Falta` in margem, `A planilha é obrigatória` in soft ink, no file line, one `+` | same | note: picture draws it on `conta salário` `2806/55110-8`, fourth row; 41px tall in both |
| row state 2, PDF alone: `Pdf extrato-maio-2026.pdf` above `A planilha é obrigatória`, `+` and `×`, no `✓` | same | note: picture draws it on `poupança`, fifth row; the Documentos cell measures 157px in both; the staged line is soft ink where the capture draws it in body ink (shade) |
| row state 3, PDF and spreadsheet: `Pdf` above `Planilha`, `✓` and `×` | same | note: picture draws it on `conta corrente`, second row; the cell measures 187px in both; both staged lines soft ink (shade) |
| row state 4, refused: `Só PDF, .csv ou .xlsx` in margem above `A planilha é obrigatória`, one `+`, nothing staged | same | note: picture draws it on `aplicação` `2806/40022-1`, first row; 134px in both, both printing the refusal as a plain margem sentence in the cell with no second bar |
| row state 5, Presente: `Presente` in body ink, `Pdf` above `Planilha`, pencil | same | note: picture draws it on `conta corrente BB` `2806/33117-0`, third row; 187px and the status 62px wide in both; the capture repeats `2806/24942-4` twice and the picture does not (fixture data) |
| action cell: 16px stroke glyphs, `caixa` for `+`, `✓` and pencil, `margem` for `×`, side by side with a small gap, vertically centred | same | the single glyph's ink is 10x10 at x=1027..1036 against 963..972; the pair spans 47px in both (1026..1072 against 962..1008); the pencil is 13x13 with 62 ink px in both, at x=1026..1038 against 962..974 on the Presente row. The same three ink colours in both - `caixa` for `+` and `✓`, `margem` for `×` |
| one control per row; no band, no chip, no second form surface, no visible `Incluir extrato` / `Substituir extrato` | same | AD-0015 |
| legend paragraph `Estados: 1 sem nada escolhido, …` under the sheet | same | note: the sketch's own state annotation, not page copy; the picture draws none |
| account chips `Todas` … `poupança` above Pagamentos | same | note: capture draws none; incumbent month chrome. Six chips 34px tall on one row at y=658..691 - 68 / 94 / 131 / 155 / 118 / 97px wide - in the band where the capture draws its legend paragraph |
| bank row heights | same | note: the head is 45px in both (327..372 against 278..323); the one-line state is 41px in both (519..560 against 323..364); a two-line state is 49px in the picture and 52px in the capture, a hair tighter |
| `Pagamentos` heading with a rule under it | same | note: picture draws it as an open disclosure summary, `▾ Pagamentos`, 122px wide at x=96..217 against the capture's 102px; rule x=96..1183 at y=772 against x=32..1119 at y=715. Incumbent month chrome |
| payment sheet head labels `Data`, `Histórico`, `Valor`, `Status`, `Documento` | same | note: `Histórico` 52px and `Documento` 67px in both; `Data` 41px and `Valor` 44px against the capture's 27 and 31 |
| payment head labels carry sort glyphs | same | note: `Data ↑` and `Valor ↕` are drawn and the capture's labels are bare, but the head's five tracks and every rule sit at the same offsets in both, so nothing in the sheet moves. Incumbent sortable-ledger chrome the sketch omits; the plan does not change it and AD-0015 does not cover it - reported, not blocking |
| payment column tracks | same | vertical rules at x=247 / 719 / 847 / 1007 against the capture's 183 / 655 / 783 / 943 - 151 / 472 / 128 / 160 / 176px in both |
| payment rows: four rows, two lines each, history over the account meta, both `…` with the full text in `title`, never wrapped | same | notes: 43px pitch in both (rules at 813 / 856 / 899 / 942 / 985 against 756 / 799 / 842 / 885 / 928), every row two lines and no row a third |
| type step: history, status and document at `14px`/`18px`, account meta at `13px`/`18px` | same | history 13px tall and 370 / 302 / 384 / 375px wide in both; status 11px tall; document 14px tall; the two-line cell 28px in both |
| amount right-aligned in its track, tabular digits, same step as the history | same | 90 / 75 / 66 / 75px wide by 15px, all ending at x=836 against the capture's x=772 - the same 11px inset from the 128px Valor track's right rule at 847 and 783 |
| status word left-aligned in the Status track | same | x=859 against 794, the same 126 / 46 / 95px widths as the capture in rows 1-3 (the capture's `Casado` reads 47); note: the picture draws `Documento faltante` in margem where the capture draws the same words in body ink (shade) |
| Documento cell: matched payee names, truncated with `…` | same | row 2 draws `Atacado de Confecçõe…` 153x14 against the capture's 154x14, both inside the 176px track; note: rows 1, 3 and 4 are empty because those payments carry no document |
| no third line, no match observation in the row | same | both rows are two lines |
| red left margin, 3px, inset on the first cell | same | 3px at x=96..98 on rows 1 and 4 (814..855, 943..984) against x=32..34 on the capture's row 1 (757..798); the first line starts 16px in at x=112 against 48, so the inset matches too. The margin follows the missing-document rows only in both |
| `Documentos sem casamento` and `Recebimentos` folds under Pagamentos | same | note: the capture ends at its fourth payment row's rule at y=928 and draws neither fold; the picture's frame ends at its fourth payment row's rule at y=985 with the folds below the 993px window - neither picture draws a fold |

### `captures/statement-row-390.running.png`

| Element | Result | Picture draws |
| --- | --- | --- |
| render: 390x1833, the capture's own size, not resized - `maio de 2026` 168x22 in both, `2026-05` 50x9 in both, `06/05/2026` 87x16 at x=36 in both, `R$ 1.200,00` 90x15 ending x=369 in both, the history line 215x13 in both, `Documento faltante` 126x11 in both | same | note: the earlier full-page picture was 2153px tall; the frame now ends at 1833 like the capture's |
| header: mark and brand | same | note: AD-0016 - the picture's brand takes one line (mark 20x20 at x=20..39, `Fechamento Mensal` 146px to x=194, the org-switcher badge `Caminhada` 108x32 at x=219..326); the capture draws a three-line brand block ending x=150 with `Centro Social da Rua` inline |
| nav links: `Início`, `Documentos`, `Configuração`, `Administração`, `Sair` | same | note: AD-0016, approved difference - five labels in that order, `Sair` underlined last, left-aligned at the gutter on two rows (39 / 89 / 93px at y=57..73 running x=21..284, then 103 / 28px at y=85..101 running x=20..171). The capture keeps the same five labels in a right-hand column x=186..331 over three rows beside the three-line brand. Accepted by the user: "Aceitar - registrar como diferença aprovada; o header do app continua como está" |
| hairline under the header | same | full-bleed x=0..389 at y=116 against y=120 |
| `Voltar para Início` above the title | same | note: capture draws none; incumbent month chrome |
| page title `<h1>` and slug `2026-05` | same | 168x22 at y=209..230 and 50x9 at y=244..252 against the capture's y=165..186 and y=200..208 |
| summary sentence | same | the picture draws the confirmed-state missing-document summary on two lines, 336 and 186px wide, against the capture's `Insira os extratos…` on two lines, 333 and 252px - the other summary state, as at 1280 |
| `Casar pagamentos` and `Fechar para envio` | same | note: capture draws none; incumbent month chrome. Both buttons at y=274..315 |
| `Contas bancárias` heading with a rule under it | same | 143x15 in both; the picture's rule at y=460 against the capture's y=358 |
| content box: section rules, row rules and fold rules run the gutter to gutter | same | every long rule runs x=20..369 - y=460, 673, 870, 1067, 1246, 1443, 1690, 1756, 1806 against the capture's y=358, 553, 753, 953, 1153, 1353, 1532, 1603, 1658, 1713, 1768: a 20px gutter on both sides, as the capture draws. Round 1's 6px right gutter was the full-page scrollbar, and it is gone |
| bank rows stacked: bank, name, coordinates, then `Falta` or `Presente`, then the document lines, then the icons; one row per account with a rule between | same | five rows in both, each one account |
| bank row inner gutters: text at x=20-21, icons on a row under the documents | same | note: rows run 195-200px in the capture and 179-213px in the picture; the 179px one is the empty state, which stacks the fewest lines |
| the five bank-row states, one per account | same | the same five states in both - one empty, `Pdf` alone above the hint with `+` and `×`, `Pdf` above `Planilha` with `✓` and `×`, the margem refusal above the hint with one `+`, and Presente with the pencil - on different accounts and in a different order (fixture data) |
| action icons per state: one `+`; `+` and `×`; `✓` and `×`; one `+`; pencil | same | the same five shapes in the same order of state |
| legend paragraph `Estados: …` | same | note: the sketch's state annotation, 5 lines at y=1373..1454; the picture draws none |
| account chips `Todas` … `poupança` above Pagamentos | same | note: capture draws none; incumbent month chrome. Three wrapped rows at y=1492..1609 |
| `Pagamentos` disclosure heading with a rule under it | same | 102px of label in both; the picture prefixes the `▾` glyph, 12x10 at x=20..31 |
| payment row first line: date left, amount right | same | 87x16 at x=36 and 90x15 at x=280..369 in both - round 1's type-step row is closed at the capture's own size |
| payment row second line: truncated history left, status right | same | history 215x13 at x=24..238 and status 126x11 at x=244..369 in both |
| Documento cell and the account meta line hidden | same | no ink in either beyond x=369 in the payment rows |
| history truncated with `…` (`MAR…`, `Confecc…`, `Cobra…`, `ROSE…`) | same | the picture's two whole rows truncate exactly as the capture's do: row 1 ends `…` at x=238 against 238 (both against the 126px status), row 2 at x=291 against 291 (both against the 46px `Casado`), and the third row is cut by the window. The rows the 1833px frame cuts are covered by the 1280 picture, where all four truncate |
| type step of the payment row | same | the first line is the capture's step: 16px tall for the date against 16, 15px for the amount against 15; the second line 13px and 11px in both |
| status word in margem, right-aligned | same | 126x11 ending x=369 in both, `Casado` 46px against 47 |
| red left margin on each payment row | same | 3px at x=20..22 on row 1 (1707..1755) and none on row 2, which reads `Casado`, exactly as the capture draws it (1549..1602, none on its row 2) |
| `Documentos sem casamento` and `Recebimentos` folds | same | note: the capture draws four payment rows and its last ink is the rule at y=1768, with no fold; the picture draws two rows in full (rules 1756, 1806) and the third row's text cut at y=1829 by the 1833px window, with no fold either. The page chrome above Pagamentos - three chip rows where the capture draws the legend - is what puts the picture's later rows below the frame |

### The accepted difference

The one row that draws something other than the sketch is the phone nav's arrangement, and it is
decided: `docs/adr/0016-month-page-phone-header.md` records it as an approved difference, and the
plan's `## Differences from the source` carries the row with `Confirmed: y - AD-0016`. The sketch
draws a three-line brand block with the nav in a right-hand column; `layouts/_header` is shared by
every signed-in screen, so it keeps its own wrap - brand on one line, nav wrapping under it,
left-aligned at the gutter, the same five labels in the same order with `Sair` underlined last. The
picture draws precisely that, so the row reads `same` against the approved shape, not `differs` against
the sketch.

The 1280 picture has no accepted difference of its own: its one note worth repeating is the payment
head's sort glyphs, incumbent chrome the sketch omits, whose tracks and rules are identical and which
this feature does not touch.

### The two open questions from round 1

**Closed at 1280.** The mixed fixture draws both readings the round-1 picture could not: the Documento
column carries `Atacado de Confecçõe…` in a 153px cell, the same width the capture truncates in, so AC
13's `…` is drawn and measured; and the red margin runs on the two `Documento faltante` rows only, so
the "a missing row only" rule is visible. One residue, not a gap: the capture has two matched rows
carrying payees (`Atacado…` 154px, `Roselena Borges da Si…` 152px) and the picture has one, because its
fourth payment is `Documento faltante` rather than `Casado` - the same fixture fact as the status
column, and one instance already proves the rule at the capture's width.

Nothing was open at 390 on truncation: the history truncates in every row of both pictures.

### AC 15's no-horizontal-scroll clause

**Carried.** The content box is x=20..369 inside a 390px window, 20px on both sides as the capture
draws, and the only ink outside it is the full-bleed header hairline at y=116 (x=0..389), which the
capture also draws full-bleed at y=120. The widest payment-row ink ends at x=369, the rules at 369, and
no cell is clipped or scrolled off the window. The picture is a 390px viewport capture at the capture's
own size, so this is the page's own layout and not a resized frame.

### Verdict

`captures/statement-row.running.png` **matches**. `captures/statement-row-390.running.png` **matches**,
with the nav's arrangement recorded as the difference AD-0016 approved. Every row this feature owns
reads `same` in both pictures, and the content-box row that carries AC 15 reads `same`.
