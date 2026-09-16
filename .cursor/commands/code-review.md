Review the relevant code (the current diff, or files/branches named in the request) with a code review mindset.

- Prioritize bugs, behavioral regressions, security issues, and missing tests.
- Findings are the primary output, ordered by severity (most severe first).
- Check against this repo's own conventions before inventing new ones: `.cursor/rules/rails.mdc` for Ruby/Rails/Hotwire conventions, `AGENTS.md` for stack and process rules, `CONTEXT.md` for domain vocabulary.
- Do not make code changes unless the user explicitly asks you to.

Run this before opening a pull request to `main` (see AGENTS.md "Pull requests" section).
