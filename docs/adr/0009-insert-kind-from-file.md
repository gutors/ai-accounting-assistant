# Empty insert Tipo is classified from the file, then the existing pipeline

On insert, a blank posted `kind` becomes `nota_fiscal` when XML is uploaded, or when one `PhotoSymbols` scan of the photo yields a 44-digit chave or a `qr_url`; otherwise a photo is `recibo`. Posted `nota_fiscal` or `recibo` is kept. A non-blank kind that is not those two stays `BAD_KIND`. Infer does not run on a persisted row.

## Status

accepted

## Considered options

- **Live preview when Incluir foto chooses the file.** Rejected: classify on POST / Incluir documento.
- **Overwrite a posted Tipo from the file.** Rejected: `submit_blank_only`.
- **PhotoFields triple or EMITENTE as an NF signal.** Rejected: would classify a recibo with `R$` as nota fiscal once a recibo parser exists; symbols already mean “this photo is a nota”.
- **Filename heuristics (`danfe.jpg`).** Rejected: not a document fact.
- **Infer on PATCH.** Rejected: `KIND_LOCKED`.
- **Cloud classifier.** Rejected: later “detect more kinds” copies XML-or-PhotoSymbols-then-default-recibo.

## Consequences

- Callers that treated empty insert `kind` plus a photo as `BAD_KIND` (documents-list-mask-and-actions C25) now persist an inferred kind.
- One `PhotoSymbols` scan per insert; NF fill stays identified → public → `PhotoFields` → typed; recibo stays typed.
