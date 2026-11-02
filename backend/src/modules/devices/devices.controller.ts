import type { FastifyReply, FastifyRequest } from 'fastify';
import { DevicesService } from './devices.service';
import type { LogHoursBody } from './devices.schema';

export class DevicesController {
  public constructor(private readonly service: DevicesService) {}

  public logHours = async (
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<void> => {
    const user = request.user as { id: string };
    const result = await this.service.logDeviceHours(user.id, request.body as LogHoursBody);
    return reply.status(200).send(result);
  };

  public getSummary = async (request: FastifyRequest, reply: FastifyReply): Promise<void> => {
    const user = request.user as { id: string };
    const result = await this.service.getDeviceSummary(user.id);
    return reply.status(200).send(result);
  };
}
