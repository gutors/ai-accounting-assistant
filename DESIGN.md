---
name: Fechamento mensal
description: A well-kept ledger for closing an NGO's month.
colors:
  caixa: "#2e6b4e"
  margem: "#b4372a"
  aviso: "#8a5c0a"
  paper: "#f3f5f1"
  sheet: "#ffffff"
  ink: "#1b3229"
  ink-soft: "#5c6e66"
  rule: "#c7d5ca"
typography:
  display:
    fontFamily: "IBM Plex Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "2.25rem"
    fontWeight: 600
    lineHeight: 1.1
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "IBM Plex Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.5rem"
    fontWeight: 600
    lineHeight: "1.75rem"
    letterSpacing: "-0.01em"
  title:
    fontFamily: "IBM Plex Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 600
    lineHeight: "1.5rem"
  body:
    fontFamily: "IBM Plex Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: "1.5rem"
  label:
    fontFamily: "IBM Plex Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 500
    lineHeight: "1.5rem"
  button:
    fontFamily: "IBM Plex Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 600
    lineHeight: "1.5rem"
  meta:
    fontFamily: "IBM Plex Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.8125rem"
    fontWeight: 400
    lineHeight: "1.125rem"
  amount:
    fontFamily: "IBM Plex Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 500
    lineHeight: "1.5rem"
    fontFeature: "tnum"
  chave:
    fontFamily: "IBM Plex Mono, ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: "0.8125rem"
    fontWeight: 400
    lineHeight: "1.125rem"
rounded:
  control: "4px"
  stamp: "2px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  gutter: "20px"
  gutter-wide: "32px"
  page: "40px"
  section: "48px"
  header: "56px"
  page-end: "64px"
components:
  button-primary:
    backgroundColor: "{colors.caixa}"
    textColor: "{colors.sheet}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    padding: "8px 16px"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "8px 16px"
  button-danger:
    backgroundColor: "transparent"
    textColor: "{colors.margem}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "8px 16px"
  button-filter-current:
    backgroundColor: "{colors.caixa}"
    textColor: "{colors.sheet}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    padding: "4px 12px"
  button-filter:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "4px 12px"
  button-org-switch:
    backgroundColor: "{colors.caixa}"
    textColor: "{colors.sheet}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    padding: "4px 12px"
  action-destructive:
    textColor: "{colors.margem}"
    typography: "{typography.body}"
  action-quiet:
    textColor: "{colors.caixa}"
    typography: "{typography.body}"
  input:
    backgroundColor: "{colors.sheet}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "8px 12px"
  disclosure:
    backgroundColor: "{colors.sheet}"
    rounded: "{rounded.control}"
    padding: "16px"
  stamp:
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.stamp}"
    padding: "2px 8px"
  stamp-row:
    textColor: "{colors.ink}"
    typography: "{typography.meta}"
    rounded: "{rounded.stamp}"
    padding: "1px 6px"
  notice:
    textColor: "{colors.margem}"
    typography: "{typography.body}"
    padding: "0 0 0 12px"
  toast-ok:
    backgroundColor: "{colors.caixa}"
    textColor: "{colors.sheet}"
    typography: "{typography.body}"
    padding: "12px 20px"
  toast-error:
    backgroundColor: "{colors.margem}"
    textColor: "{colors.sheet}"
    typography: "{typography.body}"
    padding: "12px 20px"
---

# Design System: Fechamento mensal

## Overview

**Creative North Star: "Livro-caixa"**

The interface is a well-kept Brazilian cash book. The page is cool ledger paper. Every list of money is a ruled row: date, history, amount, status, with figures in tabular numbers and the amount on the right. The only loud hue is the red of the cash-book margin. It marks a payment that still lacks a document, an error, a failed invite, and a destructive action. A month page with no red in the records is ready to close.

Density follows the coordinator's laptop ritual. Início is a two-pane close desk: a 26rem month index on the left, the selected month or the people book on the right. Every other signed-in page is one left-aligned column, 72rem at most, sections separated by a rule. Status stays on the row. The form that changes a row folds into a disclosure or a work panel the person opens. The submitter's phone uses the same tokens, stacked.

The closed month is an ink stamp, the only double-ruled mark in the system. The app mark repeats the same three strokes — a green field, two paper rules, one red margin — and carries no wordmark. The header always reads the product name. When more than one organization is in play, a caixa-filled switcher opens a sheet list under it.

**Key Characteristics:**

