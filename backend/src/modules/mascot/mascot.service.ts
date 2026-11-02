import crypto from 'node:crypto';
import { AuthService } from '../auth/auth.service';
import type {
  BuyAccessoryResponse,
  EquipAccessoryResponse,
  EquipOutfitResponse,
  EquippedAccessoriesSchema,
  InteractResponse,
  MascotExpression,
  MascotMoodSchema,
  MascotState,
  OutfitItem,
  OutfitsResponse,
  WardrobeItem,
  WardrobeResponse,
} from './mascot.schema';
import type { Static } from '@sinclair/typebox';
import type { Pool, PoolClient } from 'pg';

type MascotMood = Static<typeof MascotMoodSchema>;
type EquippedAccessories = Static<typeof EquippedAccessoriesSchema>;

export interface MascotRecord {
  id: string;
  userId: string;
  type: 'sparrow' | 'squirrel';
  name: string;
  level: number;
  currentExp: number;
  vitality: number;
  equipped: EquippedAccessories;
  ownedAccessories: string[];
  lastInteractedAt: string;
}

// Master Wardrobe Accessory Catalog
export const WARDROBE_CATALOG: Omit<WardrobeItem, 'isOwned' | 'isEquipped'>[] = [
  // HEAD
  {
    id: 'solar_cap',
    name: 'Solar Peak Baseball Cap',
    slot: 'HEAD',
    description: 'A stylish sporty cap equipped with a micro-solar panel visor.',
    price: 100,
    requiredLevel: 1,
    assetModel: 'solar_cap.glb',
  },
  {
    id: 'acc_head_solar_cap',
    name: 'Solar Peak Baseball Cap',
    slot: 'HEAD',
    description: 'A stylish sporty cap equipped with a micro-solar panel visor.',
    price: 100,
    requiredLevel: 1,
    assetModel: 'solar_cap.glb',
  },
  {
    id: 'beanie',
    name: 'Cozy Wool Beanie',
    slot: 'HEAD',
    description: 'Hand-knitted pompom beanie keeping ears warm in chilly mornings.',
    price: 160,
    requiredLevel: 1,
    assetModel: 'beanie.glb',
  },
  {
    id: 'straw',
    name: 'Eco Straw Sunhat',
    slot: 'HEAD',
    description: 'Woven organic sunhat shielding from fierce summer heat.',
    price: 150,
    requiredLevel: 1,
    assetModel: 'straw.glb',
  },
  {
    id: 'flowers',
    name: 'Floral Blossom Crown',
    slot: 'HEAD',
    description: 'Handcrafted circlet of vibrant spring blossoms.',
    price: 140,
    requiredLevel: 1,
    assetModel: 'flowers.glb',
  },
  {
    id: 'acorn',
    name: 'Acorn Cap Beret',
    slot: 'HEAD',
    description: 'Whimsical acorn cap crafted from forest flora.',
    price: 130,
    requiredLevel: 1,
    assetModel: 'acorn.glb',
  },
  {
    id: 'rainhat',
    name: 'Yellow Fisher Rainhat',
    slot: 'HEAD',
    description: 'Waterproof sunny yellow rainhat for monsoon puddle jumping.',
    price: 150,
    requiredLevel: 1,
    assetModel: 'rainhat.glb',
  },
  {
    id: 'santa',
    name: 'Holiday Santa Cap',
    slot: 'HEAD',
    description: 'Jolly red festive cap with a fluffy white pompom.',
    price: 180,
    requiredLevel: 1,
    assetModel: 'santa.glb',
  },
  {
    id: 'gujarati_paghdi',
    name: 'Royal Gujarati Paghdi',
    slot: 'HEAD',
    description: 'Traditional handcrafted Saurashtra turban for state energy champions.',
    price: 250,
    requiredLevel: 10,
    assetModel: 'gujarati_paghdi.glb',
  },

  // FACE
  {
    id: 'sunnies',
    name: 'Cool UV Shades',
    slot: 'FACE',
    description: 'Tinted sunglasses for soaking in solar rays in style.',
    price: 90,
    requiredLevel: 1,
    assetModel: 'sunnies.glb',
  },
  {
    id: 'readers',
    name: 'Wireframe Reading Glasses',
    slot: 'FACE',
    description: 'Studious spectacles for reviewing energy audit metrics.',
    price: 80,
    requiredLevel: 1,
    assetModel: 'readers.glb',
  },

  // NECK
  {
    id: 'bow',
    name: 'Dapper Green Bow Tie',
    slot: 'NECK',
    description: 'Silk bow tie made of eco-certified organic fibers.',
    price: 70,
    requiredLevel: 1,
    assetModel: 'bow.glb',
  },
  {
    id: 'collar',
    name: 'Smart Leather Band',
    slot: 'NECK',
    description: 'Neat collar with a miniature water droplet pendant.',
    price: 80,
    requiredLevel: 1,
    assetModel: 'collar.glb',
  },
  {
    id: 'lei',
    name: 'Tropical Hawaiian Lei',
    slot: 'NECK',
    description: 'Vibrant garland of fragrant plumeria and orchids.',
    price: 90,
    requiredLevel: 1,
    assetModel: 'lei.glb',
  },
  {
    id: 'knit',
    name: 'Cozy Knitted Scarf',
    slot: 'NECK',
    description: 'Long trailing winter muffler woven from recycled wool.',
    price: 100,
    requiredLevel: 1,
    assetModel: 'knit.glb',
  },
  {
    id: 'plaid',
    name: 'Warm Plaid Scarf',
    slot: 'NECK',
    description: 'Autumnal plaid patterned scarf for brisk evening walks.',
    price: 100,
    requiredLevel: 1,
    assetModel: 'plaid.glb',
  },
  {
    id: 'xmas',
    name: 'Festive Holiday Garland',
    slot: 'NECK',
    description: 'Holly leaves and jingle bells celebrating green holidays.',
    price: 110,
    requiredLevel: 1,
    assetModel: 'xmas.glb',
  },
  {
    id: 'green_muffler',
    name: 'Hand-Knitted Green Muffler',
    slot: 'NECK',
    description: 'Cozy woolen green scarf made from recycled eco-fibers.',
    price: 100,
    requiredLevel: 1,
    assetModel: 'green_muffler.glb',
  },
  {
    id: 'acc_neck_green_muffler',
    name: 'Hand-Knitted Green Muffler',
    slot: 'NECK',
    description: 'Cozy woolen green scarf made from recycled eco-fibers.',
    price: 100,
    requiredLevel: 1,
    assetModel: 'green_muffler.glb',
  },
  {
    id: 'eco_bell',
    name: 'Solar Brass Eco-Bell',
    slot: 'NECK',
    description: 'Chimes pleasantly whenever you maintain a sustainable energy streak.',
    price: 180,
    requiredLevel: 5,
    assetModel: 'eco_bell.glb',
  },

  // HELD
  {
    id: 'umbrella',
    name: 'Classic Twill Umbrella',
    slot: 'HELD',
    description: 'Sturdy wind-resistant parasol for rainy days.',
    price: 140,
    requiredLevel: 1,
    assetModel: 'umbrella.glb',
  },
  {
    id: 'leafbrella',
    name: 'Lotus Leaf Parasol',
    slot: 'HELD',
    description: 'Giant rain-shedding lotus leaf plucked straight from the garden pond.',
    price: 170,
    requiredLevel: 1,
    assetModel: 'leafbrella.glb',
  },

  // FX (Weather & Ambience)
  {
    id: 'petals',
    name: 'Swirling Cherry Petals',
    slot: 'FX',
    description: 'Whirling pink sakura blossom petals drifting in the breeze.',
    price: 50,
    requiredLevel: 1,
    assetModel: 'petals.fx',
  },
  {
    id: 'butterflies',
    name: 'Golden Pollinator Flutters',
    slot: 'FX',
    description: 'Glowing yellow and teal butterflies dancing around your sparrow.',
    price: 80,
    requiredLevel: 1,
    assetModel: 'butterflies.fx',
  },
  {
    id: 'leaves',
    name: 'Autumn Amber Foliage',
    slot: 'FX',
    description: 'Crisp russet and golden leaves tumbling gently to the soil.',
    price: 50,
    requiredLevel: 1,
    assetModel: 'leaves.fx',
  },
  {
    id: 'snow',
    name: 'Soft Winter Flurries',
    slot: 'FX',
    description: 'Delicate crystalline snowflakes shimmering in the air.',
    price: 60,
    requiredLevel: 1,
    assetModel: 'snow.fx',
  },
  {
    id: 'rain',
    name: 'Monsoon Rain Droplets',
    slot: 'FX',
    description: 'Refreshing monsoonal rain droplets and subtle ripple splashes.',
    price: 60,
    requiredLevel: 1,
    assetModel: 'rain.fx',
  },
];

