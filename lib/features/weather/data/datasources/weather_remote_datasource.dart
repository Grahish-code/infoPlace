import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../models/weather_model.dart';

class WeatherRemoteDataSource {
  Future<Weather> fetchCurrentWeather(double lat, double lon) async {
    final url = Uri.parse(
      "${ApiConstants.baseUrl}weather?lat=$lat&lon=$lon&units=metric&appid=${ApiConstants.apiKey}",
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return Weather.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to load weather");
    }
  }
}
