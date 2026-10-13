---
name: Fechamento mensal
description: A well-kept ledger for closing an NGO's month.
colors:
  caixa: "#2e6b4e"
  margem: "#b4372a"
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
  button-org-current:
    backgroundColor: "{colors.caixa}"
    textColor: "{colors.sheet}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    padding: "4px 12px"
  button-org:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
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
  notice:
    textColor: "{colors.margem}"
    typography: "{typography.body}"
    padding: "0 0 0 12px"
---

# Design System: Fechamento mensal

## Overview

**Creative North Star: "Livro-caixa"**

The interface is a well-kept Brazilian cash book. The page is cool ledger paper. Every list of money is a ruled row: date, history, amount, status, with figures in tabular numbers and the amount on the right. The only loud device is the red margin. It marks a payment that still lacks a document, and an error. A month page with no red is ready to close.

Density follows the coordinator's laptop ritual. One left-aligned column, sections separated by a rule, status always visible, and the form that changes a row folded into a disclosure the person opens. The submitter's phone uses the same tokens, stacked. Nothing is a card. Nothing floats.

The closed month is an ink stamp, the only double-ruled mark in the system. The app mark repeats the same three strokes — a green field, two paper rules, one red margin — and carries no wordmark. When no organization is focused, the header reads the product name in the same medium weight as an organization name.

**Key Characteristics:**

- **Ruled rows.** Record lists are a ledger sheet: vertical and horizontal rules, not cards.
- **One red margin.** Red appears only on a missing document or an error.
- **Flat paper.** Depth is a hairline rule, not a shadow.
- **The stamp.** A closed month is inked and double-ruled. Nothing else is boxed.
- **One type family.** IBM Plex Sans for the book; IBM Plex Mono only for the access key.

## Colors

Tokens live as theme colors. Views use the token, never a raw palette step. Contrast floors the identity commits to: ink on paper above 12:1; caixa on sheet, margem on sheet, and white on caixa each at least 6:1.

### Primary

**Ledger green** (`caixa`) fills the primary button, colors links and disclosure summaries, draws the focus ring, and fills the focused organization. It is the working green of the book, not a highlight sprinkled on decoration.

### Signal

**Margin red** (`margem`) is the red rule of the cash book. It is the left edge of a payment with a missing document, the color of an error notice, the color of a destructive text action, and the color of a missing-document count. It is not a second brand color.

**The One Red Rule.** `margem` marks a payment with a missing document and an error. A month page with no red is ready to close.

### Neutral

**Ledger paper** (`paper`) is the page and the header. It is a cool gray-green, the color of ruled paper, not warm cream.

**Sheet white** (`sheet`) is the field inside a control and the panel behind an open disclosure. Inputs sit on a sheet; the page stays paper.

**Forest ink** (`ink`) is text, the secondary button's border, and the stamp. **Soft ink** (`ink-soft`) is the second line: filenames, account coordinates, the month-folder name, an inactive account, "Aberto" and "Fechado".

**Ruling green** (`rule`) is the 1px line under a section heading, between rows, and around a field or an open disclosure.

## Typography

One family, self-hosted, Latin subset, `font-display: swap`. IBM Plex Sans at 400 for sentences, 500 for the primary text of a row and for field labels, 600 for headings, the stamp, and primary buttons. The fallback stack is IBM Plex Sans, then the UI sans. IBM Plex Mono at 400 is the only other face.

- **Display** (600, tight leading, slight negative tracking): the month in words (`maio de 2026`). Below 768px it steps down to 1.75rem at the same leading and tracking; the token itself is the larger size.
- **Headline** (600, slight negative tracking): page titles.
- **Title** (600): a section heading, sitting on a ruling underline.
- **Body** (400): sentences and secondary buttons. Prose stays within a 72-character measure.
- **Label** (500): the history, payee, or account name on a row, and the visible label of a field.
- **Button** (600, body size): primary actions and the stamp. Secondary buttons stay at body weight.
- **Meta** (400, soft ink): filenames, coordinates, the month-folder slug, document kind.
- **Amount** (500, tabular figures): right-aligned. Dates on a row use the same tabular figures at body weight.
- **Chave** (mono 400, meta size): the 44-digit access key, shown as eleven groups of four. The edit field keeps the raw digits.

