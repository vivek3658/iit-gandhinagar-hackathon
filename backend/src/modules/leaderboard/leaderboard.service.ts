import type { Pool } from 'pg';
import type {
  CheerResponse,
  GardenVisitorResponse,
  GlobalLeaderboardResponse,
  LeagueLeaderboardResponse,
  LeagueMember,
  LeagueTier,
} from './leaderboard.schema';

type JsonRecord = Record<string, unknown>;

function parseJsonArray(value: unknown): JsonRecord[] {
  const parsed = typeof value === 'string' ? JSON.parse(value) : value;
  return Array.isArray(parsed)
    ? parsed.filter((item): item is JsonRecord => typeof item === 'object' && item !== null)
    : [];
}

function tierForLevel(level: number): LeagueTier {
  if (level >= 75) return 'DIAMOND';
  if (level >= 50) return 'RUBY';
  if (level >= 25) return 'SAPPHIRE';
  if (level >= 10) return 'GOLD';
  if (level >= 5) return 'SILVER';
  return 'BRONZE';
}

function expressionFor(vitality: number): string {
  const hour = new Date().getUTCHours();
  if (hour >= 22 || hour < 5 || vitality < 25) return 'nest';
  if (vitality >= 80) return 'excited';
  if (vitality >= 50) return 'happy';
  return 'resting';
}

function iconForTile(tileId: string): string {
  if (tileId.includes('TREE') || tileId.includes('BANYAN') || tileId.includes('FLOWER')) return '🌳';
  if (tileId.includes('WATER') || tileId.includes('POND') || tileId.includes('WELL')) return '💧';
  if (tileId.includes('SOLAR') || tileId.includes('WIND')) return '☀️';
  if (tileId.includes('BIRD') || tileId.includes('SPARROW')) return '🐦';
  return '🌱';
}

export class LeaderboardService {
  private static instance: LeaderboardService;
  private static schemaReady = new WeakMap<Pool, Promise<void>>();
  private db: Pool | null = null;

  private constructor() {}

  public static getInstance(): LeaderboardService {
    if (!LeaderboardService.instance) {
      LeaderboardService.instance = new LeaderboardService();
    }
    return LeaderboardService.instance;
  }

  public setDbPool(db: Pool | null): void {
    this.db = db;
  }

  private async ensureSchema(): Promise<void> {
    if (!this.db) return;
    let ready = LeaderboardService.schemaReady.get(this.db);
    if (!ready) {
      ready = this.db.query(`
        CREATE TABLE IF NOT EXISTS public.citizen_gardens (
          user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
          placed_tiles JSONB NOT NULL DEFAULT '[]'::jsonb,
          inventory JSONB NOT NULL DEFAULT '[]'::jsonb,
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
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
        CREATE TABLE IF NOT EXISTS public.chapter_completions (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          chapter_id TEXT NOT NULL,
          chapter_version INTEGER NOT NULL,
          coin_reward INTEGER NOT NULL CHECK (coin_reward >= 0),
          completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          UNIQUE (user_id, chapter_id, chapter_version)
        );
        CREATE TABLE IF NOT EXISTS public.waste_game_sessions (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          reward_date DATE NOT NULL,
          idempotency_key TEXT NOT NULL,
          answers JSONB NOT NULL,
          correct_count INTEGER NOT NULL,
          item_count INTEGER NOT NULL,
          coin_reward INTEGER NOT NULL CHECK (coin_reward >= 0),
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          UNIQUE (user_id, reward_date),
          UNIQUE (user_id, idempotency_key)
        );
        CREATE TABLE IF NOT EXISTS public.daily_quests (
          user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          quest_date DATE NOT NULL,
          quests JSONB NOT NULL,
          streak_days INTEGER NOT NULL DEFAULT 0,
          streak_claimed BOOLEAN NOT NULL DEFAULT FALSE,
          PRIMARY KEY (user_id, quest_date)
        );
        CREATE TABLE IF NOT EXISTS public.citizen_cheers (
          visitor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          host_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          PRIMARY KEY (visitor_id, host_id),
          CHECK (visitor_id <> host_id)
        );
      `).then(() => undefined);
      LeaderboardService.schemaReady.set(this.db, ready);
    }
    await ready;
  }

