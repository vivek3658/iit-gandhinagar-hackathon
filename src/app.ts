import fastifyEnv from '@fastify/env';
import { TypeBoxTypeProvider } from '@fastify/type-provider-typebox';
import fastify, { FastifyError, FastifyInstance, FastifyServerOptions } from 'fastify';
import { envOptions } from './config/env';
import compressPlugin from './plugins/compress';
import corsPlugin from './plugins/cors';
import helmetPlugin from './plugins/helmet';
import sensiblePlugin from './plugins/sensible';
import swaggerPlugin from './plugins/swagger';
import authPlugin from './plugins/auth';
import { healthRoutes } from './modules/health/health.routes';
import { authRoutes } from './modules/auth/auth.routes';
import { mediaRoutes } from './modules/media/media.routes';
import { mascotRoutes } from './modules/mascot/mascot.routes';
import { gardenRoutes } from './modules/garden/garden.routes';
import { activityRoutes } from './modules/activity/activity.routes';

export function buildApp(opts: FastifyServerOptions = {}): FastifyInstance {
  const app = fastify({
    logger: {
      level: process.env.LOG_LEVEL || 'info',
      serializers: {
        req(request) {
          return {
            method: request.method,
            url: request.url,
            hostname: request.hostname,
            remoteAddress: request.ip,
          };
        },
      },
    },
    ...opts,
  }).withTypeProvider<TypeBoxTypeProvider>();

  // 1. Environment Parsing & Validation
  app.register(fastifyEnv, envOptions);

  // 2. Core Security & Performance Plugins
  app.register(sensiblePlugin);
  app.register(helmetPlugin);
  app.register(corsPlugin);
  app.register(compressPlugin);
  app.register(authPlugin);
  app.register(swaggerPlugin);

  // 3. Centralized Standard Error Handler
  app.setErrorHandler((error: FastifyError, request, reply) => {
    const statusCode = error.statusCode || 500;
    const errorName = error.name || 'InternalServerError';
    const message = error.validation
      ? error.message
      : statusCode >= 500
        ? 'An internal server error occurred'
        : error.message;

    if (statusCode >= 500) {
      request.log.error(error);
    } else {
      request.log.warn({ err: error }, 'Client error occurred');
    }

    reply.status(statusCode).send({
      statusCode,
      error: errorName,
      message,
    });
  });

  // 4. Centralized 404 Handler
  app.setNotFoundHandler((request, reply) => {
    reply.status(404).send({
      statusCode: 404,
      error: 'NotFound',
      message: `Route ${request.method} ${request.url} not found`,
    });
  });

  // 5. Feature & System Routes
  app.register(healthRoutes);
  app.register(healthRoutes, { prefix: '/api/v1' });
  app.register(authRoutes, { prefix: '/api/v1/auth' });
  app.register(mediaRoutes, { prefix: '/api/v1/media' });
  app.register(mascotRoutes, { prefix: '/api/v1/mascot' });
  app.register(gardenRoutes, { prefix: '/api/v1/garden' });
  app.register(activityRoutes, { prefix: '/api/v1/activity' });

  return app;
}
