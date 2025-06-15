class ForecastModel {
  final List<ForecastDay> days;

  ForecastModel({required this.days});

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    final List list = json['list'];
    Map<String, List<ForecastHour>> dailyMap = {};

    for (var item in list) {
      final dtTxt = item['dt_txt'];
      final date = dtTxt.split(' ')[0];
      final hour = DateTime.parse(dtTxt);

      final main = item['main'];
      final weather = item['weather'][0];

      final hourData = ForecastHour(
        time: hour,
        temperature: main['temp'].toDouble(),
        condition: weather['main'],
        icon: weather['icon'],
      );

      dailyMap.putIfAbsent(date, () => []).add(hourData);
    }

    final days = dailyMap.entries.map((entry) {
      return ForecastDay(
        date: DateTime.parse(entry.key),
        hours: entry.value,
      );
    }).toList();

    return ForecastModel(days: days);
  }
}

class ForecastDay {
  final DateTime date;
  final List<ForecastHour> hours;

  ForecastDay({required this.date, required this.hours});
}

class ForecastHour {
  final DateTime time;
  final double temperature;
  final String condition;
  final String icon;

  ForecastHour({
    required this.time,
    required this.temperature,
    required this.condition,
    required this.icon,
  });
}