export interface OutfitDefinition {
  id: string;
  name: string;
  description: string;
  season: string;
  head: string | null;
  face: string | null;
  neck: string | null;
  held: string | null;
  fx: string | null;
}

export const OUTFITS_CATALOG: OutfitDefinition[] = [
  {
    id: 'spring',
    name: 'Spring Blossom',
    description: 'Fresh spring floral crown, dapper bow tie, and swirling flower petals.',
    season: 'spring',
    head: 'flowers',
    face: null,
    neck: 'bow',
    held: null,
    fx: 'petals',
  },
  {
    id: 'summer',
    name: 'Summer Breeze',
    description: 'Chic straw sunhat, UV-protective shades, tropical floral lei, and fluttering butterflies.',
    season: 'summer',
    head: 'straw',
    face: 'sunnies',
    neck: 'lei',
    held: null,
    fx: 'butterflies',
  },
  {
    id: 'autumn',
    name: 'Autumn Harvest',
    description: 'Cozy acorn cap, studious reader glasses, warm plaid scarf, and crisp falling autumn leaves.',
    season: 'autumn',
    head: 'acorn',
    face: 'readers',
    neck: 'plaid',
    held: null,
    fx: 'leaves',
  },
  {
    id: 'winter',
    name: 'Cozy Winter',
    description: 'Warm knitted beanie, cozy green muffler, and gentle falling snowflakes.',
    season: 'winter',
    head: 'beanie',
    face: null,
    neck: 'knit',
    held: null,
    fx: 'snow',
  },
  {
    id: 'rainy',
    name: 'Monsoon Splash',
    description: 'Waterproof yellow rainhat, rain collar, organic leaf umbrella, and soothing rain ripples.',
    season: 'rainy',
    head: 'rainhat',
    face: null,
    neck: 'collar',
    held: 'leafbrella',
    fx: 'rain',
  },
  {
    id: 'festive',
    name: 'Festive Celebration',
    description: 'Celebratory red holiday hat, festive holiday garland, and glistening snow.',
    season: 'festive',
    head: 'santa',
    face: null,
    neck: 'xmas',
    held: null,
    fx: 'snow',
  },
];

