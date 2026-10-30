import type { FastifyPluginAsync } from 'fastify';
import {
  BuyAndPlaceRouteSchema,
  GetGardenRouteSchema,
  PlaceFromInventoryRouteSchema,
  PreviewTileRouteSchema,
  RemoveToInventoryRouteSchema,
  SellTileRouteSchema,
} from './garden.schema';
import { GardenController } from './garden.controller';

export const gardenRoutes: FastifyPluginAsync = async (fastify) => {
  // All garden interactions require authenticated citizen identity
  fastify.addHook('preHandler', fastify.authenticate);

  // Read Sanctuary State
  fastify.get('/', { schema: GetGardenRouteSchema }, GardenController.getGarden);
  fastify.get('/state', { schema: GetGardenRouteSchema }, GardenController.getGarden);

  // Preview before purchasing
  fastify.post('/preview', { schema: PreviewTileRouteSchema }, GardenController.previewTile);

  // Buy and Place Directly
  fastify.post('/buy-and-place', { schema: BuyAndPlaceRouteSchema }, GardenController.buyAndPlace);

  // Place from existing inventory
  fastify.post('/place-from-inventory', { schema: PlaceFromInventoryRouteSchema }, GardenController.placeFromInventory);

  // Remove to inventory
  fastify.post('/remove-to-inventory', { schema: RemoveToInventoryRouteSchema }, GardenController.removeToInventory);

  // Sell tile from inventory (80% recovery)
  fastify.post('/sell', { schema: SellTileRouteSchema }, GardenController.sellTile);
};
