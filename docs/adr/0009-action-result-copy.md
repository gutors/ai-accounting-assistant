# Action-result copy in one module

A finished action reports what it changed through a single `app/models/action_toast.rb`, one
function per action returning a `String`. Controllers pick the function and never build the
sentence.

## Status

accepted

## Considered options

- **A message literal at each call site.** Rejected: `Pronto.` survived fourteen callers precisely
  because each one could write its own text, so the wording had no review point and no way to say
  which row on a list of twelve had changed.
- **One set of constants per model** (`BankAccount::DEACTIVATED`, `Month::CLOSED_FOR_SEND`, …).
  Rejected: the formatting rules — truncation at 40 characters, BRL through `format_reais`, month
  through `month_title` — would be duplicated once per entity, and the nouns that appear in one
  sentence (`Extrato`, `Casamento`, `Exceção`) do not belong to any single record.
- **`config/locales/pt-BR.yml` under an `action_toast:` key.** Rejected: the copy is not static. A
  sentence names a record's own value (`Ana Contábil`, `11.222.333/0001-81`, `R$ 220,00`), so the
  interpolation and the plural rules would live in the templates anyway, and the repo keeps product
  copy in model constants and views rather than in I18n. ADR-0001 established no I18n layer.
- **`app/models/action_toast.rb` with one class method per action (chosen).** Two private helpers
  carry the formatting rules: `name_of` truncates a named value at `NAME_MAX` and `money` delegates
  to `ApplicationHelper#format_reais`. `month_title` is reimplemented locally because the helper's
  version goes through the view `l`, which a model does not have.

## Consequences

- `ApplicationController#redirect_success(path, message)` takes the message as a required positional
  argument, so no caller can fall back to a generic success sentence. `redirect_with_toast` writes
  no toast when the message is blank.
- A new action adds one function here plus one call; the sentence is reviewed in the diff of this
  file rather than at the call site.
- `ActionToast` is a PORO at the layer of `BrlCents` and `BrazilianTaxId`: no persistence, no
  request state, proven at the model layer with one example per action, and again at the boundary
  in the request spec that already covers the route.
- When an action's row disappears, the controller reads the value it will name **before** the
  destroy — `AccessesController#destroy` captures the e-mail, `MatchesController#destroy` the
  payee, `SupportingDocumentsController#destroy` the payee.
- A typed value (an extra exception kind) is punctuation-delimited data rather than the subject of
  the verb, so `Exceção marcada: Doação, R$ 45,00.` stays grammatical for any kind a coordinator
  invents. Any future sentence that makes a typed value the subject needs a gender source first.
