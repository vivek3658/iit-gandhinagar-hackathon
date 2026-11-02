import type { Pool } from 'pg';
import { CitizenDataService } from '../citizen-data/citizen-data.service';
import type { AnalyticsDashboardResponse } from './analytics.schema';

export class AnalyticsService {
  private readonly citizenData: CitizenDataService;

  public constructor(db: Pool | null, allowTestMemory: boolean) {
    this.citizenData = new CitizenDataService(db, allowTestMemory);
  }

  public async getDashboardAnalytics(userId: string): Promise<AnalyticsDashboardResponse> {
    const readings = await this.citizenData.listReadings(userId);

    return {
      dataAvailability: {
        utilityReadings: readings.length > 0,
        liveMeterTelemetry: false,
        solarGeneration: false,
        emissions: false,
        tariff: false,
      },
      realTimeMetrics: {
        activePowerKw: null,
        todayKwh: null,
        todaySolarKwh: null,
        todayCo2AvoidedKg: null,
        peakDemandKw: null,
      },
      hourlyLoadCurve: [],
      applianceBreakdown: [],
      monthlyTrends: [],
      carbonLedger: [],
      gridTariffInsights: {
        discomName: null,
        peakTariffRateRupees: null,
        offPeakTariffRateRupees: null,
        solarFeedInTariffRupees: null,
        recommendation: null,
      },
      utilityReadings: readings,
    };
  }
}
