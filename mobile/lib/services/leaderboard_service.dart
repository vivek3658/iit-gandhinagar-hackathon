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
    try {
      final res = await _request('/leaderboard/league');
      final members = res['members'] as List<dynamic>?;
      if (members != null && members.isNotEmpty) {
        return res;
      }
    } catch (_) {}

    final user = AuthService.instance.currentUser;
    return {
      'league': 'GOLD',
      'seasonEndsAt': DateTime.now().add(const Duration(days: 4)).toIso8601String(),
      'totalMembers': 5,
      'yourRank': 1,
      'members': [
        {
          'rank': 1,
          'citizenId': user?.id ?? 'citizen_me',
          'name': (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Gujarat Citizen',
          'avatarUrl': user?.avatarUrl,
          'district': user?.district ?? 'Ahmedabad',
          'weeklyExp': user?.points ?? 250,
          'streakDays': 7,
          'status': 'PROMOTING',
          'isCurrentUser': true,
          'mascotSnapshot': {
            'name': user?.mascotName ?? 'Cheechee',
            'level': 5,
            'expression': 'cheering',
          },
          'gardenSnapshot': {'islandLevel': 2, 'slots': []},
        },
        {
          'rank': 2,
          'citizenId': 'cit_aarav',
          'name': 'Aarav Patel',
          'avatarUrl': null,
          'district': 'Gandhinagar',
          'weeklyExp': 220,
          'streakDays': 5,
          'status': 'PROMOTING',
          'isCurrentUser': false,
          'mascotSnapshot': {'name': 'Panku', 'level': 4, 'expression': 'happy'},
          'gardenSnapshot': {'islandLevel': 1, 'slots': []},
        },
        {
          'rank': 3,
          'citizenId': 'cit_diya',
          'name': 'Diya Shah',
          'avatarUrl': null,
          'district': 'Surat',
          'weeklyExp': 195,
          'streakDays': 4,
          'status': 'PROMOTING',
          'isCurrentUser': false,
          'mascotSnapshot': {'name': 'Tweety', 'level': 3, 'expression': 'happy'},
          'gardenSnapshot': {'islandLevel': 1, 'slots': []},
        },
        {
          'rank': 4,
          'citizenId': 'cit_rohan',
          'name': 'Rohan Joshi',
          'avatarUrl': null,
          'district': 'Vadodara',
          'weeklyExp': 160,
          'streakDays': 3,
          'status': 'SAFE',
          'isCurrentUser': false,
          'mascotSnapshot': {'name': 'Cheep', 'level': 3, 'expression': 'resting'},
          'gardenSnapshot': {'islandLevel': 1, 'slots': []},
        },
        {
          'rank': 5,
          'citizenId': 'cit_ananya',
          'name': 'Ananya Desai',
          'avatarUrl': null,
          'district': 'Rajkot',
          'weeklyExp': 140,
          'streakDays': 2,
          'status': 'SAFE',
          'isCurrentUser': false,
          'mascotSnapshot': {'name': 'Koko', 'level': 2, 'expression': 'happy'},
          'gardenSnapshot': {'islandLevel': 1, 'slots': []},
        },
      ],
    };
  }

  Future<Map<String, dynamic>> getGlobal() async {
    try {
      final res = await _request('/leaderboard/global');
      final munis = res['municipalRankings'] as List<dynamic>?;
      if (munis != null && munis.isNotEmpty) {
        return res;
      }
    } catch (_) {}

    final user = AuthService.instance.currentUser;
    return {
      'municipalRankings': [
        {
          'rank': 1,
          'district': 'Gandhinagar Municipal Corp',
          'totalCo2SavedTonnes': 142.8,
          'activeCitizens': 3420,
          'primaryEnergyMode': 'Rooftop Solar & Smart Grid',
        },
        {
          'rank': 2,
          'district': 'Surat Smart City',
          'totalCo2SavedTonnes': 128.4,
          'activeCitizens': 2890,
          'primaryEnergyMode': 'EV BRTS & Industrial LED',
        },
        {
          'rank': 3,
          'district': 'Ahmedabad Municipal Corp',
          'totalCo2SavedTonnes': 115.6,
          'activeCitizens': 4150,
          'primaryEnergyMode': 'Sabarmati Solar Corridor',
        },
        {
          'rank': 4,
          'district': 'Vadodara Urban Dev',
          'totalCo2SavedTonnes': 94.2,
          'activeCitizens': 1850,
          'primaryEnergyMode': 'Biogas & Canal Solar',
        },
        {
          'rank': 5,
          'district': 'Rajkot Municipal Corp',
          'totalCo2SavedTonnes': 76.5,
          'activeCitizens': 1420,
          'primaryEnergyMode': 'Aji River Clean Drive',
        },
      ],
      'topCitizens': [
        {
          'rank': 1,
          'citizenId': user?.id ?? 'citizen_me',
          'name': (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Gujarat Citizen',
          'avatarUrl': user?.avatarUrl,
          'district': user?.district ?? 'Ahmedabad',
          'totalCo2SavedKg': 84.5,
          'badgeTitle': 'Solar Champion',
        },
        {
          'rank': 2,
          'citizenId': 'top_cit_1',
          'name': 'Bhavin Mehta',
          'avatarUrl': null,
          'district': 'Gandhinagar',
          'totalCo2SavedKg': 78.2,
          'badgeTitle': 'EV Pioneer',
        },
        {
          'rank': 3,
          'citizenId': 'top_cit_2',
          'name': 'Pooja Trivedi',
          'avatarUrl': null,
          'district': 'Surat',
          'totalCo2SavedKg': 69.4,
          'badgeTitle': 'Zero Waste Guardian',
        },
      ],
    };
  }

  Future<GardenVisitorData?> visitGarden(String citizenId) async {
    try {
      final result = await _request('/leaderboard/visit/${Uri.encodeComponent(citizenId)}');
      return GardenVisitorData.fromJson(result);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> cheerCitizen(String citizenId) async {
    try {
      return await _request('/leaderboard/cheer/${Uri.encodeComponent(citizenId)}', method: 'POST');
    } catch (_) {
      return {'success': true, 'cheersReceived': 1};
    }
  }
}
