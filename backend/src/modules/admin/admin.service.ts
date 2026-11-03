import { scrypt, timingSafeEqual } from 'node:crypto';
import crypto from 'node:crypto';
import { promisify } from 'node:util';
import type { Pool } from 'pg';
import { ProvidersService } from '../providers/providers.service';
import { DevicesService } from '../devices/devices.service';
import { CitizenDataService } from '../citizen-data/citizen-data.service';
import type {
  AdminKpisResponse,
  AdminProvidersListResponse,
  CreateTenantAdminBody,
} from './admin.schema';
import type { CreateProviderBody, UtilityProvider } from '../providers/providers.schema';

const scryptAsync = promisify(scrypt);

export class AdminConfigurationError extends Error {}

export interface AdminIdentity {
  id: string;
  email: string;
  role: 'ADMIN' | 'PROVIDER_ADMIN' | 'CITY_ADMIN';
  adminAccountId?: string;
  tenantId?: string;
  tenantType?: 'PROVIDER' | 'CITY';
}

export interface TenantAdminRecord {
  id: string;
  email: string;
  displayName: string;
  tenantType: 'PROVIDER' | 'CITY';
  tenantId: string;
  districts: string[];
  createdAt: string;
}

export class AdminService {
  private static schemaReady = new WeakMap<Pool, Promise<void>>();

  private static async ensureSchema(db: Pool): Promise<void> {
    let ready = this.schemaReady.get(db);
    if (!ready) {
      ready = db
        .query(
          `
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
          household_analytics_enabled BOOLEAN NOT NULL DEFAULT FALSE,
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        ALTER TABLE public.citizen_notification_preferences
          ADD COLUMN IF NOT EXISTS household_analytics_enabled BOOLEAN NOT NULL DEFAULT FALSE;
        CREATE TABLE IF NOT EXISTS public.citizen_provider_links (
          user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
          electricity_provider_id TEXT,
          gas_provider_id TEXT,
          water_provider_id TEXT,
          transit_provider_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
          consumer_numbers JSONB NOT NULL DEFAULT '{}'::jsonb,
          linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
      `,
        )
        .then(() => undefined)
        .catch((error: unknown) => {
          this.schemaReady.delete(db);
          throw error;
        });
      this.schemaReady.set(db, ready);
    }
    await ready;
  }

  private static async hashPassword(password: string): Promise<string> {
    const salt = crypto.randomBytes(16);
    const hash = (await scryptAsync(password, salt, 64)) as Buffer;
    return `scrypt$${salt.toString('base64')}$${hash.toString('base64')}`;
  }

  private static async verifyPasswordHash(password: string, value: string): Promise<boolean> {
    const [algorithm, encodedSalt, encodedHash] = value.split('$');
    if (algorithm !== 'scrypt' || !encodedSalt || !encodedHash) return false;
    const salt = Buffer.from(encodedSalt, 'base64');
    const expectedHash = Buffer.from(encodedHash, 'base64');
    if (salt.length !== 16 || expectedHash.length !== 64) return false;
    const actualHash = (await scryptAsync(password, salt, expectedHash.length)) as Buffer;
    return timingSafeEqual(actualHash, expectedHash);
  }

  public static async authenticateTenantAdmin(
    db: Pool | null,
    email: string,
    password: string,
  ): Promise<(TenantAdminRecord & { role: 'PROVIDER_ADMIN' | 'CITY_ADMIN' }) | null> {
    if (!db) return null;
    await this.ensureSchema(db);
    const result = await db.query(
      `SELECT id, email, password_hash, display_name, tenant_type, tenant_id, districts, created_at
       FROM public.tenant_admin_accounts
       WHERE LOWER(email) = LOWER($1) AND is_active = TRUE LIMIT 1`,
      [email],
    );
    const row = result.rows[0];
    if (!row || !(await this.verifyPasswordHash(password, String(row.password_hash)))) return null;
    const tenantType = row.tenant_type as 'PROVIDER' | 'CITY';
    return {
      id: String(row.id),
      email: String(row.email),
      displayName: String(row.display_name),
      tenantType,
      tenantId: String(row.tenant_id),
      districts: typeof row.districts === 'string' ? JSON.parse(row.districts) : row.districts,
      createdAt: new Date(row.created_at).toISOString(),
      role: tenantType === 'PROVIDER' ? 'PROVIDER_ADMIN' : 'CITY_ADMIN',
    };
  }

