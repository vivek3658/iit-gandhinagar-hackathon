import helmet from '@fastify/helmet';
import fp from 'fastify-plugin';

export default fp(async (fastify) => {
  await fastify.register(helmet, {
    contentSecurityPolicy: false, // Disabled for pure REST API; enable if serving HTML views
    crossOriginEmbedderPolicy: false,
  });
});
