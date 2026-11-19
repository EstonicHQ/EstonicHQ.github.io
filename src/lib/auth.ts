import { supabase } from './supabase';
import type { Profile, AuthResult, UsernameAvailability } from './auth-types';
import { isEmail, isValidUsername } from './auth-types';

export type SignUpInput = {
  email: string;
  username: string;
  displayName: string;
  password: string;
};

export type SignInInput = {
  identifier: string;
  password: string;
};

export async function checkUsernameAvailability(
  username: string,
): Promise<UsernameAvailability> {
  const normalized = username.trim().toLowerCase();
  if (!isValidUsername(normalized)) {
    return {
      available: false,
      error:
        'Usernames must be 3-24 characters using lowercase letters, numbers, and underscores.',
    };
  }
  const { data, error } = await supabase.rpc('is_username_available', {
    p_username: normalized,
  });
  if (error) return { available: false, error: 'Could not check that username. Try again.' };
  return { available: data === true, error: null };
}

export async function signUp(input: SignUpInput): Promise<AuthResult> {
  const email = input.email.trim().toLowerCase();
  const username = input.username.trim().toLowerCase();
  const displayName = input.displayName.trim();

  if (!isEmail(email)) throw new Error('Please enter a valid email address.');
  if (!isValidUsername(username))
    throw new Error(
      'Usernames must be 3-24 characters using lowercase letters, numbers, and underscores.',
    );
  if (displayName.length < 1 || displayName.length > 60)
    throw new Error('Please enter a display name (up to 60 characters).');
  if (input.password.length < 8)
    throw new Error('Passwords must be at least 8 characters.');

  const availability = await checkUsernameAvailability(username);
  if (availability.error) throw new Error(availability.error);
  if (!availability.available) throw new Error('That username is already taken.');

  const { data, error } = await supabase.auth.signUp({
    email,
    password: input.password,
    options: {
      data: { username, display_name: displayName },
    },
  });

  if (error) {
    if (error.message.includes('already registered')) {
      throw new Error('An account with this email already exists. Try signing in.');
    }
    throw new Error(error.message);
  }

  const userId = data.user?.id;
  if (data.session && userId) {
    const { error: profileError } = await supabase.from('profiles').insert({
      id: userId,
      username,
      display_name: displayName,
    });
    if (profileError) throw new Error(profileError.message);
  }

  return { needsEmailVerification: !data.session };
}

export async function signIn({ identifier, password }: SignInInput): Promise<void> {
  const value = identifier.trim();
  const isEmailSignIn = isEmail(value);

  if (!isEmailSignIn && !isValidUsername(value)) {
    throw new Error('Enter a valid email address or username.');
  }

  let email = value;
  if (!isEmailSignIn) {
    const { data, error } = await supabase.rpc('get_email_for_username', {
      p_username: value.toLowerCase(),
    });
    if (error || !data) {
      throw new Error('No account found with that username.');
    }
    email = data;
  }

  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    if (error.message.includes('Invalid login credentials')) {
      throw new Error('Incorrect email/username or password.');
    }
    throw new Error(error.message);
  }
}

export async function signOut(): Promise<void> {
  const { error } = await supabase.auth.signOut();
  if (error) throw new Error(error.message);
}

export async function getCurrentProfile(): Promise<Profile | null> {
  const { data: sessionData, error: sessionError } = await supabase.auth.getSession();
  if (sessionError) throw new Error(sessionError.message);
  const userId = sessionData.session?.user?.id;
  if (!userId) return null;

  const { data, error } = await supabase
    .from('profiles')
    .select('id, username, display_name, created_at, updated_at')
    .eq('id', userId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return data ?? null;
}

export function onAuthStateChange(
  callback: (profile: Profile | null) => void,
): () => void {
  let latestUserId: string | null = null;

  const { data } = supabase.auth.onAuthStateChange((event, session) => {
    void (async () => {
      const userId = session?.user?.id ?? null;
      if (userId === latestUserId && event !== 'SIGNED_OUT') return;
      latestUserId = userId;
      try {
        const profile = userId ? await getCurrentProfile() : null;
        if ((session?.user?.id ?? null) !== latestUserId) return;
        callback(profile);
      } catch {
        callback(null);
      }
    })();
  });

  return () => data.subscription.unsubscribe();
}

export async function initializeAuth(callback: (profile: Profile | null) => void): Promise<() => void> {
  const profile = await getCurrentProfile();
  callback(profile);
  return onAuthStateChange(callback);
}
