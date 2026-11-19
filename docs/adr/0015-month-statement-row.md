# The month statement action is one icon in the row

The month page's statement control was chosen from a four-option prototype
(`.impeccable/mocks/statement-files.html`). The user took option 3, "Um ícone, nenhuma faixa": the
statement action is a single small icon in the account row's action cell, and the white band under
the row disappears. Three facts of that sketch are not adopted, because each would produce a control
that cannot work or a second control for the same action:

- the empty row drew two controls, the `+` in the Extrato cell and a quiet `+ Escolher PDF ou
  planilha` link in Documentos. The product keeps one control, the `+`, and Documentos carries only
  the sentence `A planilha é obrigatória`;
- the row drew `✓ Enviar extrato` and `× Descartar` as soon as any file was staged. The product
  shows `+` and `×` while a PDF is staged alone, and `✓` with `×` once a spreadsheet is among them:
  the spreadsheet is the one file `BankStatement#submit` requires, so a PDF-only send is always
  refused with `Envie a planilha`, and a `422` re-renders the page, which cannot carry chosen files
  back into a file input;
- the empty cell offered the words `Escolher PDF ou planilha` as its action. The product shows no
  such words; the sentence above replaces them.

The replacement copy `Substituir extrato` also stops being visible: with one icon for both states,
the pencil's accessible name `Substituir extrato` is what names it to a screen reader, and
`Incluir extrato` / `Substituir extrato` no longer appear as disclosure summaries.

    30|## Status

accepted

## Considered options

- **Reproduce the sketch literally, two controls on an empty row and a send from the first file.**
  Rejected: a second control for the same action makes the row's Documentos cell both a status and a
  button, and the send it offers is one the server always refuses.
- **Keep a band for replacement while removing it for the first attach.** Rejected by the user:
  "nenhuma faixa" was chosen for both states, so the same gesture includes and replaces.
- **Accumulate both files behind a server-side staging table, so a `422` keeps them.** Rejected: it
  adds a persisted entity and a one-way door for a state that lasts one submit, and the user chose
  the in-row refusal sentence instead.
- **One icon, one control, staged in the DOM until the send.** Chosen: the action stays where the
  app already puts row actions (`.ledger-action-icon`, 1.75rem), and the verdict stays in
  `BankStatement#submit`, where the request specs already reach it.

## Consequences

- `plan.md` `## Differences from the source` carries one row per departed fact, citing this ADR.
- The screens sub-agent's inventory marks the absent second control, the gated `✓` and the absent
  quiet link as accepted differences, not findings.
- `DESIGN.md`'s file-field entry still describes the green chip for the document insert and setup
  screens; the month page no longer uses it, and a later feature that touches those screens decides
  their field treatment on its own terms.
