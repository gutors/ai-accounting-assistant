# Unmatched documents in the package and restore month folder

Sources:

- `.tasks/unmatched-docs-and-restore.md` - this cut: criteria 1–45, doors, sweep, surface
- https://github.com/gutors/ai-accounting-assistant/issues/39 - coordinator chooses no-month documents for the package; restore the month folder from the closed month
- https://github.com/gutors/ai-accounting-assistant/issues/18#issuecomment-5625697017 - unmatched documents enter the monthly package; the package identifies which are unmatched; they do not block close
- https://github.com/gutors/ai-accounting-assistant/issues/18#issuecomment-5628194570 - which unmatched documents go is the coordinator’s choice; nothing enters alone
- https://github.com/gutors/ai-accounting-assistant/issues/19#issuecomment-5625697908 - restore rewrites the package-archive folder equal to the frozen month; does not thaw; not valid while open; reopen does not touch Drive
- https://github.com/gutors/ai-accounting-assistant/issues/20#issuecomment-5628193823 - month is born at confirmed match or when included at close-for-send; on reopen they stay until matched on it or returned
- https://github.com/gutors/ai-accounting-assistant/issues/22#issuecomment-5625699009 - third spreadsheet section; omitted when none; no total line
- https://github.com/gutors/ai-accounting-assistant/issues/23#issuecomment-5625700120 - tree `notas-sem-casamento/`; same filename stem as `notas/`
- `CONTEXT.md` - Unmatched document, Supporting document, Closed month, Month folder, Close-for-send, Monthly package, Summary spreadsheet
- `.specs/features/close-for-send/plan.md` Landing doors 2 and 4 - restore reuses `PackageArchiveWriter`; close stays in-request with the Month row lock
- `.specs/features/match-and-exception/plan.md` Landing door 4 - optional Month on SupportingDocument is the unmatched-in-package path
- `.tasks/assisted-suggestions.md` Out of scope - suggesting against a month assigned only at close-for-send is #39
- [ADR-0001](../docs/adr/0001-rails-8-hotwire.md) - Rails 8 + Hotwire; restore is the same long Puma request as close
- user delegated - month-page copy `Devolver` / `Restaurar pasta`; Turbo confirm on `Fechar para envio` (`Fechar o mês para envio?`), `Reabrir` (`Reabrir o mês?`), and `Restaurar pasta` (`Restaurar a pasta do mês no arquivo do pacote?`); `Devolver` has no extra confirm; close field `supporting_document_ids[]`
- user delegated - supporting-documents label `Sem casamento em YYYY-MM`; heading `Sem mês` stays
- user delegated - spreadsheet heading `Documentos sem casamento`; Tipo `Nota fiscal` / `Recibo`
- user delegated - restore rebuilds `MonthPackage.files` (live organization header, frozen month rows); no snapshot blob

No design source for the screens.

## Out of scope

- Email or any dispatch to the accountant - #6 / #17; coordinator still delivers
- Creating the package-archive folder or changing Drive ACL - #23
- Drive scopes on operator login; a second package-archive writer - ADR-0001; close-for-send door 2
- Open Finance JSON as a statement path - #16
- Storing a byte snapshot of the last close to replay on restore - working files stay on the blob store; restore rebuilds `MonthPackage.files` from the frozen month
- Submitter choosing unmatched documents into the package, restoring, or returning - coordinator-only, same as close
- Accountant login - accountant is not an operator
- N×M match, extra exception kinds, SEFAZ consulta - already shipped or other issues
- Restructuring `/supporting_documents` away from heading `Sem mês` - only the unmatched-in-package label in criterion 32

## Landing

Touches `Month#close_for_send` (selected unmatched documents assigned after a successful write), `MonthPackage#document_files`, `SummarySpreadsheet` third section, `Match.confirm` HAS_MONTH, `Suggestion::Assigner#groups`, the month unmatched pool, `POST /months/:year_month/restore`, and `POST .../supporting_documents/:id/return`. Reuses `PackageArchiveWriter.replace_month_folder`, `require_coordinator_organization`, existing `supporting_documents.month_id`, and close’s Month row lock.