- **Ruled rows.** Money and document lists are a ledger sheet: vertical and horizontal rules, not cards.
- **Two layouts.** Início and Configuração are two-pane desks. Close work, documents, and administration stay a single ledger column.
- **One red.** `margem` is the only red. It is a left rule on a blocked row, a sentence, a quiet destructive word, or a toast fill.
- **Flat paper.** Depth is a hairline rule, not a drop shadow. A work panel is a ruling-bordered sheet.
- **The stamp.** A closed month is inked and double-ruled. The index uses a compact “Fechado”; the month page uses “Mês fechado”.
- **One type family.** IBM Plex Sans for the book; IBM Plex Mono only for the access key.

## Colors

Tokens live as theme colors. Views use the token, never a raw palette step. Contrast floors the identity commits to: ink on paper above 12:1; caixa on sheet, margem on sheet, and white on caixa each at least 6:1.

### Primary

**Ledger green** (`caixa`) fills the primary button, colors links and disclosure summaries, draws the focus ring, fills the organization switcher and the current filter chip, and fills a success toast. It is the working green of the book, not a highlight sprinkled on decoration.

### Signal

**Margin red** (`margem`) is the red rule of the cash book. It is the left edge of a payment with a missing document, the color of an error notice, a failed-invite count, a destructive text action, a danger secondary border, and an error toast. It is not a second brand color.

**Mustard ink** (`aviso`) is the only yellow. It marks `Faltam extratos` on an open month row in the home Meses list. It is not a fill, a badge, or a second brand color. Missing documents stay `margem`.

**The One Red Rule.** `margem` is the only red. A month page with no red in the records is ready to close.

### Neutral

**Ledger paper** (`paper`) is the page, the header, the wait veil, and the home index pin. It is a cool gray-green, the color of ruled paper, not warm cream.

**Sheet white** (`sheet`) is the field inside a control, the open org list, a work panel, and the selected lote row. Inputs sit on a sheet; the page stays paper.

**Forest ink** (`ink`) is text, the secondary button's border, the stamp, and table text. **Soft ink** (`ink-soft`) is the second line: filenames, account coordinates, the month-folder name, an inactive account, and "Em andamento" on an open month row that already has its statements.

**Ruling green** (`rule`) is the 1px line under a section heading, between rows, around a field or an open panel, and the dashed drop zone.

## Typography

One family, self-hosted, Latin subset, `font-display: swap`. IBM Plex Sans at 400 for sentences, 500 for the primary text of a row and for field labels, 600 for headings, the stamp, and primary buttons. The fallback stack is IBM Plex Sans, then the UI sans. IBM Plex Mono at 400 is the only other face.

- **Display** (600, tight leading, slight negative tracking): the month in words (`maio de 2026`) and the people-book title. On the month and match pages it steps down to 1.75rem below 768px; the token itself is the larger size. The home desk uses the token size at every width.
- **Headline** (600, slight negative tracking): page titles (`Documentos de suporte`, `Administração`, login).
- **Title** (600): a section heading, sitting on a ruling underline.
- **Body** (400): sentences and secondary buttons. Prose stays within a 72-character measure.
- **Label** (500): the history, payee, or account name on a row, and the visible label of a field.
- **Button** (600, body size): primary actions and the month-page stamp. Secondary buttons stay at body weight.
- **Meta** (400, soft ink): filenames, coordinates, the month-folder slug, document kind. The compact “Fechado” stamp uses this size at weight 600.
- **Amount** (500, tabular figures): right-aligned. Dates on a row use the same tabular figures at body weight.
- **Chave** (mono 400, meta size): the 44-digit access key, shown as eleven groups of four. The edit field keeps the raw digits.

**The Sentence Case Rule.** Labels, buttons, and headings stay in sentence case. No all-caps, no eyebrow, no letterspaced small caps. The header product name is the one title-case exception: `Fechamento Mensal`.

**The Chave Rule.** IBM Plex Mono appears only on the access key.

## Layout

Signed-in pages other than Início and Configuração live in a 72rem column, left-aligned, inside the viewport. The page gutter is 20px on a phone and 32px from 768px. Below the header (minimum height 3.5rem) the title sits 40px down; sections stack 48px apart; the column ends with 64px.

**Início (coordinator).** From 768px the main is a two-pane desk: a 26rem index with a right ruling, and a scrolling in-work pane. The index is `Abrir mês` (select and primary on one row), then `Meses` as a single-rule list (title `Setembro - 09/2026`, `Faltam extratos` in aviso or `Em andamento`, or the compact Fechado stamp), then a paper pin at the bottom for `Coordenadores e submitters`. The right pane shows the selected month (display title, `YYYY-MM`, Continuar, missing-document sentence, three-track Contas bancárias) or the people book. Below 768px the panes stack. Submitter home is not this desk: it is the one-column sentence that points at Documentos.

