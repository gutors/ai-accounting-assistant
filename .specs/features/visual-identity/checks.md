# Visual identity checks

Profile: ui
Plan: `.specs/features/visual-identity/plan.md`
Binding design source: `.specs/features/visual-identity/design.md`

54 checks in 5 slices · 4 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.
Checks on the served stylesheet are chained after `bin/rails tailwindcss:build`, because the
build output is gitignored and `bin/rspec` does not build it; C14 pins the same step in CI.
The "served stylesheet" is the `<link rel="stylesheet">` href of `GET /login`, fetched in the
same request spec, so Propshaft's URL rewriting is part of what is asserted.

## Checks

### S1 - Shell and tokens · door 1 · door 2

**C1** - The served stylesheet declares `--color-paper: #f3f5f1`, `--color-ink: #1b3229`, `--color-rule: #c7d5ca`, `--color-caixa: #2e6b4e`, and `--color-margem: #b4372a` (SHELL-01, AC 1, door 2)
Proof: `bin/rails tailwindcss:build && bin/rspec spec/requests/stylesheet_spec.rb -e "served stylesheet declares the five livro-caixa color tokens"`

**C2** - The served stylesheet declares `@font-face` for `IBM Plex Sans` at `font-weight` `400`, `500`, `600` and `IBM Plex Mono` at `400`, each with a `src` `url(` that starts with `/assets/` and ends in `.woff2` (SHELL-01, AC 2, door 1)
Proof: `bin/rails tailwindcss:build && bin/rspec spec/requests/stylesheet_spec.rb -e "served stylesheet declares four IBM Plex font faces served from /assets/"`

**C3** - Neither the served stylesheet nor the HTML of `GET /login` and coordinator `GET /` includes `fonts.googleapis.com` or `fonts.gstatic.com` (SHELL-01, AC 3, door 1)
Proof: `bin/rails tailwindcss:build && bin/rspec spec/requests/stylesheet_spec.rb -e "no Google Fonts host in the stylesheet or in login and home HTML"`

**C4** - The served stylesheet contains a `:focus-visible` rule whose `outline` declaration uses `var(--color-caixa)` (SHELL-01, AC 4)
Proof: `bin/rails tailwindcss:build && bin/rspec spec/requests/stylesheet_spec.rb -e "served stylesheet has a focus-visible outline in caixa"`

**C5** - The served stylesheet does not contain `@keyframes` (SHELL-01, AC 5)
Proof: `bin/rails tailwindcss:build && bin/rspec spec/requests/stylesheet_spec.rb -e "served stylesheet ships no keyframes"`

**C6** - Coordinator focused on `ONG Norte`, `GET /`: exactly one `<header>`, containing `ONG Norte`, `<a href="/">`, `<a href="/supporting_documents">`, `<a href="/setup">`, and a `Sair` submit button (SHELL-01, AC 6)
Proof: `bin/rspec spec/requests/layout_spec.rb -e "coordinator header names ONG Norte and links Inicio Documentos Configuracao and Sair"`

**C7** - Account with only submitter access, `GET /`: the `<header>` has no `href="/setup"` and the page does not include `Configuração` (SHELL-01, AC 7)
Proof: `bin/rspec spec/requests/layout_spec.rb -e "submitter header omits Configuracao and /setup"`

**C8** - `GET /login`: a `<header>` containing `Fechamento mensal` with no `<nav>` inside it, an `<h1>` whose text is `Fechamento mensal`, the sentence `Feche o mês da sua organização: extratos, documentos, casamentos e o pacote para o contador.`, and the `Entrar com Google` button (SHELL-01, AC 8)
Proof: `bin/rspec spec/requests/sessions_spec.rb -e "GET /login renders the header without nav, the h1, the sentence and Entrar com Google"`

**C9** - `GET /denied`: a `<header>` containing `Fechamento mensal` with no `<nav>` inside it, and `Você não foi convidado a usar este sistema.` (SHELL-01, AC 9)
Proof: `bin/rspec spec/requests/denied_spec.rb -e "GET /denied renders the header without nav and the denied sentence"`

**C10** - `@import_error`: `POST /months/2026-05/bank_statements` without files renders `422` whose `Envie o PDF e a planilha` is the text of a `<p role="alert" data-notice="error">` (SHELL-01, AC 10)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "import error renders as a data-notice error alert"`

**C11** - `@month_error`: `POST /months/2026-05/close` with a missing document renders `422` whose `Há documento faltante` is the text of a `<p role="alert" data-notice="error">` (SHELL-01, AC 10)
Proof: `bin/rspec spec/requests/close_spec.rb -e "month error renders as a data-notice error alert"`

**C12** - `@document_error`: `POST /supporting_documents` recibo without photo renders `422` whose `Envie a foto do recibo` is the text of a `<p role="alert" data-notice="error">` (SHELL-01, AC 10)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "document error renders as a data-notice error alert"`

