import Redis from 'ioredis';
import fp from 'fastify-plugin';
import { LeaderboardService } from '../modules/leaderboard/leaderboard.service';

declare module 'fastify' {
  interface FastifyInstance {
    redis: Redis | null;
  }
}

export default fp(async (fastify) => {
  const config = fastify.config;
  const redisUrl = config?.REDIS_URL;

  let redisClient: Redis | null = null;

  if (redisUrl && redisUrl.trim() !== '') {
    try {
      redisClient = new Redis(redisUrl, {
        lazyConnect: true,
        maxRetriesPerRequest: 1,
        connectTimeout: 4000,
        retryStrategy(times) {
          if (times > 3) {
            return null; // Stop retrying after 3 attempts
          }
          return Math.min(times * 1000, 3000);
        },
      });

      redisClient.on('error', (err) => {
        fastify.log.warn({ err: err.message }, '[Redis] Connection warning or offline');
      });

      // Try connecting asynchronously
      redisClient.connect()
        .then(() => {
          fastify.log.info('[Redis] Connected successfully to Redis instance');
          LeaderboardService.getInstance().setRedisClient(redisClient);
        })
        .catch((err: unknown) => {
          const msg = err instanceof Error ? err.message : String(err);
          fastify.log.warn({ err: msg }, '[Redis] Could not connect to REDIS_URL. Operating in fallback memory mode.');
        });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      fastify.log.warn({ err: msg }, '[Redis] Failed to initialize Redis client');
    }
  } else {
    fastify.log.info('[Redis] REDIS_URL not configured. Operating in fallback memory mode.');
  }

  fastify.decorate('redis', redisClient);
  LeaderboardService.getInstance().setRedisClient(redisClient);

  fastify.addHook('onClose', async () => {
    if (redisClient && redisClient.status === 'ready') {
      await redisClient.quit().catch(() => redisClient?.disconnect());
    }
  });
});