| One-way door | Literal shape | Alternative rejected |
| --- | --- | --- |
| Unmatched-in-package is `month_id` set and `match_id` nil | Close that selects a no-month document, after a successful `replace_month_folder`, persists that document’s `month_id` to the Month in the same lock as `closed`. Return sets `month_id` nil while the Month is open and `match_id` is nil. Match confirm on that Month keeps `month_id`. Leave-match still nulls `month_id` (`Match#dissolve`). | A second column or close-inclusion join — match-and-exception door 4 reserved this optional Month for #39. Assign `month_id` before the writer — a Drive failure would leave documents of an open month with no folder (criterion 7). |
| Restore rewrites through `PackageArchiveWriter.replace_month_folder` in the request | `POST /months/:year_month/restore` holds the same Month row lock as close, calls `replace_month_folder(parent_id:, name:, folder_id: month_folder_id, files: MonthPackage.files(month))`, does not change `closed` or `month_folder_id`, enqueues no job. Only while `closed` is true. | A second Drive client in the restore action — close-for-send door 2. Active Job / a `closing` flag — #19 forbids a third state. Treating restore as POST close — close-while-closed is already `422` `Mês fechado`. |
| Spreadsheet unmatched section is third, after `Resultado mês`, omitted when empty | Sheet `{YYYY-MM}`. Heading `Documentos sem casamento`. Headers `Arquivo`, `Tipo`, `Valor`, `Data`, `Favorecido`, `Observação`. `Tipo` is `Nota fiscal` or `Recibo`. Amounts are Excel numerics like expenses (`155` for `15500` cents). No `SUM` over that section. Photo and XML in `Arquivo` joined with `; `. Rows by `document_on` then id. | Mixing unmatched rows into Custos/Despesas — #22 third section, does not feed totals. Putting the section before totals — would require excluding those rows from `SUM`. |
| Unmatched package files use folder `notas-sem-casamento/` and the existing stem | `{nota\|recibo}-{YYYY-MM-DD}-{parameterize(payee)}-{id}.{ext}` under `notas-sem-casamento/`. Matched documents stay under `notas/`. Folder omitted when no unmatched-in-package document has a blob. `id` is the SupportingDocument primary key. | A `sem-casamento-` filename prefix inside `notas/` — #23 the folder identifies. A generated UUID per close — re-close of an unchanged set would rename files. |

- Nothing else in this change is hard to reverse

Unresolved 1 stays open (none).

## Test policy

Follows `.cursor/rules/rails.mdc` (already answers both allocation questions):

| Code | Required proofs | Coverage expectation | Verdict |
| --- | --- | --- | --- |
| Decides, and is reached across a boundary | one at the model layer **and** one request spec at HTTP | one asserted case per enumerated member at the model; status / who may call at the boundary | follow |
| Decides, not reached across a boundary | one at the model layer | one asserted case per enumerated member | follow |
| Entry point that decides nothing | one request spec | accepted input, each rejected input, each error path | follow |
| Instrumentation / pass-through | none of its own | covered by its consumer | follow |

Evidence:

- `.cursor/rules/rails.mdc` lines 49–51 name the level and the sampling rule (one asserted case per enumerated member; HTTP also a request spec)
- `spec/models/month_spec.rb` + `spec/requests/close_spec.rb` — close blockers / writer failure / concurrent close is the closest analogue
- `spec/models/match_spec.rb` + `spec/requests/matches_spec.rb` — confirm / dissolve / HAS_MONTH sibling
- `spec/models/suggestion_spec.rb` + `spec/requests/months_spec.rb` — assignment vs GET copy
- `spec/requests/accesses_spec.rb` concurrent DELETE — two-session request race for C31 / C45
- MonthsController close/restore/return stay pass-through once Month and SupportingDocument decide, except other-org / missing-id `404`; HTTP status / who may call still need request specs

Cost: model specs for close assignment after write, selected-document rejects, restore self-loop, return, Match HAS_MONTH, Suggestion other-month exclusion, MonthPackage folder split, SummarySpreadsheet unmatched section; request specs for every status/route/copy claim below.

## Checks

### S1 - Unmatched documents in the monthly package · 24 files · 296 KB · ~74k

