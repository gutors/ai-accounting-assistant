# Visual identity

Sources:

- conversation (2026-09-19) - "improve the design and style for this project"; all interface is ERB; no behaviour change requested
- [`design.md`](design.md) - **binding for the interface**: screens `login`, `denied`, `home`, `setup`, `month`, `documents`; tokens, components, per-screen arrangement and the copy this feature adds. Existing copy stays in the ERB under `app/views/` verbatim
- `CONTEXT.md` - vocabulary the new copy uses (documento faltante, extrato, casamento, pasta do mês)
- `.cursor/rules/rails.mdc` - Tailwind, Hotwire, semantic HTML, visible labels, pt-BR copy, no React
- [ADR-0001](../../../docs/adr/0001-rails-8-hotwire.md) - server-rendered HTML; Propshaft serves assets

Profile raised from `standard` to `ui` for this feature: the plan names six screens and a binding
design source (`AGENTS.md`, tlc-spec-lean).

## Problem

Every screen is unstyled Tailwind defaults: zinc buttons, underlined text links, one `container`
with no header, lists where a payment's date, amount, account, history, status, suggestion, and
four forms run together on one line. A coordinator scanning thirty payments cannot tell from
the page how many still lack a document or which account still lacks a statement; the only
signal is the `422` after pressing `Fechar para envio`. A submitter on a phone gets a desktop
form with a fixed `max-w-md`. The product has no mark (`public/icon.svg` is a red circle) and no
typographic identity. The source gives no usage figures; the cost is scan time on the month page
and a first impression that reads as a scaffold.

When this ships, the same six screens keep their routes, forms, field names, and copy, and gain
one visual system: a header with the organization and the navigation, ledger rows with aligned
columns and tabular figures, a red margin that marks only what blocks the close, a stamp for a
closed month, and a summary sentence on the month page that says what is still missing. Forms
that change a row fold into a `<details>` that opens when there is a suggestion to confirm.

## Out of scope

| Excluded | Why |
| --- | --- |
| Any route, controller, model, or validation change | style pass; behaviour is proven by the existing specs and stays untouched |
| Rewording existing copy asserted by specs | the request specs pin it; `design.md` lists only additions |
| Dark mode | no request; one palette is the identity |
| Stimulus controllers for the fold/unfold | `<details>` is native and keyboard-accessible; `rails.mdc` reserves Stimulus for events and browser APIs |
| Disabling `Fechar para envio` while a document is missing | the server answers with the reason; design.md `Rejected` |
| Flash/success messages | none exist today; adding them is a behaviour change |
| Pagination or filtering of payments | not requested; the month is one ledger |
| Icons beyond the app mark | design.md principle 5 |
| Package spreadsheet styling | the xlsx is #22, not the web UI |

## Assumptions

| Assumption | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Typeface | IBM Plex Sans 400/500/600 + IBM Plex Mono 400, self-hosted woff2 (OFL) | forms-and-documents heritage matches DANFE and statement material; tabular figures; no third-party request (LGPD) | n |
| Palette | livro-caixa: paper `#f3f5f1`, ink `#1b3229`, rule `#c7d5ca`, caixa `#2e6b4e`, margem `#b4372a` | subject-derived (ledger paper: green ruling, red margin); avoids the cream/serif/terracotta default | n |
| Per-row forms fold into `<details>` | `Resolver` on a missing payment, `Editar` on documents and bank accounts, `Substituir extrato` when a statement exists; `open` when a suggestion exists | keeps the ledger scannable while the one-click confirm of a suggestion stays visible | n |
| Month title in words | `maio de 2026` via `pt-BR.date.month_names` added to `config/locales/pt-BR.yml`; `2026-05` kept under it | human title plus the month-folder name; no gem added | n |
| Where the missing-document count comes from | `@missing_document_payments.size` and `@active_bank_accounts` minus `@statements_by_account_id` keys, already loaded by `MonthsController#show` | no new query; `rails.mdc` keeps queries out of views | n |
| Home page title | coordinator: `Meses`; submitter: `Início` with one sentence linking `/supporting_documents` | the header already names the organization; the page names its job | n |
| Existing request specs that scrape markup by utility class | re-anchor the helpers on `data-row` / `data-notice`; assertions unchanged | class strings are what this feature changes; the proofs must not depend on them | n |
| Screen proofs at `ui` profile | Capybara + Cuprite system spec saving one PNG per screen and viewport under `tmp/screenshots/` | Chrome is present locally and on `ubuntu-latest`; Cuprite drives it over CDP with no driver download | n |
| `public/icon.png` | regenerated from the new `icon.svg` with `rsvg-convert` or `qlmanage`; if neither is on the machine the SVG ships and the PNG is left as is | `public/icon.svg` is what modern browsers pick; the PNG is the fallback | n |