**C13** - `@certificate_error`: `POST /sefaz_certificate` with an invalid file renders `422` whose `O certificado deve ser e-CNPJ A1 vigente` is the text of a `<p role="alert" data-notice="error">` (SHELL-01, AC 10)
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "certificate error renders as a data-notice error alert"`

**C14** - `.github/workflows/ci.yml` has a step running `bin/rails tailwindcss:build` before the step running `bin/rspec` (SHELL-01, AC 1 - startup assembly for C1–C5 and C41–C46)
Proof: `bin/rspec spec/config/ci_workflow_spec.rb -e "ci builds tailwind before rspec"`

**C15** - `public/icon.svg` does not contain `fill="red"` and contains a `<rect>` with `fill="#2e6b4e"` and a `<rect>` with `fill="#b4372a"` (SHELL-01, AC 11)
Proof: `bin/rspec spec/assets/icon_spec.rb -e "icon.svg is the ledger mark"`

**C16** - No file under `app/views/` matches `\b(zinc|gray|slate|neutral|stone)-` (SHELL-01, AC 12, door 2)
Proof: `bin/rspec spec/assets/views_palette_spec.rb -e "views use token utilities and no raw Tailwind palette"`

### S2 - Month ledger

**C17** - Coordinator `GET /months/2026-05`: the `<h1>` text includes `maio de 2026` and the body includes `2026-05` (LEDGER-01, AC 13)
Proof: `bin/rspec spec/requests/months_spec.rb -e "month title is maio de 2026 with 2026-05 under it"`

**C18** - With 2 missing-document payments the body includes `2 pagamentos com documento faltante` (LEDGER-01, AC 14)
Proof: `bin/rspec spec/requests/months_spec.rb -e "summary says 2 pagamentos com documento faltante"`

**C19** - With exactly 1 missing-document payment the body includes `1 pagamento com documento faltante` (LEDGER-01, AC 14)
Proof: `bin/rspec spec/requests/months_spec.rb -e "summary says 1 pagamento com documento faltante"`

**C20** - With 0 missing-document payments the body includes `Nenhum documento faltante` and does not include `Documento faltante` (LEDGER-01, AC 15)
Proof: `bin/rspec spec/requests/months_spec.rb -e "summary says Nenhum documento faltante and no row says Documento faltante"`

**C21** - With 1 active account lacking a statement the body includes `Falta o extrato de 1 conta ativa` (LEDGER-01, AC 16)
Proof: `bin/rspec spec/requests/months_spec.rb -e "summary says Falta o extrato de 1 conta ativa"`

**C22** - With 2 active accounts lacking statements the body includes `Falta o extrato de 2 contas ativas` (LEDGER-01, AC 16)
Proof: `bin/rspec spec/requests/months_spec.rb -e "summary says Falta o extrato de 2 contas ativas"`

**C23** - With every active account holding a statement (and one inactive account without) the body does not include `Falta o extrato` (LEDGER-01, AC 16)
Proof: `bin/rspec spec/requests/months_spec.rb -e "summary omits Falta o extrato when every active account has a statement"`

**C24** - A missing-document payment renders as `li[data-row="payment"][data-payment-id="{id}"][data-status="missing"]` (LEDGER-01, AC 17)
Proof: `bin/rspec spec/requests/months_spec.rb -e "payment row data-status is missing"`

**C25** - A matched payment renders with `data-status="matched"` (LEDGER-01, AC 17)
Proof: `bin/rspec spec/requests/months_spec.rb -e "payment row data-status is matched"`

**C26** - A `bank_fee` payment renders with `data-status="bank_fee"` (LEDGER-01, AC 17)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "payment row data-status is bank_fee"`

**C27** - An `accountant_fee` payment renders with `data-status="accountant_fee"` (LEDGER-01, AC 17)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "payment row data-status is accountant_fee"`

**C28** - A payment marked with extra exception kind `Doação` renders with `data-status="extra"` (LEDGER-01, AC 17)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "payment row data-status is extra"`