**C1** - Given open Month `2026-05` that is ready to close and an unmatched SupportingDocument with no month, kind `recibo`, payee `Padaria Central`, `amount_cents` `15500`, `document_on` `2026-05-11`, and a `.jpg` photo, when a coordinator POSTs `/months/2026-05/close` with `supporting_document_ids` of that document, then the response is `302` to `/months/2026-05`, the Month is closed, that document’s `month_id` is that Month and `match_id` is nil, and the writer files include `notas-sem-casamento/recibo-2026-05-11-padaria-central-{id}.jpg` and do not include that `{id}` under `notas/`
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with Padaria id assigns unmatched-in-package and writes notas-sem-casamento"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close with Padaria assigns month_id after a successful write"`
Proof: `bin/rspec spec/models/month_package_spec.rb -e "unmatched-in-package recibo path is notas-sem-casamento"`

**C2** - When that POST omits `supporting_document_ids` (or sends an empty list) while that Padaria document still has no month, then the response is `302`, that document’s `month_id` stays nil, and the writer files have no path starting with `notas-sem-casamento/`
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close omitting supporting_document_ids leaves Padaria with no month"`
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with empty supporting_document_ids leaves Padaria with no month"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close without documents leaves Padaria month_id nil"`

**C3** - Given no-month documents payees `Padaria Central` and `Mercado Silva`, when POST close includes only Padaria’s id, then Padaria’s `month_id` is the `2026-05` Month, Mercado’s `month_id` is nil, and the writer files include Padaria’s `notas-sem-casamento/` path and no path containing Mercado’s id
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with only Padaria id leaves Mercado with no month"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close with only Padaria leaves Mercado month_id nil"`

**C4** - If POST close includes a SupportingDocument id that exists only on organization B while focused on A, then the response is `404`, A’s Month stays open, B’s document `month_id` stays nil, and the writer is not invoked
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with another organization document id returns 404"`

**C5** - If POST close includes a document whose `month_id` is already Month `2026-06`, then the response is `422` with `Documento já pertence a um mês`, `2026-05` stays open, the June document is unchanged, and the writer is not invoked
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with June unmatched-in-package returns 422 Documento ja pertence a um mes"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close with a document of another month does not write"`

**C6** - If POST close includes a document that belongs to a Match, then the response is `422` with `Documento já está em um casamento`, the Month stays open, and the writer is not invoked
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close with a matched document returns 422 Documento ja esta em um casamento"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close with a matched document does not write"`

**C7** - If the package-archive writer raises during a close that selected Padaria, then the response is `422` with `Não foi possível gravar no arquivo do pacote`, the Month stays open, and Padaria’s `month_id` stays nil
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close selecting Padaria when writer raises leaves month_id nil"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close selecting Padaria when writer raises leaves month_id nil"`

**C8** - If POST close selects Padaria while a Payment of `22000` cents on that Month is still a missing document, then the response is `422` with `Há documento faltante`, Padaria’s `month_id` stays nil, and the writer is not invoked
Proof: `bin/rspec spec/requests/close_spec.rb -e "POST close selecting Padaria with missing document 22000 returns 422"`
Proof: `bin/rspec spec/models/month_spec.rb -e "close selecting Padaria with missing document does not assign month_id"`

**C9** - When `GET /months/2026-05` on an open Month lists unmatched no-month `Padaria Central`, then the response is `200`, the page includes `Documentos sem casamento`, includes `Padaria Central`, includes an input named `supporting_document_ids[]` whose value is that document’s id, and the `Fechar para envio` control uses Turbo confirm `Fechar o mês para envio?`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET open month lists Padaria close checkbox and Fechar turbo confirm"`

**C10** - When `GET /months/2026-05` after a close that included Padaria, then the page includes `Mês fechado`, includes `Restaurar pasta`, includes `Reabrir`, includes `Padaria Central` under `Documentos sem casamento`, does not include `Fechar para envio`, does not include a later-inserted no-month payee `Mercado Silva`, the `Restaurar pasta` control uses Turbo confirm `Restaurar a pasta do mês no arquivo do pacote?`, and the `Reabrir` control uses Turbo confirm `Reabrir o mês?`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET closed month with unmatched Padaria includes Restaurar pasta and omits Mercado Silva"`

