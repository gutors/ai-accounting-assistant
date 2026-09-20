# Visual identity verification

**Verdict**: FAIL
**Profile**: ui
**Diff range**: `fc0d56b..4a554d1` (C1–C54 closed at `0d0606d`; `4a554d1` is docs-only: STATE.md, plan.md, checks.md)
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

Every check runs green at `HEAD` with a located assertion (54/54), every fault aimed at a
proven surface was killed (4/4), and every screen matches `design.md` in copy and arrangement.
The verdict is FAIL on three **omissions in the checks** that the recomputed Coverage join and
the per-screen enumeration surface — the code satisfies the design on all three, but nothing
proves it, and one of them was confirmed by a mutant that survived every proof:

1. `@theme` tokens: `design.md` declares 7 colours and Landing door 2 declares 9 variables;
   C1 proves 5. `--color-sheet`, `--color-ink-soft`, `--font-sans`, `--font-mono` have no
   proof — removing `--color-ink-soft` deletes the `text-ink-soft` utility from the built CSS
   and every proof stays green (fault F5).
2. `home` (coordinator): `Pessoas` is new copy the design names; no check covers it
   (`app/views/organizations/show.html.erb:43`).
3. `documents`: the justification row's `Editar` `<details>` is drawn by the design; no check
   covers it (`app/views/supporting_documents/index.html.erb:151-152`). The
   `<details>` summaries set is 6, not 5.

## Binding sources

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| `design.md` § Tokens / Type / Layout / Mark | yes - read in full; compared against `application.css`, `_header.html.erb`, `icon.svg` | none | `--color-sheet`, `--color-ink-soft`, `--font-sans`, `--font-mono` (design Tokens table + Landing door 2) have no check; see Coverage |
| `design.md` § `login` | yes - `tmp/screenshots/login-{390,1280}.png` + `sessions/new.html.erb` | none | - |
| `design.md` § `denied` | yes - `tmp/screenshots/denied-{390,1280}.png` + `sessions/denied.html.erb` | none | - |
| `design.md` § `home` (coordinator) | yes - `tmp/screenshots/home-{390,1280}.png` + `organizations/show.html.erb` | none | `Pessoas` `<h2>` (design "New copy") — `app/views/organizations/show.html.erb:43` rendered, no check |
| `design.md` § `home` (submitter) | yes - `organizations/show.html.erb:110-111`; no screenshot (spec shoots `documents` as submitter) | none | - |
| `design.md` § `setup` | yes - `tmp/screenshots/setup-{390,1280}.png` + `setup/show.html.erb` | none | - |
| `design.md` § `month` (open) | yes - `tmp/screenshots/month-open-{390,1280}.png` + `months/show.html.erb` | none | - |
| `design.md` § `month` (closed) | yes - `tmp/screenshots/month-closed-{390,1280}.png` | none | - |
| `design.md` § `documents` | yes - `tmp/screenshots/documents-{390,1280}.png` + `supporting_documents/index.html.erb` | none | justification `Editar` `<details>` (`index.html.erb:151-152`) rendered per design, no check |
| `CONTEXT.md`, `.cursor/rules/rails.mdc`, ADR-0001 | listed in plan Sources, not marked binding | - | - |

### Per-screen enumeration (copy and arrangement)

Each line: what `design.md` decides that a selector reaches -> the check that covers it, or the gap.
Arrangement not asserted by a selector is covered by C49 (14 PNGs) plus this comparison, as the
plan's Observable row for `design.md` says ("the Verifier compares it against the 14 screenshots").

**Header (all screens)** - `_header.html.erb`
- one `<header>`, mark + focused organization name, nav `Início` `/`, `Documentos` `/supporting_documents`, `Configuração` `/setup` coordinator-only, `Sair` submit -> C6, C7
- no organization focused: `Fechamento mensal`, no `<nav>` -> C8, C9
- nav wraps under the name below 640px -> seen in `home-390.png`, `month-open-390.png` (`flex-wrap`, `sm:ml-auto` at `_header.html.erb:2,13`); no selector check, C49 comparison
- 1px `rule` under the header -> colour/border, exempt (below)

**`login`** - `sessions/new.html.erb`
- `<h1>` `Fechamento mensal`, one sentence, `Entrar com Google` button, left-aligned `max-w-md` -> C8; arrangement seen in `login-1280.png`
- `mt-24` -> spacing, exempt (implementation `mt-14` inside `main mt-10`)

**`denied`** - `sessions/denied.html.erb`
- same shell, `Você não foi convidado a usar este sistema.` -> C9; `<h1>` also rendered (design: "same shell as login"), not contradicted

