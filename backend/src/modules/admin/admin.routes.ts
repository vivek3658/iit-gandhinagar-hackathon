import type { FastifyPluginAsync } from 'fastify';
import { AdminController } from './admin.controller';
import {
  AdminBroadcastAlertBodySchema,
  AdminBroadcastAlertResponseSchema,
  AdminKpisResponseSchema,
  AdminProvidersListResponseSchema,
} from './admin.schema';

export const adminRoutes: FastifyPluginAsync = async (app) => {
  // State-wide GEDA KPIs & metrics
  app.get(
    '/kpis',
    {
      schema: {
        description: 'Retrieves state-wide energy demand shift and citizen impact KPIs',
        tags: ['Admin'],
        response: {
          200: AdminKpisResponseSchema,
        },
      },
    },
    AdminController.getKpis
  );

  // Broadcast emergency or peak load alert
  app.post(
    '/broadcast-alert',
    {
      schema: {
        description: 'Admin broadcasts an alert/notification to citizen feeds',
        tags: ['Admin'],
        body: AdminBroadcastAlertBodySchema,
        response: {
          200: AdminBroadcastAlertResponseSchema,
        },
      },
    },
    AdminController.broadcastAlert
  );

  // Send reminder directly to specific citizen or broadcast
  app.post(
    '/send-reminder',
    {
      schema: {
        description: 'Admin sends a targeted reminder or advisory to a specific citizen or broadcast',
        tags: ['Admin'],
        body: AdminBroadcastAlertBodySchema,
        response: {
          200: AdminBroadcastAlertResponseSchema,
        },
      },
    },
    AdminController.broadcastAlert
  );

  // Monitor utility providers and subscriber health
  app.get(
    '/providers',
    {
      schema: {
        description: 'Lists all utility providers with active subscriber metrics',
        tags: ['Admin'],
        response: {
          200: AdminProvidersListResponseSchema,
        },
      },
    },
    AdminController.listProviders
  );
};
