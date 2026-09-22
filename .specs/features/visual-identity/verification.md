# Visual identity verification

**Verdict**: PASS
**Profile**: ui
**Diff range**: `fc0d56b..612c08d` (fix diff `8513b63..612c08d`, one commit, specs and `checks.md` only; product code unchanged since `0d0606d`)
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier; also not the round-1 verifier)

Round 1 (`4a554d1`, report committed at `8513b63`) ended on three check omissions: four `@theme`
tokens with no proof and a mutant on `--color-ink-soft` that every proof let through, the home
`Pessoas` heading with no check, and the justification `Editar` fold with no check. The fix adds
C55–C57 (human-approved additive checks, `checks.md` `### S6`) and three request examples, and
changes no product code. This round proves the three new checks at `HEAD`, re-injects the
mutant that got through in round 1 plus one fault per new assertion surface (3/3 killed),
recomputes the three affected Coverage sets (0 members unproven), re-opens `design.md` for the
two uncovered items (both now covered), and re-runs every proof in one invocation at `612c08d`
(977 examples, 0 failures; all 56 named examples present individually). Every other verdict was
PASS in round 1 and is carried forward below with its origin marked.

## Scope of this round

Per `verify.md` § Re-verifying after a fix: the fix's diff plus every verdict that was not PASS.

| Item | Status in this round |
| --- | --- |
| C55, C56, C57 | verified at `612c08d` - proof run, example shown in the fix diff, assertion located |
| C1–C54 proofs | re-run at `612c08d` (green is a property of a commit); citations carried from `4a554d1`, refreshed for `organizations_spec.rb` (the fix inserted an example at `:169-177`, moving C39 and C41) |
| Coverage: `@theme` colour tokens, door 2 variables, `<details>` summaries, home new copy, Landing doors | recomputed at `612c08d` |
| Coverage: every other set | carried from `4a554d1` - the fix touched none of their authorities |
| Binding sources: `home` (coordinator), `documents` | re-opened at `612c08d` for the two uncovered items |
| Binding sources: other rows, per-screen enumeration, exemption list | carried from `4a554d1` - the fix touched no view |
| Test policy: `static configuration -> proven where served` | re-judged at `612c08d` (was unmet) |
| Test policy: other rows | carried from `4a554d1`; the fix touched only spec files, which no row classifies |
| Faults: F5 (`--color-ink-soft`) | re-injected exactly at `612c08d` |
| Faults: F6, F7 (new assertion surfaces of C56, C57) | injected at `612c08d` |
| Faults: F1–F4 | carried from `4a554d1` (all killed there; their surfaces are untouched) |
| Swept existing | carried from `4a554d1` - no controller or view changed |

## Binding sources

Rows marked `612c08d` were re-opened this round; the rest are carried from `4a554d1`.

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| `design.md` § Tokens › Color table (7 rows), § Type (font stacks) | yes - `612c08d`; compared against `application.css:38-47` and C1 + C55 | none | - |
| `design.md` § Tokens › Layout / Mark | carried from `4a554d1` | none | - |
| `design.md` § `login` | carried from `4a554d1` | none | - |
| `design.md` § `denied` | carried from `4a554d1` | none | - |
| `design.md` § `home` (coordinator) | yes - `612c08d`; `design.md:168-192` against `organizations/show.html.erb:43` and C56 | none - `Pessoas` is an `(h2)` in the sketch (`design.md:177`) and in "New copy" (`:192`); the view renders `<h2>Pessoas</h2>` and C56 asserts the `h2` text | - |
| `design.md` § `home` (submitter) | carried from `4a554d1` | none | - |
| `design.md` § `setup` | carried from `4a554d1` | none | - |
| `design.md` § `month` (open) | carried from `4a554d1` | none | - |
| `design.md` § `month` (closed) | carried from `4a554d1` | none | - |
| `design.md` § `documents` | yes - `612c08d`; `design.md:287-320` against `supporting_documents/index.html.erb:150-160` and C57 | none - design line `:310` draws `▸ Editar (submitter, when allowed)` on the justification row; the view guards the fold with `!coordinator_on_focus? && … month_id.nil?` (`:150`) and C57 asserts the PATCH form sits under a `<details>` whose summary is `Editar`, as submitter, with `month_id` nil | - |
| `CONTEXT.md`, `.cursor/rules/rails.mdc`, ADR-0001 | listed in plan Sources, not marked binding | - | - |

