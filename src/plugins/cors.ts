import cors from '@fastify/cors';
import fp from 'fastify-plugin';

export default fp(async (fastify) => {
  await fastify.register(cors, {
    origin: fastify.config?.CORS_ORIGIN === '*' ? true : fastify.config?.CORS_ORIGIN || true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Accept-Encoding'],
  });
});