**`home` coordinator** - `organizations/show.html.erb`
- switcher `<nav aria-label="Organizações">`, focused `aria-current="true"`, other none -> C40; focused filled `bg-caixa`, others secondary -> colour, exempt
- `<h1>` `Meses` -> C38
- month ledger `li[data-row="month"]`: `year_month` linked, then `Aberto` / `Fechado` -> C38, C39; `Nenhum mês aberto` -> existing
- `Mês` field + `Abrir mês` after the list -> existing copy; order seen in `home-1280.png`
- **`Pessoas` `<h2>` -> no check (gap)**; rendered at `organizations/show.html.erb:43`
- two columns `Coordenadores` | `Submitters` from 768px, invite forms under their lists with `<legend>` `Convidar coordenador` / `Convidar submitter`, submit `Convidar` -> existing copy; arrangement `md:grid-cols-2` at `:44`, `<legend>` at `:57,79`; seen in `home-1280.png` (two columns) and `home-390.png` (one)
- `Convites pendentes` `<h2>` full width, `Cancelar` quiet -> existing; seen

**`home` submitter**
- `<h1>` `Início`, sentence with link to `/supporting_documents`, no `Meses` -> C41; header without `Configuração` -> C7

**`setup`** - `setup/show.html.erb`
- `<h1>` `Configuração` -> C42; `@certificate_error` notice under the title -> C13
- `<h2>` `Contador`, `Arquivo do pacote`, `Certificado SEFAZ`, `Contas bancárias`, `Tipos extras de exceção` -> existing copy; order seen in `setup-1280.png`
- bank-account `li[data-row="bank-account"]`: name, slug + coordinates meta, `Inativa`, quiet actions, then `<details><summary>Editar</summary>` with the edit form -> C42
- extra kind `li[data-row="extra-exception-kind"]` -> C43
- accountant / bank-account forms two columns from 768px -> arrangement, `md:grid-cols-2` at `:15,109,132`; seen in `setup-1280.png` (two) vs `setup-390.png` (one)
- no horizontal scroll at 390 -> C52

**`month`** - `months/show.html.erb`
- `<h1>` month in words in display size, `2026-05` meta under it -> C17; right side: `Fechar para envio` when open / stamp `[data-stamp="closed"]` `Mês fechado` + `Restaurar pasta`, `Reabrir` when closed -> C34 + existing copy; seen in both `month-*-1280.png`
- summary line: missing documents first, statements second, three forms each -> C18–C23; missing sentence in `margem` when N > 0 -> colour, exempt
- `@import_error`, `@month_error` notices -> C10, C11
- `Contas bancárias` rows: name + coordinates | `Presente` + two filenames / `Falta` | inline form when absent, `Substituir extrato` fold when present, no form when closed -> C35, C36, C34 (no `<details>`); `Falta` in `margem` -> colour, exempt
- `Recebimentos` `li[data-row="inflow"]`: date | history + account | amount, no status cell -> C29 (row), C50 (amount cell); arrangement `grid-cols-[5.5rem_minmax(0,1fr)_8rem_12rem]` at `:91`
- `Pagamentos` `li[data-row="payment"][data-payment-id][data-status]`, five statuses -> C24–C28; red margin on `missing` -> colour/border, exempt (class at `:108`)
- status cell words `Documento faltante` / `Casado` + payees + observation / `Tarifa bancária` / `Honorário do contador` / extra kind name, `Sugestão` / `Sugestão de exceção`, quiet undo actions -> `Documento faltante` C30, C20; the rest existing copy proven by pre-existing specs
- `Resolver` `<details>` holds match form + exception buttons, `Documento faltante` precedes it, `open` iff suggestion or exception suggestion -> C30, C31, C32, C33
- N:1 form after the list inside `Casar vários pagamentos com um documento` -> C37
- pool `li[data-row="pool-document"]`: checkbox + payee label | amount | `Devolver` -> C29, C50; `Devolver` existing
- ledger grid stacks below 768 (date + amount first line, history second, status third) -> seen in `month-open-390.png`; C51 (no horizontal scroll with `Resolver` open)
- Note on placement: the design's sketch draws `▾ Resolver` under the status column; the code places the `<details>` as a grid item spanning columns 2–4 on row 2 (`:152`), so the summary sits under the history column. `design.md` § Layout also says the action panel is "full width of the row", and plan Landing states "`<details>` placement ... settled in the diff". Not a contradiction.

