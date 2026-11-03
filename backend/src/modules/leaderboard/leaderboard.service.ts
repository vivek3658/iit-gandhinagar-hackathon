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

  public async getLeagueLeaderboard(
    userId: string,
    requestedPage = 1,
    requestedPageSize = 50,
  ): Promise<LeagueLeaderboardResponse> {
    const page = Number.isInteger(requestedPage) ? Math.max(1, requestedPage) : 1;
    const pageSize = Number.isInteger(requestedPageSize)
      ? Math.min(100, Math.max(1, requestedPageSize))
      : 50;
    if (!this.db) {
      return {
        league: 'BRONZE',
        district: 'Unassigned',
        seasonEndsAt: this.getSeasonEnd(),
        page,
        pageSize,
        totalMembers: 0,
        totalPages: 0,
        yourRank: 0,
        members: [],
      };
    }

    await this.ensureSchema();
    const profileResult = await this.db.query(
      `SELECT COALESCE(m.level, 1)::integer AS level,
              COALESCE(NULLIF(BTRIM(u.district), ''), 'Unassigned') AS district
       FROM public.users u
       LEFT JOIN public.citizen_mascots m ON m.user_id = u.id
       WHERE u.id = $1 AND u.deleted_at IS NULL`,
      [userId],
    );
    const profile = profileResult.rows[0];
    if (!profile) {
      return {
        league: 'BRONZE',
        district: 'Unassigned',
        seasonEndsAt: this.getSeasonEnd(),
        page,
        pageSize,
        totalMembers: 0,
        totalPages: 0,
        yourRank: 0,
        members: [],
      };
    }
    const league = tierForLevel(Number(profile?.level ?? 1));
    const district = String(profile.district);
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
         SELECT d.user_id,
                SUM(COALESCE((quest.value->>'estimatedCo2eKg')::numeric, 0)) AS estimated_weekly_co2e_kg
         FROM public.daily_quests d
         CROSS JOIN LATERAL jsonb_array_elements(d.quests) AS quest(value)
         WHERE d.quest_date >= date_trunc('week', NOW() AT TIME ZONE 'UTC')::date
           AND quest.value->>'isClaimed' = 'true'
         GROUP BY d.user_id
       ), ranked AS (
         SELECT u.id, u.name, u.avatar_url,
                COALESCE(NULLIF(BTRIM(u.district), ''), 'Unassigned') AS district,
                COALESCE(m.level, 1)::integer AS mascot_level,
                COALESCE(m.name, 'Chirpy') AS mascot_name,
                COALESCE(m.vitality, 85)::integer AS vitality,
                COALESCE(m.equipped, '{}'::jsonb) AS equipped,
                COALESCE(a.estimated_weekly_co2e_kg, 0)::numeric AS estimated_weekly_co2e_kg,
                COALESCE((
                  SELECT d.streak_days FROM public.daily_quests d
                  WHERE d.user_id = u.id AND d.quest_date >= CURRENT_DATE - 1
                  ORDER BY d.quest_date DESC LIMIT 1
                ), 0)::integer AS streak_days,
                COALESCE(g.placed_tiles, '[]'::jsonb) AS placed_tiles,
                ROW_NUMBER() OVER (
                  ORDER BY COALESCE(a.estimated_weekly_co2e_kg, 0) DESC, u.id
                )::integer AS rank,
                COUNT(*) OVER()::integer AS total_members
         FROM public.users u
         LEFT JOIN activity a ON a.user_id = u.id
         LEFT JOIN public.citizen_mascots m ON m.user_id = u.id
         LEFT JOIN public.citizen_gardens g ON g.user_id = u.id
         WHERE u.deleted_at IS NULL
           AND LOWER(COALESCE(NULLIF(BTRIM(u.district), ''), 'unassigned')) = LOWER(BTRIM($3))
           AND COALESCE(m.level, 1) BETWEEN $1 AND $2
       )
       SELECT * FROM ranked
       WHERE (rank > $4 AND rank <= $5)
          OR id = $6
       ORDER BY rank`,
      [minimumLevel, maximumLevel, district, (page - 1) * pageSize, page * pageSize, userId],
    );

    const members: LeagueMember[] = result.rows.map((row) => {
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
      const estimatedWeeklyCo2eKg = Number(row.estimated_weekly_co2e_kg);
      const rank = Number(row.rank);
      const totalMembers = Number(row.total_members);
      const status: LeagueMember['status'] =
        rank <= 3 ? 'PROMOTING' : totalMembers > 5 && rank > totalMembers - 2 ? 'DEMOTING' : 'SAFE';
      return {
        rank,
        citizenId: String(row.id),
        name: String(row.name),
        avatarUrl: row.avatar_url ?? null,
        district: String(row.district),
        estimatedWeeklyCo2eKg,
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
    const totalMembers = Number(result.rows[0]?.total_members ?? 0);
    const currentMember = members.find((member) => member.citizenId === userId);

    return {
      league,
      district,
      seasonEndsAt: this.getSeasonEnd(),
      page,
      pageSize,
      totalMembers,
      totalPages: Math.ceil(totalMembers / pageSize),
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
    const municipalResult = await this.db.query(
      `SELECT MIN(BTRIM(u.district)) AS district,
              (SUM((quest.value->>'estimatedCo2eKg')::numeric) / 1000)::numeric AS estimated_co2e_tonnes,
              COUNT(DISTINCT d.user_id)::integer AS active_citizens
       FROM public.daily_quests d
       CROSS JOIN LATERAL jsonb_array_elements(d.quests) AS quest(value)
       JOIN public.users u ON u.id = d.user_id
       WHERE u.deleted_at IS NULL
         AND BTRIM(COALESCE(u.district, '')) <> ''
         AND quest.value->>'isClaimed' = 'true'
         AND COALESCE((quest.value->>'estimatedCo2eKg')::numeric, 0) > 0
       GROUP BY LOWER(BTRIM(u.district))
       ORDER BY SUM((quest.value->>'estimatedCo2eKg')::numeric) DESC, LOWER(BTRIM(u.district))
       LIMIT 100`,
    );
    const citizenResult = await this.db.query(
      `SELECT u.id, u.name, u.avatar_url, COALESCE(NULLIF(BTRIM(u.district), ''), '') AS district,
              COALESCE(SUM((quest.value->>'estimatedCo2eKg')::numeric), 0)::numeric AS estimated_co2e_kg,
              COALESCE(m.level, 1)::integer AS level
       FROM public.daily_quests d
       CROSS JOIN LATERAL jsonb_array_elements(d.quests) AS quest(value)
       JOIN public.users u ON u.id = d.user_id
       LEFT JOIN public.citizen_mascots m ON m.user_id = u.id
       WHERE u.deleted_at IS NULL AND quest.value->>'isClaimed' = 'true'
       GROUP BY u.id, u.name, u.avatar_url, u.district, m.level
       HAVING SUM(COALESCE((quest.value->>'estimatedCo2eKg')::numeric, 0)) > 0
       ORDER BY estimated_co2e_kg DESC, u.id
       LIMIT 100`,
    );
    return {
      municipalRankings: municipalResult.rows.map((row, index) => ({
        rank: index + 1,
        district: String(row.district),
        estimatedCo2eTonnes: Number(row.estimated_co2e_tonnes),
        activeCitizens: Number(row.active_citizens),
      })),
      topCitizens: citizenResult.rows.map((row, index) => ({
        rank: index + 1,
        citizenId: String(row.id),
        name: String(row.name),
        avatarUrl: row.avatar_url ?? null,
        district: String(row.district),
        estimatedCo2eKg: Number(row.estimated_co2e_kg),
        mascotLevel: Number(row.level),
        badgeTitle: index === 0 ? 'CO₂e Leader' : index < 3 ? 'Low-Carbon Champion' : 'Eco Citizen',
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
              COALESCE((
                SELECT SUM(COALESCE((quest.value->>'estimatedCo2eKg')::numeric, 0))
                FROM public.daily_quests d
                CROSS JOIN LATERAL jsonb_array_elements(d.quests) AS quest(value)
                WHERE d.user_id = u.id AND quest.value->>'isClaimed' = 'true'
              ), 0)::numeric AS estimated_co2e_kg,
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
        estimatedCo2eKg: Number(row.estimated_co2e_kg),
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
