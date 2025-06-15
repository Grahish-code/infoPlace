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
        '${ApiConstants.baseUrl}forecast?lat=$lat&lon=$lon&appid=${ApiConstants.apiKey}&units=metric';

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
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=${ApiConstants.apiKey}&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print("Weather API response: ${response.body}");
        final json = response.body;
        await WeatherCache.saveWeather(json); // ✅ Save to cache
        return Weather.fromJson(jsonDecode(json));
      } else {
        throw Exception('Failed to load weather for $cityName');
      }
    } catch (e) {
      final cached = await WeatherCache.getWeather();
      if (cached != null) {
        print('⚠️ Loaded weather from cache');
        return Weather.fromJson(jsonDecode(cached));
      }
      throw Exception('No weather data available');
    }
  }

  /// 🚨 Check for weather alerts
  static Future<List<WeatherAlert>> checkWeatherAlert({
    required double lat,
    required double lon,
    bool notifyUser = true,
  }) async {
    final url =
        'https://api.weatherapi.com/v1/forecast.json?key=f9a5f6215f0c487f81a52241251406&&q=Mumbai&days=1&alerts=yes';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<WeatherAlert> alerts = [];

      if (data['alerts'] != null &&
          data['alerts']['alert'] != null &&
          data['alerts']['alert'] is List) {
        final lastAlertId = await AlertCache.getLastAlertId();

        for (var alertJson in data['alerts']['alert']) {
          final alert = WeatherAlert.fromJson(alertJson);
          alerts.add(alert);

          final currentId = alert.event + alert.description;

          if (notifyUser && currentId != lastAlertId) {
            await NotificationService.showNotification(
              title: alert.event,
              body: alert.description,
            );

            await AlertCache.setLastAlertId(currentId);
          }
        }
      }

      return alerts;
    } else {
      throw Exception('Failed to fetch weather alerts : ${response.body}');
    }
  }
}
