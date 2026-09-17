# Match and document exception checks

Profile: standard
Plan: `.specs/features/match-and-exception/plan.md`

53 checks in 5 slices · 5 one-way doors · 0 open

Proofs use `bin/rspec` and `-e` as `.cursor/rules/rails.mdc` names. CI runs `bin/rspec`.

## Checks

### S1 - Missing document and the unmatched pool

**C1** - `GET /months/2026-05` with a Payment of `22000` cents and no Match and no document exception responds `200` and that payment’s row includes `Documento faltante` (MATCH-01, AC 1)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 unmatched payment includes Documento faltante"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "payment with no match and no exception is missing document"`

**C2** - `GET /months/2026-05` with zero Payments does not include `Documento faltante` (MATCH-01, AC 2)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 with zero Payments does not include Documento faltante"`

**C3** - `GET /months/2026-05` includes the heading `Documentos sem casamento` (MATCH-01, AC 3)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 includes Documentos sem casamento"`

**C4** - `GET /months/2026-05` includes `Nenhum documento sem casamento` when the focused organization has no SupportingDocument out of every Match (MATCH-01, AC 4)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 with no unmatched documents includes Nenhum documento sem casamento"`

**C5** - `GET /months/2026-05` includes `Padaria Central` under `Documentos sem casamento` when that unmatched SupportingDocument belongs to the focused organization (MATCH-01, AC 5)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 pool includes unmatched Padaria Central"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "unmatched documents of the organization include Padaria Central"`

**C6** - `GET /months/2026-05` while focused on organization A does not include payee text that exists only on organization B’s supporting documents (MATCH-01, AC 6)
Proof: `bin/rspec spec/requests/months_spec.rb -e "month unmatched pool does not include another organization payee"`

**C7** - `GET /supporting_documents` listing that unmatched document does not include `Casado em 2026-05` (MATCH-01, AC 7)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents unmatched document does not include Casado em 2026-05"`

**C8** - `GET /months/2026-05` `Recebimentos` section listing an Inflow does not include `Documento faltante` (MATCH-01, AC 8)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 Recebimentos does not include Documento faltante"`

**C44** - Unauthenticated `GET /months/2026-05` responds `302` to `/login` (Surface `GET /months/:year_month`)
Proof: `bin/rspec spec/requests/months_spec.rb -e "unauthenticated GET /months/2026-05 responds 302 to /login"`

**C45** - `GET /months/2026-05` with a session and no focused organization responds `302` to `/login` (Surface `GET /months/:year_month`)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 without focus responds 302 to /login"`

**C46** - `GET /months/2026-04` when that organization has no Month for `2026-04` responds `404` (Surface `GET /months/:year_month`)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-04 when never opened responds 404"`

**C47** - Authenticated `GET /supporting_documents` responds `200` (Surface `GET /supporting_documents`)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents responds 200 with pt-BR and Documentos de suporte"`

**C48** - Unauthenticated `GET /supporting_documents` responds `302` to `/login` (Surface `GET /supporting_documents`)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "unauthenticated GET /supporting_documents responds 302 to /login"`

### S2 - Confirm 1:N and leave the match · door 1 · door 2 · door 4

**C9** - `POST /months/2026-05/matches` with one Payment of `22000` cents and two unmatched documents of `10000` and `12000` cents, observation blank, persists one Match, responds `302` to `/months/2026-05`, and that page includes `Casado` on that payment and the two payees and does not include `Documento faltante` on that payment (MATCH-02, AC 9, door 1, door 2)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST 1 payment 2 documents persists Casado and redirects"`
Proof: `bin/rspec spec/models/match_spec.rb -e "confirm 1 payment 2 documents persists one Match"`

**C10** - After that confirm, `GET /supporting_documents` includes `Casado em 2026-05` for both documents (MATCH-02, AC 10, door 4)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "GET /supporting_documents after match includes Casado em 2026-05"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "confirm assigns Month 2026-05 on both documents"`

**C11** - After that confirm, `/months/2026-05` under `Documentos sem casamento` does not include those two payees (MATCH-02, AC 11)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match removes both payees from unmatched pool"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "matched documents are absent from unmatched list"`

