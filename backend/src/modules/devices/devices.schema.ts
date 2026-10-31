import { Type, type Static } from '@sinclair/typebox';

export const LogHoursBodySchema = Type.Object({
  deviceCatalogId: Type.String(),
  operatingHours: Type.Number({ minimum: 0.1, maximum: 24 }),
  thermostatTemp: Type.Optional(Type.Number({ minimum: 16, maximum: 30 })),
  date: Type.Optional(Type.String()),
});

export type LogHoursBody = Static<typeof LogHoursBodySchema>;

export const HighUsageAlertSchema = Type.Object({
  triggered: Type.Boolean(),
  alertTitle: Type.String(),
  alertMessage: Type.String(),
  excessHours: Type.Number(),
  potentialSavingsRupeesMonthly: Type.Number(),
  potentialCo2ReductionKgMonthly: Type.Number(),
  recommendation: Type.String(),
});

export const DeviceTimeLogResponseSchema = Type.Object({
  loggedDevice: Type.Object({
    deviceId: Type.String(),
    deviceName: Type.String(),
    icon: Type.String(),
    operatingHours: Type.Number(),
    ratedPowerKw: Type.Number(),
    energyConsumedKwh: Type.Number(),
    co2EmissionsKg: Type.Number(),
  }),
  highUsageAlert: Type.Union([HighUsageAlertSchema, Type.Null()]),
  totalDailyEnergyKwh: Type.Number(),
});

export type DeviceTimeLogResponse = Static<typeof DeviceTimeLogResponseSchema>;

export const DeviceSummaryItemSchema = Type.Object({
  deviceId: Type.String(),
  name: Type.String(),
  category: Type.String(),
  icon: Type.String(),
  ratedPowerKw: Type.Number(),
  totalWeeklyHours: Type.Number(),
  avgDailyHours: Type.Number(),
  status: Type.Union([Type.Literal('OPTIMAL'), Type.Literal('MODERATE'), Type.Literal('HIGH_USAGE')]),
  recommendation: Type.String(),
});

export const DeviceSummaryResponseSchema = Type.Object({
  devices: Type.Array(DeviceSummaryItemSchema),
  highHourWarnings: Type.Array(Type.String()),
  monthlyProjectedBillRupees: Type.Number(),
});

export type DeviceSummaryResponse = Static<typeof DeviceSummaryResponseSchema>;
