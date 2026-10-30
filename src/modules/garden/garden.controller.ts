import type { FastifyReply, FastifyRequest } from 'fastify';
import { GardenService } from './garden.service';
import type {
  BuyAndPlaceTileBody,
  GardenActionResponse,
  GardenStateResponse,
  PlaceFromInventoryBody,
  PreviewTileBody,
  PreviewTileResponse,
  RemoveToInventoryBody,
  SellTileBody,
} from './garden.schema';

export class GardenController {
  public static async getGarden(
    request: FastifyRequest,
    reply: FastifyReply
  ): Promise<GardenStateResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    return GardenService.getGardenState(userId);
  }

  public static async previewTile(
    request: FastifyRequest,
    reply: FastifyReply
  ): Promise<PreviewTileResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    const { tileId, x, y, rotation } = request.body as PreviewTileBody;
    return GardenService.previewTile(userId, tileId, x, y, rotation || 0);
  }

  public static async buyAndPlace(
    request: FastifyRequest,
    reply: FastifyReply
  ): Promise<GardenActionResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    const { tileId, x, y, rotation } = request.body as BuyAndPlaceTileBody;
    try {
      return GardenService.buyAndPlace(userId, tileId, x, y, rotation || 0);
    } catch (err: unknown) {
      const error = err as Error;
      return reply.badRequest(error.message);
    }
  }

  public static async placeFromInventory(
    request: FastifyRequest,
    reply: FastifyReply
  ): Promise<GardenActionResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    const { instanceId, x, y, rotation } = request.body as PlaceFromInventoryBody;
    try {
      return GardenService.placeFromInventory(userId, instanceId, x, y, rotation || 0);
    } catch (err: unknown) {
      const error = err as Error;
      return reply.badRequest(error.message);
    }
  }

  public static async removeToInventory(
    request: FastifyRequest,
    reply: FastifyReply
  ): Promise<GardenActionResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    const { x, y } = request.body as RemoveToInventoryBody;
    try {
      return GardenService.removeToInventory(userId, x, y);
    } catch (err: unknown) {
      const error = err as Error;
      return reply.badRequest(error.message);
    }
  }

  public static async sellTile(
    request: FastifyRequest,
    reply: FastifyReply
  ): Promise<GardenActionResponse> {
    const userId = request.user?.id;
    if (!userId) {
      return reply.unauthorized('User identity not verified');
    }

    const { instanceId } = request.body as SellTileBody;
    try {
      return GardenService.sellTileFromInventory(userId, instanceId);
    } catch (err: unknown) {
      const error = err as Error;
      return reply.badRequest(error.message);
    }
  }
}