**`documents`** - `supporting_documents/index.html.erb`
- `<h1>` `Documentos de suporte`, `@document_error` notice -> C44, C12
- `Incluir documento` form is the first `<section>` -> C44; two columns from 768 (`md:grid-cols-2` at `:12`) -> arrangement; seen in `documents-1280.png` vs `documents-390.png`
- `Sem mês` rows `li[data-row="document"]`: date | payee + kind, chave grouped mono `[data-chave]`, filenames, observation, `Casado em` (coordinator) | amount -> C44, C48, C50; `Casado em` existing
- `Usar dados da SEFAZ` outside `Editar` -> C47; `Editar` `<details>` with edit form then `Excluir` -> C44, C45; raw chave in the edit field -> C48
- `Justificativas` rows `li[data-row="justification"]` -> C46; **`▸ Editar` (submitter, when allowed) `<details>` at `:151-152` -> no check (gap)**
- justification form (submitter only) -> existing
- no horizontal scroll at 390 with one `Editar` open -> C53

### Out of a selector's reach (enumerated, not a blanket clause)

`checks.md` carries no exemption clause at all. The following is what a `ui` profile leaves
to the eye, named per screen so nothing selector-reachable hides under it:

- all screens: header 3.5rem, `mt-10` to title, `space-y-12`, `pb-16`, `px-5`/`px-8`; type scale (display 2.25rem/1.75rem, h1 1.5rem, h2 1.125rem, meta 0.8125rem); weights 400/500/600; `rule` colour of separators; focus ring is proven only as a CSS rule (C4), not per control
- `home`: switcher fill colours; `Aberto`/`Fechado` in `ink-soft`
- `month`: red margin colour/width on `missing` rows; `margem` on the missing sentence and on `Falta`; stamp double rule geometry
- `documents`: chave mono face; meta colours
- `setup`: nothing beyond the shared list

## Checks

