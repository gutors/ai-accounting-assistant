# NF-e photo OCR Verification

**Verdict**: PASS
**Profile**: standard
**Diff range**: `eb00bd56f261d6c229790df55105b312870a1e0c`..`546fbc684cbc70aebba08e9049efaf77b973962d`
**Round**: 2 - scoped
**Verifier**: independent sub-agent (author != verifier)

HEAD `546fbc6`. Commits on the range: `4358bbb` docs(nfe): freeze printed-chave and photo-field OCR checks; `85a0dcd` feat(nfe): read printed chave and DANFE fields with Tesseract; `546fbc6` test(nfe): match Tesseract packages as whole tokens. Flow is tlc-implement (`.checks/nfe-photo-ocr.md` present; no `.specs/features/nfe-photo-ocr/checks.md`). No `plan.md`.

Round 1 FAIL at `85a0dcd`: C10 surviving mutant (`include?("tesseract-ocr")` matched inside `tesseract-ocr-por`). Fix `546fbc6` touched only `spec/config/application_spec.rb`. Proofs re-run in full at `546fbc6`. Sections the fix could not have touched are marked carried from `85a0dcd`.

## Binding sources

Step 1 (`ui` screens) skipped — no source marked binding; fix did not touch UI. Carried from `85a0dcd`.

| Source | Opened | Contradiction | Uncovered |
|---|---|---|---|
| (none marked binding) | n/a — step 1 empty | n/a | n/a |

## Checks

Proofs re-run at `546fbc6` in one invocation: `bundle exec ruby "$(bundle exec ruby -e 'puts Gem.bin_path("rspec-core", "rspec")')" spec/models/photo_symbols_spec.rb spec/models/photo_fields_spec.rb spec/config/application_spec.rb --example-matches "<C1|C2|…|C11 names>"` — 14 examples, 0 failures, 0 pending. Each named C1–C11 proof (C9 is four examples) exists (`rg -n` on those files) and passed in `/tmp/nfe-photo-ocr-proofs-r2.json` (`status=passed` each). Examples live in the feature diff (`eb00bd56..HEAD`), not in untouched pre-feature tests.

`bin/rspec` / `bundle exec rspec` are wrapped by `rtk` here and swallow `--format`; the rspec-core gem binary is the same runner. C1–C9 citations unchanged from `85a0dcd` (those files were not in `546fbc6`). C10/C11 citations refreshed.

