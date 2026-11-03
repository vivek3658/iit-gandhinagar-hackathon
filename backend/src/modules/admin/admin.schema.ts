import { Type, type Static } from '@sinclair/typebox';

export const AdminKpisResponseSchema = Type.Object({
  success: Type.Boolean(),
  dataAsOf: Type.String({ format: 'date-time' }),
  kpis: Type.Object({
    totalRegisteredCitizens: Type.Number(),
    activeSanctuariesCount: Type.Union([Type.Number(), Type.Null()]),
    totalCo2eSavedKg: Type.Union([Type.Number(), Type.Null()]),
    totalPeakMwhShifted: Type.Union([Type.Number(), Type.Null()]),
    totalCoinsInCirculation: Type.Number(),
    districtBreakdown: Type.Record(Type.String(), Type.Number()),
    wardBreakdown: Type.Array(
      Type.Object({
        district: Type.String(),
        ward: Type.String(),
        citizenCount: Type.Number(),
      }),
    ),
    utilityUsage: Type.Array(
      Type.Object({
        utility: Type.Union([
          Type.Literal('ELECTRICITY'),
          Type.Literal('WATER'),
          Type.Literal('GAS'),
        ]),
        district: Type.String(),
        ward: Type.String(),
        unit: Type.String(),
        period: Type.String(),
        averageValue: Type.Number(),
        contributors: Type.Number(),
      }),
    ),
    estimatedCommuteCo2eKg: Type.Union([Type.Number(), Type.Null()]),
    estimatedImpactByArea: Type.Array(
      Type.Object({
        district: Type.String(),
        ward: Type.String(),
        estimatedCo2eKg: Type.Number(),
        contributors: Type.Number(),
      }),
    ),
    providerSubscribers: Type.Union([Type.Record(Type.String(), Type.Number()), Type.Null()]),
    householdAnalytics: Type.Object({
      consentedCitizens: Type.Union([Type.Number(), Type.Null()]),
      registeredDevices: Type.Union([Type.Number(), Type.Null()]),
      estimatedEnergyKwh: Type.Union([Type.Number(), Type.Null()]),
      utilityReadings: Type.Union([Type.Number(), Type.Null()]),
      runtimeLogs: Type.Union([Type.Number(), Type.Null()]),
      confirmedTrips: Type.Union([Type.Number(), Type.Null()]),
    }),
  }),
  unavailableMetrics: Type.Array(Type.String()),
});

export type AdminKpisResponse = Static<typeof AdminKpisResponseSchema>;

export const AdminBroadcastAlertBodySchema = Type.Object({
  title: Type.String({ minLength: 3, maxLength: 120 }),
  message: Type.String({ minLength: 5, maxLength: 500 }),
  category: Type.Optional(
    Type.Union([Type.Literal('ALERT'), Type.Literal('COMMUNITY'), Type.Literal('HABIT')]),
  ),
  targetDistrict: Type.Optional(
    Type.String({ description: 'Specific Gujarat district or null for state-wide' }),
  ),
  targetWard: Type.Optional(
    Type.String({
      minLength: 2,
      maxLength: 64,
      description: 'Optional ward within the selected district',
    }),
  ),
  targetProviderId: Type.Optional(
    Type.String({ description: 'Specific utility provider or null for all' }),
  ),
  targetUserId: Type.Optional(Type.String({ description: 'Specific citizen ID to remind' })),
  targetUserEmail: Type.Optional(Type.String({ description: 'Specific citizen email to remind' })),
  incentiveCoins: Type.Optional(Type.Number({ minimum: 0, maximum: 100 })),
  urgency: Type.Optional(
    Type.Union([Type.Literal('LOW'), Type.Literal('MEDIUM'), Type.Literal('HIGH')]),
  ),
  reason: Type.Optional(Type.String({ minLength: 5, maxLength: 240 })),
  scheduledAt: Type.Optional(Type.String({ format: 'date-time' })),
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
  subscribersCount: Type.Union([Type.Number(), Type.Null()]),
  status: Type.String(),
});