Proofs run at `4a554d1` in one invocation: `bin/rails tailwindcss:build && bin/rspec --format documentation` -
974 examples, 0 failures; each of the 53 named examples appears once in the documentation output
as passed (confirmed by exact-string grep against the run's output), and all 53 are `+ it "…"`
lines in `git diff fc0d56b..HEAD -- spec` (none resolves to a pre-existing test). C54 ran as written.

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | served CSS declares the five colour tokens | `stylesheet_spec.rb -e "served stylesheet declares the five livro-caixa color tokens"` passed | `spec/requests/stylesheet_spec.rb:18-25` - table of 5 `{token => hex}`, `expect(css).to match(/--color-#{token}:\s*#{hex}\b/i)`; served via `<link>` of `/login` `:4-12` | PASS |
| C2 | four `@font-face`, `src` `/assets/…woff2` | `-e "served stylesheet declares four IBM Plex font faces served from /assets/"` passed | `spec/requests/stylesheet_spec.rb:33-40` - 4 `[family, weight]` pairs; `expect(src).to start_with("/assets/")`, `.to end_with(".woff2")` | PASS |
| C3 | no Google Fonts host in CSS, `/login`, coordinator `/` | `-e "no Google Fonts host in the stylesheet or in login and home HTML"` passed | `spec/requests/stylesheet_spec.rb:46-58` - `not_to include("fonts.googleapis.com")` / `("fonts.gstatic.com")` on css, `/login`, `/` | PASS |
| C4 | `:focus-visible` outline uses `var(--color-caixa)` | `-e "served stylesheet has a focus-visible outline in caixa"` passed | `spec/requests/stylesheet_spec.rb:63-66` - `rule = css[/:focus-visible\s*\{[^}]*\}/m]`, `expect(rule).to match(/outline:[^;}]*var\(--color-caixa\)/)` | PASS |
| C5 | no `@keyframes` | `-e "served stylesheet ships no keyframes"` passed | `spec/requests/stylesheet_spec.rb:70` - `expect(served_stylesheet).not_to include("@keyframes")` | PASS |
| C6 | coordinator header: one `<header>`, `ONG Norte`, three links, `Sair` | `layout_spec.rb -e "coordinator header names ONG Norte …"` passed | `spec/requests/layout_spec.rb:12-19` - `expect(headers.size).to eq(1)`, `header.text include("ONG Norte")`, `at_css('a[href="/"]')`, `'a[href="/supporting_documents"]'`, `'a[href="/setup"]'` not nil, `Sair` submit not nil | PASS |
| C7 | submitter header: no `/setup`, no `Configuração` | `-e "submitter header omits Configuracao and /setup"` passed | `spec/requests/layout_spec.rb:31-32` - `expect(header.at_css('a[href="/setup"]')).to be_nil`, `body not_to include("Configuração")` | PASS |
| C8 | `/login`: header without nav, h1, sentence, button | `sessions_spec.rb -e "GET /login renders the header without nav, the h1, the sentence and Entrar com Google"` passed | `spec/requests/sessions_spec.rb:25-29` - `header.text include("Fechamento mensal")`, `header.at_css("nav") be_nil`, `h1 text eq("Fechamento mensal")`, sentence `include(…)`, submit texts `include("Entrar com Google")` | PASS |
| C9 | `/denied`: header without nav, sentence | `denied_spec.rb -e "GET /denied renders the header without nav and the denied sentence"` passed | `spec/requests/denied_spec.rb:17-19` - `header.text include("Fechamento mensal")`, `header.at_css("nav") be_nil`, `include("Você não foi convidado a usar este sistema.")` | PASS |
| C10 | `@import_error` -> 422 `data-notice` alert | `bank_statements_spec.rb -e "import error renders as a data-notice error alert"` passed | `spec/requests/bank_statements_spec.rb:84-85` - `have_http_status(:unprocessable_content)`, `error_notice_text(body) eq("Envie o PDF e a planilha")`; locator `spec/support/page_helpers.rb:7-13` = `p[role="alert"][data-notice="error"]` | PASS |
| C11 | `@month_error` -> 422 alert | `close_spec.rb -e "month error renders as a data-notice error alert"` passed | `spec/requests/close_spec.rb:61-62` - `:unprocessable_content`, `error_notice_text eq("Há documento faltante")` | PASS |
| C12 | `@document_error` -> 422 alert | `supporting_documents_spec.rb -e "document error renders as a data-notice error alert"` passed | `spec/requests/supporting_documents_spec.rb:202-203` - `:unprocessable_content`, `error_notice_text eq("Envie a foto do recibo")` | PASS |
| C13 | `@certificate_error` -> 422 alert | `sefaz_certificates_spec.rb -e "certificate error renders as a data-notice error alert"` passed | `spec/requests/sefaz_certificates_spec.rb:87-88` - `:unprocessable_content`, `error_notice_text eq("O certificado deve ser e-CNPJ A1 vigente")` | PASS |
| C14 | CI builds Tailwind before `bin/rspec` | `ci_workflow_spec.rb -e "ci builds tailwind before rspec"` passed | `spec/config/ci_workflow_spec.rb:9-14` - `build_index`/`rspec_index` over `steps[].run`, `expect(build_index).to be < rspec_index`; `.github/workflows/ci.yml:73,76` | PASS |
| C15 | `icon.svg` no `fill="red"`, rects `#2e6b4e` and `#b4372a` | `icon_spec.rb -e "icon.svg is the ledger mark"` passed | `spec/assets/icon_spec.rb:8-9` - `not_to include('fill="red"')`, `rects.map { fill } include("#2e6b4e", "#b4372a")` | PASS |
| C16 | no raw palette under `app/views/` | `views_palette_spec.rb -e "views use token utilities and no raw Tailwind palette"` passed | `spec/assets/views_palette_spec.rb:6,10` - `/\b(zinc\|gray\|slate\|neutral\|stone)-/` over `app/views/**/*`, `expect(offenders).to be_empty` | PASS |
| C17 | h1 includes `maio de 2026`, body `2026-05` | `months_spec.rb -e "month title is maio de 2026 with 2026-05 under it"` passed | `spec/requests/months_spec.rb:1318-1319` - `at_css("h1").text include("maio de 2026")`, `body include("2026-05")` | PASS |
| C18 | 2 missing -> `2 pagamentos com documento faltante` | `-e "summary says 2 pagamentos com documento faltante"` passed | `spec/requests/months_spec.rb:1329` - `include("2 pagamentos com documento faltante")` after two `plant_payment` `:1324-1325` | PASS |
| C19 | 1 missing -> `1 pagamento com documento faltante` | `-e "summary says 1 pagamento com documento faltante"` passed | `spec/requests/months_spec.rb:1338` | PASS |
| C20 | 0 missing -> `Nenhum documento faltante`, no `Documento faltante` | `-e "summary says Nenhum documento faltante and no row says Documento faltante"` passed | `spec/requests/months_spec.rb:1347-1348` - `include("Nenhum documento faltante")`, `not_to include("Documento faltante")` | PASS |
| C21 | 1 active account without statement | `-e "summary says Falta o extrato de 1 conta ativa"` passed | `spec/requests/months_spec.rb:1357` | PASS |
| C22 | 2 active accounts without statement | `-e "summary says Falta o extrato de 2 contas ativas"` passed | `spec/requests/months_spec.rb:1367` | PASS |
| C23 | all active have statements (one inactive without) -> no `Falta o extrato` | `-e "summary omits Falta o extrato when every active account has a statement"` passed | `spec/requests/months_spec.rb:1372-1373,1377` - inactive account planted, `not_to include("Falta o extrato")` | PASS |
| C24 | `data-status="missing"` row | `-e "payment row data-status is missing"` passed | `spec/requests/months_spec.rb:1386` - `row(body, "payment", payment_id:, status: "missing") not_to be_nil`; locator `page_helpers.rb:19-22` = `li[data-row="payment"][data-payment-id="…"][data-status="…"]` | PASS |
| C25 | `data-status="matched"` | `-e "payment row data-status is matched"` passed | `spec/requests/months_spec.rb:1397` | PASS |
| C26 | `data-status="bank_fee"` | `document_exceptions_spec.rb -e "payment row data-status is bank_fee"` passed | `spec/requests/document_exceptions_spec.rb:347` | PASS |
| C27 | `data-status="accountant_fee"` | `-e "payment row data-status is accountant_fee"` passed | `spec/requests/document_exceptions_spec.rb:357` | PASS |
| C28 | `data-status="extra"` (`Doação`) | `-e "payment row data-status is extra"` passed | `spec/requests/document_exceptions_spec.rb:362-364,368` | PASS |
| C29 | `inflow`, `pool-document`, `bank-account` rows | `months_spec.rb -e "inflow pool-document and bank-account rows carry data-row hooks"` passed | `spec/requests/months_spec.rb:1408-1410` - `rows(body,"inflow").size eq(1)`, `row(…,"pool-document", document_id:)`, `row(…,"bank-account", bank_account_id:)` not nil | PASS |
| C30 | `missing` row: all forms under one `Resolver` `<details>`, `Documento faltante` first | `-e "missing row folds its forms under Resolver after the status"` passed | `spec/requests/months_spec.rb:1422-1425` - `forms not_to be_empty`, `forms.all? { ancestors.include?(details) } eq(true)`, `html.index("Documento faltante") < html.index("<details")`; `resolver_details` `:1306-1310` asserts exactly one `<details>` whose `<summary>` is `Resolver` | PASS |
| C31 | suggestion -> `open` | `-e "Resolver is open when a suggestion exists"` passed | `spec/requests/months_spec.rb:1436` - `details.has_attribute?("open") eq(true)` | PASS |
| C32 | exception suggestion -> `open` | `-e "Resolver is open when an exception suggestion exists"` passed | `spec/requests/months_spec.rb:1447` | PASS |
| C33 | neither -> not `open` | `-e "Resolver is closed when no suggestion exists"` passed | `spec/requests/months_spec.rb:1457` - `has_attribute?("open") eq(false)` | PASS |
| C34 | closed: `Mês fechado` stamp, no `<details` | `close_spec.rb -e "closed month shows the stamp and no details"` passed | `spec/requests/close_spec.rb:49-52` - `at_css('[data-stamp="closed"]') not nil`, `stamp.text eq("Mês fechado")`, `body not_to include("<details")` | PASS |
| C35 | statement present -> form under `Substituir extrato` | `months_spec.rb -e "present statement folds the upload form under Substituir extrato"` passed | `spec/requests/months_spec.rb:1467-1471` - form `action == "/months/2026-05/bank_statements"` found, `details = form.ancestors("details").first not nil`, `summary text eq("Substituir extrato")` | PASS |
| C36 | statement absent -> form inline | `-e "absent statement shows the upload form inline"` passed | `spec/requests/months_spec.rb:1481-1483` - form found, `form.ancestors("details") be_empty` | PASS |
| C37 | N:1 form under `Casar vários pagamentos com um documento` | `matches_spec.rb -e "N:1 form folds under Casar varios pagamentos com um documento"` passed | `spec/requests/matches_spec.rb:605-611` - form with submit `Confirmar casamento N:1`, `ancestors("details").first not nil`, `summary text eq("Casar vários pagamentos com um documento")` | PASS |
| C38 | home h1 `Meses`, open month row with link and `Aberto` | `organizations_spec.rb -e "home h1 is Meses and an open month row says Aberto"` passed | `spec/requests/organizations_spec.rb:161-166` - `h1 text eq("Meses")`, `rows(body,"month").size eq(1)`, `a[href="/months/2026-05"]` not nil, `text include("Aberto")`, `not_to include("Fechado")` | PASS |
| C39 | closed month row `Fechado` | `-e "closed month row says Fechado"` passed | `spec/requests/organizations_spec.rb:178-180` | PASS |
| C40 | focused switcher button `aria-current="true"`, other none | `focus_spec.rb -e "focused organization button carries aria-current"` passed | `spec/requests/focus_spec.rb:27-31` - buttons under `nav[aria-label="Organizações"]`, `norte["aria-current"] eq("true")`, `sul.has_attribute?("aria-current") eq(false)` | PASS |
| C41 | submitter home: h1 `Início`, sentence + link, no `Meses` | `organizations_spec.rb -e "submitter home says Inicio and points to Documentos"` passed | `spec/requests/organizations_spec.rb:189-192` - `h1 eq("Início")`, `include("Inclua e acompanhe seus documentos de suporte em")`, `main a[href="/supporting_documents"]` not nil, `not_to include("Meses")` | PASS |
| C42 | setup h1 `Configuração`; bank-account row, PATCH form under `Editar` | `setup_spec.rb -e "setup h1 is Configuracao and bank account edit folds under Editar"` passed | `spec/requests/setup_spec.rb:352-359` - `h1 eq("Configuração")`, `row(…,"bank-account", bank_account_id:)`, form `action == "/bank_accounts/#{id}"` with `_method=patch`, `ancestors("details").first not nil`, `summary eq("Editar")` | PASS |
| C43 | extra-exception-kind row | `extra_exception_kinds_spec.rb -e "extra exception kind row carries data-row hook"` passed | `spec/requests/extra_exception_kinds_spec.rb:265-267` - `row(…,"extra-exception-kind", extra_exception_kind_id:) not nil`, text `include("Doação")` | PASS |
| C44 | documents h1; insert form in first `<section>` with `Incluir documento`; document row; PATCH form under `Editar` | `supporting_documents_spec.rb -e "documents h1 insert form first and edit folds under Editar"` passed | `spec/requests/supporting_documents_spec.rb:139-149` - `h1 eq("Documentos de suporte")`, `first_section = page.css("section").first`, insert form `action=="/supporting_documents"`, submit `Incluir documento`, edit form `_method=patch`, `ancestors.include?(editar_details(row)) eq(true)`; `editar_details` `:125-129` asserts exactly one `<details>` with summary `Editar` | PASS |
| C45 | `Excluir` inside `Editar` | `-e "Excluir sits inside Editar"` passed | `spec/requests/supporting_documents_spec.rb:159-161` | PASS |
| C46 | justification row | `justifications_spec.rb -e "justification row carries data-row hook"` passed | `spec/requests/justifications_spec.rb:234-236` - `row(…,"justification", justification_id:) not nil` | PASS |
| C47 | `Usar dados da SEFAZ` has no `<details>` ancestor | `supporting_documents_spec.rb -e "Usar dados da SEFAZ stays outside Editar"` passed | `spec/requests/supporting_documents_spec.rb:171,176-178` - `sefaz_confirm_pending? eq(true)` precondition, button found, `sefaz.ancestors("details") be_empty` | PASS |
| C48 | chave grouped in `[data-chave]`, raw in `input[name="chave"]` | `-e "chave is displayed in groups of four and kept raw in the edit field"` passed | `spec/requests/supporting_documents_spec.rb:191-192` - `[data-chave] text eq("3524 0612 3456 7800 0190 5500 1000 0012 3410 0001 2340")`, `input[name="chave"]["value"] eq(chave)` | PASS |
| C49 | 14 screenshots written, exit 0 | `bin/rails tailwindcss:build && bin/rspec spec/system/screens_spec.rb -e "saves one screenshot per screen and viewport"` passed | `spec/system/screens_spec.rb:121-123` - `expected.size eq(14)`, `expected.reject { File.file? && size.positive? } be_empty`; 14 files present in `tmp/screenshots/` after the run | PASS |
| C50 | every `li[data-row] [data-cell="amount"]` on month and documents: `tabular-nums`, `text-align: right` at 1280 | `-e "amount cells are tabular and right-aligned on month and documents"` passed | `spec/system/screens_spec.rb:134-138` - `styles not_to be_empty`, each `numeric include("tabular-nums")`, `align eq("right")`; selector `:96-101` | PASS |
| C51 | month at 390, `Resolver` open: `scrollWidth <= 390` | `-e "month has no horizontal scroll at 390"` passed | `spec/system/screens_spec.rb:149-150` - `have_css('li[data-status="missing"] details[open]')`, `scroll_width be <= 390` | PASS |
| C52 | home and setup at 390 | `-e "home and setup have no horizontal scroll at 390"` passed | `spec/system/screens_spec.rb:160-165` | PASS |
| C53 | documents at 390 with `Editar` open | `-e "documents has no horizontal scroll at 390"` passed | `spec/system/screens_spec.rb:175-177` - click first `Editar` summary, `have_css('li[data-row="document"] details[open]')`, `scroll_width be <= 390` | PASS |
| C54 | no class-string anchors under `spec/` | `! rg -n 'class="mb-2"\|class="mb-6"\|class="border rounded p-3 mb-3"' spec/` exit 0 | `rg` matched nothing (exit 1, negated to 0); positive anchors at `spec/support/page_helpers.rb:15-25` | PASS |

Notes on precision and sampling (not FAIL-grade on their own):
- C50 quantifies over the amount cells the system spec's world renders; `plant_world` (`screens_spec.rb:26-60`) plants no justification, so the justification amount cell (`index.html.erb:147`) is never traversed.
- C17 proves one of the 12 `date.month_names` (`config/locales/pt-BR.yml:6`); the claim names only `maio`, so no gap against the claim - recorded because the plan's Impact enumerates 13 entries and no Coverage row exists for them.

## Coverage

Recomputed from the authority over each set, not read back from `checks.md`.

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| `@theme` colour tokens (7) | `design.md` § Tokens › Color table (7 rows); `application.css:41-47` | `paper` C1 · `ink` C1 · `rule` C1 · `caixa` C1 · `margem` C1 | `sheet` (`application.css:42`), `ink-soft` (`application.css:44`) - fault F5 survived |
| Landing door 2 `@theme` variables (9) | plan Landing row 2 literal shape; `application.css:38-47` | 5 colours C1 · views use only token utilities C16 | `--font-sans` (`application.css:38`), `--font-mono` (`:39`) in addition to `sheet`, `ink-soft` above - no proof that the body face is IBM Plex or that `font-mono` resolves to IBM Plex Mono |
| font faces (4) | plan Landing door 1; `application.css:4-34` | 4 `[family, weight]` pairs C2, table-driven | - |
| Google Fonts hosts (2) | plan AC 3 | both C3 | - |
| header variants (4) | `_header.html.erb:10,12,16` (name fallback, nav guard, coordinator guard) | coordinator C6 · submitter C7 · login C8 · denied C9 | - |
| error notice ivars (4) | `grep render "shared/notice"`: `months/show:35,39`, `setup/show:6`, `supporting_documents/index:6` | `@import_error` C10 · `@month_error` C11 · `@document_error` C12 · `@certificate_error` C13 | - |
| startup assembly: Tailwind build (2) | proof chains in checks; `ci.yml:73,76` | local chain C1–C5, C49–C53 · CI C14 | - |
| missing-document summary (3) | `months/show.html.erb:24-28` | 0 C20 · 1 C19 · 2 C18 | - |
| statement summary (3) | `months/show.html.erb:29-31` | 0 C23 · 1 C21 · 2 C22 | - |
| payment `data-status` (5) | `application_helper.rb:14-26` | `missing` C24 · `matched` C25 · `bank_fee` C26 · `accountant_fee` C27 · `extra` C28 | - |
| `data-row` names (8) | `rg 'data-row="' app/views` | `bank-account` C29, C42 · `inflow` C29 · `payment` C24 · `pool-document` C29 · `month` C38 · `extra-exception-kind` C43 · `document` C44 · `justification` C46 | - |
| `Resolver` open state (3) | `months/show.html.erb:152` | suggestion C31 · exception suggestion C32 · neither C33 | - |
| statement upload fold (2) | `months/show.html.erb:69-78` | present C35 · absent C36 | - |
| `<details>` summaries (6) | `design.md` § Screens (`▸`/`▾` marks) and `rg '<summary' app/views` | `Resolver` C30 · `Substituir extrato` C35 · `Casar vários pagamentos com um documento` C37 · `Editar` bank account C42 · `Editar` document C44 | `Editar` on justification row (`supporting_documents/index.html.erb:151-152`; design § `documents` line "▸ Editar (submitter, when allowed)") |
| month state on home (2) | `organizations/show.html.erb:28` | `Aberto` C38 · `Fechado` C39 | - |
| closed-month page (2) | `months/show.html.erb:12,67,151,196` | stamp C34 · no `<details>` C34 | - |
| home h1 by access (2) | `organizations/show.html.erb:16-17,110` | `Meses` C38 · `Início` C41 | - |
| actions outside the fold (1) | `design.md` § `documents`; `index.html.erb:81-83` | `Usar dados da SEFAZ` C47 | - |
| screens (6) | `design.md` § Screens | `login` C8 · `denied` C9 · `home` C38–C41 · `setup` C42–C43 · `month` C17–C37 · `documents` C44–C48; all six shot by C49 | - (copy gap on `home` recorded under Binding sources) |
| screens at 390 (4) | plan AC 25, 30, 34 | `month` C51 · `home` C52 · `setup` C52 · `documents` C53 | - |
| tabular amount screens (2) | `rg 'data-cell="amount"' app/views` -> `months/show`, `supporting_documents/index` | `month` C50 · `documents` C50 | - |
| screenshot files (14) | plan AC 35 = 7 screens × 2 widths | C49 | - |
| Landing doors (4) | plan Landing | fonts C2 · tokens C1, C16 (partial - see rows 1–2) · test anchors C54 · screen proofs C49 | - |
| Surface routes / Relations entities | plan says `None` for both | no set rows owed | - |

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decides, reached across a boundary | `months/show.html.erb` (status ×5, `Resolver` ×3, fold ×2, summaries 3×3), `layouts/_header.html.erb` (×4), `organizations/show.html.erb` (×2, ×2, ×2), `setup/show.html.erb`, `supporting_documents/index.html.erb` | one request example per member; the artifact names the request spec as a view's own layer | yes - C6–C9, C18–C48, one asserted case per member; faults F1–F4 each killed by the member's own example |
| Decides, not reached across a boundary | `application_helper.rb` `payment_status`/`format_chave`/`month_title` are not classified in the evidence; each is reached only through the views | own-layer proof | yes, via the boundary - every `payment_status` member C24–C28, `format_chave` C48, `month_title` C17; no helper spec, consistent with the evidence's "no view-spec layer" reading |
| Entry point that decides nothing | none classified | - | n/a |
| Instrumentation, pass-throughs | `shared/_notice.html.erb`, `months/_statement_form.html.erb` | consumer's proof | yes - C10–C13, C35–C36 |
| static configuration -> proven where served | `application.css`, `public/icon.svg`, `config/locales/pt-BR.yml` | C1–C5, C15, C17 | no - `application.css` declares 9 `@theme` variables and 5 are proven where served; `--color-sheet`, `--color-ink-soft`, `--font-sans`, `--font-mono` have no proof (Coverage rows 1–2, fault F5) |
| browser-level facts -> system spec | `spec/system/screens_spec.rb` | C49–C53 | yes |

## Swept existing

- authorization: `require_account` at `app/controllers/application_controller.rb:8`, skipped only for `sessions#new/denied` and `sefaz_certificates#show` - present. Submitter chrome C7, C41.
- destructive confirms kept: `Revogar` `organizations/show.html.erb:51,73`, `Excluir` `supporting_documents/index.html.erb:127`, `Remover` `setup/show.html.erb:67`, `Fechar para envio`/`Restaurar pasta`/`Reabrir` `months/show.html.erb:13-16` - `data-turbo-confirm` present on each.
- dependency failure: `driven_by :cuprite` with `process_timeout: 30` (`screens_spec.rb:7-11`) raises when Chrome is absent - no silent skip.
- `n/a` rows (validation, idempotency, concurrency, data lifecycle, observability): policy approved in the plan; nothing in the code to contradict.

## Faults injected

Scratch worktree `git worktree add /tmp/vi-scratch HEAD`; real-tree porcelain before and after: `?? skills-lock.json` only. Scratch removed after F5.

| Mutation | Location | Killed |
| --- | --- | --- |
| `payment_status`: `bank_fee?` branch returns `"accountant_fee"` | `app/helpers/application_helper.rb:19-20` | yes - C26 `document_exceptions_spec.rb:347` (`expected: not nil`) |
| `Resolver` `open:` drops `exception_suggestion.present?` | `app/views/months/show.html.erb:152` | yes - C32 `months_spec.rb:1447` (`expected: true`) |
| header renders `Configuração` for every account (`if true`) | `app/views/layouts/_header.html.erb:16` | yes - C7 `layout_spec.rb:31` (`expected: nil`) |
| summary pluralization swapped (`1 pagamentos`, `2 pagamento`) | `app/views/months/show.html.erb:27` | yes - C18 `months_spec.rb:1329`, C19 `:1338` |
| `--color-ink-soft` removed from `@theme` (built CSS loses every `text-ink-soft` utility) | `app/assets/tailwind/application.css:44` | no - survived: `bin/rails tailwindcss:build && bin/rspec spec/requests/stylesheet_spec.rb spec/assets/views_palette_spec.rb spec/requests/layout_spec.rb` 8 examples, 0 failures |

## Gate

`bin/rails tailwindcss:build && bin/rspec` at `4a554d1` - 974 examples, 0 failures.
`! rg -n 'class="mb-2"|class="mb-6"|class="border rounded p-3 mb-3"' spec/` - exit 0.
`python3 .cursor/skills/tlc-spec-lean/scripts/validate_verification.py visual-identity` - exit 1 (verdict FAIL; expected).

## Ranked gaps

1. Four `@theme` variables with no proof (`--color-sheet`, `--color-ink-soft`, `--font-sans`, `--font-mono`) - C1 / Landing door 2 - `app/assets/tailwind/application.css:38-39,42,44`; mutant F5 survived. Fix: extend the stylesheet proof to every token the design table and door 2 name (a table-driven example over 7 colours and 2 font stacks), then re-inject F5.
2. `home` `Pessoas` `<h2>` - new copy in `design.md` with no check - `app/views/organizations/show.html.erb:43`. Fix: one request example (`h2` text `Pessoas` on coordinator `GET /`).
3. Justification `Editar` `<details>` - drawn in `design.md` § `documents`, no check - `app/views/supporting_documents/index.html.erb:151-152`. Fix: one request example as submitter with an editable justification: PATCH `/justifications/{id}` form has a `<details>` ancestor whose `<summary>` is `Editar`.

All three are check omissions; the product code satisfies the design on each (seen in the ERB and in `home-1280.png` / `documents-1280.png`). No code change is required unless the new proofs disagree.
