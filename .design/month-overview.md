# Month overview

> Plan this with **tlc-plan**.
> Decisions below carry the literal shape — copy them, do not re-derive them.
> Issue [#112](https://github.com/gutors/ai-accounting-assistant/issues/112). Part of #75. Blocked by #111.
> HTML mock: `GET /prototypes/month-overview` (development). It is not a binding source; this file is.

## Situation

The month page is the close status, not the matching bench. Matching left for `GET /months/:year_month/matches` (#111). Visitor mode is Operate. Coordinator, laptop. After **accounts confirmation** the three movement lists appear; until then only Contas and the confirm step.

The page uses the livro-caixa rules in `DESIGN.md`. Composition is **Livro com bloqueio** (locked 14 Oct 2026): title and close controls, the blocking sentence, Contas, then the book. Pagamentos, Documentos sem casamento, Recebimentos last. Those three lists sit in `<details open>`. Account chips sit after Contas and before Pagamentos; they filter Pagamentos and Recebimentos only.

## Screen `month` — `GET /months/:year_month`

Header unchanged. Nav still has `Início`. Quiet `Voltar para Início` is the first control in `<main>`, to `/`. Title is the month in words (`maio de 2026`); `2026-05` under it in meta. After confirmation, while the month is **open**: title-right `Casar pagamentos` (`.ds-btn-secondary`) then `Fechar para envio` (`.ds-btn-primary`). While **closed**: the stamp `Mês fechado` sits under `2026-05`, not on the action row; title-right is only `Restaurar pasta` and `Reabrir` (both secondary). `Casar pagamentos` is absent. Reopening returns the open chrome (Casar + Fechar). The matches URL still exists; the month page does not offer it.

```
┌ header ────────────────────────────────────────────────────────┐
│  Início  Documentos  Configuração                         Sair │
│                                                                │
│  Voltar para Início                                            │
│  maio de 2026              [ Casar pagamentos ]  [ Fechar para envio ]
│  2026-05                                                       │
│  3 pagamentos com documento faltante. Falta o extrato de 1 conta ativa.
│                                                                │
│  Contas bancárias                                              │
│  Banco  Nome  Agência/conta  Situação  Documentos  Incluir…    │
│                                                                │
│  [ Todas ]  Conta Principal  Conta Alfa                        │
│                                                                │
│  ▾ Pagamentos                                                  │
│  Data  Histórico  Valor  Status  Documento                     │
│  11/05 Pix — Padaria  220,00  Documento faltante               │
│  13/05 Energia        340,00  Casado     Enel, CEMIG           │
│  15/05 Honorários     800,00  Honorário do contador            │
│                                                                │
│  ▾ Documentos sem casamento                                    │
│  Data  Favorecido  Tipo  Valor  Foto  Devolver                 │
│  11/05 Padaria ☐   Recibo 220,00 foto.jpg                      │
│  18/05 Limpeza     Recibo  50,00 danfe.jpg  Devolver           │
│                                                                │
│  ▾ Recebimentos                                                │
│  Data  Histórico  Valor                                        │
└────────────────────────────────────────────────────────────────┘
```

### Blockers

Same sentences as today. Unconfirmed and open: `Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.` After confirmation or while closed: missing-document count (`margem` when N > 0), then missing statements. `Fechar para envio` stays enabled; a blocked close is a sentence, not a disabled button.

### Contas bancárias

Unchanged from the live month: Banco, Nome, Agência/conta, Situação, Documentos, statement disclosure. Not inside `<details>`. Not filtered by the chips. Confirm step `Confirmar contas para fechamento` still follows Contas while unconfirmed and open. Close-for-send still requires every active account’s statement.

### Filter

Chips after Contas (or after the confirm step when that step is present and movements are hidden — then the chips are absent). `Todas` is current when `bank_account_id` is omitted. Then each active account by name, `?bank_account_id=`. Default all. The filter applies to Pagamentos and Recebimentos. Contas and Documentos sem casamento ignore it. Missing-document count follows the filter. Unknown, foreign, or inactive `bank_account_id` is `404`.

### Folds

Pagamentos, Documentos sem casamento, Recebimentos are each a `<details open>`. The `<summary>` is the section heading (title size, ruling underline). Default open; the coordinator may collapse. Empty copy stays inside the fold.

Order after Contas: Pagamentos, Documentos sem casamento, Recebimentos last.

### Pagamentos

Ruled sheet, `ledger-pay` density (3px vertical). Columns: Data, Histórico (history + account name in meta), Valor, Status, Documento. There is no Ações column. There is no `Resolver`, no N:1 fold, no `Marcar tarifa` / `Marcar honorário` / extra, no `Desfazer casamento`, no `Desmarcar exceção`.

Status keeps the words: `Documento faltante` (`margem`, row `is-block`), `Casado`, `Tarifa bancária`, `Honorário do contador`, extra kind name. Suggestion text may sit under status (`Sugestão {payees}`, `Sugestão de exceção`) as a hint; it is not a control. Exception copy stays in Status.

Documento: the matched supporting-document payee names, comma-separated (1:N and N:1). Empty on missing and on every exception.

### Documentos sem casamento

Ruled sheet. Columns: Data, Favorecido, Tipo (`Recibo` / `Nota fiscal`), Valor, Foto, then Devolver. Package checkboxes stay on this list: on an open month, a document with no month has a checkbox `form="close-month"` whose label is the payee. `Devolver` stays on a document that already belongs to this month (`month_id`). Foto: the photo filename as a quiet `caixa` underlined link to the attached Active Storage blob (`url_for` of `photo`), same tab; omit the cell content when there is no photo. The documents list prints that filename as meta under Favorecido and does not open it — do not copy that. Empty: `Nenhum documento sem casamento`.

Closed month: no checkboxes, no Devolver.

### Recebimentos

Same three-column sheet as today (Data, Histórico, Valor). Last section. Filtered with Pagamentos.

### Closed month

Stamp under the title (`Mês fechado`, `.stamp-closed`). Title-right: `Restaurar pasta`, `Reabrir`. Lists remain. No statement form, no checkboxes, no Devolver. No `Casar pagamentos`. Folds stay default open.

## Boundary

In: the GET, Voltar para Início, chips on movements, Documento column, three open folds, Recebimentos last, pool columns Data / Tipo / Foto, package checkboxes and Devolver on the pool.

Out: PagSeguro parser (#109). Statement form and Contas Documentos column (#108). Gate of confirmation (#110) — keep today’s confirm step. Matching gestures (#111). HTML mock `GET /prototypes/month-overview` as a binding source.

## Decisions

| Decision | Choice | Why this | Alternative, and what would make it win | Reversibility |
|---|---|---|---|---|
| Composition | Blockers, then Contas, then the book | Locked 14 Oct 2026 (interview) | Close strip above Pagamentos, or Contas as a footer, if the book is the daily scan and accounts are rare | reversible |
| Folds | All three default `open` | Locked 14 Oct 2026; issue left the default to the prototype | Open only when the list still has work, if a ready month is too long to scan | reversible |
| Filter placement | One chip row after Contas, before Pagamentos | Locked 14 Oct 2026; same `bank_account_id` as #111; pool unfiltered | Chips repeated inside each movement fold, if the pool between the lists makes the chips look global | reversible |
| Documento column | Payee names; empty on missing and exception | Issue: Ações gone; exception stays in Status | Filename in that column, if the coordinator needs the file without opening the pool | reversible |
| Suggestion | Meta under Status, not a control | Resolver lives on #111 | Omit suggestion copy, if a hint without an action is noise | reversible |
| Casar pagamentos | Secondary button; only while open and confirmed | Matching is read-only on a closed month; Reabrir restores the control | Keep the door while closed, if viewing matches without reopening is the job | reversible |
| Stamp | Under the title, not on the action row | Locked 14 Oct 2026 | Stamp in the button cluster, if status must sit next to Reabrir | reversible |

## Sources

- Issue #112
- Conversation, 14 Oct 2026 — folds always open; blockers then book; chips after Contas; Casar secondary and open-only; stamp under title
- `DESIGN.md` — ruled sheet, one red margin, no card
- `.design/month-match.md` — `Casar pagamentos`, chips, filter 404
- `GET /prototypes/month-overview` (development) — not binding; composition check only
