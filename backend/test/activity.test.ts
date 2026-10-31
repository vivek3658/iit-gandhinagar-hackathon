import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app';
import { AuthService } from '../src/modules/auth/auth.service';
import { ActivityService } from '../src/modules/activity/activity.service';

describe('Activity Feed Module (Event Stream & Notifications)', () => {
  let app: FastifyInstance;
  let citizenToken: string;

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
  });

  it('1. GET /api/v1/activity auto-seeds welcome + community Gujarat eco-events', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/activity',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);

    expect(body.activities.length).toBeGreaterThanOrEqual(4);
    expect(body.unreadCount).toBeGreaterThanOrEqual(4);
    expect(body.totalCount).toBeGreaterThanOrEqual(4);

    // Verify presence of welcome event
    const welcome = body.activities.find((a: { title: string }) => a.title.includes('Welcome'));
    expect(welcome).toBeDefined();
    expect(welcome.coinsEarned).toBe(50);
  });

  it('2. Filter activity by category (e.g. HABIT, COMMUNITY, ALERT)', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/activity?category=COMMUNITY',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.activities.length).toBeGreaterThanOrEqual(1);
    for (const act of body.activities) {
      expect(act.category).toBe('COMMUNITY');
    }
  });

  it('3. POST /api/v1/activity/:id/read marks single notification as read', async () => {
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