**The Sentence Case Rule.** Labels, buttons, and headings stay in sentence case. No all-caps, no eyebrow, no letterspaced small caps.

**The Chave Rule.** IBM Plex Mono appears only on the access key.

## Layout

The content column is 72rem, left-aligned, inside the viewport. The page gutter is the narrow step on a phone and the wide step from 768px. Below the header (minimum height 3.5rem) the title sits one page-step down; sections stack one section-step apart; the column ends with the page-end step.

From 768px every record list is a ruled sheet: 1px vertical `rule` between cells, 1px horizontal `rule` between rows, snug cell padding (6px by 10px; payment rows 3px vertical). Head and body rows of one sheet share one column template. A payment row is five tracks: 9.5rem for the date (`time`, nowrap, tabular), a flexible history, 8rem for the amount, 12rem for status, 11rem for actions. A month Contas bancárias row is six tracks: Banco, Nome, Agência/conta, Situação (6.5rem), Documentos (filenames in meta, truncated inside the cell), then the statement action (11rem). A home Convites pendentes row is five tracks: E-mail, Tipo (8.5rem), Status, Reenviar e-mail (10.5rem), Cancelar (6rem). The header row uses soft-ink labels (the Pagamentos Data label is ink and semibold as the visual sort key) and a 1px ink underline. Below 768px the header hides, cells stack, and vertical rules drop. Other lists (months, people, setup banks, documents, administration) share this sheet grammar with their own tracks. Rows have no fill. Short forms cap at 28rem; two-column forms and the people list begin at 768px. Navigation wraps under the organization name below 640px.

The month page leads with the month in words, the folder name in meta under it, and one summary sentence: missing documents first (in margin red when any remain), missing statements second. There is no horizontal scroll at 390px.

**The Ledger Column Rule.** Every record list is a ruled sheet with aligned columns, vertical rules, and tabular figures. The amount is right-aligned. Status and each action occupy their own columns.

**The Shared Track Rule.** Head and body of a sheet use the same column template. Action tracks are fixed rem, never `auto` or `max-content`: the header cell is empty, and a content-sized track would let the row drift off the rule.

## Elevation & Depth

The system is flat. There is no shadow vocabulary and no gradient. A row, a section, and a field are separated by the ruling line. The red margin is the only edge that means "this blocks the close." An open disclosure is a white sheet with a ruling border, not a raised card.

Focus is a 2px solid ledger-green ring, offset 2px, on every control. It is the same ring everywhere.

Motion is limited to what the person triggered. Opening a native disclosure is the only state change. No transition and no keyframe ships, so a reduced-motion setting has nothing to remove. Primary buttons do not recolor on hover; links and quiet actions gain an underline.

**The Flat Ledger Rule.** Surfaces stay flat. Depth is the ruling line and the red margin.

## Shapes

Controls, fields, disclosures, and the organization switcher share a 4px corner. The page, the header, and the rows are square. The stamp is the exception: a 2px corner, a 2px ink border, and a second 1px ink outline set 3px outside, so it reads as a double rule.

The red margin is a 3px left border with 12px of inset, on the row and on the error notice. Section headings take a 1px ruling underline. The app mark is a green square whose corner, at header size, matches the 4px control radius; inside it, two paper rules and one red vertical rule. No other icon is used.

**The Stamp Rule.** The only boxed mark is the closed-month stamp. Its double rule is the whole treatment.

**The Four Pixel Rule.** Controls, fields, and disclosure panels share one small corner. The page itself stays square.

## Components

### Buttons

