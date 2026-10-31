import type { FastifyReply, FastifyRequest } from 'fastify';
import type {
  LinkProvidersBody,
  ListProvidersQuery,
  ProviderBroadcastBody,
} from './providers.schema';
import { ProvidersService } from './providers.service';

export class ProvidersController {
  public static async listProviders(
    request: FastifyRequest<{ Querystring: ListProvidersQuery }>,
    reply: FastifyReply
  ) {
    const { category, district } = request.query;
    const providers = ProvidersService.listProviders(category, district);
    return reply.status(200).send({
      success: true,
      providers,
      totalCount: providers.length,
    });
  }

  public static async getMyProviders(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user?.id || 'demo-citizen-id';
    const links = ProvidersService.getCitizenLinks(userId);
    return reply.status(200).send({
      success: true,
      links,
    });
  }

  public static async linkProviders(
    request: FastifyRequest<{ Body: LinkProvidersBody }>,
    reply: FastifyReply
  ) {
    const userId = request.user?.id || 'demo-citizen-id';
    const updatedLinks = ProvidersService.linkCitizenProviders(userId, request.body);
    return reply.status(200).send({
      success: true,
      links: updatedLinks,
    });
  }

  public static async broadcastProviderAlert(
    request: FastifyRequest<{
      Params: { providerId: string };
      Body: ProviderBroadcastBody;
    }>,
    reply: FastifyReply
  ) {
    const { providerId } = request.params;
    try {
      const result = ProvidersService.broadcastAlert(providerId, request.body);
      return reply.status(200).send(result);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Failed to broadcast provider alert';
      return reply.status(404).send({
        statusCode: 404,
        error: 'NotFound',
        message,
      });
    }
  }
}
