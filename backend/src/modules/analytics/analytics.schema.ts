import { Type, type Static } from '@sinclair/typebox';

export const HourlyLoadPointSchema = Type.Object({
  hour: Type.Number({ minimum: 0, maximum: 23 }),
  timeLabel: Type.String(), // '06:00', '18:00'
  loadKw: Type.Number(),
  solarGenKw: Type.Number(),
  gridNetKw: Type.Number(),
  isPeakHour: Type.Boolean(),
});

export const ApplianceShareSchema = Type.Object({
  applianceName: Type.String(),
  category: Type.String(),
  kwhPerMonth: Type.Number(),
  percentShare: Type.Number(),
  icon: Type.String(),
  rating: Type.String(),
});

export const MonthlyTrendPointSchema = Type.Object({
  month: Type.String(),
  consumptionKwh: Type.Number(),
  billRupees: Type.Number(),
  solarOffsetPercent: Type.Number(),
  co2eAvoidedKg: Type.Number(),
});

export const CarbonLedgerDomainSchema = Type.Object({
  domain: Type.String(),
  kgCo2e: Type.Number(),
  percent: Type.Number(),
  icon: Type.String(),
});

export const AnalyticsDashboardResponseSchema = Type.Object({
  realTimeMetrics: Type.Object({
    activePowerKw: Type.Number(),
    todayKwh: Type.Number(),
    todaySolarKwh: Type.Number(),
    todayCo2AvoidedKg: Type.Number(),
    peakDemandKw: Type.Number(),
  }),
  hourlyLoadCurve: Type.Array(HourlyLoadPointSchema),
  applianceBreakdown: Type.Array(ApplianceShareSchema),
  monthlyTrends: Type.Array(MonthlyTrendPointSchema),
  carbonLedger: Type.Array(CarbonLedgerDomainSchema),
  gridTariffInsights: Type.Object({
    discomName: Type.String(),
    peakTariffRateRupees: Type.Number(),
    offPeakTariffRateRupees: Type.Number(),
    solarFeedInTariffRupees: Type.Number(),
    recommendation: Type.String(),
  }),
});

export type AnalyticsDashboardResponse = Static<typeof AnalyticsDashboardResponseSchema>;