### Per-screen enumeration (copy and arrangement)

Carried from `4a554d1` (round-1 report at `8513b63`, section "Per-screen enumeration") for every
line except the two that were gaps, which now read:

- **`home` coordinator** - `Pessoas` `<h2>` -> C56 (`organizations/show.html.erb:43`)
- **`documents`** - `Justificativas` rows: `▸ Editar` (submitter, when allowed) `<details>` -> C57 (`supporting_documents/index.html.erb:151-152`)

The fix touched no ERB, layout, CSS or locale, so every other enumerated line (header, `login`,
`denied`, `home` submitter, `setup`, `month`, `documents` document rows) holds as recorded in
round 1, including the `Resolver` placement note.

### Out of a selector's reach (enumerated, not a blanket clause)

Carried from `4a554d1`: spacing, type scale, weights, `rule` colour, switcher fill, `ink-soft`
on `Aberto`/`Fechado`, red-margin geometry, `margem` on `Falta` and the missing sentence, chave
mono face, meta colours - named per screen in the round-1 report. One addition from this
round's recompute: the `@theme` block also declares five `--text-*` variables
(`application.css:49-53`: `meta` size/line-height, `display` size/line-height/letter-spacing).
They sit outside Landing door 2's literal shape (9 variables) and outside the design Tokens
table; they are the type scale, which round 1 already enumerated as exempt per screen. Recorded
so the exemption stays enumerated rather than implied.

## Checks

Proofs run at `612c08d`. One invocation for the whole target: `bin/rails tailwindcss:build &&
bin/rspec --format documentation` - 977 examples, 0 failures; each of the 56 `-e` names in
`checks.md` appears exactly once in the documentation output (exact-string match, count = 1 for
all 56). C54 ran as written (`rg` exit 1, negated to 0). Additionally the three new examples were
run alone in one invocation (`bin/rspec spec/requests/stylesheet_spec.rb
spec/requests/organizations_spec.rb spec/requests/justifications_spec.rb -e … -e … -e …` - 3
examples, 0 failures). All three are `+ it "…"` lines in `git diff 8513b63..612c08d -- spec`
(`stylesheet_spec.rb` +73, `organizations_spec.rb` +169, `justifications_spec.rb` +239); none
resolves to a pre-existing example.

### Verified at `612c08d`

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C55 | served CSS declares `--color-sheet` `#fff`/`#ffffff`, `--color-ink-soft` `#5c6e66`, `--font-sans` beginning `"IBM Plex Sans"`, `--font-mono` beginning `"IBM Plex Mono"` | `bin/rails tailwindcss:build && bin/rspec spec/requests/stylesheet_spec.rb -e "served stylesheet declares sheet, ink-soft and the two font stacks"` passed | `spec/requests/stylesheet_spec.rb:76-79` - `expect(css).to match(/--color-sheet:\s*#(fff∣ffffff)\b/i)` (∣ stands for the regex alternation bar, kept out of the table cell), `match(/--color-ink-soft:\s*#5c6e66\b/i)`, `match(/--font-sans:\s*"IBM Plex Sans"/)`, `match(/--font-mono:\s*"IBM Plex Mono"/)`; `css` is the stylesheet fetched from the `<link>` of `GET /login` (`:4-12`); source values `application.css:38,39,42,44` | PASS |
| C56 | coordinator `GET /` renders an `<h2>` whose text is `Pessoas` | `bin/rspec spec/requests/organizations_spec.rb -e "home has a Pessoas h2"` passed | `spec/requests/organizations_spec.rb:175-176` - `headings = page_doc(response.body).css("h2").map { ∣h2∣ h2.text.strip }` (∣ = block-parameter bars), `expect(headings).to include("Pessoas")` after `get "/"` as coordinator (`:170-173`) | PASS |
| C57 | submitter `GET /supporting_documents`: justification with all documents `month_id` nil renders its `PATCH /justifications/{id}` form inside `<details>` with summary `Editar`, inside `li[data-row="justification"][data-justification-id="{id}"]` | `bin/rspec spec/requests/justifications_spec.rb -e "justification edit form folds under Editar"` passed | `spec/requests/justifications_spec.rb:248-254` - `row(response.body, "justification", justification_id: justification.id)` (locator `spec/support/page_helpers.rb:19-22` = `li[data-row="justification"][data-justification-id="…"]`), `form = justification_row.at_css("form[action=\"/justifications/#{id}\"]")` not nil, `input[name="_method"][value="patch"]` not nil, `details = form.ancestors("details").first` not nil, `details.at_css("summary").text.strip eq("Editar")`; precondition `expect(document.reload.month_id).to be_nil` `:244`, signed in via `signed_submitter` `:240` | PASS |

