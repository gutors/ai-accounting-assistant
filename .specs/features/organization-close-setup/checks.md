# Organization close setup checks

Profile: standard
Plan: `.specs/features/organization-close-setup/plan.md`

50 checks in 4 slices · 4 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.

## Checks

### S1 - Accountant and package destination · door 1

**C1** - Unauthenticated `GET /setup` responds `302` to `/login` (ACCT-01, AC 1)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "unauthenticated GET /setup responds 302 to /login"`

**C2** - `GET /setup` with a session and no focused organization responds `302` to `/login` (ACCT-01, AC 2)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup without focus responds 302 to /login"`

**C3** - Authenticated `GET /` includes a link whose text is `Configuração` and whose href is `/setup` (ACCT-01, AC 3)
Proof: `bin/rspec spec/requests/organizations_spec.rb -e "organization home links Configuracao to /setup"`

**C4** - Authenticated `GET /setup` responds `200`, uses locale `pt-BR`, and includes headings `Contador`, `Arquivo do pacote`, and `Contas bancárias` (ACCT-01, AC 4)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup responds 200 with pt-BR headings"`

**C5** - `GET /setup` includes `Cadastre o contador` when the focused organization has no accountant presentation name (ACCT-01, AC 5)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup empty accountant includes Cadastre o contador"`

**C6** - `PATCH /accountant` with a non-blank presentation name persists the trimmed name on the Organization, responds `302` to `/setup`, and `GET /setup` includes that name (ACCT-01, AC 6, door 1)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant persists presentation name and redirects"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "persists trimmed accountant presentation name"`

**C7** - `PATCH /accountant` with presentation name, CNPJ `11222333000181`, and razão social persists digits `11222333000181` and the trimmed razão social and responds `302` to `/setup` (ACCT-01, AC 7, door 1)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant persists CNPJ digits and razao social"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "persists CNPJ digits and razao social"`

**C8** - `PATCH /accountant` with presentation name and CPF `39053344705` and no razão social persists digits `39053344705`, persists no razão social, and responds `302` to `/setup` (ACCT-01, AC 8, door 1)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant persists CPF digits and no razao social"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "persists CPF digits and no razao social"`

**C9** - `PATCH /accountant` with presentation name and destination `Coord@Example.COM` persists `coord@example.com` and responds `302` to `/setup` (ACCT-01, AC 9, door 1)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant persists normalized destination email"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "persists destination email via NormalizedEmail"`

**C10** - `PATCH /accountant` with presentation name and a PIX key of 1 character or of 77 characters persists the trimmed key and responds `302` to `/setup` (ACCT-01, AC 10)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant persists PIX of 1 and 77 characters"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "persists PIX of 1 and 77 characters"`

**C11** - `PATCH /accountant` with presentation name and blank tax id, razão social, PIX, and destination email clears those four fields and responds `302` to `/setup` (ACCT-01, AC 11)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant blank optional fields clears them"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "blank optional accountant fields clear them"`

**C12** - `PATCH /accountant` with blank presentation name and any of tax id, razão social, PIX, or destination email persists none of those fields and responds `422` (ACCT-01, AC 12)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant without presentation name returns 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "rejects satellite accountant fields without presentation name"`

**C13** - `PATCH /accountant` with presentation name and a tax id that is not 11 or 14 digits after stripping non-digits, or whose módulo-11 check digits are invalid, leaves the organization unchanged and responds `422` for each of: 10 digits `1234567890`, CPF `39053344700`, CNPJ `11222333000180` (ACCT-01, AC 13)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant rejected tax ids return 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "rejects tax id length and check digits"`

**C14** - `PATCH /accountant` with presentation name, CNPJ `11222333000181`, and blank razão social leaves the organization unchanged and responds `422` (ACCT-01, AC 14)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant CNPJ without razao social returns 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "rejects CNPJ without razao social"`

**C15** - `PATCH /accountant` with presentation name, CPF `39053344705`, and a non-blank razão social leaves the organization unchanged and responds `422` (ACCT-01, AC 15)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant CPF with razao social returns 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "rejects CPF with razao social"`

**C16** - `PATCH /accountant` with presentation name and destination `not-an-email` leaves the destination unchanged and responds `422` (ACCT-01, AC 16)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "PATCH /accountant invalid destination returns 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "rejects destination that fails NormalizedEmail"`

**C17** - Unauthenticated `PATCH /accountant` persists no accountant fields and responds `302` to `/login` (ACCT-01, AC 17)
Proof: `bin/rspec spec/requests/accountants_spec.rb -e "unauthenticated PATCH /accountant responds 302 to /login"`

**C18** - `GET /setup` while focused on organization A does not include organization B’s accountant presentation name (ACCT-01, AC 18)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup does not include another organization accountant name"`

### S2 - Package archive URL · door 2

