import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app';
import { AuthService } from '../src/modules/auth/auth.service';

describe('Registered household devices', () => {
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
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_registrycitizen' },
    });
    citizenToken = JSON.parse(login.body).accessToken as string;
  });

  it('registers, estimates daily energy from rated power, and removes an owned device', async () => {
    const registration = await app.inject({
      method: 'POST',
      url: '/api/v1/devices/registry',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        name: 'Living room fan',
        category: 'fan',
        discoveryMethod: 'BLE',
        ratedPowerW: 500,
      },
    });

    expect(registration.statusCode).toBe(201);
    const { device } = JSON.parse(registration.body) as {
      device: { id: string; ratedPowerW: number };
    };
    expect(device.ratedPowerW).toBe(500);

    const runtime = await app.inject({
      method: 'POST',
      url: `/api/v1/devices/registry/${device.id}/runtime`,
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: { operatingHours: 2, date: '2026-03-01' },
    });
    expect(runtime.statusCode).toBe(200);
    expect(JSON.parse(runtime.body)).toMatchObject({
      energyConsumedKwh: 1,
      energyEvidence: 'RATED_POWER_ESTIMATE',
      co2EmissionsKg: null,
    });

    const list = await app.inject({
      method: 'GET',
      url: '/api/v1/devices/registry',
      headers: { authorization: `Bearer ${citizenToken}` },
    });
    const listedDevices = JSON.parse(list.body).devices as Record<string, unknown>[];
    expect(list.statusCode).toBe(200);
    expect(listedDevices).toHaveLength(1);
    expect(listedDevices[0]).toMatchObject({
      id: device.id,
      lastLoggedHours: 2,
      lastEnergyKwh: 1,
      lastLogDate: '2026-03-01',
    });
    expect(listedDevices[0]).not.toHaveProperty('userId');

    const removed = await app.inject({
      method: 'DELETE',
      url: `/api/v1/devices/registry/${device.id}`,
      headers: { authorization: `Bearer ${citizenToken}` },
    });
    expect(removed.statusCode).toBe(204);
  });

  it('keeps runtime-only logs honest and does not expose another citizen’s device', async () => {
    const registration = await app.inject({
      method: 'POST',
      url: '/api/v1/devices/registry',
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: {
        name: 'Bedroom fan',
        category: 'fan',
        discoveryMethod: 'MANUAL',
      },
    });
    const { device } = JSON.parse(registration.body) as { device: { id: string } };

    const otherLogin = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_registryother' },
    });
    const otherToken = JSON.parse(otherLogin.body).accessToken as string;

    const foreignRuntime = await app.inject({
      method: 'POST',
      url: `/api/v1/devices/registry/${device.id}/runtime`,
      headers: { authorization: `Bearer ${otherToken}` },
      payload: { operatingHours: 1, date: '2026-03-01' },
    });
    expect(foreignRuntime.statusCode).toBe(404);

    const runtime = await app.inject({
      method: 'POST',
      url: `/api/v1/devices/registry/${device.id}/runtime`,
      headers: { authorization: `Bearer ${citizenToken}` },
      payload: { operatingHours: 1, date: '2026-03-01' },
    });
    expect(runtime.statusCode).toBe(200);
    expect(JSON.parse(runtime.body)).toMatchObject({
      energyConsumedKwh: null,
      energyEvidence: 'RUNTIME_ONLY',
      co2EmissionsKg: null,
    });

    const foreignRemoval = await app.inject({
      method: 'DELETE',
      url: `/api/v1/devices/registry/${device.id}`,
      headers: { authorization: `Bearer ${otherToken}` },
    });
    expect(foreignRemoval.statusCode).toBe(404);
  });

  it('requires authentication to access the device registry', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/v1/devices/registry',
    });
    expect(response.statusCode).toBe(401);
  });
});