export class MascotRepository {
  private mascots = new Map<string, MascotRecord>(); // userId -> MascotRecord
  private static schemaReady = new WeakMap<Pool, Promise<void>>();

  public constructor(
    private db: Pool | null = null,
    private allowTestMemory = false,
  ) {}

  public configure(db: Pool | null, allowTestMemory: boolean): void {
    this.db = db;
    this.allowTestMemory = allowTestMemory;
  }

  private async ensureSchema(): Promise<void> {
    if (!this.db) return;
    let ready = MascotRepository.schemaReady.get(this.db);
    if (!ready) {
      ready = this.db.query(`
        CREATE TABLE IF NOT EXISTS public.citizen_mascots (
          user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
          mascot_id UUID NOT NULL UNIQUE,
          mascot_type TEXT NOT NULL CHECK (mascot_type IN ('sparrow', 'squirrel')),
          name TEXT NOT NULL,
          level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 100),
          current_exp INTEGER NOT NULL DEFAULT 0 CHECK (current_exp >= 0),
          vitality INTEGER NOT NULL CHECK (vitality BETWEEN 0 AND 100),
          equipped JSONB NOT NULL DEFAULT '{}'::jsonb,
          owned_accessories JSONB NOT NULL DEFAULT '[]'::jsonb,
          last_interacted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
      `).then(() => undefined);
      MascotRepository.schemaReady.set(this.db, ready);
    }
    await ready;
  }

