import 'dart:io';
import 'api_client.dart';

class DailyQuestItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final double co2SavedKg;
  final double estimatedCo2eKg;
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
    required this.estimatedCo2eKg,
    required this.coinReward,
    required this.xpReward,
    required this.isCompleted,
    required this.isClaimed,
    required this.icon,
  });

  factory DailyQuestItem.fromJson(Map<String, dynamic> json) {
    return DailyQuestItem(
      id: _requiredQuestString(json, 'id'),
      title: _requiredQuestString(json, 'title'),
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      co2SavedKg: (json['co2SavedKg'] as num?)?.toDouble() ?? 0,
      estimatedCo2eKg: (json['estimatedCo2eKg'] as num?)?.toDouble() ?? 0,
      coinReward: (json['coinReward'] as num?)?.toInt() ?? 0,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
      icon: json['icon'] as String? ?? '',
    );
  }
}

String _requiredQuestString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Daily task is missing a valid "$key" field.');
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
    final rawQuests = json['quests'];
    if (rawQuests != null && rawQuests is! List) {
      throw const FormatException('Daily tasks response must contain a list.');
    }
    final list = rawQuests == null
        ? <DailyQuestItem>[]
        : (rawQuests as List).map((quest) {
            if (quest is! Map) {
              throw const FormatException('Each daily task must be an object.');
            }
            return DailyQuestItem.fromJson(Map<String, dynamic>.from(quest));
          }).toList();
    return DailyQuestsData(
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      totalCoinsEarnableToday:
          (json['totalCoinsEarnableToday'] as num?)?.toInt() ?? 0,
      totalCo2AvoidableToday:
          (json['totalCo2AvoidableToday'] as num?)?.toDouble() ?? 0,
      quests: list,
    );
  }
}

class QuestsClientService {
  static final QuestsClientService instance = QuestsClientService._();
  QuestsClientService._();

  Future<DailyQuestsData> getDailyQuests() async {
    final response = await ApiClient.instance.get('/quests/daily');
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Could not load daily tasks (${response.statusCode}): ${response.body}',
      );
    }
    return DailyQuestsData.fromJson(response.decodeJson());
  }

  Future<Map<String, dynamic>> claimQuest(String questId) async {
    final encodedQuestId = Uri.encodeComponent(questId);
    final response = await ApiClient.instance.post(
      '/quests/claim/$encodedQuestId',
    );
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Could not claim daily task (${response.statusCode}): ${response.body}',
      );
    }
    return response.decodeJson();
  }
}