**C12** - `POST /months/2026-05/matches` with one Payment of `22000` cents and one unmatched document of `20000` cents with observation `desconto não documentado` persists the Match, responds `302`, and `/months/2026-05` includes `desconto não documentado` (MATCH-02, AC 12)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST lesser with observation persists and shows desconto nao documentado"`
Proof: `bin/rspec spec/models/match_spec.rb -e "confirm lesser with observation persists the Match"`

**C13** - `POST /months/2026-05/matches` with one Payment of `22000` cents and one unmatched document of `20000` cents with observation blank persists no Match and responds `422` with `Informe a observação do casamento` (MATCH-02, AC 13)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST lesser without observation returns 422 Informe a observacao do casamento"`
Proof: `bin/rspec spec/models/match_spec.rb -e "rejects lesser without observation"`

**C14** - `POST /months/2026-05/matches` with one Payment of `22000` cents and one unmatched document of `25000` cents with observation blank persists the Match and responds `302` (MATCH-02, AC 14)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST greater without observation persists Match 302"`
Proof: `bin/rspec spec/models/match_spec.rb -e "confirm greater without observation persists the Match"`

**C15** - `POST /months/2026-05/matches` with one Payment of `22000` cents and one unmatched document of `22000` cents with observation blank persists the Match and responds `302` (MATCH-02, AC 15, door 2)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST 1 payment 1 document equal persists Match 302"`
Proof: `bin/rspec spec/models/match_spec.rb -e "confirm 1 payment 1 document persists one Match"`

**C16** - `POST /months/2026-05/matches` with one Payment and zero `supporting_document_ids` persists no Match and responds `422` with `Selecione ao menos um documento` (MATCH-02, AC 16, door 2)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST 1 payment 0 documents returns 422 Selecione ao menos um documento"`
Proof: `bin/rspec spec/models/match_spec.rb -e "rejects 1 payment 0 documents"`

**C17** - `DELETE /months/2026-05/matches/:id` persists no Match for those ids, responds `302` to `/months/2026-05`, that payment’s row includes `Documento faltante`, the documents appear again under `Documentos sem casamento`, and `GET /supporting_documents` does not include `Casado em 2026-05` for them (MATCH-02, AC 17, door 4)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "DELETE match returns payments to Documento faltante and documents to pool"`
Proof: `bin/rspec spec/models/match_spec.rb -e "destroying a Match clears document Month and match_id"`

**C18** - `POST /months/2026-05/matches` for a Payment that already belongs to a Match persists no second Match and responds `422` with `Pagamento já está em um casamento` (MATCH-02, AC 18, door 1)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match for already matched payment returns 422 Pagamento ja esta em um casamento"`
Proof: `bin/rspec spec/models/match_spec.rb -e "rejects a second Match on the same Payment"`

**C19** - `POST /months/2026-05/matches` that includes a SupportingDocument that already belongs to a Match persists no second Match and responds `422` with `Documento já está em um casamento` (MATCH-02, AC 19, door 1)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match for already matched document returns 422 Documento ja esta em um casamento"`
Proof: `bin/rspec spec/models/match_spec.rb -e "rejects a second Match on the same SupportingDocument"`

**C20** - Unauthenticated `POST /months/2026-05/matches` persists no Match and responds `302` to `/login` (MATCH-02, AC 20)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "unauthenticated POST /months/2026-05/matches responds 302 to /login"`

**C21** - Unauthenticated `DELETE /months/2026-05/matches/:id` leaves the Match in place and responds `302` to `/login` (MATCH-02, AC 21)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "unauthenticated DELETE match responds 302 to /login and keeps the Match"`

