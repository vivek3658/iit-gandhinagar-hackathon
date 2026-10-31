import { describe, expect, it } from 'vitest';
import { buildApp } from '../src/app';

describe('Providers & Admin Modules Integration Tests', () => {
  const app = buildApp({ logger: false });
  let citizenToken = '';

  it('0. Authenticate test citizen for activity feed access', async () => {
    await app.ready();
    const login = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/google',
      payload: { idToken: 'mock_test_token_provider_user' },
    });
    expect(login.statusCode).toBe(200);
    const body = JSON.parse(login.body);
    citizenToken = body.accessToken;
    expect(citizenToken).toBeDefined();
  });

  it('1. GET /api/v1/providers lists all Gujarat electricity, gas, water, and transit utilities', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/providers',
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);
    expect(Array.isArray(body.providers)).toBe(true);
    expect(body.totalCount).toBeGreaterThanOrEqual(15);

    // Verify key Gujarat providers are seeded
    const ids = body.providers.map((p: { id: string }) => p.id);
    expect(ids).toContain('torrent_power');
    expect(ids).toContain('ugvcl');
    expect(ids).toContain('adani_png');
    expect(ids).toContain('amc_water');
    expect(ids).toContain('gmrc_metro');
  });

  it('2. GET /api/v1/providers?category=ELECTRICITY filters only electricity DISCOMs', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/providers?category=ELECTRICITY',
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.providers.every((p: { category: string }) => p.category === 'ELECTRICITY')).toBe(true);
    expect(body.providers.length).toBe(5); // Torrent, UGVCL, DGVCL, MGVCL, PGVCL
  });

  it('3. GET /api/v1/providers?district=Ahmedabad filters utilities serving Ahmedabad', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/providers?district=Ahmedabad',
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.providers.length).toBeGreaterThan(0);
    const ids = body.providers.map((p: { id: string }) => p.id);
    expect(ids).toContain('torrent_power');
    expect(ids).toContain('amc_water');
    expect(ids).toContain('amts_bus');
  });

  it('4. PUT /api/v1/providers/link links citizen accounts to their utilities', async () => {
    const linkPayload = {
      electricityProviderId: 'torrent_power',
      gasProviderId: 'adani_png',
      waterProviderId: 'amc_water',
      transitProviderIds: ['gmrc_metro', 'amts_bus'],
      consumerNumbers: {
        electricity: '100234567',
        gas: '9825012345',
      },
    };

    const res = await app.inject({
      method: 'PUT',
      url: '/api/v1/providers/link',
      payload: linkPayload,
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);
    expect(body.links.electricityProvider.id).toBe('torrent_power');
    expect(body.links.gasProvider.id).toBe('adani_png');
    expect(body.links.waterProvider.id).toBe('amc_water');
    expect(body.links.transitProviders.length).toBe(2);
    expect(body.links.consumerNumbers.electricity).toBe('100234567');
  });

  it('5. POST /api/v1/providers/:providerId/broadcast dispatches notification to citizen in-app feed', async () => {
    const broadcastPayload = {
      title: 'Peak Load Shifting Window (6:30 PM - 9:30 PM)',
      message: 'West Ahmedabad substations experiencing heavy load. Delay running washing machines to earn +20 Mudra coins!',
      category: 'ALERT',
      targetDistrict: 'Ahmedabad',
      incentiveCoins: 20,
      urgency: 'HIGH',
    };

    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/providers/torrent_power/broadcast',
      payload: broadcastPayload,
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);
    expect(body.notificationId).toBeDefined();

    // Verify notification appears in citizen activity feed!
    const activityRes = await app.inject({
      method: 'GET',
      url: '/api/v1/activity',
      headers: { authorization: `Bearer ${citizenToken}` },
    });

    expect(activityRes.statusCode).toBe(200);
    const activityBody = JSON.parse(activityRes.payload);
    const foundAlert = activityBody.activities.find((a: { title: string }) =>
      a.title.includes('Torrent Power Ltd: Peak Load Shifting Window')
    );
    expect(foundAlert).toBeDefined();
    expect(foundAlert.coinsEarned).toBe(20);
  });

  it('6. GET /api/v1/admin/kpis returns state-wide GEDA aggregated metrics', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/admin/kpis',
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);
    expect(body.kpis.totalRegisteredCitizens).toBeGreaterThan(0);
    expect(body.kpis.totalCo2eSavedKg).toBeGreaterThan(0);
    expect(body.kpis.totalPeakMwhShifted).toBeGreaterThan(0);
    expect(body.kpis.districtBreakdown['Ahmedabad']).toBeDefined();
  });

  it('7. POST /api/v1/admin/broadcast-alert broadcasts state-wide GEDA advisory', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/admin/broadcast-alert',
      payload: {
        title: 'Mission LiFE State-wide Challenge',
        message: 'All Gujarat citizens completing 5 consecutive green days earn the Gold Eco-Shield badge!',
        category: 'COMMUNITY',
        incentiveCoins: 30,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.success).toBe(true);
    expect(body.broadcastId).toBeDefined();
  });
});
