import { Type, type Static } from '@sinclair/typebox';

export const ProviderCategorySchema = Type.Union([
  Type.Literal('ELECTRICITY'),
  Type.Literal('GAS'),
  Type.Literal('WATER'),
  Type.Literal('TRANSIT'),
]);

export type ProviderCategory = Static<typeof ProviderCategorySchema>;

export const UtilityProviderSchema = Type.Object({
  id: Type.String({ description: 'Unique provider identifier slug' }),
  name: Type.String({ description: 'Display title of the utility organization' }),
  category: ProviderCategorySchema,
  districts: Type.Array(Type.String(), { description: 'Gujarat districts served by this provider' }),
  code: Type.String({ description: 'Official short code' }),
  contactPhone: Type.String(),
  peakHours: Type.Optional(Type.String({ description: 'Peak demand window for electricity' })),
  supplyWindow: Type.Optional(Type.String({ description: 'Scheduled supply hours for water' })),
  activeAlertCount: Type.Number({ default: 0 }),
});

export type UtilityProvider = Static<typeof UtilityProviderSchema>;

export const ListProvidersQuerySchema = Type.Object({
  category: Type.Optional(ProviderCategorySchema),
  district: Type.Optional(Type.String({ description: 'Filter providers serving this Gujarat district' })),
});

export type ListProvidersQuery = Static<typeof ListProvidersQuerySchema>;

export const ListProvidersResponseSchema = Type.Object({
  success: Type.Boolean(),
  providers: Type.Array(UtilityProviderSchema),
  totalCount: Type.Number(),
});

export type ListProvidersResponse = Static<typeof ListProvidersResponseSchema>;

// Link Citizen Providers
export const LinkProvidersBodySchema = Type.Object({
  electricityProviderId: Type.Optional(Type.String()),
  gasProviderId: Type.Optional(Type.String()),
  waterProviderId: Type.Optional(Type.String()),
  transitProviderIds: Type.Optional(Type.Array(Type.String())),
  consumerNumbers: Type.Optional(
    Type.Record(Type.String(), Type.String(), {
      description: 'Optional consumer/connection numbers for electricity, gas or water',
    })
  ),
});

export type LinkProvidersBody = Static<typeof LinkProvidersBodySchema>;

export const CitizenProviderLinksSchema = Type.Object({
  userId: Type.String(),
  electricityProvider: Type.Union([UtilityProviderSchema, Type.Null()]),
  gasProvider: Type.Union([UtilityProviderSchema, Type.Null()]),
  waterProvider: Type.Union([UtilityProviderSchema, Type.Null()]),
  transitProviders: Type.Array(UtilityProviderSchema),
  consumerNumbers: Type.Record(Type.String(), Type.String()),
  linkedAt: Type.String(),
});

export type CitizenProviderLinks = Static<typeof CitizenProviderLinksSchema>;

export const MyProvidersResponseSchema = Type.Object({
  success: Type.Boolean(),
  links: CitizenProviderLinksSchema,
});

export type MyProvidersResponse = Static<typeof MyProvidersResponseSchema>;

// Provider Broadcast Alert
export const ProviderBroadcastBodySchema = Type.Object({
  title: Type.String({ minLength: 3, maxLength: 120 }),
  message: Type.String({ minLength: 5, maxLength: 500 }),
  category: Type.Optional(Type.Union([Type.Literal('ALERT'), Type.Literal('COMMUNITY'), Type.Literal('HABIT')])),
  targetDistrict: Type.Optional(Type.String({ description: 'Restrict notification to this district' })),
  incentiveCoins: Type.Optional(Type.Number({ minimum: 0, maximum: 100 })),
  urgency: Type.Optional(Type.Union([Type.Literal('LOW'), Type.Literal('MEDIUM'), Type.Literal('HIGH')])),
});

export type ProviderBroadcastBody = Static<typeof ProviderBroadcastBodySchema>;

export const ProviderBroadcastResponseSchema = Type.Object({
  success: Type.Boolean(),
  notificationId: Type.String(),
  dispatchedToCount: Type.Number(),
  message: Type.String(),
});

export type ProviderBroadcastResponse = Static<typeof ProviderBroadcastResponseSchema>;
