import 'dart:convert';
import 'dart:io';

import 'api_client.dart';

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toInt();
  throw FormatException('Leaderboard field "$key" must be a number.');
}

double _requiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  throw FormatException('Leaderboard field "$key" must be a number.');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Leaderboard field "$key" must be a string.');
}

String? _nullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null || value is String) return value as String?;
  throw FormatException('Leaderboard field "$key" must be a string or null.');
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('Leaderboard field "$key" must be a boolean.');
}

Map<String, dynamic> _requiredObject(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Leaderboard field "$key" must be an object.');
}

List<T> _requiredList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) parse,
) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('Leaderboard field "$key" must be a list.');
  }
  return value.map((item) {
    if (item is! Map) {
      throw FormatException(
        'Each item in leaderboard field "$key" must be an object.',
      );
    }
    return parse(Map<String, dynamic>.from(item));
  }).toList();
}

class LeagueMemberData {
  const LeagueMemberData({
    required this.rank,
    required this.citizenId,
    required this.name,
    required this.avatarUrl,
    required this.district,
    required this.weeklyCoins,
    required this.streakDays,
    required this.status,
    required this.isCurrentUser,
    required this.mascotSnapshot,
    required this.gardenSnapshot,
  });

  final int rank;
  final String citizenId;
  final String name;
  final String? avatarUrl;
  final String district;
  final int weeklyCoins;
  final int streakDays;
  final String status;
  final bool isCurrentUser;
  final Map<String, dynamic> mascotSnapshot;
  final Map<String, dynamic> gardenSnapshot;

  factory LeagueMemberData.fromJson(Map<String, dynamic> json) =>
      LeagueMemberData(
        rank: _requiredInt(json, 'rank'),
        citizenId: _requiredString(json, 'citizenId'),
        name: _requiredString(json, 'name'),
        avatarUrl: json['avatarUrl'] as String?,
        district: _requiredString(json, 'district'),
        weeklyCoins: _requiredInt(json, 'weeklyCoins'),
        streakDays: _requiredInt(json, 'streakDays'),
        status: _requiredString(json, 'status'),
        isCurrentUser: _requiredBool(json, 'isCurrentUser'),
        mascotSnapshot: _requiredObject(json, 'mascotSnapshot'),
        gardenSnapshot: _requiredObject(json, 'gardenSnapshot'),
      );
}

class LeagueLeaderboardData {
  const LeagueLeaderboardData({
    required this.league,
    required this.seasonEndsAt,
    required this.totalMembers,
    required this.yourRank,
    required this.members,
  });

  final String league;
  final String seasonEndsAt;
  final int totalMembers;
  final int yourRank;
  final List<LeagueMemberData> members;

  factory LeagueLeaderboardData.fromJson(Map<String, dynamic> json) =>
      LeagueLeaderboardData(
        league: _requiredString(json, 'league'),
        seasonEndsAt: _requiredString(json, 'seasonEndsAt'),
        totalMembers: _requiredInt(json, 'totalMembers'),
        yourRank: _requiredInt(json, 'yourRank'),
        members: _requiredList(json, 'members', LeagueMemberData.fromJson),
      );
}

class MunicipalRankData {
  const MunicipalRankData({
    required this.rank,
    required this.district,
    required this.totalCo2SavedTonnes,
    required this.activeCitizens,
    required this.primaryEnergyMode,
  });

  final int rank;
  final String district;
  final double totalCo2SavedTonnes;
  final int activeCitizens;
  final String primaryEnergyMode;

  factory MunicipalRankData.fromJson(Map<String, dynamic> json) =>
      MunicipalRankData(
        rank: _requiredInt(json, 'rank'),
        district: _requiredString(json, 'district'),
        totalCo2SavedTonnes: _requiredDouble(json, 'totalCo2SavedTonnes'),
        activeCitizens: _requiredInt(json, 'activeCitizens'),
        primaryEnergyMode: _requiredString(json, 'primaryEnergyMode'),
      );
}

class GlobalCitizenRankData {
  const GlobalCitizenRankData({
    required this.rank,
    required this.citizenId,
    required this.name,
    required this.avatarUrl,
    required this.district,
    required this.totalCo2SavedKg,
    required this.mascotLevel,
    required this.badgeTitle,
  });

  final int rank;
  final String citizenId;
  final String name;
  final String? avatarUrl;
  final String district;
  final double totalCo2SavedKg;
  final int mascotLevel;
  final String badgeTitle;

  factory GlobalCitizenRankData.fromJson(Map<String, dynamic> json) =>
      GlobalCitizenRankData(
        rank: _requiredInt(json, 'rank'),
        citizenId: _requiredString(json, 'citizenId'),
        name: _requiredString(json, 'name'),
        avatarUrl: json['avatarUrl'] as String?,
        district: _requiredString(json, 'district'),
        totalCo2SavedKg: _requiredDouble(json, 'totalCo2SavedKg'),
        mascotLevel: _requiredInt(json, 'mascotLevel'),
        badgeTitle: _requiredString(json, 'badgeTitle'),
      );
}

