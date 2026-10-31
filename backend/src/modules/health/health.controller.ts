import type { FastifyReply, FastifyRequest } from 'fastify';
import { HealthService } from './health.service';
import type { HealthResponse } from './health.schema';

export class HealthController {
  public static async check(request: FastifyRequest, _reply: FastifyReply): Promise<HealthResponse> {
    const env = request.server.config?.NODE_ENV || 'development';
    return HealthService.getHealth(env);
  }
}
