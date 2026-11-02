import type { FastifyPluginAsync } from 'fastify';
import { DevicesController } from './devices.controller';
import { DevicesService } from './devices.service';
import {
  DeviceSummaryResponseSchema,
  DeviceTimeLogResponseSchema,
  LogHoursBodySchema,
} from './devices.schema';

export const devicesRoutes: FastifyPluginAsync = async (fastify) => {
  const service = new DevicesService(fastify.db, fastify.config.NODE_ENV !== 'production');
  const controller = new DevicesController(service);

  // 1. Log appliance runtime hours and check for high-hour threshold alerts
  fastify.post(
    '/log-hours',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Devices & Appliances'],
        security: [{ bearerAuth: [] }],
        summary: 'Log appliance runtime hours and receive high-usage guidance',
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
        security: [{ bearerAuth: [] }],
        summary: 'Get saved appliance runtime summaries and active warnings',
        response: {
          200: DeviceSummaryResponseSchema,
        },
      },
    },
    controller.getSummary,
  );
};
