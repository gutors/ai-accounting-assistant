# month-list-font-size proofs

**HEAD**: 2ee2124
**Tree**: dirty - .impeccable/design.json, app/assets/tailwind/application.css
**Result**: 2 pass, 1 fail; mutations 0 killed, 0 not

| Check | Proof | Ran | Passed | Result |
| --- | --- | --- | --- | --- |
| C1 | `walk - open the month overview and inspect the three lists and their computed font sizes` | - | - | pass (Walked) |
| Build | `bin/rubocop` | - | - | **fail** - bin/rubocop:9:in '<main>' |
| Build | `bin/erb_lint --lint-all` | - | - | pass |
