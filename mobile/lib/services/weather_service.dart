import 'dart:convert';
import 'dart:io';

class WeatherData {
  final double temperature;
  final String condition;
  final String icon;
  final String? weatherFx; // 'rain', 'leaves', 'snow', 'petals', null
  final String district;

  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.weatherFx,
    required this.district,
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
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code,wind_speed_10m',
      );
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final current = json['current'] as Map<String, dynamic>?;

        if (current != null) {
          final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 32.0;
          final code = (current['weather_code'] as num?)?.toInt() ?? 0;
          final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;

          return _mapWeatherCode(code, temp, wind, district);
        }
      }
    } catch (_) {
      // Offline fallback: Use seasonal default for Gujarat
    }

    // Default seasonal weather: warm monsoon/clear
    final month = DateTime.now().month;
    if (month >= 6 && month <= 9) {
      return const WeatherData(
        temperature: 31.5,
        condition: 'Monsoon Rain & Breezy',
        icon: '🌧️',
        weatherFx: 'rain',
        district: _defaultDistrict,
      );
    } else if (month >= 11 || month <= 2) {
      return const WeatherData(
        temperature: 24.0,
        condition: 'Mild Winter Morning',
        icon: '⛅',
        weatherFx: 'snow',
        district: _defaultDistrict,
      );
    } else if (month >= 3 && month <= 5) {
      return const WeatherData(
        temperature: 38.0,
        condition: 'Gujarat Summer Sun',
        icon: '☀️',
        weatherFx: 'petals',
        district: _defaultDistrict,
      );
    } else {
      return const WeatherData(
        temperature: 29.0,
        condition: 'Autumn Gentle Breeze',
        icon: '🍂',
        weatherFx: 'leaves',
        district: _defaultDistrict,
      );
    }
  }

  static WeatherData _mapWeatherCode(
    int code,
    double temp,
    double wind,
    String district,
  ) {
    // Rain, Drizzle, Thunderstorms (codes 51-67, 80-82, 95-99)
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95) {
      return WeatherData(
        temperature: temp,
        condition: 'Rain & Showers',
        icon: '🌧️',
        weatherFx: 'rain',
        district: district,
      );
    }

    // Snow (codes 71-77, 85-86)
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return WeatherData(
        temperature: temp,
        condition: 'Chilly Flurries',
        icon: '❄️',
        weatherFx: 'snow',
        district: district,
      );
    }

    // High Wind / Dust
    if (wind > 25.0) {
      return WeatherData(
        temperature: temp,
        condition: 'Windy Breeze',
        icon: '🍂',
        weatherFx: 'leaves',
        district: district,
      );
    }

    // Clear or Sunny (codes 0-3)
    return WeatherData(
      temperature: temp,
      condition: temp > 35 ? 'Warm Sun (40°C Peak)' : 'Clear & Breezy',
      icon: temp > 35 ? '☀️' : '🌤️',
      weatherFx: 'petals',
      district: district,
    );
  }
}
