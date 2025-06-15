import 'package:shared_preferences/shared_preferences.dart';

class AlertCache {
  static Future<String?> getLastAlertId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_alert_id');
  }

  static Future<void> setLastAlertId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_alert_id', id);
  }
}
