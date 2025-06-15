import 'package:flutter/material.dart';
import '../models/alert_model.dart';

class AlertProvider with ChangeNotifier {
  final List<WeatherAlert> _alerts = [];

  List<WeatherAlert> get alerts => _alerts;

  void addAlert(WeatherAlert alert) {
    _alerts.add(alert);
    notifyListeners();
  }

  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }
}
