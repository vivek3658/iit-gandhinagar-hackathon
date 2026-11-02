import crypto from 'node:crypto';
import type { Pool } from 'pg';
import type { ActivityCategory, ActivityFeedResponse, ActivityItem } from './activity.schema';

type ActivityEvent = Omit<ActivityItem, 'id' | 'isRead' | 'createdAt'>;

export class ActivityRepository {
  private activities: ActivityItem[] = [];
  private db: Pool | null = null;
  private allowTestMemory = false;
  private static schemaReady = new WeakMap<Pool, Promise<void>>();

  public setDbPool(db: Pool | null, allowTestMemory: boolean): void {
    this.db = db;
    this.allowTestMemory = allowTestMemory;
  }

  private async ensureSchema(): Promise<void> {
    if (!this.db) return;
    let ready = ActivityRepository.schemaReady.get(this.db);
    if (!ready) {
      ready = this.db
        .query(`
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
        `)
        .then(() => undefined);
      ActivityRepository.schemaReady.set(this.db, ready);
    }
    await ready;
  }

  private requireTestMemory(): void {
    if (!this.allowTestMemory) {
      throw new Error('PostgreSQL is required for durable activity feeds.');
    }
  }

  public async findForUser(
    userId: string,
    options: { category: ActivityCategory | 'ALL'; page: number; limit: number },
  ): Promise<ActivityFeedResponse> {
    if (!this.db) {
      this.requireTestMemory();
      const visible = this.activities.filter((item) => item.userId === userId || item.userId === null);
      const filtered = options.category === 'ALL'
        ? visible
        : visible.filter((item) => item.category === options.category);
      const start = (options.page - 1) * options.limit;
      return {
        activities: filtered.slice(start, start + options.limit).map((item) => ({ ...item })),
        totalCount: filtered.length,
        unreadCount: filtered.filter((item) => !item.isRead).length,
        page: options.page,
        limit: options.limit,
      };
    }

    await this.ensureSchema();
    const categoryClause = options.category === 'ALL' ? '' : 'AND a.category = $2';
    const parameters = options.category === 'ALL'
      ? [userId]
      : [userId, options.category];
    const countResult = await this.db.query(
      `SELECT COUNT(*)::integer AS total_count,
              COUNT(*) FILTER (WHERE r.activity_id IS NULL)::integer AS unread_count
       FROM public.citizen_activities a
       LEFT JOIN public.activity_read_status r
         ON r.activity_id = a.id AND r.user_id = $1
       WHERE (a.user_id = $1 OR a.user_id IS NULL) ${categoryClause}`,
      parameters,
    );
    const offsetIndex = parameters.length + 1;
    const limitIndex = parameters.length + 2;
    const result = await this.db.query(
      `SELECT a.id, a.user_id, a.title, a.message, a.category, a.icon,
              a.coins_earned, a.co2_saved_kg, a.district, a.created_at,
              (r.activity_id IS NOT NULL) AS is_read
       FROM public.citizen_activities a
       LEFT JOIN public.activity_read_status r
         ON r.activity_id = a.id AND r.user_id = $1
       WHERE (a.user_id = $1 OR a.user_id IS NULL) ${categoryClause}
       ORDER BY a.created_at DESC
       LIMIT $${limitIndex} OFFSET $${offsetIndex}`,
      [...parameters, options.limit, (options.page - 1) * options.limit],
    );
    return {
      activities: result.rows.map((row) => ({
        id: row.id,
        userId: row.user_id,
        title: row.title,
        message: row.message,
        category: row.category,
        icon: row.icon,
        coinsEarned: row.coins_earned ?? undefined,
        co2SavedKg: row.co2_saved_kg === null ? undefined : Number(row.co2_saved_kg),
        district: row.district ?? undefined,
        isRead: row.is_read,
        createdAt: new Date(row.created_at).toISOString(),
      })),
      totalCount: Number(countResult.rows[0]?.total_count ?? 0),
      unreadCount: Number(countResult.rows[0]?.unread_count ?? 0),
      page: options.page,
      limit: options.limit,
    };
  }