**C22** - `PATCH /supporting_documents/:id` with payee `Mercado Silva` on a SupportingDocument that belongs to a Match leaves the Match in place and `/months/2026-05` still includes `Casado` on that payment (MATCH-02, AC 22)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH payee on matched document keeps Casado"`
Proof: `bin/rspec spec/models/supporting_document_spec.rb -e "update payee on matched document keeps the Match"`

**C49** - `PATCH /supporting_documents/:id` with `kind=recibo` on a nota fiscal that has XML and no photo, without attaching a photo, responds `422` (Surface `PATCH /supporting_documents/:id`)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH kind recibo on xml-only nota_fiscal without photo returns 422 Envie a foto do recibo"`

**C50** - `PATCH /supporting_documents/:id` of an id that belongs only to organization B, while focused on organization A, responds `404` (Surface `PATCH /supporting_documents/:id`)
Proof: `bin/rspec spec/requests/supporting_documents_spec.rb -e "PATCH supporting_document of another organization returns 404"`

**C52** - `Payment` and `SupportingDocument` each allow at most one Match via unique `match_id` (door 1)
Proof: `bin/rspec spec/models/match_spec.rb -e "Payment and SupportingDocument unique match_id"`

### S3 - Confirm N:1; reject N×M · door 2

**C23** - `POST /months/2026-05/matches` with two unmatched Payments of `10000` and `12000` cents and one unmatched document of `22000` cents, observation blank, persists one Match, responds `302`, and both payment rows include `Casado` and do not include `Documento faltante` (MATCH-03, AC 23, door 2)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST 2 payments 1 document persists Casado on both"`
Proof: `bin/rspec spec/models/match_spec.rb -e "confirm 2 payments 1 document persists one Match"`

**C24** - `POST /months/2026-05/matches` with three unmatched Payments and one unmatched document whose cents equal the three payments’ sum, observation blank, persists one Match and responds `302` (MATCH-03, AC 24, door 2)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST 3 payments 1 document persists Match 302"`
Proof: `bin/rspec spec/models/match_spec.rb -e "confirm 3 payments 1 document persists one Match"`

**C25** - `POST /months/2026-05/matches` with two Payments and two SupportingDocuments persists no Match and responds `422` with `Casamento é um pagamento com um ou mais documentos, ou vários pagamentos com um documento` (MATCH-03, AC 25, door 2)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST 2 payments 2 documents returns 422 Casamento e um pagamento"`
Proof: `bin/rspec spec/models/match_spec.rb -e "rejects 2 payments 2 documents"`

**C26** - `POST /months/2026-05/matches` with zero Payments and one SupportingDocument persists no Match and responds `422` with `Selecione ao menos um pagamento` (MATCH-03, AC 26, door 2)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST 0 payments 1 document returns 422 Selecione ao menos um pagamento"`
Proof: `bin/rspec spec/models/match_spec.rb -e "rejects 0 payments 1 document"`

### S4 - Mark and unmark document exception · door 3

**C27** - `POST /months/2026-05/payments/:id/document_exception` with `kind=bank_fee` on a missing-document Payment persists the mark, responds `302` to `/months/2026-05`, and that payment’s row includes `Tarifa bancária` and does not include `Documento faltante` (EXC-01, AC 27, door 3)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST bank_fee persists Tarifa bancaria and redirects"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "mark bank_fee on missing-document payment"`

**C28** - `POST /months/2026-05/payments/:id/document_exception` with `kind=accountant_fee` on a missing-document Payment makes that payment’s row include `Honorário do contador` and not include `Documento faltante` (EXC-01, AC 28, door 3)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST accountant_fee persists Honorario do contador"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "mark accountant_fee on missing-document payment"`

