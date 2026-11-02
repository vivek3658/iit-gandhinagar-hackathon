import type { Pool, PoolClient } from 'pg';
import type {
  CompleteChapterResponseSchema,
  LearningChapterSchema,
  WasteGameResultSchema,
} from './learning.schema';
import type { Static } from '@sinclair/typebox';

type LearningChapter = Static<typeof LearningChapterSchema> & { correctAnswerId: string };
type ChapterResult = Static<typeof CompleteChapterResponseSchema>;
type WasteResult = Static<typeof WasteGameResultSchema>;
type WasteBucket = 'ORGANIC' | 'DRY_RECYCLABLE' | 'SPECIAL_HANDLING' | 'RESIDUAL';

const CHAPTERS: LearningChapter[] = [
  {
    id: 'electricity-at-home',
    version: 1,
    title: 'Know Your Electricity Use',
    summary: 'Learn how to read an electricity bill and compare the same billing periods.',
    question: 'Which comparison is most useful for tracking household electricity use?',
    options: [
      { id: 'same-period', label: 'Compare readings over similar billing periods' },
      { id: 'bill-total', label: 'Compare only the rupee total' },
      { id: 'one-day', label: 'Compare one day with a full billing month' },
    ],
    correctAnswerId: 'same-period',
    coinReward: 10,
  },
  {
    id: 'water-at-home',
    version: 1,
    title: 'Make Water Use Visible',
    summary: 'Record a dated water reading and use the same unit when comparing periods.',
    question: 'What makes two water readings easier to compare?',
    options: [
      { id: 'same-unit', label: 'Use the same unit and record each reading date' },
      { id: 'estimate', label: 'Leave out dates and estimate a monthly total' },
      { id: 'mix-units', label: 'Compare litres directly with rupees' },
    ],
    correctAnswerId: 'same-unit',
    coinReward: 10,
  },
  {
    id: 'travel-choices',
    version: 1,
    title: 'Plan a Greener Trip',
    summary: 'Choose a trip mode that suits the route and record only a confirmed summary.',
    question: 'What should happen before a trip summary is saved?',
    options: [
      { id: 'confirm', label: 'Review and confirm the trip details' },
      { id: 'upload-route', label: 'Upload the complete GPS route automatically' },
      { id: 'guess', label: 'Guess the distance without checking' },
    ],
    correctAnswerId: 'confirm',
    coinReward: 10,
  },
];

const WASTE_BUCKETS: { id: WasteBucket; label: string }[] = [
  { id: 'ORGANIC', label: 'Organic / wet waste' },
  { id: 'DRY_RECYCLABLE', label: 'Clean, dry recyclables' },
  { id: 'SPECIAL_HANDLING', label: 'Special handling / e-waste' },
  { id: 'RESIDUAL', label: 'Residual waste' },
];

const WASTE_ITEMS: { id: string; label: string; guidance: string; bucket: WasteBucket }[] = [
  {
    id: 'fruit-peel',
    label: 'Fruit peel',
    guidance: 'Often accepted with organic waste; check local composting rules.',
    bucket: 'ORGANIC',
  },
  {
    id: 'clean-bottle',
    label: 'Clean, dry plastic bottle',
    guidance: 'Keep recyclables clean and dry; local accepted plastics vary.',
    bucket: 'DRY_RECYCLABLE',
  },
  {
    id: 'used-battery',
    label: 'Used household battery',
    guidance: 'Keep batteries out of wet waste and use an authorized collection point.',
    bucket: 'SPECIAL_HANDLING',
  },
  {
    id: 'soiled-tissue',
    label: 'Soiled tissue paper',
    guidance: 'Usually residual waste; follow your local municipal instructions.',
    bucket: 'RESIDUAL',
  },
  {
    id: 'clean-cardboard',
    label: 'Clean, dry cardboard',
    guidance: 'Keep paper dry; local collection rules may differ.',
    bucket: 'DRY_RECYCLABLE',
  },
];

export class LearningService {
  private static schemaReady = new WeakMap<Pool, Promise<void>>();
  private static testCompletions = new Map<string, Set<string>>();
  private static testWastePlays = new Map<string, { key: string; result: WasteResult }>();
  private static testCoins = new Map<string, number>();

