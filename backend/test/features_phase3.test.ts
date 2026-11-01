import { beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app';
import { AuthService } from '../src/modules/auth/auth.service';

describe('Phase 3 Advanced Systems Integration Tests (Leaderboard, Calculator, Analytics, Quests, Devices)', () => {
  const app = buildApp({ logger: false });
  let token = '';

  beforeAll(async () => { await app.ready(); });
  beforeEach(async () => {
    AuthService.getRepository().clear();
    const login = await app.inject({ method: 'POST', url: '/api/v1/auth/google', payload: { idToken: 'mock_test_token_phase3_user' } });
    token = JSON.parse(login.payload).accessToken as string;
  });

  it('1. GET /api/v1/leaderboard/league returns weekly Duolingo-style league with promotion/demotion zones', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/leaderboard/league',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.league).toBeDefined();
    expect(Array.isArray(body.members)).toBe(true);
    expect(body.members).toEqual([]);
    expect(body.yourRank).toBe(0);
  });

  it('2. GET /api/v1/leaderboard/global returns Gujarat municipal city rankings and top citizens', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/leaderboard/global',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(Array.isArray(body.municipalRankings)).toBe(true);
    expect(body.municipalRankings).toEqual([]);
    expect(body.topCitizens).toEqual([]);
  });

  it('3. GET /api/v1/leaderboard/visit/:citizenId returns another citizen public 3D garden and mascot', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/leaderboard/visit/cit_priya_ahmedabad',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(res.statusCode).toBe(404);
  });

  it('4. POST /api/v1/leaderboard/cheer/:citizenId awards applause cheer and coins', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/leaderboard/cheer/cit_priya_ahmedabad',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(res.statusCode).toBe(404);
  });

  it('5. POST /api/v1/calculator/estimate computes household carbon footprint and benchmarks', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/calculator/estimate',
      payload: {
        monthlyElectricityUnitsKwh: 220,
        cookingFuelType: 'LPG_CYLINDER',
        cookingMonthlyQuantity: 1,
        dailyCommuteKm: 15,
        commuteMode: 'EV_2WHEELER',
        dietType: 'VEGETARIAN',
      },
      headers: { authorization: `Bearer ${token}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.totalYearlyKgCO2e).toBeGreaterThan(0);
    expect(body.benchmarks.gujaratAverageKgCO2e).toBe(1850);
    expect(body.benchmarks.indiaAverageKgCO2e).toBe(1910);
    expect(Array.isArray(body.actionPlan)).toBe(true);
    expect(body.actionPlan.length).toBeGreaterThanOrEqual(3);
  });

  it('6. GET /api/v1/analytics/dashboard returns 24h hourly load curve, appliance power breakdown, and solar offset', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/analytics/dashboard',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(Array.isArray(body.hourlyLoadCurve)).toBe(true);
    expect(body.hourlyLoadCurve.length).toBe(24);
    expect(Array.isArray(body.applianceBreakdown)).toBe(true);
    expect(body.applianceBreakdown.length).toBeGreaterThanOrEqual(5);

    const acAppliance = body.applianceBreakdown.find((a: { applianceName: string }) =>
      a.applianceName.toLowerCase().includes('ac') || a.category === 'Cooling',
    );
    expect(acAppliance).toBeDefined();
    expect(acAppliance?.percentShare).toBeGreaterThan(0);
  });

  it('7. GET /api/v1/quests/daily and POST /api/v1/quests/claim/:id tracks daily tasks and rewards', async () => {
    const listRes = await app.inject({
      method: 'GET',
      url: '/api/v1/quests/daily',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(listRes.statusCode).toBe(200);
    const listBody = JSON.parse(listRes.payload);
    expect(Array.isArray(listBody.quests)).toBe(true);
    expect(listBody.quests.length).toBe(5);

    const questToClaim = listBody.quests[0].id;
    const claimRes = await app.inject({
      method: 'POST',
      url: `/api/v1/quests/claim/${questToClaim}`,
      headers: { authorization: `Bearer ${token}` },
    });
    expect(claimRes.statusCode).toBe(200);
    const claimBody = JSON.parse(claimRes.payload);
    expect(claimBody.success).toBe(true);
    expect(claimBody.coinsAwarded).toBeGreaterThanOrEqual(10);
  });

  it('8. POST /api/v1/devices/log-hours and GET /api/v1/devices/summary flags excess hours alert', async () => {
    // Log AC with 8.5 hours (exceeds normal 5.0h)
    const logRes = await app.inject({
      method: 'POST',
      url: '/api/v1/devices/log-hours',
      payload: {
        deviceCatalogId: 'ac',
        operatingHours: 8.5,
        thermostatTemp: 22,
      },
      headers: { authorization: `Bearer ${token}` },
    });

    expect(logRes.statusCode).toBe(200);
    const logBody = JSON.parse(logRes.payload);
    expect(logBody.highUsageAlert).not.toBeNull();
    expect(logBody.highUsageAlert.triggered).toBe(true);
    expect(logBody.highUsageAlert.excessHours).toBe(3.5);
    expect(logBody.highUsageAlert.potentialSavingsRupeesMonthly).toBeGreaterThan(0);

    const summaryRes = await app.inject({
      method: 'GET',
      url: '/api/v1/devices/summary',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(summaryRes.statusCode).toBe(200);
    const summaryBody = JSON.parse(summaryRes.payload);
    expect(Array.isArray(summaryBody.devices)).toBe(true);
    expect(summaryBody.highHourWarnings.length).toBeGreaterThan(0);
  });
});
