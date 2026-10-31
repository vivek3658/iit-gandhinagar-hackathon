import type { FastifyReply, FastifyRequest } from 'fastify';
import type { AdminBroadcastAlertBody } from './admin.schema';
import { AdminService } from './admin.service';

export class AdminController {
  public static async getKpis(_request: FastifyRequest, reply: FastifyReply) {
    const data = AdminService.getKpis();
    return reply.status(200).send(data);
  }

  public static async broadcastAlert(
    request: FastifyRequest<{ Body: AdminBroadcastAlertBody }>,
    reply: FastifyReply
  ) {
    const result = AdminService.broadcastAlert(request.body);
    return reply.status(200).send(result);
  }

  public static async listProviders(_request: FastifyRequest, reply: FastifyReply) {
    const data = AdminService.listAdminProviders();
    return reply.status(200).send(data);
  }
}
