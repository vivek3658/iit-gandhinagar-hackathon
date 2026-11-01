import crypto from 'node:crypto';
import type { ActivityCategory, ActivityFeedResponse, ActivityItem } from './activity.schema';

export class ActivityRepository {
  private activities: ActivityItem[] = [];

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
    return item;
  }

  public markRead(id: string, userId: string): boolean {
    const item = this.activities.find((a) => a.id === id && (a.userId === userId || a.userId === null));
    if (item) {
      item.isRead = true;
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
    return count;
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

  /**
   * Seed initial activities for a new citizen so feed is lively immediately
   */
  public static ensureInitialActivities(userId: string, district = 'Ahmedabad'): void {
    // New accounts start with a truthful, empty feed. Events are added by
    // completed server actions, not fabricated onboarding rewards.
    void userId;
    void district;
  }

  /**
   * Get paginated activity feed
   */
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

  /**
   * Post a new activity event (called from habit/garden/mascot)
   */
  public static postActivity(event: Omit<ActivityItem, 'id' | 'isRead' | 'createdAt'>): ActivityItem {
    const item: ActivityItem = {
      ...event,
      id: crypto.randomUUID(),
      isRead: false,
      createdAt: new Date().toISOString(),
    };
    return this.repository.add(item);
  }

  /**
   * Mark single activity as read
   */
  public static markAsRead(id: string, userId: string): { success: boolean; unreadCount: number } {
    this.ensureInitialActivities(userId);
    this.repository.markRead(id, userId);
    const list = this.repository.findForUser(userId);
    const unreadCount = list.filter((a) => !a.isRead).length;
    return { success: true, unreadCount };
  }

  /**
   * Mark all activities as read
   */
  public static markAllAsRead(userId: string): { success: boolean; unreadCount: number } {
    this.ensureInitialActivities(userId);
    this.repository.markAllRead(userId);
    return { success: true, unreadCount: 0 };
  }
}
