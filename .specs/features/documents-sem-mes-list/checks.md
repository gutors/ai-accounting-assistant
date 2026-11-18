# Documents Sem mês list, filters, sorting, and action icons checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/documents-sem-mes-list/plan.md`

15 checks in 4 slices · 0 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.

## Checks

### S1 - Sem mês excludes matched documents and keeps unmatched ones

**C1** - When a document is confirmed in a `Match` (`match_id` present), `GET /supporting_documents` responds `200` and `#sem-mes` does not include that document for a coordinator or for the submitter who inserted it (AC 1)
Proof: `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents excludes matched documents from Sem mes"`

**C2** - When a document has `match_id: nil` and `month_id: nil`, `GET /supporting_documents` includes it in `#sem-mes` (AC 2)
Proof: `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents includes unmatched document with no month"`

**C3** - When a document has `match_id: nil` and belongs to a closed month package (`month_id` present), `GET /supporting_documents` for a coordinator includes it in `#sem-mes` with `Sem casamento em 2026-05` (AC 3)
Proof: `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents includes unmatched closed-package document with Sem casamento"`

### S2 - Filtering by payee, kind, and date range

**C4** - `SupportingDocument.filter_list(q:)` matches `payee` case-insensitively (`q: "padaria"` and `q: "PADARIA"` return `Padaria Central`; `q: "Inexistente"` returns empty; `q: "100%"` escapes SQL wildcards) (AC 4)
Proof: `bin/rspec spec/models/supporting_document_filter_list_spec.rb -e "filter_list filters by payee substring case-insensitively and escapes wildcards"`

**C5** - `SupportingDocument.filter_list(kind:)` returns only `nota_fiscal` when `kind: "nota_fiscal"`, only `recibo` when `kind: "recibo"`, and ignores unknown values like `"outro"` (AC 5)
Proof: `bin/rspec spec/models/supporting_document_filter_list_spec.rb -e "filter_list filters by valid kind and ignores unknown kind"`

**C6** - `SupportingDocument.filter_list(date_from:, date_to:)` filters `document_on >= date_from` and `document_on <= date_to` inclusive on boundaries and ignores invalid date strings without error (AC 6)
Proof: `bin/rspec spec/models/supporting_document_filter_list_spec.rb -e "filter_list filters by date_from and date_to inclusive and ignores invalid dates"`

**C7** - `GET /supporting_documents` with `q`, `kind`, `date_from`, and `date_to` filters `#sem-mes` accordingly and renders the `Limpar` link when any filter is active (AC 4, AC 5, AC 6, AC 7)
Proof: `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents filters Sem mes by q kind and date range and shows Limpar"`

### S3 - Sorting by date and amount

**C8** - `SupportingDocument.filter_list` orders by `document_on DESC, id DESC` by default, `document_on ASC, id ASC` for `sort: "date", dir: "asc"`, `amount_cents DESC, id DESC` for `sort: "amount", dir: "desc"`, and `amount_cents ASC, id ASC` for `sort: "amount", dir: "asc"` (AC 8, AC 9, AC 10, AC 11)
Proof: `bin/rspec spec/models/supporting_document_filter_list_spec.rb -e "filter_list orders by date and amount ascending and descending"`

**C9** - `GET /supporting_documents` default sort sets `aria-sort="descending"` on `Data`, links `Data` to `sort=date&dir=asc`, and orders rows newest-first (AC 8)
Proof: `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents defaults to date descending with sort header links"`

**C10** - `GET /supporting_documents?sort=date&dir=asc` sets `aria-sort="ascending"` on `Data` and orders rows oldest-first (AC 9)
Proof: `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents sorts by date ascending"`

**C11** - `GET /supporting_documents?sort=amount&dir=desc` and `GET /supporting_documents?sort=amount&dir=asc` set `aria-sort` on `Valor` and order rows by amount descending and ascending while preserving active filter params in header links (AC 10, AC 11, AC 12)
Proof: `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents sorts by amount desc and asc and preserves filter params"`

