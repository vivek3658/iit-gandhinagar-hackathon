import type { FastifyReply, FastifyRequest } from 'fastify';
import {
  AdminConfigurationError,
  AdminService,
  type AdminIdentity,
} from './admin.service';
import type { CreateTenantAdminBody } from './admin.schema';
import type { TenantAdminRecord } from './admin.service';
import { NotificationsService } from '../notifications/notifications.service';
import type { CampaignBody } from '../notifications/notifications.schema';

function isAdminIdentity(value: unknown): value is AdminIdentity {
  return typeof value === 'object' && value !== null &&
    'id' in value && typeof value.id === 'string' &&
    'email' in value && typeof value.email === 'string' &&
    'role' in value &&
    ['ADMIN', 'PROVIDER_ADMIN', 'CITY_ADMIN'].includes(String(value.role));
}

export class AdminController {
  public static async login(
    request: FastifyRequest<{ Body: { email: string; password: string } }>,
    reply: FastifyReply,
  ) {
    try {
      const email = request.body.email.trim().toLowerCase();
      const configuredEmail = request.server.config.ADMIN_EMAIL?.trim().toLowerCase();
      if (configuredEmail && configuredEmail === email) {
        const valid = await AdminService.verifyAdminCredentials(
          email,
          request.body.password,
          request.server.config.ADMIN_EMAIL,
          request.server.config.ADMIN_PASSWORD_HASH,
        );
        if (!valid) return reply.unauthorized('Invalid email or password');
        return reply.send({
          accessToken: request.server.jwt.sign(
            { id: `admin:${email}`, email, role: 'ADMIN' },
            { expiresIn: '15m' },
          ),
          tokenType: 'Bearer' as const,
          expiresInSeconds: 900,
          role: 'ADMIN' as const,
        });
      }

      const tenantAdmin = await AdminService.authenticateTenantAdmin(
        request.server.db,
        email,
        request.body.password,
      );
      if (!tenantAdmin) return reply.unauthorized('Invalid email or password');
      return reply.send({
        accessToken: request.server.jwt.sign(
          {
            id: tenantAdmin.id,
            email: tenantAdmin.email,
            role: tenantAdmin.role,
            adminAccountId: tenantAdmin.id,
            tenantId: tenantAdmin.tenantId,
            tenantType: tenantAdmin.tenantType,
          },
          { expiresIn: '15m' },
        ),
        tokenType: 'Bearer' as const,
        expiresInSeconds: 900,
        role: tenantAdmin.role,
        tenantId: tenantAdmin.tenantId,
        tenantType: tenantAdmin.tenantType,
      });
    } catch (error) {
      if (error instanceof AdminConfigurationError) {
        request.log.error({ err: error.message }, 'Admin authentication is unavailable');
        return reply.serviceUnavailable('Admin authentication is not configured');
      }
      request.log.error({ err: error }, 'Admin authentication failed');
      return reply.internalServerError('Admin authentication is temporarily unavailable');
    }
  }

  public static async getKpis(request: FastifyRequest, reply: FastifyReply) {
    if (request.user?.role !== 'ADMIN') {
      return reply.forbidden('Administrator access is required');
    }
    try {
      const data = await AdminService.getKpis(request.server.db);
      return reply.status(200).send(data);
    } catch (error) {
      request.log.error({ err: error }, 'Could not load database-backed admin metrics');
      return reply.serviceUnavailable('Database-backed admin metrics are unavailable');
    }
  }

