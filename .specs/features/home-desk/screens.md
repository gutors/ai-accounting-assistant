# Home desk screens

**Verifier**: independent sub-agent (author != verifier)
**Round**: 1
**HEAD**: 7b5a2b5

| Screen | Compared with | Verdict | Finding |
| --- | --- | --- | --- |
| `captures/coordinator-home.running.png` | `captures/coordinator-home.png` | matches | all 28 rows `same` |

### `captures/coordinator-home.running.png`

| Element | Result | Picture draws |
| --- | --- | --- |
| render: 960×970, same pixel size as the capture; labels the capture draws (`Abrir mês`, `Meses`, `outubro de 2026`, `Continuar`, `Contas bancárias`) at the same size, not resized | same | note: a native vertical scrollbar on the right edge; extra length follows confirmed Excluir and Pessoas-below-desk. Type family matches the capture’s IBM Plex |
| arrangement: header full width; `main` two columns with a vertical rule; left pane first, right pane second | same | |
| header mark: green rounded square, cream horizontal rails, red spine | same | |
| header brand `Fechamento Mensal - ONG Norte` | same | |
| principal nav, right: `Início` current (underline), then `Documentos`, `Configuração`, `Sair` | same | note: `Sair` green and underlined, as in the capture; type weight on `Início` is a shade |
| left: org chips `ONG Norte` filled current, `ONG Sul` outlined, on one row | same | |
| `Abrir mês` label with a rule under it | same | |
| Abrir mês controls on one row: select, then filled submit `Abrir mês` | same | |
| select visible value | same | capture draws `novembro de 2026`; picture draws `outubro de 2026` — previous calendar month relative to 2026-11-18; a date that follows the day, not wrong |
| `Meses` heading with a rule under it | same | |
| Meses list arrangement: year_month desc; one open row, then three closed rows | same | |
| open row: title `outubro de 2026`, `em trabalho` in green under the title, `Aberto` muted on the right | same | |
| `Excluir` on the never-sent open month | same | red underlined `Excluir` under the outubro row — confirmed difference AD-0012 (capture has no Excluir) |
| closed row `setembro de 2026` with stamp `Fechado` | same | |
| closed row `agosto de 2026` with stamp `Fechado` | same | |
| closed row `julho de 2026` with stamp `Fechado` | same | |
| `Fechado` stamp: boxed double-border mark | same | |
| right lead arrangement: `h1` left, filled `Continuar` top-right of the pane | same | |
| `h1` `outubro de 2026` | same | |
| subline `2026-10` under the `h1`, muted | same | |
| sentence `3 pagamentos com documento faltante.` | same | |
| that sentence in margem: red type, short red bar on the left | same | |
| `Contas bancárias` heading with a rule under it | same | |
| sheet heads `Banco`, `Nome`, `Extrato` | same | |
| sheet row: `Banco do Brasil`, `Conta Principal`, `Presente` | same | |
| sheet row: `Caixa`, `Conta Alfa`, `Falta` | same | |
| `Falta` in margem (red) | same | |
| sheet drawing: ruled cells, vertical and horizontal lines, Extrato column narrower | same | |
