# Uploaded XML for NFCom, NF3e, and national NFS-e

> Build this with **tlc-implement**.
> Every criterion below becomes a check with a proof, referenced by its number. Nothing under
> `Unresolved` gets settled while building.

## Intent

On `POST /supporting_documents/identify` and `POST /supporting_documents`, an uploaded `.xml` is
`nota_fiscal` only when `AuthorizedNfe.parse` finds `infNFe`, `total/ICMSTot/vNF`, emitente
`xNome`, `dhEmi`, and `Id` prefix `NFe`. Well-formed authorized XML of other Brazilian DFe
returns `422` with `O XML da nota fiscal não pôde ser lido` and persists nothing. The coordinator
hit that copy with `nota-xml-exemplo.xml` (NFCom, modelo 62). The same parser would reject NF3e
(modelo 66) and national NFS-e. Those files already carry amount, date, and payee. The
conversation that produced this task gives no conversion figure.

When this ships, identify and insert of authorized XML for NFCom, NF3e, and national NFS-e fill
and lock Valor, Data, and Favorecido the same way NF-e XML already does (`fields_origin`
`uploaded_xml`, origin copy `XML autorizado`). There is no new SEFAZ (or NFS-e portal) consulta.
Photo-only insert of those documents is unchanged. Other well-formed DFe XML, including municipal
NFS-e without `infNFSe`, is refused with a distinct sentence.

16 criteria in 4 slices · 3 one-way doors · 3 open, of which 0 block

## Criteria

### NFCom, NF3e, and national NFS-e XML

1. Given the focused organization has no SEFAZ certificate, and authorized NFCom XML (`nfcomProc`
   / `infNFCom`) with `total/vNF` `256.80`, emitente `EMPRESA TELECOM EXEMPLO S.A.`, `dhEmi`
   `2026-06-15T21:53:53-03:00`, `Id` `NFCom27260611222333000181620010008920781028142810`, when a
   coordinator POSTs `POST /supporting_documents/identify` with that file, then no
   SupportingDocument is persisted, the status is `200`, Tipo is `Nota fiscal` disabled, Valor
   `256,80`, Data `2026-06-15`, Favorecido `EMPRESA TELECOM EXEMPLO S.A.`, chave
   `27260611222333000181620010008920781028142810`, origin under Valor, Data, and Favorecido is
   `XML autorizado`, and those three inputs are disabled.
2. When that coordinator POSTs `POST /supporting_documents` with that same NFCom file and no
   `kind`, then one SupportingDocument persists `kind` `nota_fiscal`, `amount_cents` `25680`,
   `document_on` `2026-06-15`, `payee` `EMPRESA TELECOM EXEMPLO S.A.`, that chave, `fields_origin`
   `uploaded_xml`, the XML blob, no photo blob, and the status is `302` to `/supporting_documents`.
3. Given no SEFAZ certificate, and authorized NF3e XML (`infNF3e`) with `vNF` `189.40`, emitente
   `Companhia Energetica Exemplo`, `dhEmi` `2026-05-20T00:00:00-03:00`, `Id`
   `NF3e27260611222333000181660010000008920781028142`, when that coordinator POSTs identify with
   that file, then no row is persisted, the status is `200`, Valor `189,40`, Data `2026-05-20`,
   Favorecido `Companhia Energetica Exemplo`, chave `27260611222333000181660010000008920781028142`,
   origin `XML autorizado`.
4. When that coordinator POSTs create with that NF3e file and no `kind`, then one row persists
   `amount_cents` `18940`, `document_on` `2026-05-20`, `payee` `Companhia Energetica Exemplo`, that
   chave, `fields_origin` `uploaded_xml`, and `302` to `/supporting_documents`.
