import crypto from 'node:crypto';
import { RabbitMQService } from '../../plugins/rabbitmq';
import { AuthService } from '../auth/auth.service';
import { MascotService } from '../mascot/mascot.service';
import type { Pool } from 'pg';
import type {
  GardenActionResponse,
  GardenCatalogItem,
  GardenStateResponse,
  InventoryTile,
  PlacedTile,
  PreviewTileResponse,
  TileCategory,
  TileRotation,
} from './garden.schema';

export interface GardenRecord {
  userId: string;
  placedTiles: PlacedTile[];
  inventory: InventoryTile[];
  updatedAt: string;
}

export interface MasterTileDefinition {
  id: string;
  name: string;
  category: TileCategory;
  requiredLevel: number;
  cost: number;
  description: string;
}

// Master 31-Tile Catalog with economic tiering
export const MASTER_GARDEN_CATALOG: MasterTileDefinition[] = [
  // Paths & Fences (Affordable starter cosmetics: 50 - 150 coins)
  {
    id: 'EMPTY_LAND',
    name: 'Empty Land Block',
    category: 'Paths',
    requiredLevel: 1,
    cost: 50,
    description: 'Fresh tilled soil plot ready for green development.',
  },
  {
    id: 'GRASS_TILE',
    name: 'Lush Meadow Tile',
    category: 'Paths',
    requiredLevel: 1,
    cost: 50,
    description: 'Soft native Gujarati grass meadow with blooming wild sprouts.',
  },
  {
    id: 'STONE_PATH',
    name: 'Cobblestone Way',
    category: 'Paths',
    requiredLevel: 1,
    cost: 100,
    description: 'Charming permeable stone path connecting garden plots.',
  },
  {
    id: 'DIRT_PATH',
    name: 'Rammed Earth Trail',
    category: 'Paths',
    requiredLevel: 1,
    cost: 100,
    description: 'Traditional compressed clay path for natural rainwater drainage.',
  },
  {
    id: 'WOOD_FENCE',
    name: 'Rustic Picket Fence',
    category: 'Paths',
    requiredLevel: 1,
    cost: 100,
    description: 'Sturdy boundary fence made from reclaimed upcycled timber.',
  },
  {
    id: 'WOOD_PATH',
    name: 'Timber Deck Tile',
    category: 'Paths',
    requiredLevel: 2,
    cost: 120,
    description: 'Polished recycled teakwood decking for garden walkways.',
  },
  {
    id: 'GARDEN_GATE',
    name: 'Garden Gate Arch',
    category: 'Paths',
    requiredLevel: 3,
    cost: 150,
    description: 'Arched floral entryway welcoming songbirds and pollinators.',
  },

  // Flora & Agriculture (Nature & Biodiversity: 150 - 350 coins)
  {
    id: 'ROCK_BOULDER',
    name: 'Boulder Rock',
    category: 'Flora',
    requiredLevel: 1,
    cost: 150,
    description: 'Natural sandstone formation offering shade for micro-fauna.',
  },
  {
    id: 'TULSI_KYARO',
    name: 'Sacred Tulsi Altar',
    category: 'Flora',
    requiredLevel: 1,
    cost: 250,
    description: 'Traditional terracotta Tulsi planter purifying ambient air.',
  },
  {
    id: 'FLOWER_BED',
    name: 'Pollinator Flower Patch',
    category: 'Flora',
    requiredLevel: 2,
    cost: 200,
    description: 'Vibrant marigolds and jasmine attracting local bees and butterflies.',
  },
  {
    id: 'VEGETABLE_PLOT',
    name: 'Organic Vegetable Plot',
    category: 'Flora',
    requiredLevel: 2,
    cost: 300,
    description: 'Sustainable kitchen garden patch producing zero-mile fresh carrots & leafy greens.',
  },
  {
    id: 'TREE_SMALL',
    name: 'Young Fruit Tree',
    category: 'Flora',
    requiredLevel: 3,
    cost: 300,
    description: 'Young sapling yielding fresh seasonal organic fruit.',
  },
  {
    id: 'ROSE_BUSH',
    name: 'Flowering Bush',
    category: 'Flora',
    requiredLevel: 4,
    cost: 220,
    description: 'Perennial flowering shrub supporting garden micro-climate cooling.',
  },
  {
    id: 'TREE_LARGE',
    name: 'Mature Apple Tree',
    category: 'Flora',
    requiredLevel: 6,
    cost: 450,
    description: 'Flourishing fruit-bearing tree that sequesters CO2 and creates dense canopy shade.',
  },
  {
    id: 'HERITAGE_BANYAN',
    name: 'Sacred Canopy Banyan',
    category: 'Flora',
    requiredLevel: 25,
    cost: 1200,
    description: 'Grand Gujarat heritage tree illuminated with fairy lantern fireflies.',
  },
  {
    id: 'FREEDOM_TREE',
    name: 'Freedom Blossom Tree',
    category: 'Flora',
    requiredLevel: 25,
    cost: 1500,
    description: 'Majestic blossoming landmark commemorating citizen green independence.',
  },

  // Furniture & Sanctuary Decor (200 - 400 coins)
  {
    id: 'BIRD_HOUSE',
    name: 'Wooden Bird House',
    category: 'Furniture',
    requiredLevel: 1,
    cost: 200,
    description: 'Cozy elevated nest box providing safe shelter for native sparrows.',
  },
  {
    id: 'SPARROW_BATH',
    name: 'Solar Bird Bath',
    category: 'Furniture',
    requiredLevel: 2,
    cost: 250,
    description: 'Circulating fresh water fountain powered by an integrated mini solar cell.',
  },
  {
    id: 'RUSTIC_BENCH',
    name: 'Garden Bench',
    category: 'Furniture',
    requiredLevel: 3,
    cost: 200,
    description: 'Handcrafted timber bench for resting and watching sanctuary wildlife.',
  },
  {
    id: 'CAMPFIRE_PIT',
    name: 'Eco-Briquette Fire Pit',
    category: 'Furniture',
    requiredLevel: 10,
    cost: 400,
    description: 'Clean-burning circular stone pit fueled exclusively by biomass briquettes.',
  },
  {
    id: 'ZEN_STONE',
    name: 'Zen Milestone Boulder',
    category: 'Furniture',
    requiredLevel: 12,
    cost: 350,
    description: 'Engraved granite boulder honoring your personal carbon reduction journey.',
  },

  // Water Conservation Assets (350 - 450 coins)
  {
    id: 'POND_TILE',
    name: 'Lily Pond Tile',
    category: 'Water',
    requiredLevel: 1,
    cost: 350,
    description: 'Ecological mini-pond with floating lily pads and rainwater collection.',
  },
  {
    id: 'WOODEN_BRIDGE_TILE',
    name: 'Garden Footbridge',
    category: 'Water',
    requiredLevel: 5,
    cost: 400,
    description: 'Arched wooden pedestrian bridge spanning across waterway canals.',
  },
  {
    id: 'WATER_WELL',
    name: 'Stone Recharge Well',
    category: 'Water',
    requiredLevel: 10,
    cost: 450,
    description: 'Traditional Gujarati step-well style percolation pit replenishing local water tables.',
  },

  // Energy & Clean Tech (High-Value Showpieces: 300 - 1000+ coins)
  {
    id: 'SOLAR_STREET_LAMP',
    name: 'Solar Lantern Post',
    category: 'Energy',
    requiredLevel: 1,
    cost: 300,
    description: 'Self-powered LED lantern post illuminating walkways with stored solar energy.',
  },
  {
    id: 'SOLAR_PANEL_T1',
    name: 'Mini Solar Flower',
    category: 'Energy',
    requiredLevel: 1,
    cost: 500,
    description: 'Photovoltaic sunflower tracking the sun to generate clean renewable power.',
  },
  {
    id: 'COMPOST_TUMBLER',
    name: 'Organic Compost Tumbler',
    category: 'Energy',
    requiredLevel: 8,
    cost: 500,
    description: 'Aerated dual-chamber drum turning daily kitchen food scraps into rich organic compost.',
  },
  {
    id: 'WINDMILL_RUSTIC',
    name: 'Mini Kinetic Windmill',
    category: 'Energy',
    requiredLevel: 5,
    cost: 750,
    description: 'Micro-wind turbine rotating gracefully in coastal Gujarat breezes.',
  },
  {
    id: 'GREENHOUSE',
    name: 'Glass Greenhouse',
    category: 'Buildings',
    requiredLevel: 8,
    cost: 650,
    description: 'Climate-controlled passive solar glass nursery for sapling propagation.',
  },
  {
    id: 'SPARROW_HOME',
    name: 'Chibi Sparrow Manor',
    category: 'Buildings',
    requiredLevel: 5,
    cost: 800,
    description: 'Delightful multi-level green estate with smoking chimney and solar lanterns.',
  },
  {
    id: 'BIOGAS_DOME',
    name: 'Village Bio-Digester',
    category: 'Energy',
    requiredLevel: 20,
    cost: 1000,
    description: 'Modern anaerobic digestion dome converting organic waste into clean cooking biogas.',
  },
];

