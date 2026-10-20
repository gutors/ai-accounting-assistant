# Visual identity — livro-caixa

Binding design source for the `visual-identity` feature. Screens: `login`, `denied`, `home`,
`setup`, `month`, `documents`. Copy lives in the ERB under `app/views/`; this file lists only the
copy this feature adds, and the arrangement each screen must show.

## Brief

Subject: the monthly bank-to-document close a financial coordinator runs for an ONG, then hands
to the accountant. The audience is two people: the coordinator (laptop, once a month, dense
data, needs to reach zero missing documents) and the submitter (phone, uploads a photo of a
recibo after buying supplies). The material is paper bookkeeping — ruled ledger paper, thermal
receipts, the DANFE with its 44-digit chave printed in groups of four, a manila folder per month.

Primary job of the interface: make the state of the month legible at a glance and lead the
coordinator to the next missing thing until the month can be closed for send.

## Concept: livro-caixa

The Brazilian paper cash book: ruled paper, green ruling, one red margin rule, columns for data,
histórico, and valor. The app is a well-kept ledger.

- Every list of money is a **ledger row**: aligned columns, tabular figures, amount right-aligned.
- The page's one loud device is the **red margin**. It marks a payment with a missing document
  and an error message, nothing else. A month page with no red is ready to close.
- **`Mês fechado` is a stamp**: an inked, double-ruled mark. Nothing else is boxed.
- Sections are separated by **ruling**, not by cards. No shadows, no gradients, no icons other
  than the app mark.
- Motion: none that the user did not trigger. `<details>` opening and the toast timeout
  (after the action that set the toast) are the state changes.

## Tokens

Declared as Tailwind v4 `@theme` variables in `app/assets/tailwind/application.css`. Views use
the token utilities (`bg-paper`, `text-ink`, `border-rule`, `bg-caixa`, `text-margem`), never
the raw Tailwind palette.

### Color

| Token | Hex | Role |
| --- | --- | --- |
| `paper` | `#f3f5f1` | page background |
| `sheet` | `#ffffff` | inputs, open `<details>` panels |
| `ink` | `#1b3229` | text, primary borders, the stamp |
| `ink-soft` | `#5c6e66` | secondary text: filenames, coordinates, account name under history |
| `rule` | `#c7d5ca` | ledger ruling: row separators, section rules, input borders |
| `caixa` | `#2e6b4e` | primary button, links, focus ring, focused organization |
| `margem` | `#b4372a` | red margin: missing document, errors, destructive text actions |

Contrast: `ink` on `paper` > 12:1; `caixa` on `sheet` 6.3:1; `margem` on `sheet` 6.0:1; white on
`caixa` 6.3:1.

### Type

One family. **IBM Plex Sans** 400 (body), 500 (row primary text, labels), 600 (headings, stamp,
primary buttons). **IBM Plex Mono** 400 only for the chave de acesso. Self-hosted woff2, Latin
subset, `font-display: swap`. Fallback stack `"IBM Plex Sans", ui-sans-serif, system-ui, sans-serif`.

| Role | Size / line | Weight | Notes |
| --- | --- | --- | --- |
| display (month title) | 2.25rem / 1.1 | 600 | tracking −0.02em; 1.75rem below 768px |
| h1 | 1.5rem / 1.75rem | 600 | tracking −0.01em |
| h2 (section) | 1.125rem / 1.5rem | 600 | sits on a `rule` underline |
| body | 1rem / 1.5rem | 400 | forms, sentences |
| row primary | 1rem / 1.5rem | 500 | history, payee, account name |
| meta | 0.8125rem / 1.125rem | 400 | `ink-soft`: filenames, coordinates, slug |
| amount | 1rem / 1.5rem | 500 | `tabular-nums`, right-aligned |
| chave | 0.8125rem / 1.125rem | mono 400 | grouped `dddd dddd …` (11 groups of 4) |

Sentence case everywhere. No all-caps labels, no eyebrow labels, no letterspaced small caps.
Line length of prose ≤ 72ch; forms ≤ 28rem wide.

### Layout

