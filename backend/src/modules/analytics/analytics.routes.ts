import type { FastifyPluginAsync } from 'fastify';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsDashboardResponseSchema } from './analytics.schema';

export const analyticsRoutes: FastifyPluginAsync = async (fastify) => {
  const controller = new AnalyticsController(fastify.db, fastify.config.NODE_ENV === 'test');

  fastify.get(
    '/dashboard',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Analytics & Energy'],
        security: [{ bearerAuth: [] }],
        summary: 'Get persisted utility readings and explicit availability for measured analytics',
        response: {
          200: AnalyticsDashboardResponseSchema,
        },
      },
    },
    controller.getDashboard,
  );

  fastify.get(
    '/carbon',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Analytics & Energy'],
        security: [{ bearerAuth: [] }],
        summary: 'Get persisted utility readings and explicit availability for measured analytics (alias)',
        response: {
          200: AnalyticsDashboardResponseSchema,
        },
      },
    },
    controller.getDashboard,
  );
};
