import { Type, type Static } from '@sinclair/typebox';

export const HealthResponseSchema = Type.Object({
  status: Type.String({ examples: ['ok'] }),
  timestamp: Type.String(),
  uptime: Type.Number(),
  service: Type.String(),
  environment: Type.String(),
  memory: Type.Object({
    heapUsedMB: Type.Number(),
    rssMB: Type.Number(),
  }),
});

export type HealthResponse = Static<typeof HealthResponseSchema>;

export const HealthCheckRouteSchema = {
  description: 'Public health and readiness check endpoint',
  tags: ['Health'],
  response: {
    200: HealthResponseSchema,
  },
};