### Carried from `4a554d1` (proofs re-run at `612c08d`)

Claims, proofs and evidence as recorded in the round-1 report (`8513b63`). Citations are
unchanged except where the fix moved lines (`organizations_spec.rb`), refreshed below.

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | served CSS declares the five colour tokens | re-run at `612c08d`, passed | `spec/requests/stylesheet_spec.rb:18-25` | PASS - carried from `4a554d1` |
| C2 | four `@font-face`, `src` `/assets/…woff2` | re-run, passed | `spec/requests/stylesheet_spec.rb:33-40` | PASS - carried from `4a554d1` |
| C3 | no Google Fonts host | re-run, passed | `spec/requests/stylesheet_spec.rb:46-58` | PASS - carried from `4a554d1` |
| C4 | `:focus-visible` outline in `caixa` | re-run, passed | `spec/requests/stylesheet_spec.rb:63-66` | PASS - carried from `4a554d1` |
| C5 | no `@keyframes` | re-run, passed | `spec/requests/stylesheet_spec.rb:70` | PASS - carried from `4a554d1` |
| C6 | coordinator header | re-run, passed | `spec/requests/layout_spec.rb:12-19` | PASS - carried from `4a554d1` |
| C7 | submitter header omits `/setup` | re-run, passed | `spec/requests/layout_spec.rb:31-32` | PASS - carried from `4a554d1` |
| C8 | `/login` shell | re-run, passed | `spec/requests/sessions_spec.rb:25-29` | PASS - carried from `4a554d1` |
| C9 | `/denied` shell | re-run, passed | `spec/requests/denied_spec.rb:17-19` | PASS - carried from `4a554d1` |
| C10 | `@import_error` alert | re-run, passed | `spec/requests/bank_statements_spec.rb:84-85` | PASS - carried from `4a554d1` |
| C11 | `@month_error` alert | re-run, passed | `spec/requests/close_spec.rb:61-62` | PASS - carried from `4a554d1` |
| C12 | `@document_error` alert | re-run, passed | `spec/requests/supporting_documents_spec.rb:202-203` | PASS - carried from `4a554d1` |
| C13 | `@certificate_error` alert | re-run, passed | `spec/requests/sefaz_certificates_spec.rb:87-88` | PASS - carried from `4a554d1` |
| C14 | CI builds Tailwind before rspec | re-run, passed | `spec/config/ci_workflow_spec.rb:9-14` | PASS - carried from `4a554d1` |
| C15 | `icon.svg` mark | re-run, passed | `spec/assets/icon_spec.rb:8-9` | PASS - carried from `4a554d1` |
| C16 | no raw palette in views | re-run, passed | `spec/assets/views_palette_spec.rb:6,10` | PASS - carried from `4a554d1` |
| C17 | month title `maio de 2026` / `2026-05` | re-run, passed | `spec/requests/months_spec.rb:1318-1319` | PASS - carried from `4a554d1` |
| C18 | 2 missing summary | re-run, passed | `spec/requests/months_spec.rb:1329` | PASS - carried from `4a554d1` |
| C19 | 1 missing summary | re-run, passed | `spec/requests/months_spec.rb:1338` | PASS - carried from `4a554d1` |
| C20 | 0 missing summary | re-run, passed | `spec/requests/months_spec.rb:1347-1348` | PASS - carried from `4a554d1` |
| C21 | 1 account without statement | re-run, passed | `spec/requests/months_spec.rb:1357` | PASS - carried from `4a554d1` |
| C22 | 2 accounts without statement | re-run, passed | `spec/requests/months_spec.rb:1367` | PASS - carried from `4a554d1` |
| C23 | all active with statements | re-run, passed | `spec/requests/months_spec.rb:1372-1377` | PASS - carried from `4a554d1` |
| C24 | `data-status="missing"` | re-run, passed | `spec/requests/months_spec.rb:1386` | PASS - carried from `4a554d1` |
| C25 | `data-status="matched"` | re-run, passed | `spec/requests/months_spec.rb:1397` | PASS - carried from `4a554d1` |
| C26 | `data-status="bank_fee"` | re-run, passed | `spec/requests/document_exceptions_spec.rb:347` | PASS - carried from `4a554d1` |
| C27 | `data-status="accountant_fee"` | re-run, passed | `spec/requests/document_exceptions_spec.rb:357` | PASS - carried from `4a554d1` |
| C28 | `data-status="extra"` | re-run, passed | `spec/requests/document_exceptions_spec.rb:362-368` | PASS - carried from `4a554d1` |
| C29 | `inflow`, `pool-document`, `bank-account` rows | re-run, passed | `spec/requests/months_spec.rb:1408-1410` | PASS - carried from `4a554d1` |
| C30 | `Resolver` fold, `Documento faltante` first | re-run, passed | `spec/requests/months_spec.rb:1422-1425` | PASS - carried from `4a554d1` |
| C31 | `Resolver` open on suggestion | re-run, passed | `spec/requests/months_spec.rb:1436` | PASS - carried from `4a554d1` |
| C32 | `Resolver` open on exception suggestion | re-run, passed | `spec/requests/months_spec.rb:1447` | PASS - carried from `4a554d1` |
| C33 | `Resolver` closed otherwise | re-run, passed | `spec/requests/months_spec.rb:1457` | PASS - carried from `4a554d1` |
| C34 | closed month stamp, no `<details` | re-run, passed | `spec/requests/close_spec.rb:49-52` | PASS - carried from `4a554d1` |
| C35 | `Substituir extrato` fold | re-run, passed | `spec/requests/months_spec.rb:1467-1471` | PASS - carried from `4a554d1` |
| C36 | absent statement form inline | re-run, passed | `spec/requests/months_spec.rb:1481-1483` | PASS - carried from `4a554d1` |
| C37 | N:1 fold | re-run, passed | `spec/requests/matches_spec.rb:605-611` | PASS - carried from `4a554d1` |
| C38 | home h1 `Meses`, open row `Aberto` | re-run, passed | `spec/requests/organizations_spec.rb:161-166` (unchanged) | PASS - carried from `4a554d1` |
| C39 | closed month row `Fechado` | re-run, passed | `spec/requests/organizations_spec.rb:189-190` (refreshed; was `:178-180`) - `include("Fechado")`, `not_to include("Aberto")` | PASS - carried from `4a554d1` |
| C40 | switcher `aria-current` | re-run, passed | `spec/requests/focus_spec.rb:27-31` | PASS - carried from `4a554d1` |
| C41 | submitter home `Início` | re-run, passed | `spec/requests/organizations_spec.rb:199-202` (refreshed; was `:189-192`) - `eq("Início")`, `not_to include("Meses")` | PASS - carried from `4a554d1` |
| C42 | setup h1, bank-account `Editar` fold | re-run, passed | `spec/requests/setup_spec.rb:352-359` | PASS - carried from `4a554d1` |
| C43 | extra-exception-kind row | re-run, passed | `spec/requests/extra_exception_kinds_spec.rb:265-267` | PASS - carried from `4a554d1` |
| C44 | documents h1, insert form first, `Editar` fold | re-run, passed | `spec/requests/supporting_documents_spec.rb:139-149` | PASS - carried from `4a554d1` |
| C45 | `Excluir` inside `Editar` | re-run, passed | `spec/requests/supporting_documents_spec.rb:159-161` | PASS - carried from `4a554d1` |
| C46 | justification row | re-run, passed | `spec/requests/justifications_spec.rb:234-236` (unchanged; fix appended after `:238`) | PASS - carried from `4a554d1` |
| C47 | `Usar dados da SEFAZ` outside `Editar` | re-run, passed | `spec/requests/supporting_documents_spec.rb:171-178` | PASS - carried from `4a554d1` |
| C48 | grouped chave / raw edit value | re-run, passed | `spec/requests/supporting_documents_spec.rb:191-192` | PASS - carried from `4a554d1` |
| C49 | 14 screenshots | re-run, passed (14 files under `tmp/screenshots/`) | `spec/system/screens_spec.rb:121-123` | PASS - carried from `4a554d1` |
| C50 | tabular right-aligned amounts | re-run, passed | `spec/system/screens_spec.rb:134-138` | PASS - carried from `4a554d1` |
| C51 | month no horizontal scroll at 390 | re-run, passed | `spec/system/screens_spec.rb:149-150` | PASS - carried from `4a554d1` |
| C52 | home, setup at 390 | re-run, passed | `spec/system/screens_spec.rb:160-165` | PASS - carried from `4a554d1` |
| C53 | documents at 390 | re-run, passed | `spec/system/screens_spec.rb:175-177` | PASS - carried from `4a554d1` |
| C54 | no class-string anchors in `spec/` | `! rg -n 'class="mb-2"∣class="mb-6"∣class="border rounded p-3 mb-3"' spec/` (∣ = regex alternation bar) exit 0 at `612c08d`; exact command in § Gate | `rg` matched nothing; anchors at `spec/support/page_helpers.rb:15-25` | PASS - carried from `4a554d1` |

