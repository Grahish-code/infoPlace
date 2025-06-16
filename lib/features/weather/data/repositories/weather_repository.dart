import 'package:shared_preferences/shared_preferences.dart';
import '../../models/weather_model.dart';
import '../datasources/weather_remote_datasource.dart';
import '../../../../core/services/location_service.dart';
import 'dart:convert';

class WeatherRepository {
  final WeatherRemoteDataSource remoteDataSource = WeatherRemoteDataSource();

  Future<Weather> getCurrentWeather() async {
    final position = await LocationService.getCurrentLocation();
    final weather = await remoteDataSource.fetchCurrentWeather(
      position.latitude,
      position.longitude,
    );

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cached_weather', json.encode({
      'name': weather.cityName,
      'main': {'temp': weather.temperature},
      'weather': [
        {
          'description': weather.description,
          'icon': weather.iconCode,
        }
      ],
      'coord': {
        'lat': weather.lat,
        'lon': weather.lon
      }
    }));

    return weather;
  }


  Future<Weather?> getCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cached_weather');
    if (jsonString != null) {
      final jsonData = json.decode(jsonString);
      return Weather.fromJson(jsonData);
    }
    return null;
  }
}
