import type { Pool } from 'pg';
import type { ClaimQuestResponse, DailyQuestsResponse, QuestTask } from './quests.schema';

export class QuestRuleError extends Error {}

function isQuestTask(value: unknown): value is QuestTask {
  if (typeof value !== 'object' || value === null) return false;
  const task = value as Record<string, unknown>;
  return (
    typeof task.id === 'string' &&
    typeof task.title === 'string' &&
    typeof task.description === 'string' &&
    ['ENERGY', 'WATER', 'COMMUTE', 'LIFESTYLE'].includes(String(task.category)) &&
    typeof task.coinReward === 'number' &&
    typeof task.isCompleted === 'boolean' &&
    typeof task.isClaimed === 'boolean' &&
    typeof task.icon === 'string'
  );
}

export class QuestsService {
  private readonly userQuests = new Map<string, { date: string; quests: QuestTask[] }>();
  private readonly userStreaks = new Map<string, { date: string; streakDays: number }>();
  private schemaReady: Promise<void> | null = null;

  public constructor(private readonly db: Pool | null) {}

  private getDefaultQuests(): QuestTask[] {
    return [
      {
        id: 'q_ac_24',
        title: 'Sleep at 24°C Comfort Setting',
        description: 'Keep bedroom air conditioner at 24°C with a 4-hour timer overnight.',
        category: 'ENERGY',
        co2SavedKg: 0,
        coinReward: 20,
        xpReward: 0,
        isCompleted: false,
        isClaimed: false,
        icon: '❄️',
      },
      {
        id: 'q_phantom_sweep',
        title: '9:00 PM Wall Socket Sweep',
        description:
          'Switch off idle chargers, set-top boxes, and microwave displays at wall sockets.',
        category: 'ENERGY',
        co2SavedKg: 0,
        coinReward: 15,
        xpReward: 0,
        isCompleted: false,
        isClaimed: false,
        icon: '🔌',
      },
      {
        id: 'q_green_commute',
        title: 'Zero-Emission Urban Trip',
        description: 'Record a walk, bicycle trip, or electric bus ride for errands today.',
        category: 'COMMUTE',
        co2SavedKg: 0,
        coinReward: 25,
        xpReward: 0,
        isCompleted: false,
        isClaimed: false,
        icon: '🚌',
      },
      {
        id: 'q_dal_soak',
        title: 'Cook Smart Dal Pre-Soak',
        description: 'Soak lentils or chickpeas for 30 minutes before stove cooking to save gas.',
        category: 'LIFESTYLE',
        co2SavedKg: 0,
        coinReward: 15,
        xpReward: 0,
        isCompleted: false,
        isClaimed: false,
        icon: '🥘',
      },
      {
        id: 'q_tulsi_water',
        title: 'Sanctuary Flora Hydration',
        description:
          'Water your sacred Tulsi or balcony garden using harvested AC condensation water.',
        category: 'WATER',
        co2SavedKg: 0,
        coinReward: 15,
        xpReward: 0,
        isCompleted: false,
        isClaimed: false,
        icon: '🌿',
      },
    ];
  }

  public async getDailyQuests(userId: string): Promise<DailyQuestsResponse> {
    if (!this.db) {
      return this.toResponse(
        this.getOrCreateMemoryQuests(userId),
        this.getCurrentMemoryStreak(userId),
      );
    }

    await this.ensureSchema();
    const date = this.today();
    await this.db.query(
      `INSERT INTO daily_quests (user_id, quest_date, quests, streak_days)
       VALUES (
         $1,
         $2,
         $3::jsonb,
         COALESCE((
           SELECT CASE WHEN quest_date = $2::date - 1 AND streak_claimed THEN streak_days ELSE 0 END
           FROM daily_quests
           WHERE user_id = $1 AND quest_date = $2::date - 1
         ), 0)
       )
       ON CONFLICT (user_id, quest_date) DO NOTHING`,
      [userId, date, JSON.stringify(this.getDefaultQuests())],
    );

    const result = await this.db.query(
      'SELECT quests, streak_days FROM daily_quests WHERE user_id = $1 AND quest_date = $2',
      [userId, date],
    );
    const row = result.rows[0];
    if (!row) {
      throw new Error('Unable to load daily quests from PostgreSQL');
    }

    return this.toResponse(this.parseQuests(row.quests), Number(row.streak_days));
  }

