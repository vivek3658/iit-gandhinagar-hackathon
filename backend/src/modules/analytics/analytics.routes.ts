import type { FastifyPluginAsync } from 'fastify';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsDashboardResponseSchema } from './analytics.schema';

export const analyticsRoutes: FastifyPluginAsync = async (fastify) => {
  const controller = new AnalyticsController();

  // Senior Engineer Electricity & Emissions Dashboard
  fastify.get(
    '/dashboard',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Analytics & Energy'],
        summary: 'Get 24h load curve, appliance power breakdown, and multi-domain CO2e ledger',
        response: {
          200: AnalyticsDashboardResponseSchema,
        },
      },
    },
    controller.getDashboard,
  );

  // Alias for mobile app (/analytics/carbon)
  fastify.get(
    '/carbon',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Analytics & Energy'],
        summary: 'Get 24h load curve, appliance power breakdown, and multi-domain CO2e ledger (alias)',
        response: {
          200: AnalyticsDashboardResponseSchema,
        },
      },
    },
    controller.getDashboard,
  );
};