  public async add(item: ActivityItem): Promise<ActivityItem> {
    if (!this.db) {
      this.requireTestMemory();
      this.activities.unshift({ ...item });
      return item;
    }
    await this.ensureSchema();
    await this.db.query(
      `INSERT INTO public.citizen_activities
         (id, user_id, title, message, category, icon, coins_earned, co2_saved_kg, district, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
      [
        item.id, item.userId, item.title, item.message, item.category, item.icon,
        item.coinsEarned ?? null, item.co2SavedKg ?? null, item.district ?? null, item.createdAt,
      ],
    );
    return item;
  }

  public async markRead(id: string, userId: string): Promise<boolean> {
    if (!this.db) {
      this.requireTestMemory();
      const item = this.activities.find(
        (activity) => activity.id === id && (activity.userId === userId || activity.userId === null),
      );
      if (!item) return false;
      item.isRead = true;
      return true;
    }
    await this.ensureSchema();
    const result = await this.db.query(
      `INSERT INTO public.activity_read_status (user_id, activity_id)
       SELECT $1, id FROM public.citizen_activities
       WHERE id = $2 AND (user_id = $1 OR user_id IS NULL)
       ON CONFLICT (user_id, activity_id) DO NOTHING
       RETURNING activity_id`,
      [userId, id],
    );
    if (result.rowCount) return true;
    const exists = await this.db.query(
      'SELECT 1 FROM public.activity_read_status WHERE user_id = $1 AND activity_id = $2',
      [userId, id],
    );
    return exists.rowCount === 1;
  }

  public async markAllRead(userId: string): Promise<void> {
    if (!this.db) {
      this.requireTestMemory();
      for (const item of this.activities) {
        if (item.userId === userId || item.userId === null) item.isRead = true;
      }
      return;
    }
    await this.ensureSchema();
    await this.db.query(
      `INSERT INTO public.activity_read_status (user_id, activity_id)
       SELECT $1, a.id FROM public.citizen_activities a
       LEFT JOIN public.activity_read_status r
         ON r.user_id = $1 AND r.activity_id = a.id
       WHERE (a.user_id = $1 OR a.user_id IS NULL) AND r.activity_id IS NULL
       ON CONFLICT (user_id, activity_id) DO NOTHING`,
      [userId],
    );
  }

  public clear(): void {
    this.activities = [];
  }
}

export class ActivityService {
  private static repository = new ActivityRepository();

  public static getRepository(): ActivityRepository {
    return this.repository;
  }

  public static setDbPool(db: Pool | null, allowTestMemory = false): void {
    this.repository.setDbPool(db, allowTestMemory);
  }

  public static async getFeed(
    userId: string,
    options?: { category?: ActivityCategory; page?: number; limit?: number },
  ): Promise<ActivityFeedResponse> {
    return this.repository.findForUser(userId, {
      category: options?.category || 'ALL',
      page: Math.max(1, options?.page || 1),
      limit: Math.min(50, Math.max(1, options?.limit || 20)),
    });
  }

  public static async postActivity(event: ActivityEvent): Promise<ActivityItem> {
    const item: ActivityItem = {
      ...event,
      id: crypto.randomUUID(),
      isRead: false,
      createdAt: new Date().toISOString(),
    };
    return this.repository.add(item);
  }

  public static async markAsRead(
    id: string,
    userId: string,
  ): Promise<{ success: boolean; unreadCount: number }> {
    const success = await this.repository.markRead(id, userId);
    const feed = await this.repository.findForUser(userId, { page: 1, limit: 1, category: 'ALL' });
    return { success, unreadCount: feed.unreadCount };
  }

  public static async markAllAsRead(userId: string): Promise<{ success: boolean; unreadCount: number }> {
    await this.repository.markAllRead(userId);
    return { success: true, unreadCount: 0 };
  }
}
