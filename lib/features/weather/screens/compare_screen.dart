import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../providers/MultiCityWeatherProvider.dart';
import '../widget/weather_card.dart';

class CityComparisonScreen extends StatefulWidget {
  const CityComparisonScreen({Key? key}) : super(key: key);

  @override
  State<CityComparisonScreen> createState() => _CityComparisonScreenState();
}

class _CityComparisonScreenState extends State<CityComparisonScreen>
    with TickerProviderStateMixin {
  final TextEditingController _cityController = TextEditingController();
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String? _userCity;
  bool _isLoadingUserLocation = true;
  bool _isDarkTheme = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getUserLocation();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _userCity = "Mumbai";
          _isLoadingUserLocation = false;
        });
        _addUserCity("Mumbai");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _userCity = "Mumbai";
            _isLoadingUserLocation = false;
          });
          _addUserCity("Mumbai");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        String cityName = placemarks.first.locality ??
            placemarks.first.administrativeArea ??
            "Mumbai";

        setState(() {
          _userCity = cityName;
          _isLoadingUserLocation = false;
        });

        _addUserCity(cityName);
      }
    } catch (e) {
      setState(() {
        _userCity = "Mumbai";
        _isLoadingUserLocation = false;
      });
      _addUserCity("Mumbai");
    }
  }

  void _addUserCity(String cityName) {
    if (mounted) {
      Provider.of<MultiCityWeatherProvider>(context, listen: false)
          .fetchCityWeather(cityName);
      _slideController.forward();
    }
  }

  void _addCity() {
    final cityName = _cityController.text.trim();
    if (cityName.isNotEmpty) {
      final provider = Provider.of<MultiCityWeatherProvider>(context, listen: false);

      bool cityExists = provider.citiesWeather.any(
              (weather) => weather.cityName.toLowerCase() == cityName.toLowerCase()
      );

      if (!cityExists) {
        provider.fetchCityWeather(cityName);
        _cityController.clear();
        _slideController.reset();
        _slideController.forward();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$cityName already added'),
            backgroundColor: _isDarkTheme ? Colors.orange[600] : Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _cityController.clear();
      }
    }
  }

  void _removeCity(String cityName) {
    final provider = Provider.of<MultiCityWeatherProvider>(context, listen: false);
    provider.citiesWeather.removeWhere((weather) => weather.cityName == cityName);
    provider.notifyListeners();
  }

  Color get _backgroundColor => _isDarkTheme ? const Color(0xFF121212) : Colors.grey[50]!;
  Color get _cardColor => _isDarkTheme ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textColor => _isDarkTheme ? Colors.white : Colors.black87;
  Color get _accentColor => _isDarkTheme ? Colors.blue[400]! : Colors.blue[600]!;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MultiCityWeatherProvider>(context);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Weather Comparison'),
        backgroundColor: _isDarkTheme ? const Color(0xFF1E1E1E) : Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: IconButton(
              key: ValueKey(_isDarkTheme),
              icon: Icon(_isDarkTheme ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _isDarkTheme = !_isDarkTheme;
                });
              },
            ),
          ),
          if (provider.citiesWeather.length > 1)
            AnimatedScale(
              scale: provider.citiesWeather.length > 1 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: _cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Clear All Cities', style: TextStyle(color: _textColor)),
                      content: Text('Remove all cities except your location?', style: TextStyle(color: _textColor)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: _accentColor)),
                        ),
                        TextButton(
                          onPressed: () {
                            final firstCity = provider.citiesWeather.isNotEmpty
                                ? provider.citiesWeather.first
                                : null;
                            provider.clearAll();
                            if (firstCity != null && _userCity != null) {
                              provider.fetchCityWeather(_userCity!);
                            }
                            Navigator.pop(context);
                          },
                          child: Text('Clear All', style: TextStyle(color: Colors.red[400])),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add City Section with Animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isDarkTheme ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: _isDarkTheme ? Border.all(color: Colors.grey[800]!) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.add_location, color: _accentColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Add Cities to Compare',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: TextField(
                                controller: _cityController,
                                style: TextStyle(color: _textColor),
                                decoration: InputDecoration(
                                  hintText: 'Enter city name',
                                  hintStyle: TextStyle(color: _isDarkTheme ? Colors.grey[400] : Colors.grey[600]),
                                  filled: true,
                                  fillColor: _isDarkTheme ? Colors.grey[800] : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: _accentColor, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  prefixIcon: Icon(Icons.search, color: _isDarkTheme ? Colors.grey[400] : Colors.grey[600]),
                                ),
                                onSubmitted: (_) => _addCity(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: ElevatedButton(
                              onPressed: provider.citiesWeather.length >= 5 ? null : _addCity,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                disabledBackgroundColor: _isDarkTheme ? Colors.grey[700] : Colors.grey[300],
                              ),
                              child: const Text('Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: provider.citiesWeather.length >= 5
                                  ? Colors.red[100]
                                  : _accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Cities: ${provider.citiesWeather.length}/5',
                              style: TextStyle(
                                fontSize: 14,
                                color: provider.citiesWeather.length >= 5
                                    ? Colors.red[600]
                                    : _accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_userCity != null) ...[
                            const SizedBox(width: 16),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on, color: _accentColor, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isLoadingUserLocation ? 'Getting location...' : _userCity!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _accentColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Loading State with Animation
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: provider.isLoading
                      ? Container(
                    key: const ValueKey('loading'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: _isDarkTheme ? Border.all(color: Colors.grey[800]!) : null,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: _accentColor,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Loading weather data...', style: TextStyle(color: _textColor)),
                      ],
                    ),
                  )
                      : const SizedBox.shrink(),
                ),

                // Error State with Animation
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: provider.error != null
                      ? Container(
                    key: ValueKey(provider.error),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _isDarkTheme ? Colors.red[900]!.withOpacity(0.3) : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isDarkTheme ? Colors.red[400]! : Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: _isDarkTheme ? Colors.red[400] : Colors.red[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: TextStyle(color: _isDarkTheme ? Colors.red[400] : Colors.red[600]),
                          ),
                        ),
                      ],
                    ),
                  )
                      : const SizedBox.shrink(),
                ),

                // Weather Cards Section with Animation
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: provider.citiesWeather.isEmpty && !provider.isLoading
                      ? Container(
                    key: const ValueKey('empty'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: _isDarkTheme ? Border.all(color: Colors.grey[800]!) : null,
                    ),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          child: Icon(
                              Icons.cloud_outlined,
                              size: 64,
                              color: _isDarkTheme ? Colors.grey[600] : Colors.grey[400]
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No cities added yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add cities above to compare their weather',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                      : provider.citiesWeather.isNotEmpty
                      ? SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      key: const ValueKey('cities'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weather Comparison',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Improved scrollable weather cards with better sizing
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35, // Dynamic height
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: provider.citiesWeather.length,
                            itemBuilder: (context, index) {
                              final weather = provider.citiesWeather[index];
                              final isUserCity = index == 0 && _userCity != null &&
                                  weather.cityName.toLowerCase() == _userCity!.toLowerCase();

                              return AnimatedContainer(
                                duration: Duration(milliseconds: 300 + (index * 100)),
                                curve: Curves.easeOutBack,
                                width: 280,
                                margin: EdgeInsets.only(
                                  right: index == provider.citiesWeather.length - 1 ? 0 : 16,
                                ),
                                child: TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 400 + (index * 100)),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: 0.8 + (0.2 * value),
                                      child: Opacity(
                                        opacity: value,
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: _cardColor,
                                                borderRadius: BorderRadius.circular(16),
                                                border: isUserCity
                                                    ? Border.all(color: _accentColor, width: 2)
                                                    : (_isDarkTheme ? Border.all(color: Colors.grey[800]!) : null),
                                                boxShadow: _isDarkTheme ? [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    spreadRadius: 1,
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ] : [
                                                  BoxShadow(
                                                    color: Colors.grey.withOpacity(0.1),
                                                    spreadRadius: 1,
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      if (isUserCity) ...[
                                                        Container(
                                                          padding: const EdgeInsets.all(4),
                                                          decoration: BoxDecoration(
                                                            color: _accentColor.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Icon(Icons.location_on, color: _accentColor, size: 18),
                                                        ),
                                                        const SizedBox(width: 8),
                                                      ],
                                                      Expanded(
                                                        child: Text(
                                                          weather.cityName,
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                            color: isUserCity ? _accentColor : _textColor,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (isUserCity) ...[
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: _accentColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        'Your Location',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: _accentColor,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 12),
                                                  // Flexible container for WeatherCard
                                                  Expanded(
                                                    child: WeatherCard(weather: weather),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!isUserCity)
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: AnimatedScale(
                                                  scale: 1.0,
                                                  duration: const Duration(milliseconds: 200),
                                                  child: GestureDetector(
                                                    onTap: () => _removeCity(weather.cityName),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: _isDarkTheme ? Colors.red[800] : Colors.red[100],
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Icon(
                                                        Icons.close,
                                                        size: 16,
                                                        color: _isDarkTheme ? Colors.red[300] : Colors.red[600],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}