5. Given no SEFAZ certificate, and authorized national NFS-e XML (`infNFSe`) with `vServ` `610.00`,
   emitente `xNome` `Contabilidade Exemplo Ltda`, `dhEmi` `2026-05-06T10:00:00-03:00`, `Id`
   `NFS41260511222333000181000000000000000000000000000001`, when that coordinator POSTs identify
   with that file, then no row is persisted, the status is `200`, Valor `610,00`, Data
   `2026-05-06`, Favorecido `Contabilidade Exemplo Ltda`, chave
   `41260511222333000181000000000000000000000000000001`, origin `XML autorizado`.
6. When that coordinator POSTs create with that NFS-e file and no `kind`, then one row persists
   `amount_cents` `61000`, `document_on` `2026-05-06`, `payee` `Contabilidade Exemplo Ltda`, that
   50-digit chave, `fields_origin` `uploaded_xml`, and `302` to `/supporting_documents`.
7. Given a submitter of the focused organization and no certificate, when they POST identify then
   create as in criterion 2 with that NFCom file, then the persisted `account_id` is the
   submitter, `GET /supporting_documents` is `200` and includes `EMPRESA TELECOM EXEMPLO S.A.`,
   and it does not include another organization's documents.
8. Given the NFCom row from criterion 2, when `GET /supporting_documents/:id/edit` runs, then
   Valor, Data, and Favorecido are not editable and each origin is `XML autorizado`. When that
   coordinator PATCHes `payee` `Mercado Silva`, then the status is `422`,
   `[data-notice="error"]` is `Valor, data e favorecido vêm da nota e não podem ser alterados`,
   and `payee` remains `EMPRESA TELECOM EXEMPLO S.A.`.

### NF-e XML still parses; no new consulta

9. When that coordinator POSTs identify with authorized NF-e XML of `vNF` `155.00`, emitente
   `Padaria Central`, `dhEmi` `2026-05-11T10:00:00-03:00`, chave
   `43260511222333000181550010000000011123456781`, then the status is `200`, Valor `155,00`,
   Data `2026-05-11`, Favorecido `Padaria Central`, origin `XML autorizado`, and no
   SupportingDocument is persisted.
10. Always, identify or create of NFCom, NF3e, or national NFS-e XML does not call
    `SefazConsulta` and does not call `PublicNfceConsulta` (no certificate, wrapping key, or
    NFC-e QR is required for those three successes).

### Refused XML

11. If identify is posted XML that is not well-formed (`<nfe><`), then no
    SupportingDocument is persisted, the status is `422`, and `[data-notice="error"]` and the
    error toast are `O XML da nota fiscal não pôde ser lido`.
12. If identify is posted well-formed XML that has `infNFe` and no `total/ICMSTot/vNF`, then no
    row is persisted, the status is `422`, and that same unreadable copy is shown.
13. If identify is posted well-formed CT-e XML (`infCte` and no `infNFe`, `infNFCom`, `infNF3e`,
    or `infNFSe`), then no row is persisted, the status is `422`, and `[data-notice="error"]`
    and the error toast are `Este XML não é NF-e, NFC-e, NFS-e nacional, NFCom ou NF3e`.
14. If identify is posted well-formed municipal NFS-e XML (`CompNfse` / `InfNfse` and no
    `infNFSe`), then no row is persisted, the status is `422`, and that same unsupported copy
    as criterion 13 is shown.
15. When create is posted the CT-e file of criterion 13, then no row is persisted, the status
    is `422`, and `[data-notice="error"]` is that unsupported copy.

### Glossary

16. When this ships, `GLOSSARY.md` **Nota fiscal** names NF-e, NFC-e, NFCom (modelo 62), NF3e
    (modelo 66), and national NFS-e as authorized XML the supporting document may store, and
    **Chave de acesso** says the identifier on an uploaded XML is the digits from that document's
    `Id` (44 for NF-e / NFC-e / NFCom / NF3e, 50 for national NFS-e). Typed chave and photo
    decode remain 44 digits for identified SEFAZ consulta. **SEFAZ consulta** stays identified
    lookup of NF-e / NFC-e; it does not claim NFCom, NF3e, or NFS-e.

## Out of scope

