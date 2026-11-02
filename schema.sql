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

CREATE TABLE IF NOT EXISTS public.daily_quests (
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  quest_date DATE NOT NULL,
  quests JSONB NOT NULL,
  streak_days INT NOT NULL DEFAULT 0,
  streak_claimed BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (user_id, quest_date)
);

CREATE INDEX IF NOT EXISTS idx_users_google_id ON public.users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON public.refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_quests_date ON public.daily_quests(quest_date);

CREATE TABLE IF NOT EXISTS public.utility_readings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  utility TEXT NOT NULL CHECK (utility IN ('ELECTRICITY', 'WATER', 'GAS')),
  value NUMERIC NOT NULL CHECK (value > 0),
  unit TEXT NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  provider_id TEXT,
  source_reference TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (period_start <= period_end)
);

CREATE INDEX IF NOT EXISTS idx_utility_readings_user_period
  ON public.utility_readings(user_id, period_end DESC);

CREATE TABLE IF NOT EXISTS public.citizen_vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  vehicle_type TEXT NOT NULL,
  fuel_type TEXT NOT NULL,
  make TEXT,
  model TEXT,
  model_year INTEGER,
  efficiency NUMERIC,
  efficiency_unit TEXT,
  registration_label TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_citizen_vehicles_owner
  ON public.citizen_vehicles(user_id) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS public.citizen_activities (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  category TEXT NOT NULL,
  icon TEXT NOT NULL,
  coins_earned INTEGER,
  co2_saved_kg NUMERIC,
  district TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_citizen_activities_owner_created
  ON public.citizen_activities(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.activity_read_status (
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  activity_id UUID NOT NULL REFERENCES public.citizen_activities(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, activity_id)
);

CREATE TABLE IF NOT EXISTS public.confirmed_trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  idempotency_key TEXT NOT NULL,
  mode TEXT NOT NULL,
  distance_km NUMERIC NOT NULL CHECK (distance_km > 0 AND distance_km <= 2000),
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ NOT NULL,
  vehicle_id UUID REFERENCES public.citizen_vehicles(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, idempotency_key),
  CHECK (ended_at > started_at)
);

CREATE INDEX IF NOT EXISTS idx_confirmed_trips_user_started
  ON public.confirmed_trips(user_id, started_at DESC);

CREATE TABLE IF NOT EXISTS public.device_runtime_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  log_date DATE NOT NULL,
  operating_hours NUMERIC NOT NULL CHECK (operating_hours > 0 AND operating_hours <= 24),
  rated_power_kw NUMERIC NOT NULL CHECK (rated_power_kw > 0),
  energy_consumed_kwh NUMERIC NOT NULL CHECK (energy_consumed_kwh >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, device_id, log_date)
);

CREATE INDEX IF NOT EXISTS idx_device_runtime_logs_owner_date
  ON public.device_runtime_logs(user_id, log_date DESC);

CREATE TABLE IF NOT EXISTS public.citizen_gardens (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  placed_tiles JSONB NOT NULL DEFAULT '[]'::jsonb,
  inventory JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.citizen_mascots (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  mascot_id UUID NOT NULL UNIQUE,
  mascot_type TEXT NOT NULL CHECK (mascot_type IN ('sparrow', 'squirrel')),
  name TEXT NOT NULL,
  level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 100),
  current_exp INTEGER NOT NULL DEFAULT 0 CHECK (current_exp >= 0),
  vitality INTEGER NOT NULL CHECK (vitality BETWEEN 0 AND 100),
  equipped JSONB NOT NULL DEFAULT '{}'::jsonb,
  owned_accessories JSONB NOT NULL DEFAULT '[]'::jsonb,
  last_interacted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.citizen_cheers (
  visitor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  host_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (visitor_id, host_id),
  CHECK (visitor_id <> host_id)
);

CREATE TABLE IF NOT EXISTS public.citizen_provider_links (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  electricity_provider_id TEXT,
  gas_provider_id TEXT,
  water_provider_id TEXT,
  transit_provider_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  consumer_numbers JSONB NOT NULL DEFAULT '{}'::jsonb,
  linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.chapter_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  chapter_id TEXT NOT NULL,
  chapter_version INTEGER NOT NULL,
  coin_reward INTEGER NOT NULL CHECK (coin_reward >= 0),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, chapter_id, chapter_version)
);

