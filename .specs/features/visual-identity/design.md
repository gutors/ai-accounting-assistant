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
Success: fill `caixa`, white text, `role="status"`. Error: `margem` rule like Notice
(`border-l-[3px] border-margem`, `text-margem`), `role="alert"`, not `[data-notice]`.
Timeout `5000` ms. Dismiss control text `Fechar`. Stimulus removes the node. No CSS
`transition` or `@keyframes`. `prefers-reduced-motion` does not change the timeout.

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
  Mês | AAAA-MM | Status                       ← column names; from 768px
  maio de 2026    2026-05    Aberto            ← li[data-row="month"]; link on month_title
  abril de 2026   2026-04    Fechado
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
  `Aberto` or `Fechado` in `ink-soft`. `Nenhum mês aberto` stays as the empty state.
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
  cadastro (no presentation name): Nome de apresentação / CPF/CNPJ (preencher apenas números) / Razão social / PIX / Email para envio  [Salvar contador]
  leitura (presentation name exists): those five fields read-only, formatted CPF/CNPJ on read  [Editar]
Arquivo do pacote                               (h2)
  form: URL da pasta do Drive  [Salvar arquivo]
Certificado SEFAZ                               (h2)
  state line; Remover (quiet, margem); form: Arquivo / Senha [Instalar certificado]
Contas bancárias                                (h2)
  Conta Principal            extrato-conta-principal        Desativar
  ag 1234                                                    ▸ Editar   ← details with the edit form
  form: Nome / Banco / Coordenadas  [Adicionar conta]
Tipos extras de exceção                         (h2)
  Doação                                        Desativar  Excluir
  form: Nome  [Adicionar tipo extra]
```

- Contador is cadastro when there is no presentation name; after that name exists the same five fields are read-only plus `Editar`. `GET /setup?edit=accountant` is the writable form. Formatted CPF/CNPJ on read. `Arquivo do pacote` stays the always-writable URL form (`Salvar arquivo`) — #81.
- Bank account rows are `li[data-row="bank-account"]`: name (500), slug and coordinates in meta,
  `Inativa` in `ink-soft` when inactive, quiet actions, then `<details><summary>Editar</summary>`
  with the existing edit form.
- Extra exception kinds are `li[data-row="extra-exception-kind"]`.
- Forms are two columns from 768px where fields are short (accountant form: 2 columns).
- New copy: `Configuração` (h1), `Editar`.

### `month` — `GET /months/:year_month`

```
header · nav
maio de 2026                                        [ Fechar para envio ]     (open)
2026-05                                             ⌈Mês fechado⌉ [Restaurar pasta] [Reabrir]  (closed)
2 pagamentos com documento faltante.  Falta o extrato de 1 conta ativa.
<notice>
Contas bancárias                                (h2)
  Conta Principal   ag 1234      Presente   extrato.pdf, extrato.xlsx    ▸ Substituir extrato
  Conta Alfa                     Falta      PDF [..] Planilha [..] [Enviar extrato]
Recebimentos                                    (h2)
  04/05/2026  Pix - Recebido                   R$ 63,00
              Conta Principal
Pagamentos                                      (h2)
▌ 11/05/2026  Pix enviado — Padaria Central   R$ 220,00   Documento faltante
▌             Conta Principal                              Sugestão Padaria Central
▌                                                          ▾ Resolver (open: suggestion exists)
                                                             ☐ Padaria Central  ☐ Mercado Silva
                                                             Observação do casamento [    ]
                                                             [Confirmar casamento]
                                                             [Marcar tarifa] [Marcar honorário] [Doação]
  12/05/2026  Tarifa Pacote de Serviços        R$ 155,00   Tarifa bancária
              Conta Principal                              Desmarcar exceção
  ▸ Casar vários pagamentos com um documento               ← details with the N:1 form
Documentos sem casamento                        (h2)
  ☐ Padaria Central                            R$ 220,00   Devolver
```

- Title: `<h1>` is the month in words (`maio de 2026`, from `pt-BR.date.month_names`) in
  display size; `2026-05` directly under it in meta `ink-soft` (it is the month folder name the
  accountant sees). Right side: the primary action when open; when closed, the stamp
  `[data-stamp="closed"]` `Mês fechado` and the two secondary buttons.
- Summary line, body size, under the title: missing documents first, statements second.
  - `Nenhum documento faltante` when none; `1 pagamento com documento faltante`;
    `N pagamentos com documento faltante`. The missing-document sentence is `margem` when N > 0.
  - `Falta o extrato de 1 conta ativa` / `Falta o extrato de N contas ativas`; omitted when
    every active account has its statement.
- Bank account rows `li[data-row="bank-account"]`: name and coordinates | `Presente` with the
  two filenames in meta, or `Falta` in `margem` | when absent the upload form is inline; when
  present it is inside `<details><summary>Substituir extrato</summary>`. Closed month: no form.
- Inflows `li[data-row="inflow"]`: date | history + account | amount. No status cell.
- Payments `li[data-row="payment"][data-payment-id][data-status]`, `data-status` one of
  `missing`, `matched`, `bank_fee`, `accountant_fee`, `extra`. A `missing` row carries the red
  margin. Status cell shows the status words (`Documento faltante`, `Casado` + payees +
  observation, `Tarifa bancária`, `Honorário do contador`, or the extra kind name), the
  `Sugestão` / `Sugestão de exceção` text when present, then either the quiet undo action or,
  for `missing`, `<details><summary>Resolver</summary>` holding the match form and the exception
  buttons. That `<details>` is `open` exactly when a suggestion or exception suggestion exists.
- N:1 form: after the payments list, inside `<details><summary>Casar vários pagamentos com um
  documento</summary>`, same condition as today.
- Pool `li[data-row="pool-document"][data-document-id]`: checkbox (when the document has no month
  and the month is open) with the payee as its label | amount | `Devolver` when applicable.
- New copy: the summary sentences, `Resolver`, `Substituir extrato`, `Casar vários pagamentos
  com um documento`, month names.

### `documents` — `GET /supporting_documents`

```
header · nav
Documentos de suporte                           (h1)
<notice>
Incluir documento                               (h2)
  Tipo [v]        Valor [    ]      ← two columns from 768px, one on phone
  Data [    ]     Favorecido [    ]
  Chave de acesso [                          ]
  Observação [                               ]
  Foto [file]     XML [file]
  [Incluir documento]
Sem mês                                         (h2)
  11/05/2026  Padaria Central                  R$ 155,00
              Recibo (meta)
              3524 0612 3456 7800 0190 5500 1000 0012 3410 0001 2340   (mono)
              foto.jpg, nota.xml (meta)
              pago em dinheiro (meta, the observation)
              Casado em 2026-05 (coordinator only)
              [Usar dados da SEFAZ]  (only when pending)
              ▸ Editar  → details: edit form, then Excluir (quiet, margem)
Justificativas                                  (h2)
  R$ 300,00   Padaria Central, Mercado Silva     ▸ Editar (submitter, when allowed)
  form: Valor gasto [    ]  ☐ Padaria Central … [Justificar]   (submitter only)
```

- Phone-first: one column, full-width inputs, the insert form is the first section because it is
  the submitter's job.
- Document rows `li[data-row="document"][data-document-id]`: date | payee (500) with kind, chave
  (grouped, mono, `data-chave`), filenames, observation and month status as meta lines | amount.
  The raw 44-digit chave stays as the value of the edit field.
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
