import { describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { LeaderboardService } from '../src/modules/leaderboard/leaderboard.service';

describe('CO2e leaderboard scoring', () => {
  it('ranks the weekly city league and municipal standings by estimated CO2e', async () => {
    const calls: Array<{ sql: string; values: unknown[] }> = [];
    const query = async (sql: string, values: unknown[] = []) => {
      calls.push({ sql, values });
      if (sql.includes('SELECT COALESCE(m.level')) {
        return { rows: [{ level: 2, district: 'Ahmedabad' }] };
      }
      if (sql.includes('WITH activity AS')) {
        return {
          rows: [
            {
              id: 'citizen-1',
              name: 'Asha',
              avatar_url: null,
              district: 'Ahmedabad',
              mascot_level: 2,
              mascot_name: 'Chirpy',
              vitality: 85,
              equipped: {},
              estimated_weekly_co2e_kg: '0',
              streak_days: 2,
              placed_tiles: [],
              rank: 80,
              total_members: 100,
            },
          ],
        };
      }
      if (sql.includes('WITH city_scores AS')) {
        return {
          rows: [
            {
              district: 'Ahmedabad',
              estimated_co2e_tonnes: '0',
              active_citizens: 0,
            },
            { district: 'Surat', estimated_co2e_tonnes: '0.02', active_citizens: 1 },
          ],
        };
      }
      if (sql.includes('estimated_co2e_kg')) {
        return {
          rows: [
            {
              id: 'citizen-1',
              name: 'Asha',
              avatar_url: null,
              district: 'Ahmedabad',
              estimated_co2e_kg: '12.5',
              level: 2,
            },
          ],
        };
      }
      return { rows: [] };
    };
    const db = { query } as unknown as Pool;
    const service = LeaderboardService.getInstance();
    service.setDbPool(db);

    const league = await service.getLeagueLeaderboard('citizen-1', 2, 25);
    const global = await service.getGlobalLeaderboard();

    expect(league.district).toBe('Ahmedabad');
    expect(league.page).toBe(2);
    expect(league.pageSize).toBe(25);
    expect(league.totalMembers).toBe(100);
    expect(league.totalPages).toBe(4);
    expect(league.yourRank).toBe(80);
    expect(league.members[0]).toMatchObject({
      citizenId: 'citizen-1',
      rank: 80,
      estimatedWeeklyCo2eKg: 0,
      isCurrentUser: true,
    });
    expect(calls.find((call) => call.sql.includes('WITH activity AS'))?.values).toEqual([
      1,
      4,
      'Ahmedabad',
      25,
      50,
      'citizen-1',
    ]);
    const leagueQuery = calls.find((call) => call.sql.includes('WITH activity AS'))?.sql ?? '';
    expect(leagueQuery).toContain('LEFT JOIN activity a');
    expect(leagueQuery).toContain('ROW_NUMBER() OVER');
    expect(leagueQuery).toContain('OR id = $6');
    expect(global.municipalRankings[0]).toMatchObject({
      district: 'Ahmedabad',
      estimatedCo2eTonnes: 0,
      activeCitizens: 0,
    });
    expect(global.municipalRankings).toHaveLength(2);
    expect(global.municipalRankings[1].district).toBe('Surat');
    expect(global.topCitizens[0].estimatedCo2eKg).toBe(12.5);
    expect(
      calls.some((call) =>
        call.sql.includes('ORDER BY COALESCE(a.estimated_weekly_co2e_kg, 0) DESC'),
      ),
    ).toBe(true);
    expect(
      calls.some((call) => call.sql.includes('LEFT JOIN public.daily_quests d')),
    ).toBe(
      true,
    );

    service.setDbPool(null);
  });
});
