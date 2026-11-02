import crypto from 'node:crypto';
import type { Pool } from 'pg';
import { AdminService, type AdminIdentity, type TenantAdminRecord } from '../admin/admin.service';
import type { WasteScheduleWrite } from './waste.schema';

const schemaReady = new WeakMap<Pool, Promise<void>>();

interface WasteScheduleRecord {
  id: string;
  tenantId: string;
  district: string;
  ward: string;
  wasteType: string;
  pickupWeekdays: number[];
  collectionWindow: string;
  effectiveFrom: string;
  effectiveTo: string | null;
  notes: string | null;
  isActive: boolean;
  updatedAt: string;
}

function mapSchedule(row: Record<string, unknown>): WasteScheduleRecord {
  const weekdays = typeof row.pickup_weekdays === 'string'
    ? JSON.parse(row.pickup_weekdays)
    : row.pickup_weekdays;
  return {
    id: String(row.id),
    tenantId: String(row.tenant_id),
    district: String(row.district),
    ward: String(row.ward),
    wasteType: String(row.waste_type),
    pickupWeekdays: Array.isArray(weekdays) ? weekdays.map(Number) : [],
    collectionWindow: String(row.collection_window),
    effectiveFrom: new Date(String(row.effective_from)).toISOString().slice(0, 10),
    effectiveTo: row.effective_to ? new Date(String(row.effective_to)).toISOString().slice(0, 10) : null,
    notes: row.notes === null ? null : String(row.notes),
    isActive: Boolean(row.is_active),
    updatedAt: new Date(String(row.updated_at)).toISOString(),
  };
}

export class WasteService {
  private static async ensureSchema(db: Pool): Promise<void> {
    let ready = schemaReady.get(db);
    if (!ready) {
      ready = db.query(`
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
      `).then(() => undefined).catch((error: unknown) => {
        schemaReady.delete(db);
        throw error;
      });
      schemaReady.set(db, ready);
    }
    await ready;
  }

  private static async getCityTenant(db: Pool, identity: AdminIdentity): Promise<TenantAdminRecord> {
    if (identity.role !== 'CITY_ADMIN' || identity.tenantType !== 'CITY') {
      throw new Error('City administrator access is required.');
    }
    const tenant = await AdminService.authenticateTenantClaims(db, identity);
    if (!tenant || tenant.tenantType !== 'CITY') {
      throw new Error('City administrator account is inactive or its access changed.');
    }
    return tenant;
  }

  private static assertServiceArea(tenant: TenantAdminRecord, district: string): void {
    if (!tenant.districts.some((value) => value.toLowerCase() === district.trim().toLowerCase())) {
      throw new Error('District is outside this city administrator service area.');
    }
  }

  private static validateDates(schedule: WasteScheduleWrite): void {
    const from = new Date(`${schedule.effectiveFrom}T00:00:00.000Z`);
    const to = schedule.effectiveTo ? new Date(`${schedule.effectiveTo}T00:00:00.000Z`) : null;
    if (!Number.isFinite(from.getTime()) || (to && (!Number.isFinite(to.getTime()) || to < from))) {
      throw new Error('Schedule effective dates are invalid.');
    }
    const weekdays = new Set(schedule.pickupWeekdays);
    if (weekdays.size !== schedule.pickupWeekdays.length) {
      throw new Error('Pickup weekdays must not contain duplicates.');
    }
  }

