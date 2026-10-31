import type { FastifyReply, FastifyRequest } from 'fastify';
import { LeaderboardService } from './leaderboard.service';

export class LeaderboardController {
  private service = LeaderboardService.getInstance();

  public getLeagueLeaderboard = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { id?: string; name?: string } | undefined;
    const userId = user?.id || 'guest_citizen';
    const result = this.service.getLeagueLeaderboard(userId, user?.name);
    return reply.status(200).send(result);
  };

  public getGlobalLeaderboard = async (_request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const result = this.service.getGlobalLeaderboard();
    return reply.status(200).send(result);
  };

  public visitGarden = async (
    request: FastifyRequest<{ Params: { citizenId: string } }>,
    reply: FastifyReply,
  ): Promise<void> => {
    const { citizenId } = request.params;
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
    request: FastifyRequest<{ Params: { citizenId: string } }>,
    reply: FastifyReply,
  ): Promise<void> => {
    const user = request.user as { id?: string } | undefined;
    const visitorId = user?.id || 'guest_visitor';
    const { citizenId } = request.params;
    const result = this.service.cheerCitizen(visitorId, citizenId);
    return reply.status(200).send(result);
  };
}