**C11** - If an unauthenticated request POSTs close with `supporting_document_ids`, then the response is `302` to `/login` and no `month_id` is written
Proof: `bin/rspec spec/requests/close_spec.rb -e "unauthenticated POST close with supporting_document_ids responds 302 to /login"`

**C12** - If a submitter POSTs close with `supporting_document_ids`, then the response is `404`, the Month stays open, and no `month_id` is written
Proof: `bin/rspec spec/requests/close_spec.rb -e "submitter POST close with supporting_document_ids returns 404"`

**C13** - When a coordinator POSTs reopen after a close that included Padaria, then the Month is open, the writer is not invoked, Padaria’s `month_id` is still that Month and `match_id` is nil, and `GET /months/2026-05` includes `Fechar para envio` with Turbo confirm `Fechar o mês para envio?`, includes `Devolver`, includes `Padaria Central`, and does not include `Restaurar pasta` or `Mês fechado`
Proof: `bin/rspec spec/requests/reopen_spec.rb -e "POST reopen after unmatched Padaria close keeps month_id and shows Devolver"`
Proof: `bin/rspec spec/models/month_spec.rb -e "reopen after unmatched Padaria close keeps month_id and does not write"`

**C14** - When a coordinator POSTs `/months/2026-05/supporting_documents/:id/return` for that Padaria while the Month is open, then Padaria’s `month_id` is nil, the response is `302` to `/months/2026-05`, and that page under `Documentos sem casamento` includes `Padaria Central` and does not include `Devolver` for that document
Proof: `bin/rspec spec/requests/month_returns_spec.rb -e "POST return Padaria while open clears month_id and omits Devolver"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "return unmatched-in-package Padaria clears month_id"`

**C15** - If that return POST happens while the Month is closed, then the response is `422` with `Mês fechado` and Padaria’s `month_id` stays
Proof: `bin/rspec spec/requests/month_returns_spec.rb -e "POST return while closed returns 422 Mes fechado"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "return while Month closed keeps month_id"`

**C16** - If an unauthenticated request POSTs return, then the response is `302` to `/login` and the document’s `month_id` stays
Proof: `bin/rspec spec/requests/month_returns_spec.rb -e "unauthenticated POST return responds 302 to /login"`

**C17** - If a submitter POSTs return, then the response is `404` and the document’s `month_id` stays
Proof: `bin/rspec spec/requests/month_returns_spec.rb -e "submitter POST return returns 404"`

**C18** - If that return POST is for a document that is in a Match on `2026-05`, or that has no month, or that belongs only to another organization, then the response is `404` and the document is unchanged
Proof: `bin/rspec spec/requests/month_returns_spec.rb -e "POST return of a matched document returns 404"`
Proof: `bin/rspec spec/requests/month_returns_spec.rb -e "POST return of a no-month document returns 404"`
Proof: `bin/rspec spec/requests/month_returns_spec.rb -e "POST return of another organization document returns 404"`

**C19** - Given Padaria unmatched-in-package on open `2026-05` and a missing-document Payment of `15500` cents on that Month, when a coordinator POSTs a format-1 Match of that Payment and Padaria, then the Match persists, Padaria’s `month_id` stays that Month, `GET /months/2026-05` includes `Casado` and does not include `Devolver` for Padaria, and `GET /supporting_documents` includes `Casado em 2026-05` and does not include `Sem casamento em 2026-05` for that row
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST format-1 Match of unmatched-in-package Padaria keeps month_id"`
Proof: `bin/rspec spec/models/match_spec.rb -e "confirm unmatched-in-package Padaria on the same month keeps month_id"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents after matching unmatched-in-package Padaria includes Casado em 2026-05"`

**C20** - If a coordinator POSTs a Match of May unmatched-in-package Padaria onto a Payment of open Month `2026-06`, then the response is `422` with `Documento já pertence a um mês` and no Match is persisted
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match of May unmatched-in-package Padaria onto June returns 422"`
Proof: `bin/rspec spec/models/match_spec.rb -e "confirm document of another month is HAS_MONTH"`

**C21** - While Padaria is unmatched-in-package of `2026-05`, `GET /months/2026-06` does not include `Padaria Central` under `Documentos sem casamento` and does not include an input `supporting_document_ids[]` whose value is Padaria’s id
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET June omits May unmatched-in-package Padaria from the pool"`

