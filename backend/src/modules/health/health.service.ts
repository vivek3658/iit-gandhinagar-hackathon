import type { FastifyInstance } from 'fastify';
import type { HealthResponse } from './health.schema';

export class HealthService {
  public static getHealth(environment: string, fastify?: FastifyInstance): HealthResponse {
    const mem = process.memoryUsage();

    const services = fastify
      ? {
          database: fastify.db ? 'connected' : 'in-memory-fallback',
          supabase: fastify.supabase ? 'connected' : 'unconfigured',
          redis: fastify.redis
            ? fastify.redis.status === 'ready'
              ? 'connected'
              : fastify.redis.status
            : 'in-memory-fallback',
          mongodb: fastify.mongo ? 'connected' : 'in-memory-fallback',
          rabbitmq: fastify.rabbitmq?.channel ? 'connected' : 'in-memory-fallback',
        }
      : undefined;

    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: Number(process.uptime().toFixed(2)),
      service: 'urjavatika-backend',
      environment,
      memory: {
        heapUsedMB: Number((mem.heapUsed / 1024 / 1024).toFixed(2)),
        rssMB: Number((mem.rss / 1024 / 1024).toFixed(2)),
      },
      services,
    };
  }
}