**C29** - The month page renders an inflow as `li[data-row="inflow"]`, a pool document as `li[data-row="pool-document"][data-document-id="{id}"]`, and an active bank account as `li[data-row="bank-account"][data-bank-account-id="{id}"]` (LEDGER-01, AC 18)
Proof: `bin/rspec spec/requests/months_spec.rb -e "inflow pool-document and bank-account rows carry data-row hooks"`

**C30** - In a `missing` row, every `<form>` is a descendant of one `<details>` whose `<summary>` text is `Resolver`, and `Documento faltante` occurs in the row before that `<details>` (LEDGER-01, AC 19)
Proof: `bin/rspec spec/requests/months_spec.rb -e "missing row folds its forms under Resolver after the status"`

**C31** - A `missing` row with a suggestion has its `<details>` with the `open` attribute (LEDGER-01, AC 20)
Proof: `bin/rspec spec/requests/months_spec.rb -e "Resolver is open when a suggestion exists"`

**C32** - A `missing` row with an exception suggestion has its `<details>` with the `open` attribute (LEDGER-01, AC 20)
Proof: `bin/rspec spec/requests/months_spec.rb -e "Resolver is open when an exception suggestion exists"`

**C33** - A `missing` row with neither suggestion has its `<details>` without the `open` attribute (LEDGER-01, AC 20)
Proof: `bin/rspec spec/requests/months_spec.rb -e "Resolver is closed when no suggestion exists"`

**C34** - Closed `2026-05`: `Mês fechado` is the text of an element with `data-stamp="closed"` and the body contains no `<details` (LEDGER-01, AC 21)
Proof: `bin/rspec spec/requests/close_spec.rb -e "closed month shows the stamp and no details"`

**C35** - Open month, active account with a statement: its upload form is inside a `<details>` whose `<summary>` is `Substituir extrato` (LEDGER-01, AC 22)
Proof: `bin/rspec spec/requests/months_spec.rb -e "present statement folds the upload form under Substituir extrato"`

**C36** - Open month, active account without a statement: its upload form has no `<details>` ancestor (LEDGER-01, AC 22)
Proof: `bin/rspec spec/requests/months_spec.rb -e "absent statement shows the upload form inline"`

**C37** - With 2 missing payments and 1 unmatched document, the form whose submit is `Confirmar casamento N:1` is inside a `<details>` whose `<summary>` is `Casar vários pagamentos com um documento` (LEDGER-01, AC 23)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "N:1 form folds under Casar varios pagamentos com um documento"`

### S3 - Home and setup

**C38** - Coordinator `GET /`: `<h1>` text is `Meses`; an open month renders as `li[data-row="month"]` containing `<a href="/months/2026-05">` and the text `Aberto` (HOME-01, AC 26)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "home h1 is Meses and an open month row says Aberto"`

**C39** - A closed month renders as `li[data-row="month"]` containing its link and the text `Fechado` (HOME-01, AC 26)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "closed month row says Fechado"`

**C40** - Coordinator on `ONG Norte` and `ONG Sul`, focused on `ONG Norte`: the switcher button for `ONG Norte` has `aria-current="true"` and the one for `ONG Sul` has no `aria-current` (HOME-01, AC 27)
Proof: `bin/rspec spec/requests/focus_spec.rb -e "focused organization button carries aria-current"`

**C41** - Submitter `GET /`: `<h1>` text is `Início`, the body includes `Inclua e acompanhe seus documentos de suporte em` with `<a href="/supporting_documents">`, and does not include `Meses` (HOME-01, AC 28)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "submitter home says Inicio and points to Documentos"`

**C42** - Coordinator `GET /setup`: `<h1>` text is `Configuração`; a bank account renders as `li[data-row="bank-account"][data-bank-account-id="{id}"]` whose `PATCH /bank_accounts/{id}` form is inside a `<details>` with `<summary>` `Editar` (HOME-01, AC 29)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup h1 is Configuracao and bank account edit folds under Editar"`

**C43** - `GET /setup`: an extra exception kind renders as `li[data-row="extra-exception-kind"][data-extra-exception-kind-id="{id}"]` (HOME-01, AC 29)
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "extra exception kind row carries data-row hook"`

### S4 - Supporting documents

**C44** - `GET /supporting_documents`: `<h1>` text is `Documentos de suporte`; the first `<section>` contains the form posting to `/supporting_documents` with submit `Incluir documento`; a document renders as `li[data-row="document"][data-document-id="{id}"]` whose `PATCH /supporting_documents/{id}` form is inside a `<details>` with `<summary>` `Editar` (DOCS-01, AC 31)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "documents h1 insert form first and edit folds under Editar"`