  public async findByUserIdAsync(userId: string): Promise<MascotRecord | null> {
    if (!this.db) return this.findByUserId(userId);
    await this.ensureSchema();
    const result = await this.db.query(
      `SELECT mascot_id, user_id, mascot_type, name, level, current_exp, vitality,
              equipped, owned_accessories, last_interacted_at
       FROM public.citizen_mascots WHERE user_id = $1`,
      [userId],
    );
    const row = result.rows[0];
    if (!row) return null;
    const record: MascotRecord = {
      id: row.mascot_id,
      userId: row.user_id,
      type: row.mascot_type,
      name: row.name,
      level: Number(row.level),
      currentExp: Number(row.current_exp),
      vitality: Number(row.vitality),
      equipped: row.equipped,
      ownedAccessories: row.owned_accessories,
      lastInteractedAt: new Date(row.last_interacted_at).toISOString(),
    };
    return this.save(record);
  }

  public findByUserId(userId: string): MascotRecord | null {
    const mascot = this.mascots.get(userId);
    return mascot ? { ...mascot, equipped: { ...mascot.equipped }, ownedAccessories: [...mascot.ownedAccessories] } : null;
  }

  public save(record: MascotRecord): MascotRecord {
    this.mascots.set(record.userId, {
      ...record,
      equipped: { ...record.equipped },
      ownedAccessories: [...record.ownedAccessories],
    });
    return record;
  }

  public async saveAsync(
    record: MascotRecord,
    options: { pointsDelta?: number; purchaseAccessoryId?: string } = {},
  ): Promise<number | null> {
    if (!this.db) {
      if (!this.allowTestMemory) {
        throw new Error('PostgreSQL is required for durable mascot state.');
      }
      if (options.pointsDelta !== undefined) {
        const authRepository = AuthService.getRepository();
        const user = await authRepository.refreshByIdAsync(record.userId);
        if (!user) throw new Error('Citizen not found');
        const updatedPoints = user.points + options.pointsDelta;
        if (updatedPoints < 0) {
          throw new Error(`Insufficient Urja Mudra! Required: ${Math.abs(options.pointsDelta)}, Available: ${user.points}`);
        }
        await authRepository.updateUserAsync(record.userId, { points: updatedPoints });
      }
      this.save(record);
      return options.pointsDelta === undefined
        ? null
        : (await AuthService.getRepository().refreshByIdAsync(record.userId))?.points ?? null;
    }

    await this.ensureSchema();
    const queryable = async (client: Pool | PoolClient): Promise<void> => {
      await client.query(
        `INSERT INTO public.citizen_mascots
           (user_id, mascot_id, mascot_type, name, level, current_exp, vitality,
            equipped, owned_accessories, last_interacted_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, $9::jsonb, $10, NOW())
         ON CONFLICT (user_id) DO UPDATE SET
           mascot_type = EXCLUDED.mascot_type, name = EXCLUDED.name, level = EXCLUDED.level,
           current_exp = EXCLUDED.current_exp, vitality = EXCLUDED.vitality,
           equipped = EXCLUDED.equipped, owned_accessories = EXCLUDED.owned_accessories,
           last_interacted_at = EXCLUDED.last_interacted_at, updated_at = NOW()`,
        [
          record.userId, record.id, record.type, record.name, record.level, record.currentExp,
          record.vitality, JSON.stringify(record.equipped), JSON.stringify(record.ownedAccessories),
          record.lastInteractedAt,
        ],
      );
    };

    let updatedPoints: number | null = null;
    if (options.pointsDelta !== undefined) {
      const client = await this.db.connect();
      try {
        await client.query('BEGIN');
        if (options.purchaseAccessoryId) {
          const mascotResult = await client.query(
            `SELECT mascot_id, mascot_type, name, level, current_exp, vitality,
                    equipped, owned_accessories, last_interacted_at
             FROM public.citizen_mascots WHERE user_id = $1 FOR UPDATE`,
            [record.userId],
          );
          const current = mascotResult.rows[0];
          if (!current) throw new Error('Mascot not found for accessory purchase.');
          const currentOwned: string[] = Array.isArray(current.owned_accessories)
            ? current.owned_accessories
            : JSON.parse(String(current.owned_accessories));
          if (currentOwned.includes(options.purchaseAccessoryId)) {
            throw new Error('You already own this accessory!');
          }
          record.id = String(current.mascot_id);
          record.type = current.mascot_type;
          record.name = current.name;
          record.level = Number(current.level);
          record.currentExp = Number(current.current_exp);
          record.vitality = Number(current.vitality);
          record.equipped = current.equipped;
          record.ownedAccessories = [...currentOwned, options.purchaseAccessoryId];
          record.lastInteractedAt = new Date(current.last_interacted_at).toISOString();
        }
        const userResult = await client.query(
          'SELECT points FROM public.users WHERE id = $1 AND deleted_at IS NULL FOR UPDATE',
          [record.userId],
        );
        if (!userResult.rows[0]) throw new Error('Citizen not found');
        const currentPoints = Number(userResult.rows[0].points);
        updatedPoints = currentPoints + options.pointsDelta;
        if (updatedPoints < 0) {
          throw new Error(`Insufficient Urja Mudra! Required: ${Math.abs(options.pointsDelta)}, Available: ${currentPoints}`);
        }
        await client.query(
          'UPDATE public.users SET points = $2, updated_at = NOW() WHERE id = $1',
          [record.userId, updatedPoints],
        );
        await queryable(client);
        await client.query('COMMIT');
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
      AuthService.getRepository().cachePoints(record.userId, updatedPoints);
    } else {
      await queryable(this.db);
    }
    this.save(record);
    return updatedPoints;
  }

  public clear(): void {
    this.mascots.clear();
  }
}

export class MascotService {
  private static repository = new MascotRepository();

