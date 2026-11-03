import type { FastifyPluginAsync } from 'fastify';
import { DevicesController } from './devices.controller';
import { DevicesService } from './devices.service';
import {
  DeviceSummaryResponseSchema,
  DeviceTimeLogResponseSchema,
  LogHoursBodySchema,
  RegisterDeviceBodySchema,
  RegisteredDeviceRuntimeBodySchema,
  RegisteredDeviceRuntimeResponseSchema,
  RegisteredDeviceSchema,
  RegisteredDevicesResponseSchema,
} from './devices.schema';
import { Type } from '@sinclair/typebox';

export const devicesRoutes: FastifyPluginAsync = async (fastify) => {
  const service = new DevicesService(fastify.db, fastify.config.NODE_ENV !== 'production');
  const controller = new DevicesController(service);
  const authenticated = [fastify.authenticate];

  fastify.get(
    '/registry',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Devices & Appliances'],
        security: [{ bearerAuth: [] }],
        summary: 'List the authenticated citizen’s registered household devices',
        response: { 200: RegisteredDevicesResponseSchema },
      },
    },
    controller.listRegistered,
  );

  fastify.post(
    '/registry',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Devices & Appliances'],
        security: [{ bearerAuth: [] }],
        summary: 'Register a citizen-confirmed device; discovery identifiers stay on-device',
        body: RegisterDeviceBodySchema,
        response: {
          201: Type.Object({ device: RegisteredDeviceSchema }),
        },
      },
    },
    controller.register,
  );

  fastify.delete(
    '/registry/:deviceId',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Devices & Appliances'],
        security: [{ bearerAuth: [] }],
        params: Type.Object({ deviceId: Type.String({ format: 'uuid' }) }),
        response: {
          404: Type.Object({
            statusCode: Type.Integer(),
            error: Type.String(),
            message: Type.String(),
          }),
        },
      },
    },
    controller.removeRegistered,
  );

  fastify.post(
    '/registry/:deviceId/runtime',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Devices & Appliances'],
        security: [{ bearerAuth: [] }],
        params: Type.Object({ deviceId: Type.String({ format: 'uuid' }) }),
        body: RegisteredDeviceRuntimeBodySchema,
        response: {
          200: RegisteredDeviceRuntimeResponseSchema,
          404: Type.Object({
            statusCode: Type.Integer(),
            error: Type.String(),
            message: Type.String(),
          }),
        },
      },
    },
    controller.logRegisteredRuntime,
  );

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