**C22** - When `2026-05` is reopened and closed again with no `supporting_document_ids`, then Padaria remains `month_id` of that Month with `match_id` nil, and the writer files again include `notas-sem-casamento/recibo-2026-05-11-padaria-central-{id}.jpg`
Proof: `bin/rspec spec/requests/close_spec.rb -e "re-close without ids keeps unmatched Padaria in notas-sem-casamento"`
Proof: `bin/rspec spec/models/month_spec.rb -e "re-close without documents keeps unmatched Padaria month_id"`

**C23** - When Padaria is returned and `2026-05` is closed with no `supporting_document_ids`, then Padaria’s `month_id` is nil and the writer files have no path containing Padaria’s id
Proof: `bin/rspec spec/requests/close_spec.rb -e "close after return omits Padaria from writer files"`

**C24** - Given Padaria unmatched-in-package of closed `2026-05` with `amount_cents` `22000`, and open `2026-06` with a missing-document Payment of `22000` cents whose history is `Pix enviado — Padaria Central`, when a coordinator GETs `/months/2026-06`, then that payment’s row includes `Documento faltante` and does not include `Sugestão`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET June does not suggest closed May unmatched-in-package Padaria"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "does not assign a document that belongs to another month"`

**C25** - Given `2026-05` closed with a `bank_fee` Payment of `22000` cents and Padaria unmatched-in-package of `22000` cents payee `Padaria Central`, when a coordinator reopens, DELETEs that document exception, and GETs `/months/2026-05`, then that payment’s row includes `Documento faltante`, `Sugestão`, and `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET reopened May suggests unmatched-in-package Padaria"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "assigns unmatched-in-package Padaria to a missing-document payment of the same month"`

**C26** - Given a Justification whose members are May unmatched-in-package Padaria and no-month `Mercado Silva`, when a coordinator GETs `/months/2026-06` that has a missing-document Payment of the justification amount, then that payment’s row does not include `Sugestão` together with `Padaria Central`
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET June does not suggest a justification that includes May unmatched Padaria"`
Proof: `bin/rspec spec/models/suggestion_spec.rb -e "does not assign a justification group that includes a document of another month"`

**C27** - When a coordinator DELETEs the Match that includes a document that had been unmatched-in-package, then that document’s `month_id` is nil
Proof: `bin/rspec spec/requests/matches_spec.rb -e "DELETE match of former unmatched-in-package Padaria clears month_id"`
Proof: `bin/rspec spec/models/match_spec.rb -e "dissolve of former unmatched-in-package Padaria clears month_id"`

**C28** - While `2026-05` is closed and Padaria is unmatched-in-package of it, a coordinator PATCH of payee `Mercado Silva` on Padaria leaves the payee unchanged and responds `422` with `Mês fechado`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH payee while unmatched-in-package of a closed month returns 422 Mes fechado"`

**C29** - When `2026-05` is open after reopen, a coordinator PATCH of Padaria payee `Mercado Silva` responds `302` and persists that payee
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH payee of unmatched-in-package Padaria while open persists Mercado Silva"`

**C30** - If a submitter PATCHes or DELETEs Padaria while it has `month_id`, then the document is unchanged and the response is `422` with `Documento já pertence a um mês`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter PATCH unmatched-in-package Padaria returns 422 Documento ja pertence a um mes"`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "submitter DELETE unmatched-in-package Padaria returns 422 Documento ja pertence a um mes"`

**C31** - If two concurrent POSTs close ready Months `2026-05` and `2026-06`, each with `supporting_document_ids` of the same no-month Padaria, then exactly one of those Months is closed, Padaria’s `month_id` is that Month, the other POST is `422` with `Documento já pertence a um mês`, and that other close does not invoke the writer
Proof: `bin/rspec spec/requests/close_spec.rb -e "concurrent close of May and June with the same Padaria closes exactly one"`
Proof: `bin/rspec spec/models/month_spec.rb -e "concurrent close of two months with the same Padaria assigns one month_id"`

**C32** - When `GET /supporting_documents` after a close that included Padaria, then that row includes `Sem casamento em 2026-05` and does not include `Casado em 2026-05`
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents after unmatched close includes Sem casamento em 2026-05"`