Precision notes carried from `4a554d1` (not FAIL-grade): C50 quantifies over the system spec's
planted world, which has no justification row; C17 proves one of 12 month names against a claim
that names one.

## Coverage

Rows marked `612c08d` were recomputed this round from the authority over the set; the rest are
carried from `4a554d1`, whose authorities the fix did not touch.

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| `@theme` colour tokens (7) | `612c08d` - `design.md:41-47` Color table (7 rows); `application.css:41-47` (7 `--color-*` lines) | `paper` C1 · `ink` C1 · `rule` C1 · `caixa` C1 · `margem` C1 · `sheet` C55 (`stylesheet_spec.rb:76`) · `ink-soft` C55 (`:77`) | - |
| Landing door 2 `@theme` variables (9) | `612c08d` - `plan.md:227` literal shape (7 colours + `--font-sans` + `--font-mono`); `application.css:38-47` | 7 colours C1 + C55 · `--font-sans` C55 (`stylesheet_spec.rb:78`, begins `"IBM Plex Sans"`) · `--font-mono` C55 (`:79`, begins `"IBM Plex Mono"`) · views use only token utilities C16 | - |
| `<details>` summaries (6) | `612c08d` - `design.md` `▸`/`▾` marks at `:217,240,248,255,308,310` (6); `rg '<summary' app/views` -> `months/show:71,153,198`, `supporting_documents/index:85,152`, `setup/show:108` (6) | `Substituir extrato` C35 · `Resolver` C30 · `Casar vários pagamentos com um documento` C37 · `Editar` document C44 · `Editar` justification C57 (`index.html.erb:151-152`) · `Editar` bank account C42 | - |
| home `design.md` new copy (4) | `612c08d` - `design.md:192` "New copy: `Meses` (h1), `Pessoas`, `Aberto`, `Fechado`" | `Meses` C38 (`organizations_spec.rb:161`) · `Pessoas` C56 (`:176`) · `Aberto` C38 (`:165`) · `Fechado` C39 (`:189`) | - |
| Landing doors (4) | `612c08d` - plan Landing | fonts C2 · tokens C1, C55, C16 (all 9 door-2 variables now proven where served) · test anchors C54 · screen proofs C49 | - |
| font faces (4) | carried from `4a554d1` | 4 pairs C2 | - |
| Google Fonts hosts (2) | carried from `4a554d1` | C3 | - |
| header variants (4) | carried from `4a554d1` | C6 · C7 · C8 · C9 | - |
| error notice ivars (4) | carried from `4a554d1` | C10 · C11 · C12 · C13 | - |
| startup assembly: Tailwind build (2) | carried from `4a554d1` | local chain C1–C5, C49–C53, C55 · CI C14 | - |
| missing-document summary (3) | carried from `4a554d1` | C20 · C19 · C18 | - |
| statement summary (3) | carried from `4a554d1` | C23 · C21 · C22 | - |
| payment `data-status` (5) | carried from `4a554d1` | C24 · C25 · C26 · C27 · C28 | - |
| `data-row` names (8) | carried from `4a554d1` | C29, C42 · C29 · C24 · C29 · C38 · C43 · C44 · C46 | - |
| `Resolver` open state (3) | carried from `4a554d1` | C31 · C32 · C33 | - |
| statement upload fold (2) | carried from `4a554d1` | C35 · C36 | - |
| month state on home (2) | carried from `4a554d1` | C38 · C39 | - |
| closed-month page (2) | carried from `4a554d1` | C34 · C34 | - |
| home h1 by access (2) | carried from `4a554d1` | C38 · C41 | - |
| actions outside the fold (1) | carried from `4a554d1` | C47 | - |
| screens (6) | carried from `4a554d1`; the `home` copy note from round 1 is closed by C56 | C8 · C9 · C38–C41, C56 · C42–C43 · C17–C37 · C44–C48, C57; all six shot by C49 | - |
| screens at 390 (4) | carried from `4a554d1` | C51 · C52 · C52 · C53 | - |
| tabular amount screens (2) | carried from `4a554d1` | C50 · C50 | - |
| screenshot files (14) | carried from `4a554d1` | C49 | - |
| Surface routes / Relations entities | plan says `None` for both | - | - |

