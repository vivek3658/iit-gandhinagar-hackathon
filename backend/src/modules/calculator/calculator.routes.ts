import type { FastifyPluginAsync } from 'fastify';
import { CalculatorController } from './calculator.controller';
import {
  EstimateCarbonBodySchema,
  EstimateCarbonResponseSchema,
} from './calculator.schema';

export const calculatorRoutes: FastifyPluginAsync = async (fastify) => {
  const controller = new CalculatorController();

  // Simple Carbon Calculator Estimate Endpoint
  fastify.post(
    '/estimate',
    {
      schema: {
        tags: ['Carbon Calculator'],
        summary: 'Calculate household carbon footprint with benchmarking and tailored savings plan',
        body: EstimateCarbonBodySchema,
        response: {
          200: EstimateCarbonResponseSchema,
        },
      },
    },
    controller.estimateCarbon,
  );
};
