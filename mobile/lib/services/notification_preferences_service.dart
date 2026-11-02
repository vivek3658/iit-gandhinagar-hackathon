import 'dart:io';

import 'api_client.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.campaignsEnabled,
    required this.wasteRemindersEnabled,
  });

  final bool campaignsEnabled;
  final bool wasteRemindersEnabled;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        campaignsEnabled: json['campaignsEnabled'] as bool? ?? false,
        wasteRemindersEnabled: json['wasteRemindersEnabled'] as bool? ?? false,
      );
}

class NotificationPreferencesService {
  NotificationPreferencesService._();

  static final NotificationPreferencesService instance =
      NotificationPreferencesService._();

  Future<NotificationPreferences> getPreferences() async {
    final response = await ApiClient.instance.get('/notifications/preferences');
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw HttpException(
        'Could not load notification preferences (${response.statusCode}).',
      );
    }
    return NotificationPreferences.fromJson(response.decodeJson());
  }

  Future<NotificationPreferences> updatePreferences({
    required bool campaignsEnabled,
    required bool wasteRemindersEnabled,
  }) async {
    final response = await ApiClient.instance.put(
      '/notifications/preferences',
      body: {
        'campaignsEnabled': campaignsEnabled,
        'wasteRemindersEnabled': wasteRemindersEnabled,
      },
    );
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw HttpException(
        'Could not save notification preferences (${response.statusCode}).',
      );
    }
    return NotificationPreferences.fromJson(response.decodeJson());
  }
}
