# Preserve list scroll position checks

Mutations: 3
Build: `bin/rubocop`; `bin/erb_lint --lint-all`
Plan: `.specs/features/list-scroll-position/plan.md`

<12 checks in 1 slice · 0 one-way doors · 0 open, of which 0 block>

## Checks

### S1 - Update lists in place

**C1** - Sem mês sorts by Data and Valor, updates its URL, preserves the inclusion form, and retains vertical scroll within 1 px (AC 1)
Proof: `bin/rspec spec/system/list_scroll_position_spec.rb -e "sorts Sem mês by Data and Valor in place"`

**C2** - Sem mês applies and clears a filter while retaining the URL, the matching results, and vertical scroll within 1 px of the reachable offset (AC 2)
Proof: `bin/rspec spec/system/list_scroll_position_spec.rb -e "filters and clears Sem mês in place"`

**C3** - Sorting each month list updates URL and order, retains scroll within 1 px of the reachable offset, and keeps the folds as set by the coordinator (AC 3)
Proof: `bin/rspec spec/system/list_scroll_position_spec.rb -e "sorts all three month lists in place"`

**C4** - Changing the month account updates results and the Casar pagamentos link and retains vertical scroll within 1 px of the reachable offset (AC 4)
Proof: `bin/rspec spec/system/list_scroll_position_spec.rb -e "changes and clears the month account in place"`

**C5** - Keyboard focus returns to the activated control or to Favorecido after Limpar disappears, without changing scroll (AC 5)
Proof: `bin/rspec spec/system/list_scroll_position_spec.rb -e "returns keyboard focus after a list update"`

**C6** - Back, Forward, and reload show the sort state indicated by the URL (AC 6)
Proof: `bin/rspec spec/system/list_scroll_position_spec.rb -e "restores list results through history and reload"`

**C7** - An expired session during a frame update opens the full login page (AC 7)
Proof: `bin/rspec spec/system/list_scroll_position_spec.rb -e "opens the full login page after session expiry"`

**C8** - The coordinator month GET returns 200 (Surface)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 responds 200 with pt-BR and 2026-05"`

**C9** - The month GET returns 404 when the focused account is a submitter (Surface)
Proof: `bin/rspec spec/requests/months_spec.rb -e "submitter focus GET /months/2026-05 responds 404"`

**C10** - A document index GET returns 200 to the coordinator and submitter scopes (Surface)
Proof: `bin/rspec spec/requests/supporting_documents_sem_mes_spec.rb -e "GET /supporting_documents excludes matched documents from Sem mes"`

**C11** - An unauthenticated document index GET returns 302 to login (Surface)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET /supporting_documents responds 302 to /login"`

**C12** - An unauthenticated month GET returns 302 to login (Surface)
Proof: `bin/rspec spec/requests/months_spec.rb -e "unauthenticated GET /months/2026-05 responds 302 to /login"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| list surfaces (4) | Sem mês C1, C2 · Pagamentos C3 · Recebimentos C3 · Documentos sem casamento C3 | - |
| filter actions (4) | Filtrar C2 · Limpar C2 · bank account C4 · Todas C4 | - |
| viewport (2) | same offset C1, C3 · shortened page C2, C4 | - |
| browser state (4) | focus C5 · folds C3 · history and reload C6 · expired session C7 | - |
| `GET /months/:year_month` statuses (3) | 200 C8 · 302 C12 · 404 C9 | - |
| `GET /supporting_documents` statuses (2) | 200 C10 · 302 C7, C11 | - |

## Swept

- validation: existing - Rails normalizes filter and sort parameters
- failure modes: C7 covers an authentication redirect
- idempotency: existing - list GETs are read-only
- authorization: C7 and existing Rails action guards
- concurrency: existing - Turbo manages pending frame requests
- data lifecycle: C1 preserves the document inclusion form
- dependency failure: existing - Turbo handles request transport errors
- state transitions: C3, C5, C6
- observability: existing - Rails request logs

## Handoff

- **Settled mid-build:** none
- **Dispatched:** Verifier at `7a645ba` returned
- **Walked:** Signed in through Ambiente local in the in-app browser. Sorted Sem mês by Data with scroll at 55 px and Pagamentos by Valor with scroll at 286 px. Both requests changed row order and URL and kept those offsets.
- **Boundary:** C1-C12 at `7a645ba`, with proof fixes at `ec5f226`