**Configuração (coordinator).** From 768px the same two-pane desk: a 26rem index of the five standing items (Contador, Arquivo do pacote, Certificado A1, Contas bancárias, Tipos extras), and the selected item’s form on the right. Incomplete items take the red margin and `Falta` or `Expirado` in `margem`. Below 768px the panes stack. Submitter has no Configuração.

**Sheets.** From 768px every money or document list is a ruled sheet: 1px vertical `rule` between cells, 1px horizontal `rule` between rows, snug cell padding (6px by 10px; payment rows 3px vertical). Head and body rows of one sheet share one column template. Below 768px the header hides, cells stack, and vertical rules drop. There is no horizontal scroll at 390px.

Column templates from 768px:

- Month payment: 9.5rem date (`time`, nowrap, tabular), flexible history, 8rem amount, 10rem status, 11rem Documento (matched payee names).
- Month Contas bancárias: Banco, Nome, Agência/conta, Situação (6.5rem), Documentos (filenames in meta, truncated), statement action (11rem).
- Home Contas bancárias: Banco, Nome, Extrato (6.5rem).
- Documents Sem mês: 9.5rem date, flexible payee, 7rem kind, 8rem amount, 5.5rem actions.
- Administration: name, email, 7rem status, 5rem Editar.
- Matching workspace: payment and document rows carry a checkbox, flexible description and amount; completed records use scrollable tables.
- Lote queue: 9.5rem date, flexible payee, 8rem amount, 8rem kind, 7rem status.

The people book is not a five-track sheet. It is grouped `person-entry` rows: email (and Principal) on the left, quiet actions on the right, a 1px rule under each row. Invites sit in the same list. The invite form is one row: email, kind (11rem), secondary Convidar.

**The Ledger Column Rule.** Money and document records are a ruled sheet with aligned columns, vertical rules, and tabular figures. The amount is right-aligned. Status and each action occupy their own columns. The home month index and the people book are single-rule lists, not sheets.

**The Shared Track Rule.** Head and body of a sheet use the same column template. Action tracks are fixed rem, never `auto` or `max-content`: the header cell is empty, and a content-sized track would let the row drift off the rule.

**The Desk Rule.** Início and Configuração are two panes from 768px. Do not restack those pages as chapters.

## Elevation & Depth

The system is flat. There is no drop-shadow vocabulary and no gradient. A row, a section, and a field are separated by the ruling line. The red margin is the only edge that means "this blocks the close." An open disclosure, the org list, and a proof pane are white sheets with a ruling border, not raised cards.

Focus is a 2px solid ledger-green ring, offset 2px, on every control. It is the same ring everywhere. A selected lote row draws that ring inset on the row. A hollow lote tick (the file being read) is an inset 2px caixa ring on a paper fill — a drawn outline, not elevation.

The toast is a full-bleed bar pinned to the top of the viewport (z-40). The wait veil is paper at 72% over the main, starting under the header. Neither uses a shadow.

Motion is limited to what the person triggered. Opening a native disclosure, the org list, wait, or toast is a state change, not a transition. No `transition` and no `@keyframes` ship in product CSS, so a reduced-motion setting has nothing to remove. Primary buttons do not recolor on hover; links and quiet actions gain an underline. A success toast dismisses after five seconds; a progress toast stays until the work ends.

**The Flat Ledger Rule.** Surfaces stay flat. Depth is the ruling line and the red margin. Do not introduce a drop shadow to float a panel.

## Shapes

Controls, fields, disclosures, the org list, work panels, and filter chips share a 4px corner. The page, the header, and the rows are square. The stamp is the exception: a 2px corner, a 2px ink border, and a second 1px ink outline set 3px outside, so it reads as a double rule. The compact index stamp uses the same double rule at a smaller padding.

The red margin is a 3px left border with 12px of inset, on the row and on the error notice. Section headings take a 1px ruling underline. The app mark is a green square whose corner, at header size, matches the 4px control radius; inside it, two paper rules and one red vertical rule.

Stroke icons are 12px (sort chevron) or 16px (pencil, trash) with a 1.5 stroke in the current color. Zoom on a proof is “+” / “−” in 32px sheet buttons, not pictograms. The mark is the only brand emblem.

The documents drop zone is the only dashed rule: 4px corner, dashed `rule`, paper fill, 16px padding, min-height 8rem.

**The Stamp Rule.** The only double-ruled mark is the closed-month stamp. Its double rule is the whole treatment.

**The Four Pixel Rule.** Controls, fields, and panels share one small corner. The page itself stays square.

## Components

### Buttons

