import { Type, type Static } from '@sinclair/typebox';

export const LeagueTierSchema = Type.Union([
  Type.Literal('BRONZE'),
  Type.Literal('SILVER'),
  Type.Literal('GOLD'),
  Type.Literal('SAPPHIRE'),
  Type.Literal('RUBY'),
  Type.Literal('DIAMOND'),
]);

export type LeagueTier = Static<typeof LeagueTierSchema>;

export const LeagueMemberStatusSchema = Type.Union([
  Type.Literal('PROMOTING'),
  Type.Literal('SAFE'),
  Type.Literal('DEMOTING'),
]);

export const MascotSnapshotSchema = Type.Object({
  name: Type.String(),
  level: Type.Number(),
  expression: Type.String(),
  head: Type.Union([Type.String(), Type.Null()]),
  face: Type.Union([Type.String(), Type.Null()]),
  neck: Type.Union([Type.String(), Type.Null()]),
  held: Type.Union([Type.String(), Type.Null()]),
});

export const GardenSlotSnapshotSchema = Type.Object({
  x: Type.Number(),
  z: Type.Number(),
  id: Type.String(),
  name: Type.String(),
  icon: Type.String(),
  rotation: Type.Number(),
});

export const GardenSnapshotSchema = Type.Object({
  islandLevel: Type.Number(),
  placedTilesCount: Type.Number(),
  previewEmoji: Type.String(),
  slots: Type.Array(GardenSlotSnapshotSchema),
});

export const LeagueMemberSchema = Type.Object({
  rank: Type.Number({ minimum: 1 }),
  citizenId: Type.String(),
  name: Type.String(),
  avatarUrl: Type.Union([Type.String(), Type.Null()]),
  district: Type.String(),
  weeklyExp: Type.Number(),
  streakDays: Type.Number(),
  status: LeagueMemberStatusSchema,
  isCurrentUser: Type.Boolean(),
  mascotSnapshot: MascotSnapshotSchema,
  gardenSnapshot: GardenSnapshotSchema,
});

export type LeagueMember = Static<typeof LeagueMemberSchema>;

export const LeagueLeaderboardResponseSchema = Type.Object({
  league: LeagueTierSchema,
  seasonEndsAt: Type.String(),
  totalMembers: Type.Number(),
  yourRank: Type.Number(),
  members: Type.Array(LeagueMemberSchema),
});

export type LeagueLeaderboardResponse = Static<typeof LeagueLeaderboardResponseSchema>;

export const MunicipalRankSchema = Type.Object({
  rank: Type.Number(),
  district: Type.String(),
  totalCo2SavedTonnes: Type.Number(),
  activeCitizens: Type.Number(),
  primaryEnergyMode: Type.String(),
});

export const GlobalCitizenRankSchema = Type.Object({
  rank: Type.Number(),
  citizenId: Type.String(),
  name: Type.String(),
  avatarUrl: Type.Union([Type.String(), Type.Null()]),
  district: Type.String(),
  totalCo2SavedKg: Type.Number(),
  mascotLevel: Type.Number(),
  badgeTitle: Type.String(),
});

export const GlobalLeaderboardResponseSchema = Type.Object({
  municipalRankings: Type.Array(MunicipalRankSchema),
  topCitizens: Type.Array(GlobalCitizenRankSchema),
});

export type GlobalLeaderboardResponse = Static<typeof GlobalLeaderboardResponseSchema>;

export const GardenVisitorResponseSchema = Type.Object({
  citizen: Type.Object({
    id: Type.String(),
    name: Type.String(),
    avatarUrl: Type.Union([Type.String(), Type.Null()]),
    district: Type.String(),
    ward: Type.String(),
    streakDays: Type.Number(),
    totalCo2SavedKg: Type.Number(),
  }),
  mascot: Type.Object({
    name: Type.String(),
    level: Type.Number(),
    vitality: Type.Number(),
    mood: Type.String(),
    expression: Type.String(),
    equipped: Type.Object({
      head: Type.Union([Type.String(), Type.Null()]),
      face: Type.Union([Type.String(), Type.Null()]),
      neck: Type.Union([Type.String(), Type.Null()]),
      held: Type.Union([Type.String(), Type.Null()]),
    }),
  }),
  garden: Type.Object({
    islandLevel: Type.Number(),
    placedTilesCount: Type.Number(),
    slots: Type.Array(GardenSlotSnapshotSchema),
  }),
});

export type GardenVisitorResponse = Static<typeof GardenVisitorResponseSchema>;

export const CheerResponseSchema = Type.Object({
  success: Type.Boolean(),
  message: Type.String(),
  coinsEarned: Type.Number(),
  totalCheersReceived: Type.Number(),
});

export type CheerResponse = Static<typeof CheerResponseSchema>;
