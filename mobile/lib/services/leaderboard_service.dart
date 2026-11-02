import 'dart:io';

import 'api_client.dart';

class LeagueMemberData {
  final int rank;
  final String citizenId;
  final String name;
  final String? avatarUrl;
  final String district;
  final int weeklyExp;
  final int streakDays;
  final String status;
  final bool isCurrentUser;
  final Map<String, dynamic> mascotSnapshot;
  final Map<String, dynamic> gardenSnapshot;

  LeagueMemberData({
    required this.rank,
    required this.citizenId,
    required this.name,
    this.avatarUrl,
    required this.district,
    required this.weeklyExp,
    required this.streakDays,
    required this.status,
    required this.isCurrentUser,
    required this.mascotSnapshot,
    required this.gardenSnapshot,
  });

  factory LeagueMemberData.fromJson(
    Map<String, dynamic> json,
  ) => LeagueMemberData(
    rank: (json['rank'] as num?)?.toInt() ?? 1,
    citizenId: json['citizenId'] as String? ?? '',
    name: json['name'] as String? ?? 'Gujarat Citizen',
    avatarUrl: json['avatarUrl'] as String?,
    district: json['district'] as String? ?? '',
    weeklyExp: (json['weeklyExp'] as num?)?.toInt() ?? 0,
    streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
    status: json['status'] as String? ?? 'SAFE',
    isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    mascotSnapshot: json['mascotSnapshot'] as Map<String, dynamic>? ?? const {},
    gardenSnapshot: json['gardenSnapshot'] as Map<String, dynamic>? ?? const {},
  );
}

class MunicipalRankData {
  final int rank;
  final String district;
  final double totalCo2SavedTonnes;
  final int activeCitizens;
  final String primaryEnergyMode;

  MunicipalRankData({
    required this.rank,
    required this.district,
    required this.totalCo2SavedTonnes,
    required this.activeCitizens,
    required this.primaryEnergyMode,
  });

  factory MunicipalRankData.fromJson(Map<String, dynamic> json) =>
      MunicipalRankData(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        district: json['district'] as String? ?? '',
        totalCo2SavedTonnes:
            (json['totalCo2SavedTonnes'] as num?)?.toDouble() ?? 0,
        activeCitizens: (json['activeCitizens'] as num?)?.toInt() ?? 0,
        primaryEnergyMode: json['primaryEnergyMode'] as String? ?? '',
      );
}

class GardenVisitorData {
  final Map<String, dynamic> citizen;
  final Map<String, dynamic> mascot;
  final Map<String, dynamic> garden;

  GardenVisitorData({
    required this.citizen,
    required this.mascot,
    required this.garden,
  });

  factory GardenVisitorData.fromJson(Map<String, dynamic> json) =>
      GardenVisitorData(
        citizen: json['citizen'] as Map<String, dynamic>? ?? const {},
        mascot: json['mascot'] as Map<String, dynamic>? ?? const {},
        garden: json['garden'] as Map<String, dynamic>? ?? const {},
      );
}

class LeaderboardClientService {
  static final LeaderboardClientService instance = LeaderboardClientService._();

  LeaderboardClientService._();

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
  }) async {
    final response = await ApiClient.instance.request(path, method: method);
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw HttpException(
        'Leaderboard request failed (${response.statusCode}): ${response.body}',
      );
    }
    return response.decodeJson();
  }

  Future<Map<String, dynamic>> getLeague() => _request('/leaderboard/league');

  Future<Map<String, dynamic>> getGlobal() => _request('/leaderboard/global');

  Future<GardenVisitorData?> visitGarden(String citizenId) async {
    final id = Uri.encodeComponent(citizenId);
    final response = await ApiClient.instance.get('/leaderboard/visit/$id');
    if (response.statusCode == HttpStatus.notFound) return null;
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw HttpException(
        'Could not load this citizen garden (${response.statusCode}): ${response.body}',
      );
    }
    return GardenVisitorData.fromJson(response.decodeJson());
  }

  Future<Map<String, dynamic>> cheerCitizen(String citizenId) {
    final id = Uri.encodeComponent(citizenId);
    return _request('/leaderboard/cheer/$id', method: 'POST');
  }
}
