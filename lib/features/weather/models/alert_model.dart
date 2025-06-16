class WeatherAlert {
  final String event;
  final String sender;
  final String description;
  final int start;
  final int end;

  WeatherAlert({
    required this.event,
    required this.sender,
    required this.description,
    required this.start,
    required this.end,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    try {
      return WeatherAlert(
        event: json['event']?.toString() ?? 'Unknown Event',
        sender: json['headline']?.toString() ?? 'Weather Department',
        description: json['desc']?.toString() ?? 'No Description',
        start: json['effective'] != null
            ? DateTime.tryParse(json['effective'])!.millisecondsSinceEpoch ~/ 1000 ?? 0
            : 0,
        end: json['expires'] != null
            ? DateTime.tryParse(json['expires'])!.millisecondsSinceEpoch ~/ 1000 ?? 0
            : 0,
      );
    } catch (e) {
      print('Error parsing WeatherAlert: $e, JSON: $json');
      rethrow; // Rethrow to catch in checkWeatherAlert
    }
  }
}