| Check | Claim | Proof run | Evidence | Result |
|---|---|---|---|---|
| C1 | printed-digit PNG → chave `43260511222333000181550010000000011123456781`, `qr_url` nil | named example passed at `546fbc6` | `spec/models/photo_symbols_spec.rb:47-48` `result.chave).to eq(nfe_chave)` + `qr_url).to be_nil`. Same-file helper `:8-10` is the literal 44 digits. Citation carried from `85a0dcd` | PASS |
| C2 | same layout JPEG → same chave, `qr_url` nil | named example passed at `546fbc6` | `spec/models/photo_symbols_spec.rb:56-57` `eq(nfe_chave)` + `be_nil`. Citation carried from `85a0dcd` | PASS |
| C3 | PNG without 44 digits → chave nil | named example passed at `546fbc6` | `spec/models/photo_symbols_spec.rb:65` `result.chave).to be_nil`. Citation carried from `85a0dcd` | PASS |
| C4 | PNG DANFE fields → 15500, 2026-05-11, Padaria Central | named example passed at `546fbc6` | `spec/models/photo_fields_spec.rb:13-16` `be_a(PhotoFields::Fields)` + `amount_cents).to eq(15500)` + `document_on).to eq(Date.new(2026, 5, 11))` + `payee).to eq("Padaria Central")`. Citation carried from `85a0dcd` | PASS |
| C5 | same JPEG → same three values | named example passed at `546fbc6` | `spec/models/photo_fields_spec.rb:24-27` `eq(15500)` + `Date.new(2026, 5, 11)` + `eq("Padaria Central")`. Citation carried from `85a0dcd` | PASS |
| C6 | `amount_cents` Integer 15500, never Float | named example passed at `546fbc6` | `spec/models/photo_fields_spec.rb:35-37` `eq(15500)` + `be_a(Integer)` + `not_to be_a(Float)`. Citation carried from `85a0dcd` | PASS |
| C7 | PNG without amount/date/emitente → Miss | named example passed at `546fbc6` | `spec/models/photo_fields_spec.rb:45` `be_a(PhotoFields::Miss)`. Citation carried from `85a0dcd` | PASS |
| C8 | PNG with only amount is not a complete triple | named example passed at `546fbc6` | `spec/models/photo_fields_spec.rb:53-55` `complete` is Fields ∧ all three present; `expect(complete).to be(false)`. Citation carried from `85a0dcd` | PASS |
| C9 | missing Tesseract or subprocess error → chave nil and Miss (four proofs) | four named examples passed at `546fbc6` | `photo_symbols_spec.rb:74` `chave).to be_nil` · `:83` same · `photo_fields_spec.rb:64` `be_a(PhotoFields::Miss)` · `:73` same. Setup `:69/:78` and `:59/:68` set `PhotoOcr.binary` to missing path / `/bin/false`. Citation carried from `85a0dcd` | PASS |
| C10 | production Dockerfile `base` / runtime installs `tesseract-ocr` and `tesseract-ocr-por` | named example passed at `546fbc6` | `spec/config/application_spec.rb:52-55` split `base` on `FROM base AS build`, then `packages = base.split(/\s+/)` and `expect(packages).to include("tesseract-ocr", "tesseract-ocr-por")` — whole tokens, not substring. Refreshed after `546fbc6` | PASS |
| C11 | CI `test` job installs those packages before `bin/rspec` | named example passed at `546fbc6` | `spec/config/application_spec.rb:60-64` `packages = test_job.split(/\s+/)`; `packages.index("tesseract-ocr")` and `packages.index("tesseract-ocr-por")` both `< packages.index("bin/rspec")`. Refreshed after `546fbc6` | PASS |

## Coverage (recomputed)

Rows whose authority `546fbc6` did not touch are carried from `85a0dcd`. Tesseract host-packages recomputed from Landing door 1 and the two assemblies (`Dockerfile` `base` stage; CI `test` job).

| Set (authority) | Member -> proof | Unproven |
|---|---|---|
| printed-chave image type (2) — Landing / `PhotoOcr.extension` png+jpeg | PNG C1 · JPEG C2 | - |
| printed-chave miss (1) — C3 claim / `forty_four` | no 44-digit sequence C3 | - |
| field-reading image type (2) | PNG C4 · JPEG C5 | - |
| amount type (1) — AGENTS.md integer cents | Integer `15500` C6 | - |
| field-reading miss / partial (2) — `PhotoFields::Real#read` | none of the three → Miss C7 · amount only not complete C8 | - |
| Tesseract failure (2 modes × 2 ports) — Landing ENOENT / non-zero | missing symbols C9 · missing fields C9 · subprocess symbols C9 · subprocess fields C9 | - |
| Tesseract host packages (2 assemblies × 2 packages) — Landing door 1 | Dockerfile `base` `tesseract-ocr` C10 · Dockerfile `base` `tesseract-ocr-por` C10 · CI `test` `tesseract-ocr` C11 · CI `test` `tesseract-ocr-por` C11. Runtime `Dockerfile:19` is the `base` apt line (before `FROM base AS build` at `:31`; final `FROM base` at `:61`). CI `.github/workflows/ci.yml:69` installs both before `bin/rspec` at `:75`. Token `include` / `index` uniquely require each package (Faults 1–2) | - |
| startup config assemblies | `PhotoSymbols` / `PhotoFields` `current` / `Fake` / `Real` + `reset!` / `build` in each module (`photo_symbols.rb:10-24`, `photo_fields.rb:6-20`) | - |

- Claims naming a status code, route or response shape: none — C1–C11 are model / file assertions; no level gap
- No other check claims more than the single case its proof exercises
- Landing CLI `por+eng` / `--psm 6` is a door literal, not a Coverage set of outcomes; success proofs C1–C8 run that command but do not assert the argv — carried from `85a0dcd`

## Test policy rows

