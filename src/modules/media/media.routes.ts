import type { FastifyPluginAsync } from 'fastify';
import { ImageKitAuthRouteSchema } from './media.schema';
import { MediaController } from './media.controller';

export const mediaRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.get(
    '/imagekit-auth',
    {
      schema: ImageKitAuthRouteSchema,
      preHandler: [fastify.authenticate],
    },
    MediaController.getImageKitAuth,
  );
};
