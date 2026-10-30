import crypto from 'node:crypto';
import { AuthService } from '../auth/auth.service';
import type {
  BuyAccessoryResponse,
  EquipAccessoryResponse,
  EquippedAccessoriesSchema,
  InteractResponse,
  MascotExpression,
  MascotMoodSchema,
  MascotState,
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

// Master Wardrobe Accessory Catalog (Costly items >= 100 Urja Mudra)
export const WARDROBE_CATALOG: Omit<WardrobeItem, 'isOwned' | 'isEquipped'>[] = [
  // HEAD ACCESSORIES
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
    id: 'acc_head_gujarati_paghdi',
    name: 'Royal Gujarati Paghdi',
    slot: 'HEAD',
    description: 'Traditional handcrafted Saurashtra turban for state energy champions.',
    price: 250,
    requiredLevel: 10,
    assetModel: 'gujarati_paghdi.glb',
  },
  {
    id: 'acc_head_straw_hat',
    name: 'Eco-Gardener Straw Hat',
    slot: 'HEAD',
    description: 'Organic woven bamboo hat that shields your companion from Ahmedabad midday heat.',
    price: 120,
    requiredLevel: 5,
    assetModel: 'straw_hat.glb',
  },

  // NECK ACCESSORIES
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
    id: 'acc_neck_eco_bell',
    name: 'Solar Brass Eco-Bell',
    slot: 'NECK',
    description: 'Chimes pleasantly whenever you maintain a sustainable energy streak.',
    price: 180,
    requiredLevel: 5,
    assetModel: 'eco_bell.glb',
  },

  // BODY ACCESSORIES
  {
    id: 'acc_body_leaf_sweater',
    name: 'Cozy Woolen Leaf Sweater',
    slot: 'BODY',
    description: 'Warm emerald sweater embroidered with the official Mission LiFE leaf emblem.',
    price: 150,
    requiredLevel: 1,
    assetModel: 'leaf_sweater.glb',
  },
  {
    id: 'acc_body_khadi_vest',
    name: 'Heritage Khadi Vest',
    slot: 'BODY',
    description: 'Handspun organic cotton jacket celebrating Gujarat craft and zero-carbon living.',
    price: 220,
    requiredLevel: 10,
    assetModel: 'khadi_vest.glb',
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
          neck: null,
          body: null,
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
        mascot.equipped.neck === item.id ||
        mascot.equipped.body === item.id;

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
  public static equipAccessory(userId: string, slot: 'HEAD' | 'NECK' | 'BODY', accessoryId: string | null | undefined): EquipAccessoryResponse {
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

    const slotKey = slot.toLowerCase() as 'head' | 'neck' | 'body';
    mascot.equipped[slotKey] = targetAccessoryId;
    this.repository.save(mascot);

    return {
      success: true,
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