**C19** - `GET /setup` includes `Cole a URL da pasta do Drive` when the focused organization has no package archive URL (ARCH-01, AC 19)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup empty archive includes Cole a URL da pasta do Drive"`

**C20** - `PATCH /package_archive` with `https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl` persists that URL, persists folder id `15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl`, responds `302` to `/setup`, and `GET /setup` includes that URL (ARCH-01, AC 20, door 2)
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive persists folders URL and folder id"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "persists Drive folders URL and extracted folder id"`

**C21** - `PATCH /package_archive` with `https://drive.google.com/drive/u/0/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl?usp=sharing` persists folder id `15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl` and responds `302` to `/setup` (ARCH-01, AC 21, door 2)
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive persists folder id from u/0 URL with query"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "extracts folder id from drive/u/0/folders URL with query"`

**C22** - `PATCH /package_archive` with a blank URL persists no URL and no folder id and responds `302` to `/setup` (ARCH-01, AC 22)
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive blank URL clears url and folder id"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "blank archive URL clears url and folder id"`

**C23** - `PATCH /package_archive` with a URL that is not HTTPS on host `drive.google.com` with a `/folders/<id>` path segment leaves URL and folder id unchanged and responds `422` for each of: `http://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl`, `https://example.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl`, `https://drive.google.com/drive/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl` (ARCH-01, AC 23)
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive rejected folder URLs return 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "rejects http, wrong host, and missing folders segment"`

**C24** - `PATCH /package_archive` with `https://drive.google.com/file/d/0B_NiLAzvehC9R2stRmQyM3ZiVjQ/view` leaves URL and folder id unchanged and responds `422` (ARCH-01, AC 24)
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "PATCH /package_archive file URL returns 422"`
Proof: `bin/rspec spec/models/organization_spec.rb -e "rejects Drive file URL"`

**C25** - Unauthenticated `PATCH /package_archive` persists no URL and responds `302` to `/login` (ARCH-01, AC 25)
Proof: `bin/rspec spec/requests/package_archives_spec.rb -e "unauthenticated PATCH /package_archive responds 302 to /login"`

**C26** - `GET /setup` while focused on organization A does not include organization B’s package archive URL (ARCH-01, AC 26)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup does not include another organization archive URL"`

### S3 - Bank accounts from the catalog · door 3 · door 4

**C27** - The bank catalog persists exactly these 12 entries (presentation name · COMPE · ISPB): Banco do Brasil · `001` · `00000000`; PagBank/PagSeguro · `290` · `08561701`; Caixa · `104` · `00360305`; Itaú · `341` · `60701190`; Bradesco · `237` · `60746948`; Santander · `033` · `90400888`; Sicredi · `748` · `01181521`; Sicoob · `756` · `02038232`; Nubank · `260` · `18236120`; Inter · `077` · `00416968`; Banrisul · `041` · `92702067`; Unicred · `136` · `00315557` (BANK-01, AC 27, door 3)
Proof: `bin/rspec spec/models/bank_spec.rb -e "catalog is the twelve institutions from COMPE 001 through 756"`

**C28** - `GET /setup` lists those 12 presentation names in COMPE ascending order (`001`, `033`, `041`, `077`, `104`, `136`, `237`, `260`, `290`, `341`, `748`, `756`) and does not include `Outro` (BANK-01, AC 28)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "bank picker lists twelve names in COMPE order without Outro"`

**C29** - `GET /setup` includes `Nenhuma conta bancária` when the focused organization has zero bank accounts (BANK-01, AC 29)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup with zero bank accounts includes Nenhuma conta bancaria"`

**C30** - `POST /bank_accounts` with a non-blank name and COMPE `001` persists one active BankAccount on the focused organization for Banco do Brasil, persists slug equal to `ActiveSupport::Inflector.parameterize(name)`, responds `302` to `/setup`, and `GET /setup` includes that name and `extrato-{slug}` (BANK-01, AC 30, door 4)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST /bank_accounts persists active Banco do Brasil account and redirects"`
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "create with COMPE 001 persists active account and parameterized slug"`

**C31** - `POST /bank_accounts` with name `BB agência 1234` and a catalog COMPE persists slug `bb-agencia-1234` and `GET /setup` includes `extrato-bb-agencia-1234` (BANK-01, AC 31)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST /bank_accounts BB agencia 1234 shows extrato-bb-agencia-1234"`
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "parameterize BB agencia 1234 is bb-agencia-1234"`

**C32** - `POST /bank_accounts` of a second row with a distinct name and the same COMPE as an existing one persists the second row (BANK-01, AC 32)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST /bank_accounts allows two accounts at the same bank"`
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "allows two accounts at the same Bank"`

**C33** - `POST /bank_accounts` with optional coordinates persists the trimmed coordinates and `GET /setup` includes that text (BANK-01, AC 33)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST /bank_accounts persists trimmed coordinates"`
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "persists trimmed coordinates"`

**C34** - `GET /setup` lists BankAccount names in ascending order (BANK-01, AC 34)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "GET /setup lists bank account names in ascending order"`

