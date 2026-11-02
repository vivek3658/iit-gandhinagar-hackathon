import type { FastifyPluginAsync } from 'fastify';
import {
  CampaignBodySchema,
  CampaignListSchema,
  CampaignResponseSchema,
  NotificationDispatchResponseSchema,
  NotificationPreferencesSchema,
  UpdateNotificationPreferencesBodySchema,
} from './notifications.schema';
import { NotificationsController } from './notifications.controller';

export const notificationsRoutes: FastifyPluginAsync = async (app) => {
  app.get('/preferences', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Notifications'],
      security: [{ bearerAuth: [] }],
      response: { 200: NotificationPreferencesSchema },
    },
  }, NotificationsController.getPreferences);

  app.put('/preferences', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Notifications'],
      security: [{ bearerAuth: [] }],
      body: UpdateNotificationPreferencesBodySchema,
      response: { 200: NotificationPreferencesSchema },
    },
  }, NotificationsController.updatePreferences);

  app.get('/campaigns', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Admin'],
      security: [{ bearerAuth: [] }],
      response: { 200: CampaignListSchema },
    },
  }, NotificationsController.listCampaigns);

  app.post('/campaigns', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Admin'],
      security: [{ bearerAuth: [] }],
      body: CampaignBodySchema,
      response: { 201: CampaignResponseSchema },
    },
  }, NotificationsController.createCampaign);

  app.post('/internal/dispatch-due', {
    schema: {
      tags: ['Internal'],
      response: { 200: NotificationDispatchResponseSchema },
    },
  }, NotificationsController.dispatchDue);
};