  public static async authenticateTenantClaims(
    db: Pool | null,
    identity: AdminIdentity,
  ): Promise<TenantAdminRecord | null> {
    if (!db || !identity.adminAccountId || !identity.tenantId || !identity.tenantType) return null;
    await this.ensureSchema(db);
    const result = await db.query(
      `SELECT id, email, display_name, tenant_type, tenant_id, districts, created_at
       FROM public.tenant_admin_accounts
       WHERE id = $1 AND tenant_type = $2 AND tenant_id = $3 AND is_active = TRUE`,
      [identity.adminAccountId, identity.tenantType, identity.tenantId],
    );
    const row = result.rows[0];
    if (!row) return null;
    return {
      id: String(row.id),
      email: String(row.email),
      displayName: String(row.display_name),
      tenantType: row.tenant_type as 'PROVIDER' | 'CITY',
      tenantId: String(row.tenant_id),
      districts: typeof row.districts === 'string' ? JSON.parse(row.districts) : row.districts,
      createdAt: new Date(row.created_at).toISOString(),
    };
  }

  public static async createTenantAdmin(
    db: Pool | null,
    actor: AdminIdentity,
    body: CreateTenantAdminBody,
  ): Promise<TenantAdminRecord> {
    if (!db) throw new Error('PostgreSQL is required to provision tenant administrators.');
    if (actor.role !== 'ADMIN') throw new Error('Platform administrator access is required.');
    const districts = [
      ...new Set(body.districts.map((district) => district.trim()).filter(Boolean)),
    ];
    if (districts.length === 0) throw new Error('At least one valid district must be assigned.');
    if (body.tenantType === 'PROVIDER') {
      const provider = await ProvidersService.getDirectoryProviderById(body.tenantId, db);
      if (!provider) throw new Error('Provider tenant ID is not in the provider directory.');
      const allowedDistricts = new Set(
        provider.districts.map((district) => district.toLowerCase()),
      );
      if (districts.some((district) => !allowedDistricts.has(district.toLowerCase()))) {
        throw new Error(
          'Provider administrator districts must be served by the selected provider.',
        );
      }
    }
    await this.ensureSchema(db);
    const passwordHash = await this.hashPassword(body.password);
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      const created = await client.query(
        `INSERT INTO public.tenant_admin_accounts
           (email, password_hash, display_name, tenant_type, tenant_id, districts)
         VALUES (LOWER($1), $2, $3, $4, $5, $6::jsonb)
         RETURNING id, email, display_name, tenant_type, tenant_id, districts, created_at`,
        [
          body.email.trim(),
          passwordHash,
          body.displayName.trim(),
          body.tenantType,
          body.tenantId,
          JSON.stringify(districts),
        ],
      );
      const row = created.rows[0];
      await client.query(
        `INSERT INTO public.admin_audit_log
           (actor_id, actor_email, tenant_type, tenant_id, action, resource_type, resource_id, reason, after_data)
         VALUES ($1, $2, 'PLATFORM', NULL, 'TENANT_ADMIN_CREATED', 'TENANT_ADMIN', $3, $4, $5::jsonb)`,
        [
          actor.id,
          actor.email,
          row.id,
          'Provisioned tenant administrator',
          JSON.stringify({
            email: row.email,
            tenantType: row.tenant_type,
            tenantId: row.tenant_id,
            districts: row.districts,
          }),
        ],
      );
      await client.query('COMMIT');
      return {
        id: String(row.id),
        email: String(row.email),
        displayName: String(row.display_name),
        tenantType: row.tenant_type as 'PROVIDER' | 'CITY',
        tenantId: String(row.tenant_id),
        districts: typeof row.districts === 'string' ? JSON.parse(row.districts) : row.districts,
        createdAt: new Date(row.created_at).toISOString(),
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  public static async listTenantAdmins(db: Pool | null): Promise<TenantAdminRecord[]> {
    if (!db) throw new Error('PostgreSQL is required to list tenant administrators.');
    await this.ensureSchema(db);
    const result = await db.query(
      `SELECT id, email, display_name, tenant_type, tenant_id, districts, created_at
       FROM public.tenant_admin_accounts WHERE is_active = TRUE ORDER BY created_at DESC`,
    );
    return result.rows.map((row) => ({
      id: String(row.id),
      email: String(row.email),
      displayName: String(row.display_name),
      tenantType: row.tenant_type as 'PROVIDER' | 'CITY',
      tenantId: String(row.tenant_id),
      districts: typeof row.districts === 'string' ? JSON.parse(row.districts) : row.districts,
      createdAt: new Date(row.created_at).toISOString(),
    }));
  }

  public static async deactivateTenantAdmin(
    db: Pool | null,
    actor: AdminIdentity,
    adminId: string,
  ): Promise<boolean> {
    if (!db) throw new Error('PostgreSQL is required to manage tenant administrators.');
    if (actor.role !== 'ADMIN') throw new Error('Platform administrator access is required.');
    await this.ensureSchema(db);
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      const result = await client.query(
        `UPDATE public.tenant_admin_accounts
         SET is_active = FALSE, updated_at = NOW()
         WHERE id = $1 AND is_active = TRUE
         RETURNING email, tenant_type, tenant_id`,
        [adminId],
      );
      if (!result.rows[0]) {
        await client.query('ROLLBACK');
        return false;
      }
      const row = result.rows[0];
      await client.query(
        `INSERT INTO public.admin_audit_log
           (actor_id, actor_email, tenant_type, tenant_id, action, resource_type, resource_id, reason, before_data, after_data)
         VALUES ($1, $2, 'PLATFORM', NULL, 'TENANT_ADMIN_DEACTIVATED', 'TENANT_ADMIN', $3, $4, $5::jsonb, $6::jsonb)`,
        [
          actor.id,
          actor.email,
          adminId,
          'Revoked tenant administrator access',
          JSON.stringify({
            email: row.email,
            tenantType: row.tenant_type,
            tenantId: row.tenant_id,
            isActive: true,
          }),
          JSON.stringify({ isActive: false }),
        ],
      );
      await client.query('COMMIT');
      return true;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  public static async getTenantOverview(
    db: Pool | null,
    identity: AdminIdentity,
  ): Promise<{
    tenantType: 'PROVIDER' | 'CITY';
    tenantId: string;
    scopeLabel: string;
    activeCitizens: number;
    campaignOptIns: number;
    wasteReminderOptIns: number;
    dataAsOf: string;
  }> {
    if (!db) throw new Error('PostgreSQL is required for tenant metrics.');
    const tenant = await this.authenticateTenantClaims(db, identity);
    if (!tenant) throw new Error('Tenant administrator account is inactive or its access changed.');
    type TenantMetricRow = {
      active_citizens: number;
      campaign_opt_ins: number;
      waste_reminder_opt_ins: number;
    };
    let counts: TenantMetricRow;
    if (tenant.tenantType === 'CITY') {
      const result = await db.query<TenantMetricRow>(
        `SELECT COUNT(DISTINCT u.id)::integer AS active_citizens,
                COUNT(DISTINCT u.id) FILTER (WHERE p.campaigns_enabled)::integer AS campaign_opt_ins,
                COUNT(DISTINCT u.id) FILTER (WHERE p.waste_reminders_enabled)::integer AS waste_reminder_opt_ins
         FROM public.users u
         LEFT JOIN public.citizen_notification_preferences p ON p.user_id = u.id
         WHERE u.deleted_at IS NULL
           AND LOWER(u.district) IN (SELECT LOWER(value) FROM unnest($1::text[]) AS districts(value))`,
        [tenant.districts],
      );
      counts = result.rows[0] ?? {
        active_citizens: 0,
        campaign_opt_ins: 0,
        waste_reminder_opt_ins: 0,
      };
    } else {
      const provider = await ProvidersService.getDirectoryProviderById(tenant.tenantId, db);
      if (!provider) throw new Error('Provider tenant is not in the provider directory.');
      const providerDistricts = new Set(
        provider.districts.map((district) => district.toLowerCase()),
      );
      const providerColumn =
        provider.category === 'ELECTRICITY'
          ? 'electricity_provider_id'
          : provider.category === 'GAS'
            ? 'gas_provider_id'
            : 'water_provider_id';
      const providerFilter =
        provider.category === 'TRANSIT'
          ? `EXISTS (SELECT 1 FROM public.citizen_provider_links l
                   WHERE l.user_id = u.id AND l.transit_provider_ids ? $1)`
          : `EXISTS (SELECT 1 FROM public.citizen_provider_links l
                   WHERE l.user_id = u.id AND l.${providerColumn} = $1)`;
      const result = await db.query<TenantMetricRow>(
        `SELECT COUNT(DISTINCT u.id)::integer AS active_citizens,
                COUNT(DISTINCT u.id) FILTER (WHERE p.campaigns_enabled)::integer AS campaign_opt_ins,
                0::integer AS waste_reminder_opt_ins
         FROM public.users u
         LEFT JOIN public.citizen_notification_preferences p ON p.user_id = u.id
         WHERE u.deleted_at IS NULL AND ${providerFilter}
           AND LOWER(u.district) IN (SELECT LOWER(value) FROM unnest($2::text[]) AS districts(value))`,
        [
          tenant.tenantId,
          tenant.districts.filter((district) => providerDistricts.has(district.toLowerCase())),
        ],
      );
      counts = result.rows[0] ?? {
        active_citizens: 0,
        campaign_opt_ins: 0,
        waste_reminder_opt_ins: 0,
      };
    }
    return {
      tenantType: tenant.tenantType,
      tenantId: tenant.tenantId,
      scopeLabel: tenant.districts.join(', '),
      activeCitizens: Number(counts.active_citizens),
      campaignOptIns: Number(counts.campaign_opt_ins),
      wasteReminderOptIns: Number(counts.waste_reminder_opt_ins),
      dataAsOf: new Date().toISOString(),
    };
  }

  public static async getAuditLog(db: Pool | null, tenant?: TenantAdminRecord) {
    if (!db) throw new Error('PostgreSQL is required to read the administrator audit log.');
    await this.ensureSchema(db);
    const params: unknown[] = [];
    let scope = '';
    if (tenant) {
      params.push(tenant.tenantType, tenant.tenantId);
      scope = 'WHERE tenant_type = $1 AND tenant_id = $2';
      if (tenant.tenantType === 'CITY' || tenant.tenantType === 'PROVIDER') {
        params.push(tenant.districts);
        scope += ` AND LOWER(COALESCE(after_data->>'district', after_data->>'targetDistrict', before_data->>'district'))
          IN (SELECT LOWER(value) FROM unnest($3::text[]) AS districts(value))`;
      }
    }
    params.push(100);
    const result = await db.query(
      `SELECT id, actor_email, tenant_type, tenant_id, action, resource_type, resource_id, reason, created_at
       FROM public.admin_audit_log ${scope}
       ORDER BY created_at DESC LIMIT $${params.length}`,
      params,
    );
    return result.rows.map((row) => ({
      id: String(row.id),
      actorEmail: String(row.actor_email),
      tenantType: row.tenant_type as 'PLATFORM' | 'PROVIDER' | 'CITY',
      tenantId: row.tenant_id === null ? null : String(row.tenant_id),
      action: String(row.action),
      resourceType: String(row.resource_type),
      resourceId: row.resource_id === null ? null : String(row.resource_id),
      reason: row.reason === null ? null : String(row.reason),
      createdAt: new Date(row.created_at).toISOString(),
    }));
  }

  public static async verifyAdminCredentials(
    username: string,
    password: string,
    configuredUsername: string | undefined,
    configuredPasswordHash: string | undefined,
  ): Promise<boolean> {
    if (!configuredUsername || !configuredPasswordHash) {
      throw new AdminConfigurationError('Admin login credentials are not configured');
    }

    const [algorithm, encodedSalt, encodedHash] = configuredPasswordHash.split('$');
    if (algorithm !== 'scrypt' || !encodedSalt || !encodedHash) {
      throw new AdminConfigurationError('Admin password hash configuration is invalid');
    }

    let salt: Buffer;
    let expectedHash: Buffer;
    try {
      salt = Buffer.from(encodedSalt, 'base64');
      expectedHash = Buffer.from(encodedHash, 'base64');
    } catch {
      throw new AdminConfigurationError('Admin password hash configuration is invalid');
    }
    if (salt.length < 16 || expectedHash.length !== 64) {
      throw new AdminConfigurationError('Admin password hash configuration is invalid');
    }

    const derivedHash = (await scryptAsync(password, salt, expectedHash.length)) as Buffer;
    const passwordMatches = timingSafeEqual(derivedHash, expectedHash);
    const usernameMatches =
      username.trim().toLowerCase() === configuredUsername.trim().toLowerCase();
    return passwordMatches && usernameMatches;
  }

  public static async getKpis(db: Pool | null): Promise<AdminKpisResponse> {
    if (!db) {
      throw new Error('PostgreSQL is required for admin metrics');
    }

    await this.ensureSchema(db);
    await DevicesService.prepare(db);
    await CitizenDataService.prepare(db);
    const result = await db.query<{
      district: string | null;
      citizen_count: string;
      coin_total: string;
      is_total: boolean;
    }>(
      `SELECT
         district,
         COUNT(*)::text AS citizen_count,
         COALESCE(SUM(points), 0)::text AS coin_total,
         GROUPING(district) = 1 AS is_total
       FROM users
       WHERE deleted_at IS NULL
       GROUP BY GROUPING SETS ((district), ())`,
    );

    let totalRegisteredCitizens = 0;
    let totalCoinsInCirculation = 0;
    const districtBreakdown: Record<string, number> = {};
    for (const row of result.rows) {
      if (row.is_total) {
        totalRegisteredCitizens = Number(row.citizen_count);
        totalCoinsInCirculation = Number(row.coin_total);
      } else if (row.district) {
        districtBreakdown[row.district] = Number(row.citizen_count);
      }
    }

    const householdResult = await db.query<{
      consented_citizens: string | null;
      registered_devices: string | null;
      estimated_energy_kwh: string | null;
    }>(
      `WITH totals AS (
         SELECT
           COUNT(DISTINCT p.user_id)::integer AS consented_citizens,
           COUNT(DISTINCT d.id)::integer AS registered_devices,
           COALESCE(SUM(l.energy_consumed_kwh), 0)::numeric AS estimated_energy_kwh
         FROM public.citizen_notification_preferences p
         LEFT JOIN public.citizen_registered_devices d ON d.user_id = p.user_id
         LEFT JOIN public.citizen_device_runtime_logs l
           ON l.registered_device_id = d.id AND l.user_id = d.user_id
         WHERE p.household_analytics_enabled = TRUE
       )
       SELECT
         CASE WHEN consented_citizens >= 5 THEN consented_citizens::text END AS consented_citizens,
         CASE WHEN consented_citizens >= 5 THEN registered_devices::text END AS registered_devices,
         CASE WHEN consented_citizens >= 5 THEN estimated_energy_kwh::text END AS estimated_energy_kwh
       FROM totals`,
    );
    const householdRow = householdResult.rows[0];
    const householdAnalytics = {
      consentedCitizens:
        householdRow?.consented_citizens == null ? null : Number(householdRow.consented_citizens),
      registeredDevices:
        householdRow?.registered_devices == null ? null : Number(householdRow.registered_devices),
      estimatedEnergyKwh:
        householdRow?.estimated_energy_kwh == null
          ? null
          : Number(householdRow.estimated_energy_kwh),
      utilityReadings: null as number | null,
      runtimeLogs: null as number | null,
      confirmedTrips: null as number | null,
    };

    const wardResult = await db.query<{
      district: string;
      ward: string;
      citizen_count: string;
    }>(
      `SELECT BTRIM(district) AS district, BTRIM(ward) AS ward, COUNT(*)::text AS citizen_count
       FROM public.users
       WHERE deleted_at IS NULL
         AND NULLIF(BTRIM(district), '') IS NOT NULL
         AND NULLIF(BTRIM(ward), '') IS NOT NULL
       GROUP BY BTRIM(district), BTRIM(ward)
       HAVING COUNT(*) >= 5
       ORDER BY COUNT(*) DESC, district, ward
       LIMIT 20`,
    );
    const wardBreakdown = wardResult.rows.map((row) => ({
      district: String(row.district),
      ward: String(row.ward),
      citizenCount: Number(row.citizen_count),
    }));

    const utilityUsageResult = await db.query<{
      utility: 'ELECTRICITY' | 'WATER' | 'GAS';
      district: string;
      ward: string;
      unit: string;
      period: string;
      average_value: string;
      contributors: string;
    }>(
      `WITH monthly_latest AS (
         SELECT r.user_id, r.utility, r.unit, r.value,
                DATE_TRUNC('month', r.period_end)::date AS month,
                COALESCE(NULLIF(BTRIM(u.district), ''), 'Unassigned') AS district,
                COALESCE(NULLIF(BTRIM(u.ward), ''), 'Unassigned') AS ward,
                ROW_NUMBER() OVER (
                  PARTITION BY r.user_id, r.utility, r.unit, DATE_TRUNC('month', r.period_end)
                  ORDER BY r.period_end DESC, r.created_at DESC
                ) AS reading_rank
         FROM public.utility_readings r
         JOIN public.users u ON u.id = r.user_id AND u.deleted_at IS NULL
         JOIN public.citizen_notification_preferences p
           ON p.user_id = u.id AND p.household_analytics_enabled = TRUE
       )
       SELECT utility, district, ward, unit, TO_CHAR(month, 'YYYY-MM') AS period,
              AVG(value)::text AS average_value, COUNT(DISTINCT user_id)::text AS contributors
       FROM monthly_latest
       WHERE reading_rank = 1
       GROUP BY utility, district, ward, unit, month
       HAVING COUNT(DISTINCT user_id) >= 5
       ORDER BY month DESC, utility, district, ward, unit
       LIMIT 500`,
    );
    const utilityUsage = utilityUsageResult.rows.map((row) => ({
      utility: row.utility,
      district: String(row.district),
      ward: String(row.ward),
      unit: String(row.unit),
      period: String(row.period),
      averageValue: Number(row.average_value),
      contributors: Number(row.contributors),
    }));

    const estimatedImpactResult = await db.query<{
      district: string;
      ward: string;
      estimated_co2e_kg: string;
      contributors: string;
    }>(
      `WITH eligible AS (
         SELECT t.user_id,
                SUM(t.distance_km * CASE t.mode
                  WHEN 'WALK' THEN 0.14
                  WHEN 'BICYCLE' THEN 0.14
                  WHEN 'PUBLIC_TRANSIT' THEN 0.085
                  ELSE 0
                END) AS estimated_co2e_kg,
                COALESCE(NULLIF(BTRIM(u.district), ''), 'Unassigned') AS district,
                COALESCE(NULLIF(BTRIM(u.ward), ''), 'Unassigned') AS ward
         FROM public.confirmed_trips t
         JOIN public.users u ON u.id = t.user_id AND u.deleted_at IS NULL
         JOIN public.citizen_notification_preferences p
           ON p.user_id = t.user_id AND p.household_analytics_enabled = TRUE
         WHERE t.mode IN ('WALK', 'BICYCLE', 'PUBLIC_TRANSIT')
         GROUP BY t.user_id, u.district, u.ward
         HAVING SUM(t.distance_km * CASE t.mode
           WHEN 'WALK' THEN 0.14
           WHEN 'BICYCLE' THEN 0.14
           WHEN 'PUBLIC_TRANSIT' THEN 0.085
           ELSE 0
         END) > 0
       )
       SELECT district, ward, SUM(estimated_co2e_kg)::text AS estimated_co2e_kg,
              COUNT(DISTINCT user_id)::text AS contributors
       FROM eligible
       GROUP BY district, ward
       HAVING COUNT(DISTINCT user_id) >= 5
       ORDER BY SUM(estimated_co2e_kg) DESC
       LIMIT 20`,
    );
    const estimatedImpactByArea = estimatedImpactResult.rows.map((row) => ({
      district: String(row.district),
      ward: String(row.ward),
      estimatedCo2eKg: Number(row.estimated_co2e_kg),
      contributors: Number(row.contributors),
    }));

    const estimatedImpactTotalResult = await db.query<{ estimated_co2e_kg: string | null }>(
      `WITH eligible AS (
         SELECT t.user_id,
                SUM(t.distance_km * CASE t.mode
                  WHEN 'WALK' THEN 0.14
                  WHEN 'BICYCLE' THEN 0.14
                  WHEN 'PUBLIC_TRANSIT' THEN 0.085
                  ELSE 0
                END) AS estimated_co2e_kg
         FROM public.confirmed_trips t
         JOIN public.citizen_notification_preferences p
           ON p.user_id = t.user_id AND p.household_analytics_enabled = TRUE
         WHERE t.mode IN ('WALK', 'BICYCLE', 'PUBLIC_TRANSIT')
         GROUP BY t.user_id
       ), estimates AS (
         SELECT COUNT(*) FILTER (WHERE estimated_co2e_kg > 0) AS contributors,
                SUM(estimated_co2e_kg) AS estimated_co2e_kg
         FROM estimates_by_citizen
       )
       SELECT CASE WHEN contributors >= 5
         THEN COALESCE(estimated_co2e_kg, 0)::text END AS estimated_co2e_kg
       FROM estimates`,
    );
    const estimatedCommuteCo2eKg =
      estimatedImpactTotalResult.rows[0]?.estimated_co2e_kg == null
        ? null
        : Number(estimatedImpactTotalResult.rows[0].estimated_co2e_kg);

    const loggedDataResult = await db.query<{
      utility_readings: string | null;
      runtime_logs: string | null;
      confirmed_trips: string | null;
    }>(
      `WITH eligible AS (
         SELECT user_id
         FROM public.citizen_notification_preferences
         WHERE household_analytics_enabled = TRUE
       ), threshold AS (
         SELECT COUNT(*) AS contributors FROM eligible
       )
       SELECT
         CASE WHEN threshold.contributors >= 5 THEN (
           SELECT COUNT(*)::text FROM public.utility_readings r
           JOIN eligible e ON e.user_id = r.user_id
         ) END AS utility_readings,
         CASE WHEN threshold.contributors >= 5 THEN (
           SELECT COUNT(*)::text FROM public.citizen_device_runtime_logs l
           JOIN eligible e ON e.user_id = l.user_id
         ) END AS runtime_logs,
         CASE WHEN threshold.contributors >= 5 THEN (
           SELECT COUNT(*)::text FROM public.confirmed_trips t
           JOIN eligible e ON e.user_id = t.user_id
         ) END AS confirmed_trips
       FROM threshold`,
    );
    const loggedData = loggedDataResult.rows[0];
    householdAnalytics.utilityReadings =
      loggedData?.utility_readings == null ? null : Number(loggedData.utility_readings);
    householdAnalytics.runtimeLogs =
      loggedData?.runtime_logs == null ? null : Number(loggedData.runtime_logs);
    householdAnalytics.confirmedTrips =
      loggedData?.confirmed_trips == null ? null : Number(loggedData.confirmed_trips);

    const providerResult = await db.query<{
      provider_id: string;
      subscribers: string;
    }>(
      `WITH consented_links AS (
         SELECT l.user_id, l.electricity_provider_id, l.gas_provider_id, l.water_provider_id,
                l.transit_provider_ids
         FROM public.citizen_provider_links l
         JOIN public.citizen_notification_preferences p ON p.user_id = l.user_id
         WHERE p.household_analytics_enabled = TRUE
       ), linked AS (
         SELECT user_id, electricity_provider_id AS provider_id
         FROM consented_links WHERE electricity_provider_id IS NOT NULL
         UNION ALL
         SELECT user_id, gas_provider_id FROM consented_links
         WHERE gas_provider_id IS NOT NULL
         UNION ALL
         SELECT user_id, water_provider_id FROM consented_links
         WHERE water_provider_id IS NOT NULL
         UNION ALL
         SELECT user_id, provider_id.value
         FROM consented_links
         CROSS JOIN LATERAL jsonb_array_elements_text(transit_provider_ids) AS provider_id(value)
       )
       SELECT provider_id, COUNT(DISTINCT user_id)::text AS subscribers
       FROM linked
       GROUP BY provider_id
       HAVING COUNT(DISTINCT user_id) >= 5
       ORDER BY COUNT(DISTINCT user_id) DESC, provider_id`,
    );
    const providerSubscribers = Object.fromEntries(
      providerResult.rows.map((row) => [String(row.provider_id), Number(row.subscribers)]),
    );

    return {
      success: true,
      dataAsOf: new Date().toISOString(),
      kpis: {
        totalRegisteredCitizens,
        activeSanctuariesCount: null,
        totalCo2eSavedKg: null,
        totalPeakMwhShifted: null,
        totalCoinsInCirculation,
        districtBreakdown,
        wardBreakdown,
        utilityUsage,
        estimatedCommuteCo2eKg,
        estimatedImpactByArea,
        providerSubscribers,
        householdAnalytics,
      },
      unavailableMetrics: [
        'activeSanctuariesCount',
        'totalCo2eSavedKg',
        'totalPeakMwhShifted',
        'providerSubscribers',
      ],
    };
  }

  public static async listAdminProviders(db: Pool | null): Promise<AdminProvidersListResponse> {
    const providers = (await ProvidersService.listDirectoryProviders(db)).map((provider) => ({
      id: provider.id,
      name: provider.name,
      category: provider.category,
      districts: provider.districts,
      subscribersCount: null,
      status: 'DIRECTORY_ONLY',
    }));

    return { success: true, providers, totalProviders: providers.length };
  }

  public static async createProvider(
    db: Pool | null,
    actor: AdminIdentity,
    body: CreateProviderBody,
  ): Promise<UtilityProvider> {
    if (!db) throw new Error('PostgreSQL is required to create utility providers.');
    if (actor.role !== 'ADMIN') {
      throw new Error('Platform administrator access is required.');
    }
    await this.ensureSchema(db);
    const provider = await ProvidersService.createDirectoryProvider(db, body);
    await db.query(
      `INSERT INTO public.admin_audit_log
         (actor_id, actor_email, tenant_type, tenant_id, action, resource_type,
          resource_id, reason, after_data)
       VALUES ($1, $2, 'PLATFORM', NULL, 'UTILITY_PROVIDER_CREATED',
               'UTILITY_PROVIDER', $3, $4, $5::jsonb)`,
      [
        actor.id,
        actor.email,
        provider.id,
        body.reason,
        JSON.stringify({
          name: provider.name,
          category: provider.category,
          districts: provider.districts,
          code: provider.code,
        }),
      ],
    );
    return provider;
  }
}
