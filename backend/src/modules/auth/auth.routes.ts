import type { FastifyPluginAsync } from 'fastify';
import {
  CompleteProfileRouteSchema,
  DeleteAccountRouteSchema,
  GoogleAuthRouteSchema,
  LogoutRouteSchema,
  MeRouteSchema,
  RefreshTokenRouteSchema,
} from './auth.schema';
import { AuthController } from './auth.controller';

export const authRoutes: FastifyPluginAsync = async (fastify) => {
  // Public Routes
  fastify.post('/google', { schema: GoogleAuthRouteSchema }, AuthController.googleAuth);
  fastify.post('/refresh', { schema: RefreshTokenRouteSchema }, AuthController.refreshToken);

  // Authenticated Routes (Requires Bearer JWT)
  fastify.post(
    '/complete-profile',
    {
      schema: CompleteProfileRouteSchema,
      preHandler: [fastify.authenticate],
    },
    AuthController.completeProfile,
  );

  fastify.get(
    '/me',
    {
      schema: MeRouteSchema,
      preHandler: [fastify.authenticate],
    },
    AuthController.getMe,
  );

  fastify.post(
    '/logout',
    {
      schema: LogoutRouteSchema,
      preHandler: [fastify.authenticate],
    },
    AuthController.logout,
  );

  fastify.delete(
    '/account',
    {
      schema: DeleteAccountRouteSchema,
      preHandler: [fastify.authenticate],
    },
    AuthController.deleteAccount,
  );
};
