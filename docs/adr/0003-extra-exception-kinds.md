# Extra exception kinds as an organization catalog

An organization keeps extra exception kinds as named catalog rows, besides bank fee and accountant’s fee. A payment is a document exception when it carries a base `document_exception_kind` **or** an `extra_exception_kind_id`. Those extras are not enum values.

## Status

accepted

## Considered options

- **Adding extra names to `document_exception_kind`.** Rejected: match-and-exception door 3 and #36 — extras are organization catalog names, not a third enum value.
- **A string column of free text on Payment.** Rejected: #25 uniqueness, deactivate, and unused-remove live on the catalog, not on each mark.
- **Never-delete like `BankAccount`.** Rejected: #25 unused may leave.
- **Extra exception kind is an organization catalog row, not an enum value (chosen).** `ExtraExceptionKind` belongs to `Organization`. Identity is the trimmed name, unique per organization including deactivated rows, compared case-insensitively. Distinct from presentation names `Tarifa bancária` and `Honorário do contador`. Active boolean, default true. No rename. Unused row may be DELETEd; used row is `restrict`. `Payment.document_exception_kind` enum stays `{ bank_fee, accountant_fee }`.

- **A `DocumentException` row.** Rejected: match-and-exception already rejected it for the two base kinds; extras do not need a second payment-level entity once the catalog row exists.
- **Storing the extra name as text on Payment.** Rejected: deactivate would rename the mark or orphan the label; #25 the deactivated kind remains on payments already marked.
- **`kind=<name>` in the mark POST.** Rejected: a coordinator could include an extra named `bank_fee`, which is not a base presentation name, and collide with the enum.
- **Document exception extra mark is an optional Payment association, xor Match and xor base kind (chosen).** `Payment` belongs to `ExtraExceptionKind` optionally (`extra_exception_kind_id`). Database check: at most one of `match_id`, `document_exception_kind`, `extra_exception_kind_id` is non-null. Missing document is all three absent. Mark POST accepts `kind=bank_fee` or `kind=accountant_fee` **or** `extra_exception_kind_id` of an active ExtraExceptionKind of the focused organization — not both. Confirming a Match still clears the extra FK. FK `ON DELETE restrict` is the unused-remove mechanism.

## Consequences

- Later exception-suggestion (#37) must not invent a second extra-kind catalog.
- Close-for-send and the summary spreadsheet read the association, not a new column on the workbook.
- `Payment#missing_document?` and `Payment.missing_document` treat `extra_exception_kind_id` the same way they treat a base kind.
