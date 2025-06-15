class Weather {
  final String cityName;
  final double temperature;
  final String description;
  final String iconCode;
  final double lat;
  final double lon;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.iconCode,
    required this.lat,
    required this.lon,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final coord = json['coord'] ?? {};

    return Weather(
      cityName: json['name'] ?? 'Unknown',
      temperature: json['main']?['temp']?.toDouble() ?? 0.0,
      description: json['weather']?[0]?['description'] ?? 'No Description',
      iconCode: json['weather']?[0]?['icon'] ?? '01d',
      lat: coord['lat']?.toDouble() ?? 0.0,
      lon: coord['lon']?.toDouble() ?? 0.0,
    );
  }
}
