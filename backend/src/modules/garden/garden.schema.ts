import { Type, type Static } from '@sinclair/typebox';

// --- Tile Categories ---
export const TileCategorySchema = Type.Union([
  Type.Literal('Buildings'),
  Type.Literal('Energy'),
  Type.Literal('Water'),
  Type.Literal('Flora'),
  Type.Literal('Paths'),
  Type.Literal('Furniture'),
]);

export type TileCategory = Static<typeof TileCategorySchema>;

export const TileRotationSchema = Type.Union([
  Type.Literal(0),
  Type.Literal(90),
  Type.Literal(180),
  Type.Literal(270),
]);

export type TileRotation = Static<typeof TileRotationSchema>;

// --- Catalog Item ---
export const GardenCatalogItemSchema = Type.Object({
  id: Type.String(),
  name: Type.String(),
  category: TileCategorySchema,
  requiredLevel: Type.Number({ minimum: 1 }),
  cost: Type.Number({ minimum: 1 }),
  description: Type.String(),
  isUnlocked: Type.Boolean(),
});

export type GardenCatalogItem = Static<typeof GardenCatalogItemSchema>;

// --- Placed Tile on Grid ---
export const PlacedTileSchema = Type.Object({
  instanceId: Type.String({ format: 'uuid' }),
  tileId: Type.String(),
  name: Type.String(),
  category: TileCategorySchema,
  x: Type.Number({ minimum: 0 }),
  y: Type.Number({ minimum: 0 }),
  rotation: TileRotationSchema,
  purchasedPrice: Type.Number(),
  placedAt: Type.String(),
});

export type PlacedTile = Static<typeof PlacedTileSchema>;

// --- Unplaced Tile in Inventory ---
export const InventoryTileSchema = Type.Object({
  instanceId: Type.String({ format: 'uuid' }),
  tileId: Type.String(),
  name: Type.String(),
  category: TileCategorySchema,
  purchasedPrice: Type.Number(),
  sellRefundPrice: Type.Number(), // 80% recovery value
  acquiredAt: Type.String(),
});

export type InventoryTile = Static<typeof InventoryTileSchema>;

// --- Full Garden State Response ---
export const GardenStateResponseSchema = Type.Object({
  gridSize: Type.Number({ minimum: 3, maximum: 10 }),
  mascotLevel: Type.Number({ minimum: 1 }),
  maxOccupancy: Type.Number(),
  currentOccupiedCount: Type.Number(),
  citizenCoins: Type.Number(),
  placedTiles: Type.Array(PlacedTileSchema),
  inventory: Type.Array(InventoryTileSchema),
  catalog: Type.Array(GardenCatalogItemSchema),
});

export type GardenStateResponse = Static<typeof GardenStateResponseSchema>;

// --- Request Schemas ---
export const PreviewTileBodySchema = Type.Object({
  tileId: Type.String(),
  x: Type.Number({ minimum: 0 }),
  y: Type.Number({ minimum: 0 }),
  rotation: Type.Optional(TileRotationSchema),
});

export type PreviewTileBody = Static<typeof PreviewTileBodySchema>;

export const PreviewTileResponseSchema = Type.Object({
  isValid: Type.Boolean(),
  message: Type.String(),
  gridSize: Type.Number(),
  tile: GardenCatalogItemSchema,
  coordinates: Type.Object({
    x: Type.Number(),
    y: Type.Number(),
    rotation: TileRotationSchema,
  }),
});

export type PreviewTileResponse = Static<typeof PreviewTileResponseSchema>;

export const BuyAndPlaceTileBodySchema = Type.Object({
  tileId: Type.String(),
  x: Type.Number({ minimum: 0 }),
  y: Type.Number({ minimum: 0 }),
  rotation: Type.Optional(TileRotationSchema),
});

export type BuyAndPlaceTileBody = Static<typeof BuyAndPlaceTileBodySchema>;

export const PlaceFromInventoryBodySchema = Type.Object({
  instanceId: Type.String({ format: 'uuid' }),
  x: Type.Number({ minimum: 0 }),
  y: Type.Number({ minimum: 0 }),
  rotation: Type.Optional(TileRotationSchema),
});

export type PlaceFromInventoryBody = Static<typeof PlaceFromInventoryBodySchema>;

export const RemoveToInventoryBodySchema = Type.Object({
  x: Type.Number({ minimum: 0 }),
  y: Type.Number({ minimum: 0 }),
});

export type RemoveToInventoryBody = Static<typeof RemoveToInventoryBodySchema>;

export const SellTileBodySchema = Type.Object({
  instanceId: Type.String({ format: 'uuid' }),
});

export type SellTileBody = Static<typeof SellTileBodySchema>;

export const GardenActionResponseSchema = Type.Object({
  success: Type.Boolean(),
  message: Type.String(),
  remainingCoins: Type.Number(),
  placedTile: Type.Optional(PlacedTileSchema),
  removedTile: Type.Optional(PlacedTileSchema),
  refundCoins: Type.Optional(Type.Number()),
  gridSize: Type.Number(),
  placedTiles: Type.Array(PlacedTileSchema),
  inventory: Type.Array(InventoryTileSchema),
});

export type GardenActionResponse = Static<typeof GardenActionResponseSchema>;


// --- Swagger Route Schemas ---
export const GetGardenRouteSchema = {
  description: 'Retrieves citizen garden sanctuary state, grid dimensions, placed tiles, inventory, and catalog.',
  tags: ['Garden'],
  security: [{ bearerAuth: [] }],
  response: {
    200: GardenStateResponseSchema,
  },
};

export const PreviewTileRouteSchema = {
  description: 'Previews tile placement coordinates and validates grid bounds before citizen confirms purchase.',
  tags: ['Garden'],
  security: [{ bearerAuth: [] }],
  body: PreviewTileBodySchema,
  response: {
    200: PreviewTileResponseSchema,
  },
};

export const BuyAndPlaceRouteSchema = {
  description: 'Purchases a garden block with Urja Mudra coins and places it directly onto the grid.',
  tags: ['Garden'],
  security: [{ bearerAuth: [] }],
  body: BuyAndPlaceTileBodySchema,
  response: {
    200: GardenActionResponseSchema,
  },
};

export const PlaceFromInventoryRouteSchema = {
  description: 'Places an unplaced tile from inventory back onto the grid at 0 coin cost.',
  tags: ['Garden'],
  security: [{ bearerAuth: [] }],
  body: PlaceFromInventoryBodySchema,
  response: {
    200: GardenActionResponseSchema,
  },
};

export const RemoveToInventoryRouteSchema = {
  description: 'Removes a tile from the grid and stores it safely in citizen inventory.',
  tags: ['Garden'],
  security: [{ bearerAuth: [] }],
  body: RemoveToInventoryBodySchema,
  response: {
    200: GardenActionResponseSchema,
  },
};

export const SellTileRouteSchema = {
  description: 'Permanently liquidates an owned tile from inventory, refunding 80% of its original catalog cost.',
  tags: ['Garden'],
  security: [{ bearerAuth: [] }],
  body: SellTileBodySchema,
  response: {
    200: GardenActionResponseSchema,
  },
};