**C29** - `DELETE /months/2026-05/payments/:id/document_exception` on a payment marked `bank_fee` persists no mark, responds `302`, and that row includes `Documento faltante` and does not include `Tarifa bancária` (EXC-01, AC 29)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "DELETE bank_fee returns Documento faltante"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "unmark bank_fee returns missing document"`

**C30** - `POST /months/2026-05/payments/:id/document_exception` with `kind` that is neither `bank_fee` nor `accountant_fee` persists no mark and responds `422` with `Informe se é tarifa bancária ou honorário do contador` (EXC-01, AC 30, door 3)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST kind doacao returns 422 Informe se e tarifa bancaria ou honorario do contador"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "rejects document_exception_kind that is not bank_fee or accountant_fee"`

**C31** - `POST /months/2026-05/payments/:id/document_exception` on a Payment that belongs to a Match leaves the Match in place, persists no mark, and responds `422` with `Desfaça o casamento antes de marcar a exceção` (EXC-01, AC 31, door 3)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST exception on matched payment returns 422 Desfaca o casamento"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "rejects bank_fee on a matched payment"`

**C32** - `POST /months/2026-05/matches` format-1 for a Payment marked `bank_fee` persists the Match, persists no `bank_fee` mark on that Payment, and `/months/2026-05` includes `Casado` and does not include `Tarifa bancária` on that payment (EXC-01, AC 32, door 3)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match on bank_fee payment clears Tarifa bancaria"`
Proof: `bin/rspec spec/models/match_spec.rb -e "confirm on bank_fee payment clears the mark"`

**C33** - Unauthenticated `POST /months/2026-05/payments/:id/document_exception` persists no mark and responds `302` to `/login` (EXC-01, AC 33)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "unauthenticated POST document_exception responds 302 to /login"`

**C34** - Unauthenticated `DELETE /months/2026-05/payments/:id/document_exception` leaves the mark in place and responds `302` to `/login` (EXC-01, AC 34)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "unauthenticated DELETE document_exception responds 302 to /login and keeps the mark"`

**C51** - `Payment.document_exception_kind` enum members are `bank_fee` and `accountant_fee` (door 3)
Proof: `bin/rspec spec/models/payment_spec.rb -e "document_exception_kind enum members are bank_fee and accountant_fee"`

**C53** - `DELETE /months/2026-05/payments/:id/document_exception` for a Payment that belongs only to organization B, while focused on organization A, leaves the mark in place and responds `404` (Surface `DELETE /months/:year_month/payments/:id/document_exception`)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "DELETE document_exception of another organization returns 404"`

### S5 - Isolation, replace, concurrency · door 1 · door 5

**C35** - `POST /months/2026-05/matches` with a Payment id that belongs only to organization B, while focused on organization A, leaves organization B unchanged and responds `404` (MATCH-04, AC 35)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match with another organization payment returns 404"`

**C36** - `POST /months/2026-05/matches` with a SupportingDocument id that belongs only to organization B, while focused on organization A, leaves organization B unchanged and responds `404` (MATCH-04, AC 36)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "POST match with another organization document returns 404"`

**C37** - `POST /months/2026-05/payments/:id/document_exception` for a Payment of Month `2026-04` persists no mark and responds `404` (MATCH-04, AC 37)
Proof: `bin/rspec spec/requests/document_exceptions_spec.rb -e "POST exception for payment of 2026-04 on 2026-05 returns 404"`

**C38** - `DELETE /months/2026-05/matches/:id` of a Match id that belongs only to organization B, while focused on organization A, leaves that Match in place and responds `404` (MATCH-04, AC 38)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "DELETE match of another organization returns 404"`

**C39** - Replacing the BankStatement whose Payments were the only members of a Match persists no Match for those former payments, and the SupportingDocuments of that Match appear under `Documentos sem casamento` and do not include `Casado em 2026-05` on `/supporting_documents` (MATCH-04, AC 39, door 5)
Proof: `bin/rspec spec/requests/bank_statements_spec.rb -e "POST replace dissolves Match and returns documents to pool"`
Proof: `bin/rspec spec/models/bank_statement_spec.rb -e "replace destroys Payments and their Match"`

