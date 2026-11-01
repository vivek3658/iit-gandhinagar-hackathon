import type { FastifyPluginAsync } from 'fastify';
import { DevicesController } from './devices.controller';
import {
  DeviceSummaryResponseSchema,
  DeviceTimeLogResponseSchema,
  LogHoursBodySchema,
} from './devices.schema';

export const devicesRoutes: FastifyPluginAsync = async (fastify) => {
  const controller = new DevicesController();

  // 1. Log appliance runtime hours and check for high-hour threshold alerts
  fastify.post(
    '/log-hours',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Devices & Appliances'],
        summary: 'Log appliance runtime hours and receive high-usage warnings and rupee savings',
        body: LogHoursBodySchema,
        response: {
          200: DeviceTimeLogResponseSchema,
        },
      },
    },
    controller.logHours,
  );

  // 2. Get device breakdown and high-hour warnings summary
  fastify.get(
    '/summary',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Devices & Appliances'],
        summary: 'Get household device runtime summary, monthly projected bill, and active warnings',
        response: {
          200: DeviceSummaryResponseSchema,
        },
      },
    },
    controller.getSummary,
  );
};