- Content column `max-w-6xl` (72rem), left-aligned, `px-5` on phone, `px-8` from 768px.
- Vertical rhythm: header 3.5rem; `mt-10` to page title; `space-y-12` between sections; `pb-16`.
- Ledger row grid from 768px: `[5.5rem minmax(0,1fr) 8rem 12rem]` = data | histórico (+ account
  name in meta below) | valor | situação. Below 768px: data and valor on the first line, histórico
  on the second, situação on the third. Rows separated by a 1px `rule`; no row background.
- `<details>` action panel: `sheet` background, 1px `rule` border, `rounded`, `p-4`, `mt-3`,
  full width of the row. `<summary>` is a text link in `caixa`, 500.
- Controls: `rounded` (4px). Primary button `bg-caixa text-white px-4 py-2 font-semibold`.
  Secondary button `border border-ink text-ink px-4 py-2`. Quiet text action (`Revogar`,
  `Excluir`, `Desmarcar exceção`, `Desfazer casamento`, `Devolver`, `Cancelar`, `Desativar`,
  `Reativar`, `Sair`) `text-margem underline underline-offset-2` for destructive, `text-caixa`
  otherwise. Inputs `bg-sheet border border-rule rounded px-3 py-2 w-full`.
- Focus: global `:focus-visible { outline: 2px solid var(--color-caixa); outline-offset: 2px }`.
- Red margin: `border-l-[3px] border-margem pl-3` on the row (`data-status="missing"`) and on
  error notices.
- Stamp: `inline-block border-2 border-ink rounded-[2px] px-2 py-0.5 font-semibold` plus
  `outline outline-1 outline-offset-[3px] outline-ink` (double rule).

### Mark

`public/icon.svg`: a `#2e6b4e` square with 4px radius; inside, two `#f3f5f1` horizontal rules
(ledger ruling) and one `#b4372a` vertical rule near the left edge (the red margin). No text.
`public/icon.png` regenerated from it.

## Principles

1. **Ledger first.** Money is always a ruled row with aligned columns and tabular figures.
2. **One red.** `margem` only marks what blocks the close or what went wrong.
3. **Actions fold, status shows.** A row's status is always visible; the forms that change it
   live in a `<details>` that opens when there is something to confirm (a suggestion).
4. **Copy is the interface.** The page says what is missing in a sentence, in the words of
   `CONTEXT.md`; no numbers without their noun.
5. **Nothing decorative.** No cards, shadows, icons, eyebrows, dots, arrows, or motion.

## Components

### Header (`app/views/layouts/_header.html.erb`)

```
┌──────────────────────────────────────────────────────────────────┐
│ ▣ ONG Norte                    Início  Documentos  Configuração  Sair │
└──────────────────────────────────────────────────────────────────┘ ← 1px rule
```

- Left: mark (1.25rem) and the focused organization name in 500; when no organization is
  focused (login, denied): `Fechamento mensal`.
- Right: `Início` (`/`), `Documentos` (`/supporting_documents`), `Configuração` (`/setup`, coordinator
  only), `Sair` (DELETE `/session`, quiet text button). On login and denied: no nav.
- Below 640px the nav wraps under the name.

### Section heading

`<h2>` in 600 with `pb-2 border-b border-rule mb-4`. Sections are `<section>`s `space-y-12`.

### Ledger row

`<li data-row="…">` on the grid above. Cells in order: date (`<time>`), primary text (500) with
meta below (`ink-soft`), amount (`data-cell="amount"`, `tabular-nums text-right`), status. The status cell holds the
status words and, when applicable, a `<details>` with the forms.

### Notice

`<p role="alert" data-notice="error" class="border-l-[3px] border-margem pl-3 text-margem">` for
every existing error message (`@import_error`, `@month_error`, `@document_error`,
`@certificate_error`). Placed directly under the page title.

### Toast

Layout banner immediately after `header` and before `main`. One `[data-toast]` at a time.
Success: fill `caixa`, white text, `role="status"`. Error: fill `margem`, white text,
`role="alert"`, not `[data-notice]`. Timeout `5000` ms. Dismiss control text `Fechar`.
Stimulus removes the node. No CSS `transition` or `@keyframes`. `prefers-reduced-motion`
does not change the timeout.

### Empty state

A single sentence in body weight (`Nenhum documento`, `Nenhuma conta bancária ativa`, …), the
existing copy, followed by the form that fills it when one exists on the page.

## Screens

Existing copy is preserved verbatim. "New copy" lists every string this feature adds.

### `login` — `GET /login`