**C40** - Two concurrent `POST /months/2026-05/matches` that include the same SupportingDocument persist exactly one Match that includes that document (MATCH-04, AC 40, door 1)
Proof: `bin/rspec spec/models/match_spec.rb -e "concurrent confirms sharing a document persist exactly one Match"`

**C41** - Two concurrent `POST /months/2026-05/matches` that include the same Payment persist exactly one Match that includes that payment (MATCH-04, AC 41, door 1)
Proof: `bin/rspec spec/models/match_spec.rb -e "concurrent confirms sharing a payment persist exactly one Match"`

**C42** - `GET /months/2026-05` does not include `Documento faltante` while every Payment of that Month belongs to a Match or has a document exception (MATCH-04, AC 42)
Proof: `bin/rspec spec/requests/months_spec.rb -e "GET /months/2026-05 with every payment resolved omits Documento faltante"`
Proof: `bin/rspec spec/models/payment_spec.rb -e "month has no missing document when every payment is matched or excepted"`

**C43** - `DELETE /months/2026-05/matches/:id` for an id that does not exist on that Month responds `404` (MATCH-04, AC 43)
Proof: `bin/rspec spec/requests/matches_spec.rb -e "DELETE missing match id returns 404"`

## Coverage

| Set (size) | Member -> proof | Unproven |
| --- | --- | --- |
| `GET /months/:year_month` statuses (3) | 200 C1 · 302 C44 · 404 C46 | - |
| `GET /months/:year_month` 302 reasons (2) | unauthenticated C44 · no focus C45 | - |
| `POST /months/:year_month/matches` statuses (3) | 302 C9 · 422 C13 · 404 C35 | - |
| `POST /months/:year_month/matches` 422 reasons (6) | lesser no observation C13 · 0 documents C16 · payment already matched C18 · document already matched C19 · N×M C25 · 0 payments C26 | - |
| `POST /months/:year_month/matches` 404 reasons (2) | other-org payment C35 · other-org document C36 | - |
| `DELETE /months/:year_month/matches/:id` statuses (2) | 302 C17 · 404 C43 | - |
| `DELETE /months/:year_month/matches/:id` 404 reasons (2) | other org C38 · missing id C43 | - |
| `POST /months/:year_month/payments/:id/document_exception` statuses (3) | 302 C27 · 422 C30 · 404 C37 | - |
| `POST /months/:year_month/payments/:id/document_exception` 422 reasons (2) | unknown kind C30 · already matched C31 | - |
| `DELETE /months/:year_month/payments/:id/document_exception` statuses (2) | 302 C29 · 404 C53 | - |
| `GET /supporting_documents` statuses (2) | 200 C47 · 302 C48 | - |
| `PATCH /supporting_documents/:id` statuses (3) | 302 C22 · 422 C49 · 404 C50 | - |
| Match shapes accepted (4) | 1:N C9 · 1:1 C15 · 2:1 C23 · 3:1 C24 | - |
| Match shapes rejected (3) | 0 documents C16 · 0 payments C26 · 2×2 C25 | - |
| Amount vs observation (4) | equal C15 · greater C14 · lesser with observation C12 · lesser without C13 | - |
| Payment trichotomy (3) | missing document C1 · matched C9 · exception C27 | - |
| Payment transitions (6) | missing→matched C9 · missing→exception C27 · exception→missing C29 · exception→matched C32 · matched→missing C17 · matched→exception forbidden C31 | - |
| Exception kinds (2) | `bank_fee` C27 · `accountant_fee` C28 | - |
| Exception kind enum (2) | C51, table-driven over all 2 | - |
| Unique match_id (2) | Payment C18 · SupportingDocument C19 | - |
| Relations entities (5) | Month C9 · Match C9 · Payment C9 · SupportingDocument C9 · Organization C6 | - |
| Landing doors (5) | Match entity C9 · shape 1:N or N:1 C25 · exception xor Match C31 · optional Month C10 · destroy Payment dissolves Match C39 | - |

