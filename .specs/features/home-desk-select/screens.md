# Home desk select screens

**Verifier**: independent sub-agent (author != verifier)
**Round**: 2
**HEAD**: 495c3c7

| Screen | Compared with | Verdict | Finding |
| --- | --- | --- | --- |
| `captures/month-desk.running.png` | `captures/month-desk.png` | matches | |
| `captures/org-list.running.png` | `captures/org-list.png` | matches | |
| `captures/people-desk.running.png` | `captures/people-desk.png` | matches | |
| `captures/closed-month.running.png` | `captures/closed-month.png` | matches | |

### `captures/month-desk.running.png`

| Element | Result | Picture draws |
| --- | --- | --- |
| arrangement: full-width header; two-pane desk; left column (Abrir mês, Meses, people pin); right column (selected month) | same | |
| header: book mark + title `Fechamento Mensal` | same | |
| header: organization button `ONG Exemplo`, filled | same | |
| header nav: `Início` current (underlined), `Documentos`, `Configuração`, `Sair` in green | same | |
| left: label `Abrir mês` | same | |
| left: select showing `outubro de 2026` with chevron, and filled submit `Abrir mês`, on one row under the label | same | select a hair narrower; gap to the button slightly tighter |
| left: heading `Meses` with hairline under | same | |
| Meses row `novembro de 2026`: name in green, `Aberto` gray on the right, `em trabalho` in green under the name (selected) | same | row padding slightly tighter |
| Meses row `outubro de 2026`: name, outlined stamp `Fechado` on the right | same | |
| Meses row `setembro de 2026`: name, `Aberto` gray on the right | same | |
| Meses row `agosto de 2026`: name, outlined stamp `Fechado` on the right | same | |
| Meses: hairlines between rows; no `Excluir` on any row | same | |
| left pin at the bottom of the column, hairline above: title `Coordenadores e submitters` (not current) | same | |
| pin meta: `3 coordenadores · 2 submitters · 1 falhou envio` with the failed phrase in red; no `convite` | same | |
| right: `<h1>` `novembro de 2026` | same | |
| right: subtitle `2026-11` | same | |
| right: filled `Continuar` then outlined danger `Excluir`, on one row under the date | same | |
| right: `2 pagamentos com documento faltante.` in red with a short left red bar | same | |
| right: heading `Contas bancárias` | same | |
| bank sheet: ruled table, heads `Banco`, `Nome`, `Extrato` | same | column widths slightly more open |
| row `Banco do Brasil` / `Conta movimento` / `Presente` | same | |
| row `Itaú` / `Poupança` / `Presente` | same | |
| row `Sicoob` / `Projetos` / `Falta` in red | same | |

### `captures/org-list.running.png`

| Element | Result | Picture draws |
| --- | --- | --- |
| arrangement: month desk as in `month-desk.png`, with the organization list open over the header and the top of both panes | same | |
| header: book mark + title `Fechamento Mensal` | same | |
| header: organization button `ONG Exemplo`, filled, list hanging from it | same | |
| listbox: first option `ONG Exemplo` on filled green (current), flush under the button | same | |
| listbox: second option `Instituto Água Viva` on white | same | list a hair narrower |
| listbox overlay: covers the Abrir mês select chevron; leaves the `Abrir mês` submit in view; clips the right `<h1>` to `vembro de 2026` | same | |
| header nav: `Início` current, `Documentos`, `Configuração`, `Sair` in green | same | |
| left: label `Abrir mês`; select `outubro de 2026` and submit `Abrir mês` on one row | same | select a hair narrower |
| left: heading `Meses` with hairline under | same | |
| Meses row `novembro de 2026`: name in green, `Aberto`, `em trabalho` (selected) | same | |
| Meses row `outubro de 2026`: name, outlined stamp `Fechado` | same | |
| Meses row `setembro de 2026`: name, `Aberto` | same | |
| Meses row `agosto de 2026`: name, outlined stamp `Fechado` | same | |
| left pin: `Coordenadores e submitters` with `3 coordenadores · 2 submitters · 1 falhou envio` (failed phrase in red) | same | |
| right: subtitle `2026-11`; filled `Continuar` then outlined `Excluir` | same | |
| right: `2 pagamentos com documento faltante.` in red with a short left red bar | same | |
| right: heading `Contas bancárias`; ruled sheet `Banco` / `Nome` / `Extrato` | same | |
| row `Banco do Brasil` / `Conta movimento` / `Presente` | same | |
| row `Itaú` / `Poupança` / `Presente` | same | |
| row `Sicoob` / `Projetos` / `Falta` in red | same | |

