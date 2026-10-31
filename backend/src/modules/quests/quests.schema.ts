import { Type, type Static } from '@sinclair/typebox';

export const QuestCategorySchema = Type.Union([
  Type.Literal('ENERGY'),
  Type.Literal('WATER'),
  Type.Literal('COMMUTE'),
  Type.Literal('LIFESTYLE'),
]);

export const QuestTaskSchema = Type.Object({
  id: Type.String(),
  title: Type.String(),
  description: Type.String(),
  category: QuestCategorySchema,
  co2SavedKg: Type.Number(),
  coinReward: Type.Number(),
  xpReward: Type.Number(),
  isCompleted: Type.Boolean(),
  isClaimed: Type.Boolean(),
  icon: Type.String(),
});

export type QuestTask = Static<typeof QuestTaskSchema>;

export const DailyQuestsResponseSchema = Type.Object({
  streakDays: Type.Number(),
  totalCoinsEarnableToday: Type.Number(),
  totalCo2AvoidableToday: Type.Number(),
  quests: Type.Array(QuestTaskSchema),
});

export type DailyQuestsResponse = Static<typeof DailyQuestsResponseSchema>;

export const ClaimQuestResponseSchema = Type.Object({
  success: Type.Boolean(),
  coinsAwarded: Type.Number(),
  xpAwarded: Type.Number(),
  newMascotVitality: Type.Number(),
  streakDays: Type.Number(),
  message: Type.String(),
});

export type ClaimQuestResponse = Static<typeof ClaimQuestResponseSchema>;