class GlobalLeaderboardData {
  const GlobalLeaderboardData({
    required this.municipalRankings,
    required this.topCitizens,
  });

  final List<MunicipalRankData> municipalRankings;
  final List<GlobalCitizenRankData> topCitizens;

  factory GlobalLeaderboardData.fromJson(Map<String, dynamic> json) =>
      GlobalLeaderboardData(
        municipalRankings: _requiredList(
          json,
          'municipalRankings',
          MunicipalRankData.fromJson,
        ),
        topCitizens: _requiredList(
          json,
          'topCitizens',
          GlobalCitizenRankData.fromJson,
        ),
      );
}

class GardenVisitorData {
  const GardenVisitorData({
    required this.citizen,
    required this.mascot,
    required this.garden,
  });

  final GardenVisitorCitizenData citizen;
  final GardenVisitorMascotData mascot;
  final Map<String, dynamic> garden;

  factory GardenVisitorData.fromJson(Map<String, dynamic> json) =>
      GardenVisitorData(
        citizen: GardenVisitorCitizenData.fromJson(
          _requiredObject(json, 'citizen'),
        ),
        mascot: GardenVisitorMascotData.fromJson(
          _requiredObject(json, 'mascot'),
        ),
        garden: _requiredObject(json, 'garden'),
      );
}

class GardenVisitorCitizenData {
  const GardenVisitorCitizenData({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.district,
    required this.ward,
    required this.streakDays,
    required this.totalCo2SavedKg,
    required this.cheersReceived,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String district;
  final String ward;
  final int streakDays;
  final double totalCo2SavedKg;
  final int cheersReceived;

  factory GardenVisitorCitizenData.fromJson(Map<String, dynamic> json) =>
      GardenVisitorCitizenData(
        id: _requiredString(json, 'id'),
        name: _requiredString(json, 'name'),
        avatarUrl: _nullableString(json, 'avatarUrl'),
        district: _requiredString(json, 'district'),
        ward: _requiredString(json, 'ward'),
        streakDays: _requiredInt(json, 'streakDays'),
        totalCo2SavedKg: _requiredDouble(json, 'totalCo2SavedKg'),
        cheersReceived: _requiredInt(json, 'cheersReceived'),
      );
}

class GardenVisitorMascotData {
  const GardenVisitorMascotData({
    required this.name,
    required this.level,
    required this.vitality,
    required this.mood,
    required this.expression,
    required this.equipped,
  });

  final String name;
  final int level;
  final int vitality;
  final String mood;
  final String expression;
  final Map<String, dynamic> equipped;

  factory GardenVisitorMascotData.fromJson(Map<String, dynamic> json) =>
      GardenVisitorMascotData(
        name: _requiredString(json, 'name'),
        level: _requiredInt(json, 'level'),
        vitality: _requiredInt(json, 'vitality'),
        mood: _requiredString(json, 'mood'),
        expression: _requiredString(json, 'expression'),
        equipped: _requiredObject(json, 'equipped'),
      );
}

class CheerResult {
  const CheerResult({
    required this.success,
    required this.message,
    required this.coinsEarned,
    required this.totalCheersReceived,
  });

  final bool success;
  final String message;
  final int coinsEarned;
  final int totalCheersReceived;

  factory CheerResult.fromJson(Map<String, dynamic> json) => CheerResult(
    success: _requiredBool(json, 'success'),
    message: _requiredString(json, 'message'),
    coinsEarned: _requiredInt(json, 'coinsEarned'),
    totalCheersReceived: _requiredInt(json, 'totalCheersReceived'),
  );
}

class LeaderboardClientService {
  LeaderboardClientService._();

  static final instance = LeaderboardClientService._();

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
  }) async {
    final response = await ApiClient.instance.request(path, method: method);
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw HttpException(
        'Leaderboard request failed (${response.statusCode}): '
        '${_errorMessage(response.body)}',
      );
    }
    return response.decodeJson();
  }

  Future<LeagueLeaderboardData> getLeague() async =>
      LeagueLeaderboardData.fromJson(await _request('/leaderboard/league'));

  Future<GlobalLeaderboardData> getGlobal() async =>
      GlobalLeaderboardData.fromJson(await _request('/leaderboard/global'));

  Future<GardenVisitorData?> visitGarden(String citizenId) async {
    final id = Uri.encodeComponent(citizenId);
    final response = await ApiClient.instance.get('/leaderboard/visit/$id');
    if (response.statusCode == HttpStatus.notFound) return null;
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw HttpException(
        'Could not load this citizen garden (${response.statusCode}): '
        '${_errorMessage(response.body)}',
      );
    }
    return GardenVisitorData.fromJson(response.decodeJson());
  }

  Future<CheerResult> cheerCitizen(String citizenId) async {
    final id = Uri.encodeComponent(citizenId);
    return CheerResult.fromJson(
      await _request('/leaderboard/cheer/$id', method: 'POST'),
    );
  }

  static String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } on FormatException {
      return body;
    }
    return body;
  }
}