  public async getLeagueLeaderboard(userId: string): Promise<LeagueLeaderboardResponse> {
    if (!this.db) {
      return {
        league: 'BRONZE',
        seasonEndsAt: this.getSeasonEnd(),
        totalMembers: 0,
        yourRank: 0,
        members: [],
      };
    }

    await this.ensureSchema();
    const levelResult = await this.db.query(
      'SELECT COALESCE(level, 1)::integer AS level FROM public.citizen_mascots WHERE user_id = $1',
      [userId],
    );
    const league = tierForLevel(Number(levelResult.rows[0]?.level ?? 1));
    const bands: Record<LeagueTier, [number, number]> = {
      BRONZE: [1, 4],
      SILVER: [5, 9],
      GOLD: [10, 24],
      SAPPHIRE: [25, 49],
      RUBY: [50, 74],
      DIAMOND: [75, 100],
    };
    const [minimumLevel, maximumLevel] = bands[league];
    const result = await this.db.query(
      `WITH activity AS (
         SELECT user_id, SUM(weekly_coins)::integer AS weekly_coins
         FROM (
           SELECT user_id, SUM(coin_reward) AS weekly_coins
           FROM public.chapter_completions
           WHERE completed_at >= date_trunc('week', NOW())
           GROUP BY user_id
           UNION ALL
           SELECT user_id, SUM(coin_reward) AS weekly_coins
           FROM public.waste_game_sessions
           WHERE created_at >= date_trunc('week', NOW())
           GROUP BY user_id
         ) earned
         GROUP BY user_id
       )
       SELECT u.id, u.name, u.avatar_url, COALESCE(u.district, '') AS district,
              COALESCE(m.level, 1)::integer AS mascot_level,
              COALESCE(m.name, 'Chirpy') AS mascot_name,
              COALESCE(m.vitality, 85)::integer AS vitality,
              COALESCE(m.equipped, '{}'::jsonb) AS equipped,
              COALESCE(a.weekly_coins, 0)::integer AS weekly_coins,
              COALESCE((
                SELECT d.streak_days FROM public.daily_quests d
                WHERE d.user_id = u.id AND d.quest_date >= CURRENT_DATE - 1
                ORDER BY d.quest_date DESC LIMIT 1
              ), 0)::integer AS streak_days,
              COALESCE(g.placed_tiles, '[]'::jsonb) AS placed_tiles
       FROM public.users u
       JOIN activity a ON a.user_id = u.id
       LEFT JOIN public.citizen_mascots m ON m.user_id = u.id
       LEFT JOIN public.citizen_gardens g ON g.user_id = u.id
       WHERE u.deleted_at IS NULL
         AND a.weekly_coins > 0
         AND COALESCE(m.level, 1) BETWEEN $1 AND $2
       ORDER BY a.weekly_coins DESC, u.id
       LIMIT 100`,
      [minimumLevel, maximumLevel],
    );

    const members: LeagueMember[] = result.rows.map((row, index) => {
      const slots = parseJsonArray(row.placed_tiles).map((tile) => {
        const tileId = String(tile.tileId ?? 'unknown');
        return {
          x: Number(tile.x ?? 0),
          z: Number(tile.y ?? 0),
          id: tileId,
          name: String(tile.name ?? tileId),
          icon: iconForTile(tileId),
          rotation: Number(tile.rotation ?? 0),
        };
      });
      const equipped = typeof row.equipped === 'string' ? JSON.parse(row.equipped) : row.equipped;
      const mascotLevel = Number(row.mascot_level);
      const weeklyCoins = Number(row.weekly_coins);
      const status: LeagueMember['status'] =
        index < 3 ? 'PROMOTING' : result.rows.length > 5 && index >= result.rows.length - 2 ? 'DEMOTING' : 'SAFE';
      return {
        rank: index + 1,
        citizenId: String(row.id),
        name: String(row.name),
        avatarUrl: row.avatar_url ?? null,
        district: String(row.district),
        weeklyCoins,
        streakDays: Number(row.streak_days),
        status,
        isCurrentUser: String(row.id) === userId,
        mascotSnapshot: {
          name: String(row.mascot_name),
          level: mascotLevel,
          expression: expressionFor(Number(row.vitality)),
          head: equipped.head ?? null,
          face: equipped.face ?? null,
          neck: equipped.neck ?? null,
          held: equipped.held ?? null,
        },
        gardenSnapshot: {
          islandLevel: mascotLevel,
          placedTilesCount: slots.length,
          previewEmoji: slots[1]?.icon ?? '🏡',
          slots,
        },
      };
    });
    const currentMember = members.find((member) => member.citizenId === userId);

    return {
      league,
      seasonEndsAt: this.getSeasonEnd(),
      totalMembers: members.length,
      yourRank: currentMember?.rank ?? 0,
      members,
    };
  }

