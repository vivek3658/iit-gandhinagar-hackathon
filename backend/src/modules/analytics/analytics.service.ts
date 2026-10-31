import type { AnalyticsDashboardResponse } from './analytics.schema';

export class AnalyticsService {
  private static instance: AnalyticsService;

  public static getInstance(): AnalyticsService {
    if (!AnalyticsService.instance) {
      AnalyticsService.instance = new AnalyticsService();
    }
    return AnalyticsService.instance;
  }

  public getDashboardAnalytics(district = 'Ahmedabad'): AnalyticsDashboardResponse {
    // 24-Hour Engineered Load Curve
    // Peak hours in Gujarat: 18:00 to 22:00 (Evening peak) & 07:00 to 10:00 (Morning prep)
    // Solar generation curve: bell curve peaking at 12:30 PM (2.8 kW on 3 kW solar PV)
    const hourlyLoadCurve = [];
    for (let h = 0; h < 24; h++) {
      const isPeak = (h >= 18 && h <= 22) || (h >= 8 && h <= 10);
      let loadKw = 0.45; // baseline standby refrigerator & routers

      if (h >= 1 && h <= 5) {
        loadKw = 1.2; // AC nighttime cycle (thermostat at 24°C)
      } else if (h >= 6 && h <= 9) {
        loadKw = 2.1; // Geyser, kitchen induction, pumps
      } else if (h >= 10 && h <= 16) {
        loadKw = 1.1; // Daytime fans, refrigerator, daytime appliances
      } else if (h >= 17 && h <= 23) {
        loadKw = 2.6; // Evening AC, lighting, television, cooking
      }

      // Solar generation window 07:00 to 17:00
      let solarGenKw = 0.0;
      if (h >= 7 && h <= 17) {
        const solarPhase = (h - 7) / 10; // 0 to 1
        solarGenKw = Math.round(Math.sin(solarPhase * Math.PI) * 2.8 * 100) / 100;
      }

      const gridNetKw = Math.round((loadKw - solarGenKw) * 100) / 100;

      hourlyLoadCurve.push({
        hour: h,
        timeLabel: `${h.toString().padStart(2, '0')}:00`,
        loadKw,
        solarGenKw,
        gridNetKw,
        isPeakHour: isPeak,
      });
    }

    const applianceBreakdown = [
      {
        applianceName: 'Dual Inverter Split AC',
        category: 'Cooling',
        kwhPerMonth: 142.5,
        percentShare: 45,
        icon: '❄️',
        rating: '5-Star BEE',
      },
      {
        applianceName: 'Frost-Free Refrigerator',
        category: 'Refrigeration',
        kwhPerMonth: 68.2,
        percentShare: 21,
        icon: '🧊',
        rating: '4-Star BEE',
      },
      {
        applianceName: 'Instant Water Geyser',
        category: 'Water Heating',
        kwhPerMonth: 38.0,
        percentShare: 12,
        icon: '🚿',
        rating: '3-Star BEE',
      },
      {
        applianceName: 'Submersible Water Sump Pump',
        category: 'Pumping',
        kwhPerMonth: 28.5,
        percentShare: 9,
        icon: '💧',
        rating: 'ISI Certified',
      },
      {
        applianceName: 'LED Lighting & Smart Ceiling Fans',
        category: 'Lighting & Air',
        kwhPerMonth: 22.0,
        percentShare: 7,
        icon: '💡',
        rating: 'BLDC Motor',
      },
      {
        applianceName: 'Standby / Vampire Phantom Load',
        category: 'Standby Loss',
        kwhPerMonth: 19.0,
        percentShare: 6,
        icon: '🔌',
        rating: 'Zero Star',
      },
    ];

    const monthlyTrends = [
      {
        month: 'May 2026',
        consumptionKwh: 385,
        billRupees: 2680,
        solarOffsetPercent: 72,
        co2eAvoidedKg: 226.5,
      },
      {
        month: 'Jun 2026',
        consumptionKwh: 410,
        billRupees: 2890,
        solarOffsetPercent: 68,
        co2eAvoidedKg: 228.4,
      },
      {
        month: 'Jul 2026',
        consumptionKwh: 340,
        billRupees: 2320,
        solarOffsetPercent: 61,
        co2eAvoidedKg: 170.2,
      },
      {
        month: 'Aug 2026',
        consumptionKwh: 320,
        billRupees: 2190,
        solarOffsetPercent: 64,
        co2eAvoidedKg: 168.0,
      },
      {
        month: 'Sep 2026',
        consumptionKwh: 295,
        billRupees: 1980,
        solarOffsetPercent: 75,
        co2eAvoidedKg: 181.4,
      },
      {
        month: 'Oct 2026',
        consumptionKwh: 275,
        billRupees: 1840,
        solarOffsetPercent: 82,
        co2eAvoidedKg: 185.3,
      },
    ];

    const carbonLedger = [
      {
        domain: 'Grid Electricity',
        kgCo2e: 184.2,
        percent: 54,
        icon: '⚡',
      },
      {
        domain: 'Daily Urban Commute',
        kgCo2e: 88.5,
        percent: 26,
        icon: '🛵',
      },
      {
        domain: 'Clean Cooking Gas (PNG)',
        kgCo2e: 45.0,
        percent: 13,
        icon: '🥘',
      },
      {
        domain: 'Municipal Water & Sump',
        kgCo2e: 24.1,
        percent: 7,
        icon: '💧',
      },
    ];

    return {
      realTimeMetrics: {
        activePowerKw: 1.35,
        todayKwh: 9.8,
        todaySolarKwh: 12.4,
        todayCo2AvoidedKg: 10.1,
        peakDemandKw: 2.8,
      },
      hourlyLoadCurve,
      applianceBreakdown,
      monthlyTrends,
      carbonLedger,
      gridTariffInsights: {
        discomName: district === 'Ahmedabad' || district === 'Surat' ? 'Torrent Power Ltd' : 'UGVCL / DGVCL',
        peakTariffRateRupees: 7.85,
        offPeakTariffRateRupees: 4.9,
        solarFeedInTariffRupees: 2.25,
        recommendation:
          'Shift washing machine and EV charging loads between 11:00 AM and 3:00 PM to absorb 100% free rooftop solar generation!',
      },
    };
  }
}
