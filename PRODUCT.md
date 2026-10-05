# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Product truth

Do not restate these here:

- [`GLOSSARY.md`](GLOSSARY.md) — domain vocabulary. Use its terms.
- [`README.md`](README.md) — who uses the product, the close ritual, the locked platform, and what is out of this version.

Decisions that constrain later work live in [`docs/adr/`](docs/adr/).

## Design notes

- User-facing name is "Fechamento mensal". Do not show the repository name, and do not frame the product as an AI assistant. Copy is pt-BR.
- Coordinator: laptop, dense ledger. Submitter: phone. Mark: `public/icon.svg`.
- Each month screen leads with what still blocks the close. A blocked close is a fact with a reason.
- Amount, date, and payee from authorized XML or SEFAZ consulta beat typed values. Say when a value was typed.
- The product archives the package. It does not send it to the accountant.
- Pre-launch. Do not invent customers, usage figures, or testimonials. Demo data: anonymized fixtures in `spec/fixtures/files/`.
