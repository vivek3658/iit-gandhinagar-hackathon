import { Type, type Static } from '@sinclair/typebox';

export const ActivityCategorySchema = Type.Union([
  Type.Literal('ALL'),
  Type.Literal('HABIT'),
  Type.Literal('SANCTUARY'),
  Type.Literal('COMMUNITY'),
  Type.Literal('ALERT'),
]);

export type ActivityCategory = Static<typeof ActivityCategorySchema>;

export const ActivityItemSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  userId: Type.Union([Type.String({ format: 'uuid' }), Type.Null()]), // null for broadcast/community
  category: ActivityCategorySchema,
  title: Type.String(),
  message: Type.String(),
  icon: Type.String(), // emoji or icon key e.g. 'leaf', 'solar', 'bird', 'spark'
  coinsEarned: Type.Optional(Type.Number()),
  co2SavedKg: Type.Optional(Type.Number()),
  district: Type.Optional(Type.String()),
  isRead: Type.Boolean(),
  createdAt: Type.String(),
});

export type ActivityItem = Static<typeof ActivityItemSchema>;

export const GetActivityQuerySchema = Type.Object({
  category: Type.Optional(ActivityCategorySchema),
  page: Type.Optional(Type.Number({ minimum: 1, default: 1 })),
  limit: Type.Optional(Type.Number({ minimum: 1, maximum: 50, default: 20 })),
});

export type GetActivityQuery = Static<typeof GetActivityQuerySchema>;

export const ActivityFeedResponseSchema = Type.Object({
  activities: Type.Array(ActivityItemSchema),
  totalCount: Type.Number(),
  unreadCount: Type.Number(),
  page: Type.Number(),
  limit: Type.Number(),
});

export type ActivityFeedResponse = Static<typeof ActivityFeedResponseSchema>;

export const MarkReadParamsSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
});

export type MarkReadParams = Static<typeof MarkReadParamsSchema>;

export const MarkReadResponseSchema = Type.Object({
  success: Type.Boolean(),
  unreadCount: Type.Number(),
});

export type MarkReadResponse = Static<typeof MarkReadResponseSchema>;

// Route Schemas for OpenAPI/Swagger
export const GetActivityRouteSchema = {
  description: 'Fetches paginated activity updates, habit completions, sanctuary upgrades, and Gujarat community eco-events.',
  tags: ['Activity'],
  security: [{ bearerAuth: [] }],
  querystring: GetActivityQuerySchema,
  response: {
    200: ActivityFeedResponseSchema,
  },
};

export const MarkReadRouteSchema = {
  description: 'Marks an activity item as read.',
  tags: ['Activity'],
  security: [{ bearerAuth: [] }],
  params: MarkReadParamsSchema,
  response: {
    200: MarkReadResponseSchema,
  },
};

export const MarkAllReadRouteSchema = {
  description: 'Marks all activity notifications as read for current citizen.',
  tags: ['Activity'],
  security: [{ bearerAuth: [] }],
  response: {
    200: MarkReadResponseSchema,
  },
};
