import { beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app';
import { AuthService } from '../src/modules/auth/auth.service';

describe('Citizen readings, vehicles, and confirmed trips', () => {
  const app = buildApp({ logger: false });
  let token = '';

  beforeAll(async () => {
    await app.ready();
    AuthService.getRepository().clear();
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_citizen_data' },
    });
    token = (JSON.parse(login.payload) as { accessToken: string }).accessToken;
  });

  it('stores and lists user-entered utility readings with honest source labels', async () => {
    const created = await app.inject({
      method: 'POST',
      url: '/api/v1/readings',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        utility: 'ELECTRICITY',
        value: 180,
        unit: 'kWh',
        periodStart: '2026-10-01',
        periodEnd: '2026-10-31',
      },
    });

    expect(created.statusCode).toBe(201);
    expect(JSON.parse(created.payload).reading.evidenceTier).toBe('USER_ENTERED');
    const listed = await app.inject({
      method: 'GET',
      url: '/api/v1/readings',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(JSON.parse(listed.payload).readings).toHaveLength(1);
  });

  it('rejects unsupported reading units', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/api/v1/readings',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        utility: 'ELECTRICITY',
        value: 180,
        unit: 'litres',
        periodStart: '2026-10-01',
        periodEnd: '2026-10-31',
      },
    });

    expect(response.statusCode).toBe(400);
  });

  it('persists user-entered vehicles and accepts confirmed trip summaries idempotently', async () => {
    const vehicleResponse = await app.inject({
      method: 'POST',
      url: '/api/v1/vehicles',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        label: 'My scooter',
        vehicleType: 'TWO_WHEELER',
        fuelType: 'PETROL',
        efficiency: 45,
        efficiencyUnit: 'km/L',
      },
    });
    expect(vehicleResponse.statusCode).toBe(201);
    const vehicleId = JSON.parse(vehicleResponse.payload).vehicle.id as string;

    const trip = {
      idempotencyKey: 'trip-confirmation-0001',
      mode: 'PRIVATE_VEHICLE',
      distanceKm: 4.5,
      startedAt: '2026-11-02T07:00:00.000Z',
      endedAt: '2026-11-02T07:20:00.000Z',
      vehicleId,
      userConfirmed: true,
    };
    const first = await app.inject({
      method: 'POST',
      url: '/api/v1/trips',
      headers: { authorization: `Bearer ${token}` },
      payload: trip,
    });
    const retry = await app.inject({
      method: 'POST',
      url: '/api/v1/trips',
      headers: { authorization: `Bearer ${token}` },
      payload: trip,
    });

    expect(first.statusCode).toBe(201);
    expect(retry.statusCode).toBe(201);
    expect(JSON.parse(first.payload).trip.id).toBe(JSON.parse(retry.payload).trip.id);
    expect(JSON.parse(retry.payload).trip.co2eKg).toBeNull();
    expect(JSON.parse(retry.payload).trip.evidenceTier).toBe('USER_CONFIRMED_SUMMARY');
  });

  it('does not expose endpoints to unauthenticated callers', async () => {
    const response = await app.inject({ method: 'GET', url: '/api/v1/vehicles' });
    expect(response.statusCode).toBe(401);
  });
});
