import type { FastifyPluginAsync } from 'fastify';
import { Type } from '@sinclair/typebox';
import {
  WasteScheduleListSchema,
  WasteScheduleParamsSchema,
  WasteScheduleQuerySchema,
  WasteScheduleSchema,
  WasteScheduleWriteSchema,
} from './waste.schema';
import { WasteController } from './waste.controller';

export const wasteRoutes: FastifyPluginAsync = async (app) => {
  app.get('/schedules', {
    schema: {
      tags: ['Waste'],
      querystring: WasteScheduleQuerySchema,
      response: { 200: WasteScheduleListSchema },
    },
  }, WasteController.listPublic);

  app.get('/admin/schedules', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Waste'],
      security: [{ bearerAuth: [] }],
      response: { 200: Type.Object({ schedules: Type.Array(WasteScheduleSchema) }) },
    },
  }, WasteController.listForTenant);

  app.post('/admin/schedules', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Waste'],
      security: [{ bearerAuth: [] }],
      body: WasteScheduleWriteSchema,
      response: { 201: WasteScheduleSchema },
    },
  }, WasteController.create);

  app.put('/admin/schedules/:scheduleId', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Waste'],
      security: [{ bearerAuth: [] }],
      params: WasteScheduleParamsSchema,
      body: WasteScheduleWriteSchema,
      response: { 200: WasteScheduleSchema },
    },
  }, WasteController.update);
};
