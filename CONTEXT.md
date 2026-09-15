# Monthly close (ONG)

Glossary for the monthly bank-to-document close that a financial coordinator runs for NGOs, then hands to an accountant. Several organizations share this ritual. The coordinator closes the month; other people may insert supporting documents.

## People

**Account**:
A person’s standing login, identified by email. One person, one account.
_Avoid_: user (unqualified), shared login, Google (when the Drive account that writes the package archive is meant)

**Access**:
A person’s coordinator or submitter standing on one organization. A person may hold several.
_Avoid_: role, permission, membership, authorization (when SEFAZ autorização is meant)

**Coordinator**:
A person with coordinator access on an organization: runs monthly close and validates matches. An organization has one or more. Not the only person who can put documents in.
_Avoid_: accountant (as the operator), business owner, bookkeeper

**Submitter**:
A person with submitter access on an organization who inserts supporting documents, sees only their own, and does not see bank payments. May insert more than one document toward justifying a single amount they were given. A person may hold this access on more than one organization.
_Avoid_: accountant, coordinator (when the narrower close role is meant), system user

**Accountant**:
The external professional who receives that organization’s monthly package. Not an operator of the system. Each organization has one: a presentation name; optionally a tax id (CNPJ or CPF), a razão social only when that id is a CNPJ, and a PIX key. The coordinator delivers the package; the accountant does not log in.
_Avoid_: coordinator, nome social (when presentation name or razão social is meant)

**Organization**:
An NGO (or similar) whose month is being closed. Standing close setup belongs to the organization: coordinators, bank accounts, accountant, package destination, package archive, submitters, extra exception kinds, and optional SEFAZ certificate. It has no stored tax id of its own in this version. Several organizations share this ritual; a coordinator typically closes one and may close more than one.
_Avoid_: company, customer, tenant, CNPJ (when a standing organization tax id is meant)

## Monthly close

**Monthly package**:
One set, for one organization and one month, of the summary spreadsheet, the bank statements, and the supporting documents. The system prepares it; the coordinator delivers it to the accountant. It is not two channels (email vs shared folder).
_Avoid_: report, export, books, email (as the package), Drive (as the package)

**Package destination**:
The accountant’s email for that organization, where the monthly package is addressed. It belongs to the organization. It is a reminder, not a send target for the system, and it is not the package archive.
_Avoid_: inbox, Drive (as the system’s file store or as the archive)

**Package archive**:
The organization’s designated Drive folder, one per organization, pointed at in setup. The coordinator designates an existing folder; the product does not create it. Distinct from the package destination and from a month folder.
_Avoid_: Drive (as the destination), backup, repository (unqualified), month folder (when the organization-level folder is meant)

**Month folder**:
The folder for one organization-month inside the package archive. It is the kept copy of that month’s monthly package. Created on the first close-for-send of that month; a later close-for-send of the same month replaces its contents without changing the folder. Reopening does not touch it.
_Avoid_: package archive (when the month’s folder is meant)

**Close-for-send**:
The coordinator’s act that freezes an organization’s month in the product and writes that month’s package to the month folder in the package archive. It is not delivery to the accountant.
_Avoid_: send, dispatch, delivery

**Closed month**:
An organization’s month after close-for-send, until the coordinator reopens it (it is then an open month again, data intact). That month is read-only in the product; inserting a supporting document that still has no month does not change it. The coordinator may still view it, deliver the same archived package again, or restore a damaged month folder from this frozen copy.
_Avoid_: archived month

**Summary spreadsheet**:
The month’s income and expense summary included in the monthly package.
_Avoid_: ledger, books

**Bank**:
A Brazilian retail bank in the product’s fixed catalog (bootstrapped with the main retail banks; the coordinator cannot type one outside the list). Each entry has a presentation name, COMPE code, and ISPB.
_Avoid_: bank account, Outro (as a typed institution)

**Bank account**:
One account at a bank, belonging to an organization (several allowed, including two at the same bank). Identity is a unique name (UI, month-folder slug, and what the accountant reads in the statements folder), the bank, and optional free-text bank coordinates; it is active or inactive, never deleted; the organization’s PIX keys are not part of it.
_Avoid_: bank (when the account is meant), apelido, PIX (when the organization’s keys on the account are meant)

**Bank statement**:
The list of bank movements from one bank account for the month. An organization may have more than one bank account. For each bank account and month the coordinator chooses: upload PDF plus CSV/XLSX, or Open Finance (JSON). The accountant’s PDF is optional when Open Finance is used. Payments for that month do not exist in the system until the coordinator inserts the statement; that is typically the following calendar month or later.
_Avoid_: OFX, extract file (as the concept)

**Inflow**:
A bank movement that increases the account. It appears on the summary spreadsheet and does not require a supporting document.
_Avoid_: donation, entrada (as the matching unit), income (when the bank line is meant)

**Payment**:
A bank movement that decreases the account. It requires a match or a document exception. A payment belongs to at most one match.
_Avoid_: expense, saída, transaction (unqualified)

