import type { FastifyReply, FastifyRequest } from 'fastify';
import type { LinkProvidersBody, ListProvidersQuery } from './providers.schema';
import { ProvidersService } from './providers.service';
import { NotificationsService } from '../notifications/notifications.service';
import type { AdminIdentity } from '../admin/admin.service';
import type { ProviderBroadcastBody } from './providers.schema';

export class ProvidersController {
  public static async listProviders(
    request: FastifyRequest<{ Querystring: ListProvidersQuery }>,
    reply: FastifyReply,
  ) {
    const { category, district } = request.query;
    const providers = await ProvidersService.listDirectoryProviders(
      request.server.db,
      category,
      district,
    );
    return reply.status(200).send({
      success: true,
      providers,
      totalCount: providers.length,
    });
  }

  public static async getMyProviders(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user?.id;
    if (!userId) return reply.unauthorized('Citizen authentication is required');
    try {
      const links = await ProvidersService.getCitizenLinks(
        userId,
        request.server.db,
        request.server.config.NODE_ENV === 'test',
      );
      return reply.status(200).send({ success: true, links });
    } catch (error) {
      request.log.error({ err: error }, 'Could not load citizen provider links');
      return reply.serviceUnavailable('Provider-link data is unavailable');
    }
  }

  public static async linkProviders(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user?.id;
    if (!userId) return reply.unauthorized('Citizen authentication is required');
    try {
      const updatedLinks = await ProvidersService.linkCitizenProviders(
        userId,
        request.body as LinkProvidersBody,
        request.server.db,
        request.server.config.NODE_ENV === 'test',
      );
      return reply.status(200).send({ success: true, links: updatedLinks });
    } catch (error) {
      if (error instanceof Error && error.message.includes('not a valid')) {
        return reply.badRequest(error.message);
      }
      request.log.error({ err: error }, 'Could not persist citizen provider links');
      return reply.serviceUnavailable('Provider-link data is unavailable');
    }
  }

  public static async broadcastProviderAlert(request: FastifyRequest, reply: FastifyReply) {
    const { providerId } = request.params as { providerId: string };
    const identity = request.user as AdminIdentity | undefined;
    if (!identity || identity.role !== 'PROVIDER_ADMIN' || identity.tenantType !== 'PROVIDER') {
      return reply.forbidden('Provider administrator access is required.');
    }
    if (identity.tenantId !== providerId) {
      return reply.forbidden('Provider administrator cannot publish for another provider.');
    }
    const body = request.body as ProviderBroadcastBody;
    try {
      const campaign = await NotificationsService.createCampaign(request.server.db, identity, {
        title: body.title,
        message: body.message,
        category: body.category,
        targetDistrict: body.targetDistrict,
        targetProviderId: providerId,
        scheduledAt: body.scheduledAt,
        reason: body.reason ?? 'Provider-initiated service notification',
        incentiveCoins: body.incentiveCoins,
      });
      return reply.status(201).send({
        success: true,
        notificationId: campaign.id,
        dispatchedToCount: campaign.recipientCount,
        message: campaign.status === 'SCHEDULED'
          ? 'Provider notification scheduled for opted-in linked citizens.'
          : 'Provider notification queued for opted-in linked citizens.',
      });
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Provider campaign could not be created.';
      if (message.includes('must ') || message.includes('outside') || message.includes('does not match')) {
        return reply.badRequest(message);
      }
      request.log.error({ err: error, providerId }, 'Could not create provider notification campaign');
      return reply.serviceUnavailable('Provider notification campaign is unavailable.');
    }
  }
}
