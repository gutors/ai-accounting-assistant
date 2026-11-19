# Setup desk screens

**Verifier**: independent sub-agent (author != verifier)
**Round**: 2
**HEAD**: b03e73d

| Screen | Compared with | Verdict | Finding |
| --- | --- | --- | --- |
| `captures/setup-gaps.running.png` | `captures/setup-gaps.png` | matches | 4 former `differs` rows now `same`; no `same` row regressed |

### `captures/setup-gaps.running.png`

Round 1 `differs` rows reopened on the re-saved picture. Regression scan of round-1 `same` rows: none broke.

| Element | Result | Picture draws |
| --- | --- | --- |
| render: 1920×1080, same pixel size as the capture; labels the capture draws (`Configuração`, `Arquivo do pacote`, `Falta`, `Salvar arquivo`) at the same size, not resized | same | type family matches the capture’s IBM Plex |
| arrangement: full-width header; two-pane desk under it; left index, right selected item; vertical hairline between panes | same | header content a hair more inset |
| header mark: green rounded square, cream horizontal rails, red spine | same | |
| header brand `Fechamento Mensal - ONG Norte` | same | |
| header: filled chip `exemplo` (capture draws none) | same | none |
| prototype scene switcher above the header | same | omitted — confirmed difference AD-0014 |
| principal nav, right: `Início`, `Documentos`, `Configuração` current (underline), `Sair` in green | same | |
| header bottom hairline | same | |
| left: heading `Configuração` with a hairline under it | same | |
| left list: five rows in order Contador, Arquivo do pacote, Certificado A1, Contas bancárias, Tipos extras; hairline under each | same | |
| Contador: title, meta `Ana Contábil`, status `Cadastrado` muted on the right; no red margin | same | |
| Arquivo do pacote selected: title in green, meta `Pasta do Drive`, `Falta` in red on the right, red left margin | same | `Falta` a shade heavier |
| Certificado A1: title not current, meta `Consulta SEFAZ`, `Expirado` in red on the right, red left margin | same | `Expirado` a shade heavier |
| Contas bancárias: title, meta `2 contas`, status `Ativas` muted on the right; no red margin | same | |
| Tipos extras: title, meta `Tarifa e honorário`, status `2 ativos` muted on the right; no red margin | same | |
| right `<h1>` `Arquivo do pacote` | same | |
| right subtitle `Pasta do Google Drive onde o fechamento grava o mês.` muted under the heading | same | |
| `Cole a URL da pasta do Google Drive` in red with a short left red bar | same | |
| label `URL da pasta do Google Drive` above the field | same | |
| URL field: placeholder `https://drive.google.com/drive/folders/…` | same | |
| filled submit `Salvar arquivo` under the field | same | |