export class GardenRepository {
  private gardens = new Map<string, GardenRecord>();
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
    let ready = GardenRepository.schemaReady.get(this.db);
    if (!ready) {
      ready = this.db.query(`
        CREATE TABLE IF NOT EXISTS public.citizen_gardens (
          user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
          placed_tiles JSONB NOT NULL DEFAULT '[]'::jsonb,
          inventory JSONB NOT NULL DEFAULT '[]'::jsonb,
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
      `).then(() => undefined);
      GardenRepository.schemaReady.set(this.db, ready);
    }
    await ready;
  }

  public async findByUserIdAsync(userId: string): Promise<GardenRecord | null> {
    if (!this.db) return this.findByUserId(userId);
    await this.ensureSchema();
    const result = await this.db.query(
      'SELECT user_id, placed_tiles, inventory, updated_at FROM public.citizen_gardens WHERE user_id = $1',
      [userId],
    );
    const row = result.rows[0];
    if (!row) return null;
    return {
      userId: row.user_id,
      placedTiles: row.placed_tiles,
      inventory: row.inventory,
      updatedAt: new Date(row.updated_at).toISOString(),
    };
  }

  public async saveAsync(
    record: GardenRecord,
    options: { expectedUpdatedAt?: string; pointsDelta?: number } = {},
  ): Promise<number | null> {
    if (this.db) {
      await this.ensureSchema();
      const client = await this.db.connect();
      try {
        await client.query('BEGIN');
        let updatedPoints: number | null = null;
        if (options.pointsDelta !== undefined) {
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
        }

        const values = [
          record.userId,
          JSON.stringify(record.placedTiles),
          JSON.stringify(record.inventory),
          record.updatedAt,
        ];
        if (options.expectedUpdatedAt) {
          const result = await client.query(
            `UPDATE public.citizen_gardens
             SET placed_tiles = $2::jsonb, inventory = $3::jsonb,
                 updated_at = GREATEST(clock_timestamp(), updated_at + INTERVAL '1 microsecond')
             WHERE user_id = $1 AND updated_at = $4`,
            [record.userId, JSON.stringify(record.placedTiles), JSON.stringify(record.inventory), options.expectedUpdatedAt],
          );
          if (result.rowCount !== 1) {
            throw new Error('Garden changed during this action. Reload the garden and try again.');
          }
        } else {
          await client.query(
            `INSERT INTO public.citizen_gardens (user_id, placed_tiles, inventory, updated_at)
             VALUES ($1, $2::jsonb, $3::jsonb, $4)
             ON CONFLICT (user_id) DO NOTHING`,
            values,
          );
        }
        await client.query('COMMIT');
        if (updatedPoints !== null) {
          AuthService.getRepository().cachePoints(record.userId, updatedPoints);
        }
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } else if (!this.allowTestMemory) {
      throw new Error('PostgreSQL is required for durable garden state.');
    } else if (options.pointsDelta !== undefined) {
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

  public findByUserId(userId: string): GardenRecord | null {
    const garden = this.gardens.get(userId);
    if (!garden) return null;
    return {
      userId: garden.userId,
      placedTiles: garden.placedTiles.map((t) => ({ ...t })),
      inventory: garden.inventory.map((i) => ({ ...i })),
      updatedAt: garden.updatedAt,
    };
  }

  public save(record: GardenRecord): GardenRecord {
    this.gardens.set(record.userId, {
      userId: record.userId,
      placedTiles: record.placedTiles.map((t) => ({ ...t })),
      inventory: record.inventory.map((i) => ({ ...i })),
      updatedAt: record.updatedAt,
    });
    return record;
  }

  public clear(): void {
    this.gardens.clear();
  }
}

export class GardenService {
  private static repository = new GardenRepository();

  public static configure(db: Pool | null, allowTestMemory: boolean): void {
    this.repository.configure(db, allowTestMemory);
  }

  public static getRepository(): GardenRepository {
    return this.repository;
  }

  /**
   * Calculate grid dimension based strictly on verified mascot level
   */
  public static getGridDimensionForLevel(level: number): number {
    if (level >= 90) return 10;
    if (level >= 75) return 8;
    if (level >= 50) return 7;
    if (level >= 40) return 6;
    if (level >= 25) return 5;
    if (level >= 10) return 4;
    return 3; // level 1-9
  }

  /**
   * Get or initialize citizen's garden sanctuary
   */
  public static async getOrCreateGarden(userId: string): Promise<GardenRecord> {
    let garden = await this.repository.findByUserIdAsync(userId);

    if (!garden) {
      garden = {
        userId,
        placedTiles: [],
        inventory: [],
        updatedAt: new Date().toISOString(),
      };
      await this.repository.saveAsync(garden);
      garden = await this.repository.findByUserIdAsync(userId) ?? garden;
    }

    return garden;
  }

  /**
   * Fetch full garden sanctuary state
   */
  public static async getGardenState(userId: string): Promise<GardenStateResponse> {
    const garden = await this.getOrCreateGarden(userId);
    const mascot = await MascotService.getOrCreateMascot(userId);
    const user = await AuthService.getRepository().refreshByIdAsync(userId);
    const citizenCoins = user?.points ?? 0;

    const gridSize = this.getGridDimensionForLevel(mascot.level);
    const maxOccupancy = gridSize * gridSize;

    const catalog: GardenCatalogItem[] = MASTER_GARDEN_CATALOG.map((item) => ({
      id: item.id,
      name: item.name,
      category: item.category,
      requiredLevel: item.requiredLevel,
      cost: item.cost,
      description: item.description,
      isUnlocked: mascot.level >= item.requiredLevel,
    }));

    return {
      gridSize,
      mascotLevel: mascot.level,
      maxOccupancy,
      currentOccupiedCount: garden.placedTiles.length,
      citizenCoins,
      placedTiles: garden.placedTiles,
      inventory: garden.inventory,
      catalog,
    };
  }

  /**
   * Pure Preview: Validates tile placement before citizen confirms purchase
   */
  public static async previewTile(userId: string, tileId: string, x: number, y: number, rotation: TileRotation = 0): Promise<PreviewTileResponse> {
    const item = MASTER_GARDEN_CATALOG.find((t) => t.id === tileId);
    if (!item) {
      throw new Error(`Tile '${tileId}' not found in catalog`);
    }

    const mascot = await MascotService.getOrCreateMascot(userId);
    const gridSize = this.getGridDimensionForLevel(mascot.level);
    const garden = await this.getOrCreateGarden(userId);

    const isUnlocked = mascot.level >= item.requiredLevel;
    const isWithinBounds = x >= 0 && x < gridSize && y >= 0 && y < gridSize;
    const isOccupied = garden.placedTiles.some((t) => t.x === x && t.y === y);

    let isValid = true;
    let message = 'Position is valid! Ready to place or purchase.';

    if (!isUnlocked) {
      isValid = false;
      message = `Requires Mascot Level ${item.requiredLevel}. Keep saving CO2 to unlock!`;
    } else if (!isWithinBounds) {
      isValid = false;
      message = `Coordinates (${x}, ${y}) are out of current grid bounds (${gridSize}x${gridSize}). Level up mascot to expand land!`;
    } else if (isOccupied) {
      isValid = false;
      message = `Tile position (${x}, ${y}) is already occupied. Remove or pick another spot!`;
    }

    return {
      isValid,
      message,
      gridSize,
      tile: {
        ...item,
        isUnlocked,
      },
      coordinates: {
        x,
        y,
        rotation,
      },
    };
  }

  /**
   * Purchase tile with Urja Mudra coins and place directly onto grid
   * Concurrency architecture: Atomic verification mimicking Redis Lua script
   */
  public static async buyAndPlace(
    userId: string,
    tileId: string,
    x: number,
    y: number,
    rotation: TileRotation = 0
  ): Promise<GardenActionResponse> {
    const item = MASTER_GARDEN_CATALOG.find((t) => t.id === tileId);
    if (!item) {
      throw new Error(`Tile '${tileId}' not found in master catalog`);
    }

    const mascot = await MascotService.getOrCreateMascot(userId);
    if (mascot.level < item.requiredLevel) {
      throw new Error(`Requires Mascot Level ${item.requiredLevel}. Keep reducing emissions to unlock!`);
    }

    const gridSize = this.getGridDimensionForLevel(mascot.level);
    if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) {
      throw new Error(`Coordinate (${x}, ${y}) is outside unlocked grid size (${gridSize}x${gridSize})`);
    }

    const garden = await this.getOrCreateGarden(userId);
    if (garden.placedTiles.some((t) => t.x === x && t.y === y)) {
      throw new Error(`Coordinate (${x}, ${y}) is already occupied`);
    }

    const authRepo = AuthService.getRepository();
    const user = await authRepo.refreshByIdAsync(userId);
    if (!user) {
      throw new Error('Citizen not found');
    }

    if (user.points < item.cost) {
      throw new Error(`Insufficient Urja Mudra! Required: ${item.cost}, Available: ${user.points}`);
    }

    const expectedUpdatedAt = garden.updatedAt;

    const newPlacedTile: PlacedTile = {
      instanceId: crypto.randomUUID(),
      tileId: item.id,
      name: item.name,
      category: item.category,
      x,
      y,
      rotation,
      purchasedPrice: item.cost,
      placedAt: new Date().toISOString(),
    };

    garden.placedTiles.push(newPlacedTile);
    garden.updatedAt = new Date().toISOString();
    const remainingCoins = await this.repository.saveAsync(garden, {
      expectedUpdatedAt,
      pointsDelta: -item.cost,
    });

    // Publish event for RabbitMQ async write-behind worker
    this.emitWriteBehindEvent('garden.tile_placed', {
      userId,
      tile: newPlacedTile,
    });

    return {
      success: true,
      message: `Successfully built '${item.name}' at (${x}, ${y}) for ${item.cost} Urja Mudra!`,
      remainingCoins: remainingCoins ?? user.points - item.cost,
      placedTile: newPlacedTile,
      gridSize,
      placedTiles: garden.placedTiles,
      inventory: garden.inventory,
    };
  }

  /**
   * Place an existing tile from inventory onto the grid (0 coins cost)
   */
  public static async placeFromInventory(
    userId: string,
    instanceId: string,
    x: number,
    y: number,
    rotation: TileRotation = 0
  ): Promise<GardenActionResponse> {
    const garden = await this.getOrCreateGarden(userId);
    const inventoryIndex = garden.inventory.findIndex((i) => i.instanceId === instanceId);

    if (inventoryIndex === -1) {
      throw new Error(`Tile instance '${instanceId}' not found in citizen inventory`);
    }

    const inventoryItem = garden.inventory[inventoryIndex]!;
    const mascot = await MascotService.getOrCreateMascot(userId);
    const gridSize = this.getGridDimensionForLevel(mascot.level);

    if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) {
      throw new Error(`Coordinate (${x}, ${y}) is outside unlocked grid size (${gridSize}x${gridSize})`);
    }

    if (garden.placedTiles.some((t) => t.x === x && t.y === y)) {
      throw new Error(`Coordinate (${x}, ${y}) is already occupied`);
    }

    const expectedUpdatedAt = garden.updatedAt;
    // Remove from inventory
    garden.inventory.splice(inventoryIndex, 1);

    const placedTile: PlacedTile = {
      instanceId: inventoryItem.instanceId,
      tileId: inventoryItem.tileId,
      name: inventoryItem.name,
      category: inventoryItem.category,
      x,
      y,
      rotation,
      purchasedPrice: inventoryItem.purchasedPrice,
      placedAt: new Date().toISOString(),
    };

    garden.placedTiles.push(placedTile);
    garden.updatedAt = new Date().toISOString();
    await this.repository.saveAsync(garden, { expectedUpdatedAt });

    const user = await AuthService.getRepository().refreshByIdAsync(userId);

    this.emitWriteBehindEvent('garden.tile_placed_from_inventory', {
      userId,
      tile: placedTile,
    });

    return {
      success: true,
      message: `Placed '${placedTile.name}' from inventory at (${x}, ${y})`,
      remainingCoins: user?.points || 0,
      placedTile,
      gridSize,
      placedTiles: garden.placedTiles,
      inventory: garden.inventory,
    };
  }

  /**
   * Remove tile from grid and preserve it in citizen's inventory
   */
  public static async removeToInventory(userId: string, x: number, y: number): Promise<GardenActionResponse> {
    const garden = await this.getOrCreateGarden(userId);
    const tileIndex = garden.placedTiles.findIndex((t) => t.x === x && t.y === y);

    if (tileIndex === -1) {
      throw new Error(`No placed tile found at coordinate (${x}, ${y})`);
    }

    const removed = garden.placedTiles[tileIndex]!;

    if (removed.tileId === 'SPARROW_HOME') {
      throw new Error('SPARROW_HOME is the sanctuary centerpiece and cannot be removed.');
    }

    const expectedUpdatedAt = garden.updatedAt;
    garden.placedTiles.splice(tileIndex, 1);

    const inventoryItem: InventoryTile = {
      instanceId: removed.instanceId,
      tileId: removed.tileId,
      name: removed.name,
      category: removed.category,
      purchasedPrice: removed.purchasedPrice,
      sellRefundPrice: Math.floor(removed.purchasedPrice * 0.8),
      acquiredAt: new Date().toISOString(),
    };

    garden.inventory.push(inventoryItem);
    garden.updatedAt = new Date().toISOString();
    await this.repository.saveAsync(garden, { expectedUpdatedAt });

    const user = await AuthService.getRepository().refreshByIdAsync(userId);
    const mascot = await MascotService.getOrCreateMascot(userId);
    const gridSize = this.getGridDimensionForLevel(mascot.level);

    this.emitWriteBehindEvent('garden.tile_removed_to_inventory', {
      userId,
      tile: removed,
      inventoryItem,
    });

    return {
      success: true,
      message: `Stored '${removed.name}' in inventory. Available to place back or sell for 80% refund.`,
      remainingCoins: user?.points || 0,
      removedTile: removed,
      gridSize,
      placedTiles: garden.placedTiles,
      inventory: garden.inventory,
    };
  }

  /**
   * Sell an owned tile from inventory back to the system for an 80% coin recovery
   */
  public static async sellTileFromInventory(userId: string, instanceId: string): Promise<GardenActionResponse> {
    const garden = await this.getOrCreateGarden(userId);
    const inventoryIndex = garden.inventory.findIndex((i) => i.instanceId === instanceId);

    if (inventoryIndex === -1) {
      throw new Error(`Tile instance '${instanceId}' not found in inventory. Only inventory tiles can be sold.`);
    }

    const expectedUpdatedAt = garden.updatedAt;
    const itemToSell = garden.inventory.splice(inventoryIndex, 1)[0]!;
    const refundCoins = itemToSell.sellRefundPrice;

    const authRepo = AuthService.getRepository();
    const user = await authRepo.refreshByIdAsync(userId);
    if (!user) {
      throw new Error('Citizen not found');
    }

    garden.updatedAt = new Date().toISOString();
    const newCoinsBalance = await this.repository.saveAsync(garden, {
      expectedUpdatedAt,
      pointsDelta: refundCoins,
    });

    const mascot = await MascotService.getOrCreateMascot(userId);
    const gridSize = this.getGridDimensionForLevel(mascot.level);

    this.emitWriteBehindEvent('garden.tile_sold', {
      userId,
      instanceId,
      refundCoins,
    });

    return {
      success: true,
      message: `Sold '${itemToSell.name}'! Recovered 80% of price (+${refundCoins} Urja Mudra).`,
      remainingCoins: newCoinsBalance ?? user.points + refundCoins,
      refundCoins,
      gridSize,
      placedTiles: garden.placedTiles,
      inventory: garden.inventory,
    };
  }

  /**
   * RabbitMQ Write-Behind Event Dispatcher
   * Asynchronous event publisher for batch-insert worker into PostgreSQL
   */
  private static emitWriteBehindEvent(eventType: string, payload: Record<string, unknown>): void {
    RabbitMQService.enqueueTask(eventType, payload);
    // For unit tests and single-node mode, this is logged or queued non-blockingly
    if (process.env.NODE_ENV === 'debug') {
      console.log(`[RabbitMQ Write-Behind] ${eventType}:`, JSON.stringify(payload));
    }
  }
}
