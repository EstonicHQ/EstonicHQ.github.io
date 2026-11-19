export type Profile = {
  id: string;
  username: string;
  display_name: string;
  created_at: string;
  updated_at: string;
};

export type AuthResult = {
  needsEmailVerification: boolean;
};

export type UsernameAvailability = {
  available: boolean;
  error: string | null;
};

export function isEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

export function isValidUsername(username: string): boolean {
  return /^[a-z0-9_]{3,24}$/.test(username);
}

export type AuthError = { message: string };