Sweep for sets the fix could have added: the fix diff contains no branch, route, entity or
enumerated value - three request examples and three `checks.md` rows. The `checks.md` rows added
(`remaining @theme tokens, door 2 (4)`, `home design.md new copy (4)`, `<details> summaries,
sixth (1)`) are sub-rows of the three recomputed sets above and agree with the recompute.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decides, reached across a boundary | `months/show.html.erb`, `layouts/_header.html.erb`, `organizations/show.html.erb`, `setup/show.html.erb`, `supporting_documents/index.html.erb` | one request example per member | yes - carried from `4a554d1` (C6–C9, C18–C48, faults F1–F4 killed); `organizations/show.html.erb` and `supporting_documents/index.html.erb` gain C56 and C57 at the same layer, faults F6 and F7 killed at `612c08d` |
| Decides, not reached across a boundary | `application_helper.rb` (`payment_status`, `format_chave`, `month_title`), reached only through views | own-layer proof | yes - carried from `4a554d1`: every member proven via the boundary (C24–C28, C48, C17), consistent with the evidence's request-spec-as-own-layer reading |
| Entry point that decides nothing | none classified | - | n/a |
| Instrumentation, pass-throughs | `shared/_notice.html.erb`, `months/_statement_form.html.erb` | consumer's proof | yes - carried from `4a554d1` (C10–C13, C35–C36) |
| static configuration -> proven where served | `application.css`, `public/icon.svg`, `config/locales/pt-BR.yml` | C1–C5, C15, C17 (+ C55) | yes - re-judged at `612c08d`: all 9 door-2 `@theme` variables proven on the served stylesheet (C1 five colours, C55 `sheet`, `ink-soft`, `font-sans`, `font-mono`); fault F5 killed by C55; `icon.svg` C15 and locale C17 carried |
| browser-level facts -> system spec | `spec/system/screens_spec.rb` | C49–C53 | yes - carried from `4a554d1` |

