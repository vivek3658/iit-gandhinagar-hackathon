import fastifyJwt from '@fastify/jwt';
import fp from 'fastify-plugin';
import type { FastifyReply, FastifyRequest } from 'fastify';

export interface UserPayload {
  id: string;
  email: string;
  role: 'CITIZEN' | 'ADMIN';
}

declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: UserPayload;
    user: UserPayload;
  }
}

export default fp(async (fastify) => {
  const secret =
    fastify.config?.JWT_SECRET ||
    process.env.JWT_SECRET ||
    'dev-jwt-secret-key-must-be-at-least-32-characters-long';

  await fastify.register(fastifyJwt, {
    secret,
    sign: {
      expiresIn: '15m', // Short-lived access token for stateless scaling
    },
  });

  fastify.decorate('authenticate', async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      await request.jwtVerify();
    } catch {
      reply.status(401).send({
        statusCode: 401,
        error: 'Unauthorized',
        message: 'Missing or invalid authentication token',
      });
    }
  });
});
