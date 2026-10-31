import 'dart:convert';
import 'dart:io';
import '../constants/auth_config.dart';

class DailyQuestItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final double co2SavedKg;
  final int coinReward;
  final int xpReward;
  final bool isCompleted;
  final bool isClaimed;
  final String icon;

  DailyQuestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.co2SavedKg,
    required this.coinReward,
    required this.xpReward,
    required this.isCompleted,
    required this.isClaimed,
    required this.icon,
  });

  factory DailyQuestItem.fromJson(Map<String, dynamic> json) {
    return DailyQuestItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Mission LiFE Habit',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'ENERGY',
      co2SavedKg: (json['co2SavedKg'] as num?)?.toDouble() ?? 0.5,
      coinReward: json['coinReward'] as int? ?? 15,
      xpReward: json['xpReward'] as int? ?? 25,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
      icon: json['icon'] as String? ?? '🌱',
    );
  }
}

class DailyQuestsData {
  final int streakDays;
  final int totalCoinsEarnableToday;
  final double totalCo2AvoidableToday;
  final List<DailyQuestItem> quests;

  DailyQuestsData({
    required this.streakDays,
    required this.totalCoinsEarnableToday,
    required this.totalCo2AvoidableToday,
    required this.quests,
  });

  factory DailyQuestsData.fromJson(Map<String, dynamic> json) {
    final list = (json['quests'] as List<dynamic>?)?.map((e) => DailyQuestItem.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    return DailyQuestsData(
      streakDays: json['streakDays'] as int? ?? 1,
      totalCoinsEarnableToday: json['totalCoinsEarnableToday'] as int? ?? 100,
      totalCo2AvoidableToday: (json['totalCo2AvoidableToday'] as num?)?.toDouble() ?? 5.5,
      quests: list,
    );
  }
}

class QuestsClientService {
  static final QuestsClientService instance = QuestsClientService._();
  QuestsClientService._();

  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 4);

  Future<DailyQuestsData> getDailyQuests() async {
    try {
      final uri = Uri.parse('${AuthConfig.apiBaseUrl}/quests/daily');
      final req = await _http.getUrl(uri);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return DailyQuestsData.fromJson(jsonDecode(body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return _mockQuests();
  }

  Future<Map<String, dynamic>> claimQuest(String questId) async {
    try {
      final uri = Uri.parse('${AuthConfig.apiBaseUrl}/quests/claim/$questId');
      final req = await _http.postUrl(uri);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'success': true,
      'coinsAwarded': 20,
      'xpAwarded': 35,
      'newMascotVitality': 98,
      'streakDays': 8,
      'message': '🎉 Quest Claimed! Received 20 Urja Mudra & 35 XP!',
    };
  }

  DailyQuestsData _mockQuests() {
    return DailyQuestsData(
      streakDays: 7,
      totalCoinsEarnableToday: 110,
      totalCo2AvoidableToday: 6.2,
      quests: [
        DailyQuestItem(
          id: 'quest_ac_24c',
          title: 'AC Set at 24°C Comfort',
          description: 'Keep your split AC at or above 24°C to save 24% compressor load.',
          category: 'ENERGY',
          co2SavedKg: 2.4,
          coinReward: 20,
          xpReward: 35,
          isCompleted: true,
          isClaimed: false,
          icon: '❄️',
        ),
        DailyQuestItem(
          id: 'quest_socket_sweep',
          title: '9 PM Standby Socket Sweep',
          description: 'Switch off TV, microwave and mobile chargers from master wall sockets.',
          category: 'ENERGY',
          co2SavedKg: 0.9,
          coinReward: 25,
          xpReward: 40,
          isCompleted: true,
          isClaimed: false,
          icon: '🌙',
        ),
        DailyQuestItem(
          id: 'quest_water_tulsi',
          title: 'Rinse Water to Tulsi Plant',
          description: 'Reuse AC condensation or dal rinsing water for home plants.',
          category: 'WATER',
          co2SavedKg: 0.6,
          coinReward: 20,
          xpReward: 30,
          isCompleted: false,
          isClaimed: false,
          icon: '🌿',
        ),
        DailyQuestItem(
          id: 'quest_green_commute',
          title: 'Zero-Emission Commute',
          description: 'Walk, cycle or ride EV / BRTS bus for daily errands under 3 km.',
          category: 'COMMUTE',
          co2SavedKg: 1.5,
          coinReward: 25,
          xpReward: 45,
          isCompleted: false,
          isClaimed: false,
          icon: '🚴',
        ),
        DailyQuestItem(
          id: 'quest_dal_presoak',
          title: 'Pre-Soak Lentils / Dal',
          description: 'Soaking pulses for 1 hour cuts pressure cooking gas burn by 30%.',
          category: 'LIFESTYLE',
          co2SavedKg: 0.8,
          coinReward: 20,
          xpReward: 30,
          isCompleted: false,
          isClaimed: false,
          icon: '🥘',
        ),
      ],
    );
  }
}