**C35** - `PATCH /bank_accounts/:id` of the focused organization to a distinct valid name persists the new name and the new parameterized slug and responds `302` to `/setup` (BANK-01, AC 35)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "PATCH /bank_accounts/:id updates name and slug"`
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "updating name regenerates slug"`

**C36** - `POST /bank_accounts` and `PATCH /bank_accounts/:id` with a name that parameterizes to the same slug as another BankAccount of that organization persist no additional colliding BankAccount and respond `422` (BANK-01, AC 36)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST and PATCH colliding slug return 422"`
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "rejects a name whose slug collides including inactive"`

**C37** - `POST /bank_accounts` with a name that parameterizes to an empty string persists no BankAccount and responds `422` (BANK-01, AC 37)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST /bank_accounts empty slug returns 422"`
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "rejects a name that parameterizes to empty"`

**C38** - `POST /bank_accounts` with COMPE `999` persists no BankAccount and responds `422` (BANK-01, AC 38)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "POST /bank_accounts unknown COMPE returns 422"`
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "rejects COMPE not in the catalog"`

**C39** - Two concurrent `POST /bank_accounts` with the same name and organization persist exactly one BankAccount (BANK-01, AC 39, door 4)
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "concurrent creates persist exactly one BankAccount"`

**C40** - Unauthenticated `POST /bank_accounts` persists no BankAccount and responds `302` to `/login` (BANK-01, AC 40)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "unauthenticated POST /bank_accounts responds 302 to /login"`

**C47** - Bank rejects a second row for the same COMPE (door 3)
Proof: `bin/rspec spec/models/bank_spec.rb -e "rejects a second Bank for the same COMPE"`

**C48** - Bank rejects a second row for the same ISPB (door 3)
Proof: `bin/rspec spec/models/bank_spec.rb -e "rejects a second Bank for the same ISPB"`

**C49** - BankAccount rejects a second row for the same name on the same organization when the existing row is inactive (door 4)
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "rejects duplicate name when the other account is inactive"`

### S4 - Inactive, never deleted, isolation · door 4

**C41** - `PATCH /bank_accounts/:id` to inactive keeps the row, responds `302` to `/setup`, and `GET /setup` includes its name and `Inativa` (BANK-02, AC 41)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "PATCH /bank_accounts/:id to inactive keeps row and shows Inativa"`
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "deactivate keeps the row"`

**C42** - `PATCH /bank_accounts/:id` from inactive to active results in `GET /setup` including its name and not including `Inativa` on that account’s row (BANK-02, AC 42)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "PATCH /bank_accounts/:id to active omits Inativa"`
Proof: `bin/rspec spec/models/bank_account_spec.rb -e "reactivate sets active true"`

**C43** - `GET /setup` includes `Desativar` on an active BankAccount row and `Reativar` on an inactive row, and includes no delete control for that row (BANK-02, AC 43)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup shows Desativar or Reativar and no delete control"`

**C44** - `DELETE /bank_accounts/:id` leaves the BankAccount row in place and responds `404` (BANK-02, AC 44, door 4)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "DELETE /bank_accounts/:id returns 404 and keeps the row"`

**C45** - `PATCH /bank_accounts/:id` for a BankAccount not on the focused organization leaves that row unchanged and responds `404` (BANK-02, AC 45)
Proof: `bin/rspec spec/requests/bank_accounts_spec.rb -e "PATCH /bank_accounts/:id of another organization returns 404"`

**C46** - `GET /setup` while focused on organization A does not list BankAccount names that belong only to organization B (BANK-02, AC 46)
Proof: `bin/rspec spec/requests/setup_spec.rb -e "setup does not list another organization bank account names"`

**C50** - Unauthenticated `GET /` responds `302` to `/login` (Surface `GET /`)
Proof: `bin/rspec spec/requests/sessions_spec.rb -e "unauthenticated GET / responds 302 to /login"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| `GET /` statuses (2) | 200 C3 · 302 C50 | - |
| `GET /setup` statuses (2) | 200 C4 · 302 C1 | - |
| `PATCH /accountant` statuses (2) | 302 C6 · 422 C12 | - |
| accountant rejection reasons (5) | no name C12 · invalid tax id C13 · CNPJ without razão C14 · CPF with razão C15 · invalid email C16 | - |
| tax id rejects (3) | 10 digits C13 · bad CPF check digits C13 · bad CNPJ check digits C13 | - |
| tax id accepts (2) | CNPJ C7 · CPF C8 | - |
| PIX length accepts (2) | 1 C10 · 77 C10 | - |
| `PATCH /package_archive` statuses (2) | 302 C20 · 422 C23 | - |
| archive URL accepts (2) | `/drive/folders/<id>` C20 · `/drive/u/0/folders/<id>?query` C21 | - |
| archive URL rejects (4) | http C23 · wrong host C23 · missing `/folders/` C23 · `/file/d/` C24 | - |
| `POST /bank_accounts` statuses (2) | 302 C30 · 422 C36 | - |
| `PATCH /bank_accounts/:id` statuses (3) | 302 C35 · 422 C36 · 404 C45 | - |
| `DELETE /bank_accounts/:id` statuses (1) | 404 C44 | - |
| bank catalog (12) | C27, table-driven over all 12 | - |
| bank picker COMPE order (12) | C28, table-driven over all 12 | - |
| BankAccount create rejects (3) | colliding slug C36 · empty slug C37 · unknown COMPE `999` C38 | - |
| Bank uniqueness (2) | COMPE C47 · ISPB C48 | - |
| BankAccount uniqueness (2) | name including inactive C49 · slug including inactive C36 | - |
| BankAccount active (3) | create active C30 · deactivate C41 · reactivate C42 | - |
| slug collision verbs (2) | POST C36 · PATCH C36 | - |
| Relations entities (3) | Organization C6 · Bank C27 · BankAccount C30 | - |
| Landing doors (4) | accountant fields C6 · archive folder id C20 · catalog C27 · never-delete BankAccount C44 | - |
| startup config: bank catalog seed (1 assembly) | migration-seeded `banks` loaded by the Rails test app C27 | - |