Artifact follows `.cursor/rules/rails.mdc` lines 49–51 (level + one asserted case per enumerated member; HTTP also a request spec). Re-judged for the file `546fbc6` touched: C10/C11 remain file assertions in `spec/config/application_spec.rb` (read Dockerfile / workflow), not HTTP. Other rows carried from `85a0dcd`.

| Row | Files it classifies | Required proof | Expectation met |
|---|---|---|---|
| Decides, and is reached across a boundary | none in this cut — `SupportingDocumentsController` unchanged; Out of scope keeps Fake submit specs | model **and** request (status / who at the boundary) | n/a this cut — HTTP who/status already #51; new OCR members proven at model C1–C9. C10/C11 are not this row |
| Decides, not reached across a boundary | `app/models/photo_symbols.rb` printed path; `app/models/photo_fields.rb` Real; `app/models/photo_ocr.rb` | own layer, one case per member | yes — PNG/JPEG/miss C1–C3 · fields C4–C8 · Tesseract miss C9 (both ports). `PhotoOcr` failure modes asserted via those consumers after `PhotoOcr.binary=` |
| Entry point that decides nothing | none added | request spec | n/a |
| Instrumentation / pass-through | `SupportingDocumentsController` (unchanged) | none of its own | yes — no new controller spec |
| File assertions (existing `application_spec` shape; checklist Cost) | `spec/config/application_spec.rb` C10/C11 | Dockerfile `base` and CI `test` host packages, not HTTP | yes — token membership C10 · token-before-`bin/rspec` C11 |

## Swept existing

Carried from `85a0dcd` — `546fbc6` did not touch these files.

- authorization: `SupportingDocumentsController` still `before_action :require_focused_organization` (`app/controllers/supporting_documents_controller.rb:2`). #51 C42 is the unauthenticated POST `302` `/login` on that same surface (`nfe-photo-extraction` C42)
- observability: `config/initializers/filter_parameter_logging.rb:7` still includes `:passphrase` and `:certificate`

## Faults injected

Round-1 C1–C9 surfaces were not in `546fbc6`; those kills are carried from `85a0dcd`. Re-injected at `546fbc6` on the surfaces the fix touched and created (C10/C11 token split). Cap five.

Scratch: `git worktree add /tmp/nfe-photo-ocr-verify-faults-r2 HEAD`. Real-tree porcelain before and after discard: `?? .checks/nfe-photo-ocr.verified.md`. Never stash.

| Mutation | Location | Killed |
|---|---|---|
| `printed_chave = nil` (skip `PhotoOcr.text`) | `app/models/photo_symbols.rb` scan | yes — carried from `85a0dcd` (C1) |
| `parse_emitente` always `nil` | `app/models/photo_fields.rb` | yes — carried from `85a0dcd` (C4) |
| `amount_cents` returned `cents.to_f` | `app/models/photo_fields.rb` `parse_amount` | yes — carried from `85a0dcd` (C6) |
| Dockerfile `base` keeps only `tesseract-ocr-por` (drops `tesseract-ocr`) | `Dockerfile` apt line | **yes** at `546fbc6` — C10 `expected […] to include "tesseract-ocr"` (`application_spec.rb:55`). Round-1 survivor |
| CI `test` job lists only `tesseract-ocr-por` | `.github/workflows/ci.yml:69` | **yes** at `546fbc6` — C11 `expected: < 80 got: nil` (`application_spec.rb:63`). Round-1 both-packages half never mutated |
| CI `test` job: Install Tesseract moved after `bin/rspec` | `.github/workflows/ci.yml` | **yes** at `546fbc6` — C11 `expected: < 64 got: 80` (`application_spec.rb:63`). Re-injected because token `index` replaced string `index` |

Three re-injections this round (plus three carried). No survivor.

## Gate

`bundle exec ruby` rspec-core gem binary (three files, `--example-matches` of all C1–C11 names) at `546fbc6` — 14 passed, 0 failed. Fault injection this round: 3 re-injected, 3 killed; 3 C1–C9 kills carried from `85a0dcd`. Real tree porcelain after worktree remove: `?? .checks/nfe-photo-ocr.verified.md` (matches baseline).

## Gaps (ranked)

None. Round-1 C10 substring mutant is killed. Round-1 C11 both-packages residual is killed.
