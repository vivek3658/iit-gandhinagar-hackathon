import type { FastifyPluginAsync } from 'fastify';
import { CitizenDataController } from './citizen-data.controller';
import { CitizenDataService } from './citizen-data.service';
import {
  TripBodySchema,
  TripsResponseSchema,
  UtilityReadingBodySchema,
  UtilityReadingsResponseSchema,
  VehicleBodySchema,
  VehiclesResponseSchema,
} from './citizen-data.schema';

export const citizenDataRoutes: FastifyPluginAsync = async (app) => {
  const controller = new CitizenDataController(
    new CitizenDataService(app.db, app.config.NODE_ENV === 'test'),
  );
  const authenticated = [app.authenticate];

  app.get(
    '/readings',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Citizen Data'],
        security: [{ bearerAuth: [] }],
        summary: 'List the authenticated citizen utility readings',
        response: { 200: UtilityReadingsResponseSchema },
      },
    },
    controller.listReadings,
  );
  app.post(
    '/readings',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Citizen Data'],
        security: [{ bearerAuth: [] }],
        summary: 'Record a user-entered electricity, water, or gas reading',
        body: UtilityReadingBodySchema,
      },
    },
    controller.createReading,
  );

  app.get(
    '/vehicles',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Vehicles & Travel'],
        security: [{ bearerAuth: [] }],
        summary: 'List the authenticated citizen vehicles',
        response: { 200: VehiclesResponseSchema },
      },
    },
    controller.listVehicles,
  );
  app.post(
    '/vehicles',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Vehicles & Travel'],
        security: [{ bearerAuth: [] }],
        summary: 'Add a citizen-entered vehicle; no plate lookup is performed',
        body: VehicleBodySchema,
      },
    },
    controller.createVehicle,
  );
  app.put(
    '/vehicles/:vehicleId',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Vehicles & Travel'],
        security: [{ bearerAuth: [] }],
        summary: 'Update an owned vehicle',
        params: {
          type: 'object',
          required: ['vehicleId'],
          properties: { vehicleId: { type: 'string', format: 'uuid' } },
        },
        body: VehicleBodySchema,
      },
    },
    controller.updateVehicle,
  );
  app.delete(
    '/vehicles/:vehicleId',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Vehicles & Travel'],
        security: [{ bearerAuth: [] }],
        summary: 'Remove an owned vehicle',
        params: {
          type: 'object',
          required: ['vehicleId'],
          properties: { vehicleId: { type: 'string', format: 'uuid' } },
        },
      },
    },
    controller.deleteVehicle,
  );

  app.get(
    '/trips',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Vehicles & Travel'],
        security: [{ bearerAuth: [] }],
        summary: 'List citizen-confirmed trip summaries without raw route data',
        response: { 200: TripsResponseSchema },
      },
    },
    controller.listTrips,
  );
  app.post(
    '/trips',
    {
      preHandler: authenticated,
      schema: {
        tags: ['Vehicles & Travel'],
        security: [{ bearerAuth: [] }],
        summary: 'Submit an idempotent citizen-confirmed trip summary; do not send GPS coordinates',
        body: TripBodySchema,
      },
    },
    controller.createTrip,
  );
};