  private static async lockScheduleKey(
    client: import('pg').PoolClient,
    tenantId: string,
    body: WasteScheduleWrite,
  ): Promise<void> {
    const key = [tenantId, body.district.trim().toLowerCase(), body.ward.trim().toLowerCase(), body.wasteType].join(':');
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [key]);
  }

  private static async assertNoOverlap(
    client: import('pg').PoolClient,
    tenantId: string,
    body: WasteScheduleWrite,
    exceptId?: string,
  ): Promise<void> {
    if (body.isActive === false) return;
    const result = await client.query(
      `SELECT id FROM public.waste_collection_schedules
       WHERE tenant_id = $1 AND LOWER(district) = LOWER($2) AND LOWER(ward) = LOWER($3)
         AND waste_type = $4 AND is_active = TRUE
         AND effective_from <= COALESCE($6::date, 'infinity'::date)
         AND COALESCE(effective_to, 'infinity'::date) >= $5::date
         AND ($7::uuid IS NULL OR id <> $7::uuid)
       LIMIT 1`,
      [
        tenantId,
        body.district.trim(),
        body.ward.trim(),
        body.wasteType,
        body.effectiveFrom,
        body.effectiveTo,
        exceptId ?? null,
      ],
    );
    if (result.rows[0]) {
      throw new Error('An active schedule already overlaps these dates for this ward and waste type.');
    }
  }

  public static async listPublic(
    db: Pool | null,
    query: { district: string; ward?: string; date?: string },
  ): Promise<{ schedules: WasteScheduleRecord[]; asOfDate: string }> {
    if (!db) throw new Error('PostgreSQL is required to retrieve waste collection schedules.');
    await this.ensureSchema(db);
    const date = query.date ?? new Date(Date.now() + 330 * 60_000).toISOString().slice(0, 10);
    const result = await db.query(
      `SELECT id, tenant_id, district, ward, waste_type, pickup_weekdays,
              collection_window, effective_from, effective_to, notes, is_active, updated_at
       FROM public.waste_collection_schedules
       WHERE is_active = TRUE AND LOWER(district) = LOWER($1)
         AND ($2::text IS NULL OR LOWER(ward) = LOWER($2))
         AND effective_from <= $3::date AND (effective_to IS NULL OR effective_to >= $3::date)
       ORDER BY LOWER(ward), waste_type, id`,
      [query.district, query.ward ?? null, date],
    );
    return { schedules: result.rows.map(mapSchedule), asOfDate: date };
  }

  public static async listForTenant(db: Pool | null, identity: AdminIdentity) {
    if (!db) throw new Error('PostgreSQL is required to retrieve waste schedules.');
    await this.ensureSchema(db);
    const tenant = await this.getCityTenant(db, identity);
    const result = await db.query(
      `SELECT id, tenant_id, district, ward, waste_type, pickup_weekdays,
              collection_window, effective_from, effective_to, notes, is_active, updated_at
       FROM public.waste_collection_schedules
       WHERE tenant_id = $1
         AND LOWER(district) IN (SELECT LOWER(value) FROM unnest($2::text[]) AS districts(value))
       ORDER BY updated_at DESC LIMIT 200`,
      [tenant.tenantId, tenant.districts],
    );
    return result.rows.map(mapSchedule);
  }

  public static async enqueueTomorrowReminders(db: Pool | null): Promise<number> {
    if (!db) throw new Error('PostgreSQL is required to schedule waste reminders.');
    await this.ensureSchema(db);
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      await client.query(
        `DELETE FROM public.waste_schedule_reminder_runs
         WHERE pickup_date < ((NOW() AT TIME ZONE 'Asia/Kolkata')::date - 90)`,
      );
      const schedules = await client.query<{
        id: string;
        tenant_id: string;
        district: string;
        ward: string;
        waste_type: string;
        collection_window: string;
        notes: string | null;
        pickup_date: string;
        scheduled_at: Date;
      }>(
        `WITH local_clock AS (
           SELECT (NOW() AT TIME ZONE 'Asia/Kolkata')::date AS local_today,
                  (NOW() AT TIME ZONE 'Asia/Kolkata')::time AS local_time
         ), pickup AS (
           SELECT local_today + 1 AS pickup_date, local_time
           FROM local_clock
         )
         SELECT s.id, s.tenant_id, s.district, s.ward, s.waste_type,
                s.collection_window, s.notes, pickup.pickup_date::text AS pickup_date,
                ((pickup.pickup_date - 1 + TIME '18:00') AT TIME ZONE 'Asia/Kolkata') AS scheduled_at
         FROM public.waste_collection_schedules s
         CROSS JOIN pickup
         WHERE s.is_active = TRUE
           AND pickup.local_time >= TIME '18:00'
           AND s.effective_from <= pickup.pickup_date
           AND (s.effective_to IS NULL OR s.effective_to >= pickup.pickup_date)
           AND s.pickup_weekdays @> ARRAY[EXTRACT(DOW FROM pickup.pickup_date)::smallint]
           AND NOT EXISTS (
             SELECT 1 FROM public.waste_schedule_reminder_runs r
             WHERE r.schedule_id = s.id AND r.pickup_date = pickup.pickup_date
           )
         ORDER BY s.tenant_id, s.district, s.ward, s.waste_type, s.id
         LIMIT 100`,
      );
      let scheduledCount = 0;
      for (const schedule of schedules.rows) {
        const campaignId = crypto.randomUUID();
        const insertedRun = await client.query(
          `INSERT INTO public.waste_schedule_reminder_runs (schedule_id, pickup_date, campaign_id)
           VALUES ($1, $2::date, $3) ON CONFLICT (schedule_id, pickup_date) DO NOTHING
           RETURNING campaign_id`,
          [schedule.id, schedule.pickup_date, campaignId],
        );
        if (insertedRun.rowCount !== 1) continue;

        const title = `Waste collection tomorrow: ${schedule.waste_type.replaceAll('_', ' ').toLowerCase()}`;
        const message = `${schedule.ward}, ${schedule.district}: collection is scheduled for ${schedule.collection_window}.${schedule.notes ? ` ${schedule.notes}` : ''}`;
        await client.query(
          `INSERT INTO public.notification_campaigns
             (id, created_by, created_by_email, tenant_type, tenant_id, title, message, category,
              consent_type, target_district, scheduled_at, recipient_count)
           VALUES ($1, 'system:waste-reminders', 'system@urja.invalid', 'CITY', $2,
                   $3, $4, 'ALERT', 'WASTE', $5, $6, 0)`,
          [campaignId, schedule.tenant_id, title, message, schedule.district, schedule.scheduled_at],
        );
        const recipients = await client.query(
          `INSERT INTO public.notification_outbox (campaign_id, user_id, scheduled_at)
           SELECT $1, u.id, $2
           FROM public.users u
           JOIN public.citizen_notification_preferences p ON p.user_id = u.id
           WHERE u.deleted_at IS NULL
             AND p.waste_reminders_enabled = TRUE
             AND LOWER(u.district) = LOWER($3)`,
          [campaignId, schedule.scheduled_at, schedule.district],
        );
        await client.query(
          'UPDATE public.notification_campaigns SET recipient_count = $2 WHERE id = $1',
          [campaignId, recipients.rowCount ?? 0],
        );
        await client.query(
          `INSERT INTO public.admin_audit_log
             (actor_id, actor_email, tenant_type, tenant_id, action, resource_type, resource_id, reason, after_data)
           VALUES ('system:waste-reminders', 'system@urja.invalid', 'CITY', $1,
                   'WASTE_REMINDER_SCHEDULED', 'NOTIFICATION_CAMPAIGN', $2,
                   'Automatic opted-in waste collection reminder',
                   jsonb_build_object('scheduleId', $3, 'pickupDate', $4, 'recipientCount', $5, 'district', $6))`,
          [schedule.tenant_id, campaignId, schedule.id, schedule.pickup_date, recipients.rowCount ?? 0, schedule.district],
        );
        scheduledCount += 1;
      }
      await client.query('COMMIT');
      return scheduledCount;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  public static async create(
    db: Pool | null,
    identity: AdminIdentity,
    body: WasteScheduleWrite,
  ): Promise<WasteScheduleRecord> {
    if (!db) throw new Error('PostgreSQL is required to manage waste schedules.');
    await this.ensureSchema(db);
    const tenant = await this.getCityTenant(db, identity);
    this.assertServiceArea(tenant, body.district);
    this.validateDates(body);
    const scheduleId = crypto.randomUUID();
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      await this.lockScheduleKey(client, tenant.tenantId, body);
      await this.assertNoOverlap(client, tenant.tenantId, body);
      const result = await client.query(
        `INSERT INTO public.waste_collection_schedules
           (id, tenant_id, district, ward, waste_type, pickup_weekdays, collection_window,
            effective_from, effective_to, notes, is_active, created_by, updated_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $12)
         RETURNING id, tenant_id, district, ward, waste_type, pickup_weekdays, collection_window,
                   effective_from, effective_to, notes, is_active, updated_at`,
        [
          scheduleId, tenant.tenantId, body.district.trim(), body.ward.trim(), body.wasteType,
          [...new Set(body.pickupWeekdays)].sort(), body.collectionWindow.trim(), body.effectiveFrom,
          body.effectiveTo, body.notes?.trim() ?? null, body.isActive ?? true, identity.adminAccountId ?? identity.id,
        ],
      );
      await this.audit(client, identity, tenant, 'WASTE_SCHEDULE_CREATED', scheduleId, body.reason, null, body);
      await client.query('COMMIT');
      return mapSchedule(result.rows[0]);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  public static async update(
    db: Pool | null,
    identity: AdminIdentity,
    scheduleId: string,
    body: WasteScheduleWrite,
  ): Promise<WasteScheduleRecord | null> {
    if (!db) throw new Error('PostgreSQL is required to manage waste schedules.');
    await this.ensureSchema(db);
    const tenant = await this.getCityTenant(db, identity);
    this.assertServiceArea(tenant, body.district);
    this.validateDates(body);
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      const before = await client.query(
        `SELECT * FROM public.waste_collection_schedules
         WHERE id = $1 AND tenant_id = $2
           AND LOWER(district) IN (SELECT LOWER(value) FROM unnest($3::text[]) AS districts(value))
         FOR UPDATE`,
        [scheduleId, tenant.tenantId, tenant.districts],
      );
      if (!before.rows[0]) {
        await client.query('ROLLBACK');
        return null;
      }
      await this.lockScheduleKey(client, tenant.tenantId, body);
      await this.assertNoOverlap(client, tenant.tenantId, body, scheduleId);
      const result = await client.query(
        `UPDATE public.waste_collection_schedules
         SET district = $3, ward = $4, waste_type = $5, pickup_weekdays = $6,
             collection_window = $7, effective_from = $8, effective_to = $9,
             notes = $10, is_active = $11, updated_by = $12, updated_at = NOW()
         WHERE id = $1 AND tenant_id = $2
         RETURNING id, tenant_id, district, ward, waste_type, pickup_weekdays, collection_window,
                   effective_from, effective_to, notes, is_active, updated_at`,
        [
          scheduleId, tenant.tenantId, body.district.trim(), body.ward.trim(), body.wasteType,
          [...new Set(body.pickupWeekdays)].sort(), body.collectionWindow.trim(), body.effectiveFrom,
          body.effectiveTo, body.notes?.trim() ?? null, body.isActive ?? true, identity.adminAccountId ?? identity.id,
        ],
      );
      await this.audit(client, identity, tenant, 'WASTE_SCHEDULE_UPDATED', scheduleId, body.reason, before.rows[0], body);
      await client.query('COMMIT');
      return mapSchedule(result.rows[0]);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  private static async audit(
    client: import('pg').PoolClient,
    identity: AdminIdentity,
    tenant: TenantAdminRecord,
    action: string,
    scheduleId: string,
    reason: string,
    before: unknown,
    after: unknown,
  ): Promise<void> {
    await client.query(
      `INSERT INTO public.admin_audit_log
         (actor_id, actor_email, tenant_type, tenant_id, action, resource_type, resource_id,
          reason, before_data, after_data)
       VALUES ($1, $2, 'CITY', $3, $4, 'WASTE_SCHEDULE', $5, $6, $7::jsonb, $8::jsonb)`,
      [
        identity.adminAccountId ?? identity.id,
        identity.email,
        tenant.tenantId,
        action,
        scheduleId,
        reason,
        before ? JSON.stringify(before) : null,
        after ? JSON.stringify(after) : null,
      ],
    );
  }
}
