# Setup desk checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/setup-desk/plan.md`

33 checks in 4 slices · 0 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`. Capture proof is at 1920×1080.

## Checks

### S1 - The desk matches the capture

**C1** - A coordinator whose organization has accountant `Ana Contábil`, a blank package-archive URL, an expired A1, two bank accounts, and the two base extra kinds active, GETs `/setup` and sees `.specs/features/setup-desk/captures/setup-gaps.png` (AC 1)
Proof: browser - reach that coordinator setup, save `captures/setup-gaps.running.png` at 1920×1080

**C2** - Coordinator GET `/setup`: header link `Configuração` has `aria-current="page"` (AC 2)
Proof: `bin/rspec spec/requests/layout_spec.rb -e "GET /setup Configuracao has aria-current page"`

**C3** - Coordinator GET `/`: `Início` has `aria-current="page"` and `Configuração` does not (AC 3)
Proof: `bin/rspec spec/requests/layout_spec.rb -e "GET / Inicio is the only principal nav link with aria-current page"`

### S2 - The left list is the five standing items

**C4** - Coordinator GET `/setup`: the left column includes heading `Configuração` and a `nav` `aria-label="Itens de configuração"` whose five titles are `Contador`, `Arquivo do pacote`, `Certificado A1`, `Contas bancárias`, `Tipos extras` in that order (AC 4)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "setup index lists five items in order"`

**C5** - Accountant presentation name present: Contador row includes that name and `Cadastrado`, and does not take the red margin (AC 5)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "complete Contador row is Cadastrado without red margin"`

**C6** - Package-archive URL blank: Arquivo do pacote row includes `Pasta do Drive` and `Falta` in `margem`, and takes the red margin (AC 6)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "blank archive row is Falta in margem with red margin"`

**C7** - A1 installed and `sefaz_certificate_expired?`: Certificado A1 row includes `Consulta SEFAZ` and `Expirado` in `margem`, and takes the red margin (AC 7)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "expired A1 row is Expirado in margem with red margin"`

**C8** - No A1 installed: Certificado A1 row includes `Falta` in `margem`, and takes the red margin (AC 8)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "missing A1 row is Falta in margem with red margin"`

**C9** - A1 installed and not expired: Certificado A1 row includes `Instalado`, and does not take the red margin (AC 9)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "valid A1 row is Instalado without red margin"`

**C10** - Two bank accounts: Contas bancárias row includes `2 contas` and `Ativas`, and does not take the red margin (AC 10)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "two bank accounts row is 2 contas Ativas without red margin"`

**C11** - Zero bank accounts: Contas bancárias row includes `Falta` in `margem`, and takes the red margin (AC 11)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "zero bank accounts row is Falta in margem with red margin"`

**C12** - Two extra kinds active: Tipos extras row includes `2 ativos`, and does not take the red margin (AC 12)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "two active extras row is 2 ativos without red margin"`

**C13** - Tipos extras row never takes the red margin (AC 13)
Proof: `bin/rspec spec/models/setup_desk_spec.rb -e "extras is never incomplete"`
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "Tipos extras row never takes the red margin"`

**C33** - Accountant presentation name blank: Contador row includes `Falta` in `margem`, and takes the red margin (Landing Incomplete)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "blank Contador row is Falta in margem with red margin"`

### S3 - Selecting an item fills the right desk

**C14** - Arquivo do pacote row is `GET /setup?item=archive` (AC 14)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "Arquivo do pacote row is GET item archive"`

**C15** - GET `/setup?item=certificate`: Certificado A1 row is `aria-current="true"`, no other index row is, and the right column `<h1>` is `Certificado A1` (AC 15)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "item certificate marks Certificado A1 current and h1"`

**C16** - GET `/setup?item=accountant`: right column `<h1>` is `Contador` and includes today’s accountant leitura or cadastro (AC 16)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "item accountant cadastro has h1 Contador"`
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "item accountant leitura has h1 Contador"`

