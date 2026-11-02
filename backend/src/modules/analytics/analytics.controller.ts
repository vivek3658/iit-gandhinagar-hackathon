import type { FastifyReply, FastifyRequest } from 'fastify';
import { AnalyticsService } from './analytics.service';
import type { Pool } from 'pg';

export class AnalyticsController {
  private readonly service: AnalyticsService;

  public constructor(db: Pool | null, allowTestMemory: boolean) {
    this.service = new AnalyticsService(db, allowTestMemory);
  }

  public getDashboard = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    const result = await this.service.getDashboardAnalytics(userId);
    return reply.status(200).send(result);
  };
}
