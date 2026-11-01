import type { FastifyPluginAsync } from 'fastify';
import { ImageKitAuthRouteSchema } from './media.schema';
import { MediaController } from './media.controller';

export const mediaRoutes: FastifyPluginAsync = async (fastify) => {
  const handler = MediaController.getImageKitAuth;
  const opts = {
    schema: ImageKitAuthRouteSchema,
  };

  // Support standard and alias routes for client compatibility
  fastify.get('/imagekit-auth', opts, handler);
  fastify.get('/imagekit/auth', opts, handler);
  fastify.get('/auth', opts, handler);
};