**Open questions:**

| # | Kind | Question | Until answered |
| --- | --- | --- | --- |
| 1 | open | Screen proofs: Cuprite (recommended - Chrome over CDP, no chromedriver download, two gems in `:test`) or selenium-webdriver (Rails default, fetches chromedriver on first run - network-dependent in the sandbox)? | Landing door 4 stays as written (Cuprite); AC 31 is proven either way |

## Criteria

Numbering runs across the whole plan. Copy in backticks is literal.

### S1: Shell and tokens (P1)

**Acceptance Criteria**

1. The compiled stylesheet (`app/assets/builds/tailwind.css`) SHALL declare `--color-paper: #f3f5f1`, `--color-ink: #1b3229`, `--color-rule: #c7d5ca`, `--color-caixa: #2e6b4e`, and `--color-margem: #b4372a`
2. The compiled stylesheet SHALL declare `@font-face` for `IBM Plex Sans` at weights `400`, `500`, `600` and for `IBM Plex Mono` at weight `400`, each `src` a same-origin `/assets/` URL ending in `.woff2`
3. The compiled stylesheet and every rendered page SHALL not include `fonts.googleapis.com` or `fonts.gstatic.com`
4. The compiled stylesheet SHALL contain a `:focus-visible` rule whose `outline` uses `var(--color-caixa)`
5. The compiled stylesheet SHALL not contain `@keyframes`
6. WHEN a coordinator focused on `ONG Norte` GETs `/` THEN the page SHALL include one `<header>` containing `ONG Norte`, links `href="/"`, `href="/supporting_documents"`, `href="/setup"`, and a `Sair` button
7. WHILE the signed-in account holds only submitter access on the focused organization, the `<header>` SHALL not include `href="/setup"` and SHALL not include `Configuração`
8. WHEN GET `/login` THEN the page SHALL include a `<header>` containing `Fechamento mensal` and no `<nav>`, an `<h1>` `Fechamento mensal`, the sentence `Feche o mês da sua organização: extratos, documentos, casamentos e o pacote para o contador.`, and the `Entrar com Google` button
9. WHEN GET `/denied` THEN the page SHALL include a `<header>` containing `Fechamento mensal` and no `<nav>`, and `Você não foi convidado a usar este sistema.`
10. IF a controller renders an error message (`@import_error`, `@month_error`, `@document_error`, `@certificate_error`) THEN that message SHALL be the text of a `<p role="alert" data-notice="error">`
11. The file `public/icon.svg` SHALL not contain `fill="red"` and SHALL contain a `<rect>` with `fill="#2e6b4e"` and a `<rect>` with `fill="#b4372a"`
12. The views under `app/views/` SHALL not contain the raw palette utilities `zinc-`, `gray-`, `slate-`, `neutral-`, `stone-`

**Independent test:** build the CSS; open `/login` and `/denied` unauthenticated; sign in as coordinator and as submitter and read the header; grep the built CSS and the views.

### S2: Month ledger (P1)

**Acceptance Criteria**

