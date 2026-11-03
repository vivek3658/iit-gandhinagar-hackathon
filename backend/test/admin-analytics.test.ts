import { describe, expect, it, vi } from 'vitest';
import type { Pool } from 'pg';
import { AdminService } from '../src/modules/admin/admin.service';

function createDb(householdRow: {
  consented_citizens: string | null;
  registered_devices: string | null;
  estimated_energy_kwh: string | null;
}) {
  const statements: string[] = [];
  const consented = householdRow.consented_citizens !== null;
  const db = {
    query: vi.fn(async (sql: string) => {
      statements.push(sql);
      if (sql.includes('GROUPING SETS')) {
        return {
          rows: [
            {
              district: null,
              citizen_count: '10',
              coin_total: '400',
              is_total: true,
            },
          ],
        };
      }
      if (sql.includes('WITH totals AS')) return { rows: [householdRow] };
      if (sql.includes('SELECT BTRIM(district)')) {
        return consented
          ? { rows: [{ district: 'Ahmedabad', ward: 'Ward 1', citizen_count: '6' }] }
          : { rows: [] };
      }
      if (sql.includes('WITH monthly_latest AS')) {
        return consented
          ? {
              rows: [
                {
                  utility: 'ELECTRICITY',
                  district: 'Ahmedabad',
                  ward: 'Ward 1',
                  unit: 'kWh',
                  period: '2026-10',
                  average_value: '80.2',
                  contributors: '6',
                },
              ],
            }
          : { rows: [] };
      }
      if (sql.includes('GROUP BY t.user_id, u.district, u.ward')) {
        return consented
          ? {
              rows: [
                {
                  district: 'Ahmedabad',
                  ward: 'Ward 1',
                  estimated_co2e_kg: '24.8',
                  contributors: '6',
                },
              ],
            }
          : { rows: [] };
      }
      if (sql.includes('SUM(t.distance_km') && sql.includes('GROUP BY t.user_id')) {
        return { rows: [{ estimated_co2e_kg: consented ? '24.8' : null }] };
      }
      if (sql.includes('WITH eligible AS') && sql.includes('utility_readings')) {
        return {
          rows: [
            {
              utility_readings: consented ? '12' : null,
              runtime_logs: consented ? '8' : null,
              confirmed_trips: consented ? '6' : null,
            },
          ],
        };
      }
      if (sql.includes('WITH consented_links AS')) {
        return { rows: [{ provider_id: 'power-a', subscribers: '6' }] };
      }
      return { rows: [] };
    }),
  } as unknown as Pool;
  return { db, statements };
}

describe('Admin household analytics privacy', () => {
  it('suppresses anonymous totals when fewer than five citizens opt in', async () => {
    const { db, statements } = createDb({
      consented_citizens: null,
      registered_devices: null,
      estimated_energy_kwh: null,
    });

    const response = await AdminService.getKpis(db);

    expect(response.kpis.householdAnalytics).toEqual({
      consentedCitizens: null,
      registeredDevices: null,
      estimatedEnergyKwh: null,
      utilityReadings: null,
      runtimeLogs: null,
      confirmedTrips: null,
    });
    const aggregateQuery = statements.find((sql) => sql.includes('WITH totals AS'));
    expect(aggregateQuery).toContain('consented_citizens >= 5');
    expect(aggregateQuery).not.toContain('device.name');
    const usageQuery = statements.find((sql) => sql.includes('WITH monthly_latest AS'));
    expect(usageQuery).toContain('household_analytics_enabled = TRUE');
    expect(usageQuery).toContain('HAVING COUNT(DISTINCT user_id) >= 5');
    expect(response.kpis.utilityUsage).toEqual([]);
    expect(response.kpis.estimatedCommuteCo2eKg).toBeNull();
  });

  it('returns aggregate totals after the minimum opt-in threshold is met', async () => {
    const { db } = createDb({
      consented_citizens: '5',
      registered_devices: '9',
      estimated_energy_kwh: '12.5',
    });

    const response = await AdminService.getKpis(db);

    expect(response.kpis.householdAnalytics).toEqual({
      consentedCitizens: 5,
      registeredDevices: 9,
      estimatedEnergyKwh: 12.5,
      utilityReadings: 12,
      runtimeLogs: 8,
      confirmedTrips: 6,
    });
    expect(response.kpis.utilityUsage).toEqual([
      {
        utility: 'ELECTRICITY',
        district: 'Ahmedabad',
        ward: 'Ward 1',
        unit: 'kWh',
        period: '2026-10',
        averageValue: 80.2,
        contributors: 6,
      },
    ]);
    expect(response.kpis.estimatedCommuteCo2eKg).toBe(24.8);
    expect(response.kpis.estimatedImpactByArea).toEqual([
      {
        district: 'Ahmedabad',
        ward: 'Ward 1',
        estimatedCo2eKg: 24.8,
        contributors: 6,
      },
    ]);
    expect(response.kpis.providerSubscribers).toEqual({ 'power-a': 6 });
  });
});
