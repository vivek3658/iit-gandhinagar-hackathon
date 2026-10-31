import { Type, type Static } from '@sinclair/typebox';

export const CookingFuelTypeSchema = Type.Union([
  Type.Literal('LPG_CYLINDER'),
  Type.Literal('PNG_PIPED'),
  Type.Literal('ELECTRIC_INDUCTION'),
]);

export const CommuteModeSchema = Type.Union([
  Type.Literal('EV_2WHEELER'),
  Type.Literal('EV_CAR'),
  Type.Literal('PETROL_2WHEELER'),
  Type.Literal('PETROL_CAR'),
  Type.Literal('DIESEL_CAR'),
  Type.Literal('PUBLIC_BUS_METRO'),
  Type.Literal('BICYCLE_WALK'),
]);

export const DietTypeSchema = Type.Union([
  Type.Literal('VEGETARIAN'),
  Type.Literal('VEGAN'),
  Type.Literal('NON_VEGETARIAN'),
]);

export const EstimateCarbonBodySchema = Type.Object({
  monthlyElectricityUnitsKwh: Type.Optional(Type.Number({ minimum: 0, maximum: 5000 })),
  monthlyElectricityBillRupees: Type.Optional(Type.Number({ minimum: 0, maximum: 50000 })),
  cookingFuelType: CookingFuelTypeSchema,
  cookingMonthlyQuantity: Type.Number({ minimum: 0, maximum: 50 }), // cylinders or SCM
  dailyCommuteKm: Type.Number({ minimum: 0, maximum: 200 }),
  commuteMode: CommuteModeSchema,
  dietType: Type.Optional(DietTypeSchema),
});

export type EstimateCarbonBody = Static<typeof EstimateCarbonBodySchema>;

export const CarbonActionPlanItemSchema = Type.Object({
  title: Type.String(),
  description: Type.String(),
  annualSavingsRupees: Type.Number(),
  annualCo2ReductionKg: Type.Number(),
  difficulty: Type.Union([Type.Literal('EASY'), Type.Literal('MODERATE'), Type.Literal('HIGH_IMPACT')]),
  icon: Type.String(),
});

export const EstimateCarbonResponseSchema = Type.Object({
  totalYearlyKgCO2e: Type.Number(),
  totalMonthlyKgCO2e: Type.Number(),
  breakdown: Type.Object({
    electricityKgCO2e: Type.Number(),
    cookingKgCO2e: Type.Number(),
    commuteKgCO2e: Type.Number(),
    dietWasteKgCO2e: Type.Number(),
  }),
  percentages: Type.Object({
    electricity: Type.Number(),
    cooking: Type.Number(),
    commute: Type.Number(),
    dietWaste: Type.Number(),
  }),
  benchmarks: Type.Object({
    gujaratAverageKgCO2e: Type.Number(),
    indiaAverageKgCO2e: Type.Number(),
    globalAverageKgCO2e: Type.Number(),
    percentileVsGujarat: Type.Number(), // e.g. 72 means cleaner than 72% of Gujarat homes
    rating: Type.String(), // 'Eco Guardian', 'Conscious Citizen', 'High Energy Footprint'
  }),
  actionPlan: Type.Array(CarbonActionPlanItemSchema),
});

export type EstimateCarbonResponse = Static<typeof EstimateCarbonResponseSchema>;