13. WHEN a coordinator GETs `/months/2026-05` THEN the `<h1>` SHALL include `maio de 2026` and the page SHALL include `2026-05`
14. WHEN 2 payments of that month are missing documents THEN the page SHALL include `2 pagamentos com documento faltante`; WHEN exactly 1 THEN `1 pagamento com documento faltante`
15. WHEN no payment of that month is missing a document THEN the page SHALL include `Nenhum documento faltante` and SHALL not include `Documento faltante`
16. WHEN 1 active bank account has no statement for that month THEN the page SHALL include `Falta o extrato de 1 conta ativa`; WHEN 2 THEN `Falta o extrato de 2 contas ativas`; WHEN every active account has one THEN the page SHALL not include `Falta o extrato`
17. The month page SHALL render each payment as `<li data-row="payment" data-payment-id="{id}" data-status="{s}">` with `{s}` exactly one of `missing`, `matched`, `bank_fee`, `accountant_fee`, `extra`, matching `missing_document?`, `match_id`, `bank_fee?`, `accountant_fee?`, `extra_exception_kind_id` in that order
18. The month page SHALL render each inflow as `<li data-row="inflow">`, each unmatched document in the pool as `<li data-row="pool-document" data-document-id="{id}">`, and each active bank account as `<li data-row="bank-account" data-bank-account-id="{id}">`
19. WHILE a payment is `missing`, its match form and every exception form SHALL be descendants of one `<details>` whose `<summary>` text is `Resolver`, and the text `Documento faltante` SHALL precede that `<details>` inside the row
20. WHILE a `missing` payment has a suggestion or an exception suggestion, that `<details>` SHALL carry the `open` attribute; WHILE it has neither, it SHALL not
21. WHILE the month is closed, the page SHALL include `Mês fechado` as the text of an element with `data-stamp="closed"` and SHALL include no `<details>`
22. WHILE an active bank account has a statement and the month is open, its upload form SHALL be inside a `<details>` whose `<summary>` is `Substituir extrato`; WHILE it has none, the upload form SHALL not be inside any `<details>`
23. WHEN the N:1 form renders (2 or more missing payments and 1 or more unmatched documents, month open) THEN it SHALL be inside a `<details>` whose `<summary>` is `Casar vários pagamentos com um documento`
24. The amount cell of every ledger row (`li[data-row]` on `month` and `documents`) SHALL have computed `font-variant-numeric` including `tabular-nums` and computed `text-align: right` at 1280px viewport
25. WHEN the page is rendered at 390px viewport THEN `document.documentElement.scrollWidth` SHALL be `<= 390` on `month` (open, with one `missing` payment whose `<details>` is open)

**Independent test:** plant `2026-05` with two accounts (one statement), one inflow, three payments (missing with suggestion, matched, tarifa), one pool document; read the title, the two summary sentences, each row's `data-status`, the `open` state; close it and see the stamp with no `<details>`.

### S3: Home and setup (P2)

**Acceptance Criteria**

26. WHEN a coordinator GETs `/` THEN the `<h1>` SHALL be `Meses`, and each month SHALL render as `<li data-row="month">` containing a link `href="/months/{year_month}"` and the text `Aberto` when open or `Fechado` when closed
27. WHEN a coordinator with access on `ONG Norte` and `ONG Sul` is focused on `ONG Norte` THEN the switcher button for `ONG Norte` SHALL carry `aria-current="true"` and the one for `ONG Sul` SHALL not
28. WHILE the signed-in account holds only submitter access, GET `/` SHALL include `<h1>` `Início` and the sentence `Inclua e acompanhe seus documentos de suporte em` with a link `href="/supporting_documents"`, and SHALL not include `Meses`
29. WHEN a coordinator GETs `/setup` THEN the `<h1>` SHALL be `Configuração`, each bank account SHALL render as `<li data-row="bank-account" data-bank-account-id="{id}">` whose edit form is inside a `<details>` with `<summary>` `Editar`, and each extra exception kind as `<li data-row="extra-exception-kind" data-extra-exception-kind-id="{id}">`
30. WHEN the page is rendered at 390px viewport THEN `document.documentElement.scrollWidth` SHALL be `<= 390` on `home` and `setup`

**Independent test:** sign in with two organizations; read `/` and `/setup`; switch focus; sign in as submitter and read `/`.

### S4: Supporting documents (P2)

**Acceptance Criteria**