### `captures/people-desk.running.png`

| Element | Result | Picture draws |
| --- | --- | --- |
| arrangement: same two-pane desk; left column unchanged except the people pin current; right column is the people book | same | |
| header: book mark + `Fechamento Mensal`; filled `ONG Exemplo`; nav `Início` current, `Documentos`, `Configuração`, `Sair` | same | |
| left: label `Abrir mês`; select `outubro de 2026` and submit `Abrir mês` on one row | same | select a hair narrower |
| left: heading `Meses` with hairline under | same | |
| Meses row `novembro de 2026`: name in green, `Aberto`, `em trabalho` | same | |
| Meses row `outubro de 2026`: name, outlined stamp `Fechado` | same | |
| Meses row `setembro de 2026`: name, `Aberto` | same | |
| Meses row `agosto de 2026`: name, outlined stamp `Fechado` | same | |
| left pin current: title `Coordenadores e submitters` in green; meta `3 coordenadores · 2 submitters · 1 falhou envio` with the failed phrase in red | same | |
| right `<h1>` `Coordenadores e submitters`, wrapping after `e` | same | |
| people-book meta: `5 pessoas · 2 convites · 1 falhou envio` in muted type | same | |
| invite form: email placeholder `E-mail` and kind select `Coordenador` on one row; outlined submit `Convidar` under the row | same | |
| heading `Coordenadores` with hairline under | same | |
| principal row: email `gutors@gmail.com`, `Principal` under it, no `Revogar` | same | |
| standing coordinator `ana.costa@ongexemplo.org` with `Revogar` on the right | same | |
| standing coordinator `rafael.mendes@ongexemplo.org` with `Revogar` on the right | same | |
| pending coordinator invite `marina.dias@ongexemplo.org`: address wraps so `g` sits on the next line; `Reenviar e-mail` and `Cancelar` in a right column on the first line, with a gap from the address; `Convite · enviado` under the address | same | wrap breaks at `.` so `org` sits on the next line rather than a lone `g` |
| heading `Submitters` with hairline under | same | |
| standing submitter `lucia.alves@ongexemplo.org` with `Revogar` on the right | same | |
| standing submitter `paulo.nunes@ongexemplo.org` with `Revogar` on the right | same | |
| failed submitter invite `joao.freitas@ongexemplo.org`: address wraps so `org` sits on the next line; `Reenviar e-mail` and `Cancelar` in a right column on the first line; `Convite · falhou envio do e-mail` in red wrapping after `do`; red left bar on the block | same | wrap breaks before `.` so `.org` sits on the next line rather than `org` |

### `captures/closed-month.running.png`

| Element | Result | Picture draws |
| --- | --- | --- |
| arrangement: two-pane desk; left Meses with `outubro de 2026` current; right is that closed month | same | |
| header: book mark + `Fechamento Mensal`; filled `ONG Exemplo`; nav `Início` current, `Documentos`, `Configuração`, `Sair` | same | |
| left: label `Abrir mês`; select `outubro de 2026` and submit `Abrir mês` on one row | same | select a hair narrower |
| left: heading `Meses` with hairline under | same | |
| Meses row `novembro de 2026`: name not current, `Aberto` gray, `em trabalho` in green | same | |
| Meses row `outubro de 2026`: name in green (selected), outlined stamp `Fechado` on the right | same | |
| Meses row `setembro de 2026`: name, `Aberto` | same | |
| Meses row `agosto de 2026`: name, outlined stamp `Fechado` | same | |
| left pin: `Coordenadores e submitters` (not current) with `3 coordenadores · 2 submitters · 1 falhou envio` (failed phrase in red) | same | |
| right: `<h1>` `outubro de 2026` with filled `Continuar` on the same row, right-aligned | same | |
| right: subtitle `2026-10` | same | |
| right: outlined stamp `Mês fechado` under the date | same | |
| right: no `Excluir` | same | |
| right: sentence `Nenhum documento faltante.` in muted type, no red bar | same | |
| right: heading `Contas bancárias` | same | |
| bank sheet: ruled table, heads `Banco`, `Nome`, `Extrato` | same | column widths slightly more open |
| row `Banco do Brasil` / `Conta movimento` / `Presente` | same | |
| row `Itaú` / `Poupança` / `Presente` | same | |
| row `Sicoob` / `Projetos` / `Presente` | same | |
