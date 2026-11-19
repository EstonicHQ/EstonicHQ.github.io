# Project memory

## Product intent & audience

- Project name: **Estonic ID** — purpose and target audience not yet defined beyond the name suggesting an identity-related product.
- Current phase: technical foundation only; no product features or pages have been built.

## Brand personality & voice

- Not yet established — user explicitly deferred all design and branding decisions.

## Visual design & UX direction

- Explicitly deferred — no theme, colors, typography, branding, navbar, or visual layout.
- Only a minimal temporary placeholder screen exists (single message: "setup complete, UI comes later").
- No website pages (signup, login, dashboard, etc.) created yet.

## Decisions, constraints & rationale

- **Tech stack:** React + TypeScript + Vite; strict type-checking enabled; build verified clean.
- **Backend client:** `@supabase/supabase-js` installed; Supabase client configured to read `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from environment variables, with a runtime error if missing.
- **Secrets handling:** `.env` confirmed in `.gitignore`; `.env.example` documents the two required variables; no credentials invented or hardcoded.
- **Scope guardrails:** No UI design, no pages, no theme, no deployment — foundation only.
- Rationale: prepare the codebase for development before making any design or feature decisions.

## Open questions & assumptions

- What is the actual product purpose of Estonic ID (identity verification? e-residency? authentication?)?
- What pages/features will be needed once UI work begins?
- What is the target audience (Estonian citizens, e-residents, developers, etc.)?
- Supabase schema and auth configuration not yet discussed.