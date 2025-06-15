import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WeatherCache {
  static const _weatherKey = 'cached_weather';
  static const _forecastKey = 'cached_forecast';

  static Future<void> saveWeather(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonMap = json.decode(jsonStr);
    jsonMap['cached_at'] = DateTime.now().toIso8601String();

    final updatedJson = json.encode(jsonMap);
    await prefs.setString(_weatherKey, updatedJson);
  }


  static Future<String?> getWeather() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_weatherKey);
  }

  static Future<void> saveForecast(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_forecastKey, json);
  }

  static Future<String?> getForecast() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_forecastKey);
  }
}
