import 'package:flutter_test/flutter_test.dart';
import 'package:urja/services/leaderboard_service.dart';

void main() {
  test('league response parses weekly estimated CO2e standings', () {
    final response = LeagueLeaderboardData.fromJson({
      'league': 'BRONZE',
      'district': 'Ahmedabad',
      'seasonEndsAt': '2026-06-01T00:00:00.000Z',
      'page': 1,
      'pageSize': 50,
      'totalMembers': 1,
      'totalPages': 1,
      'yourRank': 1,
      'members': [
        {
          'rank': 1,
          'citizenId': 'citizen-1',
          'name': 'Asha',
          'avatarUrl': null,
          'district': 'Ahmedabad',
          'estimatedWeeklyCo2eKg': 1.25,
          'streakDays': 3,
          'status': 'PROMOTING',
          'isCurrentUser': true,
          'mascotSnapshot': {},
          'gardenSnapshot': {},
        },
      ],
    });

    expect(response.district, 'Ahmedabad');
    expect(response.pageSize, 50);
    expect(response.members.single.estimatedWeeklyCo2eKg, 1.25);
    expect(
      () => LeagueMemberData.fromJson({
        'rank': 1,
        'citizenId': 'citizen-1',
        'name': 'Asha',
        'avatarUrl': null,
        'district': 'Ahmedabad',
        'weeklyCoins': 25,
        'streakDays': 3,
        'status': 'PROMOTING',
        'isCurrentUser': true,
        'mascotSnapshot': {},
        'gardenSnapshot': {},
      }),
      throwsFormatException,
    );
  });

  test('visitor response parses backend cheer and mascot values', () {
    final visitor = GardenVisitorData.fromJson({
      'citizen': {
        'id': 'citizen-2',
        'name': 'Neel',
        'avatarUrl': null,
        'district': 'Surat',
        'ward': 'Central',
        'streakDays': 4,
        'estimatedCo2eKg': 12.5,
        'cheersReceived': 7,
      },
      'mascot': {
        'name': 'Cheechee',
        'level': 2,
        'vitality': 80,
        'mood': 'HAPPY',
        'expression': 'happy',
        'equipped': {'head': null, 'face': null, 'neck': null, 'held': null},
      },
      'garden': {'islandLevel': 1, 'placedTilesCount': 0, 'slots': []},
    });

    expect(visitor.citizen.cheersReceived, 7);
    expect(visitor.citizen.estimatedCo2eKg, 12.5);
    expect(visitor.mascot.name, 'Cheechee');
    expect(visitor.mascot.vitality, 80);
  });

  test('municipal standings parse estimated city and citizen scores', () {
    final global = GlobalLeaderboardData.fromJson({
      'municipalRankings': [
        {
          'rank': 1,
          'district': 'Ahmedabad',
          'estimatedCo2eTonnes': 0.12,
          'activeCitizens': 4,
        },
      ],
      'topCitizens': [
        {
          'rank': 1,
          'citizenId': 'citizen-3',
          'name': 'Mira',
          'avatarUrl': null,
          'district': 'Ahmedabad',
          'estimatedCo2eKg': 120,
          'mascotLevel': 5,
          'badgeTitle': 'Eco Ambassador',
        },
      ],
    });

    expect(global.municipalRankings.single.estimatedCo2eTonnes, 0.12);
    expect(global.topCitizens.single.estimatedCo2eKg, 120);
  });
}
