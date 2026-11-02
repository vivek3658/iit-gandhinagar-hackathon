import { timingSafeEqual } from 'node:crypto';
import type { FastifyReply, FastifyRequest } from 'fastify';
import type { AdminIdentity } from '../admin/admin.service';
import { NotificationsService } from './notifications.service';
import { WasteService } from '../waste/waste.service';
import type { CampaignBody, UpdateNotificationPreferencesBody } from './notifications.schema';

function isAdminIdentity(value: unknown): value is AdminIdentity {
  return typeof value === 'object' && value !== null &&
    'id' in value && typeof value.id === 'string' &&
    'email' in value && typeof value.email === 'string' &&
    'role' in value &&
    ['ADMIN', 'PROVIDER_ADMIN', 'CITY_ADMIN'].includes(String(value.role));
}

function isRuleError(error: unknown): boolean {
  return error instanceof Error && (
    error.message.includes('must ') ||
    error.message.includes('outside') ||
    error.message.includes('disabled') ||
    error.message.includes('administrator access') ||
    error.message.includes('service area') ||
    error.message.includes('directory') ||
    error.message.includes('does not match') ||
    error.message.includes('future time')
  );
}

export class NotificationsController {
  public static async getPreferences(request: FastifyRequest, reply: FastifyReply) {
    if (request.user?.role !== 'CITIZEN') {
      return reply.forbidden('Citizen authentication is required.');
    }
    const userId = request.user?.id;
    if (!userId) return reply.unauthorized('Citizen authentication is required.');
    try {
      return reply.send(await NotificationsService.getPreferences(request.server.db, userId));
    } catch (error: unknown) {
      request.log.error({ err: error }, 'Could not load notification preferences');
      return reply.serviceUnavailable('Notification preferences are unavailable.');
    }
  }

  public static async updatePreferences(request: FastifyRequest, reply: FastifyReply) {
    if (request.user?.role !== 'CITIZEN') {
      return reply.forbidden('Citizen authentication is required.');
    }
    const userId = request.user?.id;
    if (!userId) return reply.unauthorized('Citizen authentication is required.');
    try {
      return reply.send(await NotificationsService.updatePreferences(
        request.server.db,
        userId,
        request.body as UpdateNotificationPreferencesBody,
      ));
    } catch (error: unknown) {
      request.log.error({ err: error }, 'Could not save notification preferences');
      return reply.serviceUnavailable('Notification preferences could not be saved.');
    }
  }

  public static async createCampaign(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity)) return reply.forbidden('Administrator access is required.');
    try {
      const campaign = await NotificationsService.createCampaign(
        request.server.db,
        identity,
        request.body as CampaignBody,
      );
      return reply.status(201).send(campaign);
    } catch (error: unknown) {
      if (isRuleError(error)) {
        return reply.badRequest(error instanceof Error ? error.message : 'Campaign is not valid.');
      }
      request.log.error({ err: error }, 'Could not create notification campaign');
      return reply.serviceUnavailable('Notification campaign could not be created.');
    }
  }

  public static async listCampaigns(request: FastifyRequest, reply: FastifyReply) {
    const identity = request.user;
    if (!isAdminIdentity(identity)) return reply.forbidden('Administrator access is required.');
    try {
      const campaigns = await NotificationsService.listCampaigns(request.server.db, identity);
      return reply.send({ campaigns });
    } catch (error: unknown) {
      if (error instanceof Error && error.message.includes('inactive')) {
        return reply.unauthorized(error.message);
      }
      request.log.error({ err: error }, 'Could not list notification campaigns');
      return reply.serviceUnavailable('Notification campaigns are unavailable.');
    }
  }

  public static async dispatchDue(request: FastifyRequest, reply: FastifyReply) {
    const expected = request.server.config.CRON_SECRET;
    const authorization = request.headers.authorization ?? '';
    const supplied = authorization.startsWith('Bearer ') ? authorization.slice(7) : '';
    if (!expected || !supplied) return reply.unauthorized('Scheduled notification dispatch is not authorized.');
    const expectedBuffer = Buffer.from(expected);
    const suppliedBuffer = Buffer.from(supplied);
    if (expectedBuffer.length !== suppliedBuffer.length || !timingSafeEqual(expectedBuffer, suppliedBuffer)) {
      return reply.unauthorized('Scheduled notification dispatch is not authorized.');
    }
    try {
      await NotificationsService.prepare(request.server.db);
      const scheduledReminders = await WasteService.enqueueTomorrowReminders(request.server.db);
      const processed = await NotificationsService.dispatchDue(request.server.db);
      return reply.send({ processed, scheduledReminders });
    } catch (error: unknown) {
      request.log.error({ err: error }, 'Could not dispatch scheduled notifications');
      return reply.serviceUnavailable('Scheduled notification delivery is unavailable.');
    }
  }
}