- Claims naming a status code, route or response shape: C1, C2, C3, C4, C6, C12, C17, C20, C23, C25, C30, C35, C36, C37, C38, C40, C41, C44, C45, C50 - each has a proof that crosses the HTTP boundary
- No other check claims more than the single case its proof exercises, except C10 (2 PIX lengths), C13 (3 tax-id rejects), C23 (3 URL rejects), C27 (12 catalog rows), C28 (12 picker names), C36 (POST and PATCH slug collision), each table-driven over the whole set

## Test policy

`.cursor/rules/rails.mdc` already answers which level proves which code and how much of the input space counts. This build runs under those rows; they are not proposed as a new guideline commit.

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Decides, reached across a boundary | one at the boundary **and** one at its own layer | the contract at the boundary; one asserted case per row of the decision table at its own layer |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member |
| Entry point that decides nothing | one at the boundary | accepted input, each rejected input, each error path |
| Instrumentation, pass-throughs | none of its own | covered by its consumer's proof |

Evidence (classified from the approved plan):

- Organization accountant update: 8 outcomes (name, CNPJ+razão, CPF, destination, PIX, clear optionals, reject without name, reject tax id / CNPJ-razão / CPF-razão / email) -> decides, reached across `PATCH /accountant`
- Package archive URL parse: 6 outcomes (folders URL, u/0 URL, blank clear, http, wrong host, missing folders, file URL) -> decides, reached across `PATCH /package_archive`
- Bank catalog: 12 members plus unique COMPE and unique ISPB -> decides, not reached as a write across a coordinator boundary (seed/migration); proven at own layer C27, C47, C48; picker is the read boundary C28
- BankAccount create/update: persist, slug, same-bank duplicate allowed, coordinates, rename, slug collision, empty slug, unknown COMPE, concurrent name, active/inactive -> decides, reached across `POST`/`PATCH /bank_accounts`
- closest analogue in the repo: `spec/models/invite_spec.rb` + `spec/requests/coordinator_invites_spec.rb` — unique pending Invite, concurrent create, 422 at the HTTP boundary

Cost: dual proofs on accountant PATCH (C6–C16), archive PATCH (C20–C24), BankAccount create/update (C30–C38, C41–C42). Without those own-layer proofs the decision tables would be proven only by a path that happens to traverse them.

## Swept

- validation: C10, C13, C16, C23, C37, C38
- failure modes: C12, C14, C15, C24, C36
- idempotency: C22, C39
- authorization: C1, C2, C17, C25, C40, C45
- concurrency: C39
- data lifecycle: C11, C22, C41, C44 - optional fields and archive URL clear; BankAccount deactivated, never deleted
- dependency failure: n/a - no Drive API or other remote call in this cut
- state transitions: C30, C41, C42
- observability: n/a - no logging or metrics criterion in the plan

## Handoff

- S1–S4 share `/setup` and the focused organization. Estimated ~20 product/spec files, well under 150k tokens. One builder, no split.
- S1-S4 = one builder
- **Boundary:** C1-C50 proofs green
- **Settled mid-build:** none
- **Abandoned:** `rack.session` env hash cannot stand in for Rails 8 encrypted session in a request spec; C2 uses a signed-in Account whose Access rows were deleted so `focused_organization` is nil.
