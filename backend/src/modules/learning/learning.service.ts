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
    content: [
      'An electricity bill usually covers a defined billing period. Use the meter units and the dates on the bill to understand how much energy your home used.',
      'Comparing similar periods is more useful than comparing bill totals alone, because tariffs, fees, and billing-day counts can change.',
    ],
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
    content: [
      'A dated meter reading gives your household a starting point. Record the same meter and unit again later so the change can be compared.',
      'If a reading seems unusual, check the meter and household activity before drawing conclusions. A reading alone does not identify the cause of water use.',
    ],
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
    content: [
      'For a suitable route, walking, cycling, or public transport can reduce reliance on a private motor vehicle. Accessibility, safety, weather, and travel time matter too.',
      'Record a trip only after checking the mode and distance. A route estimate is not a measured emissions saving.',
    ],
    question: 'What should happen before a trip summary is saved?',
    options: [
      { id: 'confirm', label: 'Review and confirm the trip details' },
      { id: 'upload-route', label: 'Upload the complete GPS route automatically' },
      { id: 'guess', label: 'Guess the distance without checking' },
    ],
    correctAnswerId: 'confirm',
    coinReward: 10,
  },
  {
    id: 'renewable-energy',
    version: 1,
    title: 'Clean Energy, Clearly',
    summary: 'Learn what renewable electricity is and what a household can realistically change.',
    content: [
      'Solar and wind use naturally replenished sources to make electricity. Hydropower and other sources can also contribute, depending on the local grid and project.',
      'A home using grid electricity receives the mix supplied to its area. A rooftop solar system can generate power at home, but its output depends on sunlight, equipment, and safe installation.',
      'Myth: every home can become fully renewable just by changing a switch. Reality: options depend on the building, local rules, available providers, and the electricity system.',
    ],
    question: 'What is a sensible first step before installing rooftop solar?',
    options: [
      { id: 'check-site', label: 'Check roof suitability, local rules, and a qualified provider' },
      { id: 'assume-output', label: 'Assume the roof will produce the same power every day' },
      { id: 'disconnect-grid', label: 'Disconnect from the grid without a safety assessment' },
    ],
    correctAnswerId: 'check-site',
    coinReward: 15,
  },
  {
    id: 'co2e-basics',
    version: 1,
    title: 'CO₂e Without the Confusion',
    summary: 'Understand why different greenhouse gases are compared using carbon-dioxide equivalent.',
    content: [
      'Carbon dioxide equivalent, written CO₂e, is a common unit for comparing the warming effect of different greenhouse gases over a stated time period. It is not the same thing as measuring only carbon dioxide.',
      'A footprint estimate depends on its boundary, activity data, and emissions factors. Compare like with like, and treat estimates as estimates unless they are verified.',
      'Myth: a single CO₂e number tells the whole environmental story. Reality: it is useful for climate comparison, but it does not describe every impact such as water use, air pollution, or biodiversity.',
    ],
    question: 'What does CO₂e help us compare?',
    options: [
      { id: 'gas-impact', label: 'The climate impact of different greenhouse gases on a common scale' },
      { id: 'all-impacts', label: 'Every environmental impact in one complete score' },
      { id: 'exact-measurement', label: 'An exact personal measurement without activity data' },
    ],
    correctAnswerId: 'gas-impact',
    coinReward: 15,
  },
  {
    id: 'carbon-myths',
    version: 1,
    title: 'Carbon Myths, Busted',
    summary: 'Separate practical climate actions from common myths and all-or-nothing thinking.',
    content: [
      'Myth: one person’s choices do not matter. Reality: household actions reduce avoidable demand, build habits, and can influence wider community choices; durable progress also needs cleaner infrastructure and public action.',
      'Myth: buying one “green” product cancels every emission. Reality: look at how long an item lasts, whether you need it, and how it is made, used, repaired, and disposed of.',
      'Myth: planting trees alone can quickly cancel all emissions. Reality: protecting ecosystems matters, but it cannot replace reducing fossil-fuel pollution; trees need suitable places and long-term care.',
    ],
    question: 'Which statement is the most accurate?',
    options: [
      { id: 'both-scales', label: 'Personal actions help, alongside systemic and community change' },
      { id: 'offset-everything', label: 'A single purchase can cancel any household footprint' },
      { id: 'trees-alone', label: 'Tree planting removes the need to reduce emissions' },
    ],
    correctAnswerId: 'both-scales',
    coinReward: 15,
  },
  {
    id: 'small-green-steps',
    version: 1,
    title: 'Small Steps, Real Progress',
    summary: 'Choose practical changes that reduce waste and fit your home, budget, and routine.',
    content: [
      'Try one action at a time: switch off unused lights and appliances, use efficient cooling settings, fix water leaks, and choose walking, cycling, or public transport when practical.',
      'Use what you already own for longer, repair items when possible, and sort waste according to your local collection rules. A change is more useful when it is safe, affordable, and repeatable.',
      'Myth: only expensive technology makes a difference. Reality: efficient habits and maintenance can help, while upgrades should be chosen using reliable product information and local conditions.',
    ],
    question: 'Which is a strong way to build a lasting green habit?',
    options: [
      { id: 'one-repeatable', label: 'Pick one safe, practical action and repeat it consistently' },
      { id: 'buy-first', label: 'Buy new equipment before checking current use or needs' },
      { id: 'perfect-or-nothing', label: 'Wait until every part of life can be changed at once' },
    ],
    correctAnswerId: 'one-repeatable',
    coinReward: 15,
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
    id: 'vegetable-scraps',
    label: 'Vegetable scraps',
    guidance: 'Keep food scraps separate; follow your local wet-waste collection rules.',
    bucket: 'ORGANIC',
  },
  {
    id: 'tea-leaves',
    label: 'Used tea leaves',
    guidance: 'Drain excess liquid before placing in organic waste.',
    bucket: 'ORGANIC',
  },
  {
    id: 'clean-bottle',
    label: 'Clean, dry plastic bottle',
    guidance: 'Keep recyclables clean and dry; local accepted plastics vary.',
    bucket: 'DRY_RECYCLABLE',
  },
  {
    id: 'clean-cardboard',
    label: 'Clean cardboard',
    guidance: 'Flatten and keep paper/cardboard dry for collection.',
    bucket: 'DRY_RECYCLABLE',
  },
  {
    id: 'glass-jar',
    label: 'Empty glass jar',
    guidance: 'Handle carefully and check your local glass collection rules.',
    bucket: 'DRY_RECYCLABLE',
  },
  {
    id: 'aluminium-can',
    label: 'Empty drink can',
    guidance: 'Rinse and dry recyclable metal containers where accepted.',
    bucket: 'DRY_RECYCLABLE',
  },
  {
    id: 'used-battery',
    label: 'Used household battery',
    guidance: 'Keep batteries out of wet waste and use an authorized collection point.',
    bucket: 'SPECIAL_HANDLING',
  },
  {
    id: 'old-mobile',
    label: 'Old mobile phone',
    guidance: 'Use an authorized e-waste collection or take-back point.',
    bucket: 'SPECIAL_HANDLING',
  },
  {
    id: 'cfl-bulb',
    label: 'CFL bulb',
    guidance: 'Do not break it; use an authorized collection point for safe handling.',
    bucket: 'SPECIAL_HANDLING',
  },
  {
    id: 'soiled-tissue',
    label: 'Soiled tissue paper',
    guidance: 'Usually residual waste; follow your local municipal instructions.',
    bucket: 'RESIDUAL',
  },
  {
    id: 'snack-wrapper',
    label: 'Multi-layer snack wrapper',
    guidance: 'Usually not accepted with clean recyclables; check local instructions.',
    bucket: 'RESIDUAL',
  },
  {
    id: 'broken-ceramic',
    label: 'Broken ceramic cup',
    guidance: 'Wrap securely to prevent injury and follow residual-waste guidance.',
    bucket: 'RESIDUAL',
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
      content: chapter.content,
      question: chapter.question,
      options: chapter.options,
      coinReward: chapter.coinReward,
    }));
  }

  public async getProgress(userId: string): Promise<{ chapterId: string; version: number }[]> {
    if (!this.db) {
      this.requireTestMemory();
      const completed = LearningService.testCompletions.get(userId) ?? new Set<string>();
      return CHAPTERS.filter((chapter) =>
        completed.has(`${userId}:${chapter.id}:${chapter.version}`),
      ).map(({ id, version }) => ({ chapterId: id, version }));
    }

    await this.ensureSchema();
    const result = await this.db.query(
      `SELECT chapter_id, chapter_version
       FROM chapter_completions
       WHERE user_id = $1
       ORDER BY completed_at`,
      [userId],
    );
    return result.rows.map((row) => ({
      chapterId: String(row.chapter_id),
      version: Number(row.chapter_version),
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
