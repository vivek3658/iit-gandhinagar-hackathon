CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  google_id TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  avatar_url TEXT,
  dob TEXT,
  district TEXT,
  ward TEXT,
  house_type TEXT,
  household_members INT,
  monthly_bill_rupees NUMERIC,
  water_supply_type TEXT,
  water_storage_type TEXT,
  device_catalog_ids JSONB DEFAULT '[]'::jsonb,
  vehicle_catalog_ids JSONB DEFAULT '[]'::jsonb,
  mascot_name TEXT,
  role TEXT NOT NULL DEFAULT 'CITIZEN',
  is_profile_complete BOOLEAN DEFAULT FALSE,
  points INT DEFAULT 50,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.refresh_tokens (
  token_hash TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  expires_at BIGINT NOT NULL,
  revoked_at BIGINT
);

CREATE INDEX IF NOT EXISTS idx_users_google_id ON public.users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON public.refresh_tokens(user_id);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refresh_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_all_anon" ON public.users;
CREATE POLICY "users_all_anon" ON public.users FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "users_all_authenticated" ON public.users;
CREATE POLICY "users_all_authenticated" ON public.users FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "users_all_service_role" ON public.users;
CREATE POLICY "users_all_service_role" ON public.users FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "refresh_tokens_all_anon" ON public.refresh_tokens;
CREATE POLICY "refresh_tokens_all_anon" ON public.refresh_tokens FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "refresh_tokens_all_authenticated" ON public.refresh_tokens;
CREATE POLICY "refresh_tokens_all_authenticated" ON public.refresh_tokens FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "refresh_tokens_all_service_role" ON public.refresh_tokens;
CREATE POLICY "refresh_tokens_all_service_role" ON public.refresh_tokens FOR ALL TO service_role USING (true) WITH CHECK (true);

GRANT ALL ON TABLE public.users TO postgres, anon, authenticated, service_role;
GRANT ALL ON TABLE public.refresh_tokens TO postgres, anon, authenticated, service_role;
