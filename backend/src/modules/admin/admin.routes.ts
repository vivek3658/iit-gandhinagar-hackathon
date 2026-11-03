import type { FastifyPluginAsync } from 'fastify';
import { Type } from '@sinclair/typebox';
import { AdminController } from './admin.controller';
import {
  AdminBroadcastAlertBodySchema,
  AdminErrorResponseSchema,
  AdminLoginBodySchema,
  AdminLoginResponseSchema,
  AdminKpisResponseSchema,
  AdminBroadcastAlertResponseSchema,
  AdminProvidersListResponseSchema,
  CreateTenantAdminBodySchema,
  TenantAdminListResponseSchema,
  TenantAdminResponseSchema,
  AdminAuditResponseSchema,
  TenantIdentityResponseSchema,
  TenantOverviewResponseSchema,
  TenantAdminParamsSchema,
} from './admin.schema';
import {
  CampaignBodySchema,
  CampaignListSchema,
  CampaignResponseSchema,
} from '../notifications/notifications.schema';
import {
  CreateProviderBodySchema,
  UtilityProviderSchema,
} from '../providers/providers.schema';

export const adminRoutes: FastifyPluginAsync = async (app) => {
  app.post(
    '/auth/login',
    {
      schema: {
        description: 'Issues a short-lived JWT for a platform or tenant administrator',
        tags: ['Admin'],
        body: AdminLoginBodySchema,
        response: {
          200: AdminLoginResponseSchema,
          503: AdminErrorResponseSchema,
        },
      },
    },
    AdminController.login,
  );

  app.get(
    '/kpis',
    {
      schema: {
        description:
          'Retrieves database-backed admin metrics and identifies unavailable measurements',
        tags: ['Admin'],
        response: {
          200: AdminKpisResponseSchema,
          503: AdminErrorResponseSchema,
        },
      },
      preHandler: [app.authenticate],
    },
    AdminController.getKpis,
  );

  app.post(
    '/broadcast-alert',
    {
      schema: {
        description: 'Creates a consent-filtered, durable in-app notification campaign',
        tags: ['Admin'],
        body: AdminBroadcastAlertBodySchema,
        response: {
          200: AdminBroadcastAlertResponseSchema,
          503: AdminErrorResponseSchema,
        },
      },
      preHandler: [app.authenticate],
    },
    AdminController.broadcastAlert,
  );

  app.post(
    '/send-reminder',
    {
      schema: {
        description: 'Creates a consent-filtered, durable in-app reminder campaign',
        tags: ['Admin'],
        body: AdminBroadcastAlertBodySchema,
        response: {
          200: AdminBroadcastAlertResponseSchema,
          503: AdminErrorResponseSchema,
        },
      },
      preHandler: [app.authenticate],
    },
    AdminController.broadcastAlert,
  );

  app.get(
    '/providers',
    {
      schema: {
        description:
          'Lists the provider directory; subscriber metrics are unavailable until enrollment is persisted',
        tags: ['Admin'],
        response: {
          200: AdminProvidersListResponseSchema,
        },
      },
      preHandler: [app.authenticate],
    },
    AdminController.listProviders,
  );

  app.post(
    '/providers',
    {
      schema: {
        tags: ['Admin'],
        security: [{ bearerAuth: [] }],
        body: CreateProviderBodySchema,
        response: { 201: UtilityProviderSchema, 400: AdminErrorResponseSchema },
      },
      preHandler: [app.authenticate],
    },
    AdminController.createProvider,
  );

  app.post('/tenant-admins', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Admin'],
      security: [{ bearerAuth: [] }],
      body: CreateTenantAdminBodySchema,
      response: { 201: TenantAdminResponseSchema, 503: AdminErrorResponseSchema },
    },
  }, AdminController.createTenantAdmin);

  app.get('/tenant-admins', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Admin'],
      security: [{ bearerAuth: [] }],
      response: { 200: TenantAdminListResponseSchema, 503: AdminErrorResponseSchema },
    },
  }, AdminController.listTenantAdmins);

  app.post('/tenant-admins/:adminId/deactivate', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Admin'],
      security: [{ bearerAuth: [] }],
      params: TenantAdminParamsSchema,
      response: { 200: Type.Object({ success: Type.Boolean() }) },
    },
  }, AdminController.deactivateTenantAdmin);

  app.get('/tenant/me', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Admin'],
      security: [{ bearerAuth: [] }],
      response: {
        200: TenantIdentityResponseSchema,
        401: AdminErrorResponseSchema,
        503: AdminErrorResponseSchema,
      },
    },
  }, AdminController.getTenantIdentity);

  app.get('/tenant/overview', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Admin'],
      security: [{ bearerAuth: [] }],
      response: {
        200: TenantOverviewResponseSchema,
        401: AdminErrorResponseSchema,
        503: AdminErrorResponseSchema,
      },
    },
  }, AdminController.getTenantOverview);

  app.get('/audit', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Admin'],
      security: [{ bearerAuth: [] }],
      response: { 200: AdminAuditResponseSchema, 503: AdminErrorResponseSchema },
    },
  }, AdminController.getAuditLog);

  app.get('/campaigns', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Admin'],
      security: [{ bearerAuth: [] }],
      response: { 200: CampaignListSchema },
    },
  }, AdminController.listCampaigns);

  app.post('/campaigns', {
    preHandler: [app.authenticate],
    schema: {
      tags: ['Admin'],
      security: [{ bearerAuth: [] }],
      body: CampaignBodySchema,
      response: { 201: CampaignResponseSchema, 400: AdminErrorResponseSchema },
    },
  }, AdminController.createCampaign);
};