31. WHEN GET `/supporting_documents` THEN the `<h1>` SHALL be `Documentos de suporte`, the first `<section>` SHALL contain the `Incluir documento` form, each document SHALL render as `<li data-row="document" data-document-id="{id}">` whose edit form and `Excluir` button (when rendered) are inside a `<details>` with `<summary>` `Editar`, and each justification as `<li data-row="justification" data-justification-id="{id}">`
32. WHILE a document has `sefaz_confirm_pending?`, its `Usar dados da SEFAZ` button SHALL not be inside any `<details>`
33. WHEN a document has chave `35240612345678000190550010000012341000012340` THEN the row SHALL include an element with `data-chave` whose text is `3524 0612 3456 7800 0190 5500 1000 0012 3410 0001 2340`, and the edit field `name="chave"` SHALL have value `35240612345678000190550010000012341000012340`
34. WHEN the page is rendered at 390px viewport THEN `document.documentElement.scrollWidth` SHALL be `<= 390` on `documents` (with one document whose `<details>` is open)

**Independent test:** as submitter on a 390px viewport, insert a recibo, open `Editar`, save; as coordinator see the same list with `Casado em`.

### S5: Screen proofs (P1)

**Acceptance Criteria**

35. WHEN `bin/rspec spec/system/screens_spec.rb` runs THEN it SHALL write `tmp/screenshots/{login,denied,home,setup,month-open,month-closed,documents}-{390,1280}.png` (14 files) and exit `0`
36. The existing request specs SHALL locate rows and notices through `data-row`, `data-notice`, `data-status`, or `data-stamp`, and `spec/` SHALL not contain the strings `class="mb-2"`, `class="mb-6"`, or `class="border rounded p-3 mb-3"`

**Independent test:** run the whole suite; open the 14 PNGs next to `design.md`.

## Traceability

