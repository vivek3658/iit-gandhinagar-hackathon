import 'dart:convert';
import 'dart:io';

class WeatherData {
  final double? temperature;
  final String condition;
  final String icon;
  final String? weatherFx;
  final String? companionMood;
  final String district;
  final bool isLive;

  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.weatherFx,
    required this.companionMood,
    required this.district,
    required this.isLive,
  });
}

class WeatherService {
  static const String _defaultDistrict = 'Ahmedabad, Gujarat';
  static const double _defaultLat = 23.0225;
  static const double _defaultLon = 72.5714;

  /// Fetches live weather for Gujarat from Open-Meteo (Zero API key required)
  static Future<WeatherData> fetchCurrentWeather({
    double latitude = _defaultLat,
    double longitude = _defaultLon,
    String district = _defaultDistrict,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 4)
      ..idleTimeout = const Duration(seconds: 4);
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code,wind_speed_10m&timezone=auto',
      );
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 5));
        final json = jsonDecode(body) as Map<String, dynamic>;
        final current = json['current'] as Map<String, dynamic>?;
        final temp = (current?['temperature_2m'] as num?)?.toDouble();
        final code = (current?['weather_code'] as num?)?.toInt();
        final wind = (current?['wind_speed_10m'] as num?)?.toDouble();

        if (temp != null && code != null && wind != null) {
          return _mapWeatherCode(code, temp, wind, district);
        }
      }
    } on Object {
      // Weather is optional; the companion remains usable without a live forecast.
    } finally {
      client.close(force: true);
    }

    return WeatherData(
      temperature: null,
      condition: 'Weather unavailable',
      icon: '☁️',
      weatherFx: null,
      companionMood: null,
      district: district,
      isLive: false,
    );
  }

  static WeatherData _mapWeatherCode(
    int code,
    double temp,
    double wind,
    String district,
  ) {
    // Rain, Drizzle, Thunderstorms (codes 51-67, 80-82, 95-99)
    if ((code >= 51 && code <= 67) ||
        (code >= 80 && code <= 82) ||
        code >= 95) {
      return WeatherData(
        temperature: temp,
        condition: 'Rain & Showers',
        icon: '🌧️',
        weatherFx: 'rain',
        companionMood: 'rain',
        district: district,
        isLive: true,
      );
    }

    // Snow (codes 71-77, 85-86)
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return WeatherData(
        temperature: temp,
        condition: 'Chilly Flurries',
        icon: '❄️',
        weatherFx: 'snow',
        companionMood: 'cold',
        district: district,
        isLive: true,
      );
    }

    // High Wind / Dust
    if (wind > 25.0) {
      return WeatherData(
        temperature: temp,
        condition: 'Windy Breeze',
        icon: '🍂',
        weatherFx: 'leaves',
        companionMood: 'windy',
        district: district,
        isLive: true,
      );
    }

    if (temp >= 35.0) {
      return WeatherData(
        temperature: temp,
        condition: 'Hot & Sunny',
        icon: '☀️',
        weatherFx: 'butterflies',
        companionMood: 'hot',
        district: district,
        isLive: true,
      );
    }

    // Clear or Sunny (codes 0-3)
    return WeatherData(
      temperature: temp,
      condition: code <= 3 ? 'Clear & Breezy' : 'Cloudy & Calm',
      icon: code <= 3 ? '🌤️' : '☁️',
      weatherFx: 'petals',
      companionMood: 'clear',
      district: district,
      isLive: true,
    );
  }
}
