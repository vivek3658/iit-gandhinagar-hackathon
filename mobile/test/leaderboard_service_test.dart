import 'package:flutter_test/flutter_test.dart';
import 'package:urja/services/leaderboard_service.dart';

void main() {
  test('league response parses weekly rewards as coins', () {
    final response = LeagueLeaderboardData.fromJson({
      'league': 'BRONZE',
      'seasonEndsAt': '2026-06-01T00:00:00.000Z',
      'totalMembers': 1,
      'yourRank': 1,
      'members': [
        {
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
        },
      ],
    });

    expect(response.members.single.weeklyCoins, 25);
    expect(
      () => LeagueMemberData.fromJson({
        'rank': 1,
        'citizenId': 'citizen-1',
        'name': 'Asha',
        'avatarUrl': null,
        'district': 'Ahmedabad',
        'weeklyExp': 25,
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
        'totalCo2SavedKg': 12.5,
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
    expect(visitor.citizen.totalCo2SavedKg, 12.5);
    expect(visitor.mascot.name, 'Cheechee');
    expect(visitor.mascot.vitality, 80);
  });
}
