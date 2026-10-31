import type { FastifyPluginAsync } from 'fastify';
import { ProvidersController } from './providers.controller';
import {
  LinkProvidersBodySchema,
  ListProvidersQuerySchema,
  ListProvidersResponseSchema,
  MyProvidersResponseSchema,
  ProviderBroadcastBodySchema,
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
    ProvidersController.listProviders
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
    },
    ProvidersController.getMyProviders
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
    },
    ProvidersController.linkProviders
  );

  // Provider broadcast alert (sends in-app notification to linked citizens)
  app.post(
    '/:providerId/broadcast',
    {
      schema: {
        description: 'Provider operator broadcasts alert/notification to linked citizens',
        tags: ['Providers'],
        body: ProviderBroadcastBodySchema,
        response: {
          200: ProviderBroadcastResponseSchema,
        },
      },
    },
    ProvidersController.broadcastProviderAlert
  );
};