- **Shape:** 4px corner. Primary, secondary, and danger share 8px vertical and 16px horizontal padding. Class `.ds-btn-primary` / `.ds-btn-secondary`.
- **Primary:** ledger-green fill, sheet-white label, weight 600. This is "Fechar para envio", "Entrar com Google", "Incluir documento", "Abrir mês", "Continuar", and every other commit action. No hover recolor. Focus uses the global ring.
- **Secondary:** transparent fill, 1px ink border, ink label at body weight. "Casar pagamentos", "Reabrir", "Restaurar pasta", "Convidar", "Corrigir", and "Filtrar".
- **Danger secondary:** the secondary shape with margem label and margem border. Class `.ds-btn-secondary.ds-btn-danger`. "Excluir" on a never-sent month, "Retirar" on a lote row.
- **Quiet:** no border and no fill. An underline sits 2px under the words. Destructive words (revoke, delete, undo a match, deactivate) are margin red. Other quiet words, including "Sair" and inline links, are ledger green. Match undo and exception unmark are margem text actions on the matching screen, not month-row actions.

### Filter chips

Bank filters on the month and match pages are a row of small buttons. The current account (or `Todas`) is a primary fill with tighter padding (4px by 12px) and `aria-current`. The others are ink-bordered chips at that same padding.

### Organization switcher

A caixa-filled button in the header, only when more than one organization can be focused. It shows the current name (ellipsis at 18rem), `aria-haspopup="listbox"`. Open, the top corners square off and a sheet list drops under it (1px `rule` border, 4px on the free corners, min 16rem). The current option is caixa fill; the others are quiet ink rows that underline on hover. A single-organization account does not get this control: the name is appended to the product name in the header.

### Cards / Containers

Record lists are not cards. Three sheet panels exist, all flat:

- **Disclosure:** sheet ground, 1px ruling border, 4px corner, 16px padding, sitting under a ledger-green summary.
- **Proof pane:** the photo or XML beside an insert form — sheet, ruling border, 4px, with the image on paper inside.
- **Matching workspace:** payment and document selections use flat ruled sheets in two columns. Confirmation and exception marking share the primary action; the exception picker follows the organization switcher. Confirmed matches and marked exceptions occupy separate ruled tables with details and undo actions.

### Inputs / Fields

Sheet ground, 1px ruling border, 4px corner, 8px by 12px padding, full width of the form. Labels stay visible above the field at label weight. Focus uses the global ring. An error is not a red field border; it is the notice under the page title, or a toast after a submit.

**File field.** The native picker is covered, not shown. The control is a sheet field: ruling border, 4px corner, empty copy “Nenhum arquivo” in meta soft ink. A chosen filename replaces that copy at label weight. The action chip on the right uses the primary fill (“Incluir foto”, “Incluir XML”, “Incluir arquivo”). It is not a second form commit. **Limpar** sits beside the chip as a quiet underlined action and zeros that control without a submit. Disabled is 50% opacity and ignores pointer events. The month statement row does not use this control: see **Statement row**.

**Lote drop.** Coordinator insert replaces the file field with the dashed drop zone until files are in. Then a proof pane and a 28rem book sit side by side from 768px.

**Statement row.** The month page's extrato control is not a field or a disclosure. One icon in the account row's own action cell, at the `.ledger-action-icon` size (1.75rem hit area, 16px stroke glyph): a `+` when the account has no statement, the pencil when it has one, each carrying `aria-label` and `title` (`Incluir extrato` / `Substituir extrato`). It opens one native picker that accepts `.pdf`, `.csv` and `.xlsx`; the choice is staged in the Documentos cell as `Pdf {filename}` above `Planilha {filename}` in meta soft ink, one line each, truncated with a `title`. While no spreadsheet is staged the cell keeps `A planilha é obrigatória` and the action cell shows `+` and `×`; with the spreadsheet it shows `✓` (`Enviar extrato`) and `×` (`Descartar`). A file that is neither kind is refused and the cell prints `Só PDF, .csv ou .xlsx` in margem above the hint. There is no band, no bordered panel, and no filled action chip on this row. Replacement is the same gesture; a closed month shows no control.

**Image zoom.** On a proof, “+” / “−” sit at the top-right of the image as 32px sheet buttons with a ruling border.

### Navigation

A paper bar with a 1px ruling line along its bottom. Left: the mark at 1.25rem and `Fechamento Mensal`, then the org switcher when there is more than one organization. Right: text links in ink (Início, Documentos, Configuração, Administração) that underline on hover; the current item is semibold and underlined (`aria-current="page"`). “Sair” is a quiet ledger-green action. Below 640px the links wrap under the name. Login and the denied page keep this bar with the mark and product name, and no nav links.

