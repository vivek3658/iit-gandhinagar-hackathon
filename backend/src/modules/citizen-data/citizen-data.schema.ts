import { Type, type Static } from '@sinclair/typebox';

export const UtilityTypeSchema = Type.Union([
  Type.Literal('ELECTRICITY'),
  Type.Literal('WATER'),
  Type.Literal('GAS'),
]);

export const UtilityReadingBodySchema = Type.Object({
  utility: UtilityTypeSchema,
  value: Type.Number({ exclusiveMinimum: 0 }),
  unit: Type.String({ minLength: 1, maxLength: 16 }),
  periodStart: Type.String({ format: 'date' }),
  periodEnd: Type.String({ format: 'date' }),
  providerId: Type.Optional(Type.String({ maxLength: 80 })),
  sourceReference: Type.Optional(Type.String({ maxLength: 120 })),
});

export type UtilityReadingBody = Static<typeof UtilityReadingBodySchema>;

export const UtilityReadingSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  utility: UtilityTypeSchema,
  value: Type.Number(),
  unit: Type.String(),
  periodStart: Type.String({ format: 'date' }),
  periodEnd: Type.String({ format: 'date' }),
  providerId: Type.Union([Type.String(), Type.Null()]),
  sourceReference: Type.Union([Type.String(), Type.Null()]),
  evidenceTier: Type.Literal('USER_ENTERED'),
  createdAt: Type.String({ format: 'date-time' }),
});

export const UtilityReadingsResponseSchema = Type.Object({
  readings: Type.Array(UtilityReadingSchema),
});

export const VehicleBodySchema = Type.Object({
  label: Type.String({ minLength: 1, maxLength: 80 }),
  vehicleType: Type.Union([
    Type.Literal('TWO_WHEELER'),
    Type.Literal('CAR'),
    Type.Literal('BUS'),
    Type.Literal('OTHER'),
  ]),
  fuelType: Type.Union([
    Type.Literal('PETROL'),
    Type.Literal('DIESEL'),
    Type.Literal('CNG'),
    Type.Literal('ELECTRIC'),
    Type.Literal('HYBRID'),
    Type.Literal('OTHER'),
  ]),
  make: Type.Optional(Type.String({ maxLength: 80 })),
  model: Type.Optional(Type.String({ maxLength: 80 })),
  modelYear: Type.Optional(Type.Integer({ minimum: 1900, maximum: 2100 })),
  efficiency: Type.Optional(Type.Number({ exclusiveMinimum: 0, maximum: 1000 })),
  efficiencyUnit: Type.Optional(Type.String({ maxLength: 24 })),
  registrationLabel: Type.Optional(Type.String({ maxLength: 24 })),
});

export type VehicleBody = Static<typeof VehicleBodySchema>;

export const VehicleSchema = Type.Intersect([
  VehicleBodySchema,
  Type.Object({
    id: Type.String({ format: 'uuid' }),
    createdAt: Type.String({ format: 'date-time' }),
    updatedAt: Type.String({ format: 'date-time' }),
  }),
]);

export const VehiclesResponseSchema = Type.Object({
  vehicles: Type.Array(VehicleSchema),
});

export const TripBodySchema = Type.Object({
  idempotencyKey: Type.String({ minLength: 8, maxLength: 128 }),
  mode: Type.Union([
    Type.Literal('WALK'),
    Type.Literal('BICYCLE'),
    Type.Literal('PUBLIC_TRANSIT'),
    Type.Literal('PRIVATE_VEHICLE'),
    Type.Literal('OTHER'),
  ]),
  distanceKm: Type.Number({ exclusiveMinimum: 0, maximum: 2000 }),
  startedAt: Type.String({ format: 'date-time' }),
  endedAt: Type.String({ format: 'date-time' }),
  vehicleId: Type.Optional(Type.String({ format: 'uuid' })),
  userConfirmed: Type.Literal(true),
  notes: Type.Optional(Type.String({ maxLength: 500 })),
});

export type TripBody = Static<typeof TripBodySchema>;

export const TripSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  mode: TripBodySchema.properties.mode,
  distanceKm: Type.Number(),
  startedAt: Type.String({ format: 'date-time' }),
  endedAt: Type.String({ format: 'date-time' }),
  vehicleId: Type.Union([Type.String({ format: 'uuid' }), Type.Null()]),
  evidenceTier: Type.Literal('USER_CONFIRMED_SUMMARY'),
  co2eKg: Type.Null(),
  createdAt: Type.String({ format: 'date-time' }),
});

export const TripsResponseSchema = Type.Object({
  trips: Type.Array(TripSchema),
});

export type UtilityReading = Static<typeof UtilityReadingSchema>;
export type Vehicle = Static<typeof VehicleSchema>;
export type Trip = Static<typeof TripSchema>;
