import type { FastifyPluginAsync } from 'fastify';
import {
  GetActivityRouteSchema,
  MarkAllReadRouteSchema,
  MarkReadRouteSchema,
} from './activity.schema';
import { ActivityController } from './activity.controller';

export const activityRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('onRoute', (routeOptions) => {
    if (routeOptions.schema) {
      routeOptions.schema.security = [{ bearerAuth: [] }];
    }
  });
  fastify.addHook('preHandler', fastify.authenticate);

  fastify.get('/', { schema: GetActivityRouteSchema }, ActivityController.getFeed);
  fastify.post('/:id/read', { schema: MarkReadRouteSchema }, ActivityController.markRead);
  fastify.post('/read-all', { schema: MarkAllReadRouteSchema }, ActivityController.markAllRead);
};
