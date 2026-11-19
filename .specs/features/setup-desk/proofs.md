# setup-desk proofs

**HEAD**: b03e73d
**Tree**: clean
**Result**: 47 pass, 0 fail; mutations 3 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `browser - reach that coordinator setup, save captures/setup-gaps.running.png at 1920×1080` | - | - | pass |
| C2 | `bin/rspec spec/requests/layout_spec.rb -e "GET /setup Configuracao has aria-current page"` | count unknown | - | pass |
| C3 | `bin/rspec spec/requests/layout_spec.rb -e "GET / Inicio is the only principal nav link with aria-current page"` | count unknown | - | pass |
| C4 | `bin/rspec spec/requests/setup_desk_spec.rb -e "setup index lists five items in order"` | count unknown | - | pass |
| C5 | `bin/rspec spec/requests/setup_desk_spec.rb -e "complete Contador row is Cadastrado without red margin"` | count unknown | - | pass |
| C6 | `bin/rspec spec/requests/setup_desk_spec.rb -e "blank archive row is Falta in margem with red margin"` | count unknown | - | pass |
| C7 | `bin/rspec spec/requests/setup_desk_spec.rb -e "expired A1 row is Expirado in margem with red margin"` | count unknown | - | pass |
| C8 | `bin/rspec spec/requests/setup_desk_spec.rb -e "missing A1 row is Falta in margem with red margin"` | count unknown | - | pass |
| C9 | `bin/rspec spec/requests/setup_desk_spec.rb -e "valid A1 row is Instalado without red margin"` | count unknown | - | pass |
| C10 | `bin/rspec spec/requests/setup_desk_spec.rb -e "two bank accounts row is 2 contas Ativas without red margin"` | count unknown | - | pass |
| C11 | `bin/rspec spec/requests/setup_desk_spec.rb -e "zero bank accounts row is Falta in margem with red margin"` | count unknown | - | pass |
| C12 | `bin/rspec spec/requests/setup_desk_spec.rb -e "two active extras row is 2 ativos without red margin"` | count unknown | - | pass |
| C13 | `bin/rspec spec/models/setup_desk_spec.rb -e "extras is never incomplete"` | count unknown | - | pass |
| C13 | `bin/rspec spec/requests/setup_desk_spec.rb -e "Tipos extras row never takes the red margin"` | count unknown | - | pass |
| C33 | `bin/rspec spec/requests/setup_desk_spec.rb -e "blank Contador row is Falta in margem with red margin"` | count unknown | - | pass |
| C14 | `bin/rspec spec/requests/setup_desk_spec.rb -e "Arquivo do pacote row is GET item archive"` | count unknown | - | pass |
| C15 | `bin/rspec spec/requests/setup_desk_spec.rb -e "item certificate marks Certificado A1 current and h1"` | count unknown | - | pass |
| C16 | `bin/rspec spec/requests/setup_desk_spec.rb -e "item accountant cadastro has h1 Contador"` | count unknown | - | pass |
| C16 | `bin/rspec spec/requests/setup_desk_spec.rb -e "item accountant leitura has h1 Contador"` | count unknown | - | pass |
| C17 | `bin/rspec spec/requests/setup_desk_spec.rb -e "item banks has h1 Contas bancarias sheet and Adicionar conta"` | count unknown | - | pass |
| C18 | `bin/rspec spec/requests/setup_desk_spec.rb -e "item extras has h1 Tipos extras sheet and Adicionar tipo extra"` | count unknown | - | pass |
| C19 | `bin/rspec spec/models/setup_desk_spec.rb -e "absent item selects first incomplete"` | count unknown | - | pass |
| C19 | `bin/rspec spec/models/setup_desk_spec.rb -e "empty item selects first incomplete"` | count unknown | - | pass |
| C19 | `bin/rspec spec/models/setup_desk_spec.rb -e "unknown item selects first incomplete"` | count unknown | - | pass |
| C19 | `bin/rspec spec/models/setup_desk_spec.rb -e "complete setup selects accountant"` | count unknown | - | pass |
| C19 | `bin/rspec spec/models/setup_desk_spec.rb -e "missing A1 after complete accountant and archive selects certific` | count unknown | - | pass |
| C20 | `bin/rspec spec/requests/setup_desk_spec.rb -e "default GET setup selects archive when it is the first Falta"` | count unknown | - | pass |
| C21 | `bin/rspec spec/requests/setup_desk_spec.rb -e "edit accountant selects Contador and opens the writable form"` | count unknown | - | pass |
| C22 | `bin/rspec spec/requests/setup_desk_spec.rb -e "edit package_archive selects Arquivo and opens the writable for` | count unknown | - | pass |
| C23 | `bin/rspec spec/requests/setup_desk_spec.rb -e "edit bank_account selects Contas and opens that row form"` | count unknown | - | pass |
| C24 | `bin/rspec spec/requests/setup_desk_spec.rb -e "blank archive pane Cole a URL in margem and Salvar arquivo"` | count unknown | - | pass |
| C25 | `bin/rspec spec/requests/setup_desk_spec.rb -e "missing A1 pane includes the empty install line"` | count unknown | - | pass |
| C26 | `bin/rspec spec/requests/setup_desk_spec.rb -e "blank Contador pane includes Cadastre o contador"` | count unknown | - | pass |
| C27 | `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant names the saved accountant in the toast"` | count unknown | - | pass |
| C27 | `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive toasts the saved package folder"` | count unknown | - | pass |
| C27 | `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "POST /sefaz_certificate names the titular and validity ` | count unknown | - | pass |
| C27 | `bin/rspec spec/requests/sefaz_certificates_spec.rb -e "DELETE /sefaz_certificate names the removed titular in ` | count unknown | - | pass |
| C27 | `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST /bank_accounts names the created account in the toast"` | count unknown | - | pass |
| C27 | `bin/rspec spec/requests/extra_exception_kinds_spec.rb -e "POST /extra_exception_kinds names the created kind i` | count unknown | - | pass |
| C27 | `bin/rspec spec/requests/base_document_exceptions_spec.rb -e "PATCH bank_fee inactive names the deactivated exc` | count unknown | - | pass |
| C28 | `bin/rspec spec/requests/setup_desk_spec.rb -e "setup omits stacked chapter headings and space-y-12"` | count unknown | - | pass |
| C29 | `bin/rspec spec/requests/setup_desk_spec.rb -e "setup main is a two-column grid with first column 26rem"` | count unknown | - | pass |
| C30 | `bin/rspec spec/requests/setup_spec.rb -e "unauthenticated GET /setup responds 302 to /login"` | count unknown | - | pass |
| C31 | `bin/rspec spec/requests/setup_spec.rb -e "GET /setup without focus responds 302 to /login"` | count unknown | - | pass |
| C32 | `bin/rspec spec/requests/layout_spec.rb -e "submitter header omits Configuracao and /setup"` | count unknown | - | pass |
| Build | `bin/rubocop` | - | - | pass |
| Build | `bin/erb_lint --lint-all` | - | - | pass |

## Mutations

| Mutation | Location | Killed |
| --- | --- | --- |
| extras never incomplete -> always incomplete | `app/models/setup_desk.rb:49` | yes |
| expired A1 no longer incomplete | `app/models/setup_desk.rb:47` | yes |
| complete-setup fallback accountant -> archive | `app/models/setup_desk.rb:65` | yes |