```
┌ header: ▣ Fechamento mensal ──────────────────────────────────┐
│                                                               │
│  Fechamento mensal                                  (h1)      │
│  Feche o mês da sua organização: extratos, documentos,        │
│  casamentos e o pacote para o contador.                       │
│                                                               │
│  [ Entrar com Google ]                                        │
└───────────────────────────────────────────────────────────────┘
```

Left-aligned, `max-w-md`, `mt-24`. New copy: the one sentence above.

### `denied` — `GET /denied`

Same shell as login. Body: `Você não foi convidado a usar este sistema.` New copy: none.

### `home` — `GET /` (coordinator)

```
header: ▣ ONG Norte · nav
Organizações                                   (visible label; nav aria-label Organizações)
  ONG Norte                                    ← name in ink, not a button, when only one organization
  [ ONG Norte ] [ ONG Sul ]                    ← only when >1; focused has aria-current
Início                                         (h1)
Selecione um mês para abrir o fechamento ou escolha um na lista abaixo.
Abrir o fechamento mensal                      (h2)
  Mês  [ select today − 12 through today + 12, previous calendar month selected ]  [ Abrir mês ]
Meses                                          (h2)
  Mês | AAAA-MM | Status |                     ← last column is the action; from 768px
  maio de 2026    2026-05    Aberto   Excluir  ← never-sent Aberto; Turbo Excluir este fechamento?
  abril de 2026   2026-04    Fechado           ← Fechado and reopened Aberto omit Excluir
Pessoas                                        (h2)
  Coordenadores            | Submitters         ← two columns from 768px
   ana@…       Revogar     |  joao@…   Revogar
   [E-mail] [Convidar]     |  [E-mail] [Convidar]
Convites pendentes                             (h2, full width)
  E-mail | Tipo | Status                       ← column names; from 768px
  guest@…  Coordenador|Submitter  enviado|falhou envio do e-mail  Reenviar e-mail  Cancelar
```

- The organization switcher keeps its `<nav aria-label="Organizações">` on every home, with the
  visible label `Organizações`. One organization: the focused name as text, not a button. More
  than one: chips; the focused button carries `aria-current="true"` and is filled
  `bg-caixa text-white`; others are secondary.
- Open-month form is the first section after the page title. Months list is a ledger of
  `li[data-row="month"]`: `month_title` linked, `year_month` in meta tabular figures, then
  `Aberto` or `Fechado` in `ink-soft`, then a last action column. `Excluir` is on `Aberto`
  rows that have never been closed-for-send (`month_folder_id` blank), with Turbo confirm
  `Excluir este fechamento?`. `Fechado` and reopened `Aberto` rows omit it.
  `Nenhum mês aberto` stays as the empty state.
- Invite forms sit under their list inside the column. The `Convidar coordenador` /
  `Convidar submitter` headings become the `<legend>`-style labels of those forms; the submit
  stays `Convidar`.
- New copy: `Início` (h1), `Abrir o fechamento mensal`, `Meses` (h2), `Pessoas`, `Aberto`,
  `Fechado`, column names `Mês`, `AAAA-MM`, `Status`, `E-mail`, `Tipo`.

### `home` — `GET /` (submitter)

```
header: ▣ ONG Norte · Início Documentos Sair
Organizações                                   (same block as coordinator)
  ONG Norte
Início                                          (h1)
Inclua e acompanhe seus documentos de suporte em Documentos.   ← link to /supporting_documents
```

New copy: `Início`, `Inclua e acompanhe seus documentos de suporte em Documentos.`

### `setup` — `GET /setup`