export const AdminProvidersListResponseSchema = Type.Object({
  success: Type.Boolean(),
  providers: Type.Array(AdminProviderItemSchema),
  totalProviders: Type.Number(),
});

export type AdminProvidersListResponse = Static<typeof AdminProvidersListResponseSchema>;

export const AdminLoginBodySchema = Type.Object(
  {
    username: Type.Optional(Type.String({ minLength: 3, maxLength: 254 })),
    email: Type.Optional(Type.String({ format: 'email', maxLength: 254 })),
    password: Type.String({ minLength: 1, maxLength: 256 }),
  },
  { minProperties: 2 },
);

export const AdminLoginResponseSchema = Type.Object({
  accessToken: Type.String(),
  tokenType: Type.Literal('Bearer'),
  expiresInSeconds: Type.Integer(),
  role: Type.Union([
    Type.Literal('ADMIN'),
    Type.Literal('PROVIDER_ADMIN'),
    Type.Literal('CITY_ADMIN'),
  ]),
  tenantId: Type.Optional(Type.String()),
  tenantType: Type.Optional(Type.Union([Type.Literal('PROVIDER'), Type.Literal('CITY')])),
});

export const CreateTenantAdminBodySchema = Type.Object({
  email: Type.String({ format: 'email', maxLength: 254 }),
  password: Type.String({ minLength: 12, maxLength: 256 }),
  displayName: Type.String({ minLength: 2, maxLength: 100 }),
  tenantType: Type.Union([Type.Literal('PROVIDER'), Type.Literal('CITY')]),
  tenantId: Type.String({ minLength: 2, maxLength: 100, pattern: '^[a-z0-9][a-z0-9_-]*$' }),
  districts: Type.Array(Type.String({ minLength: 2, maxLength: 64 }), {
    minItems: 1,
    maxItems: 30,
  }),
});

export type CreateTenantAdminBody = Static<typeof CreateTenantAdminBodySchema>;

export const TenantAdminResponseSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  email: Type.String(),
  displayName: Type.String(),
  tenantType: Type.Union([Type.Literal('PROVIDER'), Type.Literal('CITY')]),
  tenantId: Type.String(),
  districts: Type.Array(Type.String()),
  createdAt: Type.String({ format: 'date-time' }),
});

export const TenantAdminListResponseSchema = Type.Object({
  admins: Type.Array(TenantAdminResponseSchema),
});

export const TenantIdentityResponseSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  email: Type.String(),
  displayName: Type.String(),
  tenantType: Type.Union([Type.Literal('PROVIDER'), Type.Literal('CITY')]),
  tenantId: Type.String(),
  districts: Type.Array(Type.String()),
  role: Type.Union([Type.Literal('PROVIDER_ADMIN'), Type.Literal('CITY_ADMIN')]),
});

export const TenantOverviewResponseSchema = Type.Object({
  tenantType: Type.Union([Type.Literal('PROVIDER'), Type.Literal('CITY')]),
  tenantId: Type.String(),
  scopeLabel: Type.String(),
  activeCitizens: Type.Number(),
  campaignOptIns: Type.Number(),
  wasteReminderOptIns: Type.Number(),
  dataAsOf: Type.String({ format: 'date-time' }),
});

export const TenantAdminParamsSchema = Type.Object({
  adminId: Type.String({ format: 'uuid' }),
});

export const AdminAuditItemSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  actorEmail: Type.String(),
  tenantType: Type.Union([
    Type.Literal('PLATFORM'),
    Type.Literal('PROVIDER'),
    Type.Literal('CITY'),
  ]),
  tenantId: Type.Union([Type.String(), Type.Null()]),
  action: Type.String(),
  resourceType: Type.String(),
  resourceId: Type.Union([Type.String(), Type.Null()]),
  reason: Type.Union([Type.String(), Type.Null()]),
  createdAt: Type.String({ format: 'date-time' }),
});

export const AdminAuditResponseSchema = Type.Object({
  items: Type.Array(AdminAuditItemSchema),
});

export const AdminErrorResponseSchema = Type.Object({
  statusCode: Type.Integer(),
  error: Type.String(),
  message: Type.String(),
});