### Ledger row

A list item in a CSS grid sheet (`.ledger-sheet` / `.ledger-row`), not a table and not a card. Direct children are cells. Head and body share the sheet’s column template. Sortable header cells (`ledger_sort_cell` / `.ledger-sort-link`) link the column label with a 12px linear sort-direction SVG and set `aria-sort` (`descending`, `ascending`, or `none`) on the header cell; the active column takes `.sort-key`. Lists that filter use `shared/_ledger_filters` above the sheet (payee search, kind select, `De`/`Até` dates, `Filtrar`, and `Limpar`). Row action cells (`shared/_ledger_row_actions`) may use 16px stroke SVG icon controls (`.ledger-action-icon`): pencil in `caixa` for `Editar` and trash in `margem` for `Excluir`, each carrying `aria-label`, `title`, and screen-reader label text. The month statement row uses the same control for `Incluir extrato` / `Substituir extrato` (see **Statement row** under Inputs / Fields). The month payment sheet runs date, primary text with a soft-ink meta line under it, amount, Status, then Documento (payee names) as separate columns — not stacked inside status. A month payment row is two lines at most (`14px` / `18px` for history, status and document, `13px` / `18px` for the account meta), every one of those cells truncated with `title`, and a match observation is read on Casar, not here. Matching undo (`Resolver`, `Desfazer casamento`, `Desmarcar exceção`) is not a month-row action; it lives on the matches screen. A missing document adds the red margin (3px left border, 12px inset on the first cell) and the status words in margin red. One sheet per section; do not group rows into status bands.

### Desk lists

The month index and the people book are not sheets. Each row is a two-column grid with a 1px `rule` under it. The selected month title and the current people-nav title go caixa and semibold. Open month rows carry `Faltam extratos` in aviso or `Em andamento` in soft ink; closed rows carry the compact Fechado stamp. A blocked person or a failed invite takes the red margin on the row.

### Notice

An alert paragraph: margin-red text, 3px margin-red left border, 12px inset. It sits directly under the page title.

### Toast

A full-width bar pinned to the top of the viewport. Success and progress fill `caixa`; error fills `margem`. Sheet-white sentence, quiet “Fechar” on the right, white focus ring. Error and success dismiss after five seconds; progress stays until dismissed or replaced.

### Wait

A paper veil over the main (not the header) while a long submit runs. After one second with no copy, the veil alone. With copy (`wait_copy` on the form), a 4.5rem paper strip under the header carries the sentence and a 2px caixa rule along the header’s bottom, snapped to 42% width — a hold, not a determinate bar.

### Stamp

Inline, ink on paper: "Mês fechado" on the month page and the desk pane, weight 600, title size, the double rule from Shapes. Class `.stamp-closed`. Compact `.stamp-closed-row` (“Fechado”) sits on the month index. Closed-month actions are only `Restaurar pasta` and `Reabrir`. `Casar pagamentos` is absent while the month is closed.

### Lote measure

While a wave of files is being read, the section heading’s underline becomes a row of 8px ticks (`lote-rule`): pale `rule` queued, paper with a caixa inset ring reading, caixa filled done, margem filled on error. One tick per document.

## Do's and Don'ts

### Do:

- **Do** set a missing-document row and an error notice with a 3px left border in `margem` and 12px of inset.
- **Do** fill a primary action with `caixa`, a sheet-white label, weight 600, and 8px by 16px padding.
- **Do** separate sections with a ruling line under the heading, and draw each money or document list as one flat ruled sheet with vertical rules between cells.
- **Do** keep payment rows denser than other lists, with Status and Documento as separate columns on the month payment sheet.
- **Do** give the header row and every data row of a sheet the same column template; size action tracks in rem, not auto.
- **Do** self-host IBM Plex Sans and IBM Plex Mono. The page makes no third-party font request.
- **Do** draw focus as a 2px solid `caixa` ring, offset 2px, on every control.
- **Do** keep Início as a two-pane desk for the coordinator; keep the 72rem column for every other close-work page.

### Don't:

- **Don't** introduce a second red, a drop shadow, a gradient, or a decorative icon set. Sort and row-action strokes, and “+” / “−” zoom, are the allowed exceptions; the mark stays the only brand emblem.
- **Don't** put a money record in a card. Column alignment is how the book is scanned.
- **Don't** set a heading in all caps, small caps, or a serif display.
- **Don't** tint the page warm cream. The paper is the cool ledger gray-green.
- **Don't** disable the close action to hide a reason. The reason is a `margem` sentence.
- **Don't** add CSS transitions or keyframes. Wait and toast appear because the person submitted; they do not ease in.
