/*
# Tighten grants on public.profiles

1. Plain-English explanation
- Supabase grants broad default privileges to the `anon` and `authenticated`
  roles on new tables. This migration revokes those defaults and re-applies the
  minimum privileges the app actually needs, so the intended restrictions hold.

2. Modified Tables
- `public.profiles`: privilege grants only. No columns, rows or policies change.

3. Security changes
- `anon`: all privileges revoked (unauthenticated visitors have no policy
  access anyway, so the table was already unreachable to them).
- `authenticated`: keep SELECT on all columns; keep INSERT and UPDATE limited
  to (id, username, display_name) / (username, display_name) respectively;
  revoke DELETE (profiles are removed via ON DELETE CASCADE with the auth user).
*/

REVOKE ALL ON public.profiles FROM anon;

REVOKE INSERT, UPDATE, DELETE ON public.profiles FROM authenticated;

GRANT SELECT ON public.profiles TO authenticated;
GRANT INSERT (id, username, display_name) ON public.profiles TO authenticated;
GRANT UPDATE (username, display_name) ON public.profiles TO authenticated;
