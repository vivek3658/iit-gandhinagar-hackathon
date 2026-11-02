import { Type, type Static } from '@sinclair/typebox';

export const NotificationPreferencesSchema = Type.Object({
  campaignsEnabled: Type.Boolean(),
  wasteRemindersEnabled: Type.Boolean(),
  updatedAt: Type.String({ format: 'date-time' }),
});

export type NotificationPreferences = Static<typeof NotificationPreferencesSchema>;

export const UpdateNotificationPreferencesBodySchema = Type.Object({
  campaignsEnabled: Type.Boolean(),
  wasteRemindersEnabled: Type.Boolean(),
});

export type UpdateNotificationPreferencesBody = Static<typeof UpdateNotificationPreferencesBodySchema>;

export const CampaignBodySchema = Type.Object({
  title: Type.String({ minLength: 3, maxLength: 120 }),
  message: Type.String({ minLength: 5, maxLength: 500 }),
  category: Type.Optional(Type.Union([
    Type.Literal('ALERT'),
    Type.Literal('COMMUNITY'),
    Type.Literal('HABIT'),
  ])),
  targetDistrict: Type.Optional(Type.String({ minLength: 2, maxLength: 64 })),
  targetProviderId: Type.Optional(Type.String({ minLength: 2, maxLength: 100 })),
  targetUserId: Type.Optional(Type.String({ format: 'uuid' })),
  targetUserEmail: Type.Optional(Type.String({ format: 'email' })),
  scheduledAt: Type.Optional(Type.String({ format: 'date-time' })),
  reason: Type.String({ minLength: 5, maxLength: 240 }),
  incentiveCoins: Type.Optional(Type.Integer({ minimum: 0, maximum: 100 })),
});

export type CampaignBody = Static<typeof CampaignBodySchema>;

export const CampaignResponseSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  message: Type.String(),
  category: Type.String(),
  tenantType: Type.String(),
  tenantId: Type.Union([Type.String(), Type.Null()]),
  targetDistrict: Type.Union([Type.String(), Type.Null()]),
  scheduledAt: Type.String({ format: 'date-time' }),
  status: Type.String(),
  recipientCount: Type.Number(),
  deliveredCount: Type.Number(),
  createdAt: Type.String({ format: 'date-time' }),
});

export const CampaignListSchema = Type.Object({
  campaigns: Type.Array(CampaignResponseSchema),
});

export const NotificationDispatchResponseSchema = Type.Object({
  processed: Type.Integer(),
  scheduledReminders: Type.Integer(),
});
