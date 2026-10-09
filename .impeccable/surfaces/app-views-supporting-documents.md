---
version: 1
slug: "app-views-supporting-documents"
primary_target: "app/views/supporting_documents"
related_targets: []
---

# Surface: supporting document edit

Mode: Operate. Audience: Coordinator on a laptop during the monthly close.

## Direction contract

THESIS: The document’s paper is the proof on the left; the book that can still be corrected is a narrow column on the right. It refuses the inline disclosure on the list and refuses a card around either pane.

OWN-WORLD: Ledger paper page, sheet-white only inside fields and the photo’s ruled frame, 1px rule, 4px controls, IBM Plex Sans, Plex Mono only on the chave, caixa for commit and quiet links, margem only on the SEFAZ notice and Excluir.

STORY: The coordinator left the list, sees the photo, and can change typed valor/data/favorecido/observação, add XML, confirm SEFAZ, save, or delete.

FIRST VIEWPORT: Header. Voltar para documentos. Editar documento. Margem notice plus Usar dados da SEFAZ. Then two columns from 768px: left photo (ruled sheet, filename, lock sentence) and XML row; right 28rem stacked fields (tipo locked, valor, data, favorecido, chave, observação) then Salvar documento and Excluir. Below 768px the photo stacks first.

FORM: Evidence pane (dealt structure 7). Seed ceb7f789.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

## Constraints

- Typed NF: amount, date, payee editable; observation always editable.
- Tipo cannot change. Attached photo cannot be replaced; XML picker only if none attached.
- Save, delete (no month), and SEFAZ confirm live on this page.
- Approved comp: `.impeccable/mocks/decision/evidence-pane.webp`