## Swept existing

Carried from `4a554d1`: the fix changed no controller, view or config, so `require_account`
(`application_controller.rb:8`), the `data-turbo-confirm` guards on `Revogar` / `Excluir` /
`Remover` / `Fechar para envio` / `Restaurar pasta` / `Reabrir`, the `driven_by :cuprite`
process timeout, and the approved `n/a` rows stand as recorded in the round-1 report.

## Faults injected

Scratch worktree `git worktree add /tmp/vi-scratch2 HEAD` (`612c08d`); real-tree porcelain
before: `?? skills-lock.json`; after removal: `?? skills-lock.json`, `HEAD` = `612c08d`,
`git worktree list` shows the scratch gone. `master.key` copied into the scratch for boot only.
Each fault was reverted in the scratch (`git checkout -- <file>`, clean porcelain confirmed)
before the next.

| Mutation | Location | Killed |
| --- | --- | --- |
| F5 (round-1 mutant, re-injected exactly): `--color-ink-soft: #5c6e66;` line deleted from `@theme`, then `bin/rails tailwindcss:build` | `app/assets/tailwind/application.css:44` | yes - C55 `spec/requests/stylesheet_spec.rb:77` `expect(css).to match(/--color-ink-soft:\s*#5c6e66\b/i)` red (1 example, 1 failure) |
| F6: home `<h2>Pessoas</h2>` -> `<h2>Equipe</h2>` | `app/views/organizations/show.html.erb:43` | yes - C56 `spec/requests/organizations_spec.rb:176` `expected ["Equipe", "Convites pendentes"] to include "Pessoas"` |
| F7: justification PATCH form moved outside its `<details>` (the `</details>` closed right after the `Editar` summary, form follows as a sibling) | `app/views/supporting_documents/index.html.erb:151-160` | yes - C57 `spec/requests/justifications_spec.rb:253` `expect(details).not_to be_nil` (`expected: not nil`) |
| F1 `payment_status` `bank_fee?` -> `"accountant_fee"` | `app/helpers/application_helper.rb:19-20` | yes - carried from `4a554d1` (C26) |
| F2 `Resolver` `open:` drops `exception_suggestion.present?` | `app/views/months/show.html.erb:152` | yes - carried from `4a554d1` (C32) |
| F3 header renders `Configuração` for every account | `app/views/layouts/_header.html.erb:16` | yes - carried from `4a554d1` (C7) |
| F4 summary pluralization swapped | `app/views/months/show.html.erb:27` | yes - carried from `4a554d1` (C18, C19) |

Every proof carrying a check on the fix's surfaces has now been made to fail once (C55 by F5,
C56 by F6, C57 by F7); the round-1 surfaces were made to fail once in round 1 and are untouched.

## Gate

`bin/rails tailwindcss:build && bin/rspec` at `612c08d` - 977 examples, 0 failures.
`bin/rspec --format documentation` at `612c08d` - 977 examples, 0 failures; all 56 named examples present once each.
`bin/rspec spec/requests/stylesheet_spec.rb spec/requests/organizations_spec.rb spec/requests/justifications_spec.rb -e "served stylesheet declares sheet, ink-soft and the two font stacks" -e "home has a Pessoas h2" -e "justification edit form folds under Editar"` - 3 examples, 0 failures.
`! rg -n 'class="mb-2"|class="mb-6"|class="border rounded p-3 mb-3"' spec/` - exit 0.
`python3 .cursor/skills/tlc-spec-lean/scripts/validate_verification.py visual-identity` - 0 error(s), 0 warning(s), exit 0.
