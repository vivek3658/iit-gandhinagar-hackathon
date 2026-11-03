import { beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app';
import { AuthService } from '../src/modules/auth/auth.service';

describe('Learning chapters and daily waste-sorting game', () => {
  const app = buildApp({ logger: false });
  let token = '';

  beforeAll(async () => {
    await app.ready();
    AuthService.getRepository().clear();
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_learning_rewards' },
    });
    token = (JSON.parse(login.payload) as { accessToken: string }).accessToken;
  });

  it('exposes versioned chapters without revealing quiz answers', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/v1/learning/chapters',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(response.statusCode).toBe(200);
    const chapters = JSON.parse(response.payload).chapters as Array<Record<string, unknown>>;
    expect(chapters.length).toBeGreaterThan(0);
    expect(chapters[0].version).toBe(1);
    expect(chapters[0].correctAnswerId).toBeUndefined();
  });

  it('awards a chapter-version reward once and only after a correct answer', async () => {
    const wrong = await app.inject({
      method: 'POST',
      url: '/api/v1/learning/chapters/electricity-at-home/complete',
      headers: { authorization: `Bearer ${token}` },
      payload: { version: 1, answerId: 'bill-total' },
    });
    expect(wrong.statusCode).toBe(400);

    const payload = { version: 1, answerId: 'same-period' };
    const first = await app.inject({
      method: 'POST',
      url: '/api/v1/learning/chapters/electricity-at-home/complete',
      headers: { authorization: `Bearer ${token}` },
      payload,
    });
    const retry = await app.inject({
      method: 'POST',
      url: '/api/v1/learning/chapters/electricity-at-home/complete',
      headers: { authorization: `Bearer ${token}` },
      payload,
    });
    expect(JSON.parse(first.payload).coinsAwarded).toBe(10);
    expect(JSON.parse(first.payload).alreadyCompleted).toBe(false);
    expect(JSON.parse(retry.payload).coinsAwarded).toBe(0);
    expect(JSON.parse(retry.payload).alreadyCompleted).toBe(true);

    const progress = await app.inject({
      method: 'GET',
      url: '/api/v1/learning/progress',
      headers: { authorization: 'Bearer ' + token },
    });
    expect(progress.statusCode).toBe(200);
    expect(JSON.parse(progress.payload).completions).toContainEqual({
      chapterId: 'electricity-at-home',
      version: 1,
    });
  });

  it('awards the waste game once per day and does not claim measured diversion', async () => {
    const payload = {
      idempotencyKey: 'sorting-session-0001',
      answers: [
        { itemId: 'fruit-peel', bucket: 'ORGANIC' },
        { itemId: 'used-battery', bucket: 'SPECIAL_HANDLING' },
      ],
    };
    const first = await app.inject({
      method: 'POST',
      url: '/api/v1/learning/waste-game/play',
      headers: { authorization: `Bearer ${token}` },
      payload,
    });
    const retry = await app.inject({
      method: 'POST',
      url: '/api/v1/learning/waste-game/play',
      headers: { authorization: `Bearer ${token}` },
      payload: { ...payload, idempotencyKey: 'sorting-session-retry-02' },
    });

    expect(first.statusCode).toBe(200);
    expect(JSON.parse(first.payload).coinsAwarded).toBe(5);
    expect(JSON.parse(retry.payload).alreadyPlayedToday).toBe(true);
    expect(JSON.parse(retry.payload).coinsAwarded).toBe(0);
  });
});
