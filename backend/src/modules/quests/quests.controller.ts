import type { FastifyReply, FastifyRequest } from 'fastify';
import type { Pool } from 'pg';
import { QuestRuleError, QuestsService } from './quests.service';

export class QuestsController {
  private service: QuestsService;

  public constructor(db: Pool | null) {
    this.service = new QuestsService(db);
  }

  public getDailyQuests = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { id: string };
    const result = await this.service.getDailyQuests(user.id);
    return reply.status(200).send(result);
  };

  public claimQuest = async (
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> => {
    const user = request.user as { id: string };
    const userId = user.id;
    const { questId } = request.params as { questId: string };
    try {
      const result = await this.service.claimQuest(userId, questId);
      return reply.status(200).send(result);
    } catch (err: unknown) {
      if (err instanceof QuestRuleError) {
        return reply.status(400).send({
          statusCode: 400,
          error: 'BadRequest',
          message: err.message,
        });
      }
      throw err;
    }
  };
}
