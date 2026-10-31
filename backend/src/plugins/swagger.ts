import fastifySwagger from '@fastify/swagger';
import fastifySwaggerUi from '@fastify/swagger-ui';
import fp from 'fastify-plugin';

export default fp(async (fastify) => {
  await fastify.register(fastifySwagger, {
    openapi: {
      openapi: '3.1.0',
      info: {
        title: 'UrjaVatika API | GEDA Mission LiFE',
        description:
          'High-throughput API specification for Gujarat Energy Development Agency (GEDA) Mission LiFE Citizen Engagement Platform (Problem Statement: HC26-GEDA01).',
        version: '1.0.0',
        contact: {
          name: 'UrjaVatika Engineering Team',
          email: 'support@urjavatika.gujarat.gov.in',
        },
      },
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Local Development Server',
        },
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
            description: 'Enter your short-lived access JWT token',
          },
        },
      },
      tags: [
        { name: 'Health', description: 'System & cluster health check endpoints' },
        { name: 'Auth', description: 'Google OAuth, profile completion, and token management' },
        { name: 'Mascot', description: 'Interactive sparrow/squirrel mood and vitality engine' },
        { name: 'Garden', description: 'Urja Vatika 3x3 virtual green energy plot state' },
        { name: 'Footprint', description: 'DISCOM energy baseline & carbon reduction calculator' },
        { name: 'Nudges', description: 'Gujarat peak-hour demand response alerts & micro-tasks' },
        { name: 'Solar', description: 'PM Surya Ghar rooftop solar feasibility calculator' },
        { name: 'Leaderboard', description: 'Sub-millisecond district and ward rankings' },
      ],
    },
  });

  await fastify.register(fastifySwaggerUi, {
    routePrefix: '/docs',
    uiConfig: {
      docExpansion: 'list',
      deepLinking: true,
      displayRequestDuration: true,
    },
    staticCSP: true,
    transformStaticCSP: (header) => header,
  });
});