CREATE TABLE IF NOT EXISTS public.waste_game_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reward_date DATE NOT NULL,
  idempotency_key TEXT NOT NULL,
  answers JSONB NOT NULL,
  correct_count INTEGER NOT NULL,
  item_count INTEGER NOT NULL,
  coin_reward INTEGER NOT NULL CHECK (coin_reward >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, reward_date),
  UNIQUE (user_id, idempotency_key)
);

ALTER TABLE public.daily_quests
  ADD COLUMN IF NOT EXISTS streak_claimed BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS public.tenant_admin_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  display_name TEXT NOT NULL,
  tenant_type TEXT NOT NULL CHECK (tenant_type IN ('PROVIDER', 'CITY')),
  tenant_id TEXT NOT NULL,
  districts JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT tenant_admin_accounts_email_key UNIQUE (email)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_tenant_admin_email_ci
  ON public.tenant_admin_accounts (LOWER(email));
CREATE INDEX IF NOT EXISTS idx_tenant_admin_scope
  ON public.tenant_admin_accounts (tenant_type, tenant_id) WHERE is_active;

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id TEXT NOT NULL,
  actor_email TEXT NOT NULL,
  tenant_type TEXT NOT NULL CHECK (tenant_type IN ('PLATFORM', 'PROVIDER', 'CITY')),
  tenant_id TEXT,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  reason TEXT,
  before_data JSONB,
  after_data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_tenant_created
  ON public.admin_audit_log (tenant_type, tenant_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.citizen_notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  campaigns_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  waste_reminders_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.notification_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by TEXT NOT NULL,
  created_by_email TEXT NOT NULL,
  tenant_type TEXT NOT NULL CHECK (tenant_type IN ('PLATFORM', 'PROVIDER', 'CITY')),
  tenant_id TEXT,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('ALERT', 'COMMUNITY', 'HABIT')),
  consent_type TEXT NOT NULL DEFAULT 'CAMPAIGN' CHECK (consent_type IN ('CAMPAIGN', 'WASTE')),
  target_district TEXT,
  scheduled_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'COMPLETED', 'CANCELLED')),
  recipient_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_campaigns_tenant_created
  ON public.notification_campaigns (tenant_type, tenant_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.notification_outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES public.notification_campaigns(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  scheduled_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'DELIVERED', 'CANCELLED')),
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (campaign_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_notification_outbox_pending
  ON public.notification_outbox (scheduled_at, id) WHERE status = 'PENDING';

CREATE TABLE IF NOT EXISTS public.waste_collection_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id TEXT NOT NULL,
  district TEXT NOT NULL,
  ward TEXT NOT NULL,
  waste_type TEXT NOT NULL CHECK (waste_type IN ('ORGANIC', 'DRY_RECYCLABLE', 'RESIDUAL', 'SPECIAL_HANDLING')),
  pickup_weekdays SMALLINT[] NOT NULL CHECK (
    cardinality(pickup_weekdays) BETWEEN 1 AND 7
    AND pickup_weekdays <@ ARRAY[0, 1, 2, 3, 4, 5, 6]::smallint[]
  ),
  collection_window TEXT NOT NULL,
  effective_from DATE NOT NULL,
  effective_to DATE,
  notes TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by TEXT NOT NULL,
  updated_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE INDEX IF NOT EXISTS idx_waste_schedules_lookup
  ON public.waste_collection_schedules (LOWER(district), LOWER(ward), effective_from, effective_to)
  WHERE is_active;

CREATE TABLE IF NOT EXISTS public.waste_schedule_reminder_runs (
  schedule_id UUID NOT NULL REFERENCES public.waste_collection_schedules(id) ON DELETE CASCADE,
  pickup_date DATE NOT NULL,
  campaign_id UUID NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (schedule_id, pickup_date)
);
