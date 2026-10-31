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

  private constructor() {
    this.seedCitizens();
  }

  public static getInstance(): LeaderboardService {
    if (!LeaderboardService.instance) {
      LeaderboardService.instance = new LeaderboardService();
    }
    return LeaderboardService.instance;
  }

  private seedCitizens(): void {
    const seedData: CitizenSocialRecord[] = [
      {
        id: 'cit_priya_ahmedabad',
        name: 'Priya Patel',
        avatarUrl: null,
        district: 'Ahmedabad',
        ward: 'Navrangpura',
        league: 'GOLD',
        weeklyExp: 340,
        totalCo2SavedKg: 48.2,
        streakDays: 14,
        cheersReceived: 38,
        mascot: {
          name: 'Cheechee',
          level: 4,
          vitality: 95,
          mood: 'EXCITED',
          expression: 'cheering',
          equipped: { head: 'flowers', face: null, neck: 'bow', held: null },
        },
        garden: {
          islandLevel: 2,
          slots: [
            { x: 0, z: 0, id: 'SPARROW_HOME', name: 'Sparrow Eco Home', icon: '🏡', rotation: 0 },
            { x: 0, z: -1, id: 'FLOWER_BED', name: 'Fragrant Flower Bed', icon: '🌷', rotation: 0 },
            { x: 1, z: 0, id: 'SPARROW_BATH', name: 'Bird Bath Fountain', icon: '⛲', rotation: 1 },
            { x: -1, z: 0, id: 'SOLAR_STREET_LAMP', name: 'Solar Lantern Post', icon: '🏮', rotation: 0 },
          ],
        },
      },
      {
        id: 'cit_aarav_surat',
        name: 'Aarav Shah',
        avatarUrl: null,
        district: 'Surat',
        ward: 'Adajan',
        league: 'GOLD',
        weeklyExp: 310,
        totalCo2SavedKg: 44.5,
        streakDays: 11,
        cheersReceived: 29,
        mascot: {
          name: 'Piku',
          level: 3,
          vitality: 88,
          mood: 'HAPPY',
          expression: 'happy',
          equipped: { head: 'straw', face: 'sunnies', neck: null, held: null },
        },
        garden: {
          islandLevel: 2,
          slots: [
            { x: 0, z: 0, id: 'SPARROW_HOME', name: 'Sparrow Eco Home', icon: '🏡', rotation: 0 },
            { x: -1, z: -1, id: 'TREE_LARGE', name: 'Large Apple Tree', icon: '🌳', rotation: 0 },
            { x: 1, z: 1, id: 'SOLAR_STREET_LAMP', name: 'Solar Lantern Post', icon: '🏮', rotation: 2 },
          ],
        },
      },
      {
        id: 'cit_diya_vadodara',
        name: 'Diya Joshi',
        avatarUrl: null,
        district: 'Vadodara',
        ward: 'Alkapuri',
        league: 'GOLD',
        weeklyExp: 290,
        totalCo2SavedKg: 39.8,
        streakDays: 9,
        cheersReceived: 21,
        mascot: {
          name: 'Chirpy',
          level: 3,
          vitality: 82,
          mood: 'HAPPY',
          expression: 'resting',
          equipped: { head: null, face: 'readers', neck: 'plaid', held: null },
        },
        garden: {
          islandLevel: 1,
          slots: [
            { x: 0, z: 0, id: 'SPARROW_HOME', name: 'Sparrow Eco Home', icon: '🏡', rotation: 0 },
            { x: 0, z: 1, id: 'TULSI_KYARO', name: 'Sacred Tulsi Altar', icon: '🌿', rotation: 0 },
            { x: -1, z: 0, id: 'ROCK_BOULDER', name: 'Zen Milestone Boulder', icon: '🪨', rotation: 0 },
          ],
        },
      },
      {
        id: 'cit_manav_rajkot',
        name: 'Manav Mehta',
        avatarUrl: null,
        district: 'Rajkot',
        ward: 'Kalawad Road',
        league: 'GOLD',
        weeklyExp: 260,
        totalCo2SavedKg: 35.1,
        streakDays: 7,
        cheersReceived: 18,
        mascot: {
          name: 'Vira',
          level: 2,
          vitality: 76,
          mood: 'HAPPY',
          expression: 'curious',
          equipped: { head: 'beanie', face: null, neck: 'knit', held: null },
        },
        garden: {
          islandLevel: 1,
          slots: [
            { x: 0, z: 0, id: 'SPARROW_HOME', name: 'Sparrow Eco Home', icon: '🏡', rotation: 0 },
            { x: 1, z: 0, id: 'WINDMILL_RUSTIC', name: 'Old Stone Windmill', icon: '🌬️', rotation: 0 },
          ],
        },
      },
      {
        id: 'cit_ananya_gandhinagar',
        name: 'Ananya Desai',
        avatarUrl: null,
        district: 'Gandhinagar',
        ward: 'Sector 7',
        league: 'GOLD',
        weeklyExp: 240,
        totalCo2SavedKg: 31.4,
        streakDays: 8,
        cheersReceived: 15,
        mascot: {
          name: 'Moti',
          level: 2,
          vitality: 70,
          mood: 'HAPPY',
          expression: 'watering',
          equipped: { head: 'rainhat', face: null, neck: null, held: 'leafbrella' },
        },
        garden: {
          islandLevel: 1,
          slots: [
            { x: 0, z: 0, id: 'SPARROW_HOME', name: 'Sparrow Eco Home', icon: '🏡', rotation: 0 },
            { x: 0, z: -1, id: 'CAMPFIRE_PIT', name: 'Cozy Campfire', icon: '🔥', rotation: 0 },
          ],
        },
      },
      {
        id: 'cit_karan_bhavnagar',
        name: 'Karan Vora',
        avatarUrl: null,
        district: 'Bhavnagar',
        ward: 'Kalanala',
        league: 'GOLD',
        weeklyExp: 195,
        totalCo2SavedKg: 26.0,
        streakDays: 5,
        cheersReceived: 11,
        mascot: {
          name: 'Suraj',
          level: 2,
          vitality: 65,
          mood: 'HAPPY',
          expression: 'thinking',
          equipped: { head: 'acorn', face: null, neck: null, held: null },
        },
        garden: {
          islandLevel: 1,
          slots: [
            { x: 0, z: 0, id: 'SPARROW_HOME', name: 'Sparrow Eco Home', icon: '🏡', rotation: 0 },
            { x: -1, z: 1, id: 'COMPOST_TUMBLER', name: 'Organic Compost Bin', icon: '♻️', rotation: 0 },
          ],
        },
      },
      {
        id: 'cit_neha_surat',
        name: 'Neha Trivedi',
        avatarUrl: null,
        district: 'Surat',
        ward: 'Vesu',
        league: 'GOLD',
        weeklyExp: 160,
        totalCo2SavedKg: 21.8,
        streakDays: 4,
        cheersReceived: 8,
        mascot: {
          name: 'Kiki',
          level: 2,
          vitality: 60,
          mood: 'HAPPY',
          expression: 'happy',
          equipped: { head: null, face: null, neck: 'collar', held: null },
        },
        garden: {
          islandLevel: 1,
          slots: [
            { x: 0, z: 0, id: 'SPARROW_HOME', name: 'Sparrow Eco Home', icon: '🏡', rotation: 0 },
          ],
        },
      },
      {
        id: 'cit_rohit_ahmedabad',
        name: 'Rohit Dave',
        avatarUrl: null,
        district: 'Ahmedabad',
        ward: 'Maninagar',
        league: 'GOLD',
        weeklyExp: 120,
        totalCo2SavedKg: 16.5,
        streakDays: 3,
        cheersReceived: 5,
        mascot: {
          name: 'Chotu',
          level: 1,
          vitality: 55,
          mood: 'DROOPY',
          expression: 'resting',
          equipped: { head: null, face: null, neck: null, held: null },
        },
        garden: {
          islandLevel: 1,
          slots: [
            { x: 0, z: 0, id: 'SPARROW_HOME', name: 'Sparrow Eco Home', icon: '🏡', rotation: 0 },
          ],
        },
      },
    ];

    for (const record of seedData) {
      this.citizens.set(record.id, record);
    }
  }

  public getLeagueLeaderboard(userId: string, currentUserName?: string): LeagueLeaderboardResponse {
    // Check if current user is recorded, or build active entry
    let currentUser = this.citizens.get(userId);
    if (!currentUser) {
      currentUser = {
        id: userId,
        name: currentUserName || 'Gujarat Eco Citizen',
        avatarUrl: null,
        district: 'Ahmedabad',
        ward: 'West Zone',
        league: 'GOLD',
        weeklyExp: 220,
        totalCo2SavedKg: 28.5,
        streakDays: 6,
        cheersReceived: 12,
        mascot: {
          name: 'Cheechee',
          level: 2,
          vitality: 85,
          mood: 'HAPPY',
          expression: 'happy',
          equipped: { head: null, face: null, neck: null, held: null },
        },
        garden: {
          islandLevel: 1,
          slots: [
            { x: 0, z: 0, id: 'SPARROW_HOME', name: 'Sparrow Eco Home', icon: '🏡', rotation: 0 },
          ],
        },
      };
      this.citizens.set(userId, currentUser);
    }

    // Filter to current league tier
    const cohort = Array.from(this.citizens.values()).filter((c) => c.league === currentUser.league);
    // Sort descending by weeklyExp
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

    // End of weekly season: next Sunday midnight
    const now = new Date();
    const daysUntilSunday = (7 - now.getDay()) % 7 || 7;
    const seasonEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate() + daysUntilSunday, 23, 59, 59);

    return {
      league: currentUser.league,
      seasonEndsAt: seasonEnd.toISOString(),
      totalMembers: members.length,
      yourRank,
      members,
    };
  }

  public getGlobalLeaderboard(): GlobalLeaderboardResponse {
    const municipalRankings = [
      {
        rank: 1,
        district: 'Surat',
        totalCo2SavedTonnes: 1420.5,
        activeCitizens: 34200,
        primaryEnergyMode: 'Rooftop Solar & EV BRTS',
      },
      {
        rank: 2,
        district: 'Ahmedabad',
        totalCo2SavedTonnes: 1280.8,
        activeCitizens: 41800,
        primaryEnergyMode: 'Metro Rail & AC 24°C LiFE Habits',
      },
      {
        rank: 3,
        district: 'Vadodara',
        totalCo2SavedTonnes: 890.2,
        activeCitizens: 18400,
        primaryEnergyMode: 'Canal Top Solar & Bio-CNG',
      },
      {
        rank: 4,
        district: 'Rajkot',
        totalCo2SavedTonnes: 620.4,
        activeCitizens: 14900,
        primaryEnergyMode: 'Wind-Solar Hybrid & Rainwater Wells',
      },
      {
        rank: 5,
        district: 'Gandhinagar',
        totalCo2SavedTonnes: 480.9,
        activeCitizens: 11200,
        primaryEnergyMode: '100% LED Green Capital Grid',
      },
      {
        rank: 6,
        district: 'Bhavnagar',
        totalCo2SavedTonnes: 340.1,
        activeCitizens: 8700,
        primaryEnergyMode: 'Coastal Wind & Bio-Composting',
      },
    ];

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

    return {
      municipalRankings,
      topCitizens,
    };
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

  public cheerCitizen(_visitorId: string, hostCitizenId: string): CheerResponse {
    const host = this.citizens.get(hostCitizenId);
    if (host) {
      host.cheersReceived += 1;
    }
    return {
      success: true,
      message: `👏 Cheered ${host?.name || 'citizen'}! Both you and ${host?.name || 'the host'} received +2 Urja Mudra coins!`,
      coinsEarned: 2,
      totalCheersReceived: host?.cheersReceived || 1,
    };
  }
}
