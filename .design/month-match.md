# Month match

> Plan this with **tlc-plan**.
> Decisions below carry the literal shape — copy them, do not re-derive them.
> Issue [#111](https://github.com/gutors/ai-accounting-assistant/issues/111). Part of #75. Blocked by #110.
> HTML mock: `GET /prototypes/month-match` (development). It is not a binding source; this file is.

## Situation

Matching today lives on the month page: per-row `Resolver` and a second fold `Casar vários pagamentos com um documento`. This screen takes that work off the month (the month keeps Devolver and unmatched-in-package checkboxes; #112 removes matching from the month). Visitor mode is Operate. Coordinator, laptop, after **accounts confirmation**. No movement to match until then (#110).

Recebimentos stay on the month page. After a confirm, the coordinator stays here: the payment row restyles to `Casado`; the document leaves the pool.

The page uses the livro-caixa rules in `DESIGN.md`. Composition is **Duas folhas** (seed `b0c6a47c`): facing ruled sheets, confirm under the pair. Approved raster `.impeccable/mocks/decision/split-sheets.webp` is composition only; cell grammar follows the live month sheet.

## Screen `matches` — `GET /months/:year_month/matches`

Header unchanged. Title is the month in words (`maio de 2026`); `2026-05` under it in meta. Quiet `Voltar ao mês` to `GET /months/:year_month`. `Fechar para envio` is absent. Entry from the month: control `Casar pagamentos`.

Account filter `?bank_account_id=`; default all. Chips: `Todas` (current when unfiltered), then each active account by name. The filter applies to Pagamentos. The pool is the unmatched documents available to this month (unchanged membership).

Summary under the chips: `Nenhum documento faltante.` or `1 pagamento com documento faltante.` / `N pagamentos com documento faltante.` (`margem` when N > 0). Count follows the filter.

```
┌ header ────────────────────────────────────────────────────────┐
│                                                                │
│  maio de 2026                           Voltar ao mês          │
│  2026-05                                                       │
│                                                                │
│  [ Todas ]  Conta Principal  Conta Alfa                        │
│  3 pagamentos com documento faltante.                          │
│                                                                │
│  Pagamentos                         Documentos sem casamento   │
│  ☐ Data  Histórico        Valor Status   ☐ Data Favorecido Valor Tipo
│  ☐ 11/05 Pix — Padaria   220,00 Faltante ☐ 11/05 Padaria  220,00 Recibo
│  ☐ 12/05 Pix — Mercado   180,00 Faltante ☐ 12/05 Mercado  180,00 NF
│  × 15/05 Honorários      800,00 Casado                         │
│                                                                │
│  Pagamentos R$ 220,00 · Documentos R$ 220,00 · Soma igual      │
│  Observação do casamento                                       │
│  [ Confirmar casamento ]  [ Marcar tarifa ] [ Marcar honorário ]
└────────────────────────────────────────────────────────────────┘
```

### Sheets

From 1100px two sheets sit side by side. Pagamentos is the wider track (~60%). Below 1100px they stack, Pagamentos first. Each sheet is a ruled grid from 768px.

Pagamentos is a ruled sheet. Columns: first cell, Data, Histórico (history + account name in meta), Valor, Status. `ledger-pay` density (3px vertical). A `missing` row has the 3px `margem` left edge and `Documento faltante` in `margem`. Suggestion text stays under status (`Sugestão {payees}`, `Sugestão de exceção`). Casado shows payees and observation in status; it does not grow an actions line. There is no `Resolver`. The first cell is a checkbox on `missing` rows. On `Casado` / tarifa / honorário / extra it is `×` (`aria-label` `Desfazer casamento` or `Desmarcar exceção`), `margem`, one click.

Documentos sem casamento: checkbox, Data, Favorecido, Valor, Tipo (`Recibo` / `Nota fiscal`). Empty: `Nenhum documento sem casamento`. `Devolver` and unmatched-in-package checkboxes stay on the month (#111 out).

### Confirm

One totaling line under both sheets (1px ink rule above it). Running sums of the checked missing payments and checked pool documents, then `Soma igual`, `Documentos somam menos`, or `Documentos somam mais`. Field `Observação do casamento`. Primary `Confirmar casamento`. Secondary `Marcar tarifa` / `Marcar honorário` when those offers are active, then each active extra kind.

POST remains `POST /months/:year_month/matches`. Domain unchanged: 1:N (one payment, one or more documents) or N:1 (more than one payment, one document). N:M is refused with notice `Casamento é um pagamento com um ou mais documentos, ou vários pagamentos com um documento` (`Match::BAD_SHAPE`). Lesser sum without observation: notice `Informe a observação do casamento` (`Match::LESSER`). The field border stays the ruling line. After a valid confirm the page stays; matched payments restyle; those documents leave the pool.

`Marcar tarifa` / `Marcar honorário` / extra apply to exactly one checked missing payment. Otherwise notice `Selecione um pagamento para marcar a exceção.`

### Closed month

Read-only: no checkboxes, no confirm, no exception marks. Stamp is not on this screen; `Voltar ao mês` remains.

## Month entry

On `GET /months/:year_month`, after confirmation (or while closed), a control `Casar pagamentos` goes to this screen. Copy is that phrase.

## Boundary

In: the GET, the two sheets, the account filter, redesigned Resolver / Casar vários as this confirm, stay-after-confirm.

Out: Fechar para envio. Statement upload. Devolver and unmatched-in-package checkboxes. Recebimentos. PagSeguro parser (#109). Removing matching from the month (#112). Reopening Match/exception rules.

## Decisions

| Decision | Choice | Why this | Alternative, and what would make it win | Reversibility |
|---|---|---|---|---|
| Composition | Facing sheets, confirm under the pair | Locked 13 Oct 2026 on the composition board (Duas folhas) | Linha de totais (sticky totaling strip) or Bancada (one working payment), if marking both lists in one glance is worse than a single well | reversible |
| Recebimentos | Absent here | Locked: they do not match; they stay on the month | Showing them last for statement context, if scanning the whole extract is the job | reversible |
| After confirm | Stay; row becomes Casado; document leaves the pool | Locked | Return to the month, if this screen is only a wizard step | reversible |
| N:1 | Checking more than one payment and one document | One confirm replaces `Casar vários pagamentos com um documento` | A second fold, if N:1 is rare and clutters the totaling line | reversible |
| Filter | Chips, default all, payments only | Issue `?bank_account_id=` | Filtering the pool by inferred account, when documents carry an account | reversible |

## Sources

- Issue #111
- Conversation, 13 Oct 2026 — omit inflows; stay-after-confirm; lock Duas folhas
- `DESIGN.md` — ruled sheet, one red margin, no card
- `GET /prototypes/month-match` (development) — not binding; composition check only
