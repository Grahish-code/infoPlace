import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infoplace/features/weather/screens/weather_cache.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/services/weather_services.dart';
import '../../news/screens/home_scree_news.dart';
import '../providers/alert_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/forecast_provider.dart';
import 'alert_screen.dart';
import 'compare_screen.dart';
import 'dart:math';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOfflineMode = false;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWeatherData();
    });
  }

  Future<void> fetchAndUpdateAlerts(
      BuildContext context, {
        required double lat,
        required double lon,
        bool notifyUser = true,
      }) async {
    try {
      final alerts = await WeatherService.checkWeatherAlert(
        lat: lat,
        lon: lon,
        notifyUser: notifyUser,
      );
      Provider.of<AlertProvider>(context, listen: false).updateAlerts(alerts);
      print('Successfully updated ${alerts.length} alerts');
    } catch (e) {
      print('Error fetching alerts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load alerts: $e')),
      );
    }
  }


  Future<void> _initializeWeatherData() async {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final forecastProvider = Provider.of<ForecastProvider>(context, listen: false);

    // Try to load from cache first
    await _loadCachedData();

    // Then try to fetch fresh data
    Future.microtask(() async {
      try {
        await weatherProvider.fetchWeather();
        if (weatherProvider.weather != null) {
          setState(() {
            _isOfflineMode = false;
            _lastUpdateTime = DateTime.now();
          });

          // Cache the fresh data
          await _cacheWeatherData(weatherProvider.weather);

          // Fetch forecast
          await forecastProvider.fetchForecast(
            weatherProvider.weather!.lat,
            weatherProvider.weather!.lon,
          );

          if (forecastProvider.forecast != null) {
            await _cacheForecastData(forecastProvider.forecast);
          }
        }
      } catch (e) {
        // If network fails and no cached data, show error
        if (weatherProvider.weather == null) {
          setState(() {
            _isOfflineMode = true;
          });
        }
      }
    });
  }

  Future<void> _loadCachedData() async {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final forecastProvider = Provider.of<ForecastProvider>(context, listen: false);

    try {
      // Load cached weather
      final cachedWeatherJson = await WeatherCache.getWeather();
      if (cachedWeatherJson != null) {
        final cachedAt = await weatherProvider.setWeatherFromCache(cachedWeatherJson);

        setState(() {
          _isOfflineMode = true;
          _lastUpdateTime = cachedAt ?? DateTime.now();
        });
      }

      // Load cached forecast
      final cachedForecastJson = await WeatherCache.getForecast();
      if (cachedForecastJson != null) {
        final forecastData = json.decode(cachedForecastJson);
        forecastProvider.setForecastFromCache(forecastData);
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  Future<void> _cacheWeatherData(dynamic weather) async {
    try {
      final weatherMap = {
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
          'lon': weather.lon,
        },
        'cached_at': DateTime.now().toIso8601String(),
      };
      await WeatherCache.saveWeather(json.encode(weatherMap));
    } catch (e) {
      print('Error caching weather data: $e');
    }
  }

  Future<void> _cacheForecastData(dynamic forecast) async {
    try {
      final forecastMap = {
        'days': forecast.days?.map((day) => {
          'date': day.date.toIso8601String(),
          'hours': day.hours?.map((hour) => {
            'time': hour.time.toIso8601String(),
            'temperature': hour.temperature,
            'condition': hour.condition,
            'icon': hour.icon,
          }).toList() ?? [],
        }).toList() ?? [],
        'cached_at': DateTime.now().toIso8601String(),
      };
      await WeatherCache.saveForecast(json.encode(forecastMap));
    } catch (e) {
      print('Error caching forecast data: $e');
    }
  }

  Color getWeatherColor(String desc) {
    if (desc.toLowerCase().contains("rain")) return Colors.blue.shade400;
    if (desc.toLowerCase().contains("cloud")) return Colors.grey.shade600;
    if (desc.toLowerCase().contains("sun")) return Colors.orange.shade400;
    if (desc.toLowerCase().contains("storm")) return Colors.purple.shade400;
    return Colors.blue.shade300;
  }

  void _showDayDetailModal(BuildContext context, dynamic day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayDetailModal(day: day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final forecastProvider = Provider.of<ForecastProvider>(context);
    final weather = weatherProvider.weather;
    final forecast = forecastProvider.forecast;

    return Scaffold(
      body: weatherProvider.isLoading && !_isOfflineMode
          ? Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade800],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading weather data...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      )
          : weatherProvider.error != null && weather == null
          ? Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade400, Colors.red.shade800],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to fetch weather data.\nPlease check your connection and try again.',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _initializeWeatherData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      )
          : weather == null
          ? Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade400, Colors.grey.shade800],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 64, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'No Weather Data Available',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: () async {
          await _initializeWeatherData();
        },
        color: Colors.white,
        backgroundColor: getWeatherColor(weather.description),
        child: Stack(
          children: [
            WeatherBackground(weather: weather.description),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    getWeatherColor(weather.description).withOpacity(0.3),
                    getWeatherColor(weather.description).withOpacity(0.7),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    floating: true,
                    snap: true,
                    actions: [
                      // Enhanced News Button
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NewsScreen()),
                            );
                          },
                          icon: const Icon(
                            Icons.newspaper_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: const Text(
                            'Latest News',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 28),
                        tooltip: 'View Alerts',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AlertScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Offline Mode Indicator
                          if (_isOfflineMode) _buildOfflineBanner(),
                          if (_isOfflineMode) const SizedBox(height: 16),

                          _buildCurrentWeatherCard(context, weather),
                          const SizedBox(height: 24),
                          _buildTodayDetailsCard(context, weather),
                          const SizedBox(height: 24),
                          forecastProvider.isLoading
                              ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          )
                              : forecastProvider.error != null
                              ? Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 32,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  forecastProvider.error!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    if (weatherProvider.weather != null) {
                                      forecastProvider.fetchForecast(
                                        weatherProvider.weather!.lat,
                                        weatherProvider.weather!.lon,
                                      );
                                    }
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                              : forecast != null &&
                              forecast.days != null &&
                              forecast.days.isNotEmpty
                              ? _buildForecastCard(context, forecast.days)
                              : Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'No forecast data available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildCompareButton(context),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _lastUpdateTime != null
                      ? 'Last updated: ${DateFormat('MMM dd, HH:mm').format(_lastUpdateTime!)}'
                      : 'Showing cached data',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _initializeWeatherData(),
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard(BuildContext context, dynamic weather) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                weather.cityName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isOfflineMode
                    ? 'Offline Data'
                    : 'Updated ${DateFormat.jm().format(DateTime.now())}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 20),
              Image.network(
                'http://openweathermap.org/img/wn/${weather.iconCode}@4x.png',
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(Icons.wb_sunny, size: 60, color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                '${weather.temperature.toStringAsFixed(0)}°',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  height: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                weather.description.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayDetailsCard(BuildContext context, dynamic weather) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TODAY\'S DETAILS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Temperature',
                      '${weather.temperature.toStringAsFixed(0)}°C',
                      Icons.thermostat,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Condition',
                      weather.description,
                      Icons.wb_cloudy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Location',
                      weather.cityName,
                      Icons.location_on,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Status',
                      _isOfflineMode ? 'Offline' : 'Live',
                      _isOfflineMode ? Icons.cloud_off : Icons.cloud_done,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.white.withOpacity(0.8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard(BuildContext context, List<dynamic> forecast) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '5-DAY FORECAST',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Row(
                    children: [
                      if (_isOfflineMode)
                        const Icon(
                          Icons.cloud_off,
                          size: 12,
                          color: Colors.orange,
                        ),
                      if (_isOfflineMode) const SizedBox(width: 4),
                      Text(
                        'Tap for details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...forecast.take(5).map((day) {
                print("ForecastDay: date=${day.date}, hours=${day.hours.length}");
                final icon = day.hours.isNotEmpty ? day.hours[0].icon : '01d';
                final temp = day.hours.isNotEmpty
                    ? day.hours
                    .map((hour) => hour.temperature)
                    .reduce((a, b) => a + b) /
                    day.hours.length
                    : 0.0;
                return GestureDetector(
                  onTap: () => _showDayDetailModal(context, day),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEE').format(day.date),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                DateFormat('MMM d').format(day.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'http://openweathermap.org/img/wn/$icon.png',
                                width: 32,
                                height: 32,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.wb_sunny,
                                    size: 32,
                                    color: Colors.white.withOpacity(0.8),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${temp.toStringAsFixed(0)}°',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (day.hours != null && day.hours.isNotEmpty)
                                Text(
                                  '${day.hours.length} hours',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompareButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CityComparisonScreen(),
                ),
              );
            },
            icon: const Icon(Icons.import_contacts_sharp, size: 24),
            label: const Text(
              "Compare Cities",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DayDetailModal extends StatelessWidget {
  final dynamic day;

  const DayDetailModal({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade400.withOpacity(0.9),
                  Colors.blue.shade600.withOpacity(0.9),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        DateFormat('EEEE, MMMM d').format(day.date),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hourly Forecast',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: day.hours != null && day.hours.isNotEmpty
                      ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: day.hours.length,
                    itemBuilder: (context, index) {
                      final hour = day.hours[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              child: Text(
                                '${hour.time.hour.toString().padLeft(2, '0')}:00',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Image.network(
                              "http://openweathermap.org/img/wn/${hour.icon}@2x.png",
                              width: 48,
                              height: 48,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.wb_sunny,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${hour.temperature.toStringAsFixed(1)}°C',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hour.condition,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 64,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hourly data available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WeatherBackground extends StatefulWidget {
  final String weather;

  const WeatherBackground({super.key, required this.weather});

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WeatherPainter(
            weather: widget.weather,
            animationValue: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}



class WeatherPainter extends CustomPainter {
  final String weather;
  final double animationValue;
  final DateTime time;

  WeatherPainter({
    required this.weather,
    required this.animationValue,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(42);

    // Draw dynamic sky background
    _drawSkyGradient(canvas, size, paint);

    // Draw weather-specific effects
    final weatherType = weather.toLowerCase();

    if (weatherType.contains("rain") || weatherType.contains("drizzle")) {
      _drawRainEffect(canvas, size, paint, random);
    } else if (weatherType.contains("snow")) {
      _drawSnowEffect(canvas, size, paint, random);
    } else if (weatherType.contains("cloud")) {
      _drawCloudyEffect(canvas, size, paint, random);
    } else if (weatherType.contains("sun") || weatherType.contains("clear")) {
      _drawSunnyEffect(canvas, size, paint, random);
    } else if (weatherType.contains("storm") || weatherType.contains("thunder")) {
      _drawStormEffect(canvas, size, paint, random);
    } else if (weatherType.contains("fog") || weatherType.contains("mist")) {
      _drawFogEffect(canvas, size, paint, random);
    } else if (weatherType.contains("wind")) {
      _drawWindyEffect(canvas, size, paint, random);
    } else {
      _drawDefaultEffect(canvas, size, paint, random);
    }

    // Add atmospheric particles
    _drawAtmosphericParticles(canvas, size, paint, random);
  }

  void _drawSkyGradient(Canvas canvas, Size size, Paint paint) {
    final colors = _getSkyColors(weather);

    // Create time-based sky variation
    final timeVariation = sin(animationValue * 2 * pi) * 0.1;
    final adjustedColors = colors.map((color) {
      final hsl = HSLColor.fromColor(color);
      return hsl.withLightness(
          (hsl.lightness + timeVariation).clamp(0.0, 1.0)
      ).toColor();
    }).toList();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: adjustedColors,
      stops: [0.0, 0.4, 1.0],
    );

    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;
  }

  void _drawRainEffect(Canvas canvas, Size size, Paint paint, Random random) {
    // Heavy rain with varying droplet sizes and speeds
    final rainIntensity = weather.toLowerCase().contains("heavy") ? 100 : 60;

    for (int i = 0; i < rainIntensity; i++) {
      final dropletSeed = i * 0.1;
      final x = (dropletSeed * size.width + animationValue * 50) % size.width;
      final speed = 1.5 + (i % 3) * 0.5;
      final y = (dropletSeed * size.height + animationValue * size.height * speed) % size.height;

      // Varying droplet properties
      final opacity = 0.4 + (i % 4) * 0.15;
      final length = 8 + (i % 3) * 4;
      final width = 1.5 + (i % 2) * 0.5;

      paint.color = Colors.lightBlue.shade100.withOpacity(opacity);
      paint.strokeWidth = width;
      paint.strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x - 5, y),
        Offset(x - 5, y + length),
        paint,
      );

      // Add splash effect at bottom
      if (y > size.height * 0.9) {
        paint.color = Colors.white.withOpacity(0.3);
        canvas.drawCircle(Offset(x - 5, size.height), 2, paint);
      }
    }

    // Draw rain clouds
    _drawRainClouds(canvas, size, paint);
  }

  void _drawSnowEffect(Canvas canvas, Size size, Paint paint, Random random) {
    // Realistic snowfall with different flake sizes
    for (int i = 0; i < 80; i++) {
      final flakeSeed = i * 0.15;
      final driftX = sin(animationValue * 2 + flakeSeed) * 20;
      final x = (flakeSeed * size.width + driftX) % size.width;
      final y = (flakeSeed * size.height + animationValue * size.height * 0.3) % size.height;

      final flakeSize = 2 + (i % 4);
      final opacity = 0.6 + (i % 3) * 0.2;

      paint.color = Colors.white.withOpacity(opacity);

      // Draw snowflake pattern
      _drawSnowflake(canvas, Offset(x, y), flakeSize.toDouble(), paint);
    }

    // Snow accumulation effect at bottom
    paint.color = Colors.white.withOpacity(0.8);
    final path = Path();
    path.moveTo(0, size.height * 0.95);
    for (double x = 0; x <= size.width; x += 10) {
      final snowHeight = 5 + sin(x * 0.1 + animationValue) * 3;
      path.lineTo(x, size.height - snowHeight);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSnowflake(Canvas canvas, Offset center, double size, Paint paint) {
    paint.strokeWidth = 1;
    paint.strokeCap = StrokeCap.round;

    // Draw 6-pointed snowflake
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final x1 = center.dx + cos(angle) * size;
      final y1 = center.dy + sin(angle) * size;
      canvas.drawLine(center, Offset(x1, y1), paint);

      // Add branches
      final branchSize = size * 0.5;
      final branchAngle1 = angle + pi / 6;
      final branchAngle2 = angle - pi / 6;
      final branchX1 = center.dx + cos(branchAngle1) * branchSize;
      final branchY1 = center.dy + sin(branchAngle1) * branchSize;
      final branchX2 = center.dx + cos(branchAngle2) * branchSize;
      final branchY2 = center.dy + sin(branchAngle2) * branchSize;

      canvas.drawLine(Offset(x1 * 0.7 + center.dx * 0.3, y1 * 0.7 + center.dy * 0.3),
          Offset(branchX1, branchY1), paint);
      canvas.drawLine(Offset(x1 * 0.7 + center.dx * 0.3, y1 * 0.7 + center.dy * 0.3),
          Offset(branchX2, branchY2), paint);
    }
  }

  void _drawCloudyEffect(Canvas canvas, Size size, Paint paint, Random random) {
    // Multiple cloud layers with different speeds and opacities
    final cloudLayers = [
      {'count': 4, 'speed': 0.1, 'opacity': 0.9, 'size': 1.2},
      {'count': 3, 'speed': 0.15, 'opacity': 0.7, 'size': 1.0},
      {'count': 5, 'speed': 0.08, 'opacity': 0.5, 'size': 0.8},
    ];

    for (final layer in cloudLayers) {
      final count = layer['count'] as int;
      final speed = layer['speed'] as double;
      final opacity = layer['opacity'] as double;
      final sizeMultiplier = layer['size'] as double;

      for (int i = 0; i < count; i++) {
        final x = (size.width * 0.25 * i + animationValue * size.width * speed) % (size.width + 150);
        final y = size.height * (0.15 + (i % 3) * 0.15);

        _drawRealisticCloud(canvas, Offset(x - 75, y),
            80 * sizeMultiplier, 50 * sizeMultiplier,
            Colors.white.withOpacity(opacity), paint);
      }
    }
  }

  void _drawRealisticCloud(Canvas canvas, Offset center, double width, double height, Color color, Paint paint) {
    paint.color = color;

    // Create fluffy cloud shape with multiple circles
    final cloudParts = [
      {'offset': Offset(0, 0), 'radius': height * 0.6},
      {'offset': Offset(-width * 0.3, height * 0.1), 'radius': height * 0.5},
      {'offset': Offset(width * 0.3, height * 0.1), 'radius': height * 0.5},
      {'offset': Offset(-width * 0.15, -height * 0.2), 'radius': height * 0.4},
      {'offset': Offset(width * 0.15, -height * 0.2), 'radius': height * 0.4},
    ];

    for (final part in cloudParts) {
      final offset = part['offset'] as Offset;
      final radius = part['radius'] as double;
      canvas.drawCircle(center + offset, radius, paint);
    }
  }

  void _drawSunnyEffect(Canvas canvas, Size size, Paint paint, Random random) {
    final sunCenter = Offset(size.width * 0.8, size.height * 0.25);
    final sunRadius = 40.0;

    // Animated sun with pulsing effect
    final pulseEffect = 1 + sin(animationValue * 4) * 0.1;

    // Sun glow effect
    final glowGradient = RadialGradient(
      colors: [
        Colors.yellow.withOpacity(0.8),
        Colors.orange.withOpacity(0.6),
        Colors.orange.withOpacity(0.2),
        Colors.transparent,
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    );

    paint.shader = glowGradient.createShader(
        Rect.fromCircle(center: sunCenter, radius: sunRadius * 2)
    );
    canvas.drawCircle(sunCenter, sunRadius * 2 * pulseEffect, paint);
    paint.shader = null;

    // Sun core
    paint.color = Colors.yellow;
    canvas.drawCircle(sunCenter, sunRadius * pulseEffect, paint);

    // Animated sun rays
    paint.color = Colors.yellow.withOpacity(0.6);
    paint.strokeWidth = 3;
    paint.strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * pi / 6) + (animationValue * 0.5);
      final rayLength = 25 + sin(animationValue * 3 + i) * 8;
      final x1 = sunCenter.dx + cos(angle) * (sunRadius + 10);
      final y1 = sunCenter.dy + sin(angle) * (sunRadius + 10);
      final x2 = sunCenter.dx + cos(angle) * (sunRadius + rayLength);
      final y2 = sunCenter.dy + sin(angle) * (sunRadius + rayLength);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    // Floating light particles
    for (int i = 0; i < 15; i++) {
      final particleX = sunCenter.dx + cos(animationValue + i) * (80 + i * 5);
      final particleY = sunCenter.dy + sin(animationValue * 0.7 + i) * (80 + i * 5);
      final opacity = (sin(animationValue * 2 + i) + 1) * 0.3;

      paint.color = Colors.yellow.withOpacity(opacity);
      canvas.drawCircle(Offset(particleX, particleY), 2, paint);
    }
  }

  void _drawStormEffect(Canvas canvas, Size size, Paint paint, Random random) {
    // Dramatic storm clouds
    paint.color = Colors.grey.shade800.withOpacity(0.9);
    for (int i = 0; i < 4; i++) {
      final x = (size.width * 0.3 * i + animationValue * size.width * 0.1) % (size.width + 100);
      final y = size.height * (0.2 + (i % 2) * 0.1);
      _drawRealisticCloud(canvas, Offset(x - 50, y), 120, 80,
          Colors.grey.shade800.withOpacity(0.8), paint);
    }

    // Lightning effect with branching
    final lightningPhase = (animationValue * 4) % 1.0;
    if (lightningPhase > 0.7 && lightningPhase < 0.85) {
      paint.color = Colors.white.withOpacity(0.9);
      paint.strokeWidth = 4;
      paint.strokeCap = StrokeCap.round;

      // Main lightning bolt
      final startX = size.width * (0.3 + sin(animationValue) * 0.2);
      _drawLightningBolt(canvas, Offset(startX, size.height * 0.1),
          Offset(startX + 20, size.height * 0.6), paint, random);

      // Screen flash effect
      paint.color = Colors.white.withOpacity(0.1);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }

    // Heavy rain during storm
    for (int i = 0; i < 80; i++) {
      final dropX = (i * size.width / 80 + animationValue * 80) % size.width;
      final dropY = (i * size.height / 80 + animationValue * size.height * 2) % size.height;

      paint.color = Colors.lightBlue.withOpacity(0.6);
      paint.strokeWidth = 2;
      canvas.drawLine(
        Offset(dropX - 10, dropY),
        Offset(dropX - 10, dropY + 15),
        paint,
      );
    }
  }

  void _drawLightningBolt(Canvas canvas, Offset start, Offset end, Paint paint, Random random) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final segments = 8;
    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final x = start.dx + (end.dx - start.dx) * t + (random.nextDouble() - 0.5) * 30;
      final y = start.dy + (end.dy - start.dy) * t;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  void _drawFogEffect(Canvas canvas, Size size, Paint paint, Random random) {
    // Layered fog effect
    for (int layer = 0; layer < 3; layer++) {
      final opacity = 0.2 - layer * 0.05;
      final speed = 0.05 + layer * 0.02;

      for (int i = 0; i < 8; i++) {
        final x = (size.width * 0.15 * i + animationValue * size.width * speed) % (size.width + 200);
        final y = size.height * (0.4 + layer * 0.2 + sin(animationValue + i) * 0.05);

        paint.color = Colors.grey.shade300.withOpacity(opacity);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x - 100, y),
            width: 150 + layer * 50,
            height: 60 + layer * 20,
          ),
          paint,
        );
      }
    }
  }

  void _drawWindyEffect(Canvas canvas, Size size, Paint paint, Random random) {
    // Wind lines showing air movement
    paint.strokeWidth = 2;
    paint.strokeCap = StrokeCap.round;

    for (int i = 0; i < 30; i++) {
      final y = size.height * 0.2 + (i % 10) * size.height * 0.06;
      final windSpeed = 1.5 + (i % 3) * 0.5;
      final x = (animationValue * size.width * windSpeed) % (size.width + 100);
      final length = 20 + (i % 4) * 10;
      final opacity = 0.3 + (i % 4) * 0.1;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawLine(
        Offset(x - 50, y),
        Offset(x - 50 + length, y),
        paint,
      );
    }

    // Swaying grass effect
    for (int i = 0; i < 20; i++) {
      final grassX = size.width * 0.05 * i;
      final sway = sin(animationValue * 3 + i * 0.5) * 10;

      paint.color = Colors.green.withOpacity(0.6);
      paint.strokeWidth = 3;
      canvas.drawLine(
        Offset(grassX, size.height),
        Offset(grassX + sway, size.height - 30),
        paint,
      );
    }
  }

  void _drawDefaultEffect(Canvas canvas, Size size, Paint paint, Random random) {
    // Gentle twinkling stars
    for (int i = 0; i < 25; i++) {
      final starX = (i * 37) % size.width.toInt();
      final starY = (i * 23) % (size.height * 0.6).toInt();
      final twinkle = (sin(animationValue * 2 + i) + 1) * 0.5;

      paint.color = Colors.white.withOpacity(twinkle * 0.8);
      canvas.drawCircle(Offset(starX.toDouble(), starY.toDouble()),
          1.5 + twinkle, paint);
    }
  }

  void _drawRainClouds(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < 3; i++) {
      final x = (size.width * 0.35 * i + animationValue * size.width * 0.05) % (size.width + 80);
      final y = size.height * (0.15 + (i % 2) * 0.08);
      _drawRealisticCloud(canvas, Offset(x - 40, y), 100, 60,
          Colors.grey.shade600.withOpacity(0.8), paint);
    }
  }

  void _drawAtmosphericParticles(Canvas canvas, Size size, Paint paint, Random random) {
    // Subtle floating particles for atmosphere
    for (int i = 0; i < 10; i++) {
      final particleX = (random.nextDouble() * size.width + animationValue * 20) % size.width;
      final particleY = (random.nextDouble() * size.height + animationValue * 10) % size.height;
      final opacity = (sin(animationValue * 1.5 + i) + 1) * 0.1;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(particleX, particleY), 1, paint);
    }
  }

  List<Color> _getSkyColors(String weather) {
    final weatherType = weather.toLowerCase();
    final hour = time.hour;

    // Time-based color adjustments
    final isDaytime = hour >= 6 && hour <= 18;
    final isSunrise = hour >= 5 && hour <= 7;
    final isSunset = hour >= 17 && hour <= 19;

    if (weatherType.contains("rain") || weatherType.contains("drizzle")) {
      return isDaytime
          ? [Colors.blueGrey.shade600, Colors.blueGrey.shade800, Colors.blueGrey.shade900]
          : [Colors.blueGrey.shade800, Colors.blueGrey.shade900, Colors.black87];
    } else if (weatherType.contains("snow")) {
      return isDaytime
          ? [Colors.grey.shade300, Colors.grey.shade500, Colors.grey.shade700]
          : [Colors.grey.shade700, Colors.grey.shade800, Colors.grey.shade900];
    } else if (weatherType.contains("cloud")) {
      return isDaytime
          ? [Colors.grey.shade400, Colors.grey.shade600, Colors.grey.shade700]
          : [Colors.grey.shade700, Colors.grey.shade800, Colors.black87];
    } else if (weatherType.contains("sun") || weatherType.contains("clear")) {
      if (isSunrise) {
        return [Colors.orange.shade200, Colors.orange.shade400, Colors.blue.shade300];
      } else if (isSunset) {
        return [Colors.pink.shade200, Colors.orange.shade300, Colors.purple.shade400];
      } else if (isDaytime) {
        return [Colors.lightBlue.shade200, Colors.blue.shade400, Colors.blue.shade600];
      } else {
        return [Colors.indigo.shade800, Colors.indigo.shade900, Colors.black];
      }
    } else if (weatherType.contains("storm") || weatherType.contains("thunder")) {
      return [Colors.purple.shade800, Colors.grey.shade900, Colors.black];
    } else if (weatherType.contains("fog") || weatherType.contains("mist")) {
      return [Colors.grey.shade200, Colors.grey.shade400, Colors.grey.shade600];
    }

    // Default sky
    return isDaytime
        ? [Colors.lightBlue.shade300, Colors.blue.shade500, Colors.blue.shade700]
        : [Colors.indigo.shade600, Colors.indigo.shade800, Colors.black87];
  }

  @override
  bool shouldRepaint(covariant WeatherPainter oldDelegate) =>
      oldDelegate.weather != weather ||
          oldDelegate.animationValue != animationValue ||
          oldDelegate.time.hour != time.hour;
}