import type { FastifyReply, FastifyRequest } from 'fastify';
import { AnalyticsService } from './analytics.service';

export class AnalyticsController {
  private service = AnalyticsService.getInstance();

  public getDashboard = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { district?: string } | undefined;
    const result = this.service.getDashboardAnalytics(user?.district || 'Ahmedabad');
    return reply.status(200).send(result);
  };
}
