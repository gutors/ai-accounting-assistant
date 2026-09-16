# Organization close setup verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: 1b5180c..HEAD
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

User walk skipped: HTML request-spec feature; no human UI walk required.

Proofs always re-run in full at HEAD `b63adc89a5ce62b4b60b7539a092b27412d4a51f`: one `bin/rspec` invocation over the nine proof files plus every named `-e` selector — 76 examples, 0 failures. Every named example existed (`rg -n` / `it "..."` hit, 76/76) and appeared as passed in that run.

Fix scoped against `spec/requests/setup_spec.rb` only (C28). Citations for that file are verified at `b63adc8`. Other files’ assertion citations are carried from `31a1874`.

## Binding sources

carried from `31a1874`. Step 1 is `ui` only. Plan: "No design source for the screens. Verification stays on project profile `standard` (no binding screen, so not `ui`)." Fix did not touch the interface. Did not drop to light.

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| n/a — no binding screen | n/a | none | - |

## Checks

Proofs verified at `b63adc8`. `spec/requests/setup_spec.rb` citations verified at `b63adc8`. Other evidence carried from `31a1874`.

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | unauthenticated GET /setup is 302 to /login | batch exit 0; `-e "unauthenticated GET /setup responds 302 to /login"` passed | `spec/requests/setup_spec.rb:7` - `expect(response).to have_http_status(:found)` ; `spec/requests/setup_spec.rb:8` - `expect(response).to redirect_to("/login")` | PASS |
| C2 | GET /setup without focus is 302 to /login | batch exit 0; `-e "GET /setup without focus responds 302 to /login"` passed | `spec/requests/setup_spec.rb:20` - `expect(response).to have_http_status(:found)` ; `spec/requests/setup_spec.rb:21` - `expect(response).to redirect_to("/login")` | PASS |
| C3 | GET / includes Configuração linking to /setup | batch exit 0; `-e "organization home links Configuracao to /setup"` passed | `spec/requests/organizations_spec.rb:71` - `expect(response).to have_http_status(:ok)` ; `spec/requests/organizations_spec.rb:72` - `expect(response.body).to include("Configuração")` ; `spec/requests/organizations_spec.rb:73` - `expect(response.body).to include('href="/setup"')` | PASS |
| C4 | GET /setup is 200, pt-BR, three headings | batch exit 0; `-e "GET /setup responds 200 with pt-BR headings"` passed | `spec/requests/setup_spec.rb:30` - `expect(response).to have_http_status(:ok)` ; `spec/requests/setup_spec.rb:31` - `expect(response.body).to include('lang="pt-BR"')` ; `spec/requests/setup_spec.rb:32-34` - include `"Contador"`, `"Arquivo do pacote"`, `"Contas bancárias"` | PASS |
| C5 | empty accountant includes Cadastre o contador | batch exit 0; `-e "GET /setup empty accountant includes Cadastre o contador"` passed | `spec/requests/setup_spec.rb:43` - `expect(response.body).to include("Cadastre o contador")` | PASS |
| C6 | PATCH /accountant persists trimmed name, 302 /setup | batch exit 0; both `-e` passed | `spec/requests/accountants_spec.rb:10-12` - `:found`, `redirect_to("/setup")`, `eq("Ana Contábil")` ; `spec/requests/accountants_spec.rb:15` - `include("Ana Contábil")` ; `spec/models/organization_spec.rb:8` - `eq("Ana Contábil")` | PASS |
| C7 | PATCH /accountant persists CNPJ `11222333000181` and razão, 302 | batch exit 0; both `-e` passed | `spec/requests/accountants_spec.rb:28-30` - `:found`, `eq("11222333000181")`, `eq("Contábil LTDA")` ; `spec/models/organization_spec.rb:19-20` - same digits and trimmed razão | PASS |
| C8 | PATCH /accountant persists CPF `39053344705`, no razão, 302 | batch exit 0; both `-e` passed | `spec/requests/accountants_spec.rb:39-41` - `:found`, `eq("39053344705")`, `be_nil` legal name ; `spec/models/organization_spec.rb:27-28` - same | PASS |
| C9 | PATCH /accountant persists `coord@example.com`, 302 | batch exit 0; both `-e` passed | `spec/requests/accountants_spec.rb:50-51` - `:found`, `eq("coord@example.com")` ; `spec/models/organization_spec.rb:35` - `eq("coord@example.com")` | PASS |
| C10 | PIX of 1 and 77 characters persist, 302 | batch exit 0; both `-e` passed | `spec/requests/accountants_spec.rb:59-65` - `:found`, `eq("x")`, `eq(seventy_seven)` with `seventy_seven = "p" * 77` ; `spec/models/organization_spec.rb:42-46` - same | PASS |
| C11 | blank optionals clear tax id, razão, PIX, destination, 302 | batch exit 0; both `-e` passed | `spec/requests/accountants_spec.rb:81-86` - `:found`, four fields `be_nil` ; `spec/models/organization_spec.rb:60-63` - four fields `be_nil` | PASS |
| C12 | no presentation name persists none, 422 | batch exit 0; both `-e` passed | `spec/requests/accountants_spec.rb:95-99` - `:unprocessable_content`, tax/pix/destination `be_nil` ; `spec/models/organization_spec.rb:74-79` - `update_accountant` `be(false)` and four fields `be_nil` for each satellite | PASS |
| C13 | tax ids `1234567890`, `39053344700`, `11222333000180` leave org unchanged, 422 | batch exit 0; both `-e` passed | `spec/requests/accountants_spec.rb:106-109` - each id `:unprocessable_content`, `accountant_tax_id` `be_nil` ; `spec/models/organization_spec.rb:87-93` - same three ids, `be(false)`, tax id `be_nil` | PASS |
| C14 | CNPJ `11222333000181` without razão unchanged, 422 | batch exit 0; both `-e` passed | `spec/requests/accountants_spec.rb:119-120` - `:unprocessable_content`, tax id `be_nil` ; `spec/models/organization_spec.rb:101-102` - `be(false)`, tax id `be_nil` | PASS |
| C15 | CPF `39053344705` with razão unchanged, 422 | batch exit 0; both `-e` passed | `spec/requests/accountants_spec.rb:133-134` - `:unprocessable_content`, tax id `be_nil` ; `spec/models/organization_spec.rb:109-115` - `be(false)`, tax id and legal name `be_nil` | PASS |
| C16 | destination `not-an-email` leaves destination, 422 | batch exit 0; both `-e` passed | `spec/requests/accountants_spec.rb:144-145` - `:unprocessable_content`, `eq("ana@example.com")` ; `spec/models/organization_spec.rb:122-123` - `be(false)`, `eq("ana@example.com")` | PASS |
| C17 | unauthenticated PATCH /accountant persists none, 302 /login | batch exit 0; `-e "unauthenticated PATCH /accountant responds 302 to /login"` passed | `spec/requests/accountants_spec.rb:151` - `not_to change` named-org count ; `spec/requests/accountants_spec.rb:153-154` - `:found`, `redirect_to("/login")` | PASS |
| C18 | setup omits other org accountant name | batch exit 0; `-e "setup does not include another organization accountant name"` passed | `spec/requests/setup_spec.rb:55` - `expect(response.body).not_to include("Contador Beta")` | PASS |
| C19 | empty archive includes Cole a URL da pasta do Drive | batch exit 0; `-e "GET /setup empty archive includes Cole a URL da pasta do Drive"` passed | `spec/requests/setup_spec.rb:64` - `expect(response.body).to include("Cole a URL da pasta do Drive")` | PASS |
| C20 | folders URL persists URL and id `15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl`, 302, shown | batch exit 0; both `-e` passed | `spec/requests/package_archives_spec.rb:12-19` - `:found`, `redirect_to("/setup")`, url/id eqs, `include(folders_url)` ; `spec/models/organization_spec.rb:131-132` - url and id eqs | PASS |
| C21 | u/0 folders URL with query persists folder id, 302 | batch exit 0; both `-e` passed | `spec/requests/package_archives_spec.rb:29-30` - `:found`, `eq("15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")` ; `spec/models/organization_spec.rb:140` - same id | PASS |
| C22 | blank archive URL clears url and folder id, 302 | batch exit 0; both `-e` passed | `spec/requests/package_archives_spec.rb:40-43` - `:found`, url and folder id `be_nil` ; `spec/models/organization_spec.rb:148-149` - both `be_nil` | PASS |
| C23 | http, wrong host, missing /folders/ unchanged, 422 | batch exit 0; both `-e` passed | `spec/requests/package_archives_spec.rb:51-60` - three URLs, `:unprocessable_content`, url/id unchanged ; `spec/models/organization_spec.rb:157-165` - same three URLs, `be(false)`, url/id unchanged | PASS |
| C24 | Drive file URL unchanged, 422 | batch exit 0; both `-e` passed | `spec/requests/package_archives_spec.rb:71-72` - `:unprocessable_content`, url unchanged ; `spec/models/organization_spec.rb:174-176` - `be(false)`, url unchanged | PASS |
| C25 | unauthenticated PATCH /package_archive persists no URL, 302 /login | batch exit 0; `-e "unauthenticated PATCH /package_archive responds 302 to /login"` passed | `spec/requests/package_archives_spec.rb:78-80` - `:found`, `redirect_to("/login")`, `Organization.where.not(package_archive_url: nil).count` `eq(0)` | PASS |
| C26 | setup omits other org archive URL | batch exit 0; `-e "setup does not include another organization archive URL"` passed | `spec/requests/setup_spec.rb:77` - `expect(response.body).not_to include(url)` | PASS |
| C27 | catalog is exactly the 12 name/COMPE/ISPB rows | batch exit 0; `-e "catalog is the twelve institutions from COMPE 001 through 756"` passed | `spec/models/bank_spec.rb:20` - `expect(Bank.count).to eq(12)` ; `spec/models/bank_spec.rb:21-24` - each of the 12 tuples `presentation_name`/`ispb` `eq` | PASS |
| C28 | picker lists the 12 names in COMPE order `001`…`756`, no Outro | batch exit 0; `-e "bank picker lists twelve names in COMPE order without Outro"` passed | `spec/requests/setup_spec.rb:89-102` - literal expected pairs `[COMPE, name]` for `001` Banco do Brasil, `033` Santander, `041` Banrisul, `077` Inter, `104` Caixa, `136` Unicred, `237` Bradesco, `260` Nubank, `290` PagBank/PagSeguro, `341` Itaú, `748` Sicredi, `756` Sicoob ; `spec/requests/setup_spec.rb:104` - `expect(options).to eq(expected)` on `select#compe` ; `spec/requests/setup_spec.rb:105` - `expect(response.body).not_to include("Outro")` | PASS |
| C29 | zero bank accounts includes Nenhuma conta bancária | batch exit 0; `-e "GET /setup with zero bank accounts includes Nenhuma conta bancaria"` passed | `spec/requests/setup_spec.rb:114` - `expect(response.body).to include("Nenhuma conta bancária")` | PASS |
| C30 | POST COMPE `001` persists active Banco do Brasil, parameterized slug, 302, extrato-{slug} | batch exit 0; both `-e` passed | `spec/requests/bank_accounts_spec.rb:10-19` - `:found`, `redirect_to("/setup")`, `be_active`, `eq("Banco do Brasil")`, `eq(ActiveSupport::Inflector.parameterize("Conta Principal"))`, includes name and `extrato-#{slug}` ; `spec/models/bank_account_spec.rb:11-15` - persisted, active, BB, parameterized slug | PASS |
| C31 | `BB agência 1234` slug `bb-agencia-1234`, setup shows extrato-bb-agencia-1234 | batch exit 0; both `-e` passed | `spec/requests/bank_accounts_spec.rb:28-30` - `eq("bb-agencia-1234")`, `include("extrato-bb-agencia-1234")` ; `spec/models/bank_account_spec.rb:21` - `eq("bb-agencia-1234")` | PASS |
| C32 | second account same COMPE persists | batch exit 0; both `-e` passed | `spec/requests/bank_accounts_spec.rb:40` - `eq(2)` ; `spec/models/bank_account_spec.rb:28-30` - both persisted, count `eq(2)` | PASS |
| C33 | trimmed coordinates persist and appear | batch exit 0; both `-e` passed | `spec/requests/bank_accounts_spec.rb:49-51` - `eq("ag 1234")`, `include("ag 1234")` ; `spec/models/bank_account_spec.rb:36` - `eq("ag 1234")` | PASS |
| C34 | GET /setup lists bank account names ascending | batch exit 0; `-e "GET /setup lists bank account names in ascending order"` passed | `spec/requests/setup_spec.rb:125` - `expect(response.body.index("Alfa")).to be < response.body.index("Zeta")` | PASS |
| C35 | PATCH name persists new name and slug, 302 /setup | batch exit 0; both `-e` passed | `spec/requests/bank_accounts_spec.rb:61-65` - `:found`, `redirect_to("/setup")`, `eq("Nova Conta")`, `eq("nova-conta")` ; `spec/models/bank_account_spec.rb:42-44` - `be(true)`, same name/slug | PASS |
| C36 | POST and PATCH colliding slug persist no extra row, 422 | batch exit 0; both `-e` passed | `spec/requests/bank_accounts_spec.rb:73-80` - POST `:unprocessable_content` count `eq(1)` ; PATCH `:unprocessable_content` name still `"Outra"` ; `spec/models/bank_account_spec.rb:51-55` - colliding `not_to be_persisted` ; `apply_from` `be(false)` including inactive | PASS |
| C37 | empty slug POST persists no BankAccount, 422 | batch exit 0; both `-e` passed | `spec/requests/bank_accounts_spec.rb:89-90` - `:unprocessable_content`, count `eq(0)` ; `spec/models/bank_account_spec.rb:61` - `not_to be_persisted` | PASS |
| C38 | COMPE `999` persists no BankAccount, 422 | batch exit 0; both `-e` passed | `spec/requests/bank_accounts_spec.rb:99-100` - `:unprocessable_content`, count `eq(0)` ; `spec/models/bank_account_spec.rb:67` - `not_to be_persisted` | PASS |
| C39 | concurrent same name persist exactly one | batch exit 0; `-e "concurrent creates persist exactly one BankAccount"` passed | `spec/models/bank_account_spec.rb:106` - `expect(BankAccount.where(organization: org, name: "Principal").count).to eq(1)` | PASS |
| C40 | unauthenticated POST /bank_accounts persists none, 302 /login | batch exit 0; `-e "unauthenticated POST /bank_accounts responds 302 to /login"` passed | `spec/requests/bank_accounts_spec.rb:106` - `not_to change(BankAccount, :count)` ; `spec/requests/bank_accounts_spec.rb:108-109` - `:found`, `redirect_to("/login")` | PASS |
| C47 | Bank rejects second COMPE | batch exit 0; `-e "rejects a second Bank for the same COMPE"` passed | `spec/models/bank_spec.rb:31` - `expect(duplicate).not_to be_valid` with `compe: "001"` | PASS |
| C48 | Bank rejects second ISPB | batch exit 0; `-e "rejects a second Bank for the same ISPB"` passed | `spec/models/bank_spec.rb:37` - `expect(duplicate).not_to be_valid` with `ispb: "00000000"` | PASS |
| C49 | BankAccount rejects duplicate name when other is inactive | batch exit 0; `-e "rejects duplicate name when the other account is inactive"` passed | `spec/models/bank_account_spec.rb:75` - `expect(duplicate).not_to be_persisted` | PASS |
| C41 | PATCH inactive keeps row, 302, shows name and Inativa | batch exit 0; both `-e` passed | `spec/requests/bank_accounts_spec.rb:119-125` - `:found`, `redirect_to("/setup")`, `not_to be_active`, include `"Principal"` and `"Inativa"` ; `spec/models/bank_account_spec.rb:81-82` - `be(true)`, `not_to be_active` | PASS |
| C42 | PATCH active omits Inativa on that account | batch exit 0; both `-e` passed | `spec/requests/bank_accounts_spec.rb:137-138` - include `"Principal"`, `not_to include("Inativa")` ; `spec/models/bank_account_spec.rb:89-90` - `be(true)`, `be_active` | PASS |
| C43 | Desativar or Reativar, no delete control | batch exit 0; `-e "setup shows Desativar or Reativar and no delete control"` passed | `spec/requests/setup_spec.rb:138-140` - include `"Desativar"`, `"Reativar"` ; `not_to include("Excluir")` | PASS |
| C44 | DELETE /bank_accounts/:id is 404 and keeps the row | batch exit 0; `-e "DELETE /bank_accounts/:id returns 404 and keeps the row"` passed | `spec/requests/bank_accounts_spec.rb:148-149` - `:not_found` ; `BankAccount.find(...)` `eq(bank_account)` | PASS |
| C45 | PATCH other-org bank account unchanged, 404 | batch exit 0; `-e "PATCH /bank_accounts/:id of another organization returns 404"` passed | `spec/requests/bank_accounts_spec.rb:160-161` - `:not_found` ; `eq("Alheia")` | PASS |
| C46 | setup omits other org bank account names | batch exit 0; `-e "setup does not list another organization bank account names"` passed | `spec/requests/setup_spec.rb:152` - `expect(response.body).not_to include("Conta Só B")` | PASS |
| C50 | unauthenticated GET / is 302 to /login | batch exit 0; `-e "unauthenticated GET / responds 302 to /login"` passed | `spec/requests/sessions_spec.rb:7` - `expect(response).to have_http_status(:found)` ; `spec/requests/sessions_spec.rb:8` - `expect(response).to redirect_to("/login")` (example not in `1b5180c..HEAD`; existing Surface status, ran at HEAD) | PASS |

