import crypto from 'node:crypto';
import type { Pool, PoolClient } from 'pg';
import { AdminService, type AdminIdentity, type TenantAdminRecord } from '../admin/admin.service';
import { ProvidersService } from '../providers/providers.service';
import type { CampaignBody, NotificationPreferences, UpdateNotificationPreferencesBody } from './notifications.schema';

const schemaReady = new WeakMap<Pool, Promise<void>>();
const linkColumnByCategory = {
  ELECTRICITY: 'electricity_provider_id',
  GAS: 'gas_provider_id',
  WATER: 'water_provider_id',
} as const;

export class NotificationsService {
  private static async ensureSchema(db: Pool): Promise<void> {
    let ready = schemaReady.get(db);
    if (!ready) {
      ready = db.query(`
        CREATE TABLE IF NOT EXISTS public.citizen_notification_preferences (
          user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
          campaigns_enabled BOOLEAN NOT NULL DEFAULT FALSE,
          waste_reminders_enabled BOOLEAN NOT NULL DEFAULT FALSE,
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
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
        CREATE TABLE IF NOT EXISTS public.citizen_provider_links (
          user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
          electricity_provider_id TEXT,
          gas_provider_id TEXT,
          water_provider_id TEXT,
          transit_provider_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
          consumer_numbers JSONB NOT NULL DEFAULT '{}'::jsonb,
          linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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
        ALTER TABLE public.notification_campaigns
          ADD COLUMN IF NOT EXISTS consent_type TEXT NOT NULL DEFAULT 'CAMPAIGN';
        DO $migration$
        BEGIN
          IF NOT EXISTS (
            SELECT 1 FROM pg_constraint
            WHERE conrelid = 'public.notification_campaigns'::regclass
              AND conname = 'notification_campaigns_consent_type_check'
          ) THEN
            ALTER TABLE public.notification_campaigns
              ADD CONSTRAINT notification_campaigns_consent_type_check
              CHECK (consent_type IN ('CAMPAIGN', 'WASTE'));
          END IF;
          IF EXISTS (
            SELECT 1 FROM pg_constraint
            WHERE conrelid = 'public.notification_campaigns'::regclass
              AND conname = 'notification_campaigns_status_check'
              AND pg_get_constraintdef(oid) NOT LIKE '%COMPLETED%'
          ) THEN
            ALTER TABLE public.notification_campaigns
              DROP CONSTRAINT notification_campaigns_status_check;
          END IF;
          IF NOT EXISTS (
            SELECT 1 FROM pg_constraint
            WHERE conrelid = 'public.notification_campaigns'::regclass
              AND conname = 'notification_campaigns_status_check'
          ) THEN
            UPDATE public.notification_campaigns c
            SET status = CASE WHEN EXISTS (
              SELECT 1 FROM public.notification_outbox o
              WHERE o.campaign_id = c.id AND o.status = 'PENDING'
            ) THEN 'SCHEDULED' ELSE 'COMPLETED' END
            WHERE c.status NOT IN ('SCHEDULED', 'COMPLETED', 'CANCELLED');
            ALTER TABLE public.notification_campaigns
              ADD CONSTRAINT notification_campaigns_status_check
              CHECK (status IN ('SCHEDULED', 'COMPLETED', 'CANCELLED'));
          END IF;
          IF EXISTS (
            SELECT 1 FROM pg_constraint
            WHERE conrelid = 'public.notification_outbox'::regclass
              AND conname = 'notification_outbox_status_check'
              AND pg_get_constraintdef(oid) NOT LIKE '%CANCELLED%'
          ) THEN
            ALTER TABLE public.notification_outbox
              DROP CONSTRAINT notification_outbox_status_check;
          END IF;
          IF NOT EXISTS (
            SELECT 1 FROM pg_constraint
            WHERE conrelid = 'public.notification_outbox'::regclass
              AND conname = 'notification_outbox_status_check'
          ) THEN
            UPDATE public.notification_outbox
            SET status = 'PENDING'
            WHERE status NOT IN ('PENDING', 'DELIVERED', 'CANCELLED');
            ALTER TABLE public.notification_outbox
              ADD CONSTRAINT notification_outbox_status_check
              CHECK (status IN ('PENDING', 'DELIVERED', 'CANCELLED'));
          END IF;
        END;
        $migration$;
      `).then(() => undefined).catch((error: unknown) => {
        schemaReady.delete(db);
        throw error;
      });
      schemaReady.set(db, ready);
    }
    await ready;
  }

