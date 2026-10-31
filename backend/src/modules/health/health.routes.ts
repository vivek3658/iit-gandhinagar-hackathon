import type { FastifyPluginAsync } from 'fastify';
import { HealthCheckRouteSchema } from './health.schema';
import { HealthController } from './health.controller';

export const healthRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.get('/health', { schema: HealthCheckRouteSchema }, HealthController.check);
};
