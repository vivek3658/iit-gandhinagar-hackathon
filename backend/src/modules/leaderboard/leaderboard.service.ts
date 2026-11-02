import type Redis from 'ioredis';
import type {
  CheerResponse,
  GardenVisitorResponse,
  GlobalLeaderboardResponse,
  LeagueLeaderboardResponse,
  LeagueMember,
  LeagueTier,
} from './leaderboard.schema';

interface CitizenSocialRecord {
  id: string;
  name: string;
  avatarUrl: string | null;
  district: string;
  ward: string;
  league: LeagueTier;
  weeklyExp: number;
  totalCo2SavedKg: number;
  streakDays: number;
  cheersReceived: number;
  mascot: {
    name: string;
    level: number;
    vitality: number;
    mood: string;
    expression: string;
    equipped: {
      head: string | null;
      face: string | null;
      neck: string | null;
      held: string | null;
    };
  };
  garden: {
    islandLevel: number;
    slots: Array<{
      x: number;
      z: number;
      id: string;
      name: string;
      icon: string;
      rotation: number;
    }>;
  };
}

export class LeaderboardService {
  private static instance: LeaderboardService;
  private citizens = new Map<string, CitizenSocialRecord>();
  private redis: Redis | null = null;

  private constructor() {}

  public static getInstance(): LeaderboardService {
    if (!LeaderboardService.instance) {
      LeaderboardService.instance = new LeaderboardService();
    }
    return LeaderboardService.instance;
  }

  public setRedisClient(client: Redis | null): void {
    this.redis = client;
    if (this.redis) {
      this.syncToRedis().catch(() => {});
    }
  }

  private async syncToRedis(): Promise<void> {
    if (!this.redis) return;
    try {
      const pipeline = this.redis.pipeline();
      for (const c of this.citizens.values()) {
        pipeline.zadd(`urja:leaderboard:league:${c.league}`, c.weeklyExp, c.id);
        pipeline.zadd('urja:leaderboard:global', c.totalCo2SavedKg, c.id);
        pipeline.hset(`urja:citizen:social:${c.id}`, {
          name: c.name,
          cheersReceived: String(c.cheersReceived),
          totalCo2SavedKg: String(c.totalCo2SavedKg),
          weeklyExp: String(c.weeklyExp),
        });
      }
      await pipeline.exec();
    } catch {
      // Non-fatal
    }
  }

  public getLeagueLeaderboard(userId: string): LeagueLeaderboardResponse {
    const currentUser = this.citizens.get(userId);
    if (!currentUser) {
      return { league: 'BRONZE', seasonEndsAt: this.getSeasonEnd(), totalMembers: 0, yourRank: 0, members: [] };
    }

    // Filter to current league tier
    const cohort = Array.from(this.citizens.values()).filter((c) => c.league === currentUser.league);
    cohort.sort((a, b) => b.weeklyExp - a.weeklyExp);

    const total = cohort.length;
    let yourRank = 1;

    const members: LeagueMember[] = cohort.map((c, idx) => {
      const rank = idx + 1;
      if (c.id === userId) yourRank = rank;

      let status: 'PROMOTING' | 'SAFE' | 'DEMOTING' = 'SAFE';
      if (rank <= 3 || (total > 6 && rank <= 4)) {
        status = 'PROMOTING';
      } else if (total > 5 && rank >= total - 1) {
        status = 'DEMOTING';
      }

      return {
        rank,
        citizenId: c.id,
        name: c.name,
        avatarUrl: c.avatarUrl,
        district: c.district,
        weeklyExp: c.weeklyExp,
        streakDays: c.streakDays,
        status,
        isCurrentUser: c.id === userId,
        mascotSnapshot: {
          name: c.mascot.name,
          level: c.mascot.level,
          expression: c.mascot.expression,
          head: c.mascot.equipped.head,
          face: c.mascot.equipped.face,
          neck: c.mascot.equipped.neck,
          held: c.mascot.equipped.held,
        },
        gardenSnapshot: {
          islandLevel: c.garden.islandLevel,
          placedTilesCount: c.garden.slots.length,
          previewEmoji: c.garden.slots[1]?.icon || '🏡',
          slots: c.garden.slots,
        },
      };
    });

    return {
      league: currentUser.league,
      seasonEndsAt: this.getSeasonEnd(),
      totalMembers: members.length,
      yourRank,
      members,
    };
  }

  private getSeasonEnd(): string {
    const now = new Date();
    const daysUntilSunday = (7 - now.getDay()) % 7 || 7;
    return new Date(now.getFullYear(), now.getMonth(), now.getDate() + daysUntilSunday, 23, 59, 59).toISOString();
  }

  public getGlobalLeaderboard(): GlobalLeaderboardResponse {
    const allCitizens = Array.from(this.citizens.values());
    allCitizens.sort((a, b) => b.totalCo2SavedKg - a.totalCo2SavedKg);

    const topCitizens = allCitizens.slice(0, 10).map((c, i) => ({
      rank: i + 1,
      citizenId: c.id,
      name: c.name,
      avatarUrl: c.avatarUrl,
      district: c.district,
      totalCo2SavedKg: c.totalCo2SavedKg,
      mascotLevel: c.mascot.level,
      badgeTitle: i === 0 ? 'Gujarat Solar Guardian 🏆' : i < 3 ? 'Mission LiFE Champion 🥇' : 'Eco Ambassador 🌿',
    }));

    return { municipalRankings: [], topCitizens };
  }

  public getVisitorGarden(citizenId: string): GardenVisitorResponse | null {
    const citizen = this.citizens.get(citizenId);
    if (!citizen) return null;

    return {
      citizen: {
        id: citizen.id,
        name: citizen.name,
        avatarUrl: citizen.avatarUrl,
        district: citizen.district,
        ward: citizen.ward,
        streakDays: citizen.streakDays,
        totalCo2SavedKg: citizen.totalCo2SavedKg,
      },
      mascot: {
        name: citizen.mascot.name,
        level: citizen.mascot.level,
        vitality: citizen.mascot.vitality,
        mood: citizen.mascot.mood,
        expression: citizen.mascot.expression,
        equipped: citizen.mascot.equipped,
      },
      garden: {
        islandLevel: citizen.garden.islandLevel,
        placedTilesCount: citizen.garden.slots.length,
        slots: citizen.garden.slots,
      },
    };
  }

  public cheerCitizen(_visitorId: string, hostCitizenId: string): CheerResponse | null {
    const host = this.citizens.get(hostCitizenId);
    if (!host) return null;

    host.cheersReceived += 1;

    // Atomic increment in Redis for instant synchronization
    if (this.redis) {
      this.redis.hincrby(`urja:citizen:social:${hostCitizenId}`, 'cheersReceived', 1).catch(() => {});
    }

    return {
      success: true,
      message: `👏 Cheered ${host.name}!`,
      coinsEarned: 0,
      totalCheersReceived: host.cheersReceived,
    };
  }
}