- Claims naming a status code, route or response shape: C1, C2, C9, C13, C16, C17, C18, C19, C20, C21, C22, C25, C26, C27, C29, C30, C31, C33, C34, C35, C36, C37, C38, C39, C43, C44, C45, C46, C47, C48, C49, C50, C53 - each has a proof that crosses the HTTP boundary
- No other check claims more than the single case its proof exercises, except C51 (enum members `bank_fee` and `accountant_fee`), table-driven over the whole set
- C40 and C41 assert uniqueness under concurrency at the model layer; they do not substitute for C18/C19 at the HTTP boundary

## Test policy

`.cursor/rules/rails.mdc` already answers which level proves which code and how much of the input space counts. This build runs under those rows; they are not proposed as a new guideline commit.

| Code | Required proofs | Coverage expectation |
| --- | --- | --- |
| Decides, reached across a boundary | one at the boundary **and** one at its own layer | the contract at the boundary; one asserted case per row of the decision table at its own layer |
| Decides, not reached across a boundary | one at its own layer | one asserted case per enumerated member |
| Entry point that decides nothing | one at the boundary | accepted input, each rejected input, each error path |
| Instrumentation, pass-throughs | none of its own | covered by its consumer's proof |

Evidence (classified from the approved plan):

- Match confirm: shape 1:N / 1:1 / N:1 / 3:1 / N×M / empty side, lesser-observation gate, unique payment and document -> decides, reached across `POST /months/:year_month/matches`
- Leave match: destroy Match, clear Month on documents, return missing document -> decides, reached across `DELETE /months/:year_month/matches/:id`
- Document exception: `bank_fee` / `accountant_fee` / other, xor Match, unmark, confirm clears mark -> decides, reached across `POST`/`DELETE` `.../document_exception`
- Missing-document label and unmatched pool -> decides, reached across `GET /months/:year_month`
- Statement replace destroying Payments dissolves the Match -> decides, reached across `POST /months/:year_month/bank_statements` and at `BankStatement` / `Payment` own layer
- Concurrent unique `match_id` -> decides, not reached as HTTP in this cut; own layer C40, C41
- GET unauth / no-focus / never-opened and DELETE 404 -> entry / guard, boundary
- closest analogue in the repo: `spec/models/supporting_document_spec.rb` + `spec/requests/supporting_documents_spec.rb` — persist, 422 copy at the HTTP boundary, concurrent write at own layer; `spec/models/bank_statement_spec.rb` concurrent unique pair

Cost: dual proofs on confirm accepts (C9, C12, C14, C15, C23, C24, C32) and rejects (C13, C16, C18, C19, C25, C26), on leave-match (C17), on exception mark/unmark (C27–C31), on month assignment (C10, C11, C22), and on replace-dissolve (C39). Without those own-layer proofs the shape table, the lesser gate, and the match/exception xor would be proven only by a path that happens to traverse them.

## Swept

- validation: C13, C16, C25, C26, C30
- failure modes: C13, C18, C19, C31
- idempotency: C18, C19 - a second confirm of the same payment or document is `422`, not a second Match
- authorization: C6, C20, C21, C33, C34, C35, C36, C38, C44, C45, C53
- concurrency: C40, C41
- data lifecycle: C17, C29, C39 - unmatch and replace return documents to no month; unmark returns missing document; no TTL
- dependency failure: n/a - no SEFAZ, Drive, or remote call in this cut
- state transitions: C1, C9, C17, C27, C29, C31, C32
- observability: n/a - no logging or metrics criterion in the plan

## Handoff

- S1–S5 share `Match`, `Payment`, `SupportingDocument`, and `/months/:year_month`. Estimated ~18 product/spec files (Match model + migration, Payment/SupportingDocument associations, MatchesController, DocumentExceptionsController, month show + documents index, request specs, model specs, replace dissolve) ≪ 150k tokens. One builder, no split.
- S1-S5 = one builder
