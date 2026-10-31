import 'dart:convert';
import 'dart:io';
import '../constants/auth_config.dart';

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

  Future<Map<String, dynamic>> getLeague() async {
    try {
      final uri = Uri.parse('${AuthConfig.apiBaseUrl}/leaderboard/league');
      final req = await _http.getUrl(uri);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return _mockLeague();
  }

  Future<Map<String, dynamic>> getGlobal() async {
    try {
      final uri = Uri.parse('${AuthConfig.apiBaseUrl}/leaderboard/global');
      final req = await _http.getUrl(uri);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return _mockGlobal();
  }

  Future<GardenVisitorData?> visitGarden(String citizenId) async {
    try {
      final uri = Uri.parse('${AuthConfig.apiBaseUrl}/leaderboard/visit/$citizenId');
      final req = await _http.getUrl(uri);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return GardenVisitorData.fromJson(jsonDecode(body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return _mockVisitor(citizenId);
  }

  Future<Map<String, dynamic>> cheerCitizen(String citizenId) async {
    try {
      final uri = Uri.parse('${AuthConfig.apiBaseUrl}/leaderboard/cheer/$citizenId');
      final req = await _http.postUrl(uri);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'success': true,
      'message': '👏 Cheered citizen! Received +2 Urja Mudra coins!',
      'coinsEarned': 2,
    };
  }

  Map<String, dynamic> _mockLeague() {
    return {
      'league': 'GOLD',
      'seasonEndsAt': 'Sunday 23:59 IST (3d 12h left)',
      'totalMembers': 10,
      'yourRank': 4,
      'members': [
        {
          'rank': 1,
          'citizenId': 'cit_priya_ahmedabad',
          'name': 'Priya Patel',
          'district': 'Ahmedabad',
          'weeklyExp': 340,
          'streakDays': 14,
          'status': 'PROMOTING',
          'isCurrentUser': false,
          'mascotSnapshot': {'name': 'Cheechee', 'level': 4, 'vitality': 95, 'expression': 'cheering'},
          'gardenSnapshot': {'islandLevel': 2, 'placedTilesCount': 4, 'previewEmoji': '🏡'},
        },
        {
          'rank': 2,
          'citizenId': 'cit_aarav_surat',
          'name': 'Aarav Shah',
          'district': 'Surat',
          'weeklyExp': 310,
          'streakDays': 11,
          'status': 'PROMOTING',
          'isCurrentUser': false,
          'mascotSnapshot': {'name': 'Piku', 'level': 3, 'vitality': 88, 'expression': 'happy'},
          'gardenSnapshot': {'islandLevel': 2, 'placedTilesCount': 3, 'previewEmoji': '🌳'},
        },
        {
          'rank': 3,
          'citizenId': 'cit_diya_vadodara',
          'name': 'Diya Mehta',
          'district': 'Vadodara',
          'weeklyExp': 290,
          'streakDays': 9,
          'status': 'PROMOTING',
          'isCurrentUser': false,
          'mascotSnapshot': {'name': 'Mithu', 'level': 3, 'vitality': 82, 'expression': 'curious'},
          'gardenSnapshot': {'islandLevel': 2, 'placedTilesCount': 3, 'previewEmoji': '🌷'},
        },
        {
          'rank': 4,
          'citizenId': 'guest_citizen',
          'name': 'You (Energy Guard)',
          'district': 'Ahmedabad',
          'weeklyExp': 240,
          'streakDays': 7,
          'status': 'SAFE',
          'isCurrentUser': true,
          'mascotSnapshot': {'name': 'Piku', 'level': 2, 'vitality': 90, 'expression': 'happy'},
          'gardenSnapshot': {'islandLevel': 1, 'placedTilesCount': 3, 'previewEmoji': '🏡'},
        },
        {
          'rank': 5,
          'citizenId': 'cit_karan_rajkot',
          'name': 'Karan Jadeja',
          'district': 'Rajkot',
          'weeklyExp': 210,
          'streakDays': 6,
          'status': 'SAFE',
          'isCurrentUser': false,
          'mascotSnapshot': {'name': 'Chirpy', 'level': 2, 'vitality': 78, 'expression': 'happy'},
          'gardenSnapshot': {'islandLevel': 1, 'placedTilesCount': 2, 'previewEmoji': '🪨'},
        },
        {
          'rank': 6,
          'citizenId': 'cit_neha_gandhinagar',
          'name': 'Neha Trivedi',
          'district': 'Gandhinagar',
          'weeklyExp': 180,
          'streakDays': 5,
          'status': 'SAFE',
          'isCurrentUser': false,
          'mascotSnapshot': {'name': 'Sparrow', 'level': 2, 'vitality': 74, 'expression': 'curious'},
          'gardenSnapshot': {'islandLevel': 1, 'placedTilesCount': 2, 'previewEmoji': '⛲'},
        },
        {
          'rank': 7,
          'citizenId': 'cit_manan_bhavnagar',
          'name': 'Manan Joshi',
          'district': 'Bhavnagar',
          'weeklyExp': 120,
          'streakDays': 3,
          'status': 'DEMOTING',
          'isCurrentUser': false,
          'mascotSnapshot': {'name': 'Bansi', 'level': 1, 'vitality': 62, 'expression': 'sleepy'},
          'gardenSnapshot': {'islandLevel': 1, 'placedTilesCount': 1, 'previewEmoji': '🏡'},
        },
      ],
    };
  }

  Map<String, dynamic> _mockGlobal() {
    return {
      'municipalRankings': [
        {'rank': 1, 'district': 'Ahmedabad', 'totalCo2SavedTonnes': 1420.5, 'activeCitizens': 38200, 'primaryEnergyMode': 'Solar Rooftop & BRTS'},
        {'rank': 2, 'district': 'Surat', 'totalCo2SavedTonnes': 1280.2, 'activeCitizens': 32400, 'primaryEnergyMode': 'EV Charging & Textile Solars'},
        {'rank': 3, 'district': 'Vadodara', 'totalCo2SavedTonnes': 890.4, 'activeCitizens': 21900, 'primaryEnergyMode': 'Biogas & Domestic Solar'},
        {'rank': 4, 'district': 'Rajkot', 'totalCo2SavedTonnes': 740.1, 'activeCitizens': 18500, 'primaryEnergyMode': 'Drip Garden & Rooftop PV'},
        {'rank': 5, 'district': 'Gandhinagar', 'totalCo2SavedTonnes': 610.8, 'activeCitizens': 14200, 'primaryEnergyMode': 'Net-Zero Govt Grid'},
      ],
      'topCitizens': [
        {'rank': 1, 'citizenId': 'cit_priya_ahmedabad', 'name': 'Priya Patel', 'district': 'Ahmedabad', 'totalCo2SavedKg': 248.5, 'mascotLevel': 5, 'badgeTitle': 'Solar Champion'},
        {'rank': 2, 'citizenId': 'cit_aarav_surat', 'name': 'Aarav Shah', 'district': 'Surat', 'totalCo2SavedKg': 214.2, 'mascotLevel': 4, 'badgeTitle': 'EV Commuter'},
        {'rank': 3, 'citizenId': 'cit_diya_vadodara', 'name': 'Diya Mehta', 'district': 'Vadodara', 'totalCo2SavedKg': 195.8, 'mascotLevel': 4, 'badgeTitle': 'Water Guardian'},
      ],
    };
  }

  GardenVisitorData _mockVisitor(String citizenId) {
    return GardenVisitorData(
      citizen: {
        'id': citizenId,
        'name': citizenId.contains('surat') ? 'Aarav Shah' : 'Priya Patel',
        'district': citizenId.contains('surat') ? 'Surat' : 'Ahmedabad',
        'ward': citizenId.contains('surat') ? 'Adajan' : 'Navrangpura',
        'streakDays': 14,
        'totalCo2SavedKg': 48.2,
      },
      mascot: {
        'name': citizenId.contains('surat') ? 'Piku' : 'Cheechee',
        'level': 4,
        'vitality': 94,
        'mood': 'EXCITED',
        'expression': 'cheering',
        'equipped': {'head': 'flowers', 'face': null, 'neck': 'bow', 'held': null},
      },
      garden: {
        'islandLevel': 2,
        'placedTilesCount': 4,
        'slots': [
          {'x': 0, 'z': 0, 'id': 'SPARROW_HOME', 'name': 'Sparrow Eco Home', 'icon': '🏡', 'rotation': 0},
          {'x': 0, 'z': -1, 'id': 'FLOWER_BED', 'name': 'Fragrant Flower Bed', 'icon': '🌷', 'rotation': 0},
          {'x': 1, 'z': 0, 'id': 'SPARROW_BATH', 'name': 'Bird Bath Fountain', 'icon': '⛲', 'rotation': 1},
          {'x': -1, 'z': 0, 'id': 'SOLAR_STREET_LAMP', 'name': 'Solar Lantern Post', 'icon': '🏮', 'rotation': 0},
        ],
      },
    );
  }
}