**C17** - GET `/setup?item=banks`: right column `<h1>` is `Contas bancárias` and includes today’s bank-account sheet and Adicionar conta (AC 17)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "item banks has h1 Contas bancarias sheet and Adicionar conta"`

**C18** - GET `/setup?item=extras`: right column `<h1>` is `Tipos extras` and includes today’s extras sheet and Adicionar tipo extra (AC 18)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "item extras has h1 Tipos extras sheet and Adicionar tipo extra"`

**C19** - `item` absent, empty, or not one of `accountant` `archive` `certificate` `banks` `extras`: selected item is the first incomplete in list order, or `accountant` when none are incomplete (AC 19)
Proof: `bin/rspec spec/models/setup_desk_spec.rb -e "absent item selects first incomplete"`
Proof: `bin/rspec spec/models/setup_desk_spec.rb -e "empty item selects first incomplete"`
Proof: `bin/rspec spec/models/setup_desk_spec.rb -e "unknown item selects first incomplete"`
Proof: `bin/rspec spec/models/setup_desk_spec.rb -e "complete setup selects accountant"`
Proof: `bin/rspec spec/models/setup_desk_spec.rb -e "missing A1 after complete accountant and archive selects certificate"`

**C20** - GET `/setup` with no `item`, Contador complete, Arquivo do pacote `Falta`: selected item is `archive` (AC 20)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "default GET setup selects archive when it is the first Falta"`

**C21** - GET `/setup?edit=accountant`: selected item is `accountant` even if another item is incomplete, and today’s accountant form is writable (AC 21)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "edit accountant selects Contador and opens the writable form"`

**C22** - GET `/setup?edit=package_archive`: selected item is `archive` and today’s archive form is writable (AC 22)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "edit package_archive selects Arquivo and opens the writable form"`

**C23** - GET `/setup?edit=bank_account` with a valid `bank_account_id`: selected item is `banks` and today’s bank-account form is open for that row (AC 23)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "edit bank_account selects Contas and opens that row form"`

### S4 - The right pane is today’s item

**C24** - Arquivo do pacote selected and URL blank: right column includes `Cole a URL da pasta do Google Drive` in `margem` and submit `Salvar arquivo` (AC 24)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "blank archive pane Cole a URL in margem and Salvar arquivo"`

**C25** - Certificado A1 selected and none installed: right column includes `Não há certificado A1 instalado. Use Instalar certificado.` (AC 25)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "missing A1 pane includes the empty install line"`

**C26** - Contador selected and presentation name blank: right column includes `Cadastre o contador` and today’s cadastro form (AC 26)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "blank Contador pane includes Cadastre o contador"`

**C27** - A successful write to accountant, package archive, A1, bank account, or extra kind redirects to `/setup?item=` of that item and today’s toast remains (AC 27)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant names the saved accountant in the toast"`
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive toasts the saved package folder"`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST /sefaz_certificate names the titular and validity in the toast"`
Proof: `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "DELETE /sefaz_certificate names the removed titular in the toast"`
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST /bank_accounts names the created account in the toast"`
Proof: `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST /extra_exception_kinds names the created kind in the toast"`
Proof: `bin/rspec spec/requests/base_document_exceptions_spec.rb -e "PATCH bank_fee inactive names the deactivated exception"`

**C28** - Coordinator GET `/setup` does not include heading `Armazenamento do pacote mensal`, does not include heading `Certificado Digital A1 - Para consulta na SEFAZ`, does not include heading `Tipos extras de exceção`, and does not stack the five chapters in one scrolling column (AC 28)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "setup omits stacked chapter headings and space-y-12"`

**C29** - Coordinator GET `/setup` at a viewport below 768px: the two panes stack, as on coordinator Início (AC 29)
Proof: `bin/rspec spec/requests/setup_desk_spec.rb -e "setup main is a two-column grid with first column 26rem"`

**C30** - Unauthenticated GET `/setup` responds `302` to `/login` (AC 30)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "unauthenticated GET /setup responds 302 to /login"`

**C31** - Signed-in Account with no focused organization GET `/setup` responds `302` to `/login` (AC 31)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup without focus responds 302 to /login"`

