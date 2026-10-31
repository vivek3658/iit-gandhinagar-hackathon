import type { FastifyReply, FastifyRequest } from 'fastify';
import { QuestsService } from './quests.service';

export class QuestsController {
  private service = QuestsService.getInstance();

  public getDailyQuests = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { id?: string } | undefined;
    const userId = user?.id || 'guest_citizen';
    const result = this.service.getDailyQuests(userId);
    return reply.status(200).send(result);
  };

  public claimQuest = async (
    request: FastifyRequest<{ Params: { questId: string } }>,
    reply: FastifyReply,
  ): Promise<void> => {
    const user = request.user as { id?: string } | undefined;
    const userId = user?.id || 'guest_citizen';
    const { questId } = request.params;
    try {
      const result = this.service.claimQuest(userId, questId);
      return reply.status(200).send(result);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to claim quest';
      return reply.status(400).send({
        statusCode: 400,
        error: 'BadRequest',
        message: msg,
      });
    }
  };
}
