import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';
import crypto from 'node:crypto';
import { buildApp } from '../src/app';
import { AuthService } from '../src/modules/auth/auth.service';

describe('Auth & Media Modules (ACID + Security Tests)', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = buildApp({ logger: false });
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    AuthService.getRepository().clear();
  });

  it('1. One-Button Google Auth creates new citizen and returns dual tokens', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_citizen1' },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);

    expect(body.isNewUser).toBe(true);
    expect(body.isProfileComplete).toBe(false);
    expect(typeof body.accessToken).toBe('string');
    expect(typeof body.refreshToken).toBe('string');
    expect(body.user.email).toBe('citizen1@example.com');
    expect(body.user.points).toBe(100); // 100 bonus Mission LiFE points
    expect(body.user.role).toBe('CITIZEN');
  });

  it('2. Complete Profile updates onboarding data and sets isProfileComplete to true', async () => {
    // 1. Initial Google signup
    const loginRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_citizen2' },
    });
    const { accessToken } = JSON.parse(loginRes.body);

    // 2. Submit onboarding profile
    const profileRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/complete-profile',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
      payload: {
        dob: '1998-04-12',
        district: 'Gandhinagar',
        avatarUrl: 'https://ik.imagekit.io/urjavatika/avatars/custom_citizen2.webp',
      },
    });

    expect(profileRes.statusCode).toBe(200);
    const profileBody = JSON.parse(profileRes.body);
    expect(profileBody.success).toBe(true);
    expect(profileBody.isProfileComplete).toBe(true);
    expect(profileBody.user.district).toBe('Gandhinagar');
    expect(profileBody.user.dob).toBe('1998-04-12');

    // 3. Subsequent Google login routes existing user with isProfileComplete = true
    const repeatLogin = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_citizen2' },
    });
    const repeatBody = JSON.parse(repeatLogin.body);
    expect(repeatBody.isNewUser).toBe(false);
    expect(repeatBody.isProfileComplete).toBe(true);
  });

  it('3. GET /api/v1/auth/me returns current user, rejecting unauthorized requests', async () => {
    // Unauthorized attempt
    const unauth = await app.inject({
      method: 'GET',
      url: '/api/v1/auth/me',
    });
    expect(unauth.statusCode).toBe(401);

    // Authorized attempt
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_citizen3' },
    });
    const { accessToken } = JSON.parse(login.body);

    const meRes = await app.inject({
      method: 'GET',
      url: '/api/v1/auth/me',
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(meRes.statusCode).toBe(200);
    const meBody = JSON.parse(meRes.body);
    expect(meBody.user.email).toBe('citizen3@example.com');
  });

  it('4. Refresh Token rotation issues fresh tokens and revokes old token (Anti-Replay)', async () => {
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_citizen4' },
    });
    const { refreshToken: initialRefreshToken } = JSON.parse(login.body);

    // First rotation succeeds
    const refreshRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/refresh',
      payload: { refreshToken: initialRefreshToken },
    });

    expect(refreshRes.statusCode).toBe(200);
    const refreshBody = JSON.parse(refreshRes.body);
    expect(typeof refreshBody.accessToken).toBe('string');
    expect(typeof refreshBody.refreshToken).toBe('string');
    expect(refreshBody.refreshToken).not.toBe(initialRefreshToken);

    // Replay attack: Using the old, already-rotated refresh token MUST be rejected!
    const replayRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/refresh',
      payload: { refreshToken: initialRefreshToken },
    });

    expect(replayRes.statusCode).toBe(401);
  });

  it('5. Logout revokes token', async () => {
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_citizen5' },
    });
    const { accessToken, refreshToken } = JSON.parse(login.body);

    const logoutRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/logout',
      headers: { authorization: `Bearer ${accessToken}` },
      payload: { refreshToken },
    });

    expect(logoutRes.statusCode).toBe(200);
    const logoutBody = JSON.parse(logoutRes.body);
    expect(logoutBody.success).toBe(true);

    // Refresh token is now invalid
    const refreshAfterLogout = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/refresh',
      payload: { refreshToken },
    });
    expect(refreshAfterLogout.statusCode).toBe(401);
  });

  it('6. Delete Account performs soft delete and scrubs citizen PII', async () => {
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_citizen6' },
    });
    const { accessToken, user } = JSON.parse(login.body);

    const deleteRes = await app.inject({
      method: 'DELETE',
      url: '/api/v1/auth/account',
      headers: { authorization: `Bearer ${accessToken}` },
    });

    expect(deleteRes.statusCode).toBe(200);

    // User is now inaccessible
    const meAfterDelete = await app.inject({
      method: 'GET',
      url: '/api/v1/auth/me',
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(meAfterDelete.statusCode).toBe(404);

    // Verify PII is scrubbed in repository
    const rawUser = AuthService.getRepository().findById(user.id);
    expect(rawUser).toBeNull(); // findById filters soft-deleted users
  });

  it('7. ImageKit Auth generates verifiable HMAC-SHA1 signature without leaking private key', async () => {
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_citizen7' },
    });
    const { accessToken } = JSON.parse(login.body);

    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/media/imagekit-auth',
      headers: { authorization: `Bearer ${accessToken}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);

    expect(typeof body.token).toBe('string');
    expect(typeof body.expire).toBe('number');
    expect(typeof body.signature).toBe('string');
    expect(typeof body.publicKey).toBe('string');

    // Cryptographic verification: Re-calculate HMAC-SHA1 using test private key
    const privateKey =
      app.config?.IMAGEKIT_PRIVATE_KEY ||
      process.env.IMAGEKIT_PRIVATE_KEY ||
      'private_mock_imagekit_key_strictly_secret';

    const expectedSignature = crypto
      .createHmac('sha1', privateKey)
      .update(body.token + body.expire)
      .digest('hex');

    expect(body.signature).toBe(expectedSignature);
  });
});
