import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.45.4";
import { HttpError, requireEnv } from "./http.ts";

let admin: SupabaseClient | undefined;

// Service-role client. Bypasses RLS: only use after checking who the caller is.
export function adminClient(): SupabaseClient {
  admin ??= createClient(requireEnv("SUPABASE_URL"), requireEnv("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return admin;
}

export async function requireUser(req: Request): Promise<{ id: string }> {
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) throw new HttpError(401, "NOT_SIGNED_IN");
  const { data, error } = await adminClient().auth.getUser(token);
  if (error || !data.user) throw new HttpError(401, "NOT_SIGNED_IN");
  return { id: data.user.id };
}

// Business-rule errors raised in SQL (e.g. raise exception 'ALREADY_UNLOCKED')
// come back as the error message. Turn the known ones into 4xx responses.
const KNOWN_DB_ERRORS: Record<string, number> = {
  LISTING_NOT_AVAILABLE: 409,
  CANNOT_UNLOCK_OWN_LISTING: 409,
  ALREADY_UNLOCKED: 409,
  ORDER_NOT_FOUND: 404,
  AMOUNT_MISMATCH: 409,
};

export function dbError(error: { message: string }): Error {
  const status = KNOWN_DB_ERRORS[error.message];
  if (status) return new HttpError(status, error.message);
  return new Error(`Database error: ${error.message}`);
}
