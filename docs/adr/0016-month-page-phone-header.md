# The month page header keeps its own phone wrap

The prototype behind `month-statement-row` (`.impeccable/mocks/statement-inline.html`) draws the
phone header as a three-line brand block with the nav in a right-hand two-column block beside it.
The product's header is the shared `layouts/_header`: below 640px the brand takes one line and the
nav wraps under it, left-aligned at the gutter, with the same five labels in the same order.

That difference is the header's, not the month page's. `month-statement-row` changes the statement
control and the payment row only; it does not reach `layouts/_header`, which every signed-in screen
draws. Changing the wrap here would change every screen's phone header inside a feature about the
extrato action.

## Status

accepted - user: "Aceitar - registrar como diferença aprovada; o header do app continua como está"

## Considered options

- **Reproduce the sketch's phone wrap inside this feature.** Rejected: `layouts/_header` is shared by
  every signed-in screen, so a wrap changed here ships to the month index, the documents book,
  Configuração and Administração as well. That is a header decision, and it needs its own feature
  with its own captures at both widths.
- **Retake the capture with a phone header the product already draws.** Rejected: a capture is
  changed by the user, not by the builder, and the sketch's wrap is what the header would have to
  become for the picture to match.
- **Record it as an approved difference and leave the header as it is.** Chosen: the link set, its
  order and the underlined `Sair` already match, and nothing in the statement row or the payment
  sheet depends on where the nav wraps.

## Consequences

- `screens.md` round 2 records the nav arrangement as an accepted difference citing this ADR, not a
  finding, and both pictures read `matches`.
- A later feature that reshapes the phone header decides the wrap on its own terms, with its own
  captures.