## Coverage

bank picker COMPE order (12) recomputed at `b63adc8` from plan AC 28. Other rows carried from `31a1874` (fix could not change their authority).

| Set (size) | Recomputed from | Member -> proof | Unproven |
| --- | --- | --- | --- |
| GET / statuses (2) | plan Surface | 200 C3 · 302 C50 | - |
| GET /setup statuses (2) | plan Surface | 200 C4 · 302 C1 | - |
| PATCH /accountant statuses (2) | plan Surface | 302 C6 · 422 C12 | - |
| accountant rejection reasons (5) | plan AC 12-16 | no name C12 · invalid tax id C13 · CNPJ without razão C14 · CPF with razão C15 · invalid email C16 | - |
| tax id rejects (3) | plan AC 13 / C13 | 10 digits C13 · bad CPF check digits C13 · bad CNPJ check digits C13 | - |
| tax id accepts (2) | plan AC 7-8 | CNPJ C7 · CPF C8 | - |
| PIX length accepts (2) | plan AC 10 | 1 C10 · 77 C10 | - |
| PATCH /package_archive statuses (2) | plan Surface | 302 C20 · 422 C23 | - |
| archive URL accepts (2) | plan Landing door 2 | `/drive/folders/<id>` C20 · `/drive/u/0/folders/<id>?query` C21 | - |
| archive URL rejects (4) | plan AC 23-24 | http C23 · wrong host C23 · missing `/folders/` C23 · `/file/d/` C24 | - |
| POST /bank_accounts statuses (2) | plan Surface | 302 C30 · 422 C36 | - |
| PATCH /bank_accounts/:id statuses (3) | plan Surface | 302 C35 · 422 C36 · 404 C45 | - |
| DELETE /bank_accounts/:id statuses (1) | plan Surface | 404 C44 | - |
| bank catalog (12) | plan AC 27 | C27 table of all 12 name/COMPE/ISPB tuples | - |
| bank picker COMPE order (12) | plan AC 28 COMPE `001`,`033`,`041`,`077`,`104`,`136`,`237`,`260`,`290`,`341`,`748`,`756` and names Banco do Brasil, Santander, Banrisul, Inter, Caixa, Unicred, Bradesco, Nubank, PagBank/PagSeguro, Itaú, Sicredi, Sicoob | C28 `expect(options).to eq(expected)` on those 12 `[COMPE, name]` pairs in that order; `not_to include("Outro")` | - |
| BankAccount create rejects (3) | plan AC 36-38 | colliding slug C36 · empty slug C37 · unknown COMPE `999` C38 | - |
| Bank uniqueness (2) | plan Relations / door 3 | COMPE C47 · ISPB C48 | - |
| BankAccount uniqueness (2) | plan Relations / door 4 | name including inactive C49 · slug including inactive C36 | - |
| BankAccount active (3) | plan AC 30,41,42 | create active C30 · deactivate C41 · reactivate C42 | - |
| slug collision verbs (2) | plan AC 36 | POST C36 · PATCH C36 | - |
| Relations entities (3) | plan Relations | Organization C6 · Bank C27 · BankAccount C30 | - |
| Landing doors (4) | plan Landing | accountant fields C6 · archive folder id C20 · catalog C27 · never-delete BankAccount C44 | - |
| startup config: bank catalog seed (1 assembly) | Landing door 3; `db/migrate/20260916214500_create_organization_close_setup.rb:38` `Bank.seed_catalog!` ; `spec/rails_helper.rb:74` suite seed ; `db/seeds.rb:1` | C27 after test-app seed of `Bank::CATALOG` | - |