```
header · nav
Configuração                                    (h1)
Contador                                        (h2)
  labels text-ink-soft; values font-medium
  cadastro (no presentation name): Nome de apresentação / CPF/CNPJ (preencher apenas números) / Razão social / PIX / Email para envio  [Salvar contador]
  #tax_id tax-id-mask: CPF grouping through 11 digits, CNPJ grouping from the 12th; extra digits dropped
  leitura (presentation name exists): those five values as labeled font-medium text, formatted CPF/CNPJ on read  [Editar]
  GET /setup?edit=accountant: the five fields as inputs; #tax_id prefills formatted  [Salvar contador]
Armazenamento do pacote mensal                  (h2)
  cadastro (no URL): Cole a URL da pasta do Google Drive; URL da pasta do Google Drive  [Salvar arquivo]
  leitura (URL exists): labeled font-medium text plus [Editar]
  GET /setup?edit=package_archive: input#url  [Confirmar]
Certificado Digital A1 - Para consulta na SEFAZ (h2)
  empty: Não há certificado A1 instalado. Use Instalar certificado.
  listed: formatted titular; Válido até / Expirado em; Remover (quiet, margem) outside the fold
  ▸ Instalar certificado   ← details with Arquivo [Limpar] / Senha [Instalar certificado]

Contas bancárias                                (h2)
  Banco do Brasil  Conta Principal  ag 1234  extrato-conta-principal  Ativa  Desativar  Editar
  Santander        Parada                    extrato-parada  Inativa  Reativar  Editar
  ▸ Adicionar conta   ← details; open on edit or bank 422; summary still Adicionar conta
    one section form: Nome / Banco / Agência/Conta Corrente  [Adicionar conta] or [Salvar conta]
  Editar is GET /setup?edit=bank_account&bank_account_id={id}; submit [Salvar conta]
Tipos extras de exceção                         (h2)
  Justificativa                                 ← column heading; no intro under the h2
  Tarifa bancária   Tarifa cobrada pelo banco; não há documento fiscal a anexar.  Ativo  Desativar
  Honorário do contador   Honorário do contador neste fechamento; isento de documento de suporte.  Ativo  Desativar
  Doação            Doação pontual sem nota.                 Ativo  Desativar  Excluir
  base rows: Ativo/Inativo and Desativar/Ativar, no Excluir
  ▸ Adicionar tipo extra   ← details; open on create 422
    form: Nome / Justificativa  [Adicionar tipo extra]
```

- Contador is cadastro when there is no presentation name; after that name exists the five values are labeled-text chrome (`p.font-medium`) plus `Editar`. Labels are `text-ink-soft` (not `font-medium`). Cadastro and `GET /setup?edit=accountant` keep the input chrome. `#tax_id` uses `tax-id-mask` (CPF through eleven digits, CNPJ from the twelfth). Formatted CPF/CNPJ on read and on the edit input.
- Armazenamento do pacote mensal is cadastro when there is no URL (`Cole a URL da pasta do Google Drive`, label `URL da pasta do Google Drive`, `[Salvar arquivo]`). After a URL exists it is labeled `font-medium` text plus `Editar`. `GET /setup?edit=package_archive` is `input#url` with `[Confirmar]`.
- Certificate: heading `Certificado Digital A1 - Para consulta na SEFAZ`. Empty line `Não há certificado A1 instalado. Use Instalar certificado.` when none. When a certificate exists, titular / validity / `Remover` (quiet, margem) stay outside the fold. Arquivo / Senha sit in `<details>` whose `<summary>` is `Instalar certificado`. Arquivo has `Limpar` beside the file control. A `422` from `POST /sefaz_certificate` re-renders that details `open`. HTML `422` does not write Senha into the HTML.
- Bank account rows are `li[data-row="bank-account"]`: four cells in order bank presentation name,
  name, agência/conta corrente, `extrato-{slug}`; Situação `Ativa` or `Inativa` in `ink-soft`; quiet
  `Desativar` / `Reativar` on the row; `Editar` fills the one section form as PATCH `Salvar conta`.
  The add/edit form sits in `<details>` whose `<summary>` is `Adicionar conta` (`open` on edit or
  bank `422`). Empty POST is `Adicionar conta`. Label `Agência/Conta Corrente`. No per-row edit fold.
- Extra exception kinds are `li[data-row="extra-exception-kind"]` (name plus justification). The
  two base document-exception kinds sit first as `li[data-row="base-document-exception"]` with
  fixed copy, not as catalog rows. Every exception-kind row including the two base names shows
  `Ativo` or `Inativo`; base rows have Desativar/Ativar and no Excluir. Extra create sits in
  `<details>` whose `<summary>` is `Adicionar tipo extra`. There is no `Nenhum tipo extra`.
- Forms are two columns from 768px where fields are short (accountant form: 2 columns).
- New copy: `Configuração` (h1), `Editar`.

### `month` — `GET /months/:year_month`

Open and `accounts_confirmed` false:

```
header · nav
maio de 2026                                        [ Fechar para envio ]
2026-05
Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.
<notice>
Contas bancárias                                (h2)
  Conta Principal   ag 1234      Presente   Pdf extrato.pdf              ▸ Substituir extrato
                                         Planilha extrato.xlsx
  Conta Alfa                     Falta                                   ▸ Incluir extrato
Confirmar contas para fechamento                (h2)
  Nome           Situação
  Conta Alfa     Falta                         ← Falta in margem; ledger name order
  Conta Principal Presente
  [Iniciar fechamento]                         ← disabled while no account has a spreadsheet;
                                                   notice: Inclua o extrato planilha de pelo menos uma conta bancária.
                                                   enabled with at least one Presente (mixed Falta allowed)
```

Recebimentos, Pagamentos, and Documentos sem casamento are omitted while unconfirmed and open.

After confirmation, or while closed (even if `accounts_confirmed` is false):

```
header · nav
Voltar para Início → /
maio de 2026                       [ Casar pagamentos ]  [ Fechar para envio ]     (open, confirmed)
2026-05
                                   [Restaurar pasta] [Reabrir]                    (closed)
                                   ⌈Mês fechado⌉ under 2026-05, not on the action row
2 pagamentos com documento faltante.  Falta o extrato de 1 conta ativa.
<notice>
Contas bancárias                                (h2, not in details)
  Conta Principal   ag 1234      Presente   Pdf extrato.pdf              ▸ Substituir extrato
                                         Planilha extrato.xlsx
  Conta Alfa                     Falta                                   ▸ Incluir extrato
[ Todas ]  Conta Alfa  Conta Principal     ← after Contas; ?bank_account_id=; Pagamentos + Recebimentos only
▾ Pagamentos                                (details open; summary heading, no h2)
  Data  Histórico  Valor  Status  Documento
▌ 11/05 Pix enviado — Padaria Central  R$ 220,00  Documento faltante
▌             Conta Principal                      Sugestão Padaria Central
  13/05 Energia                         R$ 340,00  Casado              Enel, CEMIG
  15/05 Honorários                      R$ 800,00  Honorário do contador
▾ Documentos sem casamento
  Data  Favorecido  Tipo  Valor  Foto  Devolver
  11/05 ☐ Padaria Central  Recibo  R$ 220,00  foto.jpg
  18/05 Material de limpeza Recibo R$ 50,00  danfe.jpg  Devolver
▾ Recebimentos                              (last)
  Data  Histórico  Valor
  04/05 Pix - Recebido  Conta Principal  R$ 63,00
```

- Title: `<h1>` is the month in words (`maio de 2026`, from `pt-BR.date.month_names`) in
  display size; `2026-05` directly under it in meta `ink-soft` (it is the month folder name the
  accountant sees). Quiet `Voltar para Início` is first in `<main>`, to `/`. Right side: `Casar
  pagamentos` `.ds-btn-secondary` to `GET /months/:year_month/matches` only while open and
  confirmed, before `Fechar para envio`; when closed, the stamp `[data-stamp="closed"]`
  `Mês fechado` `.stamp-closed` sits under `YYYY-MM` (not on the action row) and title-right is
  only `Restaurar pasta` and `Reabrir`.
- Summary line, body size, under the title. While `accounts_confirmed` is false and the month
  is open, the summary is `Insira os extratos das contas bancárias com as quais deseja
  realizar o fechamento.` (not the missing-document count). After confirmation (or while
  closed), missing documents first, statements second:
  - `Nenhum documento faltante` when none; `1 pagamento com documento faltante`;
    `N pagamentos com documento faltante`. The missing-document sentence is `margem` when N > 0.
  - `Falta o extrato de 1 conta ativa` / `Falta o extrato de N contas ativas`; omitted when
    every active account has its statement.
- After Contas bancárias, while unconfirmed and open: a step `Confirmar contas para
  fechamento` lists each active account’s name with `Presente` or `Falta` (`Falta` in
  `margem`) in ledger name order, two-column ledger (`Nome`, `Situação`), submit
  `Iniciar fechamento`. While that step is shown and no account has a spreadsheet
  statement, `Iniciar fechamento` is disabled and the notice is `Inclua o extrato
  planilha de pelo menos uma conta bancária.`; with at least one Presente it stays
  enabled (mixed Falta allowed). Close-for-send still requires every active account’s statement.
  That step is absent after confirmation or while closed.
  `Recebimentos`, `Pagamentos`, and `Documentos sem casamento` are omitted until then.
  After confirmation (or while closed), the missing-document summary and those three
  lists appear as `<details open class="month-fold">` with summary headings (Recebimentos
  last); chips sit after Contas; the confirm step is absent.
