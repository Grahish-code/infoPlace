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
    return WeatherAlert(
      event: json['event'] ?? 'Unknown Event',
      sender: json['headline'] ?? 'Weather Department',
      description: json['desc'] ?? 'No Description',
      start: DateTime.parse(json['effective']).millisecondsSinceEpoch ~/ 1000,
      end: DateTime.parse(json['expires']).millisecondsSinceEpoch ~/ 1000,
    );
  }
}