  public static async prepare(db: Pool | null): Promise<void> {
    if (!db) throw new Error('PostgreSQL is required for notification delivery.');
    await this.ensureSchema(db);
  }

  public static async getPreferences(db: Pool | null, userId: string): Promise<NotificationPreferences> {
    if (!db) throw new Error('PostgreSQL is required to manage notification preferences.');
    await this.prepare(db);
    await db.query(
      `INSERT INTO public.citizen_notification_preferences (user_id)
       VALUES ($1) ON CONFLICT (user_id) DO NOTHING`,
      [userId],
    );
    const preferences = await db.query(
      `SELECT campaigns_enabled, waste_reminders_enabled, updated_at
       FROM public.citizen_notification_preferences WHERE user_id = $1`,
      [userId],
    );
    const row = preferences.rows[0];
    if (!row) throw new Error('Could not load notification preferences.');
    return {
      campaignsEnabled: row.campaigns_enabled,
      wasteRemindersEnabled: row.waste_reminders_enabled,
      updatedAt: new Date(row.updated_at).toISOString(),
    };
  }

  public static async updatePreferences(
    db: Pool | null,
    userId: string,
    body: UpdateNotificationPreferencesBody,
  ): Promise<NotificationPreferences> {
    if (!db) throw new Error('PostgreSQL is required to manage notification preferences.');
    await this.ensureSchema(db);
    await db.query(
      `INSERT INTO public.citizen_notification_preferences
         (user_id, campaigns_enabled, waste_reminders_enabled, updated_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (user_id) DO UPDATE SET
         campaigns_enabled = EXCLUDED.campaigns_enabled,
         waste_reminders_enabled = EXCLUDED.waste_reminders_enabled,
         updated_at = NOW()`,
      [userId, body.campaignsEnabled, body.wasteRemindersEnabled],
    );
    return this.getPreferences(db, userId);
  }

  private static async resolveTenant(
    db: Pool,
    identity: AdminIdentity,
  ): Promise<TenantAdminRecord | null> {
    if (identity.role === 'ADMIN') return null;
    const tenant = await AdminService.authenticateTenantClaims(db, identity);
    if (!tenant) throw new Error('Tenant administrator account is inactive or its access changed.');
    return tenant;
  }

