# Rails 8 + Hotwire instead of Next.js

Platform v1 was Next.js App Router + TypeScript (one process, scale-to-zero container). We reopened that lock and chose **Rails 8** on MRI, Puma, server-rendered HTML with **Hotwire** (Turbo + Stimulus), and **RSpec**. Rails still matches the operational shape we need — one process, request timeout in minutes for **close-for-send**, not Lambda-style functions — and we would rather write that app in Rails than in Next.

## Status

accepted

## Considered options

- **Stay on Next.js App Router + TypeScript.** Rejected: the operator UI is a conventional server-rendered product, not a reason to keep a JS-first stack.
- **Rails API + separate SPA, or Inertia.js + React.** Rejected: that splits UI and server and would keep React/shadcn. Hotwire is the Rails analog of the old “one process, HTML on the server” rule.
- **Rails 8 + Hotwire + RSpec (chosen).** Tailwind stays; shadcn/ui does not. Minitest is the `rails new` default; we took RSpec instead.

## Consequences

- Product code starts from a `Gemfile` / `bin/rails`, not `package.json`. Conventions: `.cursor/rules/rails.mdc`.
- Persistence is Active Record on PostgreSQL. Money stays integer cents (`bigint` / Ruby `Integer`).
- Auth is still Google OIDC on the server (`openid email` only). The OmniAuth/OIDC gem is picked in Design of the first auth feature — not Devise by default.
- Working files stay behind the opaque blob interface. Active Storage is allowed only if that feature’s Design chooses it as the interface.
- **Close-for-send** may be a long Puma request or an Active Job (Solid Queue, no Redis); pick in Design of that feature.
- Cold start on a sleeping container is heavier than Next. Host brand is still not locked.
- A future reader should not “fix” this back to Next, React, or shadcn without reopening platform.
