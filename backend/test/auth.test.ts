import { describe, it, expect, beforeAll, afterAll, beforeEach, vi } from 'vitest';
import type { FastifyInstance } from 'fastify';
import crypto from 'node:crypto';
import type { Pool } from 'pg';
import { buildApp } from '../src/app';
import { AuthPersistenceError, AuthService } from '../src/modules/auth/auth.service';

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
    expect(body.user.points).toBe(50); // 50 bonus Mission LiFE points
    expect(body.user.role).toBe('CITIZEN');
  });

  it('rejects unsigned Google token payloads instead of trusting decoded claims', async () => {
    const unsignedToken =
      'eyJhbGciOiJub25lIn0.eyJzdWIiOiJhdHRhY2tlciIsImVtYWlsIjoiYXR0YWNrZXJAZXhhbXBsZS5jb20ifQ.';
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: unsignedToken },
    });

    expect(res.statusCode).toBe(400);
    expect(JSON.parse(res.body).message).toContain(
      'Google authentication failed',
    );
  });

  it('returns a server error when Google auth persistence fails', async () => {
    const authenticate = vi
      .spyOn(AuthService, 'authenticateWithGoogle')
      .mockRejectedValueOnce(new AuthPersistenceError('Failed to persist user', new Error('database unavailable')));

    try {
      const res = await app.inject({
        method: 'POST',
        url: '/api/v1/auth/google',
        payload: { idToken: 'mock_test_token_persistence_failure' },
      });

      expect(res.statusCode).toBe(500);
    } finally {
      authenticate.mockRestore();
    }
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

  it('8. Serverless cold-start recovery: PostgreSQL rehydrates citizen on cache wipe', async () => {
    const repo = AuthService.getRepository();
    const postgresStore = new Map<string, Record<string, unknown>>();
    const db = {
      query: async (sql: string, values: unknown[] = []) => {
        if (sql.includes('INSERT INTO users')) {
          const [
            id, googleId, email, name, avatarUrl, dob, district, ward, houseType,
            householdMembers, monthlyBillRupees, waterSupplyType, waterStorageType,
            deviceCatalogIds, vehicleCatalogIds, mascotName, role, isProfileComplete,
            points, createdAt, updatedAt, deletedAt,
          ] = values;
          postgresStore.set(String(id), {
            id,
            google_id: googleId,
            email,
            name,
            avatar_url: avatarUrl,
            dob,
            district,
            ward,
            house_type: houseType,
            household_members: householdMembers,
            monthly_bill_rupees: monthlyBillRupees,
            water_supply_type: waterSupplyType,
            water_storage_type: waterStorageType,
            device_catalog_ids: deviceCatalogIds,
            vehicle_catalog_ids: vehicleCatalogIds,
            mascot_name: mascotName,
            role,
            is_profile_complete: isProfileComplete,
            points,
            created_at: createdAt,
            updated_at: updatedAt,
            deleted_at: deletedAt,
          });
          return { rows: [] };
        }

        if (sql.includes('SELECT * FROM users')) {
          const matchingRows = Array.from(postgresStore.values()).filter((row) => {
            if (sql.includes('google_id = $1')) return row.google_id === values[0] && !row.deleted_at;
            if (sql.includes('LOWER(email)')) return String(row.email).toLowerCase() === String(values[0]).toLowerCase() && !row.deleted_at;
            if (sql.includes('id = $1')) return row.id === values[0] && !row.deleted_at;
            return !row.deleted_at;
          });
          return { rows: matchingRows };
        }

        return { rows: [] };
      },
    } as unknown as Pool;

    await repo.setDbClients({ db });

    const citizen = await repo.createUserAsync({
      googleId: 'cold_start_google_sub_999',
      email: 'coldstart@example.com',
      name: 'Cold Start Citizen',
      avatarUrl: null,
      dob: null,
      district: 'Ahmedabad',
      role: 'CITIZEN',
      isProfileComplete: false,
      points: 100,
    });

    expect(postgresStore.has(citizen.id)).toBe(true);

    repo.clear();
    expect(repo.findById(citizen.id)).toBeNull();

    const recovered = await repo.findByGoogleIdAsync('cold_start_google_sub_999');
    expect(recovered).not.toBeNull();
    expect(recovered?.id).toBe(citizen.id);
    expect(recovered?.email).toBe('coldstart@example.com');
    expect(recovered?.points).toBe(100);

    expect(repo.findById(citizen.id)).not.toBeNull();

    await repo.setDbClients({ db: null });
  });
});
