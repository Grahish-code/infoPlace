import 'dart:convert';

import 'package:flutter/material.dart';
import '../data/repositories/weather_repository.dart';
import '../models/weather_model.dart';
import '../models/alert_model.dart';
import '../../../../core/services/weather_services.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherRepository _repository = WeatherRepository();

  Weather? _weather;
  bool _isLoading = false;
  String? _error;

  List<WeatherAlert> _alerts = [];

  Weather? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<WeatherAlert> get alerts => _alerts;

  Future<void> fetchWeather() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _weather = await _repository.getCurrentWeather();

      if (_weather != null) {
        _alerts = await WeatherService.checkWeatherAlert(
          lat: _weather!.lat,
          lon: _weather!.lon,
          notifyUser: true,
        );
      } else {
        _alerts = [];
        _error = 'Weather data not found.';
      }
    } catch (e) {
      _error = e.toString();
      _weather = await _repository.getCachedWeather();
      _alerts = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  ///  Method to set weather from a cached Weather object
  Future<DateTime?> setWeatherFromCache(String jsonStr) async {
    try {
      final jsonMap = json.decode(jsonStr);
      _weather = Weather.fromJson(jsonMap);
      notifyListeners();

      // Return cached_at
      return DateTime.tryParse(jsonMap['cached_at'] ?? '');
    } catch (e) {
      _weather = null;
      _error = 'Error loading cached weather: $e';
      notifyListeners();
      return null;
    }
  }


  ///  Optional method if you want to pass cached JSON string
  void setWeatherFromCacheJson(String jsonStr) {
    try {
      _weather = Weather.fromJson(json.decode(jsonStr));
      _error = null;
      _isLoading = false;
    } catch (e) {
      _error = 'Failed to parse cached weather data.';
      _weather = null;
    }
    notifyListeners();
  }
}