  public static async createCampaign(
    db: Pool | null,
    identity: AdminIdentity,
    body: CampaignBody,
  ) {
    if (!db) throw new Error('PostgreSQL is required to create notification campaigns.');
    if (identity.role !== 'ADMIN' && identity.role !== 'PROVIDER_ADMIN' && identity.role !== 'CITY_ADMIN') {
      throw new Error('Administrator access is required.');
    }
    if ((body.incentiveCoins ?? 0) > 0) {
      throw new Error('Campaign incentives are disabled until they can be credited through the reward ledger.');
    }
    await this.ensureSchema(db);
    const tenant = await this.resolveTenant(db, identity);
    const tenantType = tenant?.tenantType ?? 'PLATFORM';
    const tenantId = tenant?.tenantId ?? null;
    if (tenant && body.targetDistrict && !tenant.districts.some((district) => district.toLowerCase() === body.targetDistrict?.toLowerCase())) {
      throw new Error('Campaign district is outside this administrator service area.');
    }
    if (tenant?.tenantType === 'PROVIDER' && (body.targetUserId || body.targetUserEmail)) {
      throw new Error('Provider campaigns may target only opted-in linked customers.');
    }
    if (tenant?.tenantType === 'PROVIDER' && !body.targetDistrict) {
      throw new Error('Provider campaigns must target one assigned district.');
    }
    if (tenant?.tenantType === 'CITY' && (body.targetUserId || body.targetUserEmail)) {
      throw new Error('City campaigns may target only opted-in residents in the service area.');
    }
    if (tenant?.tenantType === 'PROVIDER' && body.targetProviderId && body.targetProviderId !== tenant.tenantId) {
      throw new Error('Provider campaign tenant does not match the authenticated administrator.');
    }
    const provider = tenant?.tenantType === 'PROVIDER'
      ? ProvidersService.getProviderById(tenant.tenantId)
      : null;
    if (tenant?.tenantType === 'PROVIDER' && !provider) throw new Error('Provider tenant is not in the provider directory.');
    if (tenant?.tenantType === 'CITY' && !body.targetDistrict) {
      throw new Error('City campaigns must target one configured district.');
    }
    const scheduledAt = body.scheduledAt ? new Date(body.scheduledAt) : new Date();
    if (!Number.isFinite(scheduledAt.getTime()) || scheduledAt.getTime() < Date.now() - 60_000) {
      throw new Error('Campaign delivery time must be now or a future time.');
    }

    const client = await db.connect();
    try {
      await client.query('BEGIN');
      await client.query('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ');
      let audienceSql = `SELECT u.id
        FROM public.users u
        JOIN public.citizen_notification_preferences p ON p.user_id = u.id
        WHERE u.deleted_at IS NULL`;
      audienceSql += ' AND p.campaigns_enabled = TRUE';
      const params: unknown[] = [];
      if (tenantType === 'PROVIDER' && provider) {
        const category = provider.category;
        if (category === 'TRANSIT') {
          audienceSql += ` AND EXISTS (
            SELECT 1 FROM public.citizen_provider_links l
            WHERE l.user_id = u.id AND l.transit_provider_ids ? $1
          )`;
        } else {
          const column = linkColumnByCategory[category];
          audienceSql += ` AND EXISTS (
            SELECT 1 FROM public.citizen_provider_links l
            WHERE l.user_id = u.id AND l.${column} = $1
          )`;
        }
        params.push(tenantId);
        if (body.targetDistrict) {
          params.push(body.targetDistrict);
          audienceSql += ` AND LOWER(u.district) = LOWER($${params.length})`;
        } else if (tenant) {
          params.push(tenant.districts);
          audienceSql += ` AND LOWER(u.district) IN (
            SELECT LOWER(value) FROM unnest($${params.length}::text[]) AS districts(value)
          )`;
        }
      } else if (tenantType === 'CITY') {
        audienceSql += ` AND LOWER(u.district) = LOWER($1)`;
        params.push(body.targetDistrict);
      } else {
        if (body.targetProviderId) {
          const targetProvider = ProvidersService.getProviderById(body.targetProviderId);
          if (!targetProvider) throw new Error('Provider target is not in the provider directory.');
          if (targetProvider.category === 'TRANSIT') {
            params.push(body.targetProviderId);
            audienceSql += ` AND EXISTS (
              SELECT 1 FROM public.citizen_provider_links l
              WHERE l.user_id = u.id AND l.transit_provider_ids ? $${params.length}
            )`;
          } else {
            const column = linkColumnByCategory[targetProvider.category];
            params.push(body.targetProviderId);
            audienceSql += ` AND EXISTS (
              SELECT 1 FROM public.citizen_provider_links l
              WHERE l.user_id = u.id AND l.${column} = $${params.length}
            )`;
          }
        }
        if (body.targetDistrict) {
          params.push(body.targetDistrict);
          audienceSql += ` AND LOWER(u.district) = LOWER($${params.length})`;
        }
        if (body.targetUserId) {
          params.push(body.targetUserId);
          audienceSql += ` AND u.id = $${params.length}`;
        }
        if (body.targetUserEmail) {
          params.push(body.targetUserEmail.trim().toLowerCase());
          audienceSql += ` AND LOWER(u.email) = LOWER($${params.length})`;
        }
      }
      const audience = await client.query<{ recipient_count: string }>(
        `SELECT COUNT(*)::text AS recipient_count FROM (${audienceSql}) AS eligible_recipients`,
        params,
      );
      const recipientCount = Number(audience.rows[0]?.recipient_count ?? 0);
      const campaignId = crypto.randomUUID();
      const category = body.category ?? 'ALERT';
      const campaignResult = await client.query(
        `INSERT INTO public.notification_campaigns
           (id, created_by, created_by_email, tenant_type, tenant_id, title, message, category,
            target_district, scheduled_at, recipient_count)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
         RETURNING created_at`,
        [
          campaignId,
          identity.adminAccountId ?? identity.id,
          identity.email,
          tenantType,
          tenantId,
          body.title.trim(),
          body.message.trim(),
          category,
          body.targetDistrict ?? null,
          scheduledAt.toISOString(),
          recipientCount,
        ],
      );
      const campaignIdParameter = params.length + 1;
      await client.query(
        `INSERT INTO public.notification_outbox (campaign_id, user_id, scheduled_at)
         SELECT $${campaignIdParameter}, eligible_recipients.id, campaign.scheduled_at
         FROM public.notification_campaigns campaign
         CROSS JOIN LATERAL (${audienceSql}) AS eligible_recipients
         WHERE campaign.id = $${campaignIdParameter}
         ON CONFLICT (campaign_id, user_id) DO NOTHING`,
        [...params, campaignId],
      );
      await client.query(
        `INSERT INTO public.admin_audit_log
           (actor_id, actor_email, tenant_type, tenant_id, action, resource_type, resource_id, reason, after_data)
         VALUES ($1, $2, $3, $4, 'CAMPAIGN_CREATED', 'NOTIFICATION_CAMPAIGN', $5, $6, $7::jsonb)`,
        [
          identity.adminAccountId ?? identity.id,
          identity.email,
          tenantType,
          tenantId,
          campaignId,
          body.reason.trim(),
          JSON.stringify({
            title: body.title.trim(),
            category,
            targetDistrict: body.targetDistrict ?? null,
            scheduledAt: scheduledAt.toISOString(),
            recipientCount,
          }),
        ],
      );
      await client.query('COMMIT');
      return {
        id: campaignId,
        title: body.title.trim(),
        message: body.message.trim(),
        category,
        tenantType,
        tenantId,
        targetDistrict: body.targetDistrict ?? null,
        scheduledAt: scheduledAt.toISOString(),
        status: scheduledAt.getTime() <= Date.now() ? 'DELIVERING' : 'SCHEDULED',
        recipientCount,
        deliveredCount: 0,
        createdAt: new Date(campaignResult.rows[0].created_at).toISOString(),
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  public static async listCampaigns(db: Pool | null, identity: AdminIdentity) {
    if (!db) throw new Error('PostgreSQL is required to list campaigns.');
    await this.ensureSchema(db);
    const tenant = await this.resolveTenant(db, identity);
    const result = tenant
      ? await db.query(
          `SELECT c.id, c.title, c.message, c.category, c.tenant_type, c.tenant_id,
                  c.target_district, c.scheduled_at, c.status, c.recipient_count, c.created_at,
                  COUNT(o.id) FILTER (WHERE o.status = 'DELIVERED')::integer AS delivered_count
           FROM public.notification_campaigns c
           LEFT JOIN public.notification_outbox o ON o.campaign_id = c.id
           WHERE c.tenant_type = $1 AND c.tenant_id = $2
             AND LOWER(c.target_district) IN (
               SELECT LOWER(value) FROM unnest($3::text[]) AS districts(value)
             )
           GROUP BY c.id ORDER BY c.created_at DESC LIMIT 100`,
          [tenant.tenantType, tenant.tenantId, tenant.districts],
        )
      : await db.query(
          `SELECT c.id, c.title, c.message, c.category, c.tenant_type, c.tenant_id,
                  c.target_district, c.scheduled_at, c.status, c.recipient_count, c.created_at,
                  COUNT(o.id) FILTER (WHERE o.status = 'DELIVERED')::integer AS delivered_count
           FROM public.notification_campaigns c
           LEFT JOIN public.notification_outbox o ON o.campaign_id = c.id
           GROUP BY c.id ORDER BY c.created_at DESC LIMIT 100`,
        );
    return result.rows.map((row) => ({
      id: String(row.id),
      title: String(row.title),
      message: String(row.message),
      category: String(row.category),
      tenantType: String(row.tenant_type),
      tenantId: row.tenant_id === null ? null : String(row.tenant_id),
      targetDistrict: row.target_district === null ? null : String(row.target_district),
      scheduledAt: new Date(row.scheduled_at).toISOString(),
      status: String(row.status),
      recipientCount: Number(row.recipient_count),
      deliveredCount: Number(row.delivered_count),
      createdAt: new Date(row.created_at).toISOString(),
    }));
  }

  public static async dispatchDue(db: Pool | null, limit = 500): Promise<number> {
    if (!db) throw new Error('PostgreSQL is required to deliver in-app notifications.');
    await this.ensureSchema(db);
    const client = await db.connect();
    try {
      await client.query('BEGIN');
      await client.query(
        `UPDATE public.notification_outbox o SET status = 'CANCELLED'
         WHERE o.status = 'PENDING' AND o.scheduled_at <= NOW()
           AND NOT EXISTS (
             SELECT 1 FROM public.citizen_notification_preferences p
             JOIN public.notification_campaigns c ON c.id = o.campaign_id
             WHERE p.user_id = o.user_id
               AND CASE WHEN c.consent_type = 'WASTE'
                 THEN p.waste_reminders_enabled ELSE p.campaigns_enabled END = TRUE
           )`,
      );
      const delivered = await client.query<{ processed: string }>(
        `WITH due AS MATERIALIZED (
           SELECT o.id, o.user_id, c.title, c.message, c.category
           FROM public.notification_outbox o
           JOIN public.notification_campaigns c ON c.id = o.campaign_id
           JOIN public.citizen_notification_preferences p ON p.user_id = o.user_id
           WHERE o.status = 'PENDING' AND o.scheduled_at <= NOW()
             AND CASE WHEN c.consent_type = 'WASTE'
               THEN p.waste_reminders_enabled ELSE p.campaigns_enabled END = TRUE
           ORDER BY o.scheduled_at, o.id
           LIMIT $1 FOR UPDATE OF o, p SKIP LOCKED
         ), inserted_activities AS (
           INSERT INTO public.citizen_activities
             (id, user_id, title, message, category, icon, created_at)
           SELECT due.id, due.user_id, due.title, due.message, due.category, 'campaign', NOW()
           FROM due
           ON CONFLICT (id) DO NOTHING
           RETURNING id
         ), marked_delivered AS (
           UPDATE public.notification_outbox o
           SET status = 'DELIVERED', delivered_at = NOW()
           FROM due
           WHERE o.id = due.id AND o.status = 'PENDING'
           RETURNING o.id
         )
         SELECT COUNT(*)::text AS processed FROM marked_delivered`,
        [Math.min(Math.max(limit, 1), 500)],
      );
      await client.query(
        `UPDATE public.notification_campaigns c SET status = 'COMPLETED'
         WHERE c.status = 'SCHEDULED' AND c.scheduled_at <= NOW()
           AND NOT EXISTS (
             SELECT 1 FROM public.notification_outbox o
             WHERE o.campaign_id = c.id AND o.status = 'PENDING'
           )`,
      );
      await client.query('COMMIT');
      return Number(delivered.rows[0]?.processed ?? 0);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}