### S4 - Reusable action icons for Editar and Excluir

**C12** - In `#sem-mes`, each document's `[data-cell=actions]` renders an `Editar` link (`aria-label="Editar"`, `title="Editar"`) with an inline `<svg>` and, when `month_id` is nil, an `Excluir` button (`aria-label="Excluir"`, `title="Excluir"`, `data-turbo-confirm="Excluir este documento?"`) with an inline `<svg>` (AC 13, AC 14)
Proof: `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents renders SVG icon actions for Editar and Excluir"`

**C13** - In `#sem-mes`, a document with `month_id` present (`Sem casamento em 2026-05`) renders the `Editar` icon link and omits the `Excluir` button (AC 13, AC 14)
Proof: `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents omits Excluir icon when document belongs to a month"`

**C14** - Submitter justification checkboxes in `Vários documentos, um valor` remain populated with the submitter's eligible documents even when `#sem-mes` filter returns no rows (Changes underneath)
Proof: `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "submitter justification checkboxes remain available when Sem mes filter matches nothing"`

**C15** - Unauthenticated `GET /supporting_documents` responds `302` to `/login` (Surface)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET /supporting_documents responds 302 to /login"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| document match states in Sem mês (3) | matched (`match_id` present) C1 · unmatched no month C2 · unmatched in closed month package C3 | - |
| payee filter cases (4) | lowercase match C4 · uppercase match C4 · non-matching C4 · wildcard literal `%` C4 | - |
| kind filter values (3) | `nota_fiscal` C5 · `recibo` C5 · invalid `"outro"` C5 | - |
| date filter cases (4) | `date_from` boundary C6 · `date_to` boundary C6 · combined range C6 · invalid date string C6 | - |
| sort combinations (4) | `date desc` C8, C9 · `date asc` C8, C10 · `amount desc` C8, C11 · `amount asc` C8, C11 | - |
| row action icon states (2) | `month_id` nil (`Editar` + `Excluir` SVGs) C12 · `month_id` present (`Editar` SVG only) C13 | - |
| `GET /supporting_documents` statuses (2) | 200 C1 · 302 C15 | - |

## Swept

- validation: C4, C5, C6, C8 - SQL LIKE wildcard escaping, kind enum whitelist, ISO date rescue, sort/dir whitelist
- failure modes: C6 - malformed `date_from`/`date_to` or unknown `sort`/`kind` fall back cleanly without 500
- idempotency: n/a - `GET /supporting_documents` filtering and sorting are read-only
- authorization: C1, C15 - existing organization/submitter scoping and unauthenticated `302` to `/login`
- concurrency: n/a - read-only query parameters on list load
- data lifecycle: C1, C3 - matched documents remain in their `Match`/`Month` while excluded from `#sem-mes`; unmatched package documents stay visible
- dependency failure: n/a - local database query only
- state transitions: C1, C3 - confirming a match removes the document from `#sem-mes`; undoing a match returns it to `match_id: nil` so it reappears
- observability: n/a - standard Rails request logging

## Handoff

- **Settled mid-build:** none
- **Dispatched:** Verifier at `4d71ecf` returned
- **Boundary:** C1-C15 closed at `2dac52c`
- **Abandoned:** extracted `SupportingDocument::FilterList` and `SupportingDocument::SefazConfirm` to keep `app/models/supporting_document.rb` under the 5000-token limit
- **Walked:** Signed in on `/login` via Ambiente local (`gutors@gmail.com`) and opened `/supporting_documents`. Verified `#sem-mes` renders the reusable filter bar (`Favorecido`, `Tipo`, `De`, `Até`, `Filtrar`), sortable column headers (`Data` ↓ and `Valor` ↕), and SVG action icons (`Editar` pencil in `caixa`, `Excluir` trash in `margem`), excluding matched documents. Filtered with `q=Farmácia` and `sort=amount&dir=asc`, confirming only `Farmácia São José` (`R$ 89,40`) is listed and the `Limpar` link appears.