  public static configure(db: Pool | null, allowTestMemory: boolean): void {
    this.repository.configure(db, allowTestMemory);
  }

  public static getRepository(): MascotRepository {
    return this.repository;
  }

  /**
   * Get or automatically initialize citizen's mascot
   */
  public static async getOrCreateMascot(userId: string, defaultName = 'Chirpy', type: 'sparrow' | 'squirrel' = 'sparrow'): Promise<MascotState> {
    let mascot = await this.repository.findByUserIdAsync(userId);

    if (!mascot) {
      mascot = {
        id: crypto.randomUUID(),
        userId,
        type,
        name: defaultName,
        level: 1,
        currentExp: 0,
        vitality: 85, // Starts healthy and cheerful
        equipped: {
          head: null,
          face: null,
          neck: null,
          held: null,
          fx: null,
        },
        ownedAccessories: [],
        lastInteractedAt: new Date().toISOString(),
      };
      await this.repository.saveAsync(mascot);
      mascot = await this.repository.findByUserIdAsync(userId) ?? mascot;
    }

    return this.buildState(mascot);
  }

  /**
   * Update mascot name and/or switch companion species
   */
  public static async updateMascot(userId: string, updates: { name?: string; type?: 'sparrow' | 'squirrel' }): Promise<MascotState> {
    const mascot = await this.getOrCreateMascot(userId);
    const updated: MascotRecord = {
      ...mascot,
      name: updates.name?.trim() || mascot.name,
      type: updates.type || mascot.type,
    };

    await this.repository.saveAsync(updated);
    return this.buildState(updated);
  }

