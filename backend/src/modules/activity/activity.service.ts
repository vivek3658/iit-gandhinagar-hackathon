import crypto from 'node:crypto';
import type { MongoClient } from 'mongodb';
import type { ActivityCategory, ActivityFeedResponse, ActivityItem } from './activity.schema';

export class ActivityRepository {
  private activities: ActivityItem[] = [];
  private mongo: MongoClient | null = null;
  private readonly collectionName = 'citizen_activities';

  public setMongoClient(client: MongoClient | null): void {
    this.mongo = client;
    if (this.mongo) {
      this.syncFromMongo().catch(() => {});
    }
  }

  public getAll(): ActivityItem[] {
    return this.activities.map((a) => ({ ...a }));
  }

  public findForUser(userId: string): ActivityItem[] {
    return this.activities
      .filter((a) => a.userId === userId || a.userId === null)
      .map((a) => ({ ...a }));
  }

  public add(item: ActivityItem): ActivityItem {
    this.activities.unshift({ ...item });
    this.persistActivity(item).catch(() => {});
    return item;
  }

  public markRead(id: string, userId: string): boolean {
    const item = this.activities.find((a) => a.id === id && (a.userId === userId || a.userId === null));
    if (item) {
      item.isRead = true;
      this.updateReadInMongo(id, userId).catch(() => {});
      return true;
    }
    return false;
  }

  public markAllRead(userId: string): number {
    let count = 0;
    for (const item of this.activities) {
      if ((item.userId === userId || item.userId === null) && !item.isRead) {
        item.isRead = true;
        count++;
      }
    }
    this.updateAllReadInMongo(userId).catch(() => {});
    return count;
  }

  public clear(): void {
    this.activities = [];
  }

  private async syncFromMongo(): Promise<void> {
    if (!this.mongo) return;
    try {
      const docs = await this.mongo
        .db('urjavatika')
        .collection<ActivityItem>(this.collectionName)
        .find()
        .sort({ createdAt: -1 })
        .limit(100)
        .toArray();

      for (const doc of docs) {
        if (!this.activities.some((a) => a.id === doc.id)) {
          this.activities.push({
            id: doc.id,
            userId: doc.userId,
            title: doc.title,
            message: doc.message,
            category: doc.category,
            icon: doc.icon,
            coinsEarned: doc.coinsEarned,
            co2SavedKg: doc.co2SavedKg,
            district: doc.district,
            isRead: Boolean(doc.isRead),
            createdAt: doc.createdAt,
          });
        }
      }
    } catch {
      // Non-fatal
    }
  }

  private async persistActivity(item: ActivityItem): Promise<void> {
    if (!this.mongo) return;
    try {
      await this.mongo
        .db('urjavatika')
        .collection(this.collectionName)
        .insertOne({ ...item });
    } catch {
      // Non-fatal
    }
  }

  private async updateReadInMongo(id: string, userId: string): Promise<void> {
    if (!this.mongo) return;
    try {
      await this.mongo
        .db('urjavatika')
        .collection(this.collectionName)
        .updateOne(
          { id, $or: [{ userId }, { userId: null }] },
          { $set: { isRead: true } }
        );
    } catch {
      // Non-fatal
    }
  }

  private async updateAllReadInMongo(userId: string): Promise<void> {
    if (!this.mongo) return;
    try {
      await this.mongo
        .db('urjavatika')
        .collection(this.collectionName)
        .updateMany(
          { $or: [{ userId }, { userId: null }], isRead: false },
          { $set: { isRead: true } }
        );
    } catch {
      // Non-fatal
    }
  }
}

export class ActivityService {
  private static repository = new ActivityRepository();

  public static getRepository(): ActivityRepository {
    return this.repository;
  }

  public static setMongoClient(client: MongoClient | null): void {
    this.repository.setMongoClient(client);
  }

  public static ensureInitialActivities(userId: string, district = 'Ahmedabad'): void {
    void userId;
    void district;
  }

  public static getFeed(
    userId: string,
    options?: { category?: ActivityCategory; page?: number; limit?: number }
  ): ActivityFeedResponse {
    this.ensureInitialActivities(userId);

    const category = options?.category || 'ALL';
    const page = Math.max(1, options?.page || 1);
    const limit = Math.min(50, Math.max(1, options?.limit || 20));

    let list = this.repository.findForUser(userId);

    if (category !== 'ALL') {
      list = list.filter((a) => a.category === category);
    }

    const totalCount = list.length;
    const unreadCount = list.filter((a) => !a.isRead).length;

    const startIndex = (page - 1) * limit;
    const paginated = list.slice(startIndex, startIndex + limit);

    return {
      activities: paginated,
      totalCount,
      unreadCount,
      page,
      limit,
    };
  }

  public static postActivity(event: Omit<ActivityItem, 'id' | 'isRead' | 'createdAt'>): ActivityItem {
    const item: ActivityItem = {
      ...event,
      id: crypto.randomUUID(),
      isRead: false,
      createdAt: new Date().toISOString(),
    };
    return this.repository.add(item);
  }

  public static markAsRead(id: string, userId: string): { success: boolean; unreadCount: number } {
    this.ensureInitialActivities(userId);
    this.repository.markRead(id, userId);
    const list = this.repository.findForUser(userId);
    const unreadCount = list.filter((a) => !a.isRead).length;
    return { success: true, unreadCount };
  }

  public static markAllAsRead(userId: string): { success: boolean; unreadCount: number } {
    this.ensureInitialActivities(userId);
    this.repository.markAllRead(userId);
    return { success: true, unreadCount: 0 };
  }
}
