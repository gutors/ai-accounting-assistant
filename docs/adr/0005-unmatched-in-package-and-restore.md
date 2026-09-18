# Unmatched-in-package documents and month-folder restore

A supporting document belongs to a month when it is matched **or** when the coordinator includes it unmatched at close-for-send (`month_id` set, `match_id` nil). Restore rewrites that month’s package-archive folder from the frozen product copy without opening the month.

## Status

accepted

## Considered options

- **A second column or close-inclusion join.** Rejected: match-and-exception door 4 reserved the optional Month on SupportingDocument for this path (#39).
- **Assign `month_id` before the Drive write.** Rejected: a writer failure would leave documents of an open month with no folder.
- **Unmatched-in-package is `month_id` set and `match_id` nil (chosen).** Close that selects a no-month document, after a successful `replace_month_folder`, persists that document’s `month_id` in the same lock as `closed`. Return clears `month_id` while the month is open and `match_id` is nil. Match confirm on that month keeps `month_id`. Leave-match still nulls `month_id`.

- **A second Drive client in the restore action.** Rejected: close-for-send door 2 — one package-archive writer.
- **Active Job / a `closing` flag.** Rejected: #19 forbids a third month state.
- **Treating restore as POST close.** Rejected: close-while-closed is already `422` `Mês fechado`.
- **Restore rewrites through `PackageArchiveWriter.replace_month_folder` in the request (chosen).** Holds the same Month row lock as close, passes `folder_id: month_folder_id` and `MonthPackage.files(month)`, does not change `closed` or `month_folder_id`, enqueues no job. Only while `closed` is true.

## Consequences

- Suggestions, submitter withdraw, and later dispatch must treat `month_id` without a Match as belonging to that month.
- Later Drive writes keep this port; restore is not a new close and does not thaw the month.