**C45** - A deletable document's `Excluir` button is inside that same `<details>` (DOCS-01, AC 31)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "Excluir sits inside Editar"`

**C46** - A justification renders as `li[data-row="justification"][data-justification-id="{id}"]` (DOCS-01, AC 31)
Proof: `bin/rspec spec/requests/justifications_spec.rb -e "justification row carries data-row hook"`

**C47** - A document with `sefaz_confirm_pending?` renders its `Usar dados da SEFAZ` button with no `<details>` ancestor (DOCS-01, AC 32)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "Usar dados da SEFAZ stays outside Editar"`

**C48** - A document with chave `35240612345678000190550010000012341000012340` renders an element with `data-chave` whose text is `3524 0612 3456 7800 0190 5500 1000 0012 3410 0001 2340`, and its `input[name="chave"]` has value `35240612345678000190550010000012341000012340` (DOCS-01, AC 33)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "chave is displayed in groups of four and kept raw in the edit field"`

### S5 - Screen proofs · door 3 · door 4

**C49** - `spec/system/screens_spec.rb` writes `tmp/screenshots/{login,denied,home,setup,month-open,month-closed,documents}-{390,1280}.png`, all 14 files present after the run, exit `0` (PROOF-01, AC 35, door 4)
Proof: `bin/rails tailwindcss:build && bin/rspec spec/system/screens_spec.rb -e "saves one screenshot per screen and viewport"`

**C50** - At 1280px, every `li[data-row] [data-cell="amount"]` on `month` and `documents` has computed `font-variant-numeric` containing `tabular-nums` and `text-align` `right` (LEDGER-01, AC 24)
Proof: `bin/rails tailwindcss:build && bin/rspec spec/system/screens_spec.rb -e "amount cells are tabular and right-aligned on month and documents"`

**C51** - At 390px, `document.documentElement.scrollWidth <= 390` on `month` (open, one `missing` row with `Resolver` open) (LEDGER-01, AC 25)
Proof: `bin/rails tailwindcss:build && bin/rspec spec/system/screens_spec.rb -e "month has no horizontal scroll at 390"`

**C52** - At 390px, `document.documentElement.scrollWidth <= 390` on `home` and on `setup` (HOME-01, AC 30)
Proof: `bin/rails tailwindcss:build && bin/rspec spec/system/screens_spec.rb -e "home and setup have no horizontal scroll at 390"`

**C53** - At 390px, `document.documentElement.scrollWidth <= 390` on `documents` with one `Editar` open (DOCS-01, AC 34)
Proof: `bin/rails tailwindcss:build && bin/rspec spec/system/screens_spec.rb -e "documents has no horizontal scroll at 390"`

**C54** - No file under `spec/` contains `class="mb-2"`, `class="mb-6"`, or `class="border rounded p-3 mb-3"` (PROOF-01, AC 36, door 3)
Proof: `! rg -n 'class="mb-2"|class="mb-6"|class="border rounded p-3 mb-3"' spec/`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| color tokens (5) | C1, table-driven over all 5 | - |
| font faces (4) | C2, table-driven over all 4 | - |
| Google Fonts hosts (2) | `fonts.googleapis.com` C3 · `fonts.gstatic.com` C3 | - |
| header variants (4) | coordinator C6 · submitter C7 · login C8 · denied C9 | - |
| error notice ivars (4) | `@import_error` C10 · `@month_error` C11 · `@document_error` C12 · `@certificate_error` C13 | - |
| startup assembly: Tailwind build (2) | local proof chain C1 · CI workflow C14 | - |
| missing-document summary (3) | 0 C20 · 1 C19 · 2 C18 | - |
| statement summary (3) | 0 C23 · 1 C21 · 2 C22 | - |
| payment `data-status` (5) | `missing` C24 · `matched` C25 · `bank_fee` C26 · `accountant_fee` C27 · `extra` C28 | - |
| `data-row` names (9) | `payment` C24 · `inflow` C29 · `pool-document` C29 · `bank-account` C29, C42 · `month` C38 · `extra-exception-kind` C43 · `document` C44 · `justification` C46 · header has none (not a row) C6 | - |
| `Resolver` open state (3) | suggestion C31 · exception suggestion C32 · neither C33 | - |
| statement upload fold (2) | present C35 · absent C36 | - |
| `<details>` summaries (5) | `Resolver` C30 · `Substituir extrato` C35 · `Casar vários pagamentos com um documento` C37 · `Editar` on bank account C42 · `Editar` on document C44 | - |
| month state on home (2) | `Aberto` C38 · `Fechado` C39 | - |
| closed-month page (2) | stamp present C34 · no `<details>` C34 | - |
| home h1 by access (2) | coordinator `Meses` C38 · submitter `Início` C41 | - |
| actions outside the fold (1) | `Usar dados da SEFAZ` C47 | - |
| screens at 390 (4) | `month` C51 · `home` C52 · `setup` C52 · `documents` C53 | - |
| tabular amount screens (2) | `month` C50 · `documents` C50 | - |
| screenshot files (14) | C49, table-driven over all 14 | - |
| Landing doors (4) | fonts C2 · tokens C1, C16 · test anchors C54 · screen proofs C49 | - |

