import 'dart:convert';
import 'dart:io';
import '../constants/auth_config.dart';
import 'auth_service.dart';

class LeagueMemberData {
  final int rank;
  final String citizenId;
  final String name;
  final String? avatarUrl;
  final String district;
  final int weeklyExp;
  final int streakDays;
  final String status; // PROMOTING, SAFE, DEMOTING
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

  factory LeagueMemberData.fromJson(Map<String, dynamic> json) {
    return LeagueMemberData(
      rank: json['rank'] as int? ?? 1,
      citizenId: json['citizenId'] as String? ?? '',
      name: json['name'] as String? ?? 'Gujarat Citizen',
      avatarUrl: json['avatarUrl'] as String?,
      district: json['district'] as String? ?? 'Ahmedabad',
      weeklyExp: json['weeklyExp'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 1,
      status: json['status'] as String? ?? 'SAFE',
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      mascotSnapshot: json['mascotSnapshot'] as Map<String, dynamic>? ?? {},
      gardenSnapshot: json['gardenSnapshot'] as Map<String, dynamic>? ?? {},
    );
  }
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

  factory MunicipalRankData.fromJson(Map<String, dynamic> json) {
    return MunicipalRankData(
      rank: json['rank'] as int? ?? 1,
      district: json['district'] as String? ?? 'Gujarat District',
      totalCo2SavedTonnes: (json['totalCo2SavedTonnes'] as num?)?.toDouble() ?? 0.0,
      activeCitizens: json['activeCitizens'] as int? ?? 0,
      primaryEnergyMode: json['primaryEnergyMode'] as String? ?? 'Solar Rooftop & Grid',
    );
  }
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

  factory GardenVisitorData.fromJson(Map<String, dynamic> json) {
    return GardenVisitorData(
      citizen: json['citizen'] as Map<String, dynamic>? ?? {},
      mascot: json['mascot'] as Map<String, dynamic>? ?? {},
      garden: json['garden'] as Map<String, dynamic>? ?? {},
    );
  }
}

class LeaderboardClientService {
  static final LeaderboardClientService instance = LeaderboardClientService._();
  LeaderboardClientService._();

  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 4);

  Future<Map<String, dynamic>> _request(String path, {String method = 'GET'}) async {
    final token = AuthService.instance.accessToken;
    if (token == null || token.isEmpty) throw Exception('Sign in to view real leaderboard data.');
    final request = await _http.openUrl(method, Uri.parse('${AuthConfig.apiBaseUrl}$path'));
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Leaderboard request failed (${response.statusCode}).');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLeague() async {
    return _request('/leaderboard/league');
  }

  Future<Map<String, dynamic>> getGlobal() async {
    return _request('/leaderboard/global');
  }

  Future<GardenVisitorData?> visitGarden(String citizenId) async {
    final result = await _request('/leaderboard/visit/${Uri.encodeComponent(citizenId)}');
    return GardenVisitorData.fromJson(result);
  }

  Future<Map<String, dynamic>> cheerCitizen(String citizenId) async {
    return _request('/leaderboard/cheer/${Uri.encodeComponent(citizenId)}', method: 'POST');
  }

}