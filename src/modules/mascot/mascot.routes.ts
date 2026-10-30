import type { FastifyPluginAsync } from 'fastify';
import {
  BuyAccessoryRouteSchema,
  EquipAccessoryRouteSchema,
  EquipOutfitRouteSchema,
  GetMascotRouteSchema,
  GetOutfitsRouteSchema,
  GetWardrobeRouteSchema,
  InteractRouteSchema,
  UpdateMascotRouteSchema,
} from './mascot.schema';
import { MascotController } from './mascot.controller';

export const mascotRoutes: FastifyPluginAsync = async (fastify) => {
  // All mascot interactions require citizen authentication
  fastify.addHook('preHandler', fastify.authenticate);

  fastify.get('/', { schema: GetMascotRouteSchema }, MascotController.getMascot);
  fastify.get('/state', { schema: GetMascotRouteSchema }, MascotController.getMascot);
  fastify.patch('/', { schema: UpdateMascotRouteSchema }, MascotController.updateMascot);
  fastify.post('/interact', { schema: InteractRouteSchema }, MascotController.interact);

  // Wardrobe & Equippable Accessories
  fastify.get('/wardrobe', { schema: GetWardrobeRouteSchema }, MascotController.getWardrobe);
  fastify.post('/wardrobe/buy', { schema: BuyAccessoryRouteSchema }, MascotController.buyAccessory);
  fastify.post('/wardrobe/equip', { schema: EquipAccessoryRouteSchema }, MascotController.equipAccessory);

  // Seasonal Curated Outfits
  fastify.get('/outfits', { schema: GetOutfitsRouteSchema }, MascotController.getOutfits);
  fastify.post('/outfits/equip', { schema: EquipOutfitRouteSchema }, MascotController.equipOutfit);
};
