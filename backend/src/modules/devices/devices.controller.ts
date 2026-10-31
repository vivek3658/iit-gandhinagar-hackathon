import type { FastifyReply, FastifyRequest } from 'fastify';
import { DevicesService } from './devices.service';
import type { LogHoursBody } from './devices.schema';

export class DevicesController {
  private service = DevicesService.getInstance();

  public logHours = async (
    request: FastifyRequest<{ Body: LogHoursBody }>,
    reply: FastifyReply,
  ): Promise<void> => {
    const user = request.user as { id?: string } | undefined;
    const userId = user?.id || 'guest_citizen';
    const result = this.service.logDeviceHours(userId, request.body);
    return reply.status(200).send(result);
  };

  public getSummary = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { id?: string } | undefined;
    const userId = user?.id || 'guest_citizen';
    const result = this.service.getDeviceSummary(userId);
    return reply.status(200).send(result);
  };
}
