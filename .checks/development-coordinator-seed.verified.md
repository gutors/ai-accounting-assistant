# Development coordinator seed Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: `151e5944144de20dcb01fb3d2a4e3ea7e0012aca..f9382882eb6a97fd1b6f9856557284158b1d2b7c`
**Round**: 1 - full
**Verifier**: independent sub-agent (author != verifier)

## Binding sources

No design source. No binding screen. Step 1 is a line, not an investigation.

| Source | Opened | Contradiction | Uncovered |
| --- | --- | --- | --- |
| (none marked binding) | n/a | n/a | n/a |

## Checks

| Check | Claim | Proof run | Evidence | Result |
| --- | --- | --- | --- | --- |
| C1 | plant yields ONG Exemplo, gutors@gmail.com with nil google_uid, one coordinator Access, no Invite, no submitter | `bin/rspec` batch exit 0 — example passed | `spec/models/development_coordinator_seed_spec.rb:11-20` — `Organization.find_by!(name: "ONG Exemplo")`; `Account.find_by!(email: "gutors@gmail.com")`; `expect(account.google_uid).to be_nil`; `expect(access.kind).to eq("coordinator")`; `expect(Access.where(kind: "submitter").count).to eq(0)`; `expect(Invite.count).to eq(0)` | PASS |
| C2 | second plant leaves Organization/Account/Access counts unchanged | same batch — example passed | `spec/models/development_coordinator_seed_spec.rb:26-27` — `.not_to change { [ Organization.count, Account.count, Access.count ] }` | PASS |
| C3 | existing gutors@gmail.com leaves Organization/Access counts and google_uid unchanged | same batch — example passed | `spec/models/development_coordinator_seed_spec.rb:33-36` — `.not_to change { [ Organization.count, Access.count ] }`; `expect(account.reload.google_uid).to eq("uid-existing")` | PASS |
| C4 | raise from Account.create! before commit leaves counts unchanged | same batch — example passed | `spec/models/development_coordinator_seed_spec.rb:45-47` — `raise_error(RuntimeError, "before commit")` nested in `.not_to change { [ Organization.count, Account.count, Access.count ] }` | PASS |
| C5 | loading seeds.rb when not development persists no gutors@gmail.com Account | same batch — example passed | `spec/db/seeds_spec.rb:5-8` — `expect(Rails.env.development?).to be(false)`; `.not_to change { Account.where(email: "gutors@gmail.com").count }` | PASS |
| C7 | loading seeds.rb in development plants ONG Exemplo and gutors@gmail.com with coordinator Access | same batch — example passed | `spec/db/seeds_spec.rb:16-23` — `Organization.count`/`Account.count`/`Access.count` eq 1; `google_uid` nil; `access.kind` eq `"coordinator"` | PASS |
| C6 | README ## Estado notes db:seed, development, ONG Exemplo, gutors@gmail.com, coordenador | same batch — example passed | `spec/db/seeds_spec.rb:29-33` — `expect(note).to include(...)` for each of those five strings | PASS |

Proof invocation (one call, seven named examples, all passed):

```
bin/rspec spec/models/development_coordinator_seed_spec.rb spec/db/seeds_spec.rb \
  -e "plants ONG Exemplo and gutors@gmail.com with nil google_uid" \
  -e "second plant leaves Organization Account and Access counts unchanged" \
  -e "existing gutors@gmail.com leaves counts and google_uid unchanged" \
  -e "raise from Account.create! before commit leaves counts unchanged" \
  -e "loading seeds.rb when not development persists no gutors@gmail.com Account" \
  -e "loading seeds.rb in development plants ONG Exemplo and gutors@gmail.com" \
  -e "README local note states development db:seed persists ONG Exemplo and gutors@gmail.com"
```

JSON summary: 7 examples, 0 failures. Each full description listed as `passed`. Specs land in `f938288` on this range.

## Coverage (recomputed)

Authority: `app/models/development_coordinator_seed.rb` (`Account.exists?` guard + one transaction) and `db/seeds.rb` (`Rails.env.development?` gate). Landing’s development-only door is the same env gate.

| Set (size) | Members from code | Member -> proof | Unproven |
| --- | --- | --- | --- |
| planter account presence (2) | absent → continues; present → `return` | absent C1 · present C2, C3 | - |
| planter transaction (1) | three writes in `ActiveRecord::Base.transaction` | raise before commit C4 | - |
| `db/seeds.rb` `Rails.env.development?` (2) | `plant! if development?` | false C5 · true C7 | - |

No status/route/response-shape claims. No set named in Landing, Test policy evidence, or claims without a row.

## Test policy rows

| Row | Files it classifies | Required proof | Expectation met |
| --- | --- | --- | --- |
| Decides, and is reached across HTTP | (none in this change) | model + request; one case per member | follow — no HTTP boundary |
| Decides, not reached across HTTP | `app/models/development_coordinator_seed.rb`; `db/seeds.rb` | own layer; one case per member | yes — planter C1–C4 at model; env gate C5/C7 by loading `db/seeds.rb` |
| Entry point or adapter that decides nothing | (none) | boundary | follow — none here |
| Instrumentation / pass-through | (none of its own) | consumer | follow |

## Swept existing

| Row | Cited constraint | Present |
| --- | --- | --- |
| validation: Account rejects duplicate or ill-formed email; email normalized | `Account` uniqueness + well-formed + normalize | yes — `app/models/account.rb:9-12`, `:17-22` |

Other Swept rows are n/a or check-backed (C2, C4); nothing further to re-read in code.

## Faults injected

Scratch worktree at detached `f938288`; real-tree porcelain empty before and after (matched baseline).

| Mutation | Location | Killed |
| --- | --- | --- |
| `ORGANIZATION_NAME` `"ONG Exemplo"` → `"ONG Errada"` | `app/models/development_coordinator_seed.rb:3` | yes — C1 failed |
| removed `return if Account.exists?(email: EMAIL)` | `app/models/development_coordinator_seed.rb:6` | yes — C2 failed |
| removed `ActiveRecord::Base.transaction` wrapper | `app/models/development_coordinator_seed.rb:8-12` | yes — C4 failed |
| `plant! if Rails.env.development?` → `unless` | `db/seeds.rb:3` | yes — C5 failed |
| Estado note dropped `coordenadora` (no `coordenador` in section) | `README.md` ## Estado | yes — C6 failed |

C3 shares the early-return surface with C2; C7 shares the env-gate surface with C5. Cap five; every distinct assertion surface killed once. No surviving mutant.

## Gate

`bin/rspec` (seven named proofs, one invocation) — 7 passed, 0 failed
