import type { ClaimQuestResponse, DailyQuestsResponse, QuestTask } from './quests.schema';

export class QuestsService {
  private static instance: QuestsService;
  private userQuests = new Map<string, QuestTask[]>();
  private userStreaks = new Map<string, number>();

  public static getInstance(): QuestsService {
    if (!QuestsService.instance) {
      QuestsService.instance = new QuestsService();
    }
    return QuestsService.instance;
  }

  private getDefaultQuests(): QuestTask[] {
    return [
      {
        id: 'q_ac_24',
        title: 'Sleep at 24°C Comfort Setting',
        description: 'Keep bedroom air conditioner at 24°C with a 4-hour timer overnight.',
        category: 'ENERGY',
        co2SavedKg: 1.9,
        coinReward: 20,
        xpReward: 35,
        isCompleted: false,
        isClaimed: false,
        icon: '❄️',
      },
      {
        id: 'q_phantom_sweep',
        title: '9:00 PM Wall Socket Sweep',
        description: 'Switch off idle chargers, set-top boxes, and microwave displays at wall sockets.',
        category: 'ENERGY',
        co2SavedKg: 0.45,
        coinReward: 15,
        xpReward: 25,
        isCompleted: false,
        isClaimed: false,
        icon: '🔌',
      },
      {
        id: 'q_green_commute',
        title: 'Zero-Emission Urban Trip',
        description: 'Record a walk, bicycle trip, or electric bus ride for errands today.',
        category: 'COMMUTE',
        co2SavedKg: 1.2,
        coinReward: 25,
        xpReward: 40,
        isCompleted: false,
        isClaimed: false,
        icon: '🚌',
      },
      {
        id: 'q_dal_soak',
        title: 'Cook Smart Dal Pre-Soak',
        description: 'Soak lentils or chickpeas for 30 minutes before stove cooking to save gas.',
        category: 'LIFESTYLE',
        co2SavedKg: 0.35,
        coinReward: 15,
        xpReward: 20,
        isCompleted: false,
        isClaimed: false,
        icon: '🥘',
      },
      {
        id: 'q_tulsi_water',
        title: 'Sanctuary Flora Hydration',
        description: 'Water your sacred Tulsi or balcony garden using harvested AC condensation water.',
        category: 'WATER',
        co2SavedKg: 0.25,
        coinReward: 15,
        xpReward: 20,
        isCompleted: false,
        isClaimed: false,
        icon: '🌿',
      },
    ];
  }

  public getDailyQuests(userId: string): DailyQuestsResponse {
    let quests = this.userQuests.get(userId);
    if (!quests) {
      quests = this.getDefaultQuests();
      this.userQuests.set(userId, quests);
    }

    const streakDays = this.userStreaks.get(userId) || 7;
    const totalCoins = quests.reduce((sum, q) => sum + q.coinReward, 0);
    const totalCo2 = Math.round(quests.reduce((sum, q) => sum + q.co2SavedKg, 0) * 100) / 100;

    return {
      streakDays,
      totalCoinsEarnableToday: totalCoins,
      totalCo2AvoidableToday: totalCo2,
      quests,
    };
  }

  public claimQuest(userId: string, questId: string): ClaimQuestResponse {
    let quests = this.userQuests.get(userId);
    if (!quests) {
      quests = this.getDefaultQuests();
      this.userQuests.set(userId, quests);
    }

    const quest = quests.find((q) => q.id === questId);
    if (!quest) {
      throw new Error(`Quest with ID '${questId}' not found.`);
    }

    if (quest.isClaimed) {
      throw new Error('Quest has already been claimed today.');
    }

    quest.isCompleted = true;
    quest.isClaimed = true;

    const streak = (this.userStreaks.get(userId) || 7) + 1;
    this.userStreaks.set(userId, streak);

    return {
      success: true,
      coinsAwarded: quest.coinReward,
      xpAwarded: quest.xpReward,
      newMascotVitality: 98,
      streakDays: streak,
      message: `🎉 Claimed ${quest.title}! +${quest.coinReward} Urja Mudra coins, +${quest.xpReward} XP!`,
    };
  }
}