  public static async broadcastAlert(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity)) {
      return reply.forbidden('Administrator access is required');
    }
    const body = request.body as {
      title: string;
      message: string;
      category?: 'ALERT' | 'COMMUNITY' | 'HABIT';
      targetDistrict?: string;
      targetProviderId?: string;
      targetUserId?: string;
      targetUserEmail?: string;
      incentiveCoins?: number;
      reason?: string;
      scheduledAt?: string;
    };
    try {
      const campaign = await NotificationsService.createCampaign(request.server.db, identity, {
        title: body.title,
        message: body.message,
        category: body.category,
        targetDistrict: body.targetDistrict,
        targetProviderId: body.targetProviderId,
        targetUserId: body.targetUserId,
        targetUserEmail: body.targetUserEmail,
        incentiveCoins: body.incentiveCoins,
        scheduledAt: body.scheduledAt,
        reason: body.reason ?? 'Administrator initiated campaign',
      } as CampaignBody);
      return reply.status(200).send({
        success: true,
        broadcastId: campaign.id,
        scope: campaign.tenantId ? `${campaign.tenantType}:${campaign.tenantId}` : 'PLATFORM',
        recipientsReached: campaign.recipientCount,
        message: campaign.scheduledAt > new Date().toISOString()
          ? 'Campaign scheduled for delivery.'
          : 'Campaign queued for in-app delivery.',
      });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Campaign could not be created.';
      if (
        message.includes('must ') ||
        message.includes('disabled') ||
        message.includes('directory') ||
        message.includes('outside') ||
        message.includes('does not match') ||
        message.includes('delivery time')
      ) {
        return reply.badRequest(message);
      }
      request.log.error({ err: error }, 'Could not create admin notification campaign');
      return reply.serviceUnavailable('Admin campaign delivery is unavailable');
    }
  }

  public static async listProviders(request: FastifyRequest, reply: FastifyReply) {
    if (request.user?.role !== 'ADMIN') {
      return reply.forbidden('Administrator access is required');
    }
    const data = AdminService.listAdminProviders();
    return reply.status(200).send(data);
  }

  public static async createTenantAdmin(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity) || identity.role !== 'ADMIN') {
      return reply.forbidden('Platform administrator access is required');
    }
    try {
      const account = await AdminService.createTenantAdmin(
        request.server.db,
        identity,
        request.body as CreateTenantAdminBody,
      );
      return reply.status(201).send(account);
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Could not create tenant admin.';
      if (message.includes('already exists') || message.includes('directory') ||
        message.includes('must be served') ||
      message.includes('district') ||
        (typeof error === 'object' && error !== null && 'code' in error && error.code === '23505')) {
        return reply.badRequest(message);
      }
      request.log.error({ err: error }, 'Could not create tenant administrator');
      return reply.serviceUnavailable('Tenant administrator provisioning is unavailable');
    }
  }

  public static async listTenantAdmins(request: FastifyRequest, reply: FastifyReply) {
    if (request.user?.role !== 'ADMIN') {
      return reply.forbidden('Platform administrator access is required');
    }
    try {
      return reply.send({ admins: await AdminService.listTenantAdmins(request.server.db) });
    } catch (error: unknown) {
      request.log.error({ err: error }, 'Could not list tenant administrators');
      return reply.serviceUnavailable('Tenant administrator directory is unavailable');
    }
  }

  public static async deactivateTenantAdmin(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity) || identity.role !== 'ADMIN') {
      return reply.forbidden('Platform administrator access is required');
    }
    const { adminId } = request.params as { adminId: string };
    try {
      const deactivated = await AdminService.deactivateTenantAdmin(request.server.db, identity, adminId);
      if (!deactivated) return reply.notFound('Active tenant administrator was not found.');
      return reply.send({ success: true });
    } catch (error: unknown) {
      request.log.error({ err: error }, 'Could not deactivate tenant administrator');
      return reply.serviceUnavailable('Tenant administrator access could not be revoked.');
    }
  }

  public static async getTenantIdentity(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity) || !identity.adminAccountId) {
      return reply.forbidden('Tenant administrator access is required');
    }
    try {
      const tenant = await AdminService.authenticateTenantClaims(request.server.db, identity);
      if (!tenant) return reply.unauthorized('Tenant administrator account is inactive or its access changed');
      return reply.send({
        id: tenant.id,
        email: tenant.email,
        displayName: tenant.displayName,
        tenantType: tenant.tenantType,
        tenantId: tenant.tenantId,
        districts: tenant.districts,
        role: tenant.tenantType === 'CITY' ? 'CITY_ADMIN' : 'PROVIDER_ADMIN',
      });
    } catch (error: unknown) {
      request.log.error({ err: error }, 'Could not validate tenant administrator');
      return reply.serviceUnavailable('Tenant administrator access is unavailable');
    }
  }

  public static async getTenantOverview(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity) || identity.role === 'ADMIN') {
      return reply.forbidden('Tenant administrator access is required');
    }
    try {
      return reply.send(await AdminService.getTenantOverview(request.server.db, identity));
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Tenant metrics are unavailable.';
      if (message.includes('inactive')) return reply.unauthorized(message);
      request.log.error({ err: error }, 'Could not load tenant metrics');
      return reply.serviceUnavailable('Tenant metrics are unavailable');
    }
  }

  public static async getAuditLog(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity)) return reply.forbidden('Administrator access is required');
    try {
      let tenant: TenantAdminRecord | undefined;
      if (identity.role !== 'ADMIN') {
        tenant = await AdminService.authenticateTenantClaims(request.server.db, identity);
        if (!tenant) return reply.unauthorized('Tenant administrator account is inactive or its access changed');
      }
      return reply.send({ items: await AdminService.getAuditLog(request.server.db, tenant) });
    } catch (error: unknown) {
      request.log.error({ err: error }, 'Could not load administrator audit log');
      return reply.serviceUnavailable('Administrator audit log is unavailable');
    }
  }

  public static async createCampaign(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity)) return reply.forbidden('Administrator access is required.');
    try {
      return reply.status(201).send(await NotificationsService.createCampaign(
        request.server.db,
        identity,
        request.body as CampaignBody,
      ));
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Campaign is not valid.';
      if (
        message.includes('must ') ||
        message.includes('disabled') ||
        message.includes('directory') ||
        message.includes('outside') ||
        message.includes('does not match') ||
        message.includes('delivery time')
      ) {
        return reply.badRequest(message);
      }
      if (message.includes('inactive')) return reply.unauthorized(message);
      request.log.error({ err: error }, 'Could not create notification campaign');
      return reply.serviceUnavailable('Notification campaign could not be created.');
    }
  }

  public static async listCampaigns(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity)) return reply.forbidden('Administrator access is required.');
    try {
      return reply.send({ campaigns: await NotificationsService.listCampaigns(request.server.db, identity) });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Campaigns unavailable.';
      if (message.includes('inactive')) return reply.unauthorized(message);
      request.log.error({ err: error }, 'Could not list campaigns');
      return reply.serviceUnavailable('Notification campaigns are unavailable.');
    }
  }
}