- Claims naming a status code or response shape: C10, C11, C12, C13 - each has a proof that crosses the HTTP boundary
- C1–C5 assert on the stylesheet as served (after Propshaft), fetched from the `<link>` of `GET /login`
- C50–C53 assert computed style and layout, which no request spec can reach; they run in the browser via door 4
- No other check claims more than the single case its proof exercises

## Test policy

`.cursor/rules/rails.mdc` already answers which level proves which code and how much of the input space counts. This build runs under those rows; they are not proposed as a new guideline commit.

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Decides, reached across a boundary | one at the boundary **and** one at its own layer | the contract at the boundary; one asserted case per row of the decision table at its own layer |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member |
| Entry point that decides nothing | one at the boundary | accepted input, each rejected input, each error path |
| Instrumentation, pass-throughs | none of its own | covered by its consumer's proof |

Evidence (classified from the approved plan):

- `app/views/months/show.html.erb`: `data-status` dispatch over 5 members, `Resolver` open over 3 states, statement fold over 2, summary sentences over 3 × 3 counts -> decides; a view's own layer in this repo is the request spec (no view-spec layer exists), so one request example per member (C18–C37)
- `app/views/layouts/_header.html.erb`: 4 variants (coordinator, submitter, login, denied) -> decides; C6–C9
- `app/views/organizations/show.html.erb`: h1 by access (2), month state (2), `aria-current` (2) -> decides; C38–C41
- `app/views/setup/show.html.erb`, `app/views/supporting_documents/index.html.erb`: fold placement, `data-row` hooks, chave grouping -> decides; C42–C48
- `app/assets/tailwind/application.css`, `public/icon.svg`, `config/locales/pt-BR.yml`: static configuration -> proven where it is served (C1–C5, C15, C17)
- `spec/system/screens_spec.rb`: browser-level facts (computed style, scroll width, screenshots) -> the only layer that can assert them (C49–C53)
- closest analogue in the repo: `spec/requests/months_spec.rb` already proves month-page copy per state (`Mês fechado`, `Documento faltante`, `Sugestão`) at the request level, one example per member

Cost: 37 request examples across 12 spec files, 5 system examples, 4 static-file examples. Without the per-member request examples the `data-status` and `Resolver` tables would be proven only by whichever path a screenshot happened to traverse.

## Swept

- validation: n/a - no input, parameter, or validation changes; existing validations stay proven by the existing request specs
- failure modes: C10, C11, C12, C13 - every existing error message is rendered as a `role="alert"` notice
- idempotency: n/a - the feature adds no write
- authorization: C7, C41 - submitter chrome hides `Configuração` and the close ritual; `require_account` and focus guards untouched (existing)
- concurrency: n/a - no write, no shared state
- data lifecycle: n/a - no stored data; `tmp/screenshots/` is overwritten each run (C49)
- dependency failure: C3 - no third-party font host at runtime; a missing Chrome fails C49 loudly rather than silently skipping
- state transitions: C34, C38, C39 (open/closed on month and home); C31, C32, C33 (`Resolver` open/closed)
- observability: n/a - no logging or metrics criterion in the plan

## Handoff

- Files touched (6 views, layout + header partial, `application.css`, locale, `Gemfile`, `ci.yml`, icon, `match_helpers.rb`, 13 request specs, 4 new spec files) total ~296 KB by `wc -c` -> ~74k tokens ≪ 150k. One builder, no split.
- Order: S1 (tokens, fonts, header, notices) -> S2 (month) -> S5 test anchors and system spec scaffold (so re-anchored helpers exist before S3/S4 rows change) -> S3 -> S4 -> S5 screenshots last.
- **Boundary:** C1-C54 closed at `0d0606d` (feature base `fc0d56b`, branch `visual-identity`); screenshots for C49-C53 under `tmp/screenshots/` after `bin/rspec spec/system/screens_spec.rb`
