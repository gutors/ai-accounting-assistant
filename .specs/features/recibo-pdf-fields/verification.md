# Recibo PDF fields verification

**Verdict**: FAIL
**Mutations**: 3 - probed C2, C12, C5
**Proofs**: `proofs.md` at a4f83aa
**Verifier**: independent sub-agent (author != verifier)

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| C5 asserts Miss, not that the app-receipt phrases are why it misses | mutation `app-receipt guard disabled` not killed; `recibo_fields_spec.rb` fixture has `R$` lines and no date, so `parse` still returns `Miss` via the complete-triple rule | give the app-receipt PDF a date and a usable payee so only `app_receipt?` can yield `Miss` | `dbd1b41` - app-receipt fixture has date and Kali Confeitaria; mutation killed |
| C6 proves empty `pdftotext`, not unusable text falling through to OCR | second C6 proof stubs `PhotoPdf.text` to `""` only; AC 6 also names unusable (present but incomplete) text | add a proof where `pdftotext` is amount-only and raster OCR returns the Padaria triple | `dbd1b41` - `Real unusable pdftotext uses OCR Padaria triple` |
