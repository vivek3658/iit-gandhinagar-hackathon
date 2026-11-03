import 'api_client.dart';

class CitizenApi {
  CitizenApi._();

  static final instance = CitizenApi._();
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> getDailyQuests() => _api.get('/quests/daily');

  Future<Map<String, dynamic>> claimQuest(String questId) =>
      _api.post('/quests/claim/${Uri.encodeComponent(questId)}');

  Future<Map<String, dynamic>> getAnalytics() =>
      _api.get('/analytics/dashboard');

  Future<Map<String, dynamic>> getMascot() => _api.get('/mascot/state');

  Future<Map<String, dynamic>> interactWithMascot() =>
      _api.post('/mascot/interact');

  Future<Map<String, dynamic>> getGarden() => _api.get('/garden/state');

  Future<Map<String, dynamic>> previewGardenTile({
    required String tileId,
    required int x,
    required int y,
    required int rotation,
  }) => _api.post(
    '/garden/preview',
    body: {'tileId': tileId, 'x': x, 'y': y, 'rotation': rotation},
  );

  Future<Map<String, dynamic>> buyAndPlaceGardenTile({
    required String tileId,
    required int x,
    required int y,
    required int rotation,
  }) => _api.post(
    '/garden/buy-and-place',
    body: {'tileId': tileId, 'x': x, 'y': y, 'rotation': rotation},
  );

  Future<Map<String, dynamic>> getLeaderboard() =>
      _api.get('/leaderboard/league');

  Future<List<Map<String, dynamic>>> getReadings() async =>
      _records(await _api.get('/readings'), 'readings');

  Future<void> addReading({
    required String utility,
    required double value,
    required String unit,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    await _api.post(
      '/readings',
      body: {
        'utility': utility,
        'value': value,
        'unit': unit,
        'periodStart': _dateOnly(periodStart),
        'periodEnd': _dateOnly(periodEnd),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRegisteredDevices() async =>
      _records(await _api.get('/devices/registry'), 'devices');

  Future<Map<String, dynamic>> registerDevice({
    required String name,
    required String category,
    required String discoveryMethod,
    double? ratedPowerW,
  }) => _api.post(
    '/devices/registry',
    body: {
      'name': name,
      'category': category,
      'discoveryMethod': discoveryMethod,
      if (ratedPowerW != null) 'ratedPowerW': ratedPowerW,
    },
  );

  Future<Map<String, dynamic>> logRuntime({
    required String deviceId,
    required double hours,
  }) => _api.post(
    '/devices/registry/${Uri.encodeComponent(deviceId)}/runtime',
    body: {'operatingHours': hours},
  );

  Future<void> removeDevice(String deviceId) async {
    await _api.delete('/devices/registry/${Uri.encodeComponent(deviceId)}');
  }

  Future<List<Map<String, dynamic>>> getLearningChapters() async =>
      _records(await _api.get('/learning/chapters'), 'chapters');

  Future<Map<String, dynamic>> completeChapter({
    required String id,
    required int version,
    required String answerId,
  }) => _api.post(
    '/learning/chapters/${Uri.encodeComponent(id)}/complete',
    body: {'version': version, 'answerId': answerId},
  );

  Future<Map<String, dynamic>> getWasteGameCatalog() =>
      _api.get('/learning/waste-game/catalog');

  Future<Map<String, dynamic>> playWasteGame({
    required String idempotencyKey,
    required List<Map<String, String>> answers,
  }) => _api.post(
    '/learning/waste-game/play',
    body: {'idempotencyKey': idempotencyKey, 'answers': answers},
  );

  List<Map<String, dynamic>> _records(
    Map<String, dynamic> response,
    String key,
  ) {
    final value = response[key];
    if (value is! List) {
      throw const FormatException('The server returned an invalid list.');
    }
    return value.map((item) {
      if (item is! Map) {
        throw const FormatException('The server returned an invalid record.');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