**C32** - Submitter GET `/`: the header does not include `Configuração` (AC 32)
Proof: `bin/rspec spec/requests/layout_spec.rb -e "submitter header omits Configuracao and /setup"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| GET `/setup` statuses (2) | `200` C4 · `302` C30 | - |
| home `aria-current` flag (2) | Início C3 · Configuração C2 | - |
| source controls: `setup-gaps` (12) | header current C2 · left heading C4 · index nav C4 · Contador C5 · Arquivo href C14 · Arquivo Falta C6 · Certificado Expirado C7 · Contas C10 · Tipos extras C12 · right h1 C20 · Cole a URL C24 · Salvar arquivo C24 | - |
| left titles (5) | Contador C4 · Arquivo do pacote C4 · Certificado A1 C4 · Contas bancárias C4 · Tipos extras C4 | - |
| incomplete stamps (6) | Contador Falta C33 · archive Falta C6 · A1 Expirado C7 · A1 Falta C8 · banks Falta C11 · extras never C13 | - |
| complete stamps (4) | Contador Cadastrado C5 · banks Ativas C10 · extras 2 ativos C12 · A1 Instalado C9 | - |
| item keys (5) | accountant C16 · archive C14 · certificate C15 · banks C17 · extras C18 | - |
| item fallback (5) | absent C19 · empty C19 · unknown C19 · missing A1 C19 · none incomplete C19 | - |
| `edit=` (3) | accountant C21 · package_archive C22 · bank_account C23 | - |
| success redirect `item=` (7) | accountant C27 · archive C27 · sefaz POST C27 · sefaz DELETE C27 · banks C27 · extras C27 · base exception C27 | - |
| auth (3) | unsigned C30 · no-focus C31 · submitter C32 | - |

- C1 is a capture comparison. No check claims more than the cases its proofs exercise.
- GET `/setup` keeps method, params, status, and who may call, except the success `Location` of standing writes gains `item=`. Unauthenticated and no-focus 302 stay on the existing examples named above.

## Swept

- validation: existing - accountant, package-archive, bank-account, extra-kind, and A1 422 still re-render `setup/show` with today’s notices; C21–C23 keep `edit=` opening the writable form
- failure modes: existing - those 422s render `setup/show`; load_setup keeps the item being written so the form with errors stays on the desk
- idempotency: existing - a second PATCH of the same accountant or archive still 302s; C27 keeps `item=` on that Location
- authorization: existing - submitter GET `/setup` 404; C32 omits Configuração on submitter home; C30 and C31 keep unsigned and no-focus 302
- concurrency: n/a - this change is a read of existing organization fields plus a query-selected item; writes still last-write-wins
- data lifecycle: n/a - nothing to migrate; accountant, archive, A1, bank accounts, and extra kinds are unchanged
- dependency failure: n/a - no new external call
- state transitions: C19, C20 (default item); C14, C15 (selected item); C21–C23 (`edit=`); C27 (redirect stays on the written item)
- observability: n/a - no logging or metrics criterion

## Handoff

- **Settled mid-build:** none
- **Dispatched:** Verifier at `382107c` (`2a54b4a..382107c`) returned FAIL (2 findings, closed at `b03e73d`); screens round 1 at `382107c` returned (diverges, 4 rows); screens round 2 at `b03e73d` returned (matches)
- **Boundary:**
- **Abandoned:** none
- **Walked:** Ambiente local `desk-walk@example.com`, focused organization `ONG Norte` (one organization, not the administrator), `GET /setup` at 1920×1080. Header brand `Fechamento Mensal - ONG Norte`; `Configuração` current; no org chip; no `Administração`. Left heading `Configuração`; five index rows Contador `Ana Contábil` Cadastrado, Arquivo do pacote `Pasta do Drive` Falta (red margin, aria-current), Certificado A1 `Consulta SEFAZ` Expirado (red margin), Contas bancárias `2 contas` Ativas, Tipos extras `Tarifa e honorário` `2 ativos`. Right pane h1 `Arquivo do pacote`, Drive subtitle, `Cole a URL da pasta do Google Drive` in margem, URL field with placeholder `https://drive.google.com/drive/folders/…`, `Salvar arquivo`. Saved `captures/setup-gaps.running.png`. Início still opens the two-pane month desk from the header. Item panes other than the capture default are request specs (`item=accountant|certificate|banks|extras` and `edit=`).
