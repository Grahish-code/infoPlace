import 'package:flutter/material.dart';
import '../models/alert_model.dart';

class AlertProvider with ChangeNotifier {
  final List<WeatherAlert> _alerts = [];

  List<WeatherAlert> get alerts => _alerts;

  void addAlert(WeatherAlert alert) {
    _alerts.add(alert);
    notifyListeners();
  }

  void updateAlerts(List<WeatherAlert> newAlerts) {
    _alerts.clear();
    _alerts.addAll(newAlerts);
    print('AlertProvider updated with ${newAlerts.length} alerts');
    notifyListeners();
  }

  void clearAlerts() {
    _alerts.clear();
    notifyListeners();
  }
}