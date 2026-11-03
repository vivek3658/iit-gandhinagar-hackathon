import { describe, expect, it, vi } from 'vitest';
import type { Pool } from 'pg';
import type { AdminIdentity } from '../src/modules/admin/admin.service';
import { NotificationsService } from '../src/modules/notifications/notifications.service';

function createDb(deliveryCount = 2) {
  const statements: string[] = [];
  const client = {
    query: vi.fn(async (sql: string) => {
      statements.push(sql);
      if (sql.includes('COUNT(*)::text AS recipient_count')) {
        return { rows: [{ recipient_count: '2' }] };
      }
      if (sql.includes('RETURNING created_at')) {
        return { rows: [{ created_at: new Date().toISOString() }] };
      }
      if (sql.includes('COUNT(*)::text AS processed')) {
        return { rows: [{ processed: String(deliveryCount) }] };
      }
      return { rows: [] };
    }),
    release: vi.fn(),
  };
  const db = {
    query: vi.fn(async () => ({ rows: [] })),
    connect: vi.fn(async () => client),
  } as unknown as Pool;
  return { db, statements, client };
}

const platformAdmin: AdminIdentity = {
  id: 'admin-1',
  email: 'admin@example.test',
  role: 'ADMIN',
};

describe('Notification campaign delivery', () => {
  it('immediately places due opted-in campaigns in citizen activity feeds', async () => {
    const { db, statements, client } = createDb();
    const campaign = await NotificationsService.createCampaign(db, platformAdmin, {
      title: 'Water saving week',
      message: 'Join the community water-saving challenge.',
      reason: 'Announce this week’s public conservation campaign.',
    });

    expect(campaign.status).toBe('COMPLETED');
    expect(campaign.recipientCount).toBe(2);
    expect(campaign.deliveredCount).toBe(2);
    expect(statements.some((sql) => sql.includes('INSERT INTO public.citizen_activities'))).toBe(
      true,
    );
    expect(statements.some((sql) => sql.includes("SET status = 'DELIVERED'"))).toBe(true);
    expect(client.query).toHaveBeenCalledWith('COMMIT');
  });

  it('keeps future campaigns scheduled without inserting feed activities early', async () => {
    const { db, statements } = createDb();
    const campaign = await NotificationsService.createCampaign(db, platformAdmin, {
      title: 'Future water saving week',
      message: 'Join the upcoming community water-saving challenge.',
      reason: 'Schedule a future public conservation campaign.',
      scheduledAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
    });

    expect(campaign.status).toBe('SCHEDULED');
    expect(campaign.deliveredCount).toBe(0);
    expect(statements.some((sql) => sql.includes('INSERT INTO public.citizen_activities'))).toBe(
      false,
    );
  });

  it('limits city announcements to opted-in users in the selected district and ward', async () => {
    const { db, statements, client } = createDb();
    const campaign = await NotificationsService.createCampaign(db, platformAdmin, {
      title: 'Ward water update',
      message: 'A maintenance update for residents of Ward 5.',
      targetDistrict: 'Ahmedabad',
      targetWard: 'Ward 5',
      reason: 'Share the scheduled water service update.',
    });

    const audienceQuery = statements.find((sql) =>
      sql.includes('COUNT(*)::text AS recipient_count'),
    );
    expect(audienceQuery).toContain('p.campaigns_enabled = TRUE');
    expect(audienceQuery).toContain('LOWER(u.district) = LOWER($1)');
    expect(audienceQuery).toContain('LOWER(u.ward) = LOWER($2)');
    expect(client.query).toHaveBeenCalledWith(
      expect.stringContaining('target_district, target_ward, target_provider_id, scheduled_at'),
      expect.arrayContaining(['Ahmedabad', 'Ward 5']),
    );
    expect(campaign.targetDistrict).toBe('Ahmedabad');
    expect(campaign.targetWard).toBe('Ward 5');
  });
});