## Test policy rows

Bank catalog / picker-boundary row re-judged at `b63adc8` (classifies the C28 surface the fix touched). Other rows carried from `31a1874`. No unmet row from round 1 besides C28, which was an assertion-target miss rather than a dual-proof miss.

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decides, reached across a boundary | `app/models/organization.rb` accountant and archive; `app/models/bank_account.rb`; `app/controllers/accountants_controller.rb`; `app/controllers/package_archives_controller.rb`; `app/controllers/bank_accounts_controller.rb` | boundary + own layer: C6-C16, C20-C24, C30-C38, C41-C42 | yes |
| Decides, not reached across a boundary | `app/models/bank.rb` catalog uniqueness | own layer C27, C47, C48 (one row per catalog member at C27); picker read boundary C28 now asserts the 12 check-defined `[COMPE, name]` pairs | yes |
| Entry point that decides nothing | `app/controllers/setup_controller.rb` | boundary C1, C2, C4 | yes |
| Instrumentation, pass-throughs | `app/models/brazilian_tax_id.rb`; `app/models/drive_folder_url.rb`; `ApplicationController#load_setup` | none of their own; consumer C13/C23/C20/C28 | yes |

## Faults injected

verified at `b63adc8`. Real-tree `git status --porcelain` was empty before and after. Mutations ran in scratch worktree `/tmp/ocs-lean-verify-r2` at HEAD; scratch discarded. Scoped to the new C28 pair-equality surface (the only surface the fix created). Cap 5.

| Mutation | Location | Killed |
| --- | --- | --- |
| `Bank.ordered_catalog` `order(:compe)` -> `order(:presentation_name)` | `app/models/bank.rb:31` | yes |
| picker option value `:compe` -> `:presentation_name` | `app/views/setup/show.html.erb:85` | yes |
| append `<option value="999">Outro</option>` on `select#compe` | `app/views/setup/show.html.erb:85` | yes |
| `ordered_catalog` drops COMPE `756` | `app/models/bank.rb:31` | yes |
| `ordered_catalog` `order(compe: :desc)` | `app/models/bank.rb:31` | yes |

The round-1 surviving sort-key mutant now fails C28 at `spec/requests/setup_spec.rb:104` (`expect(options).to eq(expected)`).

## Swept existing

carried from `31a1874`. checks.md Swept has no `existing` rows (only check ids and `n/a`). Plan Observable `existing` for `/`: unauthenticated `/` is still 302 `/login` (`spec/requests/sessions_spec.rb:7-8`); revoke still confirms (`app/views/organizations/show.html.erb:30` `data-turbo-confirm`).

## Gate

`python3 .cursor/skills/tlc-spec-lean/scripts/validate_verification.py organization-close-setup` — exit 0: 0 errors, 0 warnings.
