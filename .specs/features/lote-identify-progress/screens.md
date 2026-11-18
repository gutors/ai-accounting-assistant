# Lote identify progress screens

**Verifier**: independent sub-agent (author != verifier)
**Round**: 1
**HEAD**: bc4af95

| Screen | Compared with | Verdict | Finding |
| --- | --- | --- | --- |
| `captures/lote-b-faixa-fila.running.png` | `captures/lote-b-faixa-fila.png` (tick states also against `captures/ruler-states.png`) | diverges | 6 rows differ |

### `captures/lote-b-faixa-fila.running.png`

| Element | Result | Picture draws |
| --- | --- | --- |
| render: 716×798, labels the capture draws (`Incluir documentos`, `Tipo`, `Valor`, sheet head) at the same size, not resized | same | note: the page type family differs slightly from the capture's (different sans glyphs); size matches |
| section heading `Incluir documentos`, bold, top left | same | |
| heading border absent; the rule takes its place under the heading | same | |
| rule: ten ticks spanning the content width, edge to edge | same | |
| ticks 1–4 filled `caixa` (dark green) | same | |
| ticks 5–8 hollow, 2px `caixa` outline, matching `ruler-states.png` `5–8 em leitura` | same | |
| ticks 9–10 filled pale `rule` | same | |
| sentence `Identificando os documentos 5 a 8 de 10` under the rule, left, small bold | same | |
| arrangement: proof square on the left, form column on the right, under the sentence | same | |
| proof square: outer frame with an inner frame; access key in monospace inside the inner frame | same | empty inner frame — approved departure AD-0011 |
| proof square height: ends near the `Favorecido` note (~y 420), well above the bottom of `Observação`; form column is the taller of the two | differs | proof square runs to ~y 612, below the `Observação` field (~y 515); it is now taller than the form column |
| proof square caption `XML - <file name>`, `XML` bold, under the inner frame and inside the outer frame | differs | caption `XML - d1.xml` sits inside the inner frame, at its bottom edge |
| `Tipo` label, field `Nota fiscal` | same | |
| green note `Definido pelo XML.` under `Tipo` | same | absent — approved departure AD-0011 |
| `Chave de acesso (opcional)` label and field | same | |
| access key value in the field: monospace, grouped in fours separated by spaces (`3526 0511 2223 …`) | differs | one unbroken 44-digit run (`43260511222333000181550010000000011123456780`) in smaller monospace |
| `Valor` and `Data` side by side on one row | same | |
| `Valor` field value with currency, `R$ 155,00` | differs | `10,00` — no `R$` prefix |
| `Data` field `11/05/2026` | same | |
| note `XML autorizado` under `Valor` and under `Data` | same | note: slightly smaller type |
| `Favorecido` label and field (payee name) | same | note: fixture payee `Emitente 1` instead of `Padaria Central` |
| note `XML autorizado` under `Favorecido` | same | |
| `Observação (opcional)` label and empty textarea with resize grip | same | |
| action row under the form: `Incluir prontos (4)` filled green, `Incluir este` outlined, `Retirar` red outline, left to right | same | note: the row sits ~70px lower (y ≈ 650 vs ≈ 580), following the taller proof square |
| lote sheet head: `Data`, `Favorecido`, `Tipo`, `Valor` (right aligned), `Situação`, column separators | same | |
| row 1: selected, green border; `11/05/2026`, bold payee, sub-line `XML · <file name>`, `Nota fiscal`, bold right-aligned `R$` value, `Pronto`; no second sentence under the file name | same | note: fixture values `Emitente 1`, `d1.xml`, `R$ 10,00` |
| row 2: `08/05/2026`, bold payee, sub-line `Foto · <file name>`, `Nota fiscal`, `R$ 320,00`, `Pronto`, fully in view | differs | cut off by the window's bottom edge mid-line: only the top of `11/05/2026  Emitente 2  Nota fiscal  R$ 11,00  Pronto`; no sub-line in view |
| row 3: `03/05/2026`, `Farmácia São José`, `Nota fiscal`, `R$ 89,40`, `Pronto`, in view above the crop | differs | not in view — scrolled below the window |