- Bank account rows `li[data-row="bank-account"]`: name and coordinates | Situação `Presente`
  or `Falta` in `margem` (no filenames) | Documentos: `Pdf {filename}` when a PDF is attached
  (omitted otherwise), `Planilha {filename}` when a spreadsheet is attached, one per line, no
  wrap | when Falta and the month is open, `<details><summary>Incluir extrato</summary>` (closed
  until a `422` for that account); when Presente and open, `<details><summary>Substituir
  extrato</summary>`. Closed month: no form.
- Account chips: `role="group"` `aria-label` `Conta bancária`; `Todas` then active accounts by
  name; `?bank_account_id=`; default all; Pagamentos and Recebimentos only; pool unfiltered;
  unknown, foreign, or inactive id `404`.
- Inflows `li[data-row="inflow"]`: date | history + account | amount. No status cell. Last fold.
  No `Documento faltante`.
- Payments `li[data-row="payment"][data-payment-id][data-status]`, `data-status` one of
  `missing`, `matched`, `bank_fee`, `accountant_fee`, `extra`. A `missing` row carries the red
  margin. Columns: Data, Histórico, Valor, Status, Documento. There is no Ações, no `Resolver`,
  no N:1 fold, no `Marcar tarifa` / `Marcar honorário` / extra submit, no `Desfazer casamento`,
  no `Desmarcar exceção`. Status cell shows the status words (`Documento faltante`, `Casado` +
  observation, `Tarifa bancária`, `Honorário do contador`, or the extra kind name) and
  `Sugestão` / `Sugestão de exceção` meta when present. Documento is matched payee names,
  comma-separated; empty on missing and on every exception.
- Pool `li[data-row="pool-document"][data-document-id]`: Data (`time` `document_on`), Favorecido
  (checkbox `form="close-month"` when the document has no month and the month is open, payee as
  label), Tipo `Recibo` / `Nota fiscal`, Valor, Foto (filename as `text-caixa` underlined
  `url_for` of the photo blob, same tab; empty when no photo), then `Devolver` when `month_id`
  is this Month. Closed month: no checkbox and no Devolver. Empty: `Nenhum documento sem casamento`.
- New copy: `Voltar para Início`, the summary sentences, `Incluir extrato`, `Substituir extrato`,
  `Casar pagamentos`, month names, Documentos `Pdf` / `Planilha`, pool `Foto`.

### `matches` — `GET /months/:year_month/matches`

```
header · nav
maio de 2026                                        Voltar ao mês
2026-05
[ Todas ]  Conta Alfa  Conta Principal
1 pagamento com documento faltante.                 ← margem when N > 0
Próxima sugestão
Pagamento 11/05 Pix — Padaria 220,00  casar com  Documento 11/05 Padaria 220,00
Pagamentos R$ 220,00 · Documentos R$ 220,00 · Soma igual
Observação do casamento  [Confirmar casamento] [Marcar tarifa] …
Pagamentos (~60%)                 Documentos sem casamento
☐ 11/05  Pix — Padaria   220,00 Faltante   ☐ 11/05 Padaria  220,00 Recibo
× 15/05  Honorários      800,00 Casado
```

- Title month in words (`maio de 2026`) plus `2026-05` in meta under it. Quiet `Voltar ao mês`.
  no `Fechar para envio` and no stamp.
- Chips `Todas` then active accounts by name, `?bank_account_id=`, default all, Pagamentos only.
- Missing-count copy (`Nenhum documento faltante.` / `1 pagamento com documento faltante.` /
  `N pagamentos com documento faltante.`) and `margem` when N > 0.
- Sticky band above the sheets: `Próxima sugestão` (Pagamento | `casar com` | Documento, day/month
  + amount + payee) then totaling / observação / confirm / marks. Dates `11/05`. Pool oldest →
  newest. click equal confirms. no `Casar` and no `Sugestão {payees}` on the payment row;
  `Sugestão de exceção` stays on the row.
