import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/forecast_model.dart';
import '../../../../core/services/weather_services.dart';

class ForecastProvider with ChangeNotifier {
  ForecastModel? _forecast;
  bool _isLoading = false;
  String? _error;

  ForecastModel? get forecast => _forecast;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchForecast(double lat, double lon) async {
    print("📡 Fetching forecast for lat: $lat, lon: $lon");
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _forecast = await WeatherService.getForecast(lat, lon);
      print(" Forecast fetched successfully");
    } catch (e) {
      _error = 'Failed to load forecast: $e';
      print(" Forecast error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  ///  Set forecast from cached JSON (already parsed)
  void setForecastFromCache(Map<String, dynamic> forecastJson) {
    try {
      _forecast = ForecastModel.fromJson(forecastJson);
      _error = null;
      _isLoading = false;
    } catch (e) {
      _forecast = null;
      _error = 'Failed to load cached forecast.';
    }
    notifyListeners();
  }
}