  public constructor(
    private readonly db: Pool | null,
    private readonly allowTestMemory: boolean,
  ) {}

  public getChapters() {
    return CHAPTERS.map((chapter) => ({
      id: chapter.id,
      version: chapter.version,
      title: chapter.title,
      summary: chapter.summary,
      question: chapter.question,
      options: chapter.options,
      coinReward: chapter.coinReward,
    }));
  }

  public getWasteCatalog() {
    return {
      buckets: WASTE_BUCKETS,
      items: WASTE_ITEMS.map(({ id, label, guidance }) => ({ id, label, guidance })),
      rewardCoins: 5,
      timezone: 'UTC' as const,
    };
  }

  public async completeChapter(
    userId: string,
    chapterId: string,
    version: number,
    answerId: string,
  ): Promise<ChapterResult> {
    const chapter = CHAPTERS.find((candidate) => candidate.id === chapterId);
    if (!chapter || chapter.version !== version) {
      throw new Error('Chapter or chapter version was not found.');
    }
    if (answerId !== chapter.correctAnswerId) {
      throw new Error('That answer is not correct yet. Review the chapter and try again.');
    }

    if (!this.db) {
      this.requireTestMemory();
      const key = `${userId}:${chapterId}:${version}`;
      const completions = LearningService.testCompletions.get(userId) ?? new Set<string>();
      LearningService.testCompletions.set(userId, completions);
      if (completions.has(key)) {
        return this.chapterResponse(true, 0, this.testBalance(userId));
      }
      completions.add(key);
      const total = this.addTestCoins(userId, chapter.coinReward);
      return this.chapterResponse(false, chapter.coinReward, total);
    }

    await this.ensureSchema();
    const client = await this.db.connect();
    try {
      await client.query('BEGIN');
      const inserted = await client.query(
        `INSERT INTO chapter_completions (user_id, chapter_id, chapter_version, coin_reward)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (user_id, chapter_id, chapter_version) DO NOTHING
         RETURNING id`,
        [userId, chapterId, version, chapter.coinReward],
      );
      if (!inserted.rows[0]) {
        const balance = await this.getBalance(client, userId);
        await client.query('COMMIT');
        return this.chapterResponse(true, 0, balance);
      }

      const balance = await this.addCoins(client, userId, chapter.coinReward);
      await client.query('COMMIT');
      return this.chapterResponse(false, chapter.coinReward, balance);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  public async playWasteGame(
    userId: string,
    idempotencyKey: string,
    answers: { itemId: string; bucket: WasteBucket }[],
  ): Promise<WasteResult> {
    if (answers.some((answer) => !WASTE_ITEMS.some((item) => item.id === answer.itemId))) {
      throw new Error('Waste game contains an unknown item.');
    }
    const correctCount = answers.reduce((count, answer) => {
      const item = WASTE_ITEMS.find((candidate) => candidate.id === answer.itemId)!;
      return count + Number(item.bucket === answer.bucket);
    }, 0);
    const rewardDate = new Date().toISOString().slice(0, 10);
    const rewardCoins = 5;

    if (!this.db) {
      this.requireTestMemory();
      const existing = LearningService.testWastePlays.get(userId);
      if (existing?.result.rewardDate === rewardDate) {
        if (existing.key !== idempotencyKey) {
          return { ...existing.result, alreadyPlayedToday: true, coinsAwarded: 0 };
        }
        return { ...existing.result, alreadyPlayedToday: true, coinsAwarded: 0 };
      }
      const total = this.addTestCoins(userId, rewardCoins);
      const result = this.wasteResponse(
        false,
        correctCount,
        answers.length,
        rewardCoins,
        total,
        rewardDate,
      );
      LearningService.testWastePlays.set(userId, { key: idempotencyKey, result });
      return result;
    }

    await this.ensureSchema();
    const client = await this.db.connect();
    try {
      await client.query('BEGIN');
      const inserted = await client.query(
        `INSERT INTO waste_game_sessions
           (user_id, reward_date, idempotency_key, answers, correct_count, item_count, coin_reward)
         VALUES ($1, $2, $3, $4::jsonb, $5, $6, $7)
         ON CONFLICT (user_id, reward_date) DO NOTHING
         RETURNING id`,
        [
          userId,
          rewardDate,
          idempotencyKey,
          JSON.stringify(answers),
          correctCount,
          answers.length,
          rewardCoins,
        ],
      );
      if (!inserted.rows[0]) {
        const existing = await client.query(
          `SELECT correct_count, item_count FROM waste_game_sessions
           WHERE user_id = $1 AND reward_date = $2`,
          [userId, rewardDate],
        );
        const balance = await this.getBalance(client, userId);
        await client.query('COMMIT');
        return this.wasteResponse(
          true,
          Number(existing.rows[0]?.correct_count ?? 0),
          Number(existing.rows[0]?.item_count ?? 0),
          0,
          balance,
          rewardDate,
        );
      }

      const balance = await this.addCoins(client, userId, rewardCoins);
      await client.query('COMMIT');
      return this.wasteResponse(
        false,
        correctCount,
        answers.length,
        rewardCoins,
        balance,
        rewardDate,
      );
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  private async ensureSchema(): Promise<void> {
    if (!this.db) return;
    let ready = LearningService.schemaReady.get(this.db);
    if (!ready) {
      ready = this.db
        .query(
          `
          CREATE TABLE IF NOT EXISTS chapter_completions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            chapter_id TEXT NOT NULL,
            chapter_version INTEGER NOT NULL,
            coin_reward INTEGER NOT NULL CHECK (coin_reward >= 0),
            completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE (user_id, chapter_id, chapter_version)
          );
          CREATE TABLE IF NOT EXISTS waste_game_sessions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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
        `,
        )
        .then(() => undefined)
        .catch((error: unknown) => {
          LearningService.schemaReady.delete(this.db!);
          throw error;
        });
      LearningService.schemaReady.set(this.db, ready);
    }
    await ready;
  }

  private async getBalance(client: PoolClient, userId: string) {
    const result = await client.query(
      'SELECT points FROM users WHERE id = $1 AND deleted_at IS NULL',
      [userId],
    );
    if (!result.rows[0]) throw new Error('Citizen account was not found.');
    return Number(result.rows[0].points ?? 0);
  }

  private async addCoins(client: PoolClient, userId: string, coins: number) {
    const result = await client.query(
      `UPDATE users SET points = COALESCE(points, 0) + $2, updated_at = NOW()
       WHERE id = $1 AND deleted_at IS NULL RETURNING points`,
      [userId, coins],
    );
    if (!result.rows[0]) throw new Error('Could not credit the citizen account.');
    return Number(result.rows[0].points);
  }

  private requireTestMemory(): void {
    if (!this.allowTestMemory) {
      throw new Error('PostgreSQL is required for learning and game rewards.');
    }
  }

  private testBalance(userId: string): number {
    return LearningService.testCoins.get(userId) ?? 0;
  }

  private addTestCoins(userId: string, coins: number): number {
    const balance = this.testBalance(userId) + coins;
    LearningService.testCoins.set(userId, balance);
    return balance;
  }

  private chapterResponse(
    alreadyCompleted: boolean,
    coinsAwarded: number,
    totalCoins: number,
  ): ChapterResult {
    return {
      success: true,
      alreadyCompleted,
      coinsAwarded,
      totalCoins,
      message: alreadyCompleted
        ? 'This chapter version has already been completed.'
        : `Chapter complete. ${coinsAwarded} Green Coins awarded; no environmental impact was claimed.`,
    };
  }

  private wasteResponse(
    alreadyPlayedToday: boolean,
    correctCount: number,
    itemCount: number,
    coinsAwarded: number,
    totalCoins: number,
    rewardDate: string,
  ): WasteResult {
    return {
      success: true,
      alreadyPlayedToday,
      correctCount,
      itemCount,
      coinsAwarded,
      totalCoins,
      rewardDate,
      message: alreadyPlayedToday
        ? 'The daily sorting game reward was already claimed.'
        : `Sorting game complete. ${coinsAwarded} Green Coins awarded; local collection rules may differ.`,
    };
  }
}
