import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forecast_provider.dart';
import '../providers/weather_provider.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({Key? key}) : super(key: key);

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final weather = Provider.of<WeatherProvider>(context, listen: false).weather;
      if (weather != null) {
        // Use Future.microtask to avoid calling notifyListeners during build
        Future.microtask(() {
          Provider.of<ForecastProvider>(context, listen: false)
              .fetchForecast(weather.lat, weather.lon);
        });
      }
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final forecastProvider = Provider.of<ForecastProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("5-Day Forecast")),
      body: forecastProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : forecastProvider.error != null
          ? Center(child: Text(forecastProvider.error!))
          : ListView.builder(
        itemCount: forecastProvider.forecast?.days.length ?? 0,
        itemBuilder: (context, index) {
          final day = forecastProvider.forecast!.days[index];
          return ExpansionTile(
            title: Text(
              "${day.date.day}/${day.date.month}/${day.date.year}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: day.hours.map((hour) {
              return ListTile(
                leading: Image.network(
                  "http://openweathermap.org/img/wn/${hour.icon}@2x.png",
                  width: 40,
                ),
                title: Text("${hour.time.hour}:00"),
                trailing: Text("${hour.temperature.toStringAsFixed(1)}°C"),
                subtitle: Text(hour.condition),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
