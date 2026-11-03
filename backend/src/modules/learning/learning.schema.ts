import { Type } from '@sinclair/typebox';

export const LearningChapterSchema = Type.Object({
  id: Type.String(),
  version: Type.Integer(),
  title: Type.String(),
  summary: Type.String(),
  content: Type.Array(Type.String({ minLength: 1, maxLength: 600 })),
  question: Type.String(),
  options: Type.Array(Type.Object({ id: Type.String(), label: Type.String() })),
  coinReward: Type.Integer(),
});

export const LearningChaptersResponseSchema = Type.Object({
  chapters: Type.Array(LearningChapterSchema),
});

export const LearningProgressResponseSchema = Type.Object({
  completions: Type.Array(
    Type.Object({
      chapterId: Type.String(),
      version: Type.Integer(),
    }),
  ),
});

export const CompleteChapterBodySchema = Type.Object({
  version: Type.Integer({ minimum: 1 }),
  answerId: Type.String({ minLength: 1, maxLength: 64 }),
});

export const CompleteChapterResponseSchema = Type.Object({
  success: Type.Boolean(),
  alreadyCompleted: Type.Boolean(),
  coinsAwarded: Type.Integer(),
  totalCoins: Type.Integer(),
  message: Type.String(),
});

export const WasteBucketSchema = Type.Union([
  Type.Literal('ORGANIC'),
  Type.Literal('DRY_RECYCLABLE'),
  Type.Literal('SPECIAL_HANDLING'),
  Type.Literal('RESIDUAL'),
]);

export const WasteItemSchema = Type.Object({
  id: Type.String(),
  label: Type.String(),
  guidance: Type.String(),
});

export const WasteGameCatalogResponseSchema = Type.Object({
  buckets: Type.Array(Type.Object({ id: WasteBucketSchema, label: Type.String() })),
  items: Type.Array(WasteItemSchema),
  rewardCoins: Type.Integer(),
  timezone: Type.Literal('UTC'),
});

export const WasteGameSubmissionSchema = Type.Object({
  idempotencyKey: Type.String({ minLength: 8, maxLength: 128 }),
  answers: Type.Array(
    Type.Object({
      itemId: Type.String({ minLength: 1, maxLength: 80 }),
      bucket: WasteBucketSchema,
    }),
    { minItems: 1, maxItems: 50 },
  ),
});

export const WasteGameResultSchema = Type.Object({
  success: Type.Boolean(),
  alreadyPlayedToday: Type.Boolean(),
  correctCount: Type.Integer(),
  itemCount: Type.Integer(),
  coinsAwarded: Type.Integer(),
  totalCoins: Type.Integer(),
  rewardDate: Type.String({ format: 'date' }),
  message: Type.String(),
});
