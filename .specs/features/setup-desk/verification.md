# Setup desk verification

**Verdict**: FAIL
**Mutations**: 3 - probed C13, C7, C19
**Proofs**: `proofs.md` at 382107c
**Verifier**: independent sub-agent (author != verifier)

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| C19 proves first-incomplete only when that item is archive, not list order across keys | `spec/models/setup_desk_spec.rb` absent/empty/unknown all `persist_standing_accountant` then `eq("archive")`; complete setup is the other branch. `incomplete?("archive") ? "archive" : "accountant"` stays green. Unnamed GET `/setup` with accountant+archive complete and missing A1 did select `certificate` at HEAD | assert selected `certificate` when earlier items are complete and A1 is missing (and/or `banks` when that is the first Falta) | `b03e73d` C19 `missing A1 after complete accountant and archive selects certificate` |
| Blank Contador has no Falta / red-margin check | Coverage incomplete stamps omit accountant; C5 only covers `Cadastrado` without red margin; C16/C26 prove pane cadastro, not the index stamp. `stamp_for("accountant")` can stop returning `Falta` and no named check fails | request example: blank Contador row is `Falta` in `margem` with `is-block` | `b03e73d` C33 |
