import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app';
import { AuthService } from '../src/modules/auth/auth.service';
import { ActivityService } from '../src/modules/activity/activity.service';

describe('Activity Feed Module (Event Stream & Notifications)', () => {
  let app: FastifyInstance;
  let citizenToken: string;
  let citizenId: string;

  beforeAll(async () => {
    app = buildApp({ logger: false });
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(async () => {
    AuthService.getRepository().clear();
    ActivityService.getRepository().clear();

    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_activity_user' },
    });
    const body = JSON.parse(login.body);
    citizenToken = body.accessToken;
    citizenId = body.user.id;
  });

  it('1. GET /api/v1/activity starts empty instead of inventing welcome rewards or community events', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/activity',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);

    expect(body.activities).toEqual([]);
    expect(body.unreadCount).toBe(0);
    expect(body.totalCount).toBe(0);
  });

  it('2. Filters real activity by category', async () => {
    ActivityService.postActivity({ userId: citizenId, category: 'COMMUNITY', title: 'Verified community update', message: 'Community update from the test fixture.', icon: 'leaf' });
    ActivityService.postActivity({ userId: citizenId, category: 'HABIT', title: 'Verified habit', message: 'Self-reported test action.', icon: 'zap' });
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/activity?category=COMMUNITY',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.activities.length).toBe(1);
    for (const act of body.activities) {
      expect(act.category).toBe('COMMUNITY');
    }
  });

  it('3. POST /api/v1/activity/:id/read marks single notification as read', async () => {
    ActivityService.postActivity({ userId: citizenId, category: 'HABIT', title: 'Test action', message: 'A real test event.', icon: 'leaf' });
    // 1. Fetch initial feed
    const feedRes = await app.inject({
      method: 'GET',
      url: '/api/v1/activity',
      headers: { authorization: `Bearer ${citizenToken}` },
    });
    const feed = JSON.parse(feedRes.body);
    const targetId = feed.activities[0].id;

    // 2. Mark as read
    const readRes = await app.inject({
      method: 'POST',
      url: `/api/v1/activity/${targetId}/read`,
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(readRes.statusCode).toBe(200);
    const readBody = JSON.parse(readRes.body);
    expect(readBody.success).toBe(true);
    expect(readBody.unreadCount).toBe(feed.unreadCount - 1);
  });

  it('4. POST /api/v1/activity/read-all marks all notifications as read', async () => {
    ActivityService.postActivity({ userId: citizenId, category: 'HABIT', title: 'Action one', message: 'Test event one.', icon: 'leaf' });
    ActivityService.postActivity({ userId: citizenId, category: 'HABIT', title: 'Action two', message: 'Test event two.', icon: 'zap' });
    const readAllRes = await app.inject({
      method: 'POST',
      url: '/api/v1/activity/read-all',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(readAllRes.statusCode).toBe(200);
    const readAllBody = JSON.parse(readAllRes.body);
    expect(readAllBody.success).toBe(true);
    expect(readAllBody.unreadCount).toBe(0);

    // Verify unreadCount in feed is now 0
    const feedRes = await app.inject({
      method: 'GET',
      url: '/api/v1/activity',
      headers: { authorization: `Bearer ${citizenToken}` },
    });
    expect(JSON.parse(feedRes.body).unreadCount).toBe(0);
  });
});