- New identified consulta, public consulta, or portal download for NFCom, NF3e, or NFS-e — the
  source chose uploaded XML only.
- Photo / DANFCom / DANF3e / DANFSE identification, OCR, or chave-from-photo for models 62 and
  66 or NFS-e — existing photo pipeline is NF-e / NFC-e 44-digit and QR.
- Parsing municipal NFS-e layouts (Ginfes, ISSNet, ABRASF `InfNfse`, and other pre-national
  schemas) — criterion 14 refuses them.
- CT-e, CT-e OS, MDF-e, BP-e, NFAg, NFGas, and CF-e SAT XML — criterion 13.
- New `kind` enum members; these documents stay `nota_fiscal`.
- Changing match, close-for-send package names, or origin copy `XML autorizado`.
- Signature validation of the XML (NF-e upload already does not verify the digest).
- Open Finance, NF-e issuance, accountant login.

## Observable

| Surface | Decision | Landing |
| --- | --- | --- |
| screen `documents` insert | empty state | existing — file-first empty square and wait copy from document-file-first-insert |
| screen `documents` insert | loading | existing — `Identificando o arquivo…` |
| screen `documents` insert | error state | 11, 12, 13, 14 — `422` unreadable vs unsupported copy; toast + `[data-notice="error"]` |
| screen `documents` insert | unauthorised | existing — unauthenticated identify `302` `/login` |
| screen `documents` insert | density and ordering | existing — proof square and book; 1, 3, 5, 9 only fill the book |
| screen `documents` insert | destructive action confirms | n/a — no new destructive action |
| screen `documents` edit | error state | 8 — `422` `LOCKED_FIELDS` |
| screen `documents` edit | empty / loading / unauthorised / density | existing — Arquivo XML, locked book for `uploaded_xml` |
| HTML `POST /supporting_documents/identify` | who may call | 7 — focused Access; submitter may identify |
| HTML `POST /supporting_documents/identify` | error shape and codes | 11–14 — `422` plus existing notice and error toast |
| HTML `POST /supporting_documents/identify` | versioning / rate limit | n/a — same session app |
| HTML `POST /supporting_documents` | error shape and codes | 15 — `422` unsupported copy |
| HTML `POST /supporting_documents` | who may call | 7 — submitter create of own XML |
| document `GLOSSARY.md` | structure / what the reader does next | 16 — names the accepted XML models; no operator action |
| collection of uploaded XML kinds | grouping / exception that does not fit | 1–6 accept 62, 66, national NFS-e, existing 55/65; 13–14 refuse the rest |

## Swept

- validation: 1–6, 11–15 — required amount, date, payee, and Id digits; malformed and incomplete
  NF-e stay unreadable; other DFe stay unsupported
- failure modes: 11, 12, 13, 14, 15 — syntax vs missing NF-e `vNF` vs wrong model
- idempotency and retry: existing — a retried create POSTs a second SupportingDocument; no unique
  chave
- authorization: 7 — existing focused organization and submitter-own-row
- concurrency and ordering: n/a — two identify-then-create sequences persist two rows; no new
  uniqueness
- data lifecycle: n/a — `chave` remains a string; nothing to backfill; NFS-e 50-digit values are
  new writes only
- external-dependency failure: 10 — these three successes must not depend on SEFAZ or public
  NFC-e; a miss on those ports is not in this path
- state transitions: 8 — `uploaded_xml` still locks the three fields (`LOCKED_FIELDS`)
- observability: existing — `:base` notice plus error toast on `422`; no new metric

## Impact

