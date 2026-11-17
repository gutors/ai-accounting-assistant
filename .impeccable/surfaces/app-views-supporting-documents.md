---
version: 1
slug: "app-views-supporting-documents"
primary_target: "app/views/supporting_documents"
related_targets: ["app/views/supporting_documents/_insert_lote.html.erb","app/views/supporting_documents/edit.html.erb","app/views/supporting_documents/index.html.erb"]
---

# Surface: supporting documents

Mode: Operate. Audience: Coordinator on a laptop during the monthly close.

## Direction contract

THESIS: The document’s paper is the proof on the left; the book that can still be corrected is a narrow column on the right. It refuses the inline disclosure on the list and refuses a card around either pane.

OWN-WORLD: Ledger paper page, sheet-white only inside fields and the photo’s ruled frame, 1px rule, 4px controls, IBM Plex Sans, Plex Mono only on the chave, caixa for commit and quiet links, margem only on the SEFAZ notice and Excluir.

STORY: On include, the coordinator drops a file, reads the photo, fills the book through Observação, and includes. On edit, they left the list, see the photo, and can change typed valor/data/favorecido/observação, confirm SEFAZ, save, or delete.

FIRST VIEWPORT: Header. Documentos de suporte, or Voltar para documentos then Editar documento. SEFAZ notice (edit only) full-width after h1. Two columns from 768px: left proof (ruled sheet whose image well stretches to the book column through Observação; filename; lock or Limpar) and right 28rem stacked fields then the primary include/save. Below 768px the photo stacks first, with a readable min-height. Sem mês sits under the split.

FORM: Evidence pane (dealt structure 7). Seed ceb7f789.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

## Constraints

- Typed NF: amount, date, payee editable; observation always editable.
- Tipo cannot change after identification. Attached photo cannot be replaced; replace by deleting and including again.
- Save, delete (no month), and SEFAZ confirm live on edit.
- From 768px the proof pane matches the book column height through Observação; the image uses object-contain inside that well.
- SEFAZ notice + `Usar dados da SEFAZ` is full-width after h1 and before the split. `.impeccable/mocks/decision/evidence-pane.webp` is the approved **Prova à esquerda** raster, not authority for that band (generation miss, same class as abbreviated Chave/Observação).
- Approved comp: `.impeccable/mocks/decision/evidence-pane.webp` (composition of panes; not the SEFAZ-band arrangement, not the proof height after stretch).
