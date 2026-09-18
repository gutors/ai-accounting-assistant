# SEFAZ A1 ciphertext in Postgres, wrap key from the environment

The organization’s optional A1 is one slot of standing fields on `Organization`, not a working file. The PKCS#12 and passphrase are ciphertext in Postgres. The wrapping key is `ENV["SEFAZ_WRAP_KEY"]` (`WrapKey`), not Rails credentials and not a column. `GET /sefaz_certificate` is always `404`. Leaf titular is the 14 digits on the certificate as written (módulo-11 is not the install gate — C13’s `12345678000101` would fail it).

## Status

accepted

## Considered options

- **`has_one :sefaz_certificate` row.** Rejected: #27 is one slot on the organization, same as accountant fields.
- **Active Storage / object store.** Rejected: AGENTS.md encrypts in Postgres; the file must not be downloadable; container disk is ephemeral.
- **Rails credentials as the wrap key.** Rejected: AGENTS.md says process environment.
- **Matching titular CNPJ to an organization tax id.** Rejected: #27 this version has none.
- **`BrazilianTaxId.cnpj?` as the install gate.** Rejected: C13’s titular `12345678000101` fails módulo-11.

## Consequences

- Later secrets-in-Postgres copy wrap-key-from-env (`WrapKey`), not Active Storage.
- Identified consulta unwraps on the server. Browser, Stimulus, and views never see the PKCS#12 or passphrase.
- A blank wrap key refuses a new install and skips identified consulta; `/setup` and close-for-send still succeed.