| ID | Slice | Criteria | Status |
| --- | --- | --- | --- |
| SHELL-01 | S1 | 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 | Pending |
| LEDGER-01 | S2 | 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 | Pending |
| HOME-01 | S3 | 26, 27, 28, 29, 30 | Pending |
| DOCS-01 | S4 | 31, 32, 33, 34 | Pending |
| PROOF-01 | S5 | 35, 36 | Pending |

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `login` | empty state | n/a - one button, no data |
| screen `login` | loading | n/a - full-page navigation to Google |
| screen `login` | error state | existing - `/auth/failure` redirects to `/login`; no message today and none added |
| screen `login` | unauthorised | n/a - the screen is the unauthenticated entry |
| screen `login` | density and ordering | AC 8 |
| screen `login` | destructive action confirms | n/a - nothing destructive |
| screen `denied` | empty / loading | n/a - static sentence |
| screen `denied` | error state | AC 9 - the screen is the error |
| screen `denied` | unauthorised | existing - reached only after a callback with no access |
| screen `denied` | density and ordering | AC 9 |
| screen `denied` | destructive action confirms | n/a - nothing destructive |
| screen `home` | empty state | existing - `Nenhum mês aberto`; AC 26 keeps it before the `Abrir mês` form |
| screen `home` | loading | n/a - Turbo full-page request |
| screen `home` | error state | existing - invite and revoke errors render on the same page today; AC 10 styles them |
| screen `home` | unauthorised | existing - `require_account` redirects to `/login`; AC 7, AC 28 for the submitter view |
| screen `home` | density and ordering | AC 26, AC 27, AC 28; two people columns from 768px (design.md) |
| screen `home` | destructive action confirms | existing - `Revogar` keeps its `data-turbo-confirm` |
| screen `setup` | empty state | existing - `Cadastre o contador`, `Nenhum certificado`, `Nenhuma conta bancária`, `Nenhum tipo extra` |
| screen `setup` | loading | n/a - Turbo full-page request |
| screen `setup` | error state | AC 10 - `@certificate_error` as `data-notice="error"` |
| screen `setup` | unauthorised | existing - coordinator only; submitter has no link (AC 7) |
| screen `setup` | density and ordering | AC 29 |
| screen `setup` | destructive action confirms | existing - `Remover` keeps its `data-turbo-confirm`; `Excluir` of an unused kind stays immediate |
| screen `month` | empty state | existing - `Nenhuma conta bancária ativa`, `Nenhum documento sem casamento`; AC 15, AC 16 for the summary when nothing is missing |
| screen `month` | loading | n/a - close-for-send waits on the same POST, as today |
| screen `month` | error state | AC 10 - `@import_error`, `@month_error` |
| screen `month` | unauthorised | existing - coordinator with focus; `404` on another organization's month |
| screen `month` | density and ordering | AC 13, AC 14, AC 16, AC 17, AC 18, AC 19, AC 20, AC 22, AC 23, AC 24, AC 25 |
| screen `month` | destructive action confirms | existing - `Fechar para envio`, `Reabrir`, `Restaurar pasta` keep their `data-turbo-confirm` |
| screen `month` | closed state | AC 21 |
| screen `documents` | empty state | existing - `Nenhum documento`, `Nenhuma justificativa` |
| screen `documents` | loading | n/a - Turbo full-page request; SEFAZ consulta is the same POST as today |
| screen `documents` | error state | AC 10 - `@document_error` |
| screen `documents` | unauthorised | existing - submitter sees only own documents; coordinator flag unchanged |
| screen `documents` | density and ordering | AC 31, AC 32, AC 33, AC 34 |
| screen `documents` | destructive action confirms | existing - `Excluir` keeps its `data-turbo-confirm`; AC 31 places it inside `Editar` |
| document `design.md` | structure | tokens, principles, components, one block per screen |
| document `design.md` | tone | n/a - technical artifact in English; product copy inside it is pt-BR |
| document `design.md` | depth | copy additions and arrangement per screen; no pixel spec beyond the type scale |
| document `design.md` | what the reader does next | the Verifier compares it against the 14 screenshots (AC 35) |
| collection `tmp/screenshots/` | grouping | AC 35 - one file per screen and viewport |
| collection `tmp/screenshots/` | naming | AC 35 - `{screen}-{width}.png` |
| collection `tmp/screenshots/` | ordering | n/a - files, not a list |
| collection `tmp/screenshots/` | duplicates | n/a - each run overwrites the same names |
| collection `tmp/screenshots/` | exception that does not fit | n/a - every screen has both widths |

## Flow

This reuses every controller, instance variable, form, field name, `format_reais`, `l(date)`,
and every existing error message as they are; nothing new is queried. It adds a layout partial,
the tokens and fonts in the Tailwind entry file, month names in the locale, and `data-*` hooks.

1. request -> controller (exists) - loads the same instance variables as today
2. `app/views/layouts/application.html.erb` (exists) - renders `layouts/_header` (new, no door - placement per conventions) from `current_account` / `focused_organization` (exist), then `yield`
3. screen ERB (exists) - ledger rows with `data-row` / `data-status` hooks, `<details>` folds, token utilities; error messages through `shared/_notice` (new, no door - one `data-notice` paragraph rendered by the four screens); the statement upload form is `months/_statement_form` (new, no door - rendered inline or inside `Substituir extrato`)
4. `app/assets/tailwind/application.css` (exists) - `@theme` tokens (door 2) and `@font-face` (door 1) pointing at `app/assets/fonts/*.woff2` (new); `bin/rails tailwindcss:build` writes `app/assets/builds/tailwind.css` (exists), Propshaft (exists) rewrites the `url()` to the digested `/assets/` path when it serves the file
5. `config/locales/pt-BR.yml` (exists) - `date.month_names` and `date.formats.month_title` for the month title; `ApplicationHelper` (exists) gains `month_title`, `payment_status` (the `data-status` dispatch) and `format_chave` (groups of four)
6. `spec/support/page_helpers.rb` (new, door 3) - `row` / `rows_html` / `error_notice_text` locators over `data-*`; `match_helpers.rb` (exists) delegates to them; `spec/system/screens_spec.rb` (new, door 4) - signs in through the OmniAuth mock (exists) and saves screenshots
7. out: the same HTML routes, the same statuses, restyled

