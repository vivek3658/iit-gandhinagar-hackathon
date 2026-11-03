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
      'An electricity bill usually covers a defined billing period. Find the start and end dates, the number of units used, and whether the bill is based on an actual meter reading or an estimate. A kilowatt-hour (kWh) is a unit of energy, not a measure of how much a bill costs.',
      'Compare kWh over similar periods rather than comparing rupee totals alone. Tariffs, fixed charges, taxes, and the number of billing days can change even when your household uses the same amount of electricity.',
      'A simple notebook or a sequence of dated readings can reveal broad patterns. Note changes such as hotter weather, guests, a new appliance, or a longer billing period before deciding why usage changed. One unusual month is a clue to investigate, not proof of a cause.',
      'Use appliance labels and safe operating guidance when exploring possible improvements. Never open a meter, electrical panel, or appliance casing. Ask a qualified electrician or your utility for help with equipment or billing questions.',
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
      'A dated water reading gives your household a starting point. Record the same meter, read the same display, and keep the same unit each time. If your home has no meter, use a clearly labelled bill or provider record instead of inventing a reading.',
      'Compare readings only when their dates and coverage periods make sense. A cumulative meter reading is different from a billed-period quantity. Keep those data types separate so a chart does not compare unlike measurements.',
      'If a reading changes unexpectedly, first check for a typing mistake, a leak, visitors, garden watering, or a change in supply. A reading can show that use changed, but it does not identify the cause or prove that a particular habit saved water.',
      'Choose practical steps that fit your home: report leaks, use water thoughtfully, and follow local guidance for storage and reuse. Avoid drinking or cooking with reclaimed water unless it has been treated and approved for that purpose.',
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
      'For a suitable route, walking, cycling, or public transport can reduce reliance on a private motor vehicle. Accessibility, safety, weather, time, and the needs of everyone travelling matter; a lower-emission option should never require an unsafe or inaccessible trip.',
      'When recording a trip, check the travel date, mode, and approximate distance. A user-confirmed trip summary is useful activity data, but it is not GPS tracking and does not by itself establish how many emissions were avoided.',
      'A fair comparison needs a clear alternative: for example, what vehicle trip would otherwise have happened, how far it would have travelled, how many people shared it, and which emissions factors apply. Without those details, treat any calculated difference as an estimate rather than a verified saving.',
      'Try planning one convenient journey at a time. Combine errands when practical, check public transport information before leaving, and choose a route that works for your health and circumstances.',
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
      'Solar and wind use naturally replenished sources to make electricity. Hydropower and other sources can also contribute, depending on the local grid and project. Every technology has a lifecycle and local context; “renewable” does not mean that every environmental impact is zero.',
      'A home using grid electricity receives the mix supplied to its area. The mix can vary by time and location. A bill showing electricity use does not reveal the exact generation source for every unit.',
      'A rooftop solar system can generate power at home, but output depends on sunlight, roof orientation and shade, equipment, maintenance, and safe installation. A qualified provider should assess the site and explain costs, permissions, warranties, and grid connection.',
      'Myth: every home can become fully renewable just by changing a switch. Reality: options depend on the building, local rules, available providers, finances, and the electricity system. Ask for documented assumptions before relying on a production or savings estimate.',
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
    summary:
      'Understand why different greenhouse gases are compared using carbon-dioxide equivalent.',
    content: [
      'Carbon dioxide equivalent, written CO₂e, is a common unit for comparing the warming effect of different greenhouse gases over a stated time period. It is not the same thing as measuring only carbon dioxide, and it does not mean that a personal footprint has been directly measured.',
      'A footprint or avoided-emissions estimate needs a defined boundary, reliable activity data, a suitable emissions factor, and a stated method. The factor may vary by fuel, location, year, and system boundary. Record the source and uncertainty so another person can understand the result.',
      'To estimate a reduction, compare an observed activity with a reasonable baseline for the same service and period. A smaller utility bill, a logged habit, or a completed trip alone cannot establish that the change was caused by one action.',
      'Myth: one CO₂e number tells the whole environmental story. Reality: it can help compare climate impacts, but it does not describe every impact such as water use, air pollution, material use, or biodiversity.',
    ],
    question: 'What does CO₂e help us compare?',
    options: [
      {
        id: 'gas-impact',
        label: 'The climate impact of different greenhouse gases on a common scale',
      },
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
      'Myth: one person’s choices do not matter. Reality: household actions can reduce avoidable demand, build durable habits, and influence community choices. Lasting progress also needs reliable public services, cleaner infrastructure, and effective policy.',
      'Myth: buying one “green” product cancels every emission. Reality: consider whether you need it, how long it lasts, how it is made and transported, whether it can be repaired, and how it will be disposed of. Reuse and maintenance may be better than replacing a working item.',
      'Myth: one month with a lower bill proves a household has reduced emissions. Reality: weather, billing dates, occupancy, tariffs, and meter estimates can all affect comparisons. Use consistent periods and describe the result as an observed change until causes and factors are assessed.',
      'Myth: planting trees alone can quickly cancel all emissions. Reality: protecting ecosystems matters, but it cannot replace reducing fossil-fuel pollution. Trees need suitable places and long-term care, and their carbon benefits are uncertain over time.',
    ],
    question: 'Which statement is the most accurate?',
    options: [
      {
        id: 'both-scales',
        label: 'Personal actions help, alongside systemic and community change',
      },
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
      'Try one action at a time: switch off unused lights and appliances when safe, use comfortable and efficient cooling settings, report water leaks, and choose walking, cycling, or public transport when practical.',
      'Make a small experiment measurable. Write down what you plan to change, the dates, and the reading or observation you will compare. Keep the same unit and time period, and record unusual circumstances such as visitors or extreme weather.',
      'Use what you already own for longer, repair items when possible, and sort waste according to your local collection rules. A change is more useful when it is safe, affordable, accessible, and repeatable for the people in your household.',
      'Myth: only expensive technology makes a difference. Reality: maintenance and practical habits can help, while upgrades should be selected using reliable product information, lifecycle needs, and local conditions. Ask providers for assumptions and avoid promises that cannot be measured.',
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
