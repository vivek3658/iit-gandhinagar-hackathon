import { Type, type Static } from '@sinclair/typebox';

export const AdminKpisResponseSchema = Type.Object({
  success: Type.Boolean(),
  kpis: Type.Object({
    totalRegisteredCitizens: Type.Number(),
    activeSanctuariesCount: Type.Number(),
    totalCo2eSavedKg: Type.Number(),
    totalPeakMwhShifted: Type.Number(),
    totalCoinsInCirculation: Type.Number(),
    districtBreakdown: Type.Record(Type.String(), Type.Number()),
    providerSubscribers: Type.Record(Type.String(), Type.Number()),
    peakGridStressStatus: Type.String(),
  }),
});

export type AdminKpisResponse = Static<typeof AdminKpisResponseSchema>;

export const AdminBroadcastAlertBodySchema = Type.Object({
  title: Type.String({ minLength: 3, maxLength: 120 }),
  message: Type.String({ minLength: 5, maxLength: 500 }),
  category: Type.Optional(Type.Union([Type.Literal('ALERT'), Type.Literal('COMMUNITY'), Type.Literal('HABIT')])),
  targetDistrict: Type.Optional(Type.String({ description: 'Specific Gujarat district or null for state-wide' })),
  targetProviderId: Type.Optional(Type.String({ description: 'Specific utility provider or null for all' })),
  targetUserId: Type.Optional(Type.String({ description: 'Specific citizen ID to remind' })),
  targetUserEmail: Type.Optional(Type.String({ description: 'Specific citizen email to remind' })),
  incentiveCoins: Type.Optional(Type.Number({ minimum: 0, maximum: 100 })),
  urgency: Type.Optional(Type.Union([Type.Literal('LOW'), Type.Literal('MEDIUM'), Type.Literal('HIGH')])),
});

export type AdminBroadcastAlertBody = Static<typeof AdminBroadcastAlertBodySchema>;

export const AdminBroadcastAlertResponseSchema = Type.Object({
  success: Type.Boolean(),
  broadcastId: Type.String(),
  scope: Type.String(),
  recipientsReached: Type.Number(),
  message: Type.String(),
});

export type AdminBroadcastAlertResponse = Static<typeof AdminBroadcastAlertResponseSchema>;

export const AdminProviderItemSchema = Type.Object({
  id: Type.String(),
  name: Type.String(),
  category: Type.String(),
  districts: Type.Array(Type.String()),
  subscribersCount: Type.Number(),
  status: Type.String(),
});

export const AdminProvidersListResponseSchema = Type.Object({
  success: Type.Boolean(),
  providers: Type.Array(AdminProviderItemSchema),
  totalProviders: Type.Number(),
});

export type AdminProvidersListResponse = Static<typeof AdminProvidersListResponseSchema>;
