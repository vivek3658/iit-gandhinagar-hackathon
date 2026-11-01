import type { FastifyReply, FastifyRequest } from 'fastify';
import { LeaderboardService } from './leaderboard.service';

export class LeaderboardController {
  private service = LeaderboardService.getInstance();

  public getLeagueLeaderboard = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { id?: string } | undefined;
    if (!user?.id) return reply.unauthorized('Sign in to view your weekly league.');
    const userId = user.id;
    const result = this.service.getLeagueLeaderboard(userId);
    return reply.status(200).send(result);
  };

  public getGlobalLeaderboard = async (_request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const result = this.service.getGlobalLeaderboard();
    return reply.status(200).send(result);
  };

  public visitGarden = async (
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> => {
    const { citizenId } = request.params as { citizenId: string };
    const result = this.service.getVisitorGarden(citizenId);
    if (!result) {
      return reply.status(404).send({
        statusCode: 404,
        error: 'NotFound',
        message: `Citizen sanctuary '${citizenId}' not found`,
      });
    }
    return reply.status(200).send(result);
  };

  public cheerCitizen = async (
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> => {
    const user = request.user as { id: string };
    const visitorId = user.id;
    const { citizenId } = request.params as { citizenId: string };
    const result = this.service.cheerCitizen(visitorId, citizenId);
    if (!result) {
      return reply.status(404).send({ statusCode: 404, error: 'NotFound', message: 'Citizen not found' });
    }
    return reply.status(200).send(result);
  };
}
