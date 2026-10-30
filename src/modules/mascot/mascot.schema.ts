import { Type, type Static } from '@sinclair/typebox';

// --- Mascot Core Types ---
export const MascotTypeSchema = Type.Union([
  Type.Literal('sparrow'),
  Type.Literal('squirrel'),
]);

export const MascotMoodSchema = Type.Union([
  Type.Literal('EXCITED'),
  Type.Literal('HAPPY'),
  Type.Literal('DROOPY'),
  Type.Literal('SLEEPY'),
]);

export const MascotExpressionSchema = Type.Union([
  Type.Literal('tpose'),
  Type.Literal('happy'),
  Type.Literal('excited'),
  Type.Literal('curious'),
  Type.Literal('thinking'),
  Type.Literal('cheering'),
  Type.Literal('resting'),
  Type.Literal('planting'),
  Type.Literal('watering'),
  Type.Literal('celebrating'),
  Type.Literal('exploring'),
  Type.Literal('nest'),
]);

export type MascotExpression = Static<typeof MascotExpressionSchema>;

export const AccessorySlotSchema = Type.Union([
  Type.Literal('HEAD'),
  Type.Literal('NECK'),
  Type.Literal('BODY'),
]);

export const EquippedAccessoriesSchema = Type.Object({
  head: Type.Union([Type.String(), Type.Null()]),
  neck: Type.Union([Type.String(), Type.Null()]),
  body: Type.Union([Type.String(), Type.Null()]),
});

export const MascotDialogueSchema = Type.Object({
  text: Type.String(),
  mood: MascotMoodSchema,
  context: Type.String(), // 'MORNING_SOLAR' | 'PEAK_HOURS' | 'IDLE' | 'STREAK' | 'BEDTIME' | 'TAP'
});

export const MascotStateSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  userId: Type.String({ format: 'uuid' }),
  type: MascotTypeSchema,
  name: Type.String({ minLength: 2, maxLength: 32 }),
  level: Type.Number({ minimum: 1, maximum: 100 }),
  currentExp: Type.Number({ minimum: 0 }), // kg of CO2 saved * 100
  nextLevelExp: Type.Number(),
  vitality: Type.Number({ minimum: 0, maximum: 100 }),
  mood: MascotMoodSchema,
  expression: MascotExpressionSchema,
  activeProps: Type.Array(Type.String()),
  equipped: EquippedAccessoriesSchema,
  ownedAccessories: Type.Array(Type.String()),
  dialogue: MascotDialogueSchema,
  lastInteractedAt: Type.String(),
});

export type MascotState = Static<typeof MascotStateSchema>;

// --- Catalog Items (Shop) ---
export const WardrobeItemSchema = Type.Object({
  id: Type.String(),
  name: Type.String(),
  slot: AccessorySlotSchema,
  description: Type.String(),
  price: Type.Number({ minimum: 50 }),
  requiredLevel: Type.Number({ minimum: 1 }),
  assetModel: Type.String(), // e.g. 'solar_cap.glb'
  isOwned: Type.Boolean(),
  isEquipped: Type.Boolean(),
});

export type WardrobeItem = Static<typeof WardrobeItemSchema>;

// --- Request / Response Bodies ---
export const UpdateMascotBodySchema = Type.Object({
  name: Type.Optional(Type.String({ minLength: 2, maxLength: 32 })),
  type: Type.Optional(MascotTypeSchema),
});

export type UpdateMascotBody = Static<typeof UpdateMascotBodySchema>;

export const InteractResponseSchema = Type.Object({
  vitality: Type.Number(),
  mood: MascotMoodSchema,
  expression: MascotExpressionSchema,
  activeProps: Type.Array(Type.String()),
  pointsAwarded: Type.Number(),
  dialogue: MascotDialogueSchema,
});

export type InteractResponse = Static<typeof InteractResponseSchema>;

export const WardrobeResponseSchema = Type.Object({
  citizenPoints: Type.Number(),
  items: Type.Array(WardrobeItemSchema),
});

export type WardrobeResponse = Static<typeof WardrobeResponseSchema>;

export const BuyAccessoryBodySchema = Type.Object({
  accessoryId: Type.String(),
});

export type BuyAccessoryBody = Static<typeof BuyAccessoryBodySchema>;

export const BuyAccessoryResponseSchema = Type.Object({
  success: Type.Boolean(),
  remainingPoints: Type.Number(),
  ownedAccessories: Type.Array(Type.String()),
  item: WardrobeItemSchema,
});

export type BuyAccessoryResponse = Static<typeof BuyAccessoryResponseSchema>;

export const EquipAccessoryBodySchema = Type.Object({
  slot: AccessorySlotSchema,
  accessoryId: Type.Union([Type.String(), Type.Null()]),
});

export type EquipAccessoryBody = Static<typeof EquipAccessoryBodySchema>;

export const EquipAccessoryResponseSchema = Type.Object({
  success: Type.Boolean(),
  equipped: EquippedAccessoriesSchema,
});

export type EquipAccessoryResponse = Static<typeof EquipAccessoryResponseSchema>;

// --- Route Schemas for Swagger ---
export const GetMascotRouteSchema = {
  description: 'Retrieves active mascot state, vitality, level, equipped accessories, and dynamic speech dialogue.',
  tags: ['Mascot'],
  security: [{ bearerAuth: [] }],
  response: {
    200: MascotStateSchema,
  },
};

export const UpdateMascotRouteSchema = {
  description: 'Updates mascot name and/or switches type (sparrow vs squirrel).',
  tags: ['Mascot'],
  security: [{ bearerAuth: [] }],
  body: UpdateMascotBodySchema,
  response: {
    200: MascotStateSchema,
  },
};

export const InteractRouteSchema = {
  description: 'Citizen interacts/taps mascot, boosting vitality and receiving dynamic contextual dialogue.',
  tags: ['Mascot'],
  security: [{ bearerAuth: [] }],
  response: {
    200: InteractResponseSchema,
  },
};

export const GetWardrobeRouteSchema = {
  description: 'Lists all available accessories (Head, Neck, Body) in the Urja Shop with pricing and ownership state.',
  tags: ['Mascot'],
  security: [{ bearerAuth: [] }],
  response: {
    200: WardrobeResponseSchema,
  },
};

export const BuyAccessoryRouteSchema = {
  description: 'Purchases an accessory using earned Urja Mudra coins (atomic balance deduction).',
  tags: ['Mascot'],
  security: [{ bearerAuth: [] }],
  body: BuyAccessoryBodySchema,
  response: {
    200: BuyAccessoryResponseSchema,
  },
};

export const EquipAccessoryRouteSchema = {
  description: 'Equips or unequips an owned accessory to a mascot slot (HEAD, NECK, BODY).',
  tags: ['Mascot'],
  security: [{ bearerAuth: [] }],
  body: EquipAccessoryBodySchema,
  response: {
    200: EquipAccessoryResponseSchema,
  },
};
