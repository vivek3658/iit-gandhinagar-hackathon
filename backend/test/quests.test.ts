import { describe, expect, it, vi } from 'vitest';
import type { Pool } from 'pg';
import { QuestsService } from '../src/modules/quests/quests.service';

describe('Daily quests PostgreSQL persistence', () => {
  it('keeps task claims across service instances and resets tasks on the next UTC day', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-11-02T12:00:00.000Z'));

    const storedDays = new Map<
      string,
      {
        userId: string;
        date: string;
        quests: unknown[];
        streakDays: number;
        streakClaimed: boolean;
      }
    >();
    let points = 50;
    const query = async (sql: string, values: unknown[] = []) => {
      if (sql.includes('INSERT INTO daily_quests')) {
        const userId = String(values[0]);
        const date = String(values[1]);
        const key = `${userId}:${date}`;
        if (!storedDays.has(key)) {
          const previousDay = new Date(`${date}T00:00:00.000Z`);
          previousDay.setUTCDate(previousDay.getUTCDate() - 1);
          const previous = storedDays.get(`${userId}:${previousDay.toISOString().slice(0, 10)}`);
          storedDays.set(key, {
            userId,
            date,
            quests: JSON.parse(String(values[2])) as unknown[],
            streakDays: previous?.streakDays || 0,
            streakClaimed: false,
          });
        }
        return { rows: [] };
      }

      if (sql.includes('SELECT quests, streak_days')) {
        const row = storedDays.get(`${String(values[0])}:${String(values[1])}`);
        return {
          rows: row
            ? [
                {
                  quests: row.quests,
                  streak_days: row.streakDays,
                  streak_claimed: row.streakClaimed,
                },
              ]
            : [],
        };
      }

      if (sql.includes('UPDATE daily_quests')) {
        const row = storedDays.get(`${String(values[0])}:${String(values[1])}`);
        if (row) {
          row.quests = JSON.parse(String(values[2])) as unknown[];
          row.streakDays = Number(values[3]);
          row.streakClaimed = true;
        }
        return { rows: [] };
      }
      if (sql.includes('UPDATE users SET points')) {
        points += Number(values[1]);
        return { rows: [{ points }] };
      }

      return { rows: [] };
    };
    const db = {
      query,
      connect: async () => ({ query, release: () => undefined }),
    } as unknown as Pool;

    try {
      const firstInstance = new QuestsService(db);
      const firstDay = await firstInstance.getDailyQuests('user-1');
      expect(firstDay.quests).toHaveLength(5);

      const firstClaim = await firstInstance.claimQuest('user-1', firstDay.quests[0].id);
      expect(firstClaim.coinsAwarded).toBe(20);
      expect(firstClaim.xpAwarded).toBe(0);
      expect(firstClaim.impactCreditedKg).toBe(0);
      expect(firstClaim.evidenceTier).toBe('SELF_REPORTED');
      expect(firstClaim.newMascotVitality).toBeNull();
      expect(points).toBe(70);
      await firstInstance.claimQuest('user-1', firstDay.quests[1].id);
      expect(points).toBe(85);
      const recovered = await new QuestsService(db).getDailyQuests('user-1');
      expect(recovered.quests[0].isClaimed).toBe(true);
      expect(recovered.quests[1].isClaimed).toBe(true);
      expect(recovered.streakDays).toBe(1);

      await expect(
        new QuestsService(db).claimQuest('user-1', firstDay.quests[0].id),
      ).rejects.toThrow('already been claimed');
      expect(points).toBe(85);

      vi.setSystemTime(new Date('2026-11-03T00:00:01.000Z'));
      const nextDay = await new QuestsService(db).getDailyQuests('user-1');
      expect(nextDay.quests.every((quest) => !quest.isClaimed)).toBe(true);
      expect(nextDay.streakDays).toBe(1);
    } finally {
      vi.useRealTimers();
    }
  });

  it('stores a transparent commute estimate from user-confirmed trip logs without crediting impact', async () => {
    let quests: unknown[] = [];
    const query = async (sql: string, values: unknown[] = []) => {
      if (sql.includes('INSERT INTO daily_quests')) {
        quests = JSON.parse(String(values[2])) as unknown[];
        return { rows: [] };
      }
      if (sql.includes('SELECT quests, streak_days')) {
        return {
          rows: [
            {
              quests,
              streak_days: 0,
              streak_claimed: false,
            },
          ],
        };
      }
      if (sql.includes('FROM public.confirmed_trips')) {
        return { rows: [{ estimated_co2e_kg: '0.425' }] };
      }
      if (sql.includes('UPDATE daily_quests')) {
        quests = JSON.parse(String(values[2])) as unknown[];
        return { rows: [] };
      }
      if (sql.includes('UPDATE users SET points')) {
        return { rows: [{ points: 25 }] };
      }
      return { rows: [] };
    };
    const db = {
      query,
      connect: async () => ({ query, release: () => undefined }),
    } as unknown as Pool;

    const result = await new QuestsService(db).claimQuest('user-1', 'q_green_commute');

    expect(result.estimatedCo2eKg).toBe(0.43);
    expect(result.impactCreditedKg).toBe(0);
    expect(result.message).toContain('not verified or credited impact');
  });
});
