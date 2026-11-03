import 'dart:convert';
import 'dart:io';

import 'api_client.dart';

class LearningOption {
  const LearningOption({required this.id, required this.label});

  final String id;
  final String label;

  factory LearningOption.fromJson(Map<String, dynamic> json) =>
      LearningOption(id: json['id'] as String, label: json['label'] as String);
}

class LearningChapter {
  const LearningChapter({
    required this.id,
    required this.version,
    required this.title,
    required this.summary,
    required this.question,
    required this.options,
    required this.coinReward,
  });

  final String id;
  final int version;
  final String title;
  final String summary;
  final String question;
  final List<LearningOption> options;
  final int coinReward;

  factory LearningChapter.fromJson(
    Map<String, dynamic> json,
  ) => LearningChapter(
    id: json['id'] as String,
    version: (json['version'] as num).toInt(),
    title: json['title'] as String,
    summary: json['summary'] as String,
    question: json['question'] as String,
    options: (json['options'] as List)
        .map(
          (option) =>
              LearningOption.fromJson(Map<String, dynamic>.from(option as Map)),
        )
        .toList(),
    coinReward: (json['coinReward'] as num).toInt(),
  );
}

class WasteGameItem {
  const WasteGameItem({
    required this.id,
    required this.label,
    required this.guidance,
  });

  final String id;
  final String label;
  final String guidance;

  factory WasteGameItem.fromJson(Map<String, dynamic> json) => WasteGameItem(
    id: json['id'] as String,
    label: json['label'] as String,
    guidance: json['guidance'] as String,
  );
}

class WasteBucket {
  const WasteBucket({required this.id, required this.label});

  final String id;
  final String label;

  factory WasteBucket.fromJson(Map<String, dynamic> json) =>
      WasteBucket(id: json['id'] as String, label: json['label'] as String);
}

class WasteGameCatalog {
  const WasteGameCatalog({
    required this.buckets,
    required this.items,
    required this.rewardCoins,
  });

  final List<WasteBucket> buckets;
  final List<WasteGameItem> items;
  final int rewardCoins;

  factory WasteGameCatalog.fromJson(Map<String, dynamic> json) =>
      WasteGameCatalog(
        buckets: (json['buckets'] as List)
            .map(
              (item) =>
                  WasteBucket.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList(),
        items: (json['items'] as List)
            .map(
              (item) => WasteGameItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        rewardCoins: (json['rewardCoins'] as num).toInt(),
      );
}

class LearningService {
  LearningService._();

  static final instance = LearningService._();

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    final response = await ApiClient.instance.request(
      path,
      method: method,
      body: body,
    );
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw HttpException(
        'Learning request failed (${response.statusCode}). ${_errorDetail(response.body)}',
      );
    }
    return response.decodeJson();
  }

  Future<List<LearningChapter>> getChapters() async {
    final response = await _request('/learning/chapters');
    final chapters = response['chapters'];
    if (chapters is! List) {
      throw const FormatException('The learning chapters response is invalid.');
    }
    return chapters
        .map(
          (item) =>
              LearningChapter.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<Map<String, dynamic>> completeChapter(
    LearningChapter chapter,
    String answerId,
  ) => _request(
    '/learning/chapters/${Uri.encodeComponent(chapter.id)}/complete',
    method: 'POST',
    body: {'version': chapter.version, 'answerId': answerId},
  );

  Future<WasteGameCatalog> getWasteGameCatalog() async =>
      WasteGameCatalog.fromJson(await _request('/learning/waste-game/catalog'));

  Future<Map<String, dynamic>> playWasteGame(Map<String, String> answers) =>
      _request(
        '/learning/waste-game/play',
        method: 'POST',
        body: {
          'idempotencyKey': DateTime.now().microsecondsSinceEpoch.toString(),
          'answers': answers.entries
              .map((entry) => {'itemId': entry.key, 'bucket': entry.value})
              .toList(),
        },
      );

  static String _errorDetail(String body) {
    try {
      final response = ApiErrorBody.tryParse(body);
      if (response != null) return response;
    } on FormatException {
      // The server may return a non-JSON error body.
    }
    return 'Please try again.';
  }
}

abstract final class ApiErrorBody {
  static String? tryParse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded['message'] is String) {
      return decoded['message'] as String;
    }
    return null;
  }
}