| Front | What changes |
|---|---|
| domain | existing term: **Nota fiscal** / `AuthorizedNfe.parse` meant NF-e (`infNFe`) and, in practice, NFC-e with the same schema. After this task it also means authorized NFCom, NF3e, and national NFS-e XML. Callers: `SupportingDocument#submit` identify and insert, `SefazConsulta` parse of identified XML (still NF-e only), every spec that treats non-`infNFe` XML as `XML_UNREADABLE`. |
| domain | existing term: **Chave de acesso** on a supporting document from uploaded XML may be 50 digits (national NFS-e). Typed chave, `PhotoSymbols`, and `CHAVE_DIGITS` stay 44 digits. `format_chave` already groups any string in fours. |
| domain | new copy: unsupported XML sentence in criterion 13 — lives next to `SupportingDocument::XML_UNREADABLE`. |
| stored data | nothing to migrate. Existing rows keep 44-digit chaves. No new columns. |

## Decided

| Decision | Shape | Alternative rejected |
|---|---|---|
| These DFe stay `kind` `nota_fiscal` | Enum unchanged. XML extension still classifies as `nota_fiscal` (ADR-0009). | New kind members per model — would split the list, infer, submitter justify, and match for no operator distinction in monthly close. |
| Upload XML only; no new consulta | Identify/create parse the bytes. `SefazConsulta` / `PublicNfceConsulta` are not invoked when that parse succeeds (10). NFCom/NF3e SVRS and NFS-e national portals are not dependencies. | Identified consulta for modelo 62/66 — different webservice and certificate use than `chNFe` distDFe already in `SefazConsulta::Real`. |
| Typed/photo chave stay 44 digits | `CHAVE_DIGITS` and `PhotoSymbols` 44-digit guard unchanged. Uploaded XML stores Id digits after the model prefix (`NFe`, `NFCom`, `NF3e`, `NFS`). | Widen typed chave to 50 — would send NFS-e keys into NF-e distDFe. |

## Surface

| Route | In | Out | Status | Criteria |
|---|---|---|---|---|
| `POST /supporting_documents/identify` | `.xml` file | filled insert HTML or 422 notice | `200`, `422` | 1, 3, 5, 9, 10, 11, 12, 13, 14 |
| `POST /supporting_documents` | `.xml` file | redirect or 422 | `302`, `422` | 2, 4, 6, 7, 15 |
| `GET /supporting_documents/:id/edit` | id | locked book, origin `XML autorizado` | `200` | 8 |
| `PATCH /supporting_documents/:id` | payee | 422 lock | `422` | 8 |

## Sources

- Conversation 2026-10-17 (this session) — accept NFS-e, NF3e (66), NFCom (62); skip new consulta
  because the XML already has the three fields. Quote: “Podemos aceitar as que tu sugeriu (NFS-e ,
  a 66 e 62). Se a consulta sefaz for muito complicada acredito que nao precisamos porque o xml
  ja tem os dados necessarios ,nao ?”
- Conversation landing before the plan — “aceitar XML de NFCom, NF3e e NFS-e nacional no mesmo
  caminho de nota fiscal + XML enviado; sem consulta nova; foto desses tipos sem XML não ganha
  identificação fiscal nesta versão. NFS-e municipal fora do padrão nacional fica recusada com
  mensagem clara.”
- `app/models/authorized_nfe.rb` — current `infNFe` + `ICMSTot/vNF` + `NFe` prefix; NFCom example
  failed here (`infNFCom`, `vNF` under `total`, `Id` prefix `NFCom`).
- `GLOSSARY.md` **Nota fiscal** — today NF-e / NFC-e only; criterion 16 amends it.
- ADR-0009 — empty insert XML still `nota_fiscal`; this task does not reopen infer.

This task is the record of decision. If a linked document diverges, ask before building.

## Unresolved

| # | Kind | Question | Until answered |
|---|---|---|---|
| 1 | open | Municipal NFS-e (ABRASF / Ginfes / ISSNet): refuse vs treat as recibo | Criterion 14 refuses with the unsupported copy. Override before build if those files should persist as typed recibo. |
| 2 | open | National NFS-e amount: `vServ` vs `vLiq` | Criteria 5–6 use `vServ` `610.00` → `61000` (same role as NF-e `vNF`). |
| 3 | open | National NFS-e date: `dhEmi` vs `dCompet` | Criteria 5–6 use `dhEmi` (same as NF-e). |
