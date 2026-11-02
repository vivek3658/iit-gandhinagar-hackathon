import { Type, type Static } from '@sinclair/typebox';
import { UtilityReadingSchema } from '../citizen-data/citizen-data.schema';

const UnavailableNumberSchema = Type.Union([Type.Number(), Type.Null()]);

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
  dataAvailability: Type.Object({
    utilityReadings: Type.Boolean(),
    liveMeterTelemetry: Type.Boolean(),
    solarGeneration: Type.Boolean(),
    emissions: Type.Boolean(),
    tariff: Type.Boolean(),
  }),
  realTimeMetrics: Type.Object({
    activePowerKw: UnavailableNumberSchema,
    todayKwh: UnavailableNumberSchema,
    todaySolarKwh: UnavailableNumberSchema,
    todayCo2AvoidedKg: UnavailableNumberSchema,
    peakDemandKw: UnavailableNumberSchema,
  }),
  hourlyLoadCurve: Type.Array(HourlyLoadPointSchema),
  applianceBreakdown: Type.Array(ApplianceShareSchema),
  monthlyTrends: Type.Array(MonthlyTrendPointSchema),
  carbonLedger: Type.Array(CarbonLedgerDomainSchema),
  gridTariffInsights: Type.Object({
    discomName: Type.Union([Type.String(), Type.Null()]),
    peakTariffRateRupees: UnavailableNumberSchema,
    offPeakTariffRateRupees: UnavailableNumberSchema,
    solarFeedInTariffRupees: UnavailableNumberSchema,
    recommendation: Type.Union([Type.String(), Type.Null()]),
  }),
  utilityReadings: Type.Array(UtilityReadingSchema),
});

export type AnalyticsDashboardResponse = Static<typeof AnalyticsDashboardResponseSchema>;
