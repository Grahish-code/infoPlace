import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/weather/models/forecast_model.dart';
import '../../features/weather/models/weather_model.dart';
import '../../features/weather/models/alert_model.dart';
import '../../features/weather/screens/weather_cache.dart';
import '../constants/api_constants.dart';
import 'notification_services.dart';
import 'alert_cache.dart';

class WeatherService {
  /// Fetch 5-day forecast data
  static Future<ForecastModel> getForecast(double lat, double lon) async {
    final url =
        '${ApiConstants.baseUrl}forecast?lat=$lat&lon=$lon&appid=${ApiConstants
        .apiKey}&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = response.body;
        await WeatherCache.saveForecast(json); // ✅ Save to cache
        return ForecastModel.fromJson(jsonDecode(json));
      } else {
        throw Exception('Failed to load forecast: ${response.body}');
      }
    } catch (e) {
      final cached = await WeatherCache.getForecast();
      if (cached != null) {
        print('⚠️ Loaded forecast from cache');
        return ForecastModel.fromJson(jsonDecode(cached));
      }
      throw Exception('No forecast data available');
    }
  }

  /// Fetch current weather for a given city
  static Future<Weather> getWeatherByCity(String cityName) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=${ApiConstants
        .apiKey}&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print("Weather API response: ${response.body}");
        final json = response.body;

        // Save original API response with timestamp
        await _cacheWeatherWithTimestamp(json);

        return Weather.fromJson(jsonDecode(json));
      } else {
        throw Exception('Failed to load weather for $cityName');
      }
    } catch (e) {
      print('Error fetching weather: $e');
      final cached = await WeatherCache.getWeather();
      if (cached != null) {
        print('⚠️ Loaded weather from cache');
        final cachedData = jsonDecode(cached);

        // Extract the original API data (without cached_at)
        final apiData = Map<String, dynamic>.from(cachedData);
        apiData.remove('cached_at'); // Remove our custom field

        return Weather.fromJson(apiData);
      }
      throw Exception('No weather data available');
    }
  }

  /// Cache weather data with timestamp while preserving original format
  static Future<void> _cacheWeatherWithTimestamp(String originalJson) async {
    try {
      final originalData = jsonDecode(originalJson);

      // Add timestamp to original data
      originalData['cached_at'] = DateTime.now().toIso8601String();

      await WeatherCache.saveWeather(jsonEncode(originalData));
    } catch (e) {
      print('Error caching weather data: $e');
    }
  }

  /// Get cache timestamp if available
  static Future<DateTime?> getCacheTimestamp() async {
    try {
      final cached = await WeatherCache.getWeather();
      if (cached != null) {
        final cachedData = jsonDecode(cached);
        if (cachedData['cached_at'] != null) {
          return DateTime.tryParse(cachedData['cached_at']);
        }
      }
    } catch (e) {
      print('Error getting cache timestamp: $e');
    }
    return null;
  }

  /// Check for weather alerts
  static Future<List<WeatherAlert>> checkWeatherAlert({
    required double lat,
    required double lon,
    bool notifyUser = true,
  }) async {
    final url =
        'https://api.weatherapi.com/v1/forecast.json?key=f9a5f6215f0c487f81a52241251406&q=$lat,$lon&days=1&alerts=yes';

    try {
      final response = await http.get(Uri.parse(url));
      print('Weather alert API response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<WeatherAlert> alerts = [];

        if (data['alerts'] != null &&
            data['alerts']['alert'] != null &&
            data['alerts']['alert'] is List) {
          print('Found ${data['alerts']['alert'].length} alerts in response');
          final lastAlertId = await AlertCache.getLastAlertId();

          for (var alertJson in data['alerts']['alert']) {
            try {
              final alert = WeatherAlert.fromJson(alertJson);
              alerts.add(alert);
              print('Parsed alert: ${alert.event}, ${alert.description}');

              final currentId = alert.event + alert.description;

              if (notifyUser && currentId != lastAlertId) {
                print('Sending notification for alert: ${alert.event}');
                await NotificationService.showNotification(
                  title: alert.event,
                  body: alert.description,
                );
                await AlertCache.setLastAlertId(currentId);
              }
            } catch (e) {
              print('Error parsing alert: $e, Alert JSON: $alertJson');
            }
          }
        } else {
          print('No alerts found in response: alerts field is ${data['alerts']}');
        }

        return alerts;
      } else {
        throw Exception('Failed to fetch weather alerts: ${response.body}');
      }
    } catch (e) {
      print('Error fetching alerts: $e');
      return [];
    }
  }
}