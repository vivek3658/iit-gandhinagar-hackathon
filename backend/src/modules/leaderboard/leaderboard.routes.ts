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
        security: [{ bearerAuth: [] }],
        summary: 'Get the weekly city and mascot-tier league ranked by estimated CO2e',
        querystring: Type.Object({
          page: Type.Optional(Type.Integer({ minimum: 1, maximum: 100000 })),
          pageSize: Type.Optional(Type.Integer({ minimum: 1, maximum: 100 })),
        }),
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
        security: [{ bearerAuth: [] }],
        summary: 'Get estimated Gujarat city rankings and top 100 all-time citizens by CO2e',
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
        security: [{ bearerAuth: [] }],
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
        security: [{ bearerAuth: [] }],
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