- Two sheets from 1100px (Pagamentos wider), stacked below with Pagamentos first. Payment first
  cell checkbox vs `×`; no `Resolver`. Pool columns Data / Favorecido / Valor / Tipo; empty
  `Nenhum documento sem casamento`.
- Totalling line and the three verdicts (`Soma igual`, `Documentos somam menos`, `Documentos somam mais`); stay after confirm.

### `documents` — `GET /supporting_documents`

```
header · nav
Documentos de suporte                           (h1)
<notice>
Incluir documento                               (h2)
  empty: proof square is the only file control (click or drop). One file: foto or XML.
         book: Inclua o documento. Valor, data e favorecido saem do arquivo.
  after identify, two columns from 768px (proof stacks first below 768px):
  left proof: preview of the photo including an image PDF + Limpar inside the square
  right 28rem: Arquivo [Foto|XML locked]  Tipo [locked]
               Valor / Data / Favorecido with origin under each
               Chave de acesso (opcional)  ← hidden when Tipo is Recibo
               Observação (opcional)
               [Incluir documento]
  identifying: Identificando o arquivo…
  HTML 422 fallback echoes Arquivo, Tipo, Valor, Data, Favorecido, Chave, Observação;
         the square's file input stays in the form (Turbo Stream 422 does not replace it)
Sem mês                                         (h2)
  Data | Favorecido | Tipo | Valor | Ações
  11/05/2026  Padaria Central     Recibo   R$ 155,00   ▸ Editar
              3524 0612 3456 7800 0190 5500 1000 0012 3410 0001 2340   (mono)
              foto.jpg, nota.xml (meta)
              pago em dinheiro (meta, the observation)
              Casado em 2026-05 (coordinator only)
              [Usar dados da SEFAZ]  (only when pending)
              Excluir (quiet, margem) sits in Ações, not inside Editar
              Editar does not offer a control that changes Tipo
Justificativas                                  (h2)
  R$ 300,00   Padaria Central, Mercado Silva     ▸ Editar (submitter, when allowed)
  form: Valor gasto [    ]  ☐ Padaria Central … [Justificar]   (submitter only)
```

- Phone-first: one column, full-width inputs, the insert form is the first section because it is
  the submitter's job.
- Insert has one file control: the proof square. `Limpar` sits inside the loaded square and
  returns it to empty without a persist. There is no second Foto or XML chip on insert.
  Both files or neither is `422` `Envie a foto ou o XML`.
- `GET /supporting_documents/:id/edit` has no XML file control. Arquivo is Foto or XML, locked.
  The file cannot be replaced; copy: `O arquivo não pode ser alterado. Exclua o documento e inclua novamente.`
  The proof previews an attached PDF the same way it previews a JPEG (embed of the photo blob, not filename-only).
- HTML `422` fallback on `POST /supporting_documents` echoes Arquivo, Tipo, Valor, Data, Favorecido, Chave,
  and Observação; the square's file input stays in the form.
- Document rows `li[data-row="document"][data-document-id]`: date | payee (filenames, chave,
  observation, month status as meta under payee) | Tipo | amount | Ações (`Editar` disclosure;
  `Excluir` in Ações, not inside the edit panel). Kind is not a meta line under payee. Editar
  does not offer a control that changes Tipo. The raw 44-digit chave stays as the value of the
  edit field.
- Justification rows `li[data-row="justification"]`.
- New copy: `Editar`.

## Responsive and accessibility floor

- No horizontal scroll at 390px on any screen.
- Every control reachable by keyboard with the `caixa` focus ring; `<details>` is native.
- Labels stay visible and associated (`for`/`id` unchanged). Destructive confirms unchanged
  (`data-turbo-confirm`).
- `prefers-reduced-motion`: nothing to reduce; no transitions or keyframes are shipped.
  The toast timeout stays `5000` ms.

## Rejected

- Warm cream paper with a serif display: the generic default; not ledger paper.
- Cards per record with shadows: hides the column alignment that makes a ledger scannable.
- A table element for ledgers: payment rows hold forms; grid rows on `<ul>` keep the markup
  valid and stack on phones.
- Disabling `Fechar para envio` while documents are missing: the server already answers with the
  reason; a disabled button hides it.
- Google Fonts: a third-party request per page view.