**Supporting document**:
The evidence kept to justify a payment: a **photo** (or image PDF) of a DANFE or recibo, and/or the authorized XML of a nota fiscal. Who inserts declares nota fiscal or recibo. Amount, date, and payee always exist. On a nota fiscal they come from the authorized XML (uploaded or obtained by identified SEFAZ consulta — not edited), from the consumer SEFAZ consulta opened by the NFC-e QR Code, from reading the photo, or are typed as fallback. Recibo has no XML; those three are typed and the photo is not read in this version. Image PDF of a DANFE or recibo counts as a photo. Several supporting documents may cover one payment; one document may cover more than one payment. It has no month until a confirmed match (the payment’s month) or until the coordinator includes it in a month’s package at close-for-send. Date is a hint, not a month assignment.
_Avoid_: invoice (unqualified), note, attachment, XML (as if it were the only file)

**Match**:
The coordinator-confirmed association in one of two shapes: one payment with one or more supporting documents, or more than one payment with a single supporting document, all in the same month. It is valid because the coordinator confirmed it, not because amounts, dates, or payee names agree. A supporting document belongs to at most one match; a payment belongs to at most one match. The coordinator may regroup while the month is open; leaving a match returns a document to having no month.
_Avoid_: pair (as if one document or one payment were required), link, assignment (unqualified), suggestion (after confirmation)

**Suggestion**:
The system’s proposed association of payment(s) and supporting document(s) that is not yet a match. It can exist for any open month that already has bank statement(s), including when the document has no month. Confirming it makes a match; until then the payment is still a missing document.
_Avoid_: match (before confirmation), auto-match, pair, exception suggestion

**Exception suggestion**:
The system’s proposed accountant’s-fee document exception on a payment that is not yet marked. Confirming it makes a document exception; until then the payment is still a missing document. It is not a suggestion (those associate documents).
_Avoid_: suggestion (the document association), auto-exception

**Justification**:
A submitter-declared amount spent plus the supporting documents that cover it. The submitter does not choose a bank payment. In a 1:1 case without discount, the spent amount may start equal to the document amount. After statements are in, the system may turn a justification into a suggestion.
_Avoid_: pair, bundle (unqualified), deposit (as the spent amount), suggestion (the justification has no payment yet)

**Unmatched document**:
A supporting document that is not in any match. With no month, it is available to any open month; at close-for-send the coordinator may put some in that month’s package, identified as unmatched — those then belong to that month until matched or returned to having no month. It does not block close-for-send; nothing enters the package unless the coordinator chooses it.
_Avoid_: orphan (unqualified), leftover, extra note, pool (as if it were a separate kind of document)

**Observation**:
Free-text note. On a supporting document it is optional and does not change amount, date, or payee when those come from the authorized XML or identified SEFAZ consulta. On a match it is required when the documents’ amounts sum to less than the payment(s); without it that match cannot be confirmed.
_Avoid_: correction, comment (unqualified)

**Nota fiscal**:
A Brazilian electronic tax invoice (NF-e / NFC-e). The fiscal document is the authorized XML; a DANFE is only a human-readable print of that XML. In monthly close the supporting document may be a photo of the DANFE, the authorized XML, or both.
_Avoid_: NF, invoice (unqualified), DANFE (as if it were the fiscal document)

**Chave de acesso**:
The 44-digit identifier of an authorized nota fiscal, printed on the DANFE. It can be used to consult the note on the state SEFAZ site. On a supporting document it may be captured from the photo or typed, so consulta can start even when the image is poor. On a photo it is often unreadable (bad photo or poor print).
_Avoid_: barcode, QR (those may encode the chave; an NFC-e QR is also a consult URL)

**SEFAZ consulta**:
Looking up an already-authorized nota fiscal on the state SEFAZ site (for example sefaz.rs.gov.br). Identified consult (SEFAZ certificate) can return the authorized XML or the matching fields. The consumer consult opened from an NFC-e QR Code needs no certificate and is not the XML. Not issuance or authorization of a note.
_Avoid_: SEFAZ integration (unqualified), emissão, autorização

**SEFAZ certificate**:
The organization’s optional A1 e-CNPJ for identified SEFAZ consulta. One at a time. Coordinators install, replace, or remove it; submitters do not see it. It is absent, valid until a date, or expired. The CNPJ on the file is the certificate’s titular, not a stored organization tax id in this version. Not a bank login.
_Avoid_: A3, e-CPF (as this certificate), accountant’s certificate, organization tax id (when the file’s CNPJ is meant)

**Recibo**:
Proof of a payment that is not a nota fiscal. It has no XML, chave de acesso, or official barcode/QR.
_Avoid_: receipt (unqualified, when the Brazilian document type is meant)

**Extra exception kind**:
A name the organization keeps, besides bank fee and accountant’s fee, for marking a document exception. Unique in that organization and distinct from the two base names. A deactivated kind remains on payments already marked and is not offered for new marks; an unused kind may be removed.
_Avoid_: category, tag, extra (unqualified), exception type (when the document exception is meant)

**Document exception**:
A payment the coordinator marked with an allowed kind (bank fee, accountant’s fee, or an extra exception kind) so it needs no match. The mark is per payment per month and only exists after the coordinator confirms it; it cannot coexist with a match.
_Avoid_: missing document, exception suggestion (before confirmation)

**Missing document**:
A payment that should have a match and does not yet (no confirmed match, no exception mark). An exception suggestion is not a mark. A month with a missing document cannot be closed for sending.
_Avoid_: exception, pending note