  private getSeasonEnd(): string {
    const now = new Date();
    const daysUntilSunday = (7 - now.getUTCDay()) % 7;
    return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + daysUntilSunday, 23, 59, 59, 999)).toISOString();
  }

  public async getGlobalLeaderboard(): Promise<GlobalLeaderboardResponse> {
    if (!this.db) return { municipalRankings: [], topCitizens: [] };
    await this.ensureSchema();
    const result = await this.db.query(
      `SELECT u.id, u.name, u.avatar_url, COALESCE(u.district, '') AS district,
              m.current_exp, m.level
       FROM public.citizen_mascots m
       JOIN public.users u ON u.id = m.user_id
       WHERE u.deleted_at IS NULL AND m.current_exp > 0
       ORDER BY m.current_exp DESC, u.id
       LIMIT 10`,
    );
    return {
      municipalRankings: [],
      topCitizens: result.rows.map((row, index) => ({
        rank: index + 1,
        citizenId: String(row.id),
        name: String(row.name),
        avatarUrl: row.avatar_url ?? null,
        district: String(row.district),
        totalCo2SavedKg: Number(row.current_exp) / 100,
        mascotLevel: Number(row.level),
        badgeTitle: index === 0 ? 'Gujarat Solar Guardian' : index < 3 ? 'Mission LiFE Champion' : 'Eco Ambassador',
      })),
    };
  }

  public async getVisitorGarden(citizenId: string): Promise<GardenVisitorResponse | null> {
    if (!this.db) return null;
    await this.ensureSchema();
    const result = await this.db.query(
      `SELECT u.id, u.name, u.avatar_url, COALESCE(u.district, '') AS district,
              COALESCE(u.ward, '') AS ward, COALESCE(m.name, 'Chirpy') AS mascot_name,
              COALESCE(m.level, 1)::integer AS mascot_level,
              COALESCE(m.vitality, 85)::integer AS vitality,
              COALESCE(m.equipped, '{}'::jsonb) AS equipped,
              COALESCE(m.current_exp, 0)::integer AS current_exp,
              COALESCE(g.placed_tiles, '[]'::jsonb) AS placed_tiles,
              COALESCE((
                SELECT COUNT(*) FROM public.citizen_cheers c
                WHERE c.host_id = u.id
              ), 0)::integer AS cheers_received,
              COALESCE((
                SELECT d.streak_days FROM public.daily_quests d
                WHERE d.user_id = u.id AND d.quest_date >= CURRENT_DATE - 1
                ORDER BY d.quest_date DESC LIMIT 1
              ), 0)::integer AS streak_days
       FROM public.users u
       LEFT JOIN public.citizen_mascots m ON m.user_id = u.id
       LEFT JOIN public.citizen_gardens g ON g.user_id = u.id
       WHERE u.id = $1 AND u.deleted_at IS NULL`,
      [citizenId],
    );
    const row = result.rows[0];
    if (!row) return null;
    const level = Number(row.mascot_level);
    const vitality = Number(row.vitality);
    const equipped = typeof row.equipped === 'string' ? JSON.parse(row.equipped) : row.equipped;
    const slots = parseJsonArray(row.placed_tiles).map((tile) => {
      const tileId = String(tile.tileId ?? 'unknown');
      return {
        x: Number(tile.x ?? 0),
        z: Number(tile.y ?? 0),
        id: tileId,
        name: String(tile.name ?? tileId),
        icon: iconForTile(tileId),
        rotation: Number(tile.rotation ?? 0),
      };
    });
    return {
      citizen: {
        id: String(row.id),
        name: String(row.name),
        avatarUrl: row.avatar_url ?? null,
        district: String(row.district),
        ward: String(row.ward),
        streakDays: Number(row.streak_days),
        totalCo2SavedKg: Number(row.current_exp) / 100,
        cheersReceived: Number(row.cheers_received),
      },
      mascot: {
        name: String(row.mascot_name),
        level,
        vitality,
        mood: vitality >= 80 ? 'EXCITED' : vitality >= 50 ? 'HAPPY' : vitality >= 25 ? 'DROOPY' : 'SLEEPY',
        expression: expressionFor(vitality),
        equipped: {
          head: equipped.head ?? null,
          face: equipped.face ?? null,
          neck: equipped.neck ?? null,
          held: equipped.held ?? null,
        },
      },
      garden: {
        islandLevel: level,
        placedTilesCount: slots.length,
        slots,
      },
    };
  }

  public async cheerCitizen(visitorId: string, hostCitizenId: string): Promise<CheerResponse | null> {
    if (!this.db) return null;
    if (visitorId === hostCitizenId) throw new Error('You cannot cheer your own garden.');
    await this.ensureSchema();
    const hostResult = await this.db.query(
      'SELECT name FROM public.users WHERE id = $1 AND deleted_at IS NULL',
      [hostCitizenId],
    );
    const host = hostResult.rows[0];
    if (!host) return null;
    await this.db.query(
      `INSERT INTO public.citizen_cheers (visitor_id, host_id)
       VALUES ($1, $2)
       ON CONFLICT (visitor_id, host_id) DO NOTHING`,
      [visitorId, hostCitizenId],
    );
    const countResult = await this.db.query(
      'SELECT COUNT(*)::integer AS total FROM public.citizen_cheers WHERE host_id = $1',
      [hostCitizenId],
    );
    return {
      success: true,
      message: `Cheered ${String(host.name)}!`,
      coinsEarned: 0,
      totalCheersReceived: Number(countResult.rows[0]?.total ?? 0),
    };
  }
}
