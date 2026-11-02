import { Type, type Static } from '@sinclair/typebox';

export const WasteTypeSchema = Type.Union([
  Type.Literal('ORGANIC'),
  Type.Literal('DRY_RECYCLABLE'),
  Type.Literal('RESIDUAL'),
  Type.Literal('SPECIAL_HANDLING'),
]);

export const WasteScheduleWriteSchema = Type.Object({
  district: Type.String({ minLength: 2, maxLength: 64 }),
  ward: Type.String({ minLength: 1, maxLength: 64 }),
  wasteType: WasteTypeSchema,
  pickupWeekdays: Type.Array(Type.Integer({ minimum: 0, maximum: 6 }), { minItems: 1, maxItems: 7 }),
  collectionWindow: Type.String({ minLength: 3, maxLength: 80 }),
  effectiveFrom: Type.String({ format: 'date' }),
  effectiveTo: Type.Union([Type.String({ format: 'date' }), Type.Null()]),
  notes: Type.Optional(Type.String({ maxLength: 500 })),
  isActive: Type.Optional(Type.Boolean()),
  reason: Type.String({ minLength: 5, maxLength: 240 }),
});

export type WasteScheduleWrite = Static<typeof WasteScheduleWriteSchema>;

export const WasteScheduleSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  tenantId: Type.String(),
  district: Type.String(),
  ward: Type.String(),
  wasteType: WasteTypeSchema,
  pickupWeekdays: Type.Array(Type.Integer({ minimum: 0, maximum: 6 })),
  collectionWindow: Type.String(),
  effectiveFrom: Type.String({ format: 'date' }),
  effectiveTo: Type.Union([Type.String({ format: 'date' }), Type.Null()]),
  notes: Type.Union([Type.String(), Type.Null()]),
  isActive: Type.Boolean(),
  updatedAt: Type.String({ format: 'date-time' }),
});

export const WasteScheduleListSchema = Type.Object({
  schedules: Type.Array(WasteScheduleSchema),
  asOfDate: Type.String({ format: 'date' }),
});

export const WasteScheduleQuerySchema = Type.Object({
  district: Type.String({ minLength: 2, maxLength: 64 }),
  ward: Type.Optional(Type.String({ minLength: 1, maxLength: 64 })),
  date: Type.Optional(Type.String({ format: 'date' })),
});

export type WasteScheduleQuery = Static<typeof WasteScheduleQuerySchema>;

export const WasteScheduleParamsSchema = Type.Object({
  scheduleId: Type.String({ format: 'uuid' }),
});