  public async claimQuest(userId: string, questId: string): Promise<ClaimQuestResponse> {
    if (!this.db) {
      const quests = this.getOrCreateMemoryQuests(userId);
      const quest = this.getClaimableQuest(quests, questId);
      quest.isCompleted = true;
      quest.isClaimed = true;

      const date = this.today();
      const previous = this.userStreaks.get(userId);
      const yesterday = new Date(`${date}T00:00:00.000Z`);
      yesterday.setUTCDate(yesterday.getUTCDate() - 1);
      const streakDays =
        previous?.date === date
          ? previous.streakDays
          : previous?.date === yesterday.toISOString().slice(0, 10)
            ? previous.streakDays + 1
            : 1;
      this.userStreaks.set(userId, { date, streakDays });
      return this.claimResponse(quest, streakDays);
    }

    await this.ensureSchema();
    const client = await this.db.connect();
    try {
      await client.query('BEGIN');
      const date = this.today();
      await client.query(
        `INSERT INTO daily_quests (user_id, quest_date, quests, streak_days, streak_claimed)
         VALUES (
           $1,
           $2,
           $3::jsonb,
           COALESCE((
             SELECT CASE WHEN streak_claimed THEN streak_days ELSE 0 END
             FROM daily_quests
             WHERE user_id = $1 AND quest_date = $2::date - 1
           ), 0),
           FALSE
         )
         ON CONFLICT (user_id, quest_date) DO NOTHING`,
        [userId, date, JSON.stringify(this.getDefaultQuests())],
      );

      const result = await client.query(
        'SELECT quests, streak_days, streak_claimed FROM daily_quests WHERE user_id = $1 AND quest_date = $2 FOR UPDATE',
        [userId, date],
      );
      const row = result.rows[0];
      if (!row) {
        throw new Error('Unable to load daily quests from PostgreSQL');
      }

      const quests = this.parseQuests(row.quests);
      const quest = this.getClaimableQuest(quests, questId);
      quest.isCompleted = true;
      quest.isClaimed = true;

      const streakDays = row.streak_claimed ? Number(row.streak_days) : Number(row.streak_days) + 1;
      await client.query(
        'UPDATE daily_quests SET quests = $3::jsonb, streak_days = $4, streak_claimed = TRUE WHERE user_id = $1 AND quest_date = $2',
        [userId, date, JSON.stringify(quests), streakDays],
      );
      const reward = await client.query(
        'UPDATE users SET points = COALESCE(points, 0) + $2, updated_at = NOW() WHERE id = $1 AND deleted_at IS NULL RETURNING points',
        [userId, quest.coinReward],
      );
      if (!reward.rows[0]) {
        throw new Error('Unable to apply daily task reward to the citizen account');
      }
      await client.query('COMMIT');

      return this.claimResponse(quest, streakDays);
    } catch (error: unknown) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  private async ensureSchema(): Promise<void> {
    if (!this.db) return;
    if (!this.schemaReady) {
      this.schemaReady = this.db
        .query(
          `
        CREATE TABLE IF NOT EXISTS daily_quests (
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          quest_date DATE NOT NULL,
          quests JSONB NOT NULL,
          streak_days INT NOT NULL DEFAULT 0,
          streak_claimed BOOLEAN NOT NULL DEFAULT FALSE,
          PRIMARY KEY (user_id, quest_date)
        )
      `,
        )
        .then(async () => {
          await this.db!.query(
            'ALTER TABLE daily_quests ADD COLUMN IF NOT EXISTS streak_claimed BOOLEAN NOT NULL DEFAULT FALSE',
          );
        })
        .then(() => undefined)
        .catch((error: unknown) => {
          this.schemaReady = null;
          throw error;
        });
    }
    await this.schemaReady;
  }

  private today(): string {
    return new Date().toISOString().slice(0, 10);
  }

  private getOrCreateMemoryQuests(userId: string): QuestTask[] {
    const date = this.today();
    let daily = this.userQuests.get(userId);
    if (!daily || daily.date !== date) {
      daily = { date, quests: this.getDefaultQuests() };
      this.userQuests.set(userId, daily);
    }
    return daily.quests;
  }

  private getCurrentMemoryStreak(userId: string): number {
    const streak = this.userStreaks.get(userId);
    if (!streak) return 0;
    const yesterday = new Date(`${this.today()}T00:00:00.000Z`);
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);
    return streak.date === this.today() || streak.date === yesterday.toISOString().slice(0, 10)
      ? streak.streakDays
      : 0;
  }

  private parseQuests(value: unknown): QuestTask[] {
    const parsed = typeof value === 'string' ? JSON.parse(value) : value;
    if (!Array.isArray(parsed)) {
      throw new Error('Invalid daily quests data returned from PostgreSQL');
    }
    return parsed.map((item) => {
      if (!isQuestTask(item)) {
        throw new Error('Invalid daily quest record returned from PostgreSQL');
      }
      return {
        ...item,
        co2SavedKg: 0,
        xpReward: 0,
      };
    });
  }

  private getClaimableQuest(quests: QuestTask[], questId: string): QuestTask {
    const quest = quests.find((candidate) => candidate.id === questId);
    if (!quest) {
      throw new QuestRuleError(`Quest with ID '${questId}' not found.`);
    }
    if (quest.isClaimed) {
      throw new QuestRuleError('Quest has already been claimed today.');
    }
    return quest;
  }

  private toResponse(quests: QuestTask[], streakDays: number): DailyQuestsResponse {
    return {
      streakDays,
      totalCoinsEarnableToday: quests.reduce((sum, quest) => sum + quest.coinReward, 0),
      totalCo2AvoidableToday:
        Math.round(quests.reduce((sum, quest) => sum + quest.co2SavedKg, 0) * 100) / 100,
      quests,
    };
  }

  private claimResponse(quest: QuestTask, streakDays: number): ClaimQuestResponse {
    return {
      success: true,
      coinsAwarded: quest.coinReward,
      xpAwarded: 0,
      impactCreditedKg: 0,
      evidenceTier: 'SELF_REPORTED',
      newMascotVitality: null,
      streakDays,
      message: `Recorded "${quest.title}" as self-reported. +${quest.coinReward} Green Coins; no CO₂e or mascot XP was credited.`,
    };
  }
}
