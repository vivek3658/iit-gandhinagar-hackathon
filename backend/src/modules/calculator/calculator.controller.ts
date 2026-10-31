import type { FastifyReply, FastifyRequest } from 'fastify';
import { CalculatorService } from './calculator.service';
import type { EstimateCarbonBody } from './calculator.schema';

export class CalculatorController {
  private service = CalculatorService.getInstance();

  public estimateCarbon = async (
    request: FastifyRequest<{ Body: EstimateCarbonBody }>,
    reply: FastifyReply,
  ): Promise<void> => {
    const result = this.service.calculate(request.body);
    return reply.status(200).send(result);
  };
}
