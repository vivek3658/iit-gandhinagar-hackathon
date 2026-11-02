import type { FastifyPluginAsync } from 'fastify';
import { ProvidersController } from './providers.controller';
import {
  LinkProvidersBodySchema,
  ListProvidersQuerySchema,
  ListProvidersResponseSchema,
  MyProvidersResponseSchema,
  ProviderBroadcastBodySchema,
  ProviderServiceUnavailableSchema,
  ProviderBroadcastResponseSchema,
} from './providers.schema';

export const providersRoutes: FastifyPluginAsync = async (app) => {
  // Public directory of Gujarat utilities
  app.get(
    '/',
    {
      schema: {
        description: 'Lists all available Gujarat electricity, gas, water, and transit providers',
        tags: ['Providers'],
        querystring: ListProvidersQuerySchema,
        response: {
          200: ListProvidersResponseSchema,
        },
      },
    },
    ProvidersController.listProviders,
  );

  // Get active citizen's linked providers
  app.get(
    '/my',
    {
      schema: {
        description: 'Retrieves current citizen linked utility providers',
        tags: ['Providers'],
        response: {
          200: MyProvidersResponseSchema,
        },
      },
      preHandler: [app.authenticate],
    },
    ProvidersController.getMyProviders,
  );

  // Link citizen providers
  app.put(
    '/link',
    {
      schema: {
        description: 'Links electricity, gas, water and transit providers to the citizen account',
        tags: ['Providers'],
        body: LinkProvidersBodySchema,
        response: {
          200: MyProvidersResponseSchema,
        },
      },
      preHandler: [app.authenticate],
    },
    ProvidersController.linkProviders,
  );

  app.post(
    '/:providerId/broadcast',
    {
      schema: {
        description:
          'Creates a consent-filtered in-app campaign for opted-in citizens linked to this provider',
        tags: ['Providers'],
        body: ProviderBroadcastBodySchema,
        response: {
          201: ProviderBroadcastResponseSchema,
          400: ProviderServiceUnavailableSchema,
          503: ProviderServiceUnavailableSchema,
        },
      },
      preHandler: [app.authenticate],
    },
    ProvidersController.broadcastProviderAlert,
  );
};
