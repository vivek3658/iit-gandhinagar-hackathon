import type { FastifyPluginAsync } from 'fastify';
import { LearningService } from './learning.service';
import {
  CompleteChapterBodySchema,
  CompleteChapterResponseSchema,
  LearningChaptersResponseSchema,
  WasteGameCatalogResponseSchema,
  WasteGameResultSchema,
  WasteGameSubmissionSchema,
} from './learning.schema';

export const learningRoutes: FastifyPluginAsync = async (app) => {
  const service = new LearningService(app.db, app.config.NODE_ENV === 'test');
  const authenticated = [app.authenticate];

  app.get(
    '/chapters',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Learning & Waste Game'],
        security: [{ bearerAuth: [] }],
        summary: 'List versioned educational chapters and quiz questions',
        response: { 200: LearningChaptersResponseSchema },
      },
    },
    async (_request, reply) => reply.send({ chapters: service.getChapters() }),
  );

  app.post(
    '/chapters/:chapterId/complete',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Learning & Waste Game'],
        security: [{ bearerAuth: [] }],
        summary: 'Complete a chapter quiz; coin reward is granted once per version',
        params: {
          type: 'object',
          required: ['chapterId'],
          properties: { chapterId: { type: 'string', minLength: 1, maxLength: 80 } },
        },
        body: CompleteChapterBodySchema,
        response: {
          200: CompleteChapterResponseSchema,
          400: {
            type: 'object',
            required: ['statusCode', 'error', 'message'],
            properties: {
              statusCode: { type: 'integer' },
              error: { type: 'string' },
              message: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { chapterId } = request.params as { chapterId: string };
      const body = request.body as { version: number; answerId: string };
      try {
        return reply.send(
          await service.completeChapter(request.user.id, chapterId, body.version, body.answerId),
        );
      } catch (error) {
        if (error instanceof Error) return reply.badRequest(error.message);
        throw error;
      }
    },
  );

  app.get(
    '/waste-game/catalog',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Learning & Waste Game'],
        security: [{ bearerAuth: [] }],
        summary: 'Get daily sorting game items; sorting guidance can vary by locality',
        response: { 200: WasteGameCatalogResponseSchema },
      },
    },
    async (_request, reply) => reply.send(service.getWasteCatalog()),
  );

  app.post(
    '/waste-game/play',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Learning & Waste Game'],
        security: [{ bearerAuth: [] }],
        summary:
          'Submit a daily sorting game; awards Green Coins once per UTC date, not waste impact',
        body: WasteGameSubmissionSchema,
        response: { 200: WasteGameResultSchema },
      },
    },
    async (request, reply) => {
      const body = request.body as {
        idempotencyKey: string;
        answers: {
          itemId: string;
          bucket: 'ORGANIC' | 'DRY_RECYCLABLE' | 'SPECIAL_HANDLING' | 'RESIDUAL';
        }[];
      };
      try {
        return reply.send(
          await service.playWasteGame(request.user.id, body.idempotencyKey, body.answers),
        );
      } catch (error) {
        if (error instanceof Error) return reply.badRequest(error.message);
        throw error;
      }
    },
  );
};
