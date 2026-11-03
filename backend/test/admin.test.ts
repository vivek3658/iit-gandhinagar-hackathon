import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { scryptSync } from 'node:crypto';
import { buildApp } from '../src/app';
import { AuthService } from '../src/modules/auth/auth.service';

const originalAdminEmail = process.env.ADMIN_EMAIL;
const originalAdminHash = process.env.ADMIN_PASSWORD_HASH;
const testPassword = 'test-admin-password';
const testSalt = Buffer.alloc(16, 23);
const testPasswordHash = scryptSync(testPassword, testSalt, 64);

process.env.ADMIN_EMAIL = 'admin@example.test';
process.env.ADMIN_PASSWORD_HASH = `scrypt$${testSalt.toString('base64')}$${testPasswordHash.toString('base64')}`;

const app = buildApp({ logger: false });

describe('Admin authentication and authorization', () => {
  let citizenToken = '';

  beforeAll(async () => {
    await app.ready();
    AuthService.getRepository().clear();
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_admin_access' },
    });
    citizenToken = (JSON.parse(login.payload) as { accessToken: string }).accessToken;
  });

  afterAll(async () => {
    await app.close();
    if (originalAdminEmail === undefined) delete process.env.ADMIN_EMAIL;
    else process.env.ADMIN_EMAIL = originalAdminEmail;
    if (originalAdminHash === undefined) delete process.env.ADMIN_PASSWORD_HASH;
    else process.env.ADMIN_PASSWORD_HASH = originalAdminHash;
  });

  it('does not allow anonymous requests to admin data', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/v1/admin/kpis',
    });

    expect(response.statusCode).toBe(401);
  });

  it('does not allow a citizen JWT to access admin data', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/v1/admin/providers',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(response.statusCode).toBe(403);
  });

  it('issues an admin JWT only for configured email/password credentials', async () => {
    const invalid = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: { email: 'admin@example.test', password: 'wrong-password' },
    });
    expect(invalid.statusCode).toBe(401);

    const valid = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: { email: 'admin@example.test', password: testPassword },
    });
    expect(valid.statusCode).toBe(200);
    expect(JSON.parse(valid.payload).accessToken).toBeTruthy();

    const usernameLogin = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: { username: 'admin@example.test', password: testPassword },
    });
    expect(usernameLogin.statusCode).toBe(200);
  });

  it('requires a platform admin to create a provider directory entry', async () => {
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: { email: 'admin@example.test', password: testPassword },
    });
    const token = (JSON.parse(login.payload) as { accessToken: string }).accessToken;
    const response = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/providers',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        id: 'test_solar_provider',
        name: 'Test Solar Provider',
        category: 'ELECTRICITY',
        districts: ['Ahmedabad'],
        code: 'TESTSOLAR',
        contactPhone: '1800-000-0000',
        reason: 'Test provider directory validation',
      },
    });
    expect(response.statusCode).toBe(503);
  });

  it('returns unavailable instead of fabricated metrics when PostgreSQL is absent', async () => {
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: { email: 'admin@example.test', password: testPassword },
    });
    const token = (JSON.parse(login.payload) as { accessToken: string }).accessToken;
    const response = await app.inject({
      method: 'GET',
      url: '/api/v1/admin/kpis',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(response.statusCode).toBe(503);
  });

  it('does not report a broadcast as delivered until durable delivery is configured', async () => {
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      payload: { email: 'admin@example.test', password: testPassword },
    });
    const token = (JSON.parse(login.payload) as { accessToken: string }).accessToken;
    const response = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/broadcast-alert',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        title: 'Grid advisory',
        message: 'Please reduce peak-hour electricity use.',
      },
    });

    expect(response.statusCode).toBe(503);
  });
});
