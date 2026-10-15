# Month match

> Plan the 15 Oct 2026 composition with **tlc-plan** (`.tasks/month-match-top-band.md`).
> Decisions below carry the literal shape — copy them, do not re-derive them.
> Issue [#111](https://github.com/gutors/ai-accounting-assistant/issues/111) shipped `GET /months/:year_month/matches` (Duas folhas, confirm under the pair). This file now holds the **winner** locked 15 Oct 2026.
> HTML mock: `GET /prototypes/month-match` (development). Binding for composition (confirm-above, next-suggestion click, dates, pool order); cell grammar follows the live month sheet. It is not a persistence source.

## Situation

Matching lives on `GET /months/:year_month/matches`: two facing sheets, account chips on Pagamentos, confirm **under** the pair. Totals and Confirmar sit below two long lists, so the coordinator scrolls past the work to commit. Suggestion copy on the payment row is payee names only (`Sugestão {payees}`). Pool order is `SupportingDocument.listed` (`document_on` desc). Dates include the year (`11/05/2026`). Visitor mode is Operate. Coordinator, laptop, after **accounts confirmation**.

Recebimentos stay on the month page. After a confirm, the coordinator stays here: the payment row restyles to `Casado`; the document leaves the pool.

The page uses the livro-caixa rules in `DESIGN.md`. Composition is **Duas folhas** plus the totaling band **above** the pair and a **Próxima sugestão** click (winner 15 Oct 2026: “topo da A com o clique da C”). Per-row `Casar` in Histórico is absent — it competed with the top click.

## Screen `matches` — `GET /months/:year_month/matches`

Header unchanged. Title is the month in words (`maio de 2026`); `2026-05` under it in meta. Quiet `Voltar ao mês` to `GET /months/:year_month`. `Fechar para envio` is absent. Entry from the month: control `Casar pagamentos`.

Account filter `?bank_account_id=`; default all. Chips: `Todas` (current when unfiltered), then each active account by name. The filter applies to Pagamentos. The pool is the unmatched documents available to this month (unchanged membership).

Summary under the chips: `Nenhum documento faltante.` or `1 pagamento com documento faltante.` / `N pagamentos com documento faltante.` (`margem` when N > 0). Count follows the filter.

Dates on this screen (sheets and the suggestion band) are day/month (`11/05`). The `datetime` attribute stays ISO-8601. The month page keeps the locale default with year.

```
┌ header ────────────────────────────────────────────────────────┐
│                                                                │
│  maio de 2026                           Voltar ao mês          │
│  2026-05                                                       │
│                                                                │
│  [ Todas ]  Conta Principal  Conta Alfa                        │
│  3 pagamentos com documento faltante.                          │
│                                                                │
│  Próxima sugestão                                              │
│  Pagamento 11/05 Pix — Padaria 220,00  casar com               │
│  Documento 11/05 Padaria 220,00                                │
│  Pagamentos R$ 220,00 · Documentos R$ 220,00 · Soma igual      │
│  Observação do casamento                                       │
│  [ Confirmar casamento ]  [ Marcar tarifa ] [ Marcar honorário ]│
│                                                                │
│  Pagamentos                         Documentos sem casamento   │
│  ☐ Data  Histórico        Valor Status   ☐ Data Favorecido Valor Tipo
│  ☐ 11/05 Pix — Padaria   220,00 Faltante ☐ 11/05 Padaria  220,00 Recibo
│  ☐ 12/05 Pix — Mercado   180,00 Faltante ☐ 12/05 Mercado  180,00 NF
│  × 15/05 Honorários      800,00 Casado                         │
└────────────────────────────────────────────────────────────────┘
```

### Sticky band

After the chips and missing-count (and the existing `:base` notice when present), before the two sheets: a sticky region (`position: sticky; top: 0`; paper background) with a 1px ink rule on its bottom edge.

`h2` `Próxima sugestão` when a next document-suggestion exists (see below). One control: payment side (`Pagamento`, day/month, history, amount) | `casar com` | document side (`Documento`, day/month, payee(s), amount). Amounts use `format_reais`. For 1:N, document amount is the sum of the suggested documents; payees join with `, `; document date is the earliest `document_on` among them.

Then the totaling line, field `Observação do casamento`, primary `Confirmar casamento`, secondary `Marcar tarifa` / `Marcar honorário` when those offers are active, then each active extra kind. Observation border is the ruling line (`border-rule`), not `margem`. Running sums of the checked missing payments and checked pool documents, then `Soma igual`, `Documentos somam menos`, or `Documentos somam mais`. Empty-side sums `R$ 0,00`; omit the three verdicts until both sides have at least one check.

Clicking the suggestion control when the checked sums are equal POSTs the existing `POST /months/:year_month/matches` with those ids and blank observation (same as Confirmar). When documents sum less than payments, the click only checks the suggested rows — it does not POST; observação is still required (`Match::LESSER`). Manual 1:N / N:1 / lesser-sum still uses the sheet checkboxes and Confirmar.

When no 1-payment document suggestion remains on the filtered Pagamentos set, omit `Próxima sugestão`; the totaling line stays.

### Sheets

From 1100px two sheets sit side by side. Pagamentos is the wider track (~60%). Below 1100px they stack, Pagamentos first. Each sheet is a ruled grid from 768px.

Pagamentos is a ruled sheet. Columns: first cell, Data, Histórico (history + account name in meta), Valor, Status. `ledger-pay` density (3px vertical). A `missing` row has the 3px `margem` left edge and `Documento faltante` in `margem`. Document-suggestion payees do **not** repeat under status (they live on Próxima sugestão). `Sugestão de exceção` stays under status when that is the only suggestion. There is no `Resolver` and no `Casar` in Histórico. The first cell is a checkbox on `missing` rows. On `Casado` / tarifa / honorário / extra it is `×` (`aria-label` `Desfazer casamento` or `Desmarcar exceção`), `margem`, one click. Casado shows payees and observation in status; it does not grow an actions line.

Documentos sem casamento: checkbox, Data, Favorecido, Valor, Tipo (`Recibo` / `Nota fiscal`). Order on this GET: `document_on` ascending, then `id` ascending (oldest → newest). Membership is unchanged (unmatched-for-this-month). Empty: `Nenhum documento sem casamento`. `Devolver` and unmatched-in-package checkboxes stay on the month (#111 out). `GET /supporting_documents` keeps `listed` (`document_on` desc).

### Confirm domain

POST remains `POST /months/:year_month/matches`. Domain unchanged: 1:N (one payment, one or more documents) or N:1 (more than one payment, one document). N:M is refused with notice `Casamento é um pagamento com um ou mais documentos, ou vários pagamentos com um documento` (`Match::BAD_SHAPE`). Lesser sum without observation: notice `Informe a observação do casamento` (`Match::LESSER`). After a valid confirm the page stays; matched payments restyle; those documents leave the pool; Próxima sugestão fills with the next remaining 1-payment document suggestion (or disappears).

`Marcar tarifa` / `Marcar honorário` / extra apply to exactly one checked missing payment. Otherwise notice `Selecione um pagamento para marcar a exceção.`

### Next suggestion

**Next** is the first missing-document payment on the **filtered** Pagamentos sheet (`occurred_on`, `id`) that belongs to a document **Suggestion** with exactly one payment (1:1 or 1:N, including a Justification group). Exception-only rows (`Sugestão de exceção`) are not next. Two-payment (`format_2`) suggestions are not next (Unresolved in the task — default: skip; N:1 stays checkbox + Confirmar).

### Closed month

Read-only: no checkboxes, no Próxima sugestão, no confirm, no exception marks. Stamp is not on this screen; `Voltar ao mês` remains. Dates and pool order still follow this screen.

## Month entry

On `GET /months/:year_month`, after confirmation (or while closed), a control `Casar pagamentos` goes to this screen. Copy is that phrase. Unchanged by this composition.

## Boundary

In: the GET layout (sticky band, next click, dates, pool order on this screen), stay-after-confirm, existing POST.

Out: Fechar para envio. Statement upload. Devolver and unmatched-in-package checkboxes. Recebimentos. PagSeguro parser (#109). Removing matching from the month (#112). Reopening Match/exception rules. Changing `SupportingDocument.listed`. Putting `Sugestão de exceção` on the click band. Deleting `GET /prototypes/month-match`.

## Decisions

| Decision | Choice | Why this | Alternative, and what would make it win | Reversibility |
|---|---|---|---|---|
| Composition | Facing sheets; sticky totaling + Próxima sugestão **above** the pair; click confirms when sums match | Locked 15 Oct 2026 on the prototype (“topo da A com o clique da C”). Confirm under the fold was the 13 Oct Duas folhas lock and is superseded | Confirm under the pair, if the sticky band hides the sheets; per-row Casar, if the top click is missed | reversible |
| Suggestion click | Equal sums POST the existing confirm; lesser only checks the rows | Locked with the winner. Lesser still needs observação | Click always only preselects, if a mis-click confirms too easily | reversible |
| Row suggestion copy | No `Sugestão {payees}` and no `Casar` on the payment row; `Sugestão de exceção` stays | Locked: the band is the one-click; Casar in Histórico competed with it | Keep payee under status, if the band is scrolled away and the row must still hint | reversible |
| Dates | Day/month on this GET only | Locked with the prototype | Year on this GET, if two years can appear in one month’s pool | reversible |
| Pool order | Oldest → newest on this GET only | Locked with the prototype | Keep `listed` desc, if newest-first matches the documents index | reversible |
| Recebimentos | Absent here | Locked: they do not match; they stay on the month | Showing them last for statement context, if scanning the whole extract is the job | reversible |
| After confirm | Stay; row becomes Casado; document leaves the pool | Locked | Return to the month, if this screen is only a wizard step | reversible |
| N:1 | Checking more than one payment and one document | One confirm replaces `Casar vários pagamentos com um documento` | A second fold, if N:1 is rare and clutters the totaling line | reversible |
| Filter | Chips, default all, payments only | Issue `?bank_account_id=` | Filtering the pool by inferred account, when documents carry an account | reversible |

## Sources

- Issue #111 — shipped GET matches, filter, entry, Match/exception rules
- Conversation, 13 Oct 2026 — omit inflows; stay-after-confirm; Duas folhas
- Conversation, 15 Oct 2026 — winner “topo da A com o clique da C”; drop per-row Casar; dates day/month; pool oldest → newest
- `DESIGN.md` — ruled sheet, one red margin, no card
- `GET /prototypes/month-match` (development) — binding for the 15 Oct composition