  /**
   * Citizen taps mascot: boosts vitality and triggers contextual dialogue
   */
  public static async interact(userId: string): Promise<InteractResponse> {
    const mascot = await this.getOrCreateMascot(userId);

    // Tapping gives +5 vitality up to max 100
    const newVitality = Math.min(100, mascot.vitality + 5);
    const updated: MascotRecord = {
      ...mascot,
      vitality: newVitality,
      lastInteractedAt: new Date().toISOString(),
    };
    await this.repository.saveAsync(updated);

    const mood = this.calculateMood(newVitality);
    const expression: MascotExpression = 'curious';
    const activeProps = ['sparks'];
    const dialogue = this.generateDialogue(mascot.name, mood, 'TAP');

    return {
      vitality: newVitality,
      mood,
      expression,
      activeProps,
      pointsAwarded: 0,
      dialogue,
    };
  }

  /**
   * Get available accessories in the Urja Wardrobe
   */
  public static async getWardrobe(userId: string): Promise<WardrobeResponse> {
    const mascot = await this.getOrCreateMascot(userId);
    const user = await AuthService.getRepository().refreshByIdAsync(userId);
    const citizenPoints = user?.points ?? 0;

    const items: WardrobeItem[] = WARDROBE_CATALOG.map((item) => {
      const isOwned = mascot.ownedAccessories.includes(item.id);
      const isEquipped =
        mascot.equipped.head === item.id ||
        mascot.equipped.face === item.id ||
        mascot.equipped.neck === item.id ||
        mascot.equipped.held === item.id ||
        mascot.equipped.fx === item.id;

      return {
        ...item,
        isOwned,
        isEquipped,
      };
    });

    return {
      citizenPoints,
      items,
    };
  }

  /**
   * Buy an accessory using citizen Urja Mudra coins
   */
  public static async buyAccessory(userId: string, accessoryId: string): Promise<BuyAccessoryResponse> {
    const mascot = await this.getOrCreateMascot(userId);
    const item = WARDROBE_CATALOG.find((catalogItem) => catalogItem.id === accessoryId);

    if (!item) {
      throw new Error(`Accessory with ID '${accessoryId}' not found in catalog`);
    }

    if (mascot.ownedAccessories.includes(accessoryId)) {
      throw new Error('You already own this accessory!');
    }

    if (mascot.level < item.requiredLevel) {
      throw new Error(`Requires Mascot Level ${item.requiredLevel}. Keep saving CO2 to unlock!`);
    }

    const authRepo = AuthService.getRepository();
    const user = await authRepo.refreshByIdAsync(userId);

    if (!user) {
      throw new Error('Citizen not found');
    }

    if (user.points < item.price) {
      throw new Error(`Insufficient Urja Mudra! Required: ${item.price}, Available: ${user.points}`);
    }

    mascot.ownedAccessories.push(accessoryId);
    const remainingPoints = await this.repository.saveAsync(mascot, {
      pointsDelta: -item.price,
      purchaseAccessoryId: accessoryId,
    });

    return {
      success: true,
      remainingPoints: remainingPoints ?? user.points - item.price,
      ownedAccessories: mascot.ownedAccessories,
      item: {
        ...item,
        isOwned: true,
        isEquipped: false,
      },
    };
  }

  /**
   * Equip or unequip an owned accessory to a designated slot
   */
  public static async equipAccessory(
    userId: string,
    slot: 'HEAD' | 'FACE' | 'NECK' | 'HELD' | 'FX',
    accessoryId: string | null | undefined
  ): Promise<EquipAccessoryResponse> {
    const mascot = await this.getOrCreateMascot(userId);

    const targetAccessoryId = accessoryId && accessoryId.trim() !== '' ? accessoryId : null;

    if (targetAccessoryId !== null) {
      if (!mascot.ownedAccessories.includes(targetAccessoryId)) {
        throw new Error('You must purchase this accessory before equipping it');
      }

      const item = WARDROBE_CATALOG.find((catalogItem) => catalogItem.id === targetAccessoryId);
      if (!item || item.slot !== slot) {
        throw new Error(`Accessory '${targetAccessoryId}' cannot be equipped in slot ${slot}`);
      }
    }

    const slotKey = slot.toLowerCase() as 'head' | 'face' | 'neck' | 'held' | 'fx';
    mascot.equipped[slotKey] = targetAccessoryId;
    await this.repository.saveAsync(mascot);

    return {
      success: true,
      equipped: mascot.equipped,
    };
  }

