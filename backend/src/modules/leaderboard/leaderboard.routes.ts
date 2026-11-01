import type { FastifyPluginAsync } from 'fastify';
import { Type } from '@sinclair/typebox';
import { LeaderboardController } from './leaderboard.controller';
import {
  CheerResponseSchema,
  GardenVisitorResponseSchema,
  GlobalLeaderboardResponseSchema,
  LeagueLeaderboardResponseSchema,
} from './leaderboard.schema';

export const leaderboardRoutes: FastifyPluginAsync = async (fastify) => {
  const controller = new LeaderboardController();

  // 1. Get Competitive Duolingo-style League Leaderboard
  fastify.get(
    '/league',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Leaderboard'],
        summary: 'Get weekly Duolingo-style competitive league cohort (Bronze to Diamond)',
        response: {
          200: LeagueLeaderboardResponseSchema,
        },
      },
    },
    controller.getLeagueLeaderboard,
  );

  // 2. Get Global & Gujarat Municipal Leaderboard
  fastify.get(
    '/global',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Leaderboard'],
        summary: 'Get Gujarat municipal city rankings and top 100 all-time eco citizens',
        response: {
          200: GlobalLeaderboardResponseSchema,
        },
      },
    },
    controller.getGlobalLeaderboard,
  );

  // 3. Visit Another Citizen's 3D Garden Island & Sparrow Mascot Snapshot
  fastify.get(
    '/visit/:citizenId',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Leaderboard'],
        summary: 'View public snapshot of another citizen 3D island, layout and mascot',
        params: Type.Object({
          citizenId: Type.String(),
        }),
        response: {
          200: GardenVisitorResponseSchema,
        },
      },
    },
    controller.visitGarden,
  );

  // 4. Send Cheer / Applause to another citizen
  fastify.post(
    '/cheer/:citizenId',
    {
      preHandler: [fastify.authenticate],
      schema: {
        tags: ['Leaderboard'],
        summary: 'Send applause to a citizen and receive Urja Mudra coins',
        params: Type.Object({
          citizenId: Type.String(),
        }),
        response: {
          200: CheerResponseSchema,
        },
      },
    },
    controller.cheerCitizen,
  );
};
