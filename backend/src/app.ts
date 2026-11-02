import fastifyEnv from '@fastify/env';
import { TypeBoxTypeProvider } from '@fastify/type-provider-typebox';
import fastify, { FastifyError, FastifyInstance, FastifyServerOptions, type FastifyReply, type FastifyRequest } from 'fastify';
import { envOptions } from './config/env';
import dbPlugin from './plugins/db';
import redisPlugin from './plugins/redis';
import mongoPlugin from './plugins/mongodb';
import rabbitmqPlugin from './plugins/rabbitmq';
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
import { providersRoutes } from './modules/providers/providers.routes';
import { adminRoutes } from './modules/admin/admin.routes';
import { leaderboardRoutes } from './modules/leaderboard/leaderboard.routes';
import { calculatorRoutes } from './modules/calculator/calculator.routes';
import { analyticsRoutes } from './modules/analytics/analytics.routes';
import { questsRoutes } from './modules/quests/quests.routes';
import { devicesRoutes } from './modules/devices/devices.routes';

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

  // 2. Persistence & Messaging Infrastructure Plugins
  app.register(dbPlugin);
  app.register(redisPlugin);
  app.register(mongoPlugin);
  app.register(rabbitmqPlugin);

  // 3. Core Security & Performance Plugins
  app.register(sensiblePlugin);
  app.register(helmetPlugin);
  app.register(corsPlugin);
  app.register(compressPlugin);
  app.register(authPlugin);
  app.register(swaggerPlugin);

  // 4. Centralized Standard Error Handler
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

  // 5. Root & Documentation Aliases
  const handleRoot = async (request: FastifyRequest, reply: FastifyReply) => {
    const accept = request.headers.accept || '';
    if (accept.includes('text/html')) {
      return reply.redirect('/docs');
    }
    return reply.send({
      name: 'UrjaVatika API | GEDA Mission LiFE',
      status: 'healthy',
      version: '1.0.0',
      documentation: '/docs',
      health: '/health',
    });
  };

  app.get('/', handleRoot);
  app.get('/api', handleRoot);
  app.get('/api/', handleRoot);
  app.get('/documentation', async (_, reply) => reply.redirect('/docs'));
  app.get('/swagger', async (_, reply) => reply.redirect('/docs'));
  app.get('/api/docs', async (_, reply) => reply.redirect('/docs'));

  // 6. Centralized 404 Handler
  app.setNotFoundHandler((request, reply) => {
    reply.status(404).send({
      statusCode: 404,
      error: 'NotFound',
      message: `Route ${request.method} ${request.url} not found`,
    });
  });

  // 7. Feature & System Routes
  app.register(healthRoutes);
  app.register(healthRoutes, { prefix: '/api/v1' });
  app.register(authRoutes, { prefix: '/api/v1/auth' });
  app.register(mediaRoutes, { prefix: '/api/v1/media' });
  app.register(mascotRoutes, { prefix: '/api/v1/mascot' });
  app.register(gardenRoutes, { prefix: '/api/v1/garden' });
  app.register(activityRoutes, { prefix: '/api/v1/activity' });
  app.register(providersRoutes, { prefix: '/api/v1/providers' });
  app.register(adminRoutes, { prefix: '/api/v1/admin' });
  app.register(leaderboardRoutes, { prefix: '/api/v1/leaderboard' });
  app.register(calculatorRoutes, { prefix: '/api/v1/calculator' });
  app.register(analyticsRoutes, { prefix: '/api/v1/analytics' });
  app.register(questsRoutes, { prefix: '/api/v1/quests' });
  app.register(devicesRoutes, { prefix: '/api/v1/devices' });

  return app;
}

export default buildApp;