  /**
   * Get all seasonal outfits with owned & equipped statuses
   */
  public static async getOutfits(userId: string): Promise<OutfitsResponse> {
    const mascot = await this.getOrCreateMascot(userId);

    const outfits: OutfitItem[] = OUTFITS_CATALOG.map((o) => {
      const requiredPieces = [o.head, o.face, o.neck, o.held, o.fx].filter((p): p is string => Boolean(p));
      const missingPieces = requiredPieces.filter((p) => !mascot.ownedAccessories.includes(p));
      const isOwned = missingPieces.length === 0;

      const isEquipped =
        (!o.head || mascot.equipped.head === o.head) &&
        (!o.face || mascot.equipped.face === o.face) &&
        (!o.neck || mascot.equipped.neck === o.neck) &&
        (!o.held || mascot.equipped.held === o.held) &&
        (!o.fx || mascot.equipped.fx === o.fx);

      const packageCost = missingPieces.reduce((acc, pieceId) => {
        const catalogItem = WARDROBE_CATALOG.find((it) => it.id === pieceId);
        return acc + (catalogItem?.price || 0);
      }, 0);

      return {
        id: o.id,
        name: o.name,
        description: o.description,
        season: o.season,
        head: o.head,
        face: o.face,
        neck: o.neck,
        held: o.held,
        fx: o.fx,
        isOwned,
        isEquipped,
        missingCount: missingPieces.length,
        packageCost,
      };
    });

    return { outfits };
  }

  /**
   * Equip a seasonal outfit bundle
   */
  public static async equipOutfit(userId: string, outfitId: string): Promise<EquipOutfitResponse> {
    const mascot = await this.getOrCreateMascot(userId);
    const outfit = OUTFITS_CATALOG.find((o) => o.id === outfitId);

    if (!outfit) {
      throw new Error(`Outfit '${outfitId}' not found in catalog`);
    }

    // Equip whatever pieces the user owns from this outfit
    if (outfit.head && mascot.ownedAccessories.includes(outfit.head)) {
      mascot.equipped.head = outfit.head;
    } else if (outfit.head) {
      mascot.equipped.head = null;
    }

    if (outfit.face && mascot.ownedAccessories.includes(outfit.face)) {
      mascot.equipped.face = outfit.face;
    } else if (outfit.face) {
      mascot.equipped.face = null;
    }

    if (outfit.neck && mascot.ownedAccessories.includes(outfit.neck)) {
      mascot.equipped.neck = outfit.neck;
    } else if (outfit.neck) {
      mascot.equipped.neck = null;
    }

    if (outfit.held && mascot.ownedAccessories.includes(outfit.held)) {
      mascot.equipped.held = outfit.held;
    } else if (outfit.held) {
      mascot.equipped.held = null;
    }

    if (outfit.fx && mascot.ownedAccessories.includes(outfit.fx)) {
      mascot.equipped.fx = outfit.fx;
    } else if (outfit.fx) {
      mascot.equipped.fx = null;
    }

    await this.repository.saveAsync(mascot);

    return {
      success: true,
      outfitId,
      equipped: mascot.equipped,
    };
  }

  /**
   * Award CO2 savings to mascot, leveling up based on real emissions prevented
   */
  public static async addCo2Savings(userId: string, kgCo2Saved: number): Promise<MascotState> {
    if (!Number.isFinite(kgCo2Saved) || kgCo2Saved <= 0) {
      throw new RangeError('CO2 savings must be a positive finite number of kilograms.');
    }
    const mascot = await this.getOrCreateMascot(userId);
    const addedExp = Math.round(kgCo2Saved * 100);
    const newExp = mascot.currentExp + addedExp;
    if (!Number.isSafeInteger(addedExp) || addedExp < 1 || newExp > 2_147_483_647) {
      throw new RangeError('CO2 savings exceed the supported mascot experience range.');
    }

    // Calculate level based on exponential square curve
    const newLevel = Math.min(100, Math.floor(Math.sqrt(newExp / 100)) + 1);

    const updated: MascotRecord = {
      ...mascot,
      currentExp: newExp,
      level: newLevel,
      vitality: Math.min(100, mascot.vitality + 10), // Saving energy restores companion vitality
    };

    await this.repository.saveAsync(updated);
    return this.buildState(updated);
  }

