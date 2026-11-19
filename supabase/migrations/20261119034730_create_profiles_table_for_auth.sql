/*
# Create profiles table and username helpers for authentication

1. Plain-English explanation
- Estonic ID needs a place to store each user's public identity (username and
  display name) next to their Supabase Auth account. This migration creates the
  `public.profiles` table for that, plus two small helper functions the sign-up
  and sign-in forms will call.

2. New Tables
- `public.profiles`
  - `id` (uuid, primary key): matches the Supabase Auth user's id exactly.
  - `username` (text, unique, required): 3-24 characters, lowercase letters,
    digits and underscores only. The UNIQUE constraint enforces username
    uniqueness at the database level, even if two people sign up at the same
    moment.
  - `display_name` (text, required): the name shown in the app.
  - `created_at` / `updated_at` (timestamps, with defaults).

3. New Functions (SECURITY DEFINER, locked search_path)
- `is_username_available(p_username text)`: returns true/false so the sign-up
  form can check a username before creating an account. Callable by anon and
  authenticated.
- `get_email_for_username(p_username text)`: returns the email address for a
  username so "sign in with username" can be converted into Supabase Auth's
  email + password sign-in. Callable by anon and authenticated. Supabase Auth
  does not support username sign-in natively, so this lookup is required.

4. Security
- Row Level Security is ENABLED on `public.profiles`.
- Grants: `authenticated` may SELECT, INSERT (id, username, display_name) and
  UPDATE (username, display_name). No grants for `anon` on the table itself.
- Policies (owner-scoped only):
  - SELECT own profile (auth.uid() = id)
  - INSERT own profile (auth.uid() = id)
  - UPDATE own profile (auth.uid() = id)
  - No DELETE policy: profiles are removed automatically when the auth user is
    deleted (ON DELETE CASCADE).
- Helper functions run as the owner (SECURITY DEFINER) but return only the
  minimum data needed (an availability boolean, or an email for sign-in), and
  EXECUTE is revoked from PUBLIC then granted explicitly.

5. Important notes
- This migration does NOT modify any existing tables, policies or triggers
  (the public schema was empty).
- A user's profile row is created by the app right after a successful sign-up
  while the user's session is active, so the ownership policy applies.
*/

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text NOT NULL UNIQUE CHECK (username ~ '^[a-z0-9_]{3,24}$'),
  display_name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT (id, username, display_name), UPDATE (username, display_name)
  ON public.profiles TO authenticated;

DROP POLICY IF EXISTS "select_own_profile" ON public.profiles;
CREATE POLICY "select_own_profile" ON public.profiles
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "insert_own_profile" ON public.profiles;
CREATE POLICY "insert_own_profile" ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "update_own_profile" ON public.profiles;
CREATE POLICY "update_own_profile" ON public.profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.is_username_available(p_username text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p_username ~ '^[a-z0-9_]{3,24}$'
    AND NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE username = p_username
    );
$$;

REVOKE EXECUTE ON FUNCTION public.is_username_available(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_username_available(text) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_email_for_username(p_username text)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.email
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE p.username = p_username
  LIMIT 1;
$$;

REVOKE EXECUTE ON FUNCTION public.get_email_for_username(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_email_for_username(text) TO anon, authenticated;
