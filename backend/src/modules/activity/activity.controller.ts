import type { FastifyReply, FastifyRequest } from 'fastify';
import { ActivityService } from './activity.service';
import type {
  ActivityFeedResponse,
  GetActivityQuery,
  MarkReadParams,
  MarkReadResponse,
} from './activity.schema';

export class ActivityController {
  public static async getFeed(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<ActivityFeedResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    const query = (request.query as GetActivityQuery) || {};
    return ActivityService.getFeed(userId, query);
  }

  public static async markRead(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<MarkReadResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    const params = request.params as MarkReadParams;
    return ActivityService.markAsRead(params.id, userId);
  }

  public static async markAllRead(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<MarkReadResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    return ActivityService.markAllAsRead(userId);
  }
}