  private static buildState(mascot: MascotRecord): MascotState {
    const mood = this.calculateMood(mascot.vitality);
    const { expression, activeProps } = this.calculateExpressionAndProps(mascot.vitality, mascot.level);
    const nextLevelExp = Math.pow(mascot.level, 2) * 100;
    const dialogue = this.generateDialogue(mascot.name, mood, 'IDLE');

    return {
      id: mascot.id,
      userId: mascot.userId,
      type: mascot.type,
      name: mascot.name,
      level: mascot.level,
      currentExp: mascot.currentExp,
      nextLevelExp,
      vitality: mascot.vitality,
      mood,
      expression,
      activeProps,
      equipped: mascot.equipped,
      ownedAccessories: mascot.ownedAccessories,
      dialogue,
      lastInteractedAt: mascot.lastInteractedAt,
    };
  }

  public static calculateExpressionAndProps(vitality: number, _level = 1): { expression: MascotExpression; activeProps: string[] } {
    const hour = new Date().getHours();
    if (hour >= 22 || hour < 5 || vitality < 25) {
      return { expression: 'nest', activeProps: ['nest', 'zzz'] };
    }
    if (vitality >= 80) {
      return { expression: 'excited', activeProps: ['sparks'] };
    }
    if (vitality >= 50) {
      return { expression: 'happy', activeProps: [] };
    }
    return { expression: 'resting', activeProps: [] };
  }

  private static calculateMood(vitality: number): MascotMood {
    if (vitality >= 80) return 'EXCITED';
    if (vitality >= 50) return 'HAPPY';
    if (vitality >= 25) return 'DROOPY';
    return 'SLEEPY';
  }

  /**
   * Context-Aware Dynamic Speech Engine
   * Generates realistic, time-of-day and state-sensitive dialogue so it never feels canned.
   */
  private static generateDialogue(name: string, mood: MascotMood, action: 'TAP' | 'IDLE'): { text: string; mood: MascotMood; context: string } {
    const hour = new Date().getHours();

    if (action === 'TAP') {
      const tapQuotes = [
        `Chirp! ⚡ ${name} is thrilled you stopped by!`,
        `Flutter! Keep powering Gujarat's Mission LiFE!`,
        `Ready for today's energy challenge? Let's conserve!`,
      ];
      const text = tapQuotes[Math.floor(Math.random() * tapQuotes.length)] || tapQuotes[0]!;
      return { text, mood, context: 'TAP' };
    }

    // Time-based contextual triggers
    if (hour >= 6 && hour < 11) {
      return {
        text: `Good morning! ☀️ Gujarat solar generation is peaking today. Great time for laundry and pumping water!`,
        mood,
        context: 'MORNING_SOLAR',
      };
    }

    if (hour >= 18 && hour <= 21) {
      return {
        text: `⚡ Evening Peak Grid Hour (6:30 - 9:30 PM)! Let's switch off idle lights to protect our Gujarat power grid.`,
        mood: mood === 'SLEEPY' ? 'DROOPY' : 'EXCITED',
        context: 'PEAK_HOURS',
      };
    }

    if (hour >= 22 || hour < 5) {
      return {
        text: `🌙 Bedtime wind-down! Remember to unplug fully-charged phones and laptop chargers.`,
        mood: 'SLEEPY',
        context: 'BEDTIME',
      };
    }

    if (mood === 'DROOPY' || mood === 'SLEEPY') {
      return {
        text: `Phew, feeling a bit sluggish... Have you completed a green micro-habit today?`,
        mood,
        context: 'LOW_VITALITY',
      };
    }

    return {
      text: `Every unit of energy you conserve helps our digital sanctuary grow! 🌿`,
      mood: 'HAPPY',
      context: 'IDLE',
    };
  }
}
