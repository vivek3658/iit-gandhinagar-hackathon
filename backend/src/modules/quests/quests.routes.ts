import type { FastifyPluginAsync } from 'fastify';
import { Type } from '@sinclair/typebox';
import { QuestsController } from './quests.controller';
import { ClaimQuestResponseSchema, DailyQuestsResponseSchema } from './quests.schema';

export const questsRoutes: FastifyPluginAsync = async (fastify) => {
  const controller = new QuestsController(fastify.db);

  // 1. Get today's active rotating daily quests
  fastify.get(
    '/daily',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Daily Quests'],
        security: [{ bearerAuth: [] }],
        summary: 'Get active rotating Mission LiFE daily tasks and streak progress',
        response: {
          200: DailyQuestsResponseSchema,
        },
      },
    },
    controller.getDailyQuests,
  );

  // 2. Claim reward for completed quest
  fastify.post(
    '/claim/:questId',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Daily Quests'],
        security: [{ bearerAuth: [] }],
        summary: 'Claim a self-reported task coin reward and update the once-daily streak',
        params: Type.Object({
          questId: Type.String(),
        }),
        response: {
          200: ClaimQuestResponseSchema,
        },
      },
    },
    controller.claimQuest,
  );
};
