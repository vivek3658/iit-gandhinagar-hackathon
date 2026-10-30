import type { FastifyReply, FastifyRequest } from 'fastify';
import { MascotService } from './mascot.service';
import type {
  BuyAccessoryBody,
  BuyAccessoryResponse,
  EquipAccessoryBody,
  EquipAccessoryResponse,
  InteractResponse,
  MascotState,
  UpdateMascotBody,
  WardrobeResponse,
} from './mascot.schema';

export class MascotController {
  public static async getMascot(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<MascotState> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    return MascotService.getOrCreateMascot(userId);
  }

  public static async updateMascot(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<MascotState> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    const body = request.body as UpdateMascotBody;
    return MascotService.updateMascot(userId, body);
  }

  public static async interact(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<InteractResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    return MascotService.interact(userId);
  }

  public static async getWardrobe(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<WardrobeResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    return MascotService.getWardrobe(userId);
  }

  public static async buyAccessory(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<BuyAccessoryResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    const body = request.body as BuyAccessoryBody;
    try {
      return MascotService.buyAccessory(userId, body.accessoryId);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to purchase accessory';
      return reply.badRequest(msg);
    }
  }

  public static async equipAccessory(
    request: FastifyRequest,
    reply: FastifyReply,
  ): Promise<EquipAccessoryResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    const body = request.body as EquipAccessoryBody;
    try {
      return MascotService.equipAccessory(userId, body.slot, body.accessoryId);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to equip accessory';
      return reply.badRequest(msg);
    }
  }
}