- **Shape:** 4px corner. Primary and secondary share 8px vertical and 16px horizontal padding.
- **Primary:** ledger-green fill, sheet-white label, weight 600. This is "Fechar para envio", "Entrar com Google", "Incluir documento", and every other commit action. No hover recolor. Focus uses the global ring.
- **Secondary:** transparent fill, 1px ink border, ink label at body weight. "Reabrir", "Restaurar pasta", "Convidar", and the exception actions ("Marcar tarifa", "Marcar honorário").
- **Quiet:** no border and no fill. An underline sits 2px under the words. Destructive words (revoke, delete, undo a match, deactivate) are margin red. Other quiet words, including "Sair" and inline links, are ledger green.

### Chips

The organization switcher is a row of small buttons. The focused organization is a primary fill with tighter padding (4px by 12px) and `aria-current`. The others are secondary buttons at that same tighter padding.

### Cards / Containers

There are no cards. The open disclosure is the only panel: sheet-white ground, 1px ruling border, 4px corner, 16px padding, sitting 12px under its summary. The summary is ledger green at label weight. It is open on a payment row only when a suggestion is waiting.

### Inputs / Fields

Sheet ground, 1px ruling border, 4px corner, 8px by 12px padding, full width of the form. Labels stay visible above the field at label weight. Focus uses the global ring. An error is not a red field border; it is the notice under the page title.

**File field.** The native picker is covered, not shown. The control is a sheet field: ruling border, 4px corner, empty copy “Nenhum arquivo” in meta soft ink. A chosen filename replaces that copy at label weight. The action chip on the right uses the primary fill (“Incluir foto”, “Incluir XML”, “Incluir arquivo”, “Incluir PDF”, “Incluir planilha”). It is not a second form commit. **Limpar** sits beside the chip as a quiet underlined action and zeros that control without a submit. Disabled is 50% opacity and ignores pointer events.

### Navigation

A paper bar with a 1px ruling line along its bottom. Left: the mark at 1.25rem and the focused organization in label weight, or the product name when nothing is focused. Right: text links in ink that underline on hover, then "Sair" as a quiet ledger-green action. Below 640px the links wrap under the name. Login and the denied page have no navigation.

### Ledger row

A list item in a CSS grid sheet (`.ledger-sheet` / `.ledger-row`), not a table and not a card. Direct children are cells. Head and body share the sheet’s column template. Money lists run date, primary text with a soft-ink meta line under it, amount, status, then actions (Desfazer casamento, Resolver, Desmarcar exceção) in their own column — not stacked inside status. A missing document adds the red margin (3px left border, 12px inset on the first cell) and the status words in margin red. Bank, invite, and extras lists split situação and each quiet action into their own columns. Inflows have no status or actions cell. One sheet per section; do not group rows into status bands.

### Notice

An alert paragraph: margin-red text, 3px margin-red left border, 12px inset. It sits directly under the page title.

### Stamp

Inline, ink on paper: "Mês fechado", weight 600, the double rule from Shapes. It replaces the primary close action on a closed month and sits beside the two secondary actions.

## Do's and Don'ts

### Do:

- **Do** set a missing-document row and an error notice with a 3px left border in `margem` and 12px of inset.
- **Do** fill a primary action with `caixa`, a sheet-white label, weight 600, and 8px by 16px padding.
- **Do** separate sections with a ruling line under the heading, and draw each record list as one flat ruled sheet with vertical rules between cells.
- **Do** keep payment rows denser than other lists, with Status and Ações as separate columns.
- **Do** give the header row and every data row of a sheet the same column template; size action tracks in rem, not auto.
- **Do** self-host IBM Plex Sans and IBM Plex Mono. The page makes no third-party font request.
- **Do** draw focus as a 2px solid `caixa` ring, offset 2px, on every control.

### Don't:

- **Don't** introduce a second red, a shadow, a gradient, or an icon besides the app mark.
- **Don't** put a record in a card. Column alignment is how the book is scanned.
- **Don't** set a heading in all caps, small caps, or a serif display.
- **Don't** tint the page warm cream. The paper is the cool ledger gray-green.
- **Don't** disable the close action to hide a reason. The reason is a `margem` sentence.
- **Don't** add motion the person did not trigger. Opening a disclosure is the only state change.