**C33** - When close includes that Padaria recibo with observation `pago em dinheiro`, the workbook sheet `2026-05` includes heading `Documentos sem casamento`, column headers `Arquivo`, `Tipo`, `Valor`, `Data`, `Favorecido`, `Observação` in that order, and a row with `notas-sem-casamento/recibo-2026-05-11-padaria-central-{id}.jpg`, `Recibo`, numeric `155`, `11/05/2026`, `Padaria Central`, `pago em dinheiro`, and that heading appears after the cell `Resultado mês`
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx unmatched section lists Padaria recibo after Resultado mes"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "unmatched recibo section is after Resultado mes with Recibo 155"`

**C34** - When the included document is `nota_fiscal` payee `Padaria Central` `document_on` `2026-05-11` with a `.jpg` photo and a `.xml`, that unmatched `Arquivo` cell equals `notas-sem-casamento/nota-2026-05-11-padaria-central-{id}.jpg; notas-sem-casamento/nota-2026-05-11-padaria-central-{id}.xml` and `Tipo` is `Nota fiscal`
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx unmatched nota fiscal Arquivo joins jpg and xml"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "unmatched nota fiscal Arquivo joins jpg and xml"`

**C35** - When two unmatched documents dated `2026-05-04` and `2026-05-20` are included, those unmatched rows appear in that date order
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "unmatched rows order by document_on then id"`

**C36** - When close includes no unmatched document, the workbook does not include `sem casamento`
Proof: `bin/rspec spec/requests/close_spec.rb -e "xlsx without unmatched documents omits sem casamento"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "workbook without unmatched documents omits sem casamento"`

**C37** - When close includes Padaria unmatched and a matched recibo `Mercado Silva` `document_on` `2026-05-11`, the writer files include `notas/recibo-2026-05-11-mercado-silva-{id}.jpg` and the unmatched section does not include Mercado Silva
Proof: `bin/rspec spec/requests/close_spec.rb -e "writer files keep matched Mercado under notas and omit it from unmatched"`
Proof: `bin/rspec spec/models/month_package_spec.rb -e "matched Mercado stays under notas when Padaria is unmatched-in-package"`
Proof: `bin/rspec spec/models/summary_spreadsheet_spec.rb -e "unmatched section omits matched Mercado Silva"`

### S2 - Restore the month folder · 6 files · 26 KB · ~7k

**C38** - Given closed `2026-05` with Padaria unmatched-in-package and a matched Mercado under `notas/`, when a coordinator POSTs `/months/2026-05/restore`, then the response is `302` to `/months/2026-05`, the Month stays closed, `month_folder_id` is unchanged, Padaria’s `month_id` is unchanged, no Active Job is enqueued, and the writer is invoked once with that `folder_id` and files that include Padaria’s `notas-sem-casamento/` path, Mercado’s `notas/` path, and `resumo-2026-05.xlsx`
Proof: `bin/rspec spec/requests/restore_spec.rb -e "POST restore closed month rewrites the same folder_id and stays closed"`
Proof: `bin/rspec spec/models/month_spec.rb -e "restore_month_folder rewrites the same folder_id and stays closed"`

**C39** - If POST restore while the Month is open, then the response is `422` with `Mês aberto` and the writer is not invoked
Proof: `bin/rspec spec/requests/restore_spec.rb -e "POST restore while open returns 422 Mes aberto"`
Proof: `bin/rspec spec/models/month_spec.rb -e "restore_month_folder while open does not write"`

**C40** - If the writer raises on restore, then the response is `422` with `Não foi possível gravar no arquivo do pacote`, the Month stays closed, and `month_folder_id` is unchanged
Proof: `bin/rspec spec/requests/restore_spec.rb -e "POST restore when writer raises returns 422 and keeps folder_id"`
Proof: `bin/rspec spec/models/month_spec.rb -e "restore_month_folder when writer raises keeps folder_id"`

**C41** - If an unauthenticated request POSTs restore, then the response is `302` to `/login` and the writer is not invoked
Proof: `bin/rspec spec/requests/restore_spec.rb -e "unauthenticated POST restore responds 302 to /login"`

**C42** - If a submitter POSTs restore, then the response is `404`, the Month stays closed, and the writer is not invoked
Proof: `bin/rspec spec/requests/restore_spec.rb -e "submitter POST restore returns 404"`

**C43** - If a coordinator focused on organization A POSTs restore for a closed `2026-05` that exists only on organization B, then B stays closed, B’s writer is not invoked, and the response is `404`
Proof: `bin/rspec spec/requests/restore_spec.rb -e "POST restore of another organization month returns 404"`

**C44** - If POST restore for a year_month that was never opened, then the response is `404`
Proof: `bin/rspec spec/requests/restore_spec.rb -e "POST restore of never-opened 2026-04 returns 404"`

**C45** - If two concurrent POSTs restore the same closed `2026-05`, then the Month stays closed, `month_folder_id` is unchanged, and both responses are `302`
Proof: `bin/rspec spec/requests/restore_spec.rb -e "concurrent POST restore both return 302 and keep folder_id"`
Proof: `bin/rspec spec/models/month_spec.rb -e "concurrent restore_month_folder keeps closed and folder_id"`

## Swept

- validation: C5, C6, C8, C18 - selected ids must be focused-org, no month, no Match; return only unmatched-in-package of that Month
- failure modes: C7, C40 - writer raise leaves assignment and closedness unchanged
- idempotency and retry: C2, C22 - omitting ids on first close includes none; omitting ids on re-close keeps already-assigned unmatched-in-package; restore may run again (C45)
- authorization: C11, C12, C16, C17, C41, C42, C43 - existing `require_coordinator_organization` (`302` `/login`, submitter `404`); other org `404`
- concurrency and ordering: C31, C45 - two months cannot take the same no-month document; two restores leave the month closed with the same folder id
- data lifecycle: C13, C14, C22, C27, C30 - reopen keeps `month_id`; return and leave-match clear it; submitter cannot withdraw once assigned; no TTL; no backfill of existing no-month rows
- external-dependency failure: C7, C40 - `PackageArchiveWriter::Error` is `422` `Não foi possível gravar no arquivo do pacote`
- state transitions: C1, C13, C14, C19, C27, C38 - restore is a self-loop on closed
- observability: existing - close/restore failures surface as `@month_error` on the month page; no new metric. C38 - restore enqueues no job

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| close selected-document rejects (4) | other org C4 · HAS_MONTH C5 · in Match C6 · missing document C8 | - |
| close auth (2) | unauthenticated C11 · submitter C12 | - |
| unmatched-in-package transitions (8) | close assigns C1 · omit ids C2 · reopen keeps C13 · return C14 · match same month C19 · match other month C20 · re-close keeps C22 · dissolve C27 | - |
| return 404 members (3) | in Match C18 · no month C18 · other org C18 | - |
| return auth (2) | unauthenticated C16 · submitter C17 | - |
| return closed vs open (2) | open 302 C14 · closed 422 C15 | - |
| package folders (3) | unmatched prefix C1 · omit when empty C2 · matched `notas/` C37 | - |
| spreadsheet unmatched section (4) | headers and recibo row C33 · nota fiscal jpg+xml C34 · date order C35 · omitted C36 | - |
| Tipo copy (2) | `Recibo` C33 · `Nota fiscal` C34 | - |
| Suggestion vs assigned month (3) | other month no suggest C24 · same month suggests C25 · mixed justification C26 | - |
| submitter mutate with `month_id` (2) | PATCH C30 · DELETE C30 | - |
| coordinator PATCH closed vs open (2) | closed C28 · open C29 | - |
| restore rejects (6) | open C39 · writer fail C40 · unauthenticated C41 · submitter C42 · other org C43 · never opened C44 | - |
| concurrency (2) | two months one document C31 · two restores C45 | - |
| startup config assemblies | no new process setting | - |

- Claims naming a status code, route or response shape: C1–C23, C27–C32, C38–C45 - each has a request-spec proof that crosses the boundary
- No other check claims more than the single case its proof exercises

## Handoff

S1 ~74k (close, package, match, suggestion, pool, return; reads existing `months_spec` / `supporting_documents_spec` / `close_spec`) + S2 ~7k (restore). Total ~81k under 150k. Surface changes at S2 (`POST /restore`) but the running total never reaches the budget, so no split.
