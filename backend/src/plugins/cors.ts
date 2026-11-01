import cors from '@fastify/cors';
import fp from 'fastify-plugin';

export default fp(async (fastify) => {
  const configuredOrigin =
    fastify.config?.CORS_ORIGIN || process.env.CORS_ORIGIN || '*';
  const isWildcard =
    configuredOrigin === '*' || configuredOrigin === '"*"' || !configuredOrigin;

  await fastify.register(cors, {
    origin: (origin, cb) => {
      // Allow requests with no origin (mobile native apps, curl, server-to-server)
      // or when origin is wildcard '*'
      if (isWildcard || !origin) {
        return cb(null, true);
      }
      const allowed = configuredOrigin
        .split(',')
        .map((o) => o.trim().replace(/^["']|["']$/g, ''));
      if (allowed.includes(origin) || allowed.includes('*')) {
        return cb(null, true);
      }
      return cb(null, false);
    },
    credentials: true,
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  });
});
