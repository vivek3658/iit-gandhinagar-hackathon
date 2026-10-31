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

  public clear(): void {
    this.mascots.clear();
  }
}

export class MascotService {
  private static repository = new MascotRepository();

  public static getRepository(): MascotRepository {
    return this.repository;
  }

  /**
   * Get or automatically initialize citizen's mascot
   */
  public static getOrCreateMascot(userId: string, defaultName = 'Chirpy', type: 'sparrow' | 'squirrel' = 'sparrow'): MascotState {
    let mascot = this.repository.findByUserId(userId);

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
      this.repository.save(mascot);
    }

    return this.buildState(mascot);
  }

  /**
   * Update mascot name and/or switch companion species
   */
  public static updateMascot(userId: string, updates: { name?: string; type?: 'sparrow' | 'squirrel' }): MascotState {
    const mascot = this.getOrCreateMascot(userId);
    const updated: MascotRecord = {
      ...mascot,
      name: updates.name?.trim() || mascot.name,
      type: updates.type || mascot.type,
    };

    this.repository.save(updated);
    return this.buildState(updated);
  }

  /**
   * Citizen taps mascot: boosts vitality and triggers contextual dialogue
   */
  public static interact(userId: string): InteractResponse {
    const mascot = this.getOrCreateMascot(userId);

    // Tapping gives +5 vitality up to max 100
    const newVitality = Math.min(100, mascot.vitality + 5);
    const updated: MascotRecord = {
      ...mascot,
      vitality: newVitality,
      lastInteractedAt: new Date().toISOString(),
    };
    this.repository.save(updated);

    const mood = this.calculateMood(newVitality);
    const expression: MascotExpression = 'curious';
    const activeProps = ['sparks'];
    const dialogue = this.generateDialogue(mascot.name, mood, 'TAP');

    return {
      vitality: newVitality,
      mood,
      expression,
      activeProps,
      pointsAwarded: 2, // 2 micro bonus points
      dialogue,
    };
  }

  /**
   * Get available accessories in the Urja Wardrobe
   */
  public static getWardrobe(userId: string): WardrobeResponse {
    const mascot = this.getOrCreateMascot(userId);
    const user = AuthService.getRepository().findById(userId);
    const citizenPoints = user?.points || 0;

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
  public static buyAccessory(userId: string, accessoryId: string): BuyAccessoryResponse {
    const mascot = this.getOrCreateMascot(userId);
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
    const user = authRepo.findById(userId);

    if (!user) {
      throw new Error('Citizen not found');
    }

    if (user.points < item.price) {
      throw new Error(`Insufficient Urja Mudra! Required: ${item.price}, Available: ${user.points}`);
    }

    // Atomic transaction: Deduct points and grant accessory
    authRepo.updateUser(userId, {
      points: user.points - item.price,
    });

    mascot.ownedAccessories.push(accessoryId);
    this.repository.save(mascot);

    return {
      success: true,
      remainingPoints: user.points - item.price,
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
  public static equipAccessory(
    userId: string,
    slot: 'HEAD' | 'FACE' | 'NECK' | 'HELD' | 'FX',
    accessoryId: string | null | undefined
  ): EquipAccessoryResponse {
    const mascot = this.getOrCreateMascot(userId);

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
    this.repository.save(mascot);

    return {
      success: true,
      equipped: mascot.equipped,
    };
  }

  /**
   * Get all seasonal outfits with owned & equipped statuses
   */
  public static getOutfits(userId: string): OutfitsResponse {
    const mascot = this.getOrCreateMascot(userId);

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
  public static equipOutfit(userId: string, outfitId: string): EquipOutfitResponse {
    const mascot = this.getOrCreateMascot(userId);
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

    this.repository.save(mascot);

    return {
      success: true,
      outfitId,
      equipped: mascot.equipped,
    };
  }

  /**
   * Award CO2 savings to mascot, leveling up based on real emissions prevented
   */
  public static addCo2Savings(userId: string, kgCo2Saved: number): MascotState {
    const mascot = this.getOrCreateMascot(userId);
    const addedExp = Math.round(kgCo2Saved * 100);
    const newExp = mascot.currentExp + addedExp;

    // Calculate level based on exponential square curve
    const newLevel = Math.min(100, Math.floor(Math.sqrt(newExp / 100)) + 1);

    const updated: MascotRecord = {
      ...mascot,
      currentExp: newExp,
      level: newLevel,
      vitality: Math.min(100, mascot.vitality + 10), // Saving energy restores companion vitality
    };

    this.repository.save(updated);
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
