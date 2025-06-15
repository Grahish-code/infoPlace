// lib/providers/multi_city_weather_provider.dart

import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../../../../core/services/weather_services.dart';

class MultiCityWeatherProvider with ChangeNotifier {
  final List<Weather> _citiesWeather = [];
  final List<String> _cityNames = [];
  bool _isLoading = false;
  String? _error;

  List<Weather> get citiesWeather => _citiesWeather;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCityWeather(String cityName) async {
    if (_citiesWeather.length >= 5 || _cityNames.contains(cityName.toLowerCase())) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final weather = await WeatherService.getWeatherByCity(cityName);
      _citiesWeather.add(weather);
      _cityNames.add(cityName.toLowerCase());
    } catch (e) {
      _error = "Failed to fetch weather for $cityName";
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearAll() {
    _citiesWeather.clear();
    _cityNames.clear();
    notifyListeners();
  }
}