## Relations

None - no stored-data shape change

## Surface

None - nothing consumed outside; every route, parameter, and status is unchanged

## Landing

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| 1. Fonts | `app/assets/fonts/IBMPlexSans-{Regular,Medium,SemiBold}.woff2`, `IBMPlexMono-Regular.woff2` (OFL, Latin subset) with `@font-face { font-family: "IBM Plex Sans"; font-display: swap; src: url(...) }` in `app/assets/tailwind/application.css`; `--font-sans: "IBM Plex Sans", ui-sans-serif, system-ui, sans-serif` | Google Fonts `<link>` - a third-party request on every page view (LGPD exposure, offline dev breaks); system stack - no tabular figures guarantee and no identity |
| 2. Tokens | `@theme { --color-paper; --color-sheet; --color-ink; --color-ink-soft; --color-rule; --color-caixa; --color-margem; --font-sans; --font-mono }` in `app/assets/tailwind/application.css`; views use only `paper/sheet/ink/ink-soft/rule/caixa/margem` utilities | raw palette in views (`zinc-900`) - a palette change touches every view; `@apply` component classes - a style read in two places (CSS and ERB), and Tailwind v4 discourages it |
| 3. Test anchors | request specs and `spec/support` helpers locate markup through `li[data-row="<name>"]`, `[data-notice="error"]`, `[data-status]`, `[data-stamp]` via Nokogiri, never through a class string | class-string scraping (`<li class="mb-2">`) - couples proofs to the styling this feature changes; `id` per row - ids already carry form associations and would collide |
| 4. Screen proofs | `gem "capybara"` and `gem "cuprite"` in `group :test`; `spec/system/screens_spec.rb` with `driven_by :cuprite`, `window_size` 390×844 and 1280×900, `page.save_screenshot("tmp/screenshots/<screen>-<width>.png")`; sign-in through `OmniAuth.config.mock_auth` (exists) | selenium-webdriver - downloads chromedriver on first run (network-dependent in the sandbox); static HTML dumps from request specs - asset URLs do not resolve from `file://` |

- Nothing else in this change is hard to reverse: partial names, grid column widths, `<details>` placement, and the icon geometry are settled in the diff.

## Impact

| Front | What changes |
| --- | --- |
| domain | no new term; the UI adopts `Aberto` / `Fechado` for a month's state on `home` and reuses `documento faltante`, `extrato`, `conta ativa` from `CONTEXT.md` in the summary sentences |
| domain | existing term: `Documento faltante` still means the payment status; the month summary says `pagamentos com documento faltante` (lowercase) so `Documento faltante` appears only on rows - specs that assert its absence keep their meaning |
| stored data | nothing to migrate |
| locale | `config/locales/pt-BR.yml` gains `date.month_names` (13 entries, index 0 nil) and `date.formats.month_title` (`%B de %Y`) |
| tests | `spec/support/match_helpers.rb` and the four request specs that scan `<li class=...>` / `<p class="mb-6">` re-anchor on `data-*` (door 3); assertions unchanged. Three `supporting_documents_spec.rb` examples also matched raw adjacency (`</time>\s*R$ 155,00\s*Recibo\s*Padaria Central`) - no wrapped amount cell can satisfy that, so they now locate the `document` row and assert the same date, amount, kind and payee inside it. `Gemfile` test group gains `capybara` and `cuprite` (door 4); `spec/system/`, `spec/assets/` and `spec/config/ci_workflow_spec.rb` are created |
| assets | `public/icon.svg` and `public/icon.png` replaced by the ledger mark; `app/assets/fonts/` created with four woff2 files (fontsource 5.3.0 Latin subset, about 86 KB total) and the two OFL texts |
| CI | `bin/rspec` now runs one system spec; `ubuntu-latest` ships Chrome. `.github/workflows/ci.yml` gains a `bin/rails tailwindcss:build` step before `bin/rspec`: the build output is gitignored and nothing in CI produces it today (`stylesheet_link_tag :app` globs, so the missing file was silent) |
