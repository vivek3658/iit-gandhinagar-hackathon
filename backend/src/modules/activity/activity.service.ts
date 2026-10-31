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
    const existing = this.repository.findForUser(userId);
    if (existing.length > 0) return;

    // Welcome action
    this.repository.add({
      id: crypto.randomUUID(),
      userId,
      category: 'HABIT',
      title: 'Welcome to Urja Sanctuary! 🌿',
      message: 'You received 50 Urja Mudra coins to embark on your Mission LiFE journey.',
      icon: 'spark',
      coinsEarned: 50,
      district,
      isRead: false,
      createdAt: new Date().toISOString(),
    });

    // Gujarat community broadcasts
    this.repository.add({
      id: crypto.randomUUID(),
      userId: null,
      category: 'COMMUNITY',
      title: 'Surat Solar Park Milestone ☀️',
      message: 'Citizens in Surat collectively generated 25,000 kWh of rooftop solar energy this week!',
      icon: 'solar',
      district: 'Surat',
      isRead: false,
      createdAt: new Date(Date.now() - 3600000).toISOString(),
    });

    this.repository.add({
      id: crypto.randomUUID(),
      userId: null,
      category: 'ALERT',
      title: 'Peak Grid Hour Reminder ⚡',
      message: 'Ahmedabad grid peak begins at 6:30 PM. Switch off standby appliances to earn 2x bonus points!',
      icon: 'zap',
      district: 'Ahmedabad',
      isRead: false,
      createdAt: new Date(Date.now() - 7200000).toISOString(),
    });

    this.repository.add({
      id: crypto.randomUUID(),
      userId: null,
      category: 'SANCTUARY',
      title: 'Rajkot Eco-Gardener Landmark 🌳',
      message: 'Citizen Patel unlocked the Sacred Canopy Banyan tree after saving 120 kg of CO2.',
      icon: 'tree',
      district: 'Rajkot',
      isRead: false,
      createdAt: new Date(Date.now() - 14400000).toISOString(),
    });
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